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
    
    -- Imprimir información detallada para diagnóstico
    print("BoardService: Generando tablero...")
    print("BoardService: Dimensiones:", width, "x", height)
    print("BoardService: Cantidad de clavijas:", pegCount)
    
    -- Opciones por defecto
    options = options or {}
    local theme = options.theme or "FOREST"
    local pegColors = options.pegColors or {
        BrickColor.new("Bright blue"),
        BrickColor.new("Cyan"),
        BrickColor.new("Royal blue")
    }
    local backgroundColor = options.backgroundColor or Color3.fromRGB(30, 30, 50)
    
    print("BoardService: Tema:", theme)
    
    -- Crear contenedor para el tablero
    local board = Instance.new("Model")
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
    
    -- Verificar que los módulos necesarios estén disponibles
    print("BoardService: Verificando módulos...")
    
    -- Si no tenemos BorderFactory, intentar cargarlo directamente
    if not self.borderFactory then
        local success, BorderFactory = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("BorderFactory"))
        end)
        
        if success and BorderFactory then
            self.borderFactory = BorderFactory.new(self)
            print("BoardService: BorderFactory cargado correctamente")
        else
            warn("BoardService: Error al cargar BorderFactory:", BorderFactory)
            -- Continuar con otras partes del tablero
        end
    end
    
    -- Si no tenemos PegFactory, intentar cargarlo directamente
    if not self.pegFactory then
        local success, PegFactory = pcall(function()
            return require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("PegFactory"))
        end)
        
        if success and PegFactory then
            self.pegFactory = PegFactory.new(self)
            print("BoardService: PegFactory cargado correctamente")
        else
            warn("BoardService: Error al cargar PegFactory:", PegFactory)
            -- Continuar con otras partes del tablero
        end
    end
    
    -- Crear bordes usando BorderFactory (o código directo si no está disponible)
    if self.borderFactory then
        print("BoardService: Creando bordes usando BorderFactory")
        self.borderFactory:createBorders(board, width, height, theme)
    else
        print("BoardService: BorderFactory no disponible, creando bordes básicos")
        self:createBasicBorders(board, width, height, theme)
    end
    
    -- Generar clavijas usando PegFactory (o código directo si no está disponible)
    if self.pegFactory then
        print("BoardService: Generando clavijas usando PegFactory")
        self.pegFactory:generatePegs(board, width, height, pegCount, pegColors, theme)
    else
        print("BoardService: PegFactory no disponible, generando clavijas básicas")
        self:generateBasicPegs(board, width, height, pegCount, pegColors, theme)
    end
    
    -- Posicionar el tablero en el mundo
    board.Parent = workspace
    
    -- Publicar evento de tablero generado
    self.eventBus:Publish("BoardGenerated", board, width, height, theme)
    print("BoardService: Tablero generado con éxito")
    
    return board
end


-- Añade estas funciones de respaldo para crear elementos básicos si fallan los módulos normales
function BoardService:createBasicBorders(board, width, height, theme)
    -- Crear bordes básicos cuando BorderFactory no está disponible
    local borderThickness = 5
    local borderHeight = height + 15
    local extendedWidth = width + 10
    
    -- Determinar apariencia según tema
    local borderColor
    if theme == "FOREST" then
        borderColor = BrickColor.new("Reddish brown")
    elseif theme == "DUNGEON" then
        borderColor = BrickColor.new("Dark stone grey")
    else
        borderColor = BrickColor.new("Medium stone grey")
    end
    
    -- Función para crear un borde
    local function createBorder(position, size, isGlass)
        local border = Instance.new("Part")
        border.Size = size
        border.Position = position
        
        if isGlass then
            border.BrickColor = BrickColor.new("Institutional white")
            border.Material = Enum.Material.Glass
            border.Transparency = 0.7
        else
            border.BrickColor = borderColor
            border.Material = Enum.Material.SmoothPlastic
        end
        
        border.Anchored = true
        border.CanCollide = true
        border:SetAttribute("IsBorder", true)
        border.Parent = board
        
        return border
    end
    
    -- Bordes superior e inferior
    createBorder(Vector3.new(0, height/2 + borderThickness/2, 0), Vector3.new(extendedWidth, borderThickness, 5))
    createBorder(Vector3.new(0, -height/2 - borderThickness/2, 0), Vector3.new(extendedWidth, borderThickness, 5))
    
    -- Bordes laterales
    createBorder(Vector3.new(width/2 + borderThickness/2, 0, 0), Vector3.new(borderThickness, borderHeight, 5))
    createBorder(Vector3.new(-width/2 - borderThickness/2, 0, 0), Vector3.new(borderThickness, borderHeight, 5))
    
    -- Paredes de cristal
    createBorder(Vector3.new(0, 0, 2), Vector3.new(width + 20, borderHeight, 0.5), true)
    createBorder(Vector3.new(0, 0, -2), Vector3.new(width + 20, borderHeight, 0.5), true)
    
    print("BoardService: Bordes básicos creados correctamente")
end

function BoardService:generateBasicPegs(board, width, height, pegCount, pegColors, theme)
    -- Resetear contadores
    self.pegCount = 0
    self.criticalPegCount = 0
    
    -- Crear clavijas en un patrón básico
    local pegSpacing = 8
    local rows = math.floor(height / pegSpacing) - 2
    local cols = math.floor(width / pegSpacing) - 2
    local totalPositions = rows * cols
    
    -- Asegurar que no intentamos crear más clavijas de las que caben
    local actualPegCount = math.min(pegCount, totalPositions)
    
    -- Crear las posiciones para todas las clavijas posibles
    local possiblePositions = {}
    for row = 1, rows do
        for col = 1, cols do
            local x = (col - (cols/2) - 0.5) * pegSpacing
            local y = (row - (rows/2) - 0.5) * pegSpacing
            table.insert(possiblePositions, Vector3.new(x, y, 0))
        end
    end
    
    -- Mezclar las posiciones para obtener una distribución más natural
    for i = #possiblePositions, 2, -1 do
        local j = math.random(i)
        possiblePositions[i], possiblePositions[j] = possiblePositions[j], possiblePositions[i]
    end
    
    -- Crear las clavijas
    for i = 1, actualPegCount do
        if i <= #possiblePositions then
            local position = possiblePositions[i]
            
            -- Determinar si es una clavija crítica (20% de probabilidad)
            local isCritical = math.random(1, 5) == 1
            if isCritical then
                self.criticalPegCount = self.criticalPegCount + 1
            end
            
            -- Crear la clavija
            local peg = Instance.new("Part")
            
            -- Determinar si es esférica o cilíndrica (20% de probabilidad de ser esférica)
            if math.random(1, 5) == 1 then
                peg.Shape = Enum.PartType.Ball
                peg.Size = Vector3.new(1, 1, 1)
            else
                peg.Shape = Enum.PartType.Cylinder
                peg.Size = Vector3.new(0.5, 2, 0.5)
                peg.Orientation = Vector3.new(0, 0, 90) -- Horizontal
            end
            
            peg.Position = position
            
            -- Definir color y material
            if isCritical then
                peg.BrickColor = BrickColor.new("Really red")
                peg.Material = Enum.Material.Neon
            else
                peg.BrickColor = pegColors[math.random(1, #pegColors)]
                
                if theme == "FOREST" then
                    peg.Material = Enum.Material.Wood
                elseif theme == "DUNGEON" then
                    peg.Material = Enum.Material.Slate
                else
                    peg.Material = Enum.Material.SmoothPlastic
                end
            end
            
            -- Propiedades físicas
            peg.Anchored = true
            peg.CanCollide = true
            
            -- Propiedades para interacción con orbes
            peg:SetAttribute("IsPeg", true)
            peg:SetAttribute("IsCritical", isCritical)
            peg:SetAttribute("HitCount", 0)
            peg:SetAttribute("MaxHits", 2)
            
            -- Añadir efecto visual para clavijas críticas
            if isCritical then
                local light = Instance.new("PointLight")
                light.Brightness = 1
                light.Color = Color3.fromRGB(255, 100, 100)
                light.Range = 4
                light.Parent = peg
            end
            
            peg.Parent = board
            table.insert(self.pegs, peg)
            self.pegCount = self.pegCount + 1
        end
    end
    
    -- Crear punto de entrada para orbes
    local entry = Instance.new("Part")
    entry.Shape = Enum.PartType.Ball
    entry.Size = Vector3.new(3, 3, 3)
    entry.Position = Vector3.new(0, height/2 - 6, 0)
    entry.BrickColor = BrickColor.new("Lime green")
    entry.Material = Enum.Material.Neon
    entry.Transparency = 0.5
    entry.Anchored = true
    entry.CanCollide = false
    entry:SetAttribute("LaunchPosition", Vector3.new(0, height/2 - 6, 0))
    entry:SetAttribute("EntryPointIndex", 1)
    entry.Parent = board
    
    -- Guardar el punto de entrada
    self.entryPoints = {entry}
    
    print("BoardService: Generadas", self.pegCount, "clavijas básicas,", self.criticalPegCount, "críticas")
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