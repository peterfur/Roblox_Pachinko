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
local EventBus = nil -- Referencia global al EventBus

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
    
    -- Añadir indicador de estado para debugging
    local debugInfo = Instance.new("TextLabel")
    debugInfo.Size = UDim2.new(0, 300, 0, 100)
    debugInfo.Position = UDim2.new(0.5, -150, 0.2, 0)
    debugInfo.AnchorPoint = Vector2.new(0, 0)
    debugInfo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    debugInfo.BackgroundTransparency = 0.7
    debugInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugInfo.Font = Enum.Font.SourceSans
    debugInfo.TextSize = 14
    debugInfo.Text = "Estado: Esperando inicio\nJuego: No iniciado\nLanzamiento: No listo"
    debugInfo.TextWrapped = true
    debugInfo.BorderSizePixel = 0
    debugInfo.Parent = launchGui
    
    launchGui.Parent = LOCAL_PLAYER:WaitForChild("PlayerGui")
    
    return {
        gui = launchGui,
        label = indicator,
        debug = debugInfo
    }
end

-- Función para actualizar el estado de debugging
local function updateDebugInfo()
    if ui and ui.debug then
        ui.debug.Text = "Estado: " .. (isInitialized and "Inicializado" or "No inicializado") ..
                       "\nJuego: " .. (isGameRunning and "En ejecución" or "No iniciado") ..
                       "\nLanzamiento: " .. (launchReady and "Listo" or "No listo")
    end
end

-- Función para forzar el inicio del juego usando eventos directos
local function forceGameStart()
    if EventBus then
        print("PeglinClient: Verificando servicios antes de forzar inicio...")
        EventBus:Publish("TestBoardService")
    end
    if not EventBus then return end
    
    print("PeglinClient: Forzando inicio del juego con eventos directos")
    
    -- Publicar eventos en secuencia para forzar el inicio del juego
    EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
    wait(0.5) -- Pequeña pausa para permitir que el sistema procese
    wait(0.5)
    EventBus:Publish("ForceCreateBoard") -- Solicitar explícitamente la creación del tablero
    wait(0.8)
    EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
    -- Solicitar la generación del tablero con parámetros estándar
    EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
    wait(1) -- Esperar a que se genere el tablero
    
    -- Cambiar a la fase de turno del jugador
    EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
    EventBus:Publish("PlayerTurnStarted")
    
    -- Actualizar estado local
    isGameRunning = true
    launchReady = true
    updateDebugInfo()
    
    if ui and ui.label then
        ui.label.Text = "¡Juego iniciado! Haga clic para lanzar"
        ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
    end
end

-- Función para probar todos los sistemas críticos
local function testCriticalSystems()
    if not EventBus then return end
    
    print("PeglinClient: Enviando evento de prueba...")
    EventBus:Publish("TestEvent", "Prueba desde el cliente")
    
    -- Probar servicio de tablero
    EventBus:Publish("BoardRequested", 60, 70, 80, {theme = "FOREST"})
    
    -- Probar cambio de fase
    EventBus:Publish("PhaseChanged", "NONE", "PLAYER_TURN")
    
    print("PeglinClient: Eventos de prueba enviados")
end

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
    end
    
    EventBus = result
    print("PeglinClient: EventBus cargado correctamente")
    
    -- Crear interfaz de usuario
    ui = createLaunchUI()
    updateDebugInfo()
    
    -- Suscribirse a eventos de estado del juego
    EventBus:Subscribe("GameStarted", function()
        print("PeglinClient: Evento GameStarted recibido")
        isGameRunning = true
        updateDebugInfo()
        if ui and ui.label then
            ui.label.Text = "¡Haga clic para lanzar un orbe!"
            ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        end
    end)
    
    -- Resto de suscripciones a eventos...
    
    -- Marcar como inicializado
    isInitialized = true
    updateDebugInfo()
    print("PeglinClient: Inicializado correctamente")
    
    -- Publicar evento de cliente listo y solicitar inicio inmediato del juego
    EventBus:Publish("ClientReady")
    print("PeglinClient: Evento ClientReady publicado")
    
    -- Solicitar inicio inmediato del juego
    EventBus:Publish("StartGameWithImmediateLoading")
    print("PeglinClient: Solicitado inicio inmediato del juego")
    
    return true
end

-- Añade esta función para manejar el botón de lanzamiento de orbes
local function handleLaunchClick(input)
    if not isGameRunning or not launchReady then return end
    
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
    print("PeglinClient: Dirección calculada:", direction.X, direction.Y, direction.Z)
    
    -- Publicar evento para solicitar el lanzamiento
    EventBus:Publish("PlayerClickedToLaunch", direction)
    
    -- Feedback visual para el usuario
    if ui and ui.label then
        ui.label.Text = "¡Lanzando orbe!"
        ui.label.BackgroundColor3 = Color3.fromRGB(30, 30, 100)
    end
    
    -- Actualizar estado
    launchReady = false
    updateDebugInfo()
    
    -- Programar recuperación del lanzamiento
    spawn(function()
        wait(orbLaunchCooldown)
        launchReady = true
        updateDebugInfo()
        if isGameRunning and ui and ui.label then
            ui.label.Text = "¡Listo para lanzar!"
            ui.label.BackgroundColor3 = Color3.fromRGB(30, 100, 30)
        end
    end)
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
            updateDebugInfo()
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