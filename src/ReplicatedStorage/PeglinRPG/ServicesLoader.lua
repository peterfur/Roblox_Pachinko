-- ServicesLoader.lua
-- Punto de entrada para el sistema de servicios refactorizado
-- Inicializa todos los componentes principales del juego

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar core infrastructure
local ServiceLocator = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceLocator"))
local EventBus = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EventBus"))

local ServicesLoader = {}

-- Función para cargar todos los servicios
function ServicesLoader:LoadServices()
    print("PeglinRPG: Cargando servicios...")
    
    -- Servicios disponibles y sus rutas
    local servicePaths = {
        -- Servicios principales
        BoardService = "Services.BoardService",
        OrbService = "Services.OrbService",
        CombatService = "Services.CombatService",
        PlayerService = "Services.PlayerService",
        EnemyService = "Services.EnemyService",
        PhysicsService = "Services.PhysicsService",
        VisualService = "Services.VisualService",
        UIService = "Services.UIService",
        GameplayService = "Services.GameplayService",
        
        -- Servicios adicionales
        EffectsService = "Services.EffectsService",
        RewardService = "Services.RewardService",
        InputService = "Services.InputService"
    }
    
    -- Lista de servicios que se han cargado correctamente
    local loadedServices = {}
    
    -- Cargar cada servicio
    for serviceName, servicePath in pairs(servicePaths) do
        local success, service = pcall(function()
            local fullPath = ReplicatedStorage:WaitForChild("PeglinRPG")
            
            -- Dividir la ruta por puntos y acceder a cada parte
            for _, part in ipairs(string.split(servicePath, ".")) do
                fullPath = fullPath:WaitForChild(part)
            end
            
            return require(fullPath)
        end)
        
        if success and service then
            -- Crear instancia del servicio con dependencias
            local serviceInstance = service.new(ServiceLocator, EventBus)
            
            -- Registrar el servicio
            ServiceLocator:RegisterService(serviceName, serviceInstance)
            
            table.insert(loadedServices, serviceName)
            print("PeglinRPG: Servicio registrado: " .. serviceName)
        else
            warn("PeglinRPG: No se pudo cargar el servicio: " .. serviceName)
            if not success then
                warn("Error: " .. tostring(service))
            end
        end
    end
    
    print("PeglinRPG: " .. #loadedServices .. " servicios cargados correctamente")
    
    return loadedServices
end

-- Inicializa todos los servicios registrados
function ServicesLoader:InitializeServices()
    print("PeglinRPG: Inicializando servicios...")
    
    -- Llamar al método Initialize en todos los servicios registrados
    ServiceLocator:InitializeAll()
    
    -- Publicar evento de sistema inicializado
    EventBus:Publish("SystemInitialized")
    
    print("PeglinRPG: Todos los servicios inicializados correctamente")
end

-- Inicia el juego completo
function ServicesLoader:StartGame()
    print("PeglinRPG: Iniciando juego...")
    
    -- Obtener el servicio principal de juego
    local gameplayService = ServiceLocator:GetService("GameplayService")
    
    if not gameplayService then
        warn("PeglinRPG: No se pudo obtener GameplayService, usando enfoque alternativo")
        
        -- Publicar un evento para que cualquier servicio que esté escuchando pueda iniciar el juego
        EventBus:Publish("GameStartRequested")
    else
        -- Iniciar juego a través de GameplayService
        gameplayService:StartNewGame()
    end
    
    print("PeglinRPG: Juego iniciado correctamente")
end

-- Método para hacer limpieza y detener todos los servicios
function ServicesLoader:Cleanup()
    print("PeglinRPG: Limpiando servicios...")
    
    -- Publicar evento antes de la limpieza
    EventBus:Publish("SystemCleanupStarted")
    
    -- Llamar al método Cleanup en todos los servicios registrados
    ServiceLocator:CleanupAll()
    
    -- Limpiar EventBus
    EventBus:ClearAll()
    
    print("PeglinRPG: Limpieza completada")
end

return ServicesLoader