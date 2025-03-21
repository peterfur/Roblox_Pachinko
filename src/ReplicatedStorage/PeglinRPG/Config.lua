-- Config.lua: Configuración central del juego

local Config = {}

-- Configuración del juego
Config.GAME = {
	TITLE = "Peglin RPG",
	VERSION = "0.1",
	DEBUG_MODE = true,
}

-- Configuración de PHYSICS optimizada para evitar que las bolas se escapen y mejorar el feedback

Config.PHYSICS = {
    BALL_SPEED = 32,         -- Velocidad base ligeramente reducida para mayor control
    BOUNCE_REDUCTION = 0.8,  -- Mayor reducción de rebote para evitar rebotes infinitos
    MIN_BOUNCE_VELOCITY = 2, -- Velocidad mínima reducida para detectar antes cuando se detiene
    GRAVITY = 100,           -- Gravedad reducida para movimiento más predecible
    BALL_ELASTICITY = 0.6,   -- Elasticidad reducida para evitar rebotes excesivos
    BALL_DENSITY = 2.5,      -- Densidad aumentada para mayor estabilidad
    BALL_WEIGHT = 1.0,       -- Peso aumentado para reducir rebotes erráticos
    BALL_FRICTION = 0.2,     -- Fricción reducida para facilitar el movimiento
    
    -- ARREGLO: Nuevos parámetros para mejor comportamiento
    COLLISION_COOLDOWN = 0.1,   -- Tiempo mínimo entre colisiones repetidas con el mismo objeto
    COLLISION_FORCE = 1.2,      -- Multiplicador de fuerza en colisiones
    STUCK_CHECK_DELAY = 0.5,    -- Tiempo para verificar si un orbe está atascado
    STUCK_VELOCITY_THRESHOLD = 1.0, -- Umbral de velocidad para considerar un orbe atascado
    AUTO_UNSTUCK_FORCE = 5.0,   -- Fuerza para desatascar automáticamente un orbe
    
    -- ARREGLO: Parámetros para garantizar que siempre haga daño
    MIN_GUARANTEED_DAMAGE = 10, -- Daño mínimo que siempre se aplicará aunque no golpee nada
    DAMAGE_TIMEOUT_SECONDS = 3, -- Tiempo después del cual se garantiza daño si no ha golpeado nada
}
-- Configuración del tablero
Config.BOARD = {
	WIDTH = 60,
	HEIGHT = 70,
	DEFAULT_PEG_COUNT = 120,
	MIN_PEG_DISTANCE = 3.2,
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
Config.PEG_TYPES = {
    STANDARD = {
        SIZE = Vector3.new(0.5, 2, 0.5),
        MAX_HITS = 2
    },
    BALL = {
        SIZE = Vector3.new(1, 1, 1),  -- Tamaño de la clavija esférica
        SPAWN_CHANCE = 20,  -- 20% de probabilidad de ser esférica
        BOUNCE_BONUS = 1.2,  -- Bonus de rebote para clavijas esféricas
        MAX_HITS = 2
    },
    BUMPER = {
        DAMAGE_MULTIPLIER = 1.5,
        MAX_HITS = 1
    }
}
-- Configuración de elementos del tablero
Config.BOARD_ELEMENTS = {
    BUMPERS = {
        MIN_COUNT = 3,
        MAX_COUNT = 6,
        SIZE = 3,
        BOUNCE_FORCE = 1.5
    },
    INTERNAL_WALLS = {
        MIN_COUNT = 1,
        MAX_COUNT = 3,
        MIN_LENGTH = 10,
        MAX_LENGTH = 20
    },
    MULTIPLIER_ZONES = {
        MIN_COUNT = 1,
        MAX_COUNT = 3,
        SIZE = 8,
        MIN_MULTIPLIER = 2,
        MAX_MULTIPLIER = 4
    },
    SPEED_LANES = {
        MIN_COUNT = 1,
        MAX_COUNT = 3,
        SEGMENT_COUNT = 6,
        SPEED_BOOST = 1.5
    },
    TELEPORT_PORTALS = {
        MIN_PAIRS = 0,
        MAX_PAIRS = 2,
        SIZE = 4
    }
}

return Config