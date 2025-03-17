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

	-- Agregar después de crear los módulos
	local function setupRemoteEvents()
		-- Crear un RemoteEvent para permitir la comunicación entre cliente y servidor
		local launchEvent = Instance.new("RemoteEvent")
		launchEvent.Name = "PeglinLaunchEvent"
		launchEvent.Parent = ReplicatedStorage:WaitForChild("PeglinRPG")

		print("Evento de lanzamiento creado en:", ReplicatedStorage:WaitForChild("PeglinRPG"):GetFullName())

		-- Cuando el cliente envía una dirección, lanzamos la bola
		launchEvent.OnServerEvent:Connect(function(player, direction)
			-- En un entorno real, aquí accederíamos al GameplayManager
			-- y llamaríamos a gameManager:launchOrb(direction)
			print("Recibida dirección de lanzamiento:", direction)
		end)

		return launchEvent
	end

	-- Llamar a esta función después de crear todos los módulos
	local launchEvent = setupRemoteEvents()

	-- CORREGIDO: Enfoque alternativo para el inicializador
	-- En lugar de intentar clonar, creamos directamente el script en ServerScriptService
	local initializerScript = Instance.new("Script")
	initializerScript.Name = "PeglinRPG_Initializer"
	
	-- Crear valores para pasar parámetros de configuración
	local gravityValue = Instance.new("NumberValue")
	gravityValue.Name = "GameGravity"
	gravityValue.Value = 130
	gravityValue.Parent = initializerScript
	
	-- Ejecutar directamente la lógica de inicialización aquí
	workspace.Gravity = 130 -- Establecer gravedad directamente
	
	-- Colocar el script en el destino final directamente
	initializerScript.Parent = game:GetService("ServerScriptService")
	
	print("PeglinRPG inicializado correctamente: gravedad establecida a 130")
	return true
end

-- Iniciar el juego
startGame()