-- OrbManager.lua: Gestiona los diferentes tipos de orbes y sus efectos

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local OrbManager = {}
OrbManager.__index = OrbManager

-- Constructor del gestor de orbes
function OrbManager.new()
	local self = setmetatable({}, OrbManager)

	-- Propiedades
	self.currentOrb = nil
	self.orbPoolForBattle = {} -- Orbes disponibles en esta batalla

	return self
end

-- Inicializa el pool de orbes para una batalla
function OrbManager:initializeBattlePool(playerManager)
	self.orbPoolForBattle = {}

	-- Copiar todos los orbes del jugador al pool de batalla
	for _, orbData in ipairs(playerManager.inventory.orbs) do
		for i = 1, orbData.count do
			table.insert(self.orbPoolForBattle, orbData.type)
		end
	end

	-- Asegurar que siempre haya al menos un orbe básico
	if #self.orbPoolForBattle == 0 then
		table.insert(self.orbPoolForBattle, "BASIC")
	end

	-- Barajar el pool para que los orbes se seleccionen aleatoriamente
	self:shufflePool()

	return self.orbPoolForBattle
end

-- Baraja el pool de orbes
function OrbManager:shufflePool()
	local n = #self.orbPoolForBattle
	for i = n, 2, -1 do
		local j = math.random(i)
		self.orbPoolForBattle[i], self.orbPoolForBattle[j] = self.orbPoolForBattle[j], self.orbPoolForBattle[i]
	end
end

-- Selecciona el siguiente orbe disponible
function OrbManager:selectNextOrb()
	if #self.orbPoolForBattle == 0 then
		-- Si no hay más orbes, crear uno básico
		self.currentOrb = self:createOrbInstance("BASIC")
	else
		-- Tomar el siguiente orbe del pool
		local nextOrbType = table.remove(self.orbPoolForBattle, 1)
		self.currentOrb = self:createOrbInstance(nextOrbType)
	end

	return self.currentOrb
end

-- Crea una instancia específica de orbe según su tipo
function OrbManager:createOrbInstance(orbType)
	local orbConfig = Config.ORBS[orbType] or Config.ORBS.BASIC

	local orbInstance = {
		type = orbType,
		name = orbConfig.NAME,
		description = orbConfig.DESCRIPTION,
		color = orbConfig.COLOR,
		damageModifier = orbConfig.DAMAGE_MODIFIER,
		specialEffect = orbConfig.SPECIAL_EFFECT,

		-- Propiedades específicas según tipo
		dotDamage = orbConfig.DOT_DAMAGE,
		dotDuration = orbConfig.DOT_DURATION,
		slowAmount = orbConfig.SLOW_AMOUNT,
		slowDuration = orbConfig.SLOW_DURATION,
		chainCount = orbConfig.CHAIN_COUNT,
		chainRadius = orbConfig.CHAIN_RADIUS,

		-- Contador para estadísticas
		pegHits = 0,
		criticalHits = 0,
		totalDamage = 0,
	}

	return orbInstance
end

-- Crea un objeto visual para un orbe
function OrbManager:createOrbVisual(orbInstance, position)
	-- Crear parte física
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2.5, 2.5, 2.5)
	ball.Position = position or Vector3.new(0, 15, 0)

	-- Aplicar color según tipo de orbe
	local color = orbInstance.color
	ball.Color = color
	ball.Material = Enum.Material.Neon

	-- Propiedades físicas
	ball.Anchored = false
	ball.CanCollide = true
	ball.CustomPhysicalProperties = PhysicalProperties.new(
		1.2,   -- Densidad
		0.3,   -- Fricción
		0.8,   -- Elasticidad
		0.4,   -- Peso
		0.5    -- Fricción rotacional
	)

	-- Efectos visuales según tipo
	if orbInstance.type == "FIRE" then
		-- Efecto de fuego
		local fire = Instance.new("Fire")
		fire.Heat = 5
		fire.Size = 3
		fire.Color = Color3.fromRGB(255, 100, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
		fire.Parent = ball

	elseif orbInstance.type == "ICE" then
		-- Efecto de hielo (partículas)
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
		sparkles.LightEmission = 0.5
		sparkles.LightInfluence = 0
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0)
		})
		sparkles.Texture = "rbxassetid://6883806171"
		sparkles.Rate = 20
		sparkles.Lifetime = NumberRange.new(1, 2)
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Parent = ball

	elseif orbInstance.type == "LIGHTNING" then
		-- Efecto eléctrico
		for i = 1, 3 do
			local beam = Instance.new("Beam")
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")

			a0.Position = Vector3.new(0, 0, 0)
			a1.Position = Vector3.new(math.random(-1, 1), math.random(-1, 1), math.random(-1, 1)).Unit * 1.25

			a0.Parent = ball
			a1.Parent = ball

			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Width0 = 0.1
			beam.Width1 = 0.05
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Color = ColorSequence.new(Color3.fromRGB(150, 150, 255))
			beam.Texture = "rbxassetid://6883560644"
			beam.TextureLength = 0.5
			beam.TextureSpeed = 2
			beam.Parent = ball
		end

	elseif orbInstance.type == "VOID" then
		-- Efecto de vacío
		local attachment = Instance.new("Attachment")
		attachment.Parent = ball

		local particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 0, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 0, 50))
		})
		particleEmitter.LightEmission = 0.5
		particleEmitter.LightInfluence = 0
		particleEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 0.25),
			NumberSequenceKeypoint.new(1, 0)
		})
		particleEmitter.Texture = "rbxassetid://6883844004"
		particleEmitter.Rate = 25
		particleEmitter.Lifetime = NumberRange.new(0.5, 1)
		particleEmitter.Speed = NumberRange.new(1, 3)
		particleEmitter.SpreadAngle = Vector2.new(180, 180)
		particleEmitter.Parent = attachment
	end

	-- Efecto de estela para todos los orbes
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, 0)
	attachment0.Parent = ball

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(1, color:Lerp(Color3.fromRGB(255, 255, 255), 0.5))
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.8
	trail.MinLength = 0.1
	trail.MaxLength = 5
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = ball

	-- Sonido al rebotar
	local bounceSound = Instance.new("Sound")
	bounceSound.SoundId = "rbxassetid://283389905"
	bounceSound.Volume = 0.5
	bounceSound.Parent = ball

	-- Etiqueta con nombre del orbe
	local nameLabel = Instance.new("BillboardGui")
	nameLabel.Size = UDim2.new(0, 100, 0, 30)
	nameLabel.StudsOffset = Vector3.new(0, 2, 0)
	nameLabel.Adornee = ball
	nameLabel.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = orbInstance.name
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = nameLabel

	nameLabel.Parent = ball

	ball.Parent = workspace

	return ball, bounceSound
end

-- Procesa un golpe contra una clavija
function OrbManager:processPegHit(orbInstance, pegInstance, enemyManager)
	-- Actualizar estadísticas del orbe
	orbInstance.pegHits = orbInstance.pegHits + 1

	-- Verificar si es un golpe crítico
	local isCritical = pegInstance:GetAttribute("IsCritical") or false
	if isCritical then
		orbInstance.criticalHits = orbInstance.criticalHits + 1
	end

	-- Calcular daño base
	local baseDamage = Config.COMBAT.BASE_DAMAGE * orbInstance.damageModifier
	if isCritical then
		baseDamage = baseDamage * Config.COMBAT.CRITICAL_MULTIPLIER
	end

	-- Aplicar efectos especiales según tipo de orbe
	if orbInstance.specialEffect == "DOT" and orbInstance.dotDamage and orbInstance.dotDuration then
		-- Daño a lo largo del tiempo (fuego)
		enemyManager:applyEffect("BURN", orbInstance.dotDuration, orbInstance.dotDamage)
	end

	if orbInstance.specialEffect == "SLOW" and orbInstance.slowAmount and orbInstance.slowDuration then
		-- Ralentizar enemigo (hielo)
		enemyManager:applyEffect("SLOW", orbInstance.slowDuration, orbInstance.slowAmount)
	end

	if orbInstance.specialEffect == "CHAIN" and orbInstance.chainCount and orbInstance.chainRadius then
		-- Golpear clavijas adicionales (electricidad)
		-- Esta parte necesitaría implementación en la lógica del tablero
		-- para encontrar clavijas cercanas a la golpeada
	end

	if orbInstance.specialEffect == "PENETRATE" then
		-- Ignora defensa (vacío)
		return "PENETRATE", baseDamage
	end

	-- Actualizar daño total causado
	orbInstance.totalDamage = orbInstance.totalDamage + baseDamage

	return "NORMAL", baseDamage
end

-- Obtiene información sobre el orbe actual
function OrbManager:getCurrentOrbInfo()
	if not self.currentOrb then
		return self:createOrbInstance("BASIC")
	end

	return self.currentOrb
end

-- Obtiene conteo de orbes restantes por tipo
function OrbManager:getRemainingOrbCounts()
	local counts = {}

	for _, orbType in ipairs(self.orbPoolForBattle) do
		counts[orbType] = (counts[orbType] or 0) + 1
	end

	return counts
end

return OrbManager