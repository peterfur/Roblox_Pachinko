-- OrbLauncherDirect.server.lua
-- Script para garantizar que el lanzamiento de orbes funcione, independientemente de otros sistemas

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("OrbLauncherDirect: Iniciando script de lanzamiento directo de orbes")

-- Cargar EventBus para comunicación
local EventBus
pcall(function()
    local PeglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG")
    local Services = PeglinRPG:WaitForChild("Services")
    EventBus = require(Services:WaitForChild("EventBus"))
end)

if not EventBus then
    warn("OrbLauncherDirect: No se pudo cargar EventBus, el script tendrá funcionalidad limitada")
end

-- Cargar configuración si está disponible
local Config
pcall(function()
    local PeglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG")
    Config = require(PeglinRPG:WaitForChild("Config"))
end)

-- Configuración por defecto
local DEFAULT_BALL_SPEED = 35

-- Verificar si hay puntos de entrada en el tablero
local function getEntryPoint()
    local board = workspace:FindFirstChild("PeglinBoard_FOREST")
    if not board then return Vector3.new(0, 15, 0) end
    
    for _, child in pairs(board:GetChildren()) do
        if child:GetAttribute("LaunchPosition") then
            local launchPos = child:GetAttribute("LaunchPosition")
            if typeof(launchPos) == "Vector3" then
                return launchPos
            end
        end
        
        if child:GetAttribute("EntryPointIndex") then
            return child.Position
        end
    end
    
    return Vector3.new(0, 15, 0) -- Posición por defecto
end

-- Función para crear y lanzar un orbe
local function createAndLaunchOrb(direction, orbType)
    -- Valores por defecto
    direction = direction or Vector3.new(0, -1, 0)
    orbType = orbType or "BASIC"
    
    -- Obtener posición de lanzamiento
    local position = getEntryPoint()
    
    print("OrbLauncherDirect: Creando orbe tipo", orbType, "en posición", position)
    
    -- Configurar propiedades según el tipo de orbe
    local orbColor = Color3.fromRGB(255, 255, 0) -- Color por defecto (amarillo)
    
    if orbType == "FIRE" then
        orbColor = Color3.fromRGB(255, 100, 0)
    elseif orbType == "ICE" then
        orbColor = Color3.fromRGB(100, 200, 255)
    elseif orbType == "LIGHTNING" then
        orbColor = Color3.fromRGB(180, 180, 255)
    elseif orbType == "VOID" then
        orbColor = Color3.fromRGB(150, 0, 150)
    end
    
    -- Crear el orbe
    local orb = Instance.new("Part")
    orb.Name = "PeglinOrb_" .. orbType
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2.5, 2.5, 2.5)
    orb.Position = position
    orb.Color = orbColor
    orb.Material = Enum.Material.Neon
    orb.Anchored = false
    orb.CanCollide = true
    
    -- Establecer propiedades físicas
    local ballSpeed = Config and Config.PHYSICS and Config.PHYSICS.BALL_SPEED or DEFAULT_BALL_SPEED
    local ballDensity = Config and Config.PHYSICS and Config.PHYSICS.BALL_DENSITY or 2.5
    local ballElasticity = Config and Config.PHYSICS and Config.PHYSICS.BALL_ELASTICITY or 0.6
    local ballFriction = Config and Config.PHYSICS and Config.PHYSICS.BALL_FRICTION or 0.2
    
    orb.CustomPhysicalProperties = PhysicalProperties.new(
        ballDensity,
        ballFriction,
        ballElasticity,
        1.0,
        ballFriction
    )
    
    -- Añadir efectos visuales
    local light = Instance.new("PointLight")
    light.Brightness = 0.8
    light.Range = 8
    light.Color = orbColor
    light.Parent = orb
    
    -- Añadir sonido de rebote
    local bounceSound = Instance.new("Sound")
    bounceSound.SoundId = "rbxassetid://6732690176"
    bounceSound.Volume = 0.5
    bounceSound.Parent = orb
    
    -- Añadir estela
    local attachment = Instance.new("Attachment")
    attachment.Parent = orb
    
    local trail = Instance.new("Trail")
    trail.Attachment0 = attachment
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, orbColor),
        ColorSequenceKeypoint.new(1, orbColor:Lerp(Color3.fromRGB(255, 255, 255), 0.5))
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Lifetime = 0.8
    trail.Parent = orb
    
    -- Preparar datos del orbe para eventos
    local orbData = {
        type = orbType,
        name = orbType .. " Orb",
        criticalHits = 0
    }
    
    -- Configurar detección de colisiones
    orb.Touched:Connect(function(hit)
        -- Reproducir sonido al golpear
        if hit:GetAttribute("IsPeg") or hit:GetAttribute("IsBorder") then
            bounceSound:Play()
        end
        
        -- Verificar si golpeó una clavija
        if hit:GetAttribute("IsPeg") then
            print("OrbLauncherDirect: Orbe golpeó clavija", hit:GetFullName())
            
            -- Incrementar contador de golpes en la clavija
            local hitCount = hit:GetAttribute("HitCount") or 0
            hitCount = hitCount + 1
            hit:SetAttribute("HitCount", hitCount)
            
            -- Verificar si es una clavija crítica
            if hit:GetAttribute("IsCritical") then
                orbData.criticalHits = orbData.criticalHits + 1
            end
            
            -- Animar la clavija
            local originalColor = hit.Color
            local originalSize = hit.Size
            
            spawn(function()
                hit.Size = originalSize * 1.3
                hit.Color = Color3.fromRGB(255, 255, 255)
                
                wait(0.1)
                
                hit.Size = originalSize
                hit.Color = originalColor
                
                -- Desactivar la clavija si ha alcanzado el máximo de golpes
                local maxHits = hit:GetAttribute("MaxHits") or 2
                if hitCount >= maxHits then
                    spawn(function()
                        for i = 1, 10 do
                            hit.Transparency = i / 10
                            wait(0.05)
                        end
                        hit.CanCollide = false
                        hit:SetAttribute("IsPeg", false)
                    end)
                end
            end)
            
            -- Aplicar daño al enemigo
            local enemyModel = workspace:FindFirstChild("Enemy_SLIME")
            if enemyModel then
                local mainPart = enemyModel:FindFirstChildWhichIsA("BasePart")
                if mainPart then
                    -- Buscar etiqueta de salud
                    local healthLabel
                    for _, child in pairs(mainPart:GetChildren()) do
                        if child:IsA("BillboardGui") then
                            for _, grandchild in pairs(child:GetChildren()) do
                                if grandchild:IsA("TextLabel") then
                                    healthLabel = grandchild
                                    break
                                end
                            end
                        end
                    end
                    
                    if healthLabel then
                        -- Extraer salud actual del texto
                        local currentText = healthLabel.Text
                        local currentHealth, maxHealth = string.match(currentText, "Slime: (%d+)/(%d+)")
                        
                        if currentHealth and maxHealth then
                            currentHealth = tonumber(currentHealth)
                            maxHealth = tonumber(maxHealth)
                            
                            -- Calcular daño
                            local damage = 10 -- Daño base
                            if hit:GetAttribute("IsCritical") then
                                damage = damage * 2.5 -- Multiplicador crítico
                            end
                            
                            -- Aplicar daño
                            currentHealth = math.max(0, currentHealth - damage)
                            
                            -- Actualizar etiqueta
                            healthLabel.Text = "Slime: " .. currentHealth .. "/" .. maxHealth
                            
                            -- Mostrar número de daño
                            local damageLabel = Instance.new("BillboardGui")
                            damageLabel.Size = UDim2.new(0, 100, 0, 40)
                            damageLabel.StudsOffset = Vector3.new(0, 2, 0)
                            damageLabel.Adornee = hit
                            
                            local textLabel = Instance.new("TextLabel")
                            textLabel.Size = UDim2.new(1, 0, 1, 0)
                            textLabel.BackgroundTransparency = 1
                            textLabel.TextColor3 = hit:GetAttribute("IsCritical") and 
                                                   Color3.fromRGB(255, 100, 100) or 
                                                   Color3.fromRGB(255, 255, 255)
                            textLabel.Font = Enum.Font.SourceSansBold
                            textLabel.TextSize = 18
                            textLabel.Text = tostring(damage)
                            textLabel.Parent = damageLabel
                            
                            damageLabel.Parent = workspace
                            
                            -- Animar el número
                            spawn(function()
                                for i = 1, 10 do
                                    textLabel.Position = UDim2.new(0, 0, 0, -i*2)
                                    textLabel.TextTransparency = i / 10
                                    wait(0.1)
                                end
                                damageLabel:Destroy()
                            end)
                            
                            -- Verificar si el enemigo murió
                            if currentHealth <= 0 then
                                -- Animar muerte del enemigo
                                spawn(function()
                                    for i = 1, 10 do
                                        mainPart.Transparency = i / 10
                                        wait(0.1)
                                    end
                                    
                                    wait(1)
                                    enemyModel:Destroy()
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- Poner el orbe en el workspace
    orb.Parent = workspace
    
    -- Notificar a través de EventBus si está disponible
    if EventBus then
        EventBus:Publish("OrbLaunched", orb, orbData)
        print("OrbLauncherDirect: Evento OrbLaunched publicado")
    end
    
    -- Aplicar impulso después de un frame para asegurar física correcta
    spawn(function()
        wait() -- Esperar un frame
        
        -- Calcular y aplicar impulso
        local impulse = direction * ballSpeed * orb:GetMass()
        orb:ApplyImpulse(impulse)
        
        print("OrbLauncherDirect: Impulso aplicado, dirección:", direction, "velocidad:", orb.Velocity.Magnitude)
    end)
    
    return orb
end

-- Suscribirse a eventos de lanzamiento si EventBus está disponible
if EventBus then
    EventBus:Subscribe("PlayerClickedToLaunch", function(direction)
        print("OrbLauncherDirect: Recibido evento PlayerClickedToLaunch, dirección:", direction)
        createAndLaunchOrb(direction)
    end)
    
    EventBus:Subscribe("OrbLaunchRequested", function(direction, position)
        print("OrbLauncherDirect: Recibido evento OrbLaunchRequested")
        createAndLaunchOrb(direction)
    end)
    
    print("OrbLauncherDirect: Suscrito a eventos de lanzamiento")
end

-- Crear remoteEvent para permitir lanzamientos directos desde el cliente
local launchEvent = Instance.new("RemoteEvent")
launchEvent.Name = "DirectOrbLaunch"
launchEvent.Parent = ReplicatedStorage

-- Manejar llamadas del cliente
launchEvent.OnServerEvent:Connect(function(player, direction, orbType)
    print("OrbLauncherDirect: Solicitud de lanzamiento recibida de", player.Name)
    createAndLaunchOrb(direction, orbType)
end)

-- Crear función global para lanzamiento manual
_G.LaunchOrb = function(direction, orbType)
    return createAndLaunchOrb(direction, orbType)
end

print("OrbLauncherDirect: Configuración completada. Función _G.LaunchOrb y RemoteEvent DirectOrbLaunch disponibles.")

