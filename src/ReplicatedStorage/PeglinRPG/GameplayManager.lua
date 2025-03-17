-- GameplayManager.lua: Gestor central que coordina todos los submódulos

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Importar configuración
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Importar gestores
local PlayerManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("PlayerManager"))
local EnemyManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("EnemyManager"))
local OrbManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("OrbManager"))
local BoardManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("BoardManager"))

-- Importar submódulos del gestor de gameplay
local UIManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Gameplay"):WaitForChild("UIManager"))
local CombatManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Gameplay"):WaitForChild("CombatManager"))
local RewardManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Gameplay"):WaitForChild("RewardManager"))
local EffectsManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Gameplay"):WaitForChild("EffectsManager"))
local PhaseManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Gameplay"):WaitForChild("PhaseManager"))

local GameplayManager = {}
GameplayManager.__index = GameplayManager

-- Constructor del gestor de gameplay
function GameplayManager.new()
	local self = setmetatable({}, GameplayManager)

	-- Instanciar subsistemas principales
	self.playerManager = PlayerManager.new()
	self.orbManager = OrbManager.new()
	self.boardManager = BoardManager.new()
	self.enemyManager = nil -- Se crea por cada encuentro

	-- Estado del juego
	self.gameState = { 
		currentPhase = "NONE", -- NONE, SETUP, PLAYER_TURN, ENEMY_TURN, REWARD, GAME_OVER
		turnCount = 0,
		battleResult = nil, -- WIN, LOSE
		boardGenerated = false,
		enemyGenerated = false,
		currentLevel = nil,
		currentEncounter = 0,
	}

	-- Referencias a objetos visuales
	self.visualElements = {
		playerUI = nil,
		boardModel = nil,
		enemyModel = nil,
		currentOrbVisual = nil,
	}

	-- Sistema de eventos
	self.events = {
		onPhaseChanged = {},
		onDamageDealt = {},
		onOrbLaunched = {},
		onBattleCompleted = {},
		onLevelCompleted = {},
	}

	-- Inicializar submódulos con referencia a este gestor
	self.uiManager = UIManager.new(self)
	self.combatManager = CombatManager.new(self)
	self.rewardManager = RewardManager.new(self)
	self.effectsManager = EffectsManager.new(self)
	self.phaseManager = PhaseManager.new(self)

	return self
end

-- Inicializa un nuevo juego
function GameplayManager:startNewGame()
	print("Iniciando nuevo juego de Peglin RPG...")

	-- Restablecer subsistemas
	self.playerManager = PlayerManager.new()
	self.orbManager = OrbManager.new()
	self.boardManager = BoardManager.new()

	-- Configurar estado inicial
	self.gameState.currentPhase = "SETUP"
	self.gameState.turnCount = 0
	self.gameState.battleResult = nil
	self.gameState.boardGenerated = false
	self.gameState.enemyGenerated = false
	self.gameState.currentLevel = "FOREST"
	self.gameState.currentEncounter = 1

	-- Iniciar primer encuentro
	self:setupEncounter()

	return true
end

-- Configura un nuevo encuentro
-- Modificación de la función setupEncounter para asegurar la creación de un nuevo enemigo
function GameplayManager:setupEncounter()
	print("Configurando encuentro:", self.gameState.currentEncounter)

	-- Limpiar el enemigo anterior si existe
	if self.visualElements.enemyModel then
		self.visualElements.enemyModel:Destroy()
		self.visualElements.enemyModel = nil
	end

	-- Limpiar el tablero anterior si existe
	if self.visualElements.boardModel then
		self.visualElements.boardModel:Destroy()
		self.visualElements.boardModel = nil
	end

	-- Determinar si es un jefe
	local isBoss = self.gameState.currentEncounter == self.playerManager.progression.totalEncounters

	-- Obtener configuración del nivel actual
	local levelConfig = Config.LEVELS[self.playerManager.progression.currentLevel]

	-- Generar enemigo (crear un nuevo enemigo para cada encuentro)
	if isBoss then
		self.enemyManager = EnemyManager.new(levelConfig.BOSS, true)
	else
		local enemyPool = levelConfig.ENEMY_POOL
		local randomEnemy = enemyPool[math.random(1, #enemyPool)]
		self.enemyManager = EnemyManager.new(randomEnemy, false)
	end

	-- Generar tablero con tema del nivel
	local boardConfig = {
		theme = self.playerManager.progression.currentLevel,
		pegColors = levelConfig.PEG_COLORS,
		backgroundColor = levelConfig.BACKGROUND_COLOR,
	}

	self.visualElements.boardModel = self.boardManager:generateBoard(
		Config.BOARD.WIDTH, 
		Config.BOARD.HEIGHT, 
		Config.BOARD.DEFAULT_PEG_COUNT,
		boardConfig
	)

	self.gameState.boardGenerated = true

	-- Visualizar enemigo
	self.visualElements.enemyModel = self.enemyManager:createVisual(workspace)
	self.gameState.enemyGenerated = true

	-- Inicializar orbes para esta batalla
	self.orbManager:initializeBattlePool(self.playerManager)

	-- Configurar interfaz
	self.visualElements.playerUI = self.uiManager:setupBattleUI()

	-- Cambiar a fase de turno del jugador
	self:changePhase("PLAYER_TURN")

	return true
end

-- Cambia la fase actual del juego
function GameplayManager:changePhase(newPhase)
	-- Delegar al gestor de fases
	return self.phaseManager:changePhase(newPhase)
end

-- Maneja el lanzamiento de un orbe
-- Modificación de la función launchOrb en GameplayManager para hacerla más robusta

function GameplayManager:launchOrb(direction)
	-- Verificar si estamos en la fase correcta y si hay un orbe visual
	if self.gameState.currentPhase ~= "PLAYER_TURN" then
		print("No se puede lanzar el orbe: No es el turno del jugador (fase actual: " .. self.gameState.currentPhase .. ")")
		return false
	end
	
	if not self.visualElements.currentOrbVisual then
		print("No se puede lanzar el orbe: No hay un orbe visual disponible")
		
		-- Intentar recuperar si hay un nuevo orbe disponible
		if #self.orbManager.orbPoolForBattle > 0 then
			print("Intentando seleccionar nuevo orbe...")
			self.phaseManager:startPlayerTurn()
		else
			print("No hay más orbes disponibles")
		end
		
		return false
	end

	print("Lanzando orbe en dirección:", direction)

	-- Obtener el orbe actual
	local currentOrb = self.orbManager:getCurrentOrbInfo()
	local orbVisual = self.visualElements.currentOrbVisual

	-- Aplicar impulso inicial
	local normalizedDir = direction.Unit
	local initialVelocity = normalizedDir * Config.PHYSICS.BALL_SPEED

	-- Añadir un pequeño componente aleatorio para más variedad
	local randomFactor = 0.05 -- Factor aleatorio pequeño
	local randomOffset = Vector3.new(
		(math.random() * 2 - 1) * randomFactor,
		(math.random() * 2 - 1) * randomFactor,
		0
	)
	
	initialVelocity = initialVelocity + randomOffset

	-- Aplicar fuerza al orbe
	orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
	
	-- Añadir un pequeño torque (giro) para comportamiento más realista
	orbVisual:ApplyAngularImpulse(Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5)))

	-- Disparar eventos
	for _, callback in ipairs(self.events.onOrbLaunched) do
		callback(currentOrb, direction)
	end

	-- Configurar detección de colisiones a través del gestor de combate
	self.combatManager:setupOrbCollisions(orbVisual, currentOrb)

	-- Limpiar referencia (ahora se controlará por física)
	self.visualElements.currentOrbVisual = nil

	-- Actualizar UI
	self.uiManager:updateUI()

	-- Añadir efecto visual de lanzamiento
	local launchEffect = Instance.new("Part")
	launchEffect.Shape = Enum.PartType.Ball
	launchEffect.Size = Vector3.new(1, 1, 1)
	launchEffect.Position = orbVisual.Position
	launchEffect.Anchored = true
	launchEffect.CanCollide = false
	launchEffect.Transparency = 0.5
	launchEffect.Material = Enum.Material.Neon
	launchEffect.Color = orbVisual.Color
	launchEffect.Parent = workspace
	
	-- Animar el efecto de lanzamiento
	spawn(function()
		for i = 1, 10 do
			launchEffect.Size = Vector3.new(1 + i*0.3, 1 + i*0.3, 1 + i*0.3)
			launchEffect.Transparency = 0.5 + (i * 0.05)
			wait(0.03)
		end
		launchEffect:Destroy()
	end)

	return true
end

-- Registra un callback para un evento
function GameplayManager:registerEvent(eventName, callback)
	if self.events[eventName] then
		table.insert(self.events[eventName], callback)
		return true
	end
	return false
end

-- Desregistra un callback de un evento
function GameplayManager:unregisterEvent(eventName, callback)
	if self.events[eventName] then
		for i, cb in ipairs(self.events[eventName]) do
			if cb == callback then
				table.remove(self.events[eventName], i)
				return true
			end
		end
	end
	return false
end

return GameplayManager