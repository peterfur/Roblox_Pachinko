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

	-- Cargar inicializador
	local initializer = script:FindFirstChild("PeglinRPG_Initializer")

	if not initializer then
		initializer = Instance.new("Script")
		initializer.Name = "PeglinRPG_Initializer"

		-- Aquí normalmente cargaríamos el código desde un archivo
		-- Para el propósito de este ejemplo, usaremos una cadena básica
		initializer.Source = [[
            print("Inicializador de PeglinRPG ejecutándose...")
            -- En un entorno real, aquí iría el código completo que hemos definido
            -- en el archivo PeglinRPG_Initializer.lua
            
            -- Intentar ejecutar el inicializador modular
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local moduleFolder = ReplicatedStorage:WaitForChild("PeglinRPG")
            
            -- Configurar gravedad para el juego
            workspace.Gravity = 130
            
            -- Notificar que el juego ha iniciado
            print("¡PeglinRPG ha iniciado correctamente!")
        ]]

		initializer.Parent = script
	end
	-- Agregar después de crear los módulos
	local function setupRemoteEvents()
		-- Crear un RemoteEvent para permitir la comunicación entre cliente y servidor
		local launchEvent = Instance.new("RemoteEvent")
		launchEvent.Name = "PeglinLaunchEvent"
		launchEvent.Parent = ReplicatedStorage:WaitForChild("PeglinRPG")

		print("Evento de lanzamiento creado")

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
	-- Ejecutar inicializador
	print("Ejecutando inicializador...")
	local success, error = pcall(function()
		initializer:Clone().Parent = game:GetService("ServerScriptService")
	end)

	if not success then
		warn("Error al iniciar PeglinRPG: " .. tostring(error))
		return false
	end

	print("PeglinRPG iniciado correctamente")
	return true
end

-- Iniciar el juego
startGame()