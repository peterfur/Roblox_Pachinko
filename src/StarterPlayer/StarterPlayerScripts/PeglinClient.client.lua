-- PeglinClient.lua
-- Este script maneja la interfaz del cliente y las entradas del usuario
-- Debe colocarse como un LocalScript en StarterPlayerScripts

print("PeglinClient iniciando...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Esperando al evento con un timeout más largo y mejor manejo de errores
local function waitForLaunchEvent()
	local maxAttempts = 10
	local attempts = 0
	local launchEvent

	repeat
		attempts = attempts + 1
		launchEvent = ReplicatedStorage:FindFirstChild("PeglinRPG") and 
			ReplicatedStorage.PeglinRPG:FindFirstChild("PeglinLaunchEvent")

		if not launchEvent and attempts < maxAttempts then
			print("Intento " .. attempts .. ": Esperando evento de lanzamiento...")
			wait(1) -- Esperar 1 segundo entre intentos
		end
	until launchEvent or attempts >= maxAttempts

	if not launchEvent then
		warn("No se pudo encontrar el evento de lanzamiento después de " .. maxAttempts .. " intentos")

		-- Creamos una UI para informar al usuario
		local player = Players.LocalPlayer
		if player then
			local errorScreen = Instance.new("ScreenGui")
			errorScreen.Name = "PeglinErrorScreen"

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 400, 0, 200)
			frame.Position = UDim2.new(0.5, -200, 0.5, -100)
			frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			frame.BorderSizePixel = 0
			frame.Parent = errorScreen

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 0, 50)
			title.Position = UDim2.new(0, 0, 0, 0)
			title.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			title.Font = Enum.Font.SourceSansBold
			title.TextSize = 24
			title.Text = "Error de Conexión"
			title.Parent = frame

			local message = Instance.new("TextLabel")
			message.Size = UDim2.new(1, -20, 0, 100)
			message.Position = UDim2.new(0, 10, 0, 60)
			message.BackgroundTransparency = 1
			message.TextColor3 = Color3.fromRGB(255, 255, 255)
			message.Font = Enum.Font.SourceSans
			message.TextSize = 16
			message.TextWrapped = true
			message.Text = "No se pudo conectar con el servidor de juego. Por favor, intenta recargar el juego o contacta al desarrollador si el problema persiste."
			message.Parent = frame

			local button = Instance.new("TextButton")
			button.Size = UDim2.new(0, 100, 0, 30)
			button.Position = UDim2.new(0.5, -50, 1, -40)
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Font = Enum.Font.SourceSansBold
			button.TextSize = 16
			button.Text = "Aceptar"
			button.Parent = frame

			button.MouseButton1Click:Connect(function()
				errorScreen:Destroy()
			end)

			errorScreen.Parent = player.PlayerGui
		end

		return nil
	end

	print("Evento de lanzamiento encontrado")
	return launchEvent
end

-- Esperar a que el juego esté inicializado
local function waitForGameInitialization()
	-- Verificar que la carpeta principal exista
	local peglinFolder = ReplicatedStorage:WaitForChild("PeglinRPG", 10)
	if not peglinFolder then
		warn("No se pudo encontrar la carpeta PeglinRPG")
		return false
	end

	print("Carpeta PeglinRPG encontrada")

	-- Obtener el evento de lanzamiento
	local launchEvent = waitForLaunchEvent()
	if not launchEvent then
		return false
	end

	return true, launchEvent
end

-- Configurar la cámara para una mejor vista
local function setupCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		warn("No se pudo acceder a la cámara")
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Posición para ver bien el tablero
	camera.CFrame = CFrame.new(Vector3.new(0, 5, 35), Vector3.new(0, 0, 0))

	print("Cámara configurada")
end

-- Manejar interacciones del usuario
-- Modificación para el archivo PeglinClient.client.lua para mejorar la detección de clics

-- Función para manejar los clics y el lanzamiento de orbes
local function setupInputHandling(launchEvent)
    -- Variables para el estado de lanzamiento
    local isReadyToLaunch = true
    local lastLaunchTime = 0
    local launchCooldown = 1 -- Tiempo en segundos entre lanzamientos
    
    -- Añadir indicador visual de lanzamiento
    local function createLaunchIndicator()
        -- Crear un indicador visual que muestre que se puede lanzar
        local launchReady = Instance.new("ScreenGui")
        launchReady.Name = "PeglinLaunchIndicator"
        
        local readyFrame = Instance.new("Frame")
        readyFrame.Size = UDim2.new(0, 200, 0, 50)
        readyFrame.Position = UDim2.new(0.5, -100, 0.05, 0)
        readyFrame.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        readyFrame.BackgroundTransparency = 0.3
        readyFrame.BorderSizePixel = 2
        readyFrame.Parent = launchReady
        
        local readyText = Instance.new("TextLabel")
        readyText.Size = UDim2.new(1, 0, 1, 0)
        readyText.BackgroundTransparency = 1
        readyText.TextColor3 = Color3.fromRGB(255, 255, 255)
        readyText.Font = Enum.Font.SourceSansBold
        readyText.TextSize = 18
        readyText.Text = "¡HAGA CLIC PARA LANZAR!"
        readyText.Parent = readyFrame
        
        launchReady.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        
        return launchReady, readyText
    end
    
    local launchIndicator, indicatorText = createLaunchIndicator()
    
    -- Actualizar el indicador de lanzamiento
    local function updateLaunchIndicator()
        if isReadyToLaunch then
            indicatorText.Text = "¡HAGA CLIC PARA LANZAR!"
            launchIndicator.Enabled = true
        else
            local timeLeft = math.max(0, launchCooldown - (tick() - lastLaunchTime))
            if timeLeft > 0 then
                indicatorText.Text = "Preparando siguiente orbe... " .. string.format("%.1f", timeLeft)
            else
                isReadyToLaunch = true
                indicatorText.Text = "¡HAGA CLIC PARA LANZAR!"
            end
        end
    end
    
    -- Iniciar bucle de actualización
    spawn(function()
        while wait(0.1) do
            updateLaunchIndicator()
        end
    end)
    
    -- Manejar el clic tanto con el mouse como con toque móvil
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local isValidInput = 
            input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch
        
        if isValidInput and isReadyToLaunch then
            -- Obtener posición del clic
            local inputPosition
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                inputPosition = UserInputService:GetMouseLocation()
            else
                inputPosition = input.Position
            end
            
            -- Convertir posición a un vector de dirección
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local centerX = viewportSize.X/2
            local centerY = viewportSize.Y/2
            
            -- Calcular dirección relativa al centro
            local dirX = (inputPosition.X - centerX) / 100
            local dirY = (inputPosition.Y - centerY) / 100
            
            -- Mantener un componente vertical negativo para que siempre vaya hacia arriba al inicio
            local direction = Vector3.new(dirX, -1, 0).Unit
            
            print("Enviando dirección de lanzamiento:", direction)
            
            -- Enviar dirección al servidor
            launchEvent:FireServer(direction)
            
            -- Actualizar estado de lanzamiento
            isReadyToLaunch = false
            lastLaunchTime = tick()
            
            -- Ocultar el indicador por un momento
            launchIndicator.Enabled = false
            
            -- Programar comprobación para volver a activar el lanzamiento
            spawn(function()
                wait(launchCooldown)
                isReadyToLaunch = true
            end)
        end
    end)
    
    print("Controlador de entrada mejorado configurado")
end

-- Función principal
local function main()
	-- Configurar la cámara
	setupCamera()

	-- Esperar a que el juego esté inicializado
	local success, launchEvent = waitForGameInitialization()

	if success then
		-- Configurar manejo de entrada
		setupInputHandling(launchEvent)

		print("PeglinClient inicializado correctamente")
	else
		warn("No se pudo inicializar PeglinClient")
	end
end

-- Iniciar el cliente
main()