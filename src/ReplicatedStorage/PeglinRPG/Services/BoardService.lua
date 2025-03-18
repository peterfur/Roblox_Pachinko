-- BoardService.lua
-- Servicio que gestiona el tablero de juego
-- Reemplaza al anterior BoardManager con una arquitectura más estructurada

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Importar dependencias
local ServiceInterface = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Services"):WaitForChild("ServiceInterface"))
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Definición del BoardService
local BoardService = ServiceInterface:Extend("BoardService")

-- Constructor
function BoardService.new(serviceLocator, eventBus)
    local self = setmetatable({}, BoardService)
    
    -- Dependencias
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    
    -- Propiedades
    self.Name = "BoardService"
    self.currentBoard = nil
    self.pegCount = 0
    self.criticalPegCount = 0
    self.activeBoard = nil
    self.pegs = {}
    self.entryPoints = {}
    
    -- Subscripciones a eventos
    self.eventSubscriptions = {}
    
    -- Módulos del tablero (serán inicializados en Initialize)
    self.pegFactory = nil
    self.borderFactory = nil
    self.obstacleManager = nil
    self.themeDecorator = nil
    self.entryPointFactory = nil
    self.collisionHandler = nil
    
    return self
end

-- Inicialización del servicio
function BoardService:Initialize()
    ServiceInterface.Initialize(self)
    
    -- Inicializar submódulos con referencia a este servicio
    local modulesPath = ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board")
    
    -- Intentar cargar los módulos con mejor manejo de errores
    local function loadModule(name)
        local success, result = pcall(function()
            return require(modulesPath:WaitForChild(name))
        end)
        
        if not success then
            warn("BoardService: Error al cargar módulo " .. name .. ": " .. tostring(result))
            return nil
        end
        
        return result
    end
    
    -- Cargar los módulos
    self.pegFactory = loadModule("PegFactory").new(self)
    self.borderFactory = loadModule("BorderFactory").new(self)
    self.obstacleManager = loadModule("ObstacleManager").new(self)
    self.themeDecorator = loadModule("ThemeDecorator").new(self)
    self.entryPointFactory = loadModule("EntryPointFactory").new(self)
    self.collisionHandler = loadModule("CollisionHandler").new(self)
    
    -- Verificar que todos los módulos se cargaron correctamente
    if not (self.pegFactory and self.borderFactory and self.obstacleManager and 
           self.themeDecorator and self.entryPointFactory and self.collisionHandler) then
        warn("BoardService: No se pudieron cargar todos los módulos necesarios")
    end
    
    -- Suscribirse a eventos
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BoardRequested", function(...)
        self:generateBoard(...)
    end))
    
    table.insert(self.eventSubscriptions, self.eventBus:Subscribe("BoardCleanup", function()
        self:cleanupBoard()
    end))
    
    print("BoardService: Inicializado correctamente")
end

-- Genera un nuevo tablero de juego
function BoardService:generateBoard(width, height, pegCount, options)
    -- Limpiar tablero existente
    self:cleanupBoard()
    
    -- Opciones por defecto
    options = options or {}
    local theme = options.theme or "FOREST"
    local pegColors = options.pegColors or {
        BrickColor.new("Bright blue"),
        BrickColor.new("Cyan"),
        BrickColor.new("Royal blue")
    }
    local backgroundColor = options.backgroundColor or Color3.fromRGB(30, 30, 50)
    
    -- Imprimir información de depuración
    print("BoardService: Generando tablero...")
    print("Dimensiones:", width, height)
    print("Tema:", theme)
    
    -- Crear contenedor para el tablero
    local board = Instance.new("Folder")
    board.Name = "PeglinBoard_" .. theme
    
    -- Registrar tablero actual
    self.currentBoard = board
    self.pegs = {}
    
    -- Crear fondo del tablero
    local background = Instance.new("Part")
    background.Size = Vector3.new(width + 4, height + 4, 1)
    background.Position = Vector3.new(0, 0, 0.5)
    background.Anchored = true
    background.CanCollide = false
    background.Transparency = 0.3
    background.Color = backgroundColor
    background.Material = Enum.Material.SmoothPlastic
    background.Parent = board
    
    -- Crear bordes usando BorderFactory
    if self.borderFactory then
        self.borderFactory:createBorders(board, width, height, theme)
    end
    
    -- Generar clavijas usando PegFactory
    if self.pegFactory then
        self.pegFactory:generatePegs(board, width, height, pegCount, pegColors, theme)
    end
    
    -- Añadir obstáculos especiales usando ObstacleManager
    -- Envolvemos en pcall para evitar que los errores interrumpan la generación
    if self.obstacleManager then
        pcall(function()
            self.obstacleManager:addSpecialObstacles(board, width, height, theme)
        end)
    end
    
    -- Añadir decoraciones temáticas usando ThemeDecorator
    if self.themeDecorator then
        self.themeDecorator:addThemeDecorations(board, theme, width, height)
    end
    
    -- Crear puntos de entrada usando EntryPointFactory
    if self.entryPointFactory then
        self.entryPoints = self.entryPointFactory:createEntryPoints(board, width, height, theme)
    end
    
    -- Posicionar el tablero en el mundo
    board.Parent = workspace
    
    -- Publicar evento de tablero generado
    self.eventBus:Publish("BoardGenerated", board, width, height, theme)
    
    return board
end

-- Limpia el tablero actual
function BoardService:cleanupBoard()
    if self.currentBoard then
        self.currentBoard:Destroy()
        self.currentBoard = nil
        self.pegs = {}
        self.entryPoints = {}
        self.pegCount = 0
        self.criticalPegCount = 0
        
        -- Publicar evento de tablero limpiado
        self.eventBus:Publish("BoardCleaned")
    end
end

-- Registra un golpe en una clavija (delegado a CollisionHandler)
function BoardService:registerPegHit(pegPart)
    if self.collisionHandler then
        return self.collisionHandler:registerPegHit(pegPart)
    end
    return false
end

-- Maneja colisiones con elementos especiales (delegado a CollisionHandler)
function BoardService:handleSpecialCollisions(orbPart, contactPoint)
    if self.collisionHandler then
        return self.collisionHandler:handleSpecialCollisions(orbPart, contactPoint)
    end
end

-- Devuelve estadísticas del tablero actual
function BoardService:getBoardStats()
    return {
        totalPegs = self.pegCount,
        criticalPegs = self.criticalPegCount,
        pegsHit = 0, -- Esto se actualizaría durante el juego
        boardWidth = self.currentBoard and self.currentBoard.Size and self.currentBoard.Size.X or 0,
        boardHeight = self.currentBoard and self.currentBoard.Size and self.currentBoard.Size.Y or 0
    }
end

-- Limpieza del servicio
function BoardService:Cleanup()
    -- Cancelar todas las suscripciones a eventos
    for _, unsubscribe in ipairs(self.eventSubscriptions) do
        if type(unsubscribe) == "function" then
            unsubscribe()
        end
    end
    self.eventSubscriptions = {}
    
    -- Limpiar tablero
    self:cleanupBoard()
    
    -- Limpiar propiedades
    self.pegFactory = nil
    self.borderFactory = nil
    self.obstacleManager = nil
    self.themeDecorator = nil
    self.entryPointFactory = nil
    self.collisionHandler = nil
    
    -- Llamar al método Cleanup de la clase base
    ServiceInterface.Cleanup(self)
end

return BoardService