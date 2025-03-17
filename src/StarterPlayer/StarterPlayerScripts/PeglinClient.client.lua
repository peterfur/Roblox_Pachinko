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
local function setupInputHandling(launchEvent)
	-- Manejar el lanzamiento de la pelota con el mouse
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Obtener dirección de lanzamiento
			local mousePos = UserInputService:GetMouseLocation()
			local viewportSize = workspace.CurrentCamera.ViewportSize

			-- Convertir posición del mouse a un vector de dirección
			local dirX = (mousePos.X - viewportSize.X/2) / 100
			local direction = Vector3.new(dirX, -1, 0).Unit

			print("Enviando dirección de lanzamiento:", direction)

			-- Enviar la dirección al servidor
			launchEvent:FireServer(direction)
		end
	end)

	print("Controlador de entrada configurado")
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