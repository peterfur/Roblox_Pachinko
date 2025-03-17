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