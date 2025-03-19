-- EnemyService.lua
-- Versión simplificada del servicio que gestiona los enemigos y sus comportamientos
-- Esta versión es un fallback básico para cuando el servicio original no está disponible

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))

-- Intentar cargar Config, pero con manejo de errores
local Config
pcall(function()
    Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))
end)

-- Configuración por defecto si no se puede cargar el módulo Config
local DEFAULT_CONFIG = {
    ENEMIES = {
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
        }
    },
    LEVELS = {
        FOREST = {
            ENEMY_POOL = {"SLIME", "GOBLIN"},
            BOSS = "ORC"
        },
        DUNGEON = {
            ENEMY_POOL = {"GOBLIN", "SKELETON"},
            BOSS = "NECROMANCER"
        }
    }
}

-- Definición del EnemyService
local EnemyService = ServiceInterface:Extend("EnemyService")

-- Constructor
function EnemyService.new(serviceLocator, eventBus)
    local self = setmetatable({}, EnemyService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Propiedades
    self.Name = "EnemyService"
    self.currentEnemy = nil
    self.enemyModel = nil
    self.health = 0
    self.maxHealth = 0
    self.defense = 0
    self.damage = 0
    self.activeEffects = {}
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    print("EnemyService (simplificado): Creado")
    
    return self
end

-- Inicialización del servicio
function EnemyService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Suscribirse a eventos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyTurnStarted", function()
        self:performEnemyTurn()
    end))
    
    print("EnemyService (simplificado): Inicializado correctamente")
end

-- Genera un enemigo nuevo para el combate
function EnemyService:generateEnemy(levelName, isBoss)
    print("EnemyService: Generando enemigo para nivel", levelName, "¿Es jefe?", isBoss)
    
    -- Usar Config si está disponible, o el valor por defecto
    local enemyConfig = Config and Config.ENEMIES or DEFAULT_CONFIG.ENEMIES
    local levelConfig = Config and Config.LEVELS and Config.LEVELS[levelName] or DEFAULT_CONFIG.LEVELS[levelName] or DEFAULT_CONFIG.LEVELS.FOREST
    
    -- Determinar tipo de enemigo
    local enemyType
    if isBoss then
        enemyType = levelConfig.BOSS or "ORC"
    else
        local enemyPool = levelConfig.ENEMY_POOL or {"SLIME", "GOBLIN"}
        enemyType = enemyPool[math.random(1, #enemyPool)]
    end
    
    -- Asegurar que el tipo de enemigo esté definido
    if not enemyConfig[enemyType] then
        print("EnemyService: Tipo de enemigo no encontrado, usando SLIME como fallback")
        enemyType = "SLIME"
    end
    
    -- Configurar datos del enemigo
    local enemyData = enemyConfig[enemyType]
    self.currentEnemy = {
        type = enemyType,
        name = enemyData.NAME or "Enemigo",
        description = enemyData.DESCRIPTION or "Un enemigo misterioso",
        attacks = enemyData.ATTACKS or {"ATTACK"},
        image = enemyData.IMAGE or ""
    }
    
    self.health = enemyData.HEALTH or 100
    self.maxHealth = self.health
    self.defense = enemyData.DEFENSE or 0
    self.damage = enemyData.DAMAGE or 10
    
    -- Crear modelo visual del enemigo
    self:createEnemyVisual(enemyType)
    
    -- Publicar evento de enemigo generado
    self.eventBus:Publish("EnemyGenerated", self.currentEnemy)
    
    return true
end

-- Crea la representación visual del enemigo
function EnemyService:createEnemyVisual(enemyType)
    -- Destruir modelo anterior si existe
    if self.enemyModel then
        self.enemyModel:Destroy()
        self.enemyModel = nil
    end
    
    -- Crear modelo base
    local model = Instance.new("Model")
    model.Name = "Enemy_" .. enemyType
    
    -- Crear parte principal del enemigo
    local mainPart = Instance.new("Part")
    mainPart.Shape = Enum.PartType.Ball
    mainPart.Size = Vector3.new(5, 5, 5)
    mainPart.Position = Vector3.new(0, 7, -10) -- Posición frente al tablero
    mainPart.Anchored = true
    mainPart.CanCollide = false
    
    -- Aspecto visual según tipo de enemigo
    if enemyType == "SLIME" then
        mainPart.Color = Color3.fromRGB(0, 200, 0)
        mainPart.Material = Enum.Material.SmoothPlastic
        mainPart.Transparency = 0.2
    elseif enemyType == "GOBLIN" then
        mainPart.Color = Color3.fromRGB(0, 150, 0)
        mainPart.Shape = Enum.PartType.Block
        mainPart.Size = Vector3.new(3, 6, 3)
    elseif enemyType == "ORC" then
        mainPart.Color = Color3.fromRGB(100, 100, 100)
        mainPart.Shape = Enum.PartType.Block
        mainPart.Size = Vector3.new(7, 8, 3)
    else
        mainPart.Color = Color3.fromRGB(150, 0, 0)
    end
    
    mainPart.Parent = model
    
    -- Agregar UI con nombre del enemigo
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 5, 0)
    billboardGui.Adornee = mainPart
    billboardGui.AlwaysOnTop = true
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = self.currentEnemy.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = billboardGui
    
    -- Mostrar salud del enemigo
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextScaled = true
    healthLabel.Font = Enum.Font.SourceSans
    healthLabel.Text = "HP: " .. self.health .. "/" .. self.maxHealth
    healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.Parent = billboardGui
    
    billboardGui.Parent = model
    
    -- Añadir efectos según el tipo
    if enemyType == "SLIME" then
        -- Agregar partículas de baba
        local attachment = Instance.new("Attachment")
        attachment.Parent = mainPart
        
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        })
        particles.Lifetime = NumberRange.new(1, 2)
        particles.Rate = 5
        particles.Speed = NumberRange.new(1, 3)
        particles.SpreadAngle = Vector2.new(180, 180)
        particles.Parent = attachment
    end
    
    model.Parent = workspace
    self.enemyModel = model
    
    -- Actualizar referencia a la etiqueta de salud para actualizaciones posteriores
    self.healthLabel = healthLabel
    
    -- Animar aparición del enemigo
    spawn(function()
        local originalPosition = mainPart.Position
        mainPart.Position = originalPosition + Vector3.new(0, 10, 0)
        mainPart.Transparency = 1
        
        for i = 1, 10 do
            mainPart.Position = originalPosition + Vector3.new(0, 10 - i, 0)
            mainPart.Transparency = 1 - (i / 10)
            wait(0.05)
        end
        
        mainPart.Position = originalPosition
        mainPart.Transparency = 0
    end)
    
    return model
end

-- Aplica daño al enemigo
function EnemyService:takeDamage(amount, damageType)
    -- Verificar que hay un enemigo activo
    if not self.currentEnemy then
        warn("EnemyService: Intento de aplicar daño sin enemigo activo")
        return false, 0
    end
    
    -- Calcular daño real
    local actualDamage = amount
    
    -- Ajustar por defensa excepto si es daño penetrante
    if damageType ~= "PENETRATE" and self.defense > 0 then
        actualDamage = math.max(1, amount - self.defense)
    end
    
    -- Aplicar daño
    self.health = math.max(0, self.health - actualDamage)
    
    -- Actualizar etiqueta de salud
    if self.healthLabel then
        self.healthLabel.Text = "HP: " .. self.health .. "/" .. self.maxHealth
    end
    
    -- Efectos visuales de daño
    if self.enemyModel then
        local mainPart = self.enemyModel:FindFirstChildWhichIsA("BasePart")
        if mainPart then
            -- Flash rojo al recibir daño
            spawn(function()
                local originalColor = mainPart.Color
                mainPart.Color = Color3.fromRGB(255, 0, 0)
                
                for i = 1, 5 do
                    mainPart.Transparency = 0.5
                    wait(0.1)
                    mainPart.Transparency = 0
                    wait(0.1)
                end
                
                mainPart.Color = originalColor
            end)
        end
    end
    
    -- Verificar si el enemigo ha sido derrotado
    local killed = self.health <= 0
    
    if killed then
        -- Publicar evento de enemigo derrotado
        self.eventBus:Publish("EnemyKilled", self.currentEnemy.type, self.enemyModel and self.enemyModel:GetPrimaryPartCFrame().Position or Vector3.new(0, 0, -10))
        
        -- Animar muerte
        if self.enemyModel then
            spawn(function()
                local mainPart = self.enemyModel:FindFirstChildWhichIsA("BasePart")
                if mainPart then
                    for i = 1, 10 do
                        mainPart.Transparency = i / 10
                        mainPart.Size = mainPart.Size * 0.9
                        wait(0.1)
                    end
                    self.enemyModel:Destroy()
                    self.enemyModel = nil
                end
            end)
        end
    else
        -- Publicar evento de daño recibido
        self.eventBus:Publish("EnemyDamaged", actualDamage, self.health, self.maxHealth)
    end
    
    return killed, actualDamage
end

-- Aplica un efecto al enemigo (quemadura, ralentización, etc.)
function EnemyService:applyEffect(effectType, duration, magnitude)
    -- Verificar que hay un enemigo activo
    if not self.currentEnemy then
        warn("EnemyService: Intento de aplicar efecto sin enemigo activo")
        return false
    end
    
    -- Registrar el efecto
    local effect = {
        type = effectType,
        duration = duration or 2,
        magnitude = magnitude or 1,
        appliedAt = tick()
    }
    
    table.insert(self.activeEffects, effect)
    
    -- Efectos visuales según tipo
    if self.enemyModel and effectType then
        local mainPart = self.enemyModel:FindFirstChildWhichIsA("BasePart")
        if mainPart then
            if effectType == "BURN" then
                -- Efecto de fuego
                local fire = Instance.new("Fire")
                fire.Heat = 10
                fire.Size = 3
                fire.Color = Color3.fromRGB(255, 100, 0)
                fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
                fire.Parent = mainPart
                
                -- Eliminar después de la duración
                spawn(function()
                    wait(duration)
                    fire:Destroy()
                end)
            elseif effectType == "SLOW" then
                -- Efecto de hielo
                mainPart.Color = mainPart.Color:Lerp(Color3.fromRGB(150, 200, 255), 0.5)
                
                -- Restaurar después de la duración
                spawn(function()
                    wait(duration)
                    mainPart.Color = self.currentEnemy.type == "SLIME" and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 0, 0)
                end)
            end
        end
    end
    
    -- Publicar evento de efecto aplicado
    self.eventBus:Publish("EnemyEffectApplied", effectType, duration, magnitude)
    
    return true
end

-- Realiza el turno del enemigo
function EnemyService:performEnemyTurn()
    -- Verificar que hay un enemigo activo
    if not self.currentEnemy then
        warn("EnemyService: Intento de realizar turno sin enemigo activo")
        self.eventBus:Publish("EnemyTurnCompleted")
        return false
    end
    
    -- Procesar efectos activos
    self:processActiveEffects()
    
    -- Verificar si el enemigo está vivo
    if self.health <= 0 then
        self.eventBus:Publish("EnemyTurnCompleted")
        return false
    end
    
    -- Seleccionar un ataque aleatorio
    local attackOptions = self.currentEnemy.attacks or {"ATTACK"}
    local selectedAttack = attackOptions[math.random(1, #attackOptions)]
    
    -- Calcular daño del ataque
    local attackDamage = self.damage
    local attackType = "NORMAL"
    
    -- Modificar según tipo de ataque
    if selectedAttack == "DEFEND" then
        attackDamage = math.floor(attackDamage * 0.5)
        self.defense = self.defense + 2
        attackType = "DEFEND"
    elseif selectedAttack == "THROW" or selectedAttack == "BONE_THROW" then
        attackDamage = math.floor(attackDamage * 1.2)
        attackType = "PROJECTILE"
    end
    
    -- Aplicar efectos (como ralentización) al daño
    for _, effect in ipairs(self.activeEffects) do
        if effect.type == "SLOW" then
            attackDamage = math.floor(attackDamage * (1 - effect.magnitude))
        end
    end
    
    -- Animar ataque
    self:animateAttack(selectedAttack)
    
    -- Esperar a que termine la animación
    wait(1.5)
    
    -- Publicar evento de ataque del enemigo
    self.eventBus:Publish("EnemyAttack", attackDamage, attackType, selectedAttack)
    
    -- Finalizar turno del enemigo
    wait(0.5)
    self.eventBus:Publish("EnemyTurnCompleted")
    
    return true
end

-- Procesa los efectos activos en el enemigo
function EnemyService:processActiveEffects()
    local currentTime = tick()
    local remainingEffects = {}
    
    for _, effect in ipairs(self.activeEffects) do
        -- Verificar si el efecto sigue activo
        if currentTime - effect.appliedAt <= effect.duration then
            -- Aplicar efecto según tipo
            if effect.type == "BURN" then
                local burnDamage = effect.magnitude or 1
                self.health = math.max(0, self.health - burnDamage)
                
                -- Actualizar etiqueta de salud
                if self.healthLabel then
                    self.healthLabel.Text = "HP: " .. self.health .. "/" .. self.maxHealth
                end
                
                -- Publicar evento de daño por quemadura
                self.eventBus:Publish("EnemyBurnDamage", burnDamage, self.health, self.maxHealth)
            end
            
            -- Mantener efecto activo
            table.insert(remainingEffects, effect)
        end
    end
    
    -- Actualizar lista de efectos activos
    self.activeEffects = remainingEffects
    
    -- Verificar si el enemigo murió por efectos
    if self.health <= 0 then
        -- Publicar evento de enemigo derrotado
        self.eventBus:Publish("EnemyKilled", self.currentEnemy.type, self.enemyModel and self.enemyModel:GetPrimaryPartCFrame().Position or Vector3.new(0, 0, -10))
    end
end

-- Anima el ataque del enemigo
function EnemyService:animateAttack(attackType)
    if not self.enemyModel then
        return
    end
    
    local mainPart = self.enemyModel:FindFirstChildWhichIsA("BasePart")
    if not mainPart then
        return
    end
    
    local originalPosition = mainPart.Position
    local originalColor = mainPart.Color
    
    if attackType == "TACKLE" or attackType == "ATTACK" then
        -- Animación de embestida
        spawn(function()
            -- Moverse hacia atrás primero
            for i = 1, 5 do
                mainPart.Position = originalPosition + Vector3.new(0, 0, -i/2)
                wait(0.02)
            end
            
            -- Luego embestir hacia adelante
            mainPart.Color = Color3.fromRGB(255, 100, 100)
            for i = 1, 15 do
                mainPart.Position = originalPosition + Vector3.new(0, 0, -2.5 + (i * 0.5))
                wait(0.01)
            end
            
            -- Volver a la posición original
            for i = 1, 10 do
                mainPart.Position = originalPosition + Vector3.new(0, 0, 5 - (i * 0.5))
                wait(0.02)
            end
            
            mainPart.Position = originalPosition
            mainPart.Color = originalColor
        end)
    elseif attackType == "DEFEND" then
        -- Animación de defensa
        spawn(function()
            -- Efecto de brillo defensivo
            mainPart.Color = Color3.fromRGB(100, 100, 255)
            
            for i = 1, 8 do
                mainPart.Transparency = 0.5
                wait(0.1)
                mainPart.Transparency = 0.2
                wait(0.1)
            end
            
            mainPart.Transparency = 0
            mainPart.Color = originalColor
        end)
    elseif attackType == "THROW" or attackType == "BONE_THROW" then
        -- Animación de lanzamiento
        spawn(function()
            -- Preparación para lanzar
            for i = 1, 5 do
                mainPart.Position = originalPosition + Vector3.new(0, i/5, -i/3)
                wait(0.05)
            end
            
            -- Crear y lanzar proyectil
            local projectile = Instance.new("Part")
            projectile.Shape = Enum.PartType.Ball
            projectile.Size = Vector3.new(1, 1, 1)
            projectile.Position = mainPart.Position + Vector3.new(0, 0, 2)
            projectile.Anchored = true
            projectile.CanCollide = false
            
            if attackType == "BONE_THROW" then
                projectile.Color = Color3.fromRGB(220, 220, 220)
                projectile.Material = Enum.Material.Plastic
            else
                projectile.Color = mainPart.Color
            end
            
            projectile.Parent = workspace
            
            -- Animar proyectil
            for i = 1, 20 do
                projectile.Position = projectile.Position + Vector3.new(0, -i/20, i)
                wait(0.02)
            end
            
            -- Efecto de impacto
            local explosion = Instance.new("Explosion")
            explosion.Position = projectile.Position
            explosion.BlastRadius = 0
            explosion.BlastPressure = 0
            explosion.ExplosionType = Enum.ExplosionType.NoCraters
            explosion.Parent = workspace
            
            projectile:Destroy()
            
            -- Volver a posición original
            mainPart.Position = originalPosition
        end)
    elseif attackType == "BOUNCE" then
        -- Animación de rebote
        spawn(function()
            for j = 1, 3 do
                for i = 1, 5 do
                    mainPart.Position = originalPosition + Vector3.new(0, i, 0)
                    wait(0.02)
                end
                for i = 5, 0, -1 do
                    mainPart.Position = originalPosition + Vector3.new(0, i, 0)
                    wait(0.02)
                end
            end
            
            mainPart.Position = originalPosition
        end)
    end
end

-- Limpieza del servicio
function EnemyService:Cleanup()
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Destruir modelo visual
    if self.enemyModel then
        self.enemyModel:Destroy()
        self.enemyModel = nil
    end
    
    -- Limpiar propiedades
    self.currentEnemy = nil
    self.health = 0
    self.maxHealth = 0
    self.defense = 0
    self.damage = 0
    self.activeEffects = {}
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return EnemyService