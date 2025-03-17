-- PeglinRPG_Initializer.lua
-- Script principal que inicializa el juego y organiza los módulos

-- Servicios de Roblox
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Crear estructura de carpetas para el juego
local function setupGameStructure()
	-- Carpeta principal para el juego
	local peglinFolder = Instance.new("Folder")
	peglinFolder.Name = "PeglinRPG"
	peglinFolder.Parent = ReplicatedStorage

	print("PeglinRPG: Configurando estructura del juego...")

	return peglinFolder
end

-- Crear los módulos del juego
local function createModules(parentFolder)
	-- Carpeta que contendrá todos los módulos
	local modulesFolder = parentFolder

	-- Crear los módulos principales
	local moduleNames = {
		"Config",
		"PlayerManager",
		"EnemyManager",
		"OrbManager",
		"BoardManager",
		"GameplayManager"
	}

	-- Crear los módulos
	local modules = {}

	for _, moduleName in ipairs(moduleNames) do
		local moduleScript = Instance.new("ModuleScript")
		moduleScript.Name = moduleName
		moduleScript.Source = ("-- " .. moduleName .. ".lua\nreturn {}")
		moduleScript.Parent = modulesFolder

		modules[moduleName] = moduleScript
		print("PeglinRPG: Creado módulo " .. moduleName)
	end

	-- Establecer contenido del módulo Config
	local configModule = modules["Config"]
	configModule.Source = [[
-- Config.lua: Configuración central del juego

local Config = {}

-- Configuración del juego
Config.GAME = {
    TITLE = "Peglin RPG",
    VERSION = "0.1",
    DEBUG_MODE = true,
}

-- Configuración de la física
Config.PHYSICS = {
    BALL_SPEED = 35,
    BOUNCE_REDUCTION = 0.9,
    MIN_BOUNCE_VELOCITY = 5,
    GRAVITY = 130,
    BALL_ELASTICITY = 0.8,
    BALL_DENSITY = 1.2,
    BALL_WEIGHT = 0.4,
    BALL_FRICTION = 0.3,
}

-- Configuración del tablero
Config.BOARD = {
    WIDTH = 40,
    HEIGHT = 50,
    DEFAULT_PEG_COUNT = 60,
    MIN_PEG_DISTANCE = 3.5,
}

-- Configuración del combate
Config.COMBAT = {
    BASE_DAMAGE = 10,
    CRITICAL_MULTIPLIER = 2.5,
    MAX_BALLS_PER_TURN = 3,
    ENEMY_ATTACK_DAMAGE = 15,
    PLAYER_STARTING_HEALTH = 100,
    ENEMY_STARTING_HEALTH = 100,
}

-- Configuración de orbes (tipos de bolas)
Config.ORBS = {
    BASIC = {
        NAME = "Orbe Básico",
        DESCRIPTION = "Un orbe básico que causa daño normal.",
        COLOR = Color3.fromRGB(255, 255, 0),
        DAMAGE_MODIFIER = 1.0,
        SPECIAL_EFFECT = nil,
    },
    FIRE = {
        NAME = "Orbe de Fuego",
        DESCRIPTION = "Incendia al enemigo, causando daño a lo largo del tiempo.",
        COLOR = Color3.fromRGB(255, 100, 0),
        DAMAGE_MODIFIER = 0.8,
        SPECIAL_EFFECT = "DOT", -- Damage over time
        DOT_DAMAGE = 5,
        DOT_DURATION = 3,
    },
    ICE = {
        NAME = "Orbe de Hielo",
        DESCRIPTION = "Ralentiza al enemigo, reduciendo su daño.",
        COLOR = Color3.fromRGB(100, 200, 255),
        DAMAGE_MODIFIER = 0.7,
        SPECIAL_EFFECT = "SLOW",
        SLOW_AMOUNT = 0.3,
        SLOW_DURATION = 2,
    },
    LIGHTNING = {
        NAME = "Orbe Eléctrico",
        DESCRIPTION = "Golpea varias clavijas a la vez con electricidad.",
        COLOR = Color3.fromRGB(180, 180, 255),
        DAMAGE_MODIFIER = 0.6,
        SPECIAL_EFFECT = "CHAIN",
        CHAIN_COUNT = 3,
        CHAIN_RADIUS = 5,
    },
    VOID = {
        NAME = "Orbe del Vacío",
        DESCRIPTION = "Causa daño que ignora la defensa del enemigo.",
        COLOR = Color3.fromRGB(150, 0, 150),
        DAMAGE_MODIFIER = 1.2,
        SPECIAL_EFFECT = "PENETRATE",
    },
}

-- Configuración de enemigos
Config.ENEMIES = {
    SLIME = {
        NAME = "Slime",
        HEALTH = 100,
        DAMAGE = 10,
        DEFENSE = 0,
        ATTACKS = {"TACKLE", "BOUNCE"},
        IMAGE = "rbxassetid://7228448649",
        DESCRIPTION = "Un slime básico que rebota de forma impredecible.",
    },
    GOBLIN = {
        NAME = "Goblin",
        HEALTH = 80,
        DAMAGE = 15,
        DEFENSE = 5,
        ATTACKS = {"SLASH", "DEFEND", "THROW"},
        IMAGE = "rbxassetid://7228469546",
        DESCRIPTION = "Un goblin astuto que alterna entre ataque y defensa.",
    },
    SKELETON = {
        NAME = "Esqueleto",
        HEALTH = 70,
        DAMAGE = 20,
        DEFENSE = 0,
        ATTACKS = {"BONE_THROW", "REASSEMBLE"},
        IMAGE = "rbxassetid://7228438496",
        DESCRIPTION = "Un esqueleto que puede reensamblarse después de recibir daño.",
    },
    ORC = {
        NAME = "Orco",
        HEALTH = 150,
        DAMAGE = 25,
        DEFENSE = 10,
        ATTACKS = {"SMASH", "ROAR", "BLOCK"},
        IMAGE = "rbxassetid://7228469982",
        DESCRIPTION = "Un orco poderoso con mucha salud y fuerza.",
    },
}

-- Configuración de reliquias (mejoras pasivas)
Config.RELICS = {
    HEART_STONE = {
        NAME = "Piedra Corazón",
        DESCRIPTION = "Aumenta la salud máxima en 20.",
        EFFECT = "MAX_HEALTH",
        VALUE = 20,
        RARITY = "COMMON",
    },
    DAMAGE_CRYSTAL = {
        NAME = "Cristal de Daño",
        DESCRIPTION = "Aumenta el daño base en 5.",
        EFFECT = "BASE_DAMAGE",
        VALUE = 5,
        RARITY = "COMMON",
    },
    LUCKY_CLOVER = {
        NAME = "Trébol de la Suerte",
        DESCRIPTION = "Aumenta la probabilidad de golpes críticos en 10%.",
        EFFECT = "CRIT_CHANCE",
        VALUE = 0.1,
        RARITY = "UNCOMMON",
    },
    MIRROR_SHARD = {
        NAME = "Fragmento de Espejo",
        DESCRIPTION = "20% de probabilidad de duplicar el daño de un golpe.",
        EFFECT = "REFLECT_CHANCE",
        VALUE = 0.2,
        RARITY = "RARE",
    },
    PHOENIX_FEATHER = {
        NAME = "Pluma de Fénix",
        DESCRIPTION = "Revive una vez con 50% de salud cuando mueres.",
        EFFECT = "REVIVE",
        VALUE = 0.5,
        RARITY = "LEGENDARY",
        ONE_TIME_USE = true,
    },
}

-- Configuración de niveles
Config.LEVELS = {
    FOREST = {
        NAME = "Bosque Encantado",
        BACKGROUND_COLOR = Color3.fromRGB(50, 100, 50),
        ENEMY_POOL = {"SLIME", "GOBLIN"},
        PEG_COLORS = {
            BrickColor.new("Bright green"),
            BrickColor.new("Forest green"),
            BrickColor.new("Lime green"),
        },
        ENCOUNTERS = 5,
        BOSS = "ORC",
    },
    DUNGEON = {
        NAME = "Mazmorra Oscura",
        BACKGROUND_COLOR = Color3.fromRGB(70, 70, 90),
        ENEMY_POOL = {"GOBLIN", "SKELETON"},
        PEG_COLORS = {
            BrickColor.new("Dark stone grey"),
            BrickColor.new("Medium stone grey"),
            BrickColor.new("Institutional white"),
        },
        ENCOUNTERS = 5,
        BOSS = "NECROMANCER",
    },
}

return Config
]]

	return modules
end

-- Crear interfaz de usuario para el juego
local function createMainMenu(parentFolder)
	-- Esta función crearía la interfaz principal del juego
	-- Implementación simplificada para este ejemplo

	local menu = Instance.new("ScreenGui")
	menu.Name = "PeglinRPG_MainMenu"

	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
	background.BackgroundTransparency = 0.2
	background.Parent = menu

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 500, 0, 100)
	title.Position = UDim2.new(0.5, -250, 0.2, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 255, 100)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 48
	title.Text = "PEGLIN RPG"
	title.Parent = background

	local startButton = Instance.new("TextButton")
	startButton.Size = UDim2.new(0, 300, 0, 60)
	startButton.Position = UDim2.new(0.5, -150, 0.6, 0)
	startButton.BackgroundColor3 = Color3.fromRGB(50, 100, 50)
	startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	startButton.Font = Enum.Font.GothamBold
	startButton.TextSize = 24
	startButton.Text = "Iniciar Juego"
	startButton.Parent = background

	-- Guardar referencia al botón de inicio para configurarlo después
	menu.StartButton = startButton

	return menu
end

-- Inicializar el juego completo
local function initializeGame()
	print("Inicializando PeglinRPG...")

	-- Establecer gravedad personalizada
	workspace.Gravity = 130

	-- Configurar estructura del juego
	local gameFolder = setupGameStructure()

	-- Crear los módulos
	local modules = createModules(gameFolder)

	-- Crear interfaces
	local mainMenu = createMainMenu(gameFolder)

	-- Configurar lógica del juego
	local function setupGameLogic()
		-- Cargar módulos
		local Config = require(modules.Config)

		-- Crear LocalScript para manejar el cliente
		local clientHandler = Instance.new("LocalScript")
		clientHandler.Name = "PeglinRPG_ClientHandler"

		clientHandler.Source = [[
            local Players = game:GetService("Players")
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            
            local player = Players.LocalPlayer
            local gameModules = ReplicatedStorage:WaitForChild("PeglinRPG")
            
            local GameplayManager = require(gameModules:WaitForChild("GameplayManager"))
            
            -- Obtener la interfaz principal
            local mainMenu = script.Parent
            
            -- Configurar el botón de inicio
            mainMenu.StartButton.MouseButton1Click:Connect(function()
                print("Iniciando juego...")
                
                -- Ocultar menú principal
                mainMenu.Enabled = false
                
                -- Iniciar juego
                local gameManager = GameplayManager.new()
                gameManager:startNewGame()
            end)
            
            -- Configurar controles de juego
            local UserInputService = game:GetService("UserInputService")
            
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    -- Esta lógica será manejada por el GameplayManager
                end
            end)
        ]]

		clientHandler.Parent = mainMenu

		-- Configurar la cámara inicial
		local function setupCamera()
			local camera = workspace.CurrentCamera
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.new(Vector3.new(0, 5, 30), Vector3.new(0, 0, 0))
		end

		local cameraScript = Instance.new("LocalScript")
		cameraScript.Name = "CameraSetup"
		cameraScript.Source = [[
            local camera = workspace.CurrentCamera
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = CFrame.new(Vector3.new(0, 5, 30), Vector3.new(0, 0, 0))
        ]]
		cameraScript.Parent = mainMenu
	end

	-- Configurar la lógica del juego
	setupGameLogic()

	-- Mostrar menú principal cuando un jugador se une
	local function onPlayerJoined(player)
		wait(1) -- Dar tiempo para que el jugador cargue completamente
		mainMenu.Parent = player.PlayerGui
	end

	-- Conectar a evento de jugador
	Players.PlayerAdded:Connect(onPlayerJoined)

	-- También para jugadores que ya están en el juego
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerJoined(player)
	end

	print("PeglinRPG inicializado correctamente!")
end

-- Ejecutar el inicializador
initializeGame()