-- EnemyManager.lua: Gestiona los enemigos y su comportamiento

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local EnemyManager = {}
EnemyManager.__index = EnemyManager

-- Constructor del gestor de enemigos
function EnemyManager.new(enemyType, isBoss)
	local self = setmetatable({}, EnemyManager)

	-- Si no se especifica, seleccionar aleatoriamente del nivel actual
	if not enemyType then
		local playerManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("PlayerManager"))
		local currentLevel = playerManager.progression.currentLevel
		local levelConfig = Config.LEVELS[currentLevel]

		if isBoss then
			enemyType = levelConfig.BOSS
		else
			local enemyPool = levelConfig.ENEMY_POOL
			enemyType = enemyPool[math.random(1, #enemyPool)]
		end
	end

	-- Obtener datos del enemigo
	local enemyData = Config.ENEMIES[enemyType]

	if not enemyData then
		warn("Tipo de enemigo no encontrado:", enemyType)
		enemyData = Config.ENEMIES.SLIME -- Enemigo por defecto
	end

	-- Propiedades del enemigo
	self.type = enemyType
	self.name = enemyData.NAME
	self.health = enemyData.HEALTH
	self.maxHealth = enemyData.HEALTH
	self.damage = enemyData.DAMAGE
	self.defense = enemyData.DEFENSE
	self.attacks = enemyData.ATTACKS
	self.image = enemyData.IMAGE
	self.description = enemyData.DESCRIPTION
	self.isBoss = isBoss or false

	-- Modificadores (para efectos temporales)
	self.modifiers = {
		damageMultiplier = 1.0,
		defenseMultiplier = 1.0,
	}

	-- Efectos activos
	self.activeEffects = {}

	-- Comportamiento y estado
	self.state = {
		nextAttack = nil,
		turnsToNextAction = 1,
		isStunned = false,
		isBurning = false,
		isSlowed = false,
	}

	-- Si es un jefe, aumentar stats
	if self.isBoss then
		self.health = self.health * 2
		self.maxHealth = self.maxHealth * 2
		self.damage = self.damage * 1.5
	end

	return self
end

-- Aplica daño al enemigo, teniendo en cuenta defensas
function EnemyManager:takeDamage(amount, damageType)
	-- Calcular defensa efectiva
	local effectiveDefense = self.defense * self.modifiers.defenseMultiplier

	-- Algunos tipos de daño ignoran defensa
	if damageType == "PENETRATE" then
		effectiveDefense = 0
	end

	-- Calcular daño real
	local actualDamage = math.max(1, amount - effectiveDefense)

	-- Aplicar daño
	self.health = math.max(0, self.health - actualDamage)

	-- Verificar si murió
	if self.health <= 0 then
		return true, actualDamage -- Murió
	end

	return false, actualDamage -- Sigue vivo
end

-- Aplica un efecto de estado al enemigo
function EnemyManager:applyEffect(effectType, duration, value)
	-- Validar parámetros
	if not effectType then return false end
	duration = duration or 2
	value = value or 0.5

	-- Aplicar efecto según tipo
	if effectType == "STUN" then
		-- Aturdir al enemigo
		self.state.isStunned = true

		-- Añadir a efectos activos
		table.insert(self.activeEffects, {
			type = "STUN",
			remaining = duration,
			value = value,
			tick = function(self)
				self.remaining = self.remaining - 1
				if self.remaining <= 0 then
					self.state.isStunned = false
					return true -- Efecto terminado
				end
				return false -- Efecto continúa
			end
		})

	elseif effectType == "BURN" or effectType == "DOT" then
		-- Efecto de daño a lo largo del tiempo
		self.state.isBurning = true

		-- Añadir a efectos activos
		table.insert(self.activeEffects, {
			type = "BURN",
			remaining = duration,
			value = value, -- Daño por turno
			tick = function(self, enemy)
				enemy:takeDamage(self.value, "DOT")
				self.remaining = self.remaining - 1
				if self.remaining <= 0 then
					self.state.isBurning = false
					return true -- Efecto terminado
				end
				return false -- Efecto continúa
			end
		})

	elseif effectType == "SLOW" then
		-- Ralentizar al enemigo (reducir daño)
		self.state.isSlowed = true
		self.modifiers.damageMultiplier = self.modifiers.damageMultiplier * (1 - value)

		-- Añadir a efectos activos
		table.insert(self.activeEffects, {
			type = "SLOW",
			remaining = duration,
			value = value,
			originalModifier = self.modifiers.damageMultiplier / (1 - value),
			tick = function(self, enemy)
				self.remaining = self.remaining - 1
				if self.remaining <= 0 then
					-- Restaurar multiplicador original
					enemy.modifiers.damageMultiplier = self.originalModifier
					enemy.state.isSlowed = false
					return true -- Efecto terminado
				end
				return false -- Efecto continúa
			end
		})

	elseif effectType == "WEAK" then
		-- Debilitar defensa
		self.modifiers.defenseMultiplier = self.modifiers.defenseMultiplier * (1 - value)

		-- Añadir a efectos activos
		table.insert(self.activeEffects, {
			type = "WEAK",
			remaining = duration,
			value = value,
			originalModifier = self.modifiers.defenseMultiplier / (1 - value),
			tick = function(self, enemy)
				self.remaining = self.remaining - 1
				if self.remaining <= 0 then
					-- Restaurar multiplicador original
					enemy.modifiers.defenseMultiplier = self.originalModifier
					return true -- Efecto terminado
				end
				return false -- Efecto continúa
			end
		})

	end

	return true
end

-- Procesa los efectos activos al final del turno
function EnemyManager:processEffects()
	local effectsToRemove = {}

	-- Procesar cada efecto activo
	for i, effect in ipairs(self.activeEffects) do
		-- Llamar a la función de tick del efecto
		local completed = effect.tick(effect, self)

		-- Si el efecto se completó, marcarlo para eliminar
		if completed then
			table.insert(effectsToRemove, i)
		end
	end

	-- Eliminar efectos completados (en orden inverso para no afectar índices)
	for i = #effectsToRemove, 1, -1 do
		table.remove(self.activeEffects, effectsToRemove[i])
	end
end

-- Decide el próximo ataque
function EnemyManager:decideNextAttack()
	-- Si está aturdido, no puede atacar
	if self.state.isStunned then
		self.state.nextAttack = "STUNNED"
		return "STUNNED", 0
	end

	-- Seleccionar un ataque de su pool
	local attackIndex = math.random(1, #self.attacks)
	local attackType = self.attacks[attackIndex]

	-- Determinar daño según tipo de ataque
	local damage = 0

	if attackType == "TACKLE" or attackType == "SLASH" or attackType == "BONE_THROW" or attackType == "SMASH" then
		-- Ataques ofensivos
		damage = self.damage * self.modifiers.damageMultiplier

	elseif attackType == "BOUNCE" then
		-- Ataque con daño variable
		damage = self.damage * self.modifiers.damageMultiplier * (math.random(80, 120) / 100)

	elseif attackType == "DEFEND" or attackType == "BLOCK" then
		-- Ataques defensivos
		self.modifiers.defenseMultiplier = self.modifiers.defenseMultiplier * 1.5
		damage = 0

	elseif attackType == "ROAR" then
		-- Buff de daño
		self.modifiers.damageMultiplier = self.modifiers.damageMultiplier * 1.2
		damage = 0

	elseif attackType == "REASSEMBLE" then
		-- Curación
		local healAmount = math.floor(self.maxHealth * 0.15)
		self.health = math.min(self.maxHealth, self.health + healAmount)
		damage = 0

	elseif attackType == "THROW" then
		-- Ataque con chance de aturdir
		damage = self.damage * self.modifiers.damageMultiplier * 0.8
		-- 20% de probabilidad de aturdir al jugador
		if math.random(1, 100) <= 20 then
			-- Lógica para aturdir al jugador (implementar en el gameplay)
		end
	end

	-- Redondear el daño
	damage = math.floor(damage)

	-- Guardar el ataque decidido
	self.state.nextAttack = attackType
	self.state.attackDamage = damage

	return attackType, damage
end

-- Ejecuta el ataque decidido anteriormente
function EnemyManager:executeAttack()
	local attackType = self.state.nextAttack
	local damage = self.state.attackDamage or 0

	-- Resetear para el próximo turno
	self.state.nextAttack = nil
	self.state.attackDamage = nil

	return attackType, damage
end

-- Crea una representación visual del enemigo
function EnemyManager:createVisual(parent)
	local enemyModel = Instance.new("Model")
	enemyModel.Name = self.name

	-- Cuerpo principal del enemigo
	local mainPart = Instance.new("Part")
	mainPart.Name = "MainPart"
	mainPart.Size = Vector3.new(5, 5, 5)
	mainPart.Position = Vector3.new(0, 5, -30)
	mainPart.Anchored = true
	mainPart.CanCollide = false

	-- Aspecto visual según tipo
	if self.type == "SLIME" then
		mainPart.Shape = Enum.PartType.Ball
		mainPart.Color = Color3.fromRGB(0, 200, 100)
		mainPart.Material = Enum.Material.SmoothPlastic
		mainPart.Transparency = 0.2
	elseif self.type == "GOBLIN" then
		mainPart.Shape = Enum.PartType.Block
		mainPart.Color = Color3.fromRGB(50, 150, 50)
		mainPart.Material = Enum.Material.SmoothPlastic

		-- Añadir detalles al goblin
		local head = Instance.new("Part")
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(2, 2, 2)
		head.Position = Vector3.new(0, 6.5, -30)
		head.Anchored = true
		head.CanCollide = false
		head.Color = Color3.fromRGB(50, 150, 50)
		head.Parent = enemyModel
	elseif self.type == "SKELETON" then
		mainPart.Shape = Enum.PartType.Block
		mainPart.Color = Color3.fromRGB(240, 240, 240)
		mainPart.Material = Enum.Material.Marble

		-- Añadir cráneo
		local skull = Instance.new("Part")
		skull.Shape = Enum.PartType.Ball
		skull.Size = Vector3.new(2, 2, 2)
		skull.Position = Vector3.new(0, 6.5, -30)
		skull.Anchored = true
		skull.CanCollide = false
		skull.Color = Color3.fromRGB(240, 240, 240)
		skull.Parent = enemyModel
	elseif self.type == "ORC" then
		mainPart.Shape = Enum.PartType.Block
		mainPart.Size = Vector3.new(7, 7, 7)
		mainPart.Color = Color3.fromRGB(100, 100, 50)
		mainPart.Material = Enum.Material.SmoothPlastic

		-- Añadir detalles al orco
		local head = Instance.new("Part")
		head.Shape = Enum.PartType.Ball
		head.Size = Vector3.new(3, 3, 3)
		head.Position = Vector3.new(0, 8, -30)
		head.Anchored = true
		head.CanCollide = false
		head.Color = Color3.fromRGB(100, 100, 50)
		head.Parent = enemyModel
	else
		-- Enemigo genérico
		mainPart.Color = Color3.fromRGB(150, 50, 50)
	end

	mainPart.Parent = enemyModel
	enemyModel.PrimaryPart = mainPart

	-- Crear barra de salud
	local healthBarBackground = Instance.new("Part")
	healthBarBackground.Size = Vector3.new(6, 0.5, 0.1)
	healthBarBackground.Position = Vector3.new(0, 8, -30)
	healthBarBackground.Anchored = true
	healthBarBackground.CanCollide = false
	healthBarBackground.Color = Color3.fromRGB(50, 50, 50)
	healthBarBackground.Transparency = 0.5
	healthBarBackground.Parent = enemyModel

	local healthBar = Instance.new("Part")
	healthBar.Size = Vector3.new(6, 0.4, 0.05)
	healthBar.Position = Vector3.new(0, 8, -29.95)
	healthBar.Anchored = true
	healthBar.CanCollide = false
	healthBar.Color = Color3.fromRGB(200, 50, 50)
	healthBar.Name = "HealthBar"
	healthBar.Parent = enemyModel

	-- Etiqueta con nombre y salud
	local nameLabel = Instance.new("BillboardGui")
	nameLabel.Size = UDim2.new(0, 100, 0, 40)
	nameLabel.StudsOffset = Vector3.new(0, 9, 0)
	nameLabel.Adornee = mainPart
	nameLabel.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = self.name .. "\n" .. self.health .. "/" .. self.maxHealth
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Name = "NameHealthLabel"
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = nameLabel

	nameLabel.Parent = enemyModel

	-- Función para actualizar la barra de salud
	self.updateHealthBar = function()
		local healthRatio = self.health / self.maxHealth
		healthBar.Size = Vector3.new(6 * healthRatio, 0.4, 0.05)
		healthBar.Position = Vector3.new(0 - (6 * (1 - healthRatio))/2, 8, -29.95)

		textLabel.Text = self.name .. "\n" .. self.health .. "/" .. self.maxHealth

		-- Cambiar color según la salud
		if healthRatio < 0.3 then
			healthBar.Color = Color3.fromRGB(255, 50, 50) -- Rojo intenso
		elseif healthRatio < 0.6 then
			healthBar.Color = Color3.fromRGB(255, 150, 50) -- Naranja
		else
			healthBar.Color = Color3.fromRGB(200, 50, 50) -- Rojo normal
		end
	end

	-- Mostrar efectos activos
	self.updateEffects = function()
		-- Limpiar efectos visuales anteriores
		for _, child in pairs(enemyModel:GetChildren()) do
			if child.Name == "EffectIndicator" then
				child:Destroy()
			end
		end

		-- Crear nuevos indicadores para cada efecto activo
		local offsetX = -2
		for _, effect in ipairs(self.activeEffects) do
			local effectPart = Instance.new("Part")
			effectPart.Shape = Enum.PartType.Ball
			effectPart.Size = Vector3.new(0.8, 0.8, 0.8)
			effectPart.Position = Vector3.new(offsetX, 7, -29.5)
			effectPart.Anchored = true
			effectPart.CanCollide = false
			effectPart.Name = "EffectIndicator"

			-- Color según el tipo de efecto
			if effect.type == "BURN" or effect.type == "DOT" then
				effectPart.Color = Color3.fromRGB(255, 100, 0)
			elseif effect.type == "STUN" then
				effectPart.Color = Color3.fromRGB(255, 255, 0)
			elseif effect.type == "SLOW" then
				effectPart.Color = Color3.fromRGB(100, 200, 255)
			elseif effect.type == "WEAK" then
				effectPart.Color = Color3.fromRGB(150, 0, 150)
			end

			effectPart.Material = Enum.Material.Neon
			effectPart.Parent = enemyModel

			-- Añadir etiqueta con duración
			local durationLabel = Instance.new("BillboardGui")
			durationLabel.Size = UDim2.new(0, 20, 0, 20)
			durationLabel.StudsOffset = Vector3.new(0, 0, 0)
			durationLabel.Adornee = effectPart
			durationLabel.AlwaysOnTop = true

			local durationText = Instance.new("TextLabel")
			durationText.Size = UDim2.new(1, 0, 1, 0)
			durationText.BackgroundTransparency = 1
			durationText.TextScaled = true
			durationText.Font = Enum.Font.GothamBold
			durationText.Text = tostring(effect.remaining)
			durationText.TextColor3 = Color3.fromRGB(255, 255, 255)
			durationText.Parent = durationLabel

			durationLabel.Parent = effectPart

			offsetX = offsetX + 1.2
		end
	end

	-- Posicionar en el espacio de juego
	if parent then
		enemyModel.Parent = parent
	else
		enemyModel.Parent = workspace
	end

	return enemyModel
end

return EnemyManager