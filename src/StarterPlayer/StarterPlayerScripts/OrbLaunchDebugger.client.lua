-- OrbLaunchDebugger.client.lua
-- Script para diagnosticar por qué los orbes no se lanzan correctamente

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local eventLog = {}
local errorMessages = {}
local diagnosticMode = false

-- Función para registrar eventos
local function logEvent(message)
    local timestamp = os.date("%H:%M:%S")
    table.insert(eventLog, timestamp .. " - " .. message)
    print("OrbDebugger: " .. message)
    
    -- Limitar el tamaño del log
    if #eventLog > 50 then
        table.remove(eventLog, 1)
    end
end

-- Función para registrar errores
local function logError(message)
    table.insert(errorMessages, message)
    warn("OrbDebugger ERROR: " .. message)
end

-- Crear interfaz de diagnóstico
local function createDebugUI()
    local debugGui = Instance.new("ScreenGui")
    debugGui.Name = "OrbDebuggerUI"
    debugGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(1, -410, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 2
    mainFrame.Visible = false -- Inicialmente oculto, se activa con tecla F8
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleLabel.BackgroundTransparency = 0.2
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "Depurador de Lanzamiento de Orbes"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 18
    titleLabel.Parent = mainFrame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 25)
    statusLabel.Position = UDim2.new(0, 5, 0, 35)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    statusLabel.Text = "Estado: Monitoreando lanzamientos"
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
    eventScrollFrame.Size = UDim2.new(1, -10, 0, 150)
    eventScrollFrame.Position = UDim2.new(0, 5, 0, 90)
    eventScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    eventScrollFrame.BackgroundTransparency = 0.5
    eventScrollFrame.BorderSizePixel = 1
    eventScrollFrame.ScrollBarThickness = 8
    eventScrollFrame.Parent = mainFrame
    
    local eventList = Instance.new("TextLabel")
    eventList.Size = UDim2.new(1, -15, 0, 500) -- Altura dinámica
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
    errorLogLabel.Position = UDim2.new(0, 5, 0, 245)
    errorLogLabel.BackgroundTransparency = 1
    errorLogLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
    errorLogLabel.Text = "Problemas Detectados:"
    errorLogLabel.Font = Enum.Font.SourceSansBold
    errorLogLabel.TextSize = 14
    errorLogLabel.TextXAlignment = Enum.TextXAlignment.Left
    errorLogLabel.Parent = mainFrame
    
    local errorList = Instance.new("TextLabel")
    errorList.Size = UDim2.new(1, -10, 0, 50)
    errorList.Position = UDim2.new(0, 5, 0, 270)
    errorList.BackgroundTransparency = 1
    errorList.TextColor3 = Color3.fromRGB(255, 100, 100)
    errorList.Text = "Sin problemas hasta ahora"
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
        -- Actualizar eventos
        local eventText = ""
        for i = #eventLog, 1, -1 do
            eventText = eventText .. eventLog[i] .. "\n"
        end
        
        if eventText == "" then
            eventText = "No se han registrado eventos"
        end
        
        eventList.Text = eventText
        eventList.Size = UDim2.new(1, -15, 0, math.max(500, 20 * #eventLog))
        
        -- Actualizar errores
        local errorText = ""
        for i, error in ipairs(errorMessages) do
            errorText = errorText .. i .. ". " .. error .. "\n"
        end
        
        if errorText == "" then
            errorText = "Sin problemas hasta ahora"
        end
        
        errorList.Text = errorText
    end
    
    -- Configurar tecla F8 para mostrar/ocultar la UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F8 then
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
    
    logEvent("UI de depuración configurada. Presiona F8 para mostrar/ocultar.")
    
    return {
        updateUI = updateDebugUI
    }
end

-- Cargar el EventBus para monitorear eventos
local function setupEventMonitoring()
    local PeglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG", 10)
    if not PeglinRPG then
        logError("No se encontró el módulo PeglinRPG")
        return nil
    end
    
    local Services = PeglinRPG:WaitForChild("Services", 10)
    if not Services then
        logError("No se encontró la carpeta Services")
        return nil
    end
    
    local success, EventBus = pcall(function()
        return require(Services:WaitForChild("EventBus", 10))
    end)
    
    if not success or not EventBus then
        logError("No se pudo cargar EventBus: " .. tostring(EventBus))
        return nil
    end
    
    logEvent("EventBus cargado correctamente")
    
    -- Monitorear eventos relacionados con orbes
    EventBus:Subscribe("OrbLaunched", function(orbVisual, orbData)
        logEvent("Evento OrbLaunched recibido. Tipo de orbe: " .. (orbData.type or "Desconocido"))
        
        -- Verificar el objeto visual
        if orbVisual and orbVisual:IsA("BasePart") then
            logEvent("- Orbe visual válido: " .. orbVisual.Name)
            logEvent("- Posición: " .. tostring(orbVisual.Position))
            logEvent("- Velocidad: " .. tostring(orbVisual.Velocity.Magnitude))
        else
            logError("Orbe visual inválido o no es una parte")
        end
    end)
    
    EventBus:Subscribe("PlayerClickedToLaunch", function(direction)
        logEvent("Evento PlayerClickedToLaunch recibido. Dirección: " .. tostring(direction))
    end)
    
    EventBus:Subscribe("OrbLaunchRequested", function(direction, position)
        logEvent("Evento OrbLaunchRequested recibido")
    end)
    
    EventBus:Subscribe("PlayerTurnStarted", function()
        logEvent("Evento PlayerTurnStarted recibido - El jugador puede lanzar")
    end)
    
    return EventBus
end

-- Monitorear clics del usuario para diagnóstico
local function monitorUserClicks()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Solo monitorear en modo diagnóstico
        if not diagnosticMode and input.KeyCode ~= Enum.KeyCode.O then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            logEvent("Clic detectado en pantalla")
            
            -- Obtener información sobre la posición del clic
            local mousePosition = UserInputService:GetMouseLocation()
            local viewportSize = workspace.CurrentCamera.ViewportSize
            
            -- Calcular dirección normalizada (centro de la pantalla como origen)
            local directionX = (mousePosition.X - viewportSize.X/2) / (viewportSize.X/2)
            local directionY = (mousePosition.Y - viewportSize.Y/2) / (viewportSize.Y/2)
            
            -- Limitar la dirección vertical para una mejor experiencia
            directionY = math.min(0.5, math.max(-1, directionY))
            
            -- La dirección estará entre -1 y 1 en ambos ejes, normalizar
            local direction = Vector3.new(directionX, -directionY, 0).Unit
            
            logEvent("- Posición del clic: " .. tostring(mousePosition))
            logEvent("- Dirección calculada: " .. tostring(direction))
        end
    end)
    
    -- Activar/desactivar modo diagnóstico con tecla "O"
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.O then
            diagnosticMode = not diagnosticMode
            logEvent("Modo diagnóstico de clics: " .. (diagnosticMode and "ACTIVADO" or "DESACTIVADO"))
        end
    end)
end

-- Verificar si existen orbes en la escena
local function checkExistingOrbs()
    local orbs = {}
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name:find("Orb") or child.Name:find("PeglinOrb") then
            table.insert(orbs, child)
        end
    end
    
    if #orbs > 0 then
        logEvent("Se encontraron " .. #orbs .. " orbes en la escena:")
        for i, orb in ipairs(orbs) do
            logEvent("- Orbe " .. i .. ": " .. orb.Name .. " (Posición: " .. tostring(orb.Position) .. ", Velocidad: " .. tostring(orb.Velocity.Magnitude) .. ")")
        end
    else
        logEvent("No se encontraron orbes en la escena")
    end
end

-- Verificar servicios relacionados con orbes
local function checkOrbServices()
    local PeglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG", 10)
    if not PeglinRPG then
        logError("No se encontró el módulo PeglinRPG")
        return false
    end
    
    local services = PeglinRPG:WaitForChild("Services", 10)
    if not services then
        logError("No se encontró la carpeta Services")
        return false
    end
    
    -- Verificar servicios críticos
    local criticalServices = {
        "OrbService",
        "GameplayService",
        "PhysicsService"
    }
    
    local servicesFound = {}
    local missingServices = {}
    
    for _, serviceName in ipairs(criticalServices) do
        local service = services:FindFirstChild(serviceName)
        if service then
            table.insert(servicesFound, serviceName)
        else
            table.insert(missingServices, serviceName)
        end
    end
    
    if #servicesFound > 0 then
        logEvent("Servicios encontrados: " .. table.concat(servicesFound, ", "))
    end
    
    if #missingServices > 0 then
        logError("Servicios faltantes: " .. table.concat(missingServices, ", "))
    end
    
    return #missingServices == 0
end

-- Crear y lanzar un orbe manualmente
local function createAndLaunchOrb(position, direction)
    if not position then
        position = Vector3.new(0, 15, 0) -- Posición por defecto
        
        -- Buscar punto de entrada en el tablero
        local board = workspace:FindFirstChild("PeglinBoard_FOREST")
        if board then
            for _, child in pairs(board:GetChildren()) do
                if child:GetAttribute("LaunchPosition") then
                    local launchPos = child:GetAttribute("LaunchPosition")
                    if typeof(launchPos) == "Vector3" then
                        position = launchPos
                        break
                    end
                end
            end
        end
    end
    
    if not direction then
        direction = Vector3.new(0, -1, 0) -- Dirección por defecto
    end
    
    logEvent("Creando orbe manual en posición " .. tostring(position))
    
    -- Crear orbe básico
    local orb = Instance.new("Part")
    orb.Name = "ManualTestOrb"
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(2.5, 2.5, 2.5)
    orb.Position = position
    orb.Color = Color3.fromRGB(255, 255, 0)
    orb.Material = Enum.Material.Neon
    orb.Anchored = false
    orb.CanCollide = true
    
    -- Propiedades físicas
    orb.CustomPhysicalProperties = PhysicalProperties.new(
        2.5,   -- Densidad
        0.2,   -- Fricción
        0.6,   -- Elasticidad
        1.0,   -- Peso
        0.6    -- Fricción rotacional
    )
    
    -- Añadir efecto visual
    local light = Instance.new("PointLight")
    light.Brightness = 0.8
    light.Range = 8
    light.Color = Color3.fromRGB(255, 255, 0)
    light.Parent = orb
    
    -- Configurar detección de colisiones para depuración
    orb.Touched:Connect(function(hit)
        if hit:GetAttribute("IsPeg") then
            logEvent("Orbe golpeó clavija: " .. hit:GetFullName())
            
            -- Verificar contador de golpes
            local hitCount = hit:GetAttribute("HitCount") or 0
            hit:SetAttribute("HitCount", hitCount + 1)
            
            -- Animar brevemente la clavija
            local originalColor = hit.Color
            hit.Color = Color3.fromRGB(255, 255, 255)
            
            spawn(function()
                wait(0.1)
                hit.Color = originalColor
            end)
        elseif hit:GetAttribute("IsBorder") then
            logEvent("Orbe golpeó borde: " .. hit:GetFullName())
        end
    end)
    
    orb.Parent = workspace
    
    -- Aplicar impulso después de un frame para asegurar física correcta
    spawn(function()
        wait()  -- Esperar un frame
        logEvent("Lanzando orbe en dirección " .. tostring(direction))
        
        -- Aplicar impulso
        local speed = 35
        local impulse = direction * speed * orb:GetMass()
        orb:ApplyImpulse(impulse)
        
        -- Verificar que el impulso se aplicó
        wait(0.1)
        logEvent("Velocidad del orbe después del impulso: " .. tostring(orb.Velocity.Magnitude))
    end)
    
    -- Monitorear el orbe
    spawn(function()
        local startTime = tick()
        local maxMonitorTime = 5  -- 5 segundos máximo
        
        while orb and orb.Parent and (tick() - startTime) < maxMonitorTime do
            wait(0.5)
            logEvent("Estado del orbe - Posición: " .. tostring(orb.Position) .. ", Velocidad: " .. tostring(orb.Velocity.Magnitude))
        end
        
        if orb and orb.Parent then
            logEvent("Fin del monitoreo del orbe (tiempo máximo alcanzado)")
        else
            logEvent("Orbe destruido o fuera de la escena")
        end
    end)
    
    return orb
end

-- Función principal
local function startDebugger()
    logEvent("OrbLaunchDebugger iniciado")
    
    -- Crear UI de diagnóstico
    local debugUI = createDebugUI()
    
    -- Configurar monitoreo de eventos
    local EventBus = setupEventMonitoring()
    
    -- Verificar servicios relacionados con orbes
    checkOrbServices()
    
    -- Verificar orbes existentes
    checkExistingOrbs()
    
    -- Configurar monitoreo de clics
    monitorUserClicks()
    
    -- Verificar periódicamente
    spawn(function()
        while true do
            wait(10)
            checkExistingOrbs()
        end
    end)
    
    -- Crear función global para lanzar orbe manual
    _G.TestLaunchOrb = function(direction)
        direction = direction or Vector3.new(0, -1, 0)
        return createAndLaunchOrb(nil, direction)
    end
    
    -- Hacer diagnóstico de orbes con tecla F7
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F7 then
            logEvent("Iniciando diagnóstico completo de orbes (F7)...")
            
            -- Verificar servicios
            checkOrbServices()
            
            -- Verificar orbes existentes
            checkExistingOrbs()
            
            -- Crear un orbe de prueba
            createAndLaunchOrb()
            
            -- Intentar forzar el flujo del juego
            if EventBus then
                EventBus:Publish("PlayerTurnStarted")
                logEvent("Evento PlayerTurnStarted forzado")
            end
        end
    end)
    
    logEvent("OrbLaunchDebugger configurado completamente")
    print("OrbLaunchDebugger: Presiona F8 para ver el depurador, F7 para prueba de orbe, O para activar diagnóstico de clics")
end

-- Iniciar el depurador
startDebugger()