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
        GameplayService = "Services.GameplayService",
        
        -- Servicios adicionales
        EffectsService = "Services.EffectsService", -- Asegurarse que está bien formateado
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
    
    -- Para asegurar que los servicios críticos estén disponibles, implementamos fallbacks básicos
    self:ensureCriticalServices()
    
    return loadedServices
end

-- Asegura que los servicios críticos estén disponibles
function ServicesLoader:ensureCriticalServices()
    print("ServicesLoader: Verificando servicios críticos")
    
    -- Verificar si EnemyService está disponible
    if not ServiceLocator:HasService("EnemyService") then
        warn("ServicesLoader: EnemyService no encontrado, creando servicio básico")
        
        local success, EnemyService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EnemyService"))
        end)
        
        if success and EnemyService then
            local enemyService = EnemyService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("EnemyService", enemyService)
            print("ServicesLoader: EnemyService básico creado correctamente")
        else
            warn("ServicesLoader: Error al cargar módulo EnemyService:", EnemyService)
        end
    end
    
    -- Verificar si EffectsService está disponible (especial handling por su estructura)
    if not ServiceLocator:HasService("EffectsService") then
        warn("ServicesLoader: EffectsService no encontrado, creando servicio básico")
        
        local success, EffectsService = pcall(function()
            -- Probar primero como archivo directo
            local module = ReplicatedStorage:FindFirstChild("PeglinRPG"):FindFirstChild("PeglinRPG_Initializer")
            if module then
                return require(module)
            else
                -- Si falla, intentar como carpeta
                return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("EffectsService"))
            end
        end)
        
        if success and EffectsService then
            local effectsService = EffectsService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("EffectsService", effectsService)
            print("ServicesLoader: EffectsService básico creado correctamente")
        else
            warn("ServicesLoader: Error al cargar módulo EffectsService:", EffectsService)
        end
    end
    
    -- Verificar si OrbService está disponible
    if not ServiceLocator:HasService("OrbService") then
        warn("ServicesLoader: OrbService no encontrado, creando servicio básico")
        
        local success, OrbService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("OrbService"))
        end)
        
        if success and OrbService then
            local orbService = OrbService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("OrbService", orbService)
            print("ServicesLoader: OrbService básico creado correctamente")
        else
            warn("ServicesLoader: Error al cargar módulo OrbService:", OrbService)
        end
    end
    
    -- Verificar si BoardService está disponible
    if not ServiceLocator:HasService("BoardService") then
        warn("ServicesLoader: BoardService no encontrado, creando servicio básico")
        
        local success, BoardService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("BoardService"))
        end)
        
        if success and BoardService then
            local boardService = BoardService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("BoardService", boardService)
            print("ServicesLoader: BoardService básico creado correctamente")
        else
            warn("ServicesLoader: Error al cargar módulo BoardService:", BoardService)
        end
    end
    
    -- Verificar si GameplayService está disponible
    if not ServiceLocator:HasService("GameplayService") then
        warn("ServicesLoader: GameplayService no encontrado, creando servicio básico")
        
        local success, GameplayService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("GameplayService"))
        end)
        
        if success and GameplayService then
            local gameplayService = GameplayService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("GameplayService", gameplayService)
            print("ServicesLoader: GameplayService básico creado correctamente")
        else
            warn("ServicesLoader: Error al cargar módulo GameplayService:", GameplayService)
        end
    end
    
    -- Imprimir servicios disponibles para diagnóstico
    print("ServicesLoader: Servicios disponibles después de verificación:")
    for serviceName, _ in pairs(ServiceLocator:GetAllServices()) do
        print("  - " .. serviceName)
    end
end

-- Inicializa todos los servicios registrados
function ServicesLoader:InitializeServices()
    print("PeglinRPG: Inicializando servicios...")
    
    -- Llamar al método Initialize en todos los servicios registrados
    for name, service in pairs(ServiceLocator:GetAllServices()) do
        if type(service) == "table" and type(service.Initialize) == "function" then
            local success, error = pcall(function()
                service:Initialize()
            end)
            
            if not success then
                warn("ServiceLocator: Error al inicializar servicio " .. name .. ": " .. tostring(error))
            else
                print("ServiceLocator: Servicio inicializado: " .. name)
            end
        end
    end
    
    -- Publicar evento de sistema inicializado
    EventBus:Publish("SystemInitialized")
    
    print("PeglinRPG: Todos los servicios inicializados correctamente")
    
    -- Suscribirse al evento de inicio de juego
    EventBus:Subscribe("GameStartRequested", function()
        print("ServicesLoader: Evento GameStartRequested recibido, iniciando juego...")
        self:StartGame()
    end)
    
    -- Suscribirse al evento ClientReady
    EventBus:Subscribe("ClientReady", function()
        print("ServicesLoader: Evento ClientReady recibido, iniciando juego automáticamente...")
        self:StartGame()
    end)
end

-- Inicia el juego completo
function ServicesLoader:StartGame()
    print("PeglinRPG: Iniciando juego...")
    
    -- Obtener el servicio principal de juego
    local gameplayService = ServiceLocator:GetService("GameplayService")
    
    if not gameplayService then
        warn("PeglinRPG: No se pudo obtener GameplayService, creando fallback")
        
        -- Intentar crear un GameplayService básico
        local success, GameplayService = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("GameplayService"))
        end)
        
        if success and GameplayService then
            gameplayService = GameplayService.new(ServiceLocator, EventBus)
            ServiceLocator:RegisterService("GameplayService", gameplayService)
            gameplayService:Initialize()
        else
            -- Si aún no podemos crear un GameplayService, notificamos a todos los servicios
            EventBus:Publish("GameStartRequested")
            warn("PeglinRPG: No se pudo iniciar el juego a través de GameplayService")
            return
        end
    end
    
    -- Iniciar juego a través de GameplayService
    local success, error = pcall(function()
        gameplayService:StartNewGame()
    end)
    
    if success then
        print("PeglinRPG: Juego iniciado correctamente mediante GameplayService")
    else
        warn("PeglinRPG: Error al iniciar juego: " .. tostring(error))
        -- Intentar iniciar el juego directamente a través de eventos como último recurso
        EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
        EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
        wait(1) -- Dar tiempo para que se genere el tablero
        EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
        EventBus:Publish("PlayerTurnStarted")
    end
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