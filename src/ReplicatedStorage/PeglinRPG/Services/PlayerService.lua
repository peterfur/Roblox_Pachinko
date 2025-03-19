-- PlayerService.lua
-- Servicio que gestiona los datos del jugador y su progresión
-- Reemplaza al anterior PlayerManager con una arquitectura más estructurada

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Definición del PlayerService
local PlayerService = ServiceInterface:Extend("PlayerService")

-- Constructor
function PlayerService.new(serviceLocator, eventBus)
    local self = setmetatable({}, PlayerService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Propiedades
    self.Name = "PlayerService"
    
    -- Estadísticas básicas del jugador
    self.stats = {
        health = Config.COMBAT.PLAYER_STARTING_HEALTH,
        maxHealth = Config.COMBAT.PLAYER_STARTING_HEALTH,
        level = 1,
        experience = 0,
        experienceRequired = 100,
        gold = 0,
    }
    
    -- Inventario del jugador con orbes variados desde el principio
    self.inventory = {
        orbs = {
            {type = "BASIC", count = 3},
            {type = "FIRE", count = 1},  -- Agregar un orbe de fuego inicialmente
            {type = "ICE", count = 1}    -- Agregar un orbe de hielo inicialmente
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
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    return self
end

-- Inicialización del servicio
function PlayerService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Suscribirse a eventos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyAttackExecuted", function(attackType, damage)
        if damage > 0 then
            self:takeDamage(damage)
        end
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyAttemptsStun", function(attackType)
        -- 20% de probabilidad de ser aturdido
        if math.random(1, 100) <= 20 then
            self:applyEffect("STUNNED", 1)
        end
    end))
    
    print("PlayerService: Inicializado correctamente")
end

-- Resetea al jugador para un nuevo juego
function PlayerService:ResetPlayer()
    -- Restablecer estadísticas básicas
    self.stats = {
        health = Config.COMBAT.PLAYER_STARTING_HEALTH,
        maxHealth = Config.COMBAT.PLAYER_STARTING_HEALTH,
        level = 1,
        experience = 0,
        experienceRequired = 100,
        gold = 0,
    }
    
    -- Restablecer inventario con configuración inicial
    self.inventory = {
        orbs = {
            {type = "BASIC", count = 3},
            {type = "FIRE", count = 1},
            {type = "ICE", count = 1}
        },
        relics = {},
        consumables = {}
    }
    
    -- Restablecer progresión
    self.progression = {
        currentLevel = "FOREST",
        completedLevels = {},
        currentEncounter = 1,
        totalEncounters = Config.LEVELS.FOREST.ENCOUNTERS,
    }
    
    -- Limpiar efectos activos
    self.activeEffects = {}
    
    -- Publicar evento de jugador reseteado
    self.eventBus:Publish("PlayerReset")
    
    return true
end

-- Aplica el daño al jugador, teniendo en cuenta defensas y efectos
function PlayerService:takeDamage(amount)
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
    
    -- Publicar evento de daño recibido
    self.eventBus:Publish("PlayerDamaged", actualDamage)
    
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
            
            -- Publicar evento de resurrección
            self.eventBus:Publish("PlayerRevived")
            
            return false, "REVIVED" -- No murió, se revivió
        else
            -- Publicar evento de muerte
            self.eventBus:Publish("PlayerDied")
            
            return true, "DEAD" -- Murió
        end
    end
    
    return false, "DAMAGED" -- Está vivo, pero dañado
end

-- Añade experiencia y sube de nivel si es necesario
function PlayerService:addExperience(amount)
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
        
        -- Publicar evento de nivel subido
        self.eventBus:Publish("PlayerLeveledUp", self.stats.level)
    end
    
    -- Publicar evento de experiencia ganada
    self.eventBus:Publish("PlayerGainedExperience", amount, self.stats.experience, self.stats.experienceRequired)
    
    return levelsGained > 0, levelsGained
end

-- Añade una reliquia al inventario del jugador
function PlayerService:addRelic(relicType)
    local relic = Config.RELICS[relicType]
    if not relic then
        warn("PlayerService: Reliquia no encontrada:", relicType)
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
    
    -- Publicar evento de reliquia añadida
    self.eventBus:Publish("PlayerGainedRelic", relicType, relicInstance)
    
    return true
end

-- Añade un orbe al inventario del jugador
function PlayerService:addOrb(orbType)
    local orb = Config.ORBS[orbType]
    if not orb then
        warn("PlayerService: Orbe no encontrado:", orbType)
        return false
    end
    
    -- Buscar si ya tenemos este tipo de orbe
    for i, existingOrb in ipairs(self.inventory.orbs) do
        if existingOrb.type == orbType then
            existingOrb.count = existingOrb.count + 1
            
            -- Publicar evento de orbe añadido
            self.eventBus:Publish("PlayerGainedOrb", orbType, existingOrb.count)
            
            return true
        end
    end
    
    -- Si no existe, añadir nuevo tipo
    table.insert(self.inventory.orbs, {type = orbType, count = 1})
    
    -- Publicar evento de orbe añadido
    self.eventBus:Publish("PlayerGainedOrb", orbType, 1)
    
    return true
end

-- Aplica un efecto al jugador
function PlayerService:applyEffect(effectType, duration, value)
    -- Validar parámetros
    if not effectType then return false end
    duration = duration or 2
    value = value or 0.5
    
    -- Añadir a efectos activos
    table.insert(self.activeEffects, {
        type = effectType,
        remaining = duration,
        value = value,
        tick = function(effect)
            effect.remaining = effect.remaining - 1
            return effect.remaining <= 0 -- Devuelve true si el efecto ha terminado
        end
    })
    
    -- Publicar evento de efecto aplicado
    self.eventBus:Publish("PlayerEffectApplied", effectType, duration, value)
    
    return true
end

-- Procesa los efectos activos
function PlayerService:processEffects()
    local effectsToRemove = {}
    
    -- Procesar cada efecto activo
    for i, effect in ipairs(self.activeEffects) do
        -- Llamar a la función de tick del efecto
        local completed = effect:tick()
        
        -- Si el efecto se completó, marcarlo para eliminar
        if completed then
            table.insert(effectsToRemove, i)
            
            -- Publicar evento de efecto finalizado
            self.eventBus:Publish("PlayerEffectEnded", effect.type)
        end
    end
    
    -- Eliminar efectos completados (en orden inverso para no afectar índices)
    for i = #effectsToRemove, 1, -1 do
        table.remove(self.activeEffects, effectsToRemove[i])
    end
end

-- Avanza al siguiente encuentro o nivel
function PlayerService:advanceProgress()
    self.progression.currentEncounter = self.progression.currentEncounter + 1
    
    -- Publicar evento de progresión avanzada
    self.eventBus:Publish("PlayerProgressed", self.progression.currentEncounter)
    
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
        
        -- Publicar evento de nivel completado
        self.eventBus:Publish("PlayerCompletedLevel", self.progression.completedLevels[#self.progression.completedLevels])
        
        return true -- Completó el nivel
    end
    
    return false -- Simplemente avanzó al siguiente encuentro
end

-- Restaura la salud del jugador (cantidad opcional)
function PlayerService:heal(amount)
    local oldHealth = self.stats.health
    
    if not amount then
        -- Curación completa
        self.stats.health = self.stats.maxHealth
    else
        -- Curación parcial
        self.stats.health = math.min(self.stats.maxHealth, self.stats.health + amount)
    end
    
    local healedAmount = self.stats.health - oldHealth
    
    -- Publicar evento de curación
    if healedAmount > 0 then
        self.eventBus:Publish("PlayerHealed", healedAmount)
    end
    
    return healedAmount
end

-- Limpieza del servicio
function PlayerService:Cleanup()
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return PlayerService