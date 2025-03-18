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

-- Función corregida de lanzamiento con manejo de errores mejorado
function GameplayManager:launchOrb()
    -- Verificar que tenemos un orbe para lanzar
    if not self.visualElements.currentOrbVisual then
        print("No hay orbe para lanzar")
        return false
    end
    
    -- ARREGLO: Verificar que tenemos puntos de entrada válidos
    if not self.boardManager or not self.boardManager.entryPoints then
        warn("BoardManager o entryPoints no están disponibles")
        
        -- Lanzamiento de emergencia desde una posición fija
        local orbVisual = self.visualElements.currentOrbVisual
        orbVisual.Position = Vector3.new(0, 20, 0)
        
        -- Dirección hacia abajo con componente aleatorio
        local angle = math.rad(math.random(-15, 15))
        local direction = Vector3.new(math.sin(angle), -math.cos(angle), 0)
        
        -- Aplicar impulso de emergencia
        local baseSpeed = 35
        local initialVelocity = direction * baseSpeed
        orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
        
        -- Configurar colisiones y continuar
        local currentOrb = self.orbManager:getCurrentOrbInfo()
        self.combatManager:setupOrbCollisions(orbVisual, currentOrb)
        self.visualElements.currentOrbVisual = nil
        self.uiManager:updateUI()
        
        return true
    end
    
    -- Verificar que hay entryPoints disponibles
    if #self.boardManager.entryPoints == 0 then
        warn("No hay puntos de entrada disponibles")
        
        -- Mismo código de emergencia que arriba
        local orbVisual = self.visualElements.currentOrbVisual
        orbVisual.Position = Vector3.new(0, 20, 0)
        
        -- Dirección hacia abajo con componente aleatorio
        local angle = math.rad(math.random(-15, 15))
        local direction = Vector3.new(math.sin(angle), -math.cos(angle), 0)
        
        -- Aplicar impulso de emergencia
        local baseSpeed = 35
        local initialVelocity = direction * baseSpeed
        orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
        
        -- Configurar colisiones y continuar
        local currentOrb = self.orbManager:getCurrentOrbInfo()
        self.combatManager:setupOrbCollisions(orbVisual, currentOrb)
        self.visualElements.currentOrbVisual = nil
        self.uiManager:updateUI()
        
        return true
    end
    
    -- ARREGLO: Seleccionar aleatoriamente uno de los tubos de lanzamiento con mejor validación
    local entryPointIndex = math.random(1, #self.boardManager.entryPoints)
    local entryPoint = self.boardManager.entryPoints[entryPointIndex]
    
    -- Verificar que el entryPoint existe y tiene posición
    if not entryPoint then
        warn("Punto de entrada no válido en índice: " .. entryPointIndex)
        
        -- Usar el primer punto de entrada disponible o fallar con elegancia
        entryPoint = self.boardManager.entryPoints[1]
        if not entryPoint then
            warn("No se pudo encontrar un punto de entrada válido")
            
            -- Código de emergencia similar a lo anterior
            local orbVisual = self.visualElements.currentOrbVisual
            orbVisual.Position = Vector3.new(0, 20, 0)
            
            -- Aplicar impulso de emergencia
            local direction = Vector3.new(0, -1, 0)
            local baseSpeed = 35
            local initialVelocity = direction * baseSpeed
            orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
            
            -- Configurar colisiones y continuar
            local currentOrb = self.orbManager:getCurrentOrbInfo()
            self.combatManager:setupOrbCollisions(orbVisual, currentOrb)
            self.visualElements.currentOrbVisual = nil
            self.uiManager:updateUI()
            
            return true
        end
    end
    
    -- VERIFICAR QUE EL PUNTO DE ENTRADA TIENE LA PROPIEDAD POSITION
    local entryPosition
    if entryPoint:GetAttribute("LaunchPosition") then
        -- Obtener posición desde el atributo si existe
        local posX = entryPoint:GetAttribute("LaunchPositionX") or 0
        local posY = entryPoint:GetAttribute("LaunchPositionY") or 20
        local posZ = entryPoint:GetAttribute("LaunchPositionZ") or 0
        entryPosition = Vector3.new(posX, posY, posZ)
    elseif entryPoint.Position then
        -- Usar directamente la propiedad Position si existe
        entryPosition = entryPoint.Position
    else
        -- Posición de respaldo si no se encuentra ninguna
        warn("El punto de entrada no tiene una posición válida, usando posición por defecto")
        entryPosition = Vector3.new(0, 20, 0)
    end
    
    -- ARREGLO: Configurar ángulos específicos para cada tubo para asegurar que las bolas caigan correctamente
    local angleRanges = {
        {min = -30, max = -10},  -- Tubo izquierdo: ángulos hacia la derecha
        {min = -15, max = 15},   -- Tubo central: ángulos más centrados
        {min = 10, max = 30}     -- Tubo derecho: ángulos hacia la izquierda
    }
    
    -- Usar un rango por defecto si entryPointIndex está fuera de rango
    local angleRange = angleRanges[entryPointIndex] or {min = -15, max = 15}
    local angle = math.rad(math.random(angleRange.min, angleRange.max))
    
    -- ARREGLO: Vector de dirección ajustado para asegurar que el orbe baje al tablero
    local direction = Vector3.new(math.sin(angle), -math.cos(angle), 0)
    
    print("Lanzando orbe desde tubo " .. entryPointIndex .. " con ángulo " .. math.deg(angle))
    
    -- ARREGLO: Crear efecto de pre-lanzamiento (con validación)
    local function preLaunchEffect()
        -- Validar que todo existe antes de crear efectos
        if not entryPosition then return end
        
        -- Crear un destello en el tubo
        local flash = Instance.new("Part")
        flash.Shape = Enum.PartType.Ball
        flash.Size = Vector3.new(3, 3, 3)
        flash.Position = entryPosition
        flash.Anchored = true
        flash.CanCollide = false
        flash.Transparency = 0.3
        flash.Material = Enum.Material.Neon
        
        -- Color basado en el orbe actual
        local currentOrb = self.orbManager:getCurrentOrbInfo()
        if currentOrb and currentOrb.color then
            flash.Color = currentOrb.color
        else
            flash.Color = Color3.fromRGB(255, 255, 255)
        end
        flash.Parent = workspace
        
        -- Animación del destello
        spawn(function()
            for i = 1, 8 do
                if not flash or not flash.Parent then break end
                flash.Size = Vector3.new(3 + i*0.2, 3 + i*0.2, 3 + i*0.2)
                flash.Transparency = 0.3 + (i * 0.08)
                wait(0.02)
            end
            if flash and flash.Parent then
                flash:Destroy()
            end
        end)
        
        -- Sonido de lanzamiento
        local launchSound = Instance.new("Sound")
        launchSound.SoundId = "rbxassetid://1080752200" -- Sonido whoosh
        launchSound.Volume = 0.8
        launchSound.PlaybackSpeed = math.random(95, 105) / 100
        
        -- Verificar que entryPoint existe antes de asignar parent
        if typeof(entryPoint) == "Instance" and entryPoint.Parent then
            launchSound.Parent = entryPoint
        else
            launchSound.Parent = workspace
        end
        
        launchSound:Play()
        
        -- Auto-destrucción del sonido
        game:GetService("Debris"):AddItem(launchSound, 2)
    end
    
    -- Ejecutar efecto de pre-lanzamiento (protegido contra errores)
    pcall(function() 
        preLaunchEffect() 
    end)
    
    -- Obtener el orbe actual y posicionarlo en el punto de lanzamiento
    local orbVisual = self.visualElements.currentOrbVisual
    
    -- Verificar que el orbe existe antes de continuar
    if not orbVisual or not orbVisual.Parent then
        warn("El orbe visual no existe o ha perdido su referencia")
        return false
    end
    
    -- Posicionar el orbe de manera segura
    orbVisual.Position = entryPosition
    
    -- ARREGLO: Dar tiempo para que el efecto sea visible antes del lanzamiento
    wait(0.1)
    
    -- Obtener información del orbe actual
    local currentOrb = self.orbManager:getCurrentOrbInfo()
    
    -- ARREGLO: Ajustar velocidad de lanzamiento para una experiencia más consistente
    local baseSpeed = 35
    if Config and Config.PHYSICS and Config.PHYSICS.BALL_SPEED then
        baseSpeed = Config.PHYSICS.BALL_SPEED
    end
    
    -- Calcular velocidad inicial
    local initialVelocity = direction * baseSpeed
    
    -- ARREGLO: Reducir el factor aleatorio para más consistencia pero mantener algo de variabilidad
    local randomFactor = 0.01
    local randomOffset = Vector3.new(
        (math.random() * 2 - 1) * randomFactor,
        (math.random() * 2 - 1) * randomFactor,
        0
    )
    
    initialVelocity = initialVelocity + (randomOffset * baseSpeed)
    
    -- ARREGLO: Asegurar que la masa del orbe es correcta para la física
    if orbVisual:GetMass() < 0.1 then
        -- Prevenir problemas con masas muy pequeñas
        orbVisual:SetMass(1)
    end
    
    -- ARREGLO: Aplicar impulso con mejor física y manejo de errores
    local success, errorMsg = pcall(function()
        orbVisual:ApplyImpulse(initialVelocity * orbVisual:GetMass())
        
        -- ARREGLO: Añadir un pequeño torque controlado para giro natural
        local torqueMagnitude = 3 -- Reducido para un giro más controlado
        orbVisual:ApplyAngularImpulse(Vector3.new(
            math.random(-torqueMagnitude, torqueMagnitude), 
            math.random(-torqueMagnitude, torqueMagnitude), 
            math.random(-torqueMagnitude * 3, torqueMagnitude * 3) -- Mayor en Z para giro visible
        ))
    end)
    
    if not success then
        warn("Error al aplicar física al orbe: " .. tostring(errorMsg))
        
        -- Alternativa si ApplyImpulse falla - establecer velocidad directamente
        orbVisual.Velocity = initialVelocity
    end

    -- Disparar eventos
    if #self.events.onOrbLaunched > 0 then
        for _, callback in ipairs(self.events.onOrbLaunched) do
            pcall(function() 
                callback(currentOrb, direction) 
            end)
        end
    end

    -- ARREGLO: Configurar detección de colisiones
    if self.combatManager then
        pcall(function() 
            self.combatManager:setupOrbCollisions(orbVisual, currentOrb) 
        end)
    else
        warn("CombatManager no disponible")
    end
    
    -- Limpiar referencia (ahora se controlará por física)
    self.visualElements.currentOrbVisual = nil

    -- Actualizar UI
    if self.uiManager then
        pcall(function() 
            self.uiManager:updateUI() 
        end)
    end

    -- ARREGLO: Añadir efecto visual de lanzamiento mejorado
    pcall(function()
        local launchEffect = Instance.new("Part")
        launchEffect.Shape = Enum.PartType.Ball
        launchEffect.Size = Vector3.new(1, 1, 1)
        launchEffect.Position = entryPosition
        launchEffect.Anchored = true
        launchEffect.CanCollide = false
        launchEffect.Transparency = 0.3
        launchEffect.Material = Enum.Material.Neon
        launchEffect.Color = orbVisual.Color
        launchEffect.Parent = workspace
        
        spawn(function()
            for i = 1, 12 do
                if not launchEffect or not launchEffect.Parent then break end
                launchEffect.Size = Vector3.new(1 + i*0.3, 1 + i*0.3, 1 + i*0.3)
                launchEffect.Transparency = 0.3 + (i * 0.06)
                
                -- Mover levemente en dirección del lanzamiento de manera segura
                if launchEffect and launchEffect.Parent then
                    launchEffect.Position = entryPosition + (direction * i * 0.2)
                end
                
                wait(0.02)
            end
            if launchEffect and launchEffect.Parent then
                launchEffect:Destroy()
            end
        end)
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