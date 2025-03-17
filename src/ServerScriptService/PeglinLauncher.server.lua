-- PeglinLauncher.lua
-- Este script es el punto de entrada para iniciar el juego Peglin RPG
-- Debe colocarse en ServerScriptService

print("PeglinLauncher iniciando...")

-- Cargar inicializador
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cargar o crear la carpeta de módulos
local function setupModuleFolder()
	local peglinFolder = ReplicatedStorage:FindFirstChild("PeglinRPG")
	
	if not peglinFolder then
		peglinFolder = Instance.new("Folder")
		peglinFolder.Name = "PeglinRPG"
		peglinFolder.Parent = ReplicatedStorage
	end
	
	return peglinFolder
end

-- Función para copiar desde el archivo incluido en este script
local function loadModuleFromGameFile(moduleName)
	-- En un entorno real, aquí cargaríamos el módulo desde un archivo local o un recurso
	-- Para esta demostración, simplemente crearemos los módulos con contenido básico
	print("Cargando módulo: " .. moduleName)
	
	local moduleScript = Instance.new("ModuleScript")
	moduleScript.Name = moduleName
	
	return moduleScript
end

-- Iniciar el juego
local function startGame()
	print("Iniciando PeglinRPG")
	
	-- Carpeta de módulos
	local moduleFolder = setupModuleFolder()
	
	-- Cargar los archivos necesarios
	local requiredModules = {
		"Config",
		"PlayerManager",
		"EnemyManager",
		"OrbManager",
		"BoardManager",
		"GameplayManager"
	}
	
	-- Cargar cada módulo
	for _, moduleName in ipairs(requiredModules) do
		local existingModule = moduleFolder:FindFirstChild(moduleName)
		
		if not existingModule then
			local newModule = loadModuleFromGameFile(moduleName)
			newModule.Parent = moduleFolder
			print("Módulo creado: " .. moduleName)
		else
			print("Módulo ya existe: " .. moduleName)
		end
	end
	-- Agregar después de crear los módulos en la función startGame()
	local function setupRemoteEvents(moduleFolder)
		-- Crear un RemoteEvent para permitir la comunicación entre cliente y servidor
		local launchEvent = Instance.new("RemoteEvent")
		launchEvent.Name = "PeglinLaunchEvent"
		launchEvent.Parent = moduleFolder

		print("Evento de lanzamiento creado en:", moduleFolder:GetFullName())

		-- Cuando el cliente envía una dirección, lanzamos la bola
		launchEvent.OnServerEvent:Connect(function(player, direction)
			-- Intentar obtener el GameplayManager y lanzar el orbe
			local success, err = pcall(function()
				local GameplayManager = require(moduleFolder:WaitForChild("GameplayManager", 5))

				-- Verificar si hay una instancia activa
				if _G.currentGameManager then
					print("GameplayManager encontrado, lanzando orbe con dirección:", direction)
					_G.currentGameManager:launchOrb(direction)
				else
					-- Crear nueva instancia si no existe
					local gameManager = GameplayManager.new()
					_G.currentGameManager = gameManager
					print("Creada nueva instancia de GameplayManager, lanzando orbe")
					gameManager:startNewGame()
					gameManager:launchOrb(direction)
				end
			end)

			if not success then
				warn("Error al procesar evento de lanzamiento:", err)
			end
		end)

		return launchEvent
	end

	-- Luego, dentro de tu función startGame(), después de cargar los módulos:
	-- Código existente...
	for _, moduleName in ipairs(requiredModules) do
		local existingModule = moduleFolder:FindFirstChild(moduleName)
		-- resto del código de carga de módulos...
	end

	-- Agregar esta línea después de cargar los módulos:
	local launchEvent = setupRemoteEvents(moduleFolder)

	-- Almacenar una referencia global al GameplayManager actual para que el evento de lanzamiento pueda acceder a él
	_G.currentGameManager = nil

	-- Crear un script local para cada jugador que se conecte
	local function setupPlayerScripts()
		local playersService = game:GetService("Players")

		-- Crear script de cliente
		local clientScript = Instance.new("LocalScript")
		clientScript.Name = "PeglinClient"

		-- Copiar el código del cliente aquí o cargar desde un template
		clientScript.Source = [[
-- Código de PeglinClient.lua
print("PeglinClient iniciando desde script copiado...")
-- resto del código aquí
]]

		-- Cuando un jugador se une
		local function onPlayerJoined(player)
			-- Entregar el script al jugador
			local scriptCopy = clientScript:Clone()
			scriptCopy.Parent = player:WaitForChild("PlayerScripts")
			print("Script de cliente entregado a:", player.Name)
		end

		playersService.PlayerAdded:Connect(onPlayerJoined)

		-- También para los jugadores ya presentes
		for _, player in ipairs(playersService:GetPlayers()) do
			onPlayerJoined(player)
		end
	end

	-- Llamar después de crear el evento de lanzamiento
	setupPlayerScripts()
	-- MODIFICADO: Enfoque alternativo para el inicializador
	-- En lugar de intentar modificar la propiedad Source, crearemos un script simple
	local initializerScript = Instance.new("Script")
	initializerScript.Name = "PeglinRPG_Initializer"
	
	-- Crear valores para pasar parámetros de configuración
	local gravityValue = Instance.new("NumberValue")
	gravityValue.Name = "GameGravity"
	gravityValue.Value = 130
	gravityValue.Parent = initializerScript
	
	-- Configuración principal (en vez de poner Source)
	print("Ejecutando inicializador...")
	
	-- Ejecutar directamente la lógica de inicialización aquí
	workspace.Gravity = 130 -- Establecer gravedad directamente
	
	-- Colocar el inicializador en ServerScriptService
	initializerScript.Parent = game:GetService("ServerScriptService")
	
	-- Crear un LocalScript para configurar la cámara (opcional)
	local cameraScript = Instance.new("LocalScript")
	cameraScript.Name = "PeglinCameraSetup"
	
	-- Configuración para todos los jugadores
	local playersService = game:GetService("Players")
	
	-- Cuando un jugador se une
	playersService.PlayerAdded:Connect(function(player)
		-- Clonar y dar el script de cámara
		local playerCameraScript = cameraScript:Clone()
		playerCameraScript.Parent = player:WaitForChild("PlayerScripts")
		
		print("Scripts configurados para el jugador: " .. player.Name)
	end)
	
	-- Iniciar el juego invocando el módulo GameplayManager
	local success, result = pcall(function()
		local gameManager = require(moduleFolder:WaitForChild("GameplayManager")).new()
		-- Opcionalmente inicia el juego automáticamente
		-- gameManager:startNewGame()
		return true
	end)
	
	if not success then
		warn("Error al iniciar PeglinRPG: " .. tostring(result))
		return false
	end
	
	print("PeglinRPG iniciado correctamente")
	return true
end



-- Iniciar el juego
startGame()