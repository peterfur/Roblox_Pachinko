-- CombatService.lua
-- Servicio que gestiona el sistema de combate y colisiones
-- Reemplaza al anterior CombatManager con una arquitectura más estructurada

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Definición del CombatService
local CombatService = ServiceInterface:Extend("CombatService")

-- Constructor
function CombatService.new(serviceLocator, eventBus)
    local self = setmetatable({}, CombatService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Propiedades
    self.Name = "CombatService"
    self.currentOrbConnection = nil
    self.hitPegs = {}
    self.damageDealt = 0
    self.minDamagePerLaunch = Config.PHYSICS.MIN_GUARANTEED_DAMAGE or 10
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    return self
end

-- Inicialización del servicio
function CombatService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Suscribirse a eventos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("OrbLaunched", function(orbVisual, orbData)
        self:setupOrbCollisions(orbVisual, orbData)
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BattleEnded", function()
        if self.currentOrbConnection then
            self.currentOrbConnection:Disconnect()
            self.currentOrbConnection = nil
        end
    end))
    
    -- Cuando un enemigo muere por daño
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("EnemyKilled", function(enemyType, position)
        self:handleVictory(enemyType, position)
    end))
    
    print("CombatService: Inicializado correctamente")
end

-- Configura la detección de colisiones para un orbe lanzado
function CombatService:setupOrbCollisions(orbVisual, orbData)
    -- Verificar que orbVisual es válido
    if not orbVisual or not orbVisual.Parent then
        warn("CombatService: orbVisual no es válido")
        return
    end
    
    -- Obtener servicios necesarios
    local boardService = self.serviceLocator:GetService("BoardService")
    local enemyService = self.serviceLocator:GetService("EnemyService")
    local effectsService = self.serviceLocator:GetService("EffectsService")
    
    if not (boardService and enemyService) then
        warn("CombatService: No se pudieron obtener los servicios necesarios")
        return
    end
    
    -- Reiniciar el registro de clavijas golpeadas y daño acumulado
    self.hitPegs = {}
    self.damageDealt = 0
    
    -- Desconectar conexión anterior si existe
    if self.currentOrbConnection then
        self.currentOrbConnection:Disconnect()
        self.currentOrbConnection = nil
    end
    
    -- Variables para seguimiento de golpes
    local bounceCount = 0
    local lastHitPeg = nil
    local comboCount = 0
    local lastHitTime = 0
    
    -- Referencia al sonido de rebote
    local bounceSound = orbVisual:FindFirstChildOfClass("Sound")
    
    -- Verificar constantemente si el orbe está activo pero no ha golpeado nada
    spawn(function()
        local launchTime = tick()
        local checkInterval = 0.5 -- Verificar cada medio segundo
        local maxTimeWithoutHit = 3.0 -- Si después de 3 segundos no ha golpeado nada, aplicar daño mínimo
        
        while orbVisual and orbVisual.Parent do
            -- Si ha pasado suficiente tiempo sin golpes y no se ha acumulado daño, aplicar daño mínimo
            if tick() - launchTime > maxTimeWithoutHit and self.damageDealt == 0 and #self.hitPegs == 0 then
                print("CombatService: No se detectaron golpes, aplicando daño mínimo garantizado:", self.minDamagePerLaunch)
                
                -- Aplicar daño mínimo garantizado
                local killed = enemyService:takeDamage(self.minDamagePerLaunch, "NORMAL")
                
                -- Mostrar mensaje de "¡Golpe automático!" para informar al usuario
                if effectsService then
                    effectsService:showDamageNumber(Vector3.new(0, 0, -30), self.minDamagePerLaunch, false, "¡Golpe automático!")
                end
                
                -- Marcar que ya aplicamos daño para evitar duplicados
                self.damageDealt = self.minDamagePerLaunch
                break
            end
            
            wait(checkInterval)
        end
    end)
    
    -- Conectar evento de colisión principal
    self.currentOrbConnection = orbVisual.Touched:Connect(function(hit)
        -- Verificar si es una clavija
        if hit:GetAttribute("IsPeg") then
            -- Verificar si ya se golpeó esta clavija (evitar conteo doble)
            local pegId = hit:GetFullName()
            if self.hitPegs[pegId] then
                return
            end
            
            -- Registrar esta clavija como golpeada
            self.hitPegs[pegId] = true
            
            -- Evitar golpear la misma clavija repetidamente
            if hit == lastHitPeg then
                return
            end
            
            -- Reproducir sonido
            if bounceSound then
                bounceSound:Play()
            end
            
            -- Registrar esta clavija como la última golpeada
            lastHitPeg = hit
            bounceCount = bounceCount + 1
            
            -- Calcular combo
            local currentTime = tick()
            if currentTime - lastHitTime < 1.5 then
                comboCount = comboCount + 1
            else
                comboCount = 1
            end
            lastHitTime = currentTime
            
            -- Procesar golpe con OrbService
            local orbService = self.serviceLocator:GetService("OrbService")
            if not orbService then
                warn("CombatService: No se pudo obtener OrbService")
                return
            end
            
            local damageType, damageAmount = orbService:processPegHit(orbData, hit, enemyService)
            
            -- Aplicar multiplicador de combo
            local comboMultiplier = math.min(3, 1 + (comboCount * 0.1))
            damageAmount = math.floor(damageAmount * comboMultiplier)
            
            -- Acumular el daño total realizado
            self.damageDealt = self.damageDealt + damageAmount
            
            -- Aplicar daño al enemigo
            local killed, actualDamage = enemyService:takeDamage(damageAmount, damageType)
            
            -- Mostrar número de daño flotante
            if effectsService then
                effectsService:showDamageNumber(hit.Position, actualDamage, comboMultiplier > 1.5)
                effectsService:showOrbEffect(orbData.type, hit.Position)
            end
            
            -- Animar clavija golpeada
            boardService:registerPegHit(hit)
            
            -- Publicar evento de daño aplicado
            self.eventBus:Publish("DamageDealt", damageAmount, orbData, hit)
        end
    end)
    
    -- Verificar si el orbe se detiene o cae fuera del tablero
    self:startOrbStateMonitoring(orbVisual, orbData)
end

-- Monitorea el estado de un orbe (si se detiene o cae)
function CombatService:startOrbStateMonitoring(orbVisual, orbData)
    local checkConnection
    checkConnection = RunService.Heartbeat:Connect(function()
        if not orbVisual or not orbVisual.Parent then
            checkConnection:Disconnect()
            return
        end
        
        -- Verificar si cayó fuera del tablero
        if orbVisual.Position.Y < -50 then
            print("CombatService: Orbe cayó fuera del tablero")
            
            -- Aplicar daño mínimo garantizado si no ha hecho daño
            if self.damageDealt == 0 then
                print("CombatService: No se registró daño, aplicando daño mínimo:", self.minDamagePerLaunch)
                
                local enemyService = self.serviceLocator:GetService("EnemyService")
                local effectsService = self.serviceLocator:GetService("EffectsService")
                
                if enemyService then
                    local killed = enemyService:takeDamage(self.minDamagePerLaunch, "NORMAL")
                    
                    if effectsService then
                        effectsService:showDamageNumber(
                            Vector3.new(0, 0, -30), 
                            self.minDamagePerLaunch, 
                            false, 
                            "¡Golpe automático!"
                        )
                    end
                end
            end
            
            orbVisual:Destroy()
            checkConnection:Disconnect()
            
            -- Publicar evento de orbe perdido
            self.eventBus:Publish("OrbLost", "FELL_OFF")
            return
        end
        
        -- Verificar si el orbe se detuvo
        local velocity = orbVisual.Velocity
        if velocity.Magnitude < Config.PHYSICS.MIN_BOUNCE_VELOCITY then
            local stillCounter = 0
            -- Verificar durante varios frames para asegurarse
            local stillCheckConnection
            stillCheckConnection = RunService.Heartbeat:Connect(function()
                if not orbVisual or not orbVisual.Parent then
                    stillCheckConnection:Disconnect()
                    return
                end
                
                if orbVisual.Velocity.Magnitude < Config.PHYSICS.MIN_BOUNCE_VELOCITY then
                    stillCounter = stillCounter + 1
                    
                    -- Si se mantiene detenido por suficiente tiempo
                    if stillCounter > 30 then
                        print("CombatService: Orbe se detuvo")
                        
                        -- Aplicar daño mínimo garantizado si no ha hecho daño
                        if self.damageDealt == 0 then
                            print("CombatService: No se registró daño, aplicando daño mínimo:", self.minDamagePerLaunch)
                            
                            local enemyService = self.serviceLocator:GetService("EnemyService")
                            local effectsService = self.serviceLocator:GetService("EffectsService")
                            
                            if enemyService then
                                local killed = enemyService:takeDamage(self.minDamagePerLaunch, "NORMAL")
                                
                                if effectsService then
                                    effectsService:showDamageNumber(
                                        Vector3.new(0, 0, -30), 
                                        self.minDamagePerLaunch, 
                                        false, 
                                        "¡Golpe automático!"
                                    )
                                end
                            end
                        end
                        
                        orbVisual:Destroy()
                        stillCheckConnection:Disconnect()
                        checkConnection:Disconnect()
                        
                        -- Publicar evento de orbe detenido
                        self.eventBus:Publish("OrbStopped")
                    end
                else
                    -- Se movió de nuevo, resetear contador
                    stillCounter = 0
                end
            end)
        end
    end)
end

-- Maneja la victoria sobre un enemigo
function CombatService:handleVictory(enemyType, position)
    print("CombatService: ¡Victoria sobre el enemigo " .. tostring(enemyType) .. "!")
    
    -- Publicar evento de victoria
    self.eventBus:Publish("BattleWon", enemyType, position)
    
    -- Limpiar colisiones activas
    if self.currentOrbConnection then
        self.currentOrbConnection:Disconnect()
        self.currentOrbConnection = nil
    end
end

-- Limpieza del servicio
function CombatService:Cleanup()
    -- Desconectar colisiones activas
    if self.currentOrbConnection then
        self.currentOrbConnection:Disconnect()
        self.currentOrbConnection = nil
    end
    
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Limpiar propiedades
    self.hitPegs = {}
    self.damageDealt = 0
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return CombatService