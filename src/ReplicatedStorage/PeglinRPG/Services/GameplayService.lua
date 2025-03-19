-- GameplayService.lua
-- Servicio central que coordina el flujo del juego
-- Reemplaza al anterior GameplayManager con una arquitectura más estructurada

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Definición del GameplayService
local GameplayService = ServiceInterface:Extend("GameplayService")

-- Constructor
function GameplayService.new(serviceLocator, eventBus)
    local self = setmetatable({}, GameplayService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Estado del juego (será manejado por el Store)
    self.gameState = {
        currentPhase = "NONE", -- NONE, SETUP, PLAYER_TURN, ENEMY_TURN, REWARD, GAME_OVER
        turnCount = 0,
        battleResult = nil, -- WIN, LOSE
        boardGenerated = false,
        enemyGenerated = false,
        currentLevel = nil,
        currentEncounter = 0,
    }
    
    -- Referencias a objetos visuales (serán manejadas por el VisualService)
    self.visualElements = {
        playerUI = nil,
        boardModel = nil,
        enemyModel = nil,
        currentOrbVisual = nil,
    }
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    return self
end


function GameplayService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Suscripción para manejar eventos de lanzamiento de orbes
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("OrbLaunchRequested", function(direction, position)
        self:handleOrbLaunchRequest(direction, position)
    end))
    
    -- Asegurarnos de que el evento ClientReady inicie el juego
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("ClientReady", function()
        print("GameplayService: Evento ClientReady recibido, iniciando juego...")
        -- Esperar un poco para asegurar que todos los servicios estén listos
        spawn(function()
            wait(0.5)
            self:StartNewGame()
        end)
    end))
    
    -- Suscripciones principales del juego
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("PlayerTurnCompleted", function()
        self:changePhase("ENEMY_TURN")
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyTurnCompleted", function()
        self:changePhase("PLAYER_TURN")
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BattleWon", function(enemyType, position)
        self:handleBattleWon(enemyType, position)
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BattleLost", function()
        self:handleBattleLost()
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("OrbLost", function(reason)
        self:handleOrbLost(reason)
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("OrbStopped", function()
        self:handleOrbStopped()
    end))
    
    -- Recibir evento de clic para lanzar desde el cliente
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("PlayerClickedToLaunch", function(direction)
        print("GameplayService: Recibida solicitud de lanzamiento desde el cliente con dirección:", direction)
        self:launchOrb(direction)
    end))
    
    -- Manejo de eventos de juego adicionales
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("GameStartRequested", function()
        print("GameplayService: Evento GameStartRequested recibido")
        self:StartNewGame()
    end))
    
    -- Eventos de respaldo para iniciar componentes específicos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BoardRequested", function(width, height, pegCount, options)
        if not self.gameState.boardGenerated then
            local boardService = self.serviceLocator:GetService("BoardService")
            if boardService then
                boardService:generateBoard(width, height, pegCount, options)
                self.gameState.boardGenerated = true
            end
        end
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyRequested", function(levelName, isBoss)
        if not self.gameState.enemyGenerated then
            local enemyService = self.serviceLocator:GetService("EnemyService")
            if enemyService then
                enemyService:generateEnemy(levelName or self.gameState.currentLevel, isBoss)
                self.gameState.enemyGenerated = true
            end
        end
    end))
    
    -- Evento de prueba para verificar la comunicación
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("TestEvent", function(message)
        print("GameplayService: Evento de prueba recibido con mensaje:", message)
    end))
    
    -- Eventos para manejar recompensas y progresión
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("RewardSelected", function(rewardType, rewardData)
        self:handleRewardSelection(rewardType, rewardData)
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("ContinueAfterReward", function()
        self:advanceToNextEncounter()
    end))
    
    -- Manejar retorno al menú o reinicio
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("ReturnToMainMenu", function()
        self:cleanupGame()
        self:changePhase("NONE")
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("RestartGame", function()
        self:cleanupGame()
        wait(0.5)
        self:StartNewGame()
    end))
    -- Añade esta suscripción en la función Initialize de GameplayService
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("ForceCreateBoard", function()
        self:forceCreateBoard()
    end))
    print("GameplayService: Inicializado correctamente")
end

-- Añade esta función al GameplayService.lua
function GameplayService:forceCreateBoard()
    print("GameplayService: Forzando creación de tablero")
    
    local boardService = self.serviceLocator:GetService("BoardService")
    if not boardService then
        print("GameplayService: BoardService no encontrado, intentando crear uno")
        -- Intentar cargar BoardService directamente
        local success, BoardService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("BorderFactory")).new()
        end)
        
        if success and BoardService then
            -- Usar directamente el BorderFactory para crear bordes
            local boardModel = Instance.new("Model")
            boardModel.Name = "EmergencyBoard"
            boardModel.Parent = workspace
            
            -- Crear bordes básicos
            BoardService:createBorders(boardModel, 60, 70, "FOREST")
            
            -- Publicar evento de tablero generado
            self.eventBus:Publish("BoardGenerated", boardModel, 60, 70, "FOREST")
            self.gameState.boardGenerated = true
            
            print("GameplayService: Tablero de emergencia creado")
            return true
        end
    else
        -- Si BoardService existe, llamar al método directamente
        local board = boardService:generateBoard(60, 70, 120, {theme = "FOREST"})
        if board then
            self.gameState.boardGenerated = true
            print("GameplayService: Tablero generado correctamente")
            return true
        else
            print("GameplayService: Error al generar tablero a través de BoardService")
        end
    end
    
    return false
end
-- Inicia un nuevo juego
function GameplayService:StartNewGame()
    print("GameplayService: Iniciando nuevo juego")
    
    -- Restablecer estado del juego
    self.gameState = {
        currentPhase = "SETUP",
        turnCount = 0,
        battleResult = nil,
        boardGenerated = false,
        enemyGenerated = false,
        currentLevel = "FOREST",
        currentEncounter = 1,
    }
    
    -- Iniciar servicios necesarios
    local playerService = self.serviceLocator:GetService("PlayerService")
    if playerService then
        playerService:ResetPlayer()
    else
        warn("GameplayService: No se pudo obtener PlayerService")
    end
    
    -- Publicar evento de nuevo juego iniciado
    self.eventBus:Publish("GameStarted", self.gameState)
    print("GameplayService: Evento GameStarted publicado")
    
    -- IMPORTANTE: Forzar creación del tablero primero
    if self:forceCreateBoard() then
        print("GameplayService: Tablero creado correctamente al inicio del juego")
    else
        warn("GameplayService: Fallo al crear tablero, intentando método alternativo")
        self.eventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
    end
    
    -- Configurar primer encuentro
    wait(1) -- Esperar a que el tablero se genere
    self:setupEncounter()
    
    return true
end

-- Reemplaza la función setupEncounter para asegurar que el tablero y el enemigo se generen correctamente
function GameplayService:setupEncounter()
    print("GameplayService: Configurando encuentro:", self.gameState.currentEncounter)
    
    -- Publicar evento de inicio de encuentro
    self.eventBus:Publish("EncounterSetupStarted", self.gameState.currentLevel, self.gameState.currentEncounter)
    
    -- Obtener servicios necesarios
    local playerService = self.serviceLocator:GetService("PlayerService")
    local enemyService = self.serviceLocator:GetService("EnemyService")
    local boardService = self.serviceLocator:GetService("BoardService")
    local orbService = self.serviceLocator:GetService("OrbService")
    local uiService = self.serviceLocator:GetService("UIService")
    
    -- Verificar servicios críticos y crear servicios básicos si no existen
    if not enemyService then
        warn("GameplayService: No se pudo obtener EnemyService, creando servicio básico")
        
        -- Crear EnemyService si no existe
        local success, EnemyService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EnemyService"))
        end)
        
        if success and EnemyService then
            enemyService = EnemyService.new(self.serviceLocator, self.eventBus)
            self.serviceLocator:RegisterService("EnemyService", enemyService)
            enemyService:Initialize()
            print("GameplayService: EnemyService creado e inicializado correctamente")
        else
            warn("GameplayService: No se pudo crear EnemyService:", EnemyService)
            return false
        end
    end
    
    -- PASO 1: Primero generar el tablero para que el enemigo tenga un contexto
    -- Generar tablero (si no hay BoardService, fallar)
    if not boardService then
        warn("GameplayService: BoardService no está disponible, intentando crear uno")
        local success, BoardService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("BoardService"))
        end)
        
        if success and BoardService then
            boardService = BoardService.new(self.serviceLocator, self.eventBus)
            self.serviceLocator:RegisterService("BoardService", boardService)
            boardService:Initialize()
            print("GameplayService: BoardService creado correctamente como fallback")
        else
            warn("GameplayService: No se pudo crear BoardService")
            return false
        end
    end

    -- Configurar encuentro con o sin enemigo explícito
    local isBoss = false
    if playerService and playerService.progression then
        isBoss = self.gameState.currentEncounter == playerService.progression.totalEncounters
    end
    
    -- Obtener configuración del nivel actual
    local levelConfig = Config.LEVELS[self.gameState.currentLevel] or {
        NAME = "Nivel Predeterminado",
        PEG_COLORS = {
            BrickColor.new("Bright blue"),
            BrickColor.new("Bright yellow"),
            BrickColor.new("Bright green"),
        },
        BACKGROUND_COLOR = Color3.fromRGB(30, 30, 50)
    }
    
    -- Configuración del tablero
    local boardConfig = {
        theme = self.gameState.currentLevel,
        pegColors = levelConfig.PEG_COLORS or {BrickColor.new("Bright blue")},
        backgroundColor = levelConfig.BACKGROUND_COLOR or Color3.fromRGB(30, 30, 50),
    }
    
    local boardWidth = Config.BOARD.WIDTH or 60
    local boardHeight = Config.BOARD.HEIGHT or 70
    local boardPegCount = Config.BOARD.DEFAULT_PEG_COUNT or 120
    
    -- PASO 2: Generar tablero Y ESPERAR a que esté listo
    print("GameplayService: Generando tablero...")
    local boardSuccess = false
    local board = nil
    
    -- Primero intentar el método normal
    if typeof(boardService.generateBoard) == "function" then
        board = boardService:generateBoard(boardWidth, boardHeight, boardPegCount, boardConfig)
        if board then
            self.gameState.boardGenerated = true
            boardSuccess = true
            print("GameplayService: Tablero generado correctamente")
        end
    end
    
    -- Si falló, intentar directamente con el EventBus como último recurso
    if not boardSuccess then
        print("GameplayService: Intentando generar tablero mediante evento directo")
        self.eventBus:Publish("BoardRequested", boardWidth, boardHeight, boardPegCount, boardConfig)
        
        -- Esperar un poco para dar tiempo a que el tablero se genere
        wait(1)
        self.gameState.boardGenerated = true
        boardSuccess = true
    end
    
    -- PASO 3: DESPUÉS de tener el tablero, generar el enemigo
    print("GameplayService: Generando enemigo para nivel", self.gameState.currentLevel, "¿Es jefe?", isBoss)
    
    -- Primero intentar el método normal de generación de enemigo
    local enemySuccess = false
    if typeof(enemyService.generateEnemy) == "function" then
        if enemyService:generateEnemy(self.gameState.currentLevel, isBoss) then
            self.gameState.enemyGenerated = true
            enemySuccess = true
            print("GameplayService: Enemigo generado correctamente")
        end
    end
    
    -- Si falló, intentar crear un enemigo de manera manual
    if not enemySuccess then
        print("GameplayService: Generando enemigo mediante método alternativo")
        
        -- Configurar datos del enemigo manualmente
        enemyService.health = 100
        enemyService.maxHealth = 100
        enemyService.defense = 0
        enemyService.damage = 10
        enemyService.currentEnemy = {
            type = "SLIME",
            name = "Slime",
            description = "Un slime básico",
            attacks = {"TACKLE"}
        }
        
        -- Crear modelo visual manualmente
        if typeof(enemyService.createEnemyVisual) == "function" then
            enemyService:createEnemyVisual("SLIME")
            self.gameState.enemyGenerated = true
            enemySuccess = true
            print("GameplayService: Enemigo creado mediante método alternativo")
        else
            -- Último recurso: crear un modelo visual muy básico
            local enemyModel = Instance.new("Model")
            enemyModel.Name = "Enemy_SLIME"
            
            local mainPart = Instance.new("Part")
            mainPart.Shape = Enum.PartType.Ball
            mainPart.Size = Vector3.new(5, 5, 5)
            mainPart.Position = Vector3.new(0, 7, -10)
            mainPart.Anchored = true
            mainPart.CanCollide = false
            mainPart.Color = Color3.fromRGB(0, 200, 0)
            mainPart.Material = Enum.Material.SmoothPlastic
            
            local healthLabel = Instance.new("BillboardGui")
            healthLabel.Size = UDim2.new(0, 200, 0, 50)
            healthLabel.StudsOffset = Vector3.new(0, 3, 0)
            healthLabel.Adornee = mainPart
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = "Slime: 100/100"
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.TextSize = 18
            textLabel.Parent = healthLabel
            
            healthLabel.Parent = mainPart
            mainPart.Parent = enemyModel
            enemyModel.Parent = workspace
            
            enemyService.healthLabel = textLabel
            enemyService.enemyModel = enemyModel
            
            self.gameState.enemyGenerated = true
            enemySuccess = true
            print("GameplayService: Creado modelo de enemigo básico de emergencia")
        end
    end
    
    -- PASO 4: Inicializar orbes si el servicio está disponible
    if orbService and playerService then
        print("GameplayService: Inicializando pool de orbes")
        orbService:initializeBattlePool(playerService)
    elseif not orbService then
        print("GameplayService: OrbService no disponible, creando servicio básico")
        
        local success, OrbService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("OrbService"))
        end)
        
        if success and OrbService then
            orbService = OrbService.new(self.serviceLocator, self.eventBus)
            self.serviceLocator:RegisterService("OrbService", orbService)
            orbService:Initialize()
            
            if playerService then
                orbService:initializeBattlePool(playerService)
            else
                -- Inicializar con valores por defecto
                orbService.orbPoolForBattle = {"BASIC", "BASIC", "BASIC"}
            end
            
            print("GameplayService: OrbService creado e inicializado correctamente")
        end
    end
    
    -- PASO 5: Configurar interfaz si el servicio está disponible
    if uiService and typeof(uiService.setupBattleUI) == "function" then
        uiService:setupBattleUI()
    end
    
    -- Publicar evento de encuentro configurado
    self.eventBus:Publish("EncounterSetupCompleted", self.gameState.currentLevel, self.gameState.currentEncounter)
    
    -- Cambiar a fase de turno del jugador con un pequeño retraso para asegurar que todo esté listo
    spawn(function()
        wait(0.5) -- Pequeña pausa para asegurar que todo se ha inicializado
        self:changePhase("PLAYER_TURN")
    end)
    
    return true
end


-- Cambia la fase actual del juego
function GameplayService:changePhase(newPhase)
    local oldPhase = self.gameState.currentPhase
    self.gameState.currentPhase = newPhase
    
    print("GameplayService: Cambiando fase: " .. oldPhase .. " -> " .. newPhase)
    
    -- Publicar evento de cambio de fase
    self.eventBus:Publish("PhaseChanged", oldPhase, newPhase)
    
    -- Lógica específica para cada fase
    if newPhase == "PLAYER_TURN" then
        self.eventBus:Publish("PlayerTurnStarted")
        self.gameState.turnCount = self.gameState.turnCount + 1
        
        -- Seleccionar el siguiente orbe si es necesario
        local orbService = self.serviceLocator:GetService("OrbService")
        if orbService then
            orbService:selectNextOrb()
        end
    elseif newPhase == "ENEMY_TURN" then
        self.eventBus:Publish("EnemyTurnStarted")
        
        -- Simulación simple del turno del enemigo
        spawn(function()
            wait(2) -- Esperar 2 segundos para simular el turno del enemigo
            self.eventBus:Publish("EnemyTurnCompleted")
        end)
    elseif newPhase == "REWARD" then
        self.eventBus:Publish("RewardPhaseStarted")
    elseif newPhase == "GAME_OVER" then
        self.eventBus:Publish("GameOverStarted", self.gameState.battleResult)
    end
    
    return true
end

-- Función modificada launchOrb para GameplayService.lua
-- Reemplaza la función actual para manejar mejor el caso cuando OrbService no está disponible
-- Modificación de GameplayService para asegurar una mejor respuesta al cliente

-- Asegúrate de añadir estas modificaciones al GameplayService.lua existente
-- Reemplaza la función launchOrb para que tenga un mejor manejo de errores:

function GameplayService:launchOrb(direction)
    print("GameplayService: Ejecutando launchOrb con dirección:", direction)
    
    -- Intentar obtener OrbService
    local orbService = self.serviceLocator:GetService("OrbService")
    
    -- Si no existe, intentamos crear uno básico
    if not orbService then
        print("GameplayService: OrbService no encontrado, creando uno básico...")
        
        local success, OrbService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("OrbService"))
        end)
        
        if success and OrbService then
            orbService = OrbService.new(self.serviceLocator, self.eventBus)
            self.serviceLocator:RegisterService("OrbService", orbService)
            orbService:Initialize()
            print("GameplayService: OrbService básico creado correctamente")
        else
            warn("GameplayService: No se pudo crear OrbService: ", OrbService)
        end
    end
    
    -- Intentar obtener PhysicsService (opcional)
    local physicsService = self.serviceLocator:GetService("PhysicsService")
    
    -- Verificar si tenemos OrbService después del intento de creación
    if not orbService then
        warn("GameplayService: No se pudo obtener OrbService, creando orbe directo")
        
        -- Crear un orbe básico directamente sin OrbService como último recurso
        local basicOrb = Instance.new("Part")
        basicOrb.Name = "PeglinOrb_Fallback"
        basicOrb.Shape = Enum.PartType.Ball
        basicOrb.Size = Vector3.new(2.5, 2.5, 2.5)
        basicOrb.Position = Vector3.new(0, 15, 0)
        basicOrb.Color = Color3.fromRGB(255, 255, 0)
        basicOrb.Material = Enum.Material.Neon
        basicOrb.Anchored = false
        basicOrb.CanCollide = true
        basicOrb.CustomPhysicalProperties = PhysicalProperties.new(
            1.5,   -- Densidad
            0.4,   -- Fricción
            0.7,   -- Elasticidad
            0.6,   -- Peso
            0.6    -- Fricción rotacional
        )
        
        -- Añadir efectos visuales mínimos
        local light = Instance.new("PointLight")
        light.Brightness = 0.8
        light.Range = 8
        light.Color = Color3.fromRGB(255, 255, 0)
        light.Parent = basicOrb
        
        -- Añadir estela
        local attachment = Instance.new("Attachment")
        attachment.Parent = basicOrb
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.4),
            NumberSequenceKeypoint.new(1, 1)
        })
        trail.Lifetime = 0.5
        trail.Parent = basicOrb
        
        basicOrb.Parent = workspace
        
        -- Aplicar física directamente
        local baseSpeed = 35 -- Velocidad predeterminada si no está Config
        local initialVelocity = direction * baseSpeed
        
        -- Aplicar impulso
        basicOrb:ApplyImpulse(initialVelocity * basicOrb:GetMass())
        print("GameplayService: Creado y lanzado orbe básico como fallback")
        
        -- Configurar listener de colisión básico
        local function onTouched(hitPart)
            -- Si golpea algo con el atributo IsPeg
            if hitPart:GetAttribute("IsPeg") then
                print("GameplayService: Orbe golpeó una clavija:", hitPart.Name)
                
                -- Verificar si hay BoardService para registrar el golpe
                local boardService = self.serviceLocator:GetService("BoardService")
                if boardService then
                    boardService:registerPegHit(hitPart)
                end
                
                -- Aplicar daño directo al enemigo como fallback
                local enemyService = self.serviceLocator:GetService("EnemyService")
                if enemyService then
                    local damage = 10
                    if hitPart:GetAttribute("IsCritical") then
                        damage = 25
                    end
                    
                    local killed = enemyService:takeDamage(damage, "NORMAL")
                    print("GameplayService: Aplicado daño directo:", damage)
                end
            end
        end
        
        basicOrb.Touched:Connect(onTouched)
        
        -- Publicar evento de orbe lanzado con información básica
        self.eventBus:Publish("OrbLaunched", basicOrb, {type = "BASIC", name = "Orbe Básico"})
        return true
    end
    
    -- Obtener información del orbe actual
    local currentOrb = orbService:getCurrentOrbInfo()
    
    -- Si no hay un orbe visual activo, crear uno
    if not orbService.activeOrbVisual then
        local entryPoint = Vector3.new(0, 15, 0) -- Posición por defecto
        
        -- Intentar obtener un punto de entrada del BoardService si está disponible
        local boardService = self.serviceLocator:GetService("BoardService")
        if boardService and boardService.entryPoints and #boardService.entryPoints > 0 then
            local selectedEntry = boardService.entryPoints[math.random(1, #boardService.entryPoints)]
            if selectedEntry then
                local launchPos = selectedEntry:GetAttribute("LaunchPosition")
                if launchPos then
                    entryPoint = launchPos
                end
            end
        end
        
        -- Crear el orbe visual
        orbService:createOrbVisual(currentOrb, entryPoint)
    end
    
    -- Obtener el orbe visual
    local orbVisual = orbService.activeOrbVisual
    
    if not orbVisual then
        warn("GameplayService: No hay orbe visual para lanzar")
        return false
    end
    
    -- Usar PhysicsService para aplicar el lanzamiento si está disponible
    if physicsService then
        physicsService:launchOrb(orbVisual, direction or Vector3.new(0, -1, 0))
    else
        -- Aplicar física directamente como fallback
        local baseSpeed = 35 -- Valor por defecto si Config no está disponible
        if type(require) == "function" then
            local success, Config = pcall(function()
                return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))
            end)
            if success and Config and Config.PHYSICS and Config.PHYSICS.BALL_SPEED then
                baseSpeed = Config.PHYSICS.BALL_SPEED
            end
        end
        
        local initialVelocity = (direction or Vector3.new(0, -1, 0)) * baseSpeed
        
        -- Aplicar impulso
        orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
        print("GameplayService: Aplicado impulso directo al orbe:", initialVelocity)
    end
    
    -- Publicar evento de orbe lanzado
    self.eventBus:Publish("OrbLaunched", orbVisual, currentOrb)
    print("GameplayService: Evento OrbLaunched publicado")
    
    return true
end
-- Asegúrate de añadir esta nueva función para manejar el evento OrbLaunchRequested
function GameplayService:handleOrbLaunchRequest(direction, position)
    print("GameplayService: Recibido evento OrbLaunchRequested")
    return self:launchOrb(direction)
end

-- Maneja cuando se gana una batalla
function GameplayService:handleBattleWon(enemyType, position)
    self.gameState.battleResult = "WIN"
    
    -- Dar tiempo para efectos visuales de victoria
    wait(1)
    
    -- Cambiar a fase de recompensa
    self:changePhase("REWARD")
end

-- Maneja cuando se pierde una batalla
function GameplayService:handleBattleLost()
    self.gameState.battleResult = "LOSE"
    
    -- Dar tiempo para efectos visuales de derrota
    wait(1)
    
    -- Cambiar a fase de juego terminado
    self:changePhase("GAME_OVER")
end

-- Maneja cuando un orbe se pierde (cae fuera del tablero)
function GameplayService:handleOrbLost(reason)
    -- Verificar si hay más orbes
    local orbService = self.serviceLocator:GetService("OrbService")
    
    if not orbService then
        warn("GameplayService: No se pudo obtener OrbService")
        return
    end
    
    if orbService.orbPoolForBattle and #orbService.orbPoolForBattle == 0 then
        -- No hay más orbes, cambiar al turno del enemigo
        wait(1) -- Esperar un poco para que el jugador vea lo que pasó
        self:changePhase("ENEMY_TURN")
    else
        -- Hay más orbes, continuar turno del jugador
        self.eventBus:Publish("PlayerTurnContinued")
    end
end

-- Maneja cuando un orbe se detiene
function GameplayService:handleOrbStopped()
    -- Similar a handleOrbLost
    self:handleOrbLost("STOPPED")
end

-- Avanza al siguiente encuentro
function GameplayService:advanceToNextEncounter()
    -- Obtener servicio de jugador
    local playerService = self.serviceLocator:GetService("PlayerService")
    
    if not playerService then
        warn("GameplayService: No se pudo obtener PlayerService")
        return false
    end
    
    -- Avanzar progresión del jugador
    local completedLevel = playerService:advanceProgress()
    
    -- Actualizar estado del juego con la nueva información
    self.gameState.currentLevel = playerService.progression.currentLevel
    self.gameState.currentEncounter = playerService.progression.currentEncounter
    
    if completedLevel then
        -- Completó el nivel, mostrar pantalla de nivel
        self.eventBus:Publish("LevelCompleted", playerService.progression.completedLevels[#playerService.progression.completedLevels])
    else
        -- Solo pasó al siguiente encuentro, preparar nuevo encuentro
        wait(1)
        self:setupEncounter()
    end
    
    return true
end

-- Limpieza del servicio
function GameplayService:Cleanup()
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Limpiar estado del juego
    self.gameState = {
        currentPhase = "NONE",
        turnCount = 0,
        battleResult = nil,
        boardGenerated = false,
        enemyGenerated = false,
        currentLevel = nil,
        currentEncounter = 0,
    }
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return GameplayService