-- BoardCreationDebugger.client.lua
-- Script dedicado a diagnosticar por qué no aparece el tablero al iniciar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local boardCheckInterval = 0.5 -- Segundos entre verificaciones
local maxBoardChecks = 20 -- Número máximo de verificaciones

-- Variables de seguimiento
local boardCreationAttempted = false
local boardCreationSucceeded = false
local eventBusCalled = false
local errorMessages = {}
local eventLog = {}
local moduleLoadStatus = {}

-- Configuración de UI de diagnóstico
local function setupDebugUI()
    local debugGui = Instance.new("ScreenGui")
    debugGui.Name = "BoardDebuggerUI"
    debugGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 2
    mainFrame.Visible = false -- Inicialmente oculto, se activa con tecla F9
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleLabel.BackgroundTransparency = 0.2
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "Depurador de Creación del Tablero"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 18
    titleLabel.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 25)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    statusLabel.Text = "Estado: Monitoreando..."
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 16
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = mainFrame
    
    local eventLogLabel = Instance.new("TextLabel")
    eventLogLabel.Size = UDim2.new(1, -10, 0, 20)
    eventLogLabel.Position = UDim2.new(0, 5, 0, 65)
    eventLogLabel.BackgroundTransparency = 1
    eventLogLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    eventLogLabel.Text = "Registro de Eventos:"
    eventLogLabel.Font = Enum.Font.SourceSansBold
    eventLogLabel.TextSize = 14
    eventLogLabel.TextXAlignment = Enum.TextXAlignment.Left
    eventLogLabel.Parent = mainFrame
    
    local eventScrollFrame = Instance.new("ScrollingFrame")
    eventScrollFrame.Size = UDim2.new(1, -10, 0, 120)
    eventScrollFrame.Position = UDim2.new(0, 5, 0, 90)
    eventScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    eventScrollFrame.BackgroundTransparency = 0.5
    eventScrollFrame.BorderSizePixel = 1
    eventScrollFrame.ScrollBarThickness = 8
    eventScrollFrame.Parent = mainFrame
    
    local eventList = Instance.new("TextLabel")
    eventList.Size = UDim2.new(1, -15, 0, 200) -- Altura dinámica
    eventList.Position = UDim2.new(0, 5, 0, 5)
    eventList.BackgroundTransparency = 1
    eventList.TextColor3 = Color3.fromRGB(200, 200, 200)
    eventList.Text = "Esperando eventos..."
    eventList.Font = Enum.Font.SourceSans
    eventList.TextSize = 14
    eventList.TextXAlignment = Enum.TextXAlignment.Left
    eventList.TextYAlignment = Enum.TextYAlignment.Top
    eventList.TextWrapped = true
    eventList.Parent = eventScrollFrame
    
    local errorLogLabel = Instance.new("TextLabel")
    errorLogLabel.Size = UDim2.new(1, -10, 0, 20)
    errorLogLabel.Position = UDim2.new(0, 5, 0, 215)
    errorLogLabel.BackgroundTransparency = 1
    errorLogLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    errorLogLabel.Text = "Errores Detectados:"
    errorLogLabel.Font = Enum.Font.SourceSansBold
    errorLogLabel.TextSize = 14
    errorLogLabel.TextXAlignment = Enum.TextXAlignment.Left
    errorLogLabel.Parent = mainFrame
    
    local errorList = Instance.new("TextLabel")
    errorList.Size = UDim2.new(1, -10, 0, 50)
    errorList.Position = UDim2.new(0, 5, 0, 240)
    errorList.BackgroundTransparency = 1
    errorList.TextColor3 = Color3.fromRGB(255, 100, 100)
    errorList.Text = "Sin errores hasta ahora"
    errorList.Font = Enum.Font.SourceSans
    errorList.TextSize = 14
    errorList.TextXAlignment = Enum.TextXAlignment.Left
    errorList.TextYAlignment = Enum.TextYAlignment.Top
    errorList.TextWrapped = true
    errorList.Parent = mainFrame
    
    mainFrame.Parent = debugGui
    debugGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    -- Función para actualizar la UI
    local function updateDebugUI()
        -- Actualizar estado
        local status = "Desconocido"
        local statusColor = Color3.fromRGB(255, 255, 100)
        
        if boardCreationSucceeded then
            status = "ÉXITO: Tablero creado"
            statusColor = Color3.fromRGB(100, 255, 100)
        elseif boardCreationAttempted then
            status = "ERROR: Intento de creación fallido"
            statusColor = Color3.fromRGB(255, 100, 100)
        elseif eventBusCalled then
            status = "PENDIENTE: EventBus llamado, esperando creación"
            statusColor = Color3.fromRGB(255, 200, 100)
        else
            status = "PENDIENTE: Esperando inicio"
            statusColor = Color3.fromRGB(200, 200, 255)
        end
        
        statusLabel.Text = "Estado: " .. status
        statusLabel.TextColor3 = statusColor
        
        -- Actualizar eventos
        local eventText = ""
        for i = #eventLog, 1, -1 do
            eventText = eventText .. eventLog[i] .. "\n"
        end
        
        if eventText == "" then
            eventText = "No se han registrado eventos"
        end
        
        eventList.Text = eventText
        eventList.Size = UDim2.new(1, -15, 0, math.max(200, 20 * #eventLog))
        
        -- Actualizar errores
        local errorText = ""
        for i, error in ipairs(errorMessages) do
            errorText = errorText .. i .. ". " .. error .. "\n"
        end
        
        if errorText == "" then
            errorText = "Sin errores hasta ahora"
        end
        
        errorList.Text = errorText
    end
    
    -- Configurar tecla F9 para mostrar/ocultar la UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F9 then
            mainFrame.Visible = not mainFrame.Visible
            updateDebugUI()
        end
    end)
    
    -- Actualizar la UI cada segundo
    spawn(function()
        while true do
            updateDebugUI()
            wait(1)
        end
    end)
    
    print("BoardCreationDebugger: UI de depuración configurada. Presiona F9 para mostrar/ocultar.")
    
    return {
        updateUI = updateDebugUI
    }
end

-- Función para registrar evento
local function logEvent(message)
    local timestamp = os.date("%H:%M:%S")
    table.insert(eventLog, timestamp .. " - " .. message)
    print("BoardDebugger: " .. message)
    
    -- Limitar el tamaño del log
    if #eventLog > 50 then
        table.remove(eventLog, 1)
    end
end

-- Función para registrar error
local function logError(message)
    table.insert(errorMessages, message)
    warn("BoardDebugger ERROR: " .. message)
end

-- Verificar si existe el tablero
local function checkBoardExists()
    local board = workspace:FindFirstChild("PeglinBoard_FOREST") or 
                  workspace:FindFirstChild("EmergencyBoard")
    
    if board then
        boardCreationSucceeded = true
        logEvent("Tablero encontrado: " .. board.Name)
        return true
    end
    
    return false
end

-- Verificar carga de módulos críticos
local function checkCriticalModules()
    local peglinRPG = ReplicatedStorage:FindFirstChild("PeglinRPG")
    if not peglinRPG then
        logError("No se encontró la carpeta PeglinRPG en ReplicatedStorage")
        return false
    end
    
    local services = peglinRPG:FindFirstChild("Services")
    if not services then
        logError("No se encontró la carpeta Services en PeglinRPG")
        return false
    end
    
    local modulesToCheck = {
        "ServiceLocator",
        "EventBus",
        "BoardService",
        "GameplayService"
    }
    
    for _, moduleName in ipairs(modulesToCheck) do
        local module = services:FindFirstChild(moduleName)
        if not module then
            logError("No se encontró el módulo " .. moduleName)
            moduleLoadStatus[moduleName] = false
        else
            moduleLoadStatus[moduleName] = true
            logEvent("Módulo encontrado: " .. moduleName)
        end
    end
    
    -- Verificar también los módulos del tablero
    local board = peglinRPG:FindFirstChild("Board")
    if not board then
        logError("No se encontró la carpeta Board en PeglinRPG")
        return false
    end
    
    local boardModules = {
        "BorderFactory",
        "PegFactory",
        "CollisionHandler"
    }
    
    for _, moduleName in ipairs(boardModules) do
        local module = board:FindFirstChild(moduleName)
        if not module then
            logError("No se encontró el módulo de tablero " .. moduleName)
            moduleLoadStatus[moduleName] = false
        else
            moduleLoadStatus[moduleName] = true
            logEvent("Módulo de tablero encontrado: " .. moduleName)
        end
    end
    
    return true
end

-- Cargar EventBus e intentar comunicarse
local function setupEventMonitoring()
    local success, EventBus
    
    success, EventBus = pcall(function()
        local peglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG")
        local services = peglinRPG:WaitForChild("Services")
        return require(services:WaitForChild("EventBus"))
    end)
    
    if not success or not EventBus then
        logError("No se pudo cargar EventBus: " .. tostring(EventBus))
        return false
    end
    
    logEvent("EventBus cargado correctamente")
    
    -- Suscribirse a eventos importantes
    EventBus:Subscribe("BoardRequested", function(width, height, pegCount, options)
        logEvent("Evento BoardRequested recibido: " .. width .. "x" .. height .. ", " .. pegCount .. " clavijas")
        boardCreationAttempted = true
        eventBusCalled = true
    end)
    
    EventBus:Subscribe("BoardGenerated", function(board, width, height, theme)
        logEvent("Evento BoardGenerated recibido: " .. width .. "x" .. height .. ", tema " .. theme)
        boardCreationSucceeded = true
    end)
    
    EventBus:Subscribe("GameStarted", function()
        logEvent("Evento GameStarted recibido")
    end)
    
    EventBus:Subscribe("SystemInitialized", function()
        logEvent("Evento SystemInitialized recibido")
    end)
    
    EventBus:Subscribe("ClientReady", function()
        logEvent("Evento ClientReady recibido")
    end)
    
    -- Método para forzar la creación del tablero
    local function forceCreateBoard()
        logEvent("Intentando forzar la creación del tablero...")
        EventBus:Publish("ForceRecreateBoard")
        EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
        
        -- También enviar evento de inicio de juego
        EventBus:Publish("GameStartRequested")
        eventBusCalled = true
    end
    
    -- Suscribirse a evento personalizado de diagnóstico
    EventBus:Subscribe("BoardDiagnosticsRequested", function()
        logEvent("Iniciando diagnóstico completo del tablero")
        
        -- Verificar estado actual
        if checkBoardExists() then
            logEvent("El tablero ya existe, diagnóstico finalizado")
            return
        end
        
        -- Verificar módulos
        checkCriticalModules()
        
        -- Intentar forzar la creación
        forceCreateBoard()
    end)
    
    -- Añadir método para publicar ese evento desde el exterior
    _G.RequestBoardDiagnostics = function()
        EventBus:Publish("BoardDiagnosticsRequested")
    end
    
    -- Añadir tecla específica para diagnóstico
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.B then
            logEvent("Tecla B presionada - Iniciando diagnóstico de tablero")
            forceCreateBoard()
        end
    end)
    
    return EventBus
end

-- Monitorear la carga inicial del juego
local function monitorInitialLoading()
    logEvent("Iniciando monitoreo de carga inicial")
    local checkCount = 0
    
    -- Verificar si el tablero ya existe
    if checkBoardExists() then
        logEvent("Tablero existente encontrado inmediatamente")
        return
    end
    
    -- Verificar periódicamente
    while checkCount < maxBoardChecks do
        wait(boardCheckInterval)
        checkCount = checkCount + 1
        
        logEvent("Verificación " .. checkCount .. " - Buscando tablero...")
        
        if checkBoardExists() then
            logEvent("Tablero encontrado después de " .. checkCount .. " verificaciones")
            return
        end
        
        -- Si ha pasado suficiente tiempo, verificar módulos críticos
        if checkCount == 5 then
            checkCriticalModules()
        end
        
        -- Si ha pasado más tiempo y sigue sin tablero, intentar forzarlo
        if checkCount == 10 and not boardCreationSucceeded then
            logEvent("No se encontró tablero después de " .. checkCount .. " verificaciones, intentando forzar creación")
            _G.RequestBoardDiagnostics()
        end
    end
    
    if not boardCreationSucceeded then
        logError("No se pudo crear el tablero después de " .. maxBoardChecks .. " intentos")
    end
end

-- Función principal
local function startDebugger()
    logEvent("BoardCreationDebugger iniciado")
    
    -- Configurar UI de diagnóstico
    local debugUI = setupDebugUI()
    
    -- Verificar módulos críticos
    checkCriticalModules()
    
    -- Configurar monitoreo de eventos
    local EventBus = setupEventMonitoring()
    
    -- Monitorear carga inicial
    spawn(monitorInitialLoading)
    
    logEvent("BoardCreationDebugger configurado completamente")
    print("BoardCreationDebugger: Presiona B para forzar creación del tablero o F9 para ver diagnóstico")
end

-- Iniciar el depurador
startDebugger()