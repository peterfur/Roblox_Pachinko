-- OrbService.lua
-- Versión simplificada del servicio que gestiona los orbes y sus efectos
-- Esta versión es un fallback básico para cuando el servicio original no está disponible

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))

-- Definición del OrbService
local OrbService = ServiceInterface:Extend("OrbService")

-- Constructor
function OrbService.new(serviceLocator, eventBus)
    local self = setmetatable({}, OrbService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Propiedades
    self.Name = "OrbService"
    self.currentOrb = nil
    self.orbPoolForBattle = {} -- Orbes disponibles en esta batalla
    self.activeOrbVisual = nil
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    print("OrbService (simplificado): Creado")
    
    return self
end

-- Inicialización del servicio
function OrbService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Suscribirse a eventos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("PlayerTurnStarted", function()
        self:selectNextOrb()
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("OrbLaunched", function()
        self.activeOrbVisual = nil
    end))
    
    print("OrbService (simplificado): Inicializado correctamente")
end

-- Inicializa el pool de orbes para una batalla
function OrbService:initializeBattlePool(playerManager)
    self.orbPoolForBattle = {"BASIC", "BASIC", "BASIC"}
    
    -- Si tenemos playerManager, intentamos usar su inventario
    if playerManager and playerManager.inventory and playerManager.inventory.orbs then
        self.orbPoolForBattle = {}
        for _, orbData in ipairs(playerManager.inventory.orbs) do
            for i = 1, orbData.count or 1 do
                table.insert(self.orbPoolForBattle, orbData.type)
            end
        end
    end
    
    -- Asegurar que siempre haya al menos un orbe básico
    if #self.orbPoolForBattle == 0 then
        table.insert(self.orbPoolForBattle, "BASIC")
    end
    
    -- Barajar el pool para que los orbes se seleccionen aleatoriamente
    self:shufflePool()
    
    -- Publicar evento de pool inicializado
    self.eventBus:Publish("OrbPoolInitialized", self.orbPoolForBattle)
    
    return self.orbPoolForBattle
end

-- Baraja el pool de orbes
function OrbService:shufflePool()
    local n = #self.orbPoolForBattle
    for i = n, 2, -1 do
        local j = math.random(i)
        self.orbPoolForBattle[i], self.orbPoolForBattle[j] = self.orbPoolForBattle[j], self.orbPoolForBattle[i]
    end
end

-- Selecciona el siguiente orbe disponible
function OrbService:selectNextOrb()
    if #self.orbPoolForBattle == 0 then
        -- Si no hay más orbes, crear uno básico
        self.currentOrb = self:createOrbInstance("BASIC")
    else
        -- Tomar el siguiente orbe del pool
        local nextOrbType = table.remove(self.orbPoolForBattle, 1)
        self.currentOrb = self:createOrbInstance(nextOrbType)
    end
    
    -- Publicar evento de orbe seleccionado
    self.eventBus:Publish("OrbSelected", self.currentOrb)
    
    return self.currentOrb
end

-- Crea una instancia específica de orbe según su tipo
function OrbService:createOrbInstance(orbType)
    -- Configuraciones básicas para diferentes tipos de orbes
    local orbConfigs = {
        BASIC = {
            NAME = "Orbe Básico",
            DESCRIPTION = "Un orbe básico que causa daño normal.",
            COLOR = Color3.fromRGB(255, 255, 0),
            DAMAGE_MODIFIER = 1.0,
        },
        FIRE = {
            NAME = "Orbe de Fuego",
            DESCRIPTION = "Incendia al enemigo, causando daño a lo largo del tiempo.",
            COLOR = Color3.fromRGB(255, 100, 0),
            DAMAGE_MODIFIER = 0.8,
            SPECIAL_EFFECT = "DOT",
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
        }
    }
    
    -- Usar configuración básica si el tipo no está definido
    local orbConfig = orbConfigs[orbType] or orbConfigs.BASIC
    
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
        
        -- Contador para estadísticas
        pegHits = 0,
        criticalHits = 0,
        totalDamage = 0,
    }
    
    return orbInstance
end

-- Crea un objeto visual para un orbe
function OrbService:createOrbVisual(orbInstance, position)
    -- Limpiar visual anterior si existe
    if self.activeOrbVisual then
        self.activeOrbVisual:Destroy()
        self.activeOrbVisual = nil
    end
    
    -- Crear parte física
    local ball = Instance.new("Part")
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(2.5, 2.5, 2.5)
    ball.Position = position or Vector3.new(0, 15, 0)
    
    -- Aplicar color según tipo de orbe
    local color = orbInstance.color or Color3.fromRGB(255, 255, 0)
    ball.Color = color
    ball.Material = Enum.Material.Neon
    
    -- Propiedades físicas
    ball.Anchored = false
    ball.CanCollide = true
    ball.CustomPhysicalProperties = PhysicalProperties.new(
        1.5,   -- Densidad
        0.4,   -- Fricción
        0.7,   -- Elasticidad
        0.6,   -- Peso
        0.6    -- Fricción rotacional
    )
    
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
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = orbInstance.name or "Orbe"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = nameLabel
    
    nameLabel.Parent = ball
    
    -- Guardar referencia al orbe visual activo
    self.activeOrbVisual = ball
    
    ball.Parent = workspace
    
    -- Publicar evento de orbe visual creado
    self.eventBus:Publish("OrbVisualCreated", ball, orbInstance)
    
    return ball, bounceSound
end

-- Procesa un golpe contra una clavija
function OrbService:processPegHit(orbInstance, pegInstance, enemyManager)
    -- Actualizar estadísticas del orbe
    orbInstance.pegHits = orbInstance.pegHits + 1
    
    -- Verificar si es un golpe crítico
    local isCritical = pegInstance:GetAttribute("IsCritical") or false
    if isCritical then
        orbInstance.criticalHits = orbInstance.criticalHits + 1
    end
    
    -- Calcular daño base (valores por defecto si no hay Config)
    local baseDamage = 10 * (orbInstance.damageModifier or 1.0)
    local criticalMultiplier = 2.5
    
    -- Intentar obtener configuración si está disponible
    local success, Config = pcall(function()
        return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))
    end)
    
    if success and Config and Config.COMBAT then
        baseDamage = Config.COMBAT.BASE_DAMAGE * (orbInstance.damageModifier or 1.0)
        criticalMultiplier = Config.COMBAT.CRITICAL_MULTIPLIER
    end
    
    if isCritical then
        baseDamage = baseDamage * criticalMultiplier
    end
    
    -- Aplicar efectos especiales según tipo de orbe
    if orbInstance.specialEffect == "DOT" and orbInstance.dotDamage and orbInstance.dotDuration and enemyManager then
        -- Daño a lo largo del tiempo (fuego)
        if type(enemyManager.applyEffect) == "function" then
            enemyManager:applyEffect("BURN", orbInstance.dotDuration, orbInstance.dotDamage)
        end
    end
    
    -- Actualizar daño total causado
    orbInstance.totalDamage = orbInstance.totalDamage + baseDamage
    
    -- Publicar evento de daño calculado
    self.eventBus:Publish("OrbDamageCalculated", orbInstance, baseDamage, isCritical)
    
    return "NORMAL", baseDamage
end

-- Obtiene información sobre el orbe actual
function OrbService:getCurrentOrbInfo()
    if not self.currentOrb then
        return self:createOrbInstance("BASIC")
    end
    
    return self.currentOrb
end

-- Obtiene conteo de orbes restantes por tipo
function OrbService:getRemainingOrbCounts()
    local counts = {}
    
    for _, orbType in ipairs(self.orbPoolForBattle) do
        counts[orbType] = (counts[orbType] or 0) + 1
    end
    
    return counts
end

-- Limpieza del servicio
function OrbService:Cleanup()
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Limpiar orbe visual activo
    if self.activeOrbVisual then
        self.activeOrbVisual:Destroy()
        self.activeOrbVisual = nil
    end
    
    -- Limpiar propiedades
    self.currentOrb = nil
    self.orbPoolForBattle = {}
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return OrbService