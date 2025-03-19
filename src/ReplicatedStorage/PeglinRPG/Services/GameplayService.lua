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
    
    -- Suscribirse a eventos
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
    
    -- NUEVO: Recibir evento de clic para lanzar desde el cliente
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("PlayerClickedToLaunch", function(direction)
        print("GameplayService: Recibida solicitud de lanzamiento desde el cliente con dirección:", direction)
        self:launchOrb(direction)
    end))
    
    -- NUEVO: Añadir un evento de prueba para verificar la comunicación
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("TestEvent", function(message)
        print("GameplayService: Evento de prueba recibido con mensaje:", message)
    end))
    
    print("GameplayService: Inicializado correctamente")
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
    
    -- Configurar primer encuentro
    self:setupEncounter()
    
    return true
end

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
    
    -- Generar enemigo (ahora obligatorio)
    print("GameplayService: Generando enemigo para nivel", self.gameState.currentLevel, "¿Es jefe?", isBoss)
    if not enemyService:generateEnemy(self.gameState.currentLevel, isBoss) then
        warn("GameplayService: Error al generar enemigo a través de enemyService:generateEnemy")
        
        -- Intento alternativo de generación
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
        
        -- Crear modelo visual manualmente si falla el método normal
        if typeof(enemyService.createEnemyVisual) == "function" then
            enemyService:createEnemyVisual("SLIME")
            print("GameplayService: Enemigo creado mediante método alternativo")
            self.gameState.enemyGenerated = true
        else
            warn("GameplayService: No se pudo crear enemigo por métodos alternativos")
            return false
        end
    else
        self.gameState.enemyGenerated = true
        print("GameplayService: Enemigo generado correctamente mediante enemyService:generateEnemy")
    end
    
    -- Generar tablero (si no hay BoardService, fallar)
    if not boardService then
        warn("GameplayService: BoardService no está disponible")
        return false
    end
    
    -- Configuración del tablero
    local boardConfig = {
        theme = self.gameState.currentLevel,
        pegColors = levelConfig.PEG_COLORS or {BrickColor.new("Bright blue")},
        backgroundColor = levelConfig.BACKGROUND_COLOR or Color3.fromRGB(30, 30, 50),
    }
    
    local boardWidth = Config.BOARD.WIDTH or 60
    local boardHeight = Config.BOARD.HEIGHT or 70
    local boardPegCount = Config.BOARD.DEFAULT_PEG_COUNT or 120
    
    -- Generar tablero
    local board = boardService:generateBoard(boardWidth, boardHeight, boardPegCount, boardConfig)
    if board then
        self.gameState.boardGenerated = true
        print("GameplayService: Tablero generado correctamente")
    else
        warn("GameplayService: Error al generar tablero")
        return false
    end
    
    -- Inicializar orbes si el servicio está disponible
    if orbService and playerService then
        orbService:initializeBattlePool(playerService)
    end
    
    -- Configurar interfaz si el servicio está disponible
    if uiService then
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

-- Maneja el lanzamiento de un orbe
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
        warn("GameplayService: No se pudo obtener OrbService")
        
        -- Crear un orbe básico directamente sin OrbService como último recurso
        local basicOrb = Instance.new("Part")
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
        basicOrb.Parent = workspace
        
        -- Aplicar física directamente
        local baseSpeed = 35 -- Velocidad predeterminada si no está Config
        local initialVelocity = direction * baseSpeed
        
        -- Aplicar impulso
        basicOrb:ApplyImpulse(initialVelocity * basicOrb:GetMass())
        print("GameplayService: Creado y lanzado orbe básico como fallback")
        
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