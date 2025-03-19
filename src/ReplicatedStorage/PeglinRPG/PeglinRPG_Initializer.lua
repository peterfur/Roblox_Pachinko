-- PeglinRPG_Initializer.lua
-- Punto de entrada refactorizado para la arquitectura actualizada
-- Este script inicia todo el sistema y maneja la carga de servicios

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Iniciar carga del sistema de servicios
local function InitializeGame()
    print("PeglinRPG: Iniciando carga del sistema...")
    
    -- Cargar módulo ServicesLoader
    local success, ServicesLoader = pcall(function()
        return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("ServicesLoader"))
    end)
    
    if not success then
        warn("PeglinRPG: Error al cargar ServicesLoader:", ServicesLoader)
        return false
    end
    
    print("PeglinRPG: ServicesLoader cargado correctamente")
    
    -- Cargar servicios principales
    local loadedServices = ServicesLoader:LoadServices()
    if #loadedServices == 0 then
        warn("PeglinRPG: No se pudo cargar ningún servicio")
        return false
    end
    
    -- Inicializar servicios
    ServicesLoader:InitializeServices()
    
    -- Configurar evento para iniciar el juego desde el cliente
    local EventBus = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EventBus"))
    EventBus:Subscribe("ClientReady", function()
        print("PeglinRPG: Cliente listo, iniciando juego...")
        ServicesLoader:StartGame()
    end)
    
    -- Comando de inicio manual para testing
    if game:GetService("RunService"):IsStudio() then
        -- Iniciar juego automáticamente en Studio para facilitar el testing
        print("PeglinRPG: Modo Studio detectado, iniciando juego automáticamente en 2 segundos...")
        spawn(function()
            wait(2)
            ServicesLoader:StartGame()
        end)
    end
    
    print("PeglinRPG: Sistema inicializado correctamente")
    return true
end

-- Ejecutar inicialización con manejo de errores
local success, result = pcall(InitializeGame)

if not success then
    warn("PeglinRPG: Error crítico durante la inicialización:", result)
    
    -- Realizar intento de recuperación básico
    spawn(function()
        print("PeglinRPG: Intentando recuperación básica...")
        wait(2)
        
        -- Iniciar directamente con eventos simplificados
        local EventBus = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EventBus"))
        EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
        wait(0.5)
        EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
        wait(0.5)
        EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
        EventBus:Publish("PlayerTurnStarted")
        
        print("PeglinRPG: Recuperación básica completada")
    end)
end

return {
    Initialize = InitializeGame -- Exponer la función para llamadas externas
}