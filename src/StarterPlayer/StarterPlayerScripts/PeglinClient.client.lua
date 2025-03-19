-- PeglinClient.client.lua
-- Cliente refactorizado para la nueva arquitectura de servicios de PeglinRPG

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constantes
local LOCAL_PLAYER = Players.LocalPlayer
local WAIT_TIMEOUT = 10 -- Segundos máximos de espera por módulos

-- Variables de estado
local isInitialized = false
local isGameRunning = false
local launchReady = true
local orbLaunchCooldown = 1 -- Segundos entre lanzamientos

-- Referencias a UI
local ui = nil

-- Logs
print("PeglinClient: Iniciando...")

-- Función para esperar módulos con timeout
local function waitForModule(path, timeout)
    local startTime = tick()
    local module
    
    repeat
        module = path:FindFirstChild("Services")
        if not module then
            wait(0.1)
        end
    until module or (tick() - startTime > timeout)
    
    if not module then
        warn("PeglinClient: No se pudo encontrar el módulo de servicios después de " .. timeout .. " segundos.")
        return nil
    end
    
    return module
end

-- Configuración de la cámara
local function setupCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.new(Vector3.new(0, 5, 35), Vector3.new(0, 0, 0))
    print("PeglinClient: Cámara configurada")
end

-- Crear interfaz para indicar estado del lanzamiento
local function createLaunchUI()
    local launchGui = Instance.new("ScreenGui")
    launchGui.Name = "PeglinLaunchUI"
    
    local indicator = Instance.new("TextLabel")
    indicator.Size = UDim2.new(0, 300, 0, 50)
    indicator.Position = UDim2.new(0.5, -150, 0.1, 0)
    indicator.AnchorPoint = Vector2.new(0, 0)
    indicator.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
    indicator.BackgroundTransparency = 0.3
    indicator.TextColor3 = Color3.fromRGB(255, 255, 255)
    indicator.Font = Enum.Font.SourceSansBold
    indicator.TextSize = 18
    indicator.Text = "¡Haga clic para lanzar un orbe!"
    indicator.TextWrapped = true
    indicator.BorderSizePixel = 2
    indicator.Parent = launchGui
    
    launchGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
    
    return {
        gui = launchGui,
        label = indicator
    }
end

-- Inicialización del cliente
local function initialize()
    print("PeglinClient: Inicializando...")
    
    -- Configurar cámara
    setupCamera()
    
    -- Esperar por el sistema de PeglinRPG
    local peglinFolder = ReplicatedStorage:WaitForChild("PeglinRPG", WAIT_TIMEOUT)
    if not peglinFolder then
        warn("PeglinClient: No se pudo encontrar la carpeta PeglinRPG.")
        return false
    end
    
    -- Esperar por los servicios
    local servicesFolder = waitForModule(peglinFolder, WAIT_TIMEOUT)
    if not servicesFolder then
        return false
    end
    
    -- Cargar EventBus
    local EventBus
    local success, result = pcall(function()
        return require(servicesFolder:WaitForChild("EventBus", WAIT_TIMEOUT))
    end)
    
    if not success or not result then
        warn("PeglinClient: No se pudo cargar EventBus: " .. tostring(result))
        
        -- Intentar cargar de manera alternativa
        success, result = pcall(function()
            return require(peglinFolder:WaitForChild("Services"):WaitForChild("EventBus"))
        end)
        
        if not success or not result then
            warn("PeglinClient: Segundo intento fallido para EventBus: " .. tostring(result))
            return false
        end
        
        EventBus = result
    else
        EventBus = result
    end
    
    print("PeglinClient: EventBus cargado correctamente")
    
    -- Crear interfaz de usuario
    ui = createLaunchUI()
    
    -- Suscribirse a eventos de estado del juego
    EventBus:Subscribe("GameStarted", function()
        print("PeglinClient: Evento GameStarted recibido")
        isGameRunning = true
        if ui and ui.label then
            ui.label.Text = "¡Haga clic para lanzar un orbe!"
            ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        end
    end)
    
    EventBus:Subscribe("GameEnded", function()
        isGameRunning = false
        if ui and ui.label then
            ui.label.Text = "Juego terminado"
            ui.label.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
        end
    end)
    
    EventBus:Subscribe("PlayerTurnStarted", function()
        print("PeglinClient: Evento PlayerTurnStarted recibido")
        launchReady = true
        if ui and ui.label then
            ui.label.Text = "¡Su turno! Haga clic para lanzar un orbe"
            ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        end
    end)
    
    EventBus:Subscribe("EnemyTurnStarted", function()
        launchReady = false
        if ui and ui.label then
            ui.label.Text = "Turno del enemigo..."
            ui.label.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
        end
    end)
    
    EventBus:Subscribe("OrbLaunched", function()
        print("PeglinClient: Evento OrbLaunched recibido")
        launchReady = false
        if ui and ui.label then
            ui.label.Text = "Orbe en movimiento..."
            ui.label.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
        end
        
        -- Programar recuperación del lanzamiento
        spawn(function()
            wait(orbLaunchCooldown)
            launchReady = true
            if isGameRunning and ui and ui.label then
                ui.label.Text = "¡Listo para lanzar!"
                ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
            end
        end)
    end)
    
    -- Controlar el lanzamiento de orbes mediante clics
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local isValidInput = 
            input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch
        
        if isValidInput and isGameRunning and launchReady then
            -- Mostrar estado actual
            print("PeglinClient: Lanzamiento solicitado. Estado del juego:", isGameRunning, "Lanzamiento listo:", launchReady)
            
            -- Obtener dirección del clic
            local mousePosition = UserInputService:GetMouseLocation()
            local viewportSize = workspace.CurrentCamera.ViewportSize
            
            -- Calcular dirección normalizada (centro de la pantalla como origen)
            local directionX = (mousePosition.X - viewportSize.X/2) / (viewportSize.X/2)
            local directionY = (mousePosition.Y - viewportSize.Y/2) / (viewportSize.Y/2)
            
            -- Limitar la dirección vertical para una mejor experiencia
            directionY = math.min(0.5, math.max(-1, directionY))
            
            -- La dirección estará entre -1 y 1 en ambos ejes, normalizar
            local direction = Vector3.new(directionX, -directionY, 0).Unit
            
            -- Logs para diagnóstico
            print("PeglinClient: Dirección calculada:", direction)
            
            -- Publicar evento para solicitar el lanzamiento
            EventBus:Publish("PlayerClickedToLaunch", direction)
            
            -- Feedback visual para el usuario
            if ui and ui.label then
                ui.label.Text = "¡Lanzando orbe!"
                ui.label.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
            end
            
            -- Simular la recepción del evento OrbLaunched si no se recibe en un tiempo razonable
            spawn(function()
                local startTime = tick()
                while launchReady and tick() - startTime < 1 do
                    wait(0.1)
                end
                
                if launchReady then
                    -- No se recibió evento OrbLaunched, forzar estado
                    launchReady = false
                    print("PeglinClient: Forzando cambio de estado por timeout")
                    
                    -- Auto-recuperación
                    spawn(function()
                        wait(orbLaunchCooldown)
                        launchReady = true
                        if isGameRunning and ui and ui.label then
                            ui.label.Text = "¡Listo para lanzar!"
                            ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
                        end
                    end)
                end
            end)
        elseif isValidInput and not launchReady and isGameRunning then
            if ui and ui.label then
                ui.label.Text = "Espere un momento..."
                -- Pequeño efecto visual para indicar que no puede lanzar aún
                local originalColor = ui.label.BackgroundColor3
                ui.label.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                spawn(function()
                    wait(0.2)
                    if ui and ui.label then
                        ui.label.BackgroundColor3 = originalColor
                    end
                end)
            end
        end
    end)
    
    -- Marcar como inicializado
    isInitialized = true
    print("PeglinClient: Inicializado correctamente")
    
    -- Publicar evento de cliente listo
    EventBus:Publish("ClientReady")
    print("PeglinClient: Evento ClientReady publicado")
    
    -- Forzar el inicio del juego para debugging
    spawn(function()
        wait(1)
        if not isGameRunning then
            print("PeglinClient: Forzando inicio del juego para debugging")
            EventBus:Publish("GameStartRequested")
        end
    end)
    
    return true
end

-- Ejecutar inicialización
local success = initialize()

if not success then
    warn("PeglinClient: No se pudo inicializar correctamente. Intentando método alternativo...")
    
    -- Intento alternativo de inicialización
    spawn(function()
        wait(2) -- Esperar un poco
        
        -- Intentar cargar directamente el inicializador principal
        local success, initializer = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("PeglinRPG_Initializer"))
        end)
        
        if success and initializer and typeof(initializer.Initialize) == "function" then
            print("PeglinClient: Intentando inicialización alternativa mediante PeglinRPG_Initializer...")
            initializer.Initialize()
            
            -- Configurar interfaz básica y cámara
            setupCamera()
            ui = createLaunchUI()
            
            -- Activar juego
            isGameRunning = true
            launchReady = true
        else
            -- Error crítico, mostrar mensaje al usuario
            local errorGui = Instance.new("ScreenGui")
            errorGui.Name = "PeglinErrorUI"
            
            local errorFrame = Instance.new("Frame")
            errorFrame.Size = UDim2.new(0, 300, 0, 100)
            errorFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
            errorFrame.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
            errorFrame.BorderSizePixel = 2
            
            local errorText = Instance.new("TextLabel")
            errorText.Size = UDim2.new(1, -20, 1, -20)
            errorText.Position = UDim2.new(0, 10, 0, 10)
            errorText.BackgroundTransparency = 1
            errorText.TextColor3 = Color3.fromRGB(255, 255, 255)
            errorText.Font = Enum.Font.SourceSansBold
            errorText.TextSize = 16
            errorText.Text = "Error de inicialización. Por favor, recargue el juego o contacte al desarrollador."
            errorText.TextWrapped = true
            errorText.Parent = errorFrame
            
            errorFrame.Parent = errorGui
            errorGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
        end
    end)
end