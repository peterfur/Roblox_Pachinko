-- BoardCreator.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("BoardCreator: Iniciando script de creación de tablero directo")

-- Cargar módulos necesarios
local PeglinRPG = ReplicatedStorage:WaitForChild("PeglinRPG", 10)
local Config
local EventBus
local BoardService
local PegFactory
local BorderFactory
local ObstacleManager
local ThemeDecorator
local EntryPointFactory
local CollisionHandler

-- Intentar cargar configuración
pcall(function()
    Config = require(PeglinRPG:WaitForChild("Config"))
end)

-- Intentar cargar EventBus
pcall(function()
    EventBus = require(PeglinRPG:WaitForChild("Services"):WaitForChild("EventBus"))
end)

-- Intentar cargar BoardService para usar sus métodos
pcall(function()
    BoardService = require(PeglinRPG:WaitForChild("Services"):WaitForChild("BoardService"))
end)

-- Cargar módulos de Board
pcall(function()
    PegFactory = require(PeglinRPG:WaitForChild("Board"):WaitForChild("PegFactory"))
    BorderFactory = require(PeglinRPG:WaitForChild("Board"):WaitForChild("BorderFactory"))
    ObstacleManager = require(PeglinRPG:WaitForChild("Board"):WaitForChild("ObstacleManager"))
    ThemeDecorator = require(PeglinRPG:WaitForChild("Board"):WaitForChild("ThemeDecorator"))
    EntryPointFactory = require(PeglinRPG:WaitForChild("Board"):WaitForChild("EntryPointFactory"))
    CollisionHandler = require(PeglinRPG:WaitForChild("Board"):WaitForChild("CollisionHandler"))
end)

-- Verificar módulos cargados
print("BoardCreator: Estado de carga de módulos:")
print("- Config:", Config ~= nil)
print("- EventBus:", EventBus ~= nil)
print("- BoardService:", BoardService ~= nil)
print("- PegFactory:", PegFactory ~= nil)
print("- BorderFactory:", BorderFactory ~= nil)
print("- ObstacleManager:", ObstacleManager ~= nil)
print("- ThemeDecorator:", ThemeDecorator ~= nil)
print("- EntryPointFactory:", EntryPointFactory ~= nil)
print("- CollisionHandler:", CollisionHandler ~= nil)

-- Verificar si el tablero ya existe
if workspace:FindFirstChild("PeglinBoard_FOREST") then
    print("BoardCreator: El tablero ya existe, no se creará uno nuevo")
    return
end

-- Función para crear el tablero utilizando el flujo original
local function createBoardUsingServices()
    print("BoardCreator: Intentando crear tablero usando los servicios originales")
    
    -- Obtener dimensiones del tablero desde Config
    local width = Config and Config.BOARD and Config.BOARD.WIDTH or 60
    local height = Config and Config.BOARD and Config.BOARD.HEIGHT or 70
    local pegCount = Config and Config.BOARD and Config.BOARD.DEFAULT_PEG_COUNT or 120
    
    -- Obtener configuración para tema
    local levelName = "FOREST"
    local levelConfig = Config and Config.LEVELS and Config.LEVELS[levelName] or {
        PEG_COLORS = {
            BrickColor.new("Bright blue"),
            BrickColor.new("Bright green"),
            BrickColor.new("Bright yellow")
        },
        BACKGROUND_COLOR = Color3.fromRGB(30, 30, 50)
    }
    
    -- Configuración del tablero
    local boardConfig = {
        theme = levelName,
        pegColors = levelConfig.PEG_COLORS or {BrickColor.new("Bright blue")},
        backgroundColor = levelConfig.BACKGROUND_COLOR or Color3.fromRGB(30, 30, 50),
    }
    
    -- Crear el modelo del tablero
    local board = Instance.new("Model")
    board.Name = "PeglinBoard_" .. levelName
    
    -- Crear estructura para emular BoardService
    local boardServiceProxy = {
        currentBoard = board,
        pegs = {},
        pegCount = 0,
        criticalPegCount = 0,
        entryPoints = {},
        eventBus = EventBus,
        
        registerPegHit = function(self, pegPart)
            if BoardService then
                -- Intentar usar la función original si está disponible
                return BoardService.registerPegHit(BoardService, pegPart)
            else
                -- Función básica si BoardService no está disponible
                if not pegPart:GetAttribute("IsPeg") then
                    return false
                end
                
                -- Incrementar contador de golpes
                local hitCount = pegPart:GetAttribute("HitCount") or 0
                hitCount = hitCount + 1
                pegPart:SetAttribute("HitCount", hitCount)
                
                -- Animar la clavija
                local originalColor = pegPart.Color
                local originalSize = pegPart.Size
                
                spawn(function()
                    pegPart.Size = originalSize * 1.3
                    pegPart.Color = Color3.fromRGB(255, 255, 255)
                    
                    wait(0.1)
                    
                    pegPart.Size = originalSize
                    pegPart.Color = originalColor
                    
                    -- Desactivar la clavija si ha alcanzado el máximo de golpes
                    local maxHits = pegPart:GetAttribute("MaxHits") or 2
                    if hitCount >= maxHits then
                        for i = 1, 10 do
                            pegPart.Transparency = i / 10
                            wait(0.05)
                        end
                        pegPart.CanCollide = false
                        pegPart:SetAttribute("IsPeg", false)
                    end
                end)
                
                return true
            end
        end
    }
    
    -- Crear fondo del tablero
    local background = Instance.new("Part")
    background.Size = Vector3.new(width + 4, height + 4, 1)
    background.Position = Vector3.new(0, 0, 0.5)
    background.Anchored = true
    background.CanCollide = false
    background.Transparency = 0.3
    background.Color = boardConfig.backgroundColor
    background.Material = Enum.Material.SmoothPlastic
    background.Parent = board
    
    print("BoardCreator: Creando bordes...")
    -- Crear bordes usando BorderFactory
    if BorderFactory then
        local borderFactory = BorderFactory.new(boardServiceProxy)
        borderFactory:createBorders(board, width, height, boardConfig.theme)
    end
    
    print("BoardCreator: Generando clavijas...")
    -- Generar clavijas usando PegFactory
    if PegFactory then
        local pegFactory = PegFactory.new(boardServiceProxy)
        pegFactory:generatePegs(board, width, height, pegCount, boardConfig.pegColors, boardConfig.theme)
    end
    
    print("BoardCreator: Añadiendo obstáculos...")
    -- Añadir obstáculos especiales
    if ObstacleManager then
        local obstacleManager = ObstacleManager.new(boardServiceProxy)
        pcall(function()
            obstacleManager:addSpecialObstacles(board, width, height, boardConfig.theme)
        end)
    end
    
    print("BoardCreator: Añadiendo decoraciones...")
    -- Añadir decoraciones temáticas
    if ThemeDecorator then
        local themeDecorator = ThemeDecorator.new(boardServiceProxy)
        themeDecorator:addThemeDecorations(board, boardConfig.theme, width, height)
    end
    
    print("BoardCreator: Creando puntos de entrada...")
    -- Crear puntos de entrada
    if EntryPointFactory then
        local entryPointFactory = EntryPointFactory.new(boardServiceProxy)
        boardServiceProxy.entryPoints = entryPointFactory:createEntryPoints(board, width, height, boardConfig.theme)
    end
    
    print("BoardCreator: Configurando sistema de colisiones...")
    -- Establecer sistema de colisiones
    if CollisionHandler then
        local collisionHandler = CollisionHandler.new(boardServiceProxy)
        boardServiceProxy.collisionHandler = collisionHandler
    end
    
    -- Posicionar el tablero en el mundo
    board.Parent = workspace
    
    -- Publicar evento de tablero generado si EventBus está disponible
    if EventBus then
        EventBus:Publish("BoardGenerated", board, width, height, boardConfig.theme)
        print("BoardCreator: Evento BoardGenerated publicado")
    end
    
    print("BoardCreator: Tablero creado con éxito siguiendo la lógica de BoardService")
    return board, boardServiceProxy
end

-- Ejecutar la creación del tablero
local board, boardServiceProxy = createBoardUsingServices()

-- Crear un enemigo básico
if not workspace:FindFirstChild("Enemy_SLIME") then
    print("BoardCreator: Creando enemigo básico...")
    
    local enemyModel = Instance.new("Model")
    enemyModel.Name = "Enemy_SLIME"
    
    local mainPart = Instance.new("Part")
    mainPart.Shape = Enum.PartType.Ball
    mainPart.Size = Vector3.new(5, 5, 5)
    mainPart.Position = Vector3.new(0, 7, -10)
    mainPart.Anchored = true
    mainPart.CanCollide = false
    mainPart.Color = Color3.fromRGB(0, 200, 0)
    mainPart.Material = Enum.Material.SmoothPlastic
    mainPart.Parent = enemyModel
    
    local healthLabel = Instance.new("BillboardGui")
    healthLabel.Size = UDim2.new(0, 200, 0, 50)
    healthLabel.StudsOffset = Vector3.new(0, 3, 0)
    healthLabel.Adornee = mainPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "Slime: 100/100"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 18
    textLabel.Parent = healthLabel
    
    healthLabel.Parent = mainPart
    enemyModel.Parent = workspace
    
    print("BoardCreator: Enemigo creado con éxito")
end

-- Notificar al sistema de juego
if EventBus then
    print("BoardCreator: Enviando eventos para inicializar el juego...")
    
    -- Simular secuencia de inicio de juego
    EventBus:Publish("GameStarted", {currentPhase = "SETUP"})
    wait(0.5)
    EventBus:Publish("PhaseChanged", "SETUP", "PLAYER_TURN")
    EventBus:Publish("PlayerTurnStarted")
    
    print("BoardCreator: Juego inicializado")
end

-- Crear función global para reparar el tablero si algo falla
_G.RepairBoard = function()
    print("BoardCreator: Reparando tablero...")
    
    -- Limpiar tablero existente
    local existingBoard = workspace:FindFirstChild("PeglinBoard_FOREST")
    if existingBoard then
        existingBoard:Destroy()
    end
    
    -- Crear nuevo tablero
    createBoardUsingServices()
    
    return "Tablero reparado"
end

print("BoardCreator: Configuración completada. Función global _G.RepairBoard disponible")