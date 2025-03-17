-- PlayerManager.lua: Gestiona los datos del jugador y su progresión

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local PlayerManager = {}
PlayerManager.__index = PlayerManager

-- Constructor del gestor de jugador
function PlayerManager.new()
	local self = setmetatable({}, PlayerManager)

	-- Estadísticas básicas del jugador
	self.stats = {
		health = Config.COMBAT.PLAYER_STARTING_HEALTH,
		maxHealth = Config.COMBAT.PLAYER_STARTING_HEALTH,
		level = 1,
		experience = 0,
		experienceRequired = 100,
		gold = 0,
	}

	-- Inventario del jugador
	self.inventory = {
		orbs = {
			{type = "BASIC", count = Config.COMBAT.MAX_BALLS_PER_TURN}
		},
		relics = {},
		consumables = {}
	}

	-- Progresión y estado actual
	self.progression = {
		currentLevel = "FOREST",
		completedLevels = {},
		currentEncounter = 1,
		totalEncounters = Config.LEVELS.FOREST.ENCOUNTERS,
	}

	-- Efectos activos sobre el jugador
	self.activeEffects = {}

	return self
end

-- Aplica el daño al jugador, teniendo en cuenta defensas y efectos
function PlayerManager:takeDamage(amount)
	-- Calcula defensa total basada en reliquias
	local defense = 0
	for _, relic in ipairs(self.inventory.relics) do
		if relic.effect == "DEFENSE" then
			defense = defense + relic.value
		end
	end

	-- Reducir el daño en función de la defensa
	local actualDamage = math.max(1, amount - defense)

	-- Verificar si hay reliquias que modifican el daño recibido
	for _, relic in ipairs(self.inventory.relics) do
		if relic.effect == "DAMAGE_REDUCTION" then
			actualDamage = actualDamage * (1 - relic.value)
		end
	end

	-- Redondear el daño
	actualDamage = math.floor(actualDamage)

	-- Aplicar el daño
	self.stats.health = math.max(0, self.stats.health - actualDamage)

	-- Verificar si el jugador murió
	if self.stats.health <= 0 then
		-- Buscar una reliquia de resurrección
		local phoenixIndex = nil
		for i, relic in ipairs(self.inventory.relics) do
			if relic.effect == "REVIVE" and not relic.used then
				phoenixIndex = i
				break
			end
		end

		-- Si hay una reliquia de resurrección, úsala
		if phoenixIndex then
			local relic = self.inventory.relics[phoenixIndex]
			self.stats.health = math.floor(self.stats.maxHealth * relic.value)

			if relic.ONE_TIME_USE then
				relic.used = true
			end

			return false, "REVIVED" -- No murió, se revivió
		else
			return true, "DEAD" -- Murió
		end
	end

	return false, "DAMAGED" -- Está vivo, pero dañado
end

-- Añade experiencia y sube de nivel si es necesario
function PlayerManager:addExperience(amount)
	self.stats.experience = self.stats.experience + amount

	local levelsGained = 0

	-- Mientras la experiencia sea suficiente para un nivel
	while self.stats.experience >= self.stats.experienceRequired do
		self.stats.experience = self.stats.experience - self.stats.experienceRequired
		self.stats.level = self.stats.level + 1
		levelsGained = levelsGained + 1

		-- Aumentar la salud máxima al subir de nivel
		self.stats.maxHealth = self.stats.maxHealth + 10
		self.stats.health = self.stats.maxHealth

		-- Calcular la experiencia necesaria para el siguiente nivel
		self.stats.experienceRequired = math.floor(self.stats.experienceRequired * 1.2)
	end

	return levelsGained > 0, levelsGained
end

-- Añade una reliquia al inventario del jugador
function PlayerManager:addRelic(relicType)
	local relic = Config.RELICS[relicType]
	if not relic then
		warn("Reliquia no encontrada:", relicType)
		return false
	end

	-- Clonar la reliquia para el inventario
	local relicInstance = {
		name = relic.NAME,
		description = relic.DESCRIPTION,
		effect = relic.EFFECT,
		value = relic.VALUE,
		rarity = relic.RARITY,
		type = relicType,
		used = false,
	}

	-- Aplicar efectos inmediatos
	if relic.EFFECT == "MAX_HEALTH" then
		self.stats.maxHealth = self.stats.maxHealth + relic.VALUE
		self.stats.health = self.stats.health + relic.VALUE
	end

	-- Añadir a la colección de reliquias
	table.insert(self.inventory.relics, relicInstance)

	return true
end

-- Añade un orbe al inventario del jugador
function PlayerManager:addOrb(orbType)
	local orb = Config.ORBS[orbType]
	if not orb then
		warn("Orbe no encontrado:", orbType)
		return false
	end

	-- Buscar si ya tenemos este tipo de orbe
	for i, existingOrb in ipairs(self.inventory.orbs) do
		if existingOrb.type == orbType then
			existingOrb.count = existingOrb.count + 1
			return true
		end
	end

	-- Si no existe, añadir nuevo tipo
	table.insert(self.inventory.orbs, {type = orbType, count = 1})
	return true
end

-- Selecciona un orbe para usar (devuelve sus propiedades)
function PlayerManager:selectOrb(orbType)
	-- Si no se especifica un tipo, seleccionar aleatoriamente
	if not orbType then
		-- Crear un pool de todos los orbes disponibles
		local orbPool = {}
		for _, orb in ipairs(self.inventory.orbs) do
			for i = 1, orb.count do
				table.insert(orbPool, orb.type)
			end
		end

		-- Seleccionar aleatoriamente
		if #orbPool > 0 then
			orbType = orbPool[math.random(1, #orbPool)]
		else
			orbType = "BASIC" -- Por defecto, si no hay orbes
		end
	end

	-- Encontrar el orbe seleccionado
	for i, orb in ipairs(self.inventory.orbs) do
		if orb.type == orbType and orb.count > 0 then
			-- Reducir la cantidad
			orb.count = orb.count - 1

			-- Si se acabaron, remover del inventario
			if orb.count <= 0 then
				table.remove(self.inventory.orbs, i)
			end

			-- Devolver una copia de las propiedades del orbe
			local orbProps = Config.ORBS[orbType]
			return {
				type = orbType,
				name = orbProps.NAME,
				description = orbProps.DESCRIPTION,
				color = orbProps.COLOR,
				damageModifier = orbProps.DAMAGE_MODIFIER,
				specialEffect = orbProps.SPECIAL_EFFECT,
				-- Incluir propiedades especiales específicas
				dotDamage = orbProps.DOT_DAMAGE,
				dotDuration = orbProps.DOT_DURATION,
				slowAmount = orbProps.SLOW_AMOUNT,
				slowDuration = orbProps.SLOW_DURATION,
				chainCount = orbProps.CHAIN_COUNT,
				chainRadius = orbProps.CHAIN_RADIUS
			}
		end
	end

	-- Si no encuentra el orbe, devolver el orbe básico
	warn("Orbe no encontrado o se acabaron, usando orbe básico")
	return {
		type = "BASIC",
		name = Config.ORBS.BASIC.NAME,
		description = Config.ORBS.BASIC.DESCRIPTION,
		color = Config.ORBS.BASIC.COLOR,
		damageModifier = Config.ORBS.BASIC.DAMAGE_MODIFIER,
		specialEffect = Config.ORBS.BASIC.SPECIAL_EFFECT
	}
end

-- Avanza al siguiente encuentro o nivel
function PlayerManager:advanceProgress()
	self.progression.currentEncounter = self.progression.currentEncounter + 1

	-- Si completó todos los encuentros del nivel actual
	local currentLevel = Config.LEVELS[self.progression.currentLevel]
	if self.progression.currentEncounter > currentLevel.ENCOUNTERS then
		-- Marcar nivel como completado
		table.insert(self.progression.completedLevels, self.progression.currentLevel)

		-- Determinar siguiente nivel (esto dependerá de tu estructura de progresión)
		if self.progression.currentLevel == "FOREST" then
			self.progression.currentLevel = "DUNGEON"
		elseif self.progression.currentLevel == "DUNGEON" then
			self.progression.currentLevel = "COMPLETED_GAME" -- O el siguiente nivel
		end

		-- Resetear contador de encuentros
		self.progression.currentEncounter = 1

		-- Actualizar total de encuentros para el nuevo nivel
		if Config.LEVELS[self.progression.currentLevel] then
			self.progression.totalEncounters = Config.LEVELS[self.progression.currentLevel].ENCOUNTERS
		end

		return true -- Completó el nivel
	end

	return false -- Simplemente avanzó al siguiente encuentro
end

-- Restaura la salud del jugador (cantidad opcional)
function PlayerManager:heal(amount)
	if not amount then
		-- Curación completa
		self.stats.health = self.stats.maxHealth
	else
		-- Curación parcial
		self.stats.health = math.min(self.stats.maxHealth, self.stats.health + amount)
	end
end

return PlayerManager