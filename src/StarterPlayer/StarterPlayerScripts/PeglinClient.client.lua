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

-- Logs
print("PeglinClient: Iniciando...")
print("PeglinClient: Estado inicial - isInitialized:", isInitialized, "isGameRunning:", isGameRunning, "launchReady:", launchReady)

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
        return false
    end
    
    EventBus = result
    print("PeglinClient: EventBus cargado correctamente")
    print("PeglinClient: Preparando suscripciones de eventos")

    -- Crear interfaz de usuario
    local ui = createLaunchUI()
    
    -- Suscribirse a eventos de estado del juego
    EventBus:Subscribe("GameStarted", function()
        print("PeglinClient: Evento GameStarted recibido")
        isGameRunning = true
        ui.label.Text = "¡Haga clic para lanzar un orbe!"
        ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        print("PeglinClient: Juego iniciado, esperando lanzamientos - isGameRunning:", isGameRunning, "launchReady:", launchReady)
    end)
    
    EventBus:Subscribe("GameEnded", function()
        print("PeglinClient: Evento GameEnded recibido")
        isGameRunning = false
        ui.label.Text = "Juego terminado"
        ui.label.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
        print("PeglinClient: Juego terminado - isGameRunning:", isGameRunning)
    end)
    
    EventBus:Subscribe("PlayerTurnStarted", function()
        print("PeglinClient: Evento PlayerTurnStarted recibido")
        launchReady = true
        ui.label.Text = "¡Su turno! Haga clic para lanzar un orbe"
        ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        print("PeglinClient: Turno del jugador iniciado - launchReady:", launchReady)
    end)
    
    EventBus:Subscribe("EnemyTurnStarted", function()
        print("PeglinClient: Evento EnemyTurnStarted recibido")
        launchReady = false
        ui.label.Text = "Turno del enemigo..."
        ui.label.BackgroundColor3 = Color3.fromRGB(100, 30, 30)
        print("PeglinClient: Turno del enemigo iniciado - launchReady:", launchReady)
    end)
    
    EventBus:Subscribe("OrbLaunched", function()
        print("PeglinClient: Evento OrbLaunched recibido")
        launchReady = false
        ui.label.Text = "Orbe en movimiento..."
        ui.label.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
        print("PeglinClient: Orbe lanzado - launchReady:", launchReady)
        
        -- Programar recuperación del lanzamiento
        spawn(function()
            wait(orbLaunchCooldown)
            launchReady = true
            if isGameRunning then
                ui.label.Text = "¡Listo para lanzar!"
                ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
                print("PeglinClient: Cooldown completado - launchReady:", launchReady)
            end
        end)
    end)

    -- Controlar el lanzamiento de orbes mediante clics
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        print("PeglinClient: Entrada detectada -", input.UserInputType.Name, "- gameProcessed:", gameProcessed)
        
        if gameProcessed then return end
        
        local isValidInput = 
            input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch
        
        if isValidInput then
            print("PeglinClient: Entrada válida detectada - isGameRunning:", isGameRunning, "launchReady:", launchReady)
            
            if isGameRunning and launchReady then
                -- Instrucciones de depuración ampliadas
                print("PeglinClient: Lanzamiento solicitado. Estado del juego:", isGameRunning, "Lanzamiento listo:", launchReady)
                
                -- Obtener dirección del clic
                local mousePosition = UserInputService:GetMouseLocation()
                local viewportSize = workspace.CurrentCamera.ViewportSize
                
                -- Calcular dirección normalizada (centro de la pantalla como origen)
                local directionX = (mousePosition.X - viewportSize.X/2) / (viewportSize.X/2)
                local directionY = (mousePosition.Y - viewportSize.Y/2) / (viewportSize.Y/2)
                
                -- La dirección estará entre -1 y 1 en ambos ejes, normalizar
                local direction = Vector3.new(directionX, -directionY, 0).Unit
                
                -- Asegúrate que el evento es realmente publicado:
                print("PeglinClient: Publicando evento PlayerClickedToLaunch con dirección:", direction)
                EventBus:Publish("PlayerClickedToLaunch", direction)
                
                -- Verificar suscriptores
                print("Suscriptores para PlayerClickedToLaunch:", EventBus:GetSubscriberCount("PlayerClickedToLaunch"))
                
                -- Intentar un evento alternativo como prueba
                print("PeglinClient: Intentando publicar evento OrbLaunched como prueba")
                EventBus:Publish("OrbLaunched", {Position = Vector3.new(0, 15, 0)}, {type = "BASIC"})
                
                -- Feedback visual para el usuario
                ui.label.Text = "¡Lanzando orbe!"
                ui.label.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
                
                print("PeglinClient: Lanzamiento solicitado en dirección: ", direction)
            elseif isGameRunning then
                print("PeglinClient: No se puede lanzar porque launchReady es falso")
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
            elseif launchReady then
                print("PeglinClient: No se puede lanzar porque isGameRunning es falso")
            else
                print("PeglinClient: No se puede lanzar porque ambos estados son falsos")
            end
        end
    end)
    
    -- Marcar como inicializado
    isInitialized = true
    print("PeglinClient: Inicializado correctamente")
    
    -- Solicitar inicio del juego
    print("PeglinClient: Buscando ServicesLoader")
    local peglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG")
    local servicesLoaderSuccess, servicesLoader = pcall(function() 
        return require(peglinRPG:WaitForChild("ServicesLoader")) 
    end)
    
    if servicesLoaderSuccess and servicesLoader then
        print("PeglinClient: ServicesLoader encontrado, intentando iniciar servicios")
        servicesLoader:LoadServices()
        servicesLoader:InitializeServices()
        servicesLoader:StartGame()
    else
        print("PeglinClient: Error al cargar ServicesLoader, intentando eventos directos")
        EventBus:Publish("ClientReady")
        EventBus:Publish("GameStarted")
        EventBus:Publish("PlayerTurnStarted")
    end   
     print("PeglinClient: Evento ClientReady publicado")
    
-- Añadir después del código anterior
-- Después de detectar que ServicesLoader fue encontrado, pero antes de llamar a LoadServices:
print("PeglinClient: Intentando crear directamente un tablero básico")

-- Cargar directamente el BoardService
local boardServicePath = peglinRPG:WaitForChild("Services"):WaitForChild("BoardService")
local success, boardService = pcall(function()
    return require(boardServicePath)
end)

if success and boardService then
    -- Crear una instancia básica del servicio
    local eventBusPath = peglinRPG:WaitForChild("Services"):WaitForChild("EventBus")
    local eventBus = require(eventBusPath)
    
    -- Crear una implementación básica de serviceLocator
    local basicServiceLocator = {
        GetService = function() return nil end,
        RegisterService = function() return nil end
    }
    
    -- Crear instancia del BoardService
    local boardServiceInstance = boardService.new(basicServiceLocator, eventBus)
    
    -- Inicializar
    boardServiceInstance:Initialize()
    
    -- Generar un tablero simple
    local boardConfig = {
        theme = "FOREST",
        pegColors = {
            BrickColor.new("Bright blue"),
            BrickColor.new("Bright green"),
            BrickColor.new("Bright red")
        }
    }
    
    -- Intentar crear el tablero
    print("PeglinClient: Generando tablero directamente")
    boardServiceInstance:generateBoard(60, 70, 120, boardConfig)
    
    -- Cambiar el estado del juego para que los clics funcionen
    isGameRunning = true
    ui.label.Text = "¡Tablero generado! Haga clic para interactuar"
    ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
else
    print("PeglinClient: No se pudo cargar BoardService directamente:", boardService)
end

-- Continuar con el intento normal (que probablemente fallará pero lo intentamos de todos modos)
servicesLoader:LoadServices()



    -- Forzar inicio de juego para depuración
    print("PeglinClient: Intentando iniciar el juego directamente")
    EventBus:Publish("GameStarted")
    EventBus:Publish("PlayerTurnStarted")
    
    return true
end

-- Ejecutar inicialización
local success = initialize()

if not success then
    warn("PeglinClient: No se pudo inicializar correctamente. Algunas características pueden no funcionar.")
    
    -- Mostrar mensaje de error al usuario
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