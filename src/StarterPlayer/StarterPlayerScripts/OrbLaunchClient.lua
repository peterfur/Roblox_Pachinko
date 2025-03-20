-- OrbLaunchClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Esperar a que el RemoteEvent esté disponible
local launchEvent
spawn(function()
    launchEvent = ReplicatedStorage:WaitForChild("DirectOrbLaunch", 10)
    if not launchEvent then
        warn("OrbLaunchClient: No se pudo encontrar el RemoteEvent DirectOrbLaunch")
        return
    end
    
    print("OrbLaunchClient: RemoteEvent encontrado, inicializando sistema de lanzamiento")
    
    -- Variables de estado
    local isReady = true
    local cooldown = 1 -- Segundos entre lanzamientos
    
    -- Función para lanzar un orbe
    local function launchOrb(direction, orbType)
        if not isReady then return end
        
        print("OrbLaunchClient: Enviando solicitud de lanzamiento al servidor")
        launchEvent:FireServer(direction, orbType)
        
        -- Aplicar cooldown
        isReady = false
        spawn(function()
            wait(cooldown)
            isReady = true
        end)
    end
    
    -- Detectar clics
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            -- Obtener dirección del clic
            local mousePosition = UserInputService:GetMouseLocation()
            local viewportSize = workspace.CurrentCamera.ViewportSize
            
            -- Calcular dirección
            local directionX = (mousePosition.X - viewportSize.X/2) / (viewportSize.X/2)
            local directionY = (mousePosition.Y - viewportSize.Y/2) / (viewportSize.Y/2)
            
            -- Limitar dirección vertical
            directionY = math.min(0.5, math.max(-1, directionY))
            
            -- Normalizar
            local direction = Vector3.new(directionX, -directionY, 0).Unit
            
            -- Lanzar orbe
            launchOrb(direction, "BASIC")
            
            print("OrbLaunchClient: Clic detectado, dirección calculada:", direction)
        end
    end)
    
    print("OrbLaunchClient: Inicializado, listo para lanzar orbes con clic")
end)