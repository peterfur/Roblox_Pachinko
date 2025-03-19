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
    
    -- Una vez cargados los servicios, programar una carga completa
    spawn(function()
        wait(1) -- Dar tiempo a que los servicios se estabilicen
        self:LoadAll()
    end)
    
    return loadedServices
end

-- Asegura que los servicios críticos estén disponibles
function ServicesLoader:ensureCriticalServices()
    print("ServicesLoader: Verificando servicios críticos")
    
    local criticalServices = {
        "BoardService", 
        "EnemyService", 
        "OrbService", 
        "GameplayService",
        "PlayerService",
        "CombatService"
    }
    
    for _, serviceName in ipairs(criticalServices) do
        if not ServiceLocator:HasService(serviceName) then
            print("ServicesLoader: Creando servicio crítico:", serviceName)
            self:ensureCriticalService(serviceName)
        end
    end
    
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
    
    -- Suscribirse al evento StartGameWithImmediateLoading
    EventBus:Subscribe("StartGameWithImmediateLoading", function()
        print("ServicesLoader: Recibido evento StartGameWithImmediateLoading, iniciando con carga inmediata...")
        self:StartGame()
    end)
    
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
    
    -- Llamar al método Initialize en todos los servicios registrados en orden
    self:InitializeServicesInOrder()
end

-- Función para garantizar el orden correcto de inicialización
function ServicesLoader:InitializeServicesInOrder()
    print("PeglinRPG: Inicializando servicios en orden de dependencia...")
    
    -- Orden de inicialización para garantizar dependencias
    local initOrder = {
        "BoardService",     -- Primero tablero, ya que varios servicios lo necesitan
        "PlayerService",    -- Datos del jugador
        "EnemyService",     -- Enemigos
        "OrbService",       -- Orbes dependen de los anteriores
        "PhysicsService",   -- Físicas para los orbes
        "CombatService",    -- Depende de los orbes y enemigos
        "EffectsService",   -- Efectos visuales
        "UIService",        -- Interfaz
        "GameplayService"   -- Último, ya que coordina todos los anteriores
    }
    
    -- Inicializar en orden
    for _, serviceName in ipairs(initOrder) do
        local service = ServiceLocator:GetService(serviceName)
        if service then
            local success, error = pcall(function()
                if typeof(service.Initialize) == "function" and not service.initialized then
                    service:Initialize()
                    print("ServicesLoader: Inicializado servicio en orden:", serviceName)
                end
            end)
            
            if not success then
                warn("ServicesLoader: Error al inicializar", serviceName, error)
            end
        end
    end
    
    -- Inicializar cualquier servicio restante que no esté en la lista
    for name, service in pairs(ServiceLocator:GetAllServices()) do
        if type(service) == "table" and type(service.Initialize) == "function" and not service.initialized then
            local success, error = pcall(function()
                service:Initialize()
            end)
            
            if not success then
                warn("ServiceLocator: Error al inicializar servicio restante " .. name .. ": " .. tostring(error))
            else
                print("ServiceLocator: Servicio inicializado (adicional): " .. name)
            end
        end
    end
    
    -- Publicar evento de sistema inicializado
    EventBus:Publish("SystemInitialized")
    
    print("PeglinRPG: Todos los servicios inicializados correctamente")
    
    -- Iniciar servicios una vez inicializados
    for _, serviceName in ipairs(initOrder) do
        local service = ServiceLocator:GetService(serviceName)
        if service and typeof(service.Start) == "function" and service.initialized then
            local success, error = pcall(function()
                service:Start()
            end)
            
            if not success then
                warn("ServicesLoader: Error al iniciar", serviceName, error)
            else
                print("ServicesLoader: Iniciado servicio:", serviceName)
            end
        end
    end
end

-- Inicia el juego completo con carga inmediata de todos los componentes
function ServicesLoader:StartGame()
    print("PeglinRPG: Iniciando juego con carga inmediata...")

    -- 1. Primero asegurar que tenemos todos los servicios críticos
    self:ensureCriticalServices()
    
    -- 2. Iniciar el juego
    local gameplayService = ServiceLocator:GetService("GameplayService")
    local boardService = ServiceLocator:GetService("BoardService")
    local enemyService = ServiceLocator:GetService("EnemyService")
    local orbService = ServiceLocator:GetService("OrbService")
    
    if not gameplayService then
        warn("ServicesLoader: GameplayService no disponible, creando uno...")
        self:ensureCriticalService("GameplayService")
        gameplayService = ServiceLocator:GetService("GameplayService")
    end
    
    if not boardService then
        warn("ServicesLoader: BoardService no disponible, creando uno...")
        self:ensureCriticalService("BoardService")
        boardService = ServiceLocator:GetService("BoardService")
    end
    
    -- 3. Forzar la creación del tablero inmediatamente
    if boardService then
        print("ServicesLoader: Generando tablero inmediatamente...")
        local board = boardService:generateBoard(60, 70, 120, {
            theme = "FOREST",
            pegColors = {
                BrickColor.new("Bright blue"),
                BrickColor.new("Bright green"),
                BrickColor.new("Bright yellow")
            },
            backgroundColor = Color3.fromRGB(30, 30, 50)
        })
        
        if board then
            print("ServicesLoader: Tablero generado correctamente")
        else
            warn("ServicesLoader: Falló la generación del tablero")
        end
    else
        warn("ServicesLoader: No se pudo crear BoardService")
    end
    
    -- 4. Crear un enemigo inmediatamente
    if enemyService then
        print("ServicesLoader: Generando enemigo inmediatamente...")
        local success = enemyService:generateEnemy("FOREST", false)
        if success then
            print("ServicesLoader: Enemigo generado correctamente")
        else
            warn("ServicesLoader: Falló la generación del enemigo")
        end
    else
        warn("ServicesLoader: No se pudo crear EnemyService")
    end
    
    -- 5. Preparar los orbes
    if orbService and ServiceLocator:HasService("PlayerService") then
        local playerService = ServiceLocator:GetService("PlayerService")
        orbService:initializeBattlePool(playerService)
        print("ServicesLoader: Pool de orbes inicializado")
    end
    
    -- 6. Una vez que todo está cargado, iniciar el juego a través de GameplayService
    if gameplayService then
        -- Intentar usar el método normal
        local success, error = pcall(function()
            gameplayService:StartNewGame()
        end)
        
        if success then
            print("ServicesLoader: Juego iniciado correctamente a través de GameplayService")
        else
            warn("ServicesLoader: Error iniciando a través de GameplayService:", error)
            
            -- Enviar eventos para asegurar que todos los componentes del juego sepan que estamos listos
            EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
            wait(0.1) -- Pequeña pausa para asegurar que los eventos se procesen
            
            -- Cambiar a fase de jugador
            EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
            EventBus:Publish("PlayerTurnStarted")
            
            print("ServicesLoader: Juego iniciado mediante eventos directos")
        end
    else
        warn("ServicesLoader: No se puede iniciar el juego sin GameplayService")
        
        -- Último intento - Usar eventos directos
        EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
        wait(0.5)
        EventBus:Publish("BoardRequested", 60, 70, 120, {theme = "FOREST"})
        wait(1)
        EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
        EventBus:Publish("PlayerTurnStarted")
    end
end

-- Función auxiliar para crear un servicio crítico específico
function ServicesLoader:ensureCriticalService(serviceName)
    print("ServicesLoader: Intentando crear servicio crítico:", serviceName)
    
    -- Mapa de rutas de módulos
    local modulePathMap = {
        BoardService = "Services/BoardService",
        EnemyService = "Services/EnemyService",
        OrbService = "Services/OrbService",
        GameplayService = "Services/GameplayService", 
        CombatService = "Services/CombatService",
        PlayerService = "Services/PlayerService",
        EffectsService = "Services/EffectsService"
    }
    
    -- Verificar si hay una ruta para este servicio
    local modulePath = modulePathMap[serviceName]
    if not modulePath then
        warn("ServicesLoader: No hay ruta definida para el servicio:", serviceName)
        return false
    end
    
    -- Intentar cargar el módulo
    local success, Service = pcall(function()
        return require(ReplicatedStorage:WaitForChild("PeglinRPG"):FindFirstChild(modulePath))
    end)
    
    if not success or not Service then
        -- Intentar un camino alternativo
        success, Service = pcall(function()
            local path = ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild(serviceName)
            return require(path)
        end)
        
        if not success or not Service then
            warn("ServicesLoader: Error al cargar módulo para", serviceName, Service)
            return false
        end
    end
    
    -- Intentar crear una instancia del servicio
    success, _ = pcall(function()
        local serviceInstance = Service.new(ServiceLocator, EventBus)
        ServiceLocator:RegisterService(serviceName, serviceInstance)
        serviceInstance:Initialize()
    end)
    
    if not success then
        warn("ServicesLoader: Error al crear instancia de", serviceName)
        return false
    end
    
    print("ServicesLoader:", serviceName, "creado e inicializado con éxito")
    return true
end

-- Función para cargar todos los componentes del juego rápidamente
function ServicesLoader:LoadAll()
    print("ServicesLoader: Cargando todos los componentes del juego...")
    
    -- 1. Cargar servicios críticos
    self:ensureCriticalServices()
    
    -- 2. Esperar a que estén todos inicializados
    wait(0.5)
    
    -- 3. Iniciar el juego con todo cargado
    self:StartGame()
    
    print("ServicesLoader: Todos los componentes cargados")
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