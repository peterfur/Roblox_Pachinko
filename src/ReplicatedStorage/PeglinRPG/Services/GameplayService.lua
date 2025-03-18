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

-- Inicialización del servicio
function GameplayService:Initialize()
    ServiceInterface.Initialize(self)
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("PlayerClickedToLaunch", function(direction)
        print("GameplayService: Recibida solicitud de lanzamiento desde el cliente")
        self:launchOrb(direction)
    end))
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
    
    -- Configurar primer encuentro
    self:setupEncounter()
    
    return true
end

-- Configura un nuevo encuentro
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
    
    -- Verificar servicios críticos
    if not (playerService and enemyService and boardService and orbService) then
        warn("GameplayService: No se pudieron obtener todos los servicios necesarios")
        return false
    end
    
    -- Determinar si es un jefe
    local isBoss = false
    if playerService.progression then
        isBoss = self.gameState.currentEncounter == playerService.progression.totalEncounters
    end
    
    -- Obtener configuración del nivel actual
    local levelConfig = Config.LEVELS[self.gameState.currentLevel]
    
    -- Generar enemigo
    if not enemyService:generateEnemy(self.gameState.currentLevel, isBoss) then
        warn("GameplayService: Error al generar enemigo")
        return false
    end
    self.gameState.enemyGenerated = true
    
    -- Generar tablero
    if not boardService then
        warn("GameplayService: BoardService no está disponible")
        return false
    end
    
    local boardConfig = {
        theme = self.gameState.currentLevel,
        pegColors = levelConfig.PEG_COLORS,
        backgroundColor = levelConfig.BACKGROUND_COLOR,
    }
    
    local boardWidth = Config.BOARD.WIDTH
    local boardHeight = Config.BOARD.HEIGHT
    local boardPegCount = Config.BOARD.DEFAULT_PEG_COUNT
    
    local board = boardService:generateBoard(boardWidth, boardHeight, boardPegCount, boardConfig)
    if not board then
        warn("GameplayService: Error al generar tablero")
        return false
    end
    self.gameState.boardGenerated = true
    
    -- Inicializar orbes para esta batalla
    orbService:initializeBattlePool(playerService)
    
    -- Configurar interfaz
    if uiService then
        uiService:setupBattleUI()
    end
    
    -- Publicar evento de encuentro configurado
    self.eventBus:Publish("EncounterSetupCompleted", self.gameState.currentLevel, self.gameState.currentEncounter)
    
    -- Cambiar a fase de turno del jugador
    self:changePhase("PLAYER_TURN")
    
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
    elseif newPhase == "ENEMY_TURN" then
        self.eventBus:Publish("EnemyTurnStarted")
    elseif newPhase == "REWARD" then
        self.eventBus:Publish("RewardPhaseStarted")
    elseif newPhase == "GAME_OVER" then
        self.eventBus:Publish("GameOverStarted", self.gameState.battleResult)
    end
    
    return true
end

-- Maneja el lanzamiento de un orbe
function GameplayService:launchOrb(direction)
    -- Obtener servicio de orbes
    local orbService = self.serviceLocator:GetService("OrbService")
    local physicsService = self.serviceLocator:GetService("PhysicsService")
    
    if not orbService then
        warn("GameplayService: No se pudo obtener OrbService")
        return false
    end
    
    -- Obtener información del orbe actual
    local currentOrb = orbService:getCurrentOrbInfo()
    
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
        local baseSpeed = Config.PHYSICS.BALL_SPEED or 35
        local initialVelocity = (direction or Vector3.new(0, -1, 0)) * baseSpeed
        
        -- Aplicar impulso
        orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
    end
    
    -- Publicar evento de orbe lanzado
    self.eventBus:Publish("OrbLaunched", orbVisual, currentOrb)
    
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
    
    if #orbService.orbPoolForBattle == 0 then
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