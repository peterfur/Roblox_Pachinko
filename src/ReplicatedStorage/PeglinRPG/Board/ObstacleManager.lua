-- ObstacleManager.lua: Gestiona los obstáculos especiales del tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local ObstacleManager = {}
ObstacleManager.__index = ObstacleManager

function ObstacleManager.new(boardManager)
	local self = setmetatable({}, ObstacleManager)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

-- Añade obstáculos especiales al tablero
function ObstacleManager:addSpecialObstacles(board, width, height, theme)
    -- Crear deflectores (bumpers)
    self:createBumpers(board, width, height, theme)
    
    -- Crear paredes internas
    self:createInternalWalls(board, width, height, theme)
    
    -- Crear zonas de multiplicador
    self:createMultiplierZones(board, width, height, theme)
    
    -- Crear canales de aceleración
    self:createSpeedLanes(board, width, height, theme)
    
    -- Crear portales de teletransporte (para temas avanzados como "DUNGEON")
    if theme == "DUNGEON" then
        self:createTeleportPortals(board, width, height)
    end
end

-- Función para crear bumpers (deflectores) que dan más puntos al golpearlos
function ObstacleManager:createBumpers(board, width, height, theme)
    -- Determinar aspecto según tema
    local bumperColor
    local bumperMaterial
    
    if theme == "FOREST" then
        bumperColor = BrickColor.new("Bright green")
        bumperMaterial = Enum.Material.Grass
    elseif theme == "DUNGEON" then
        bumperColor = BrickColor.new("Really red")
        bumperMaterial = Enum.Material.Neon
    else
        bumperColor = BrickColor.new("Bright yellow")
        bumperMaterial = Enum.Material.Metal
    end
    
    -- Crear 6-8 bumpers en posiciones estratégicas
    local bumperSettings = Config.BOARD_ELEMENTS.BUMPERS
    local bumperCount = math.random(bumperSettings.MIN_COUNT, bumperSettings.MAX_COUNT)
    local bumperSize = bumperSettings.SIZE
    
    for i = 1, bumperCount do
        -- Calcular posición que no interfiera con otras clavijas
        local x, y
        local validPosition = false
        local attempts = 0
        
        while not validPosition and attempts < 30 do
            attempts = attempts + 1
            
            -- Posiciones estratégicas para mejor gameplay
            if i <= 4 then
                -- Bumpers en la parte superior
                x = (width / 5) * i - (width / 2) + (width / 10)
                y = height / 3
            else
                -- Bumpers en la parte media-inferior
                x = (width / 4) * (i - 4) - (width / 2) + (width / 8)
                y = -height / 4
            end
            
            -- Añadir pequeña variación aleatoria
            x = x + math.random(-5, 5)
            y = y + math.random(-3, 3)
            
            -- Comprobar si está lejos de otras clavijas
            validPosition = true
            for _, peg in ipairs(self.boardManager.pegs) do
-- Continuación de ObstacleManager.lua
local distance = math.sqrt((peg.Position.X - x)^2 + (peg.Position.Y - y)^2)
if distance < bumperSize * 1.5 then
    validPosition = false
    break
end
end
end

if validPosition then
local bumper = Instance.new("Part")
bumper.Shape = Enum.PartType.Ball
bumper.Size = Vector3.new(bumperSize, bumperSize, bumperSize)
bumper.Position = Vector3.new(x, y, 0)
bumper.BrickColor = bumperColor
bumper.Material = bumperMaterial
bumper.Anchored = true
bumper.CanCollide = true

-- Propiedades para interacción con orbes
bumper:SetAttribute("IsPeg", true)
bumper:SetAttribute("IsCritical", true)
bumper:SetAttribute("IsBumper", true)
bumper:SetAttribute("DamageMultiplier", Config.PEG_TYPES.BUMPER.DAMAGE_MULTIPLIER)
bumper:SetAttribute("HitCount", 0)
bumper:SetAttribute("MaxHits", Config.PEG_TYPES.BUMPER.MAX_HITS)
bumper:SetAttribute("BounceForce", bumperSettings.BOUNCE_FORCE)

-- Efecto visual
local light = Instance.new("PointLight")
light.Brightness = 1.5
light.Color = bumperColor.Color
light.Range = 6
light.Parent = bumper

bumper.Parent = board
table.insert(self.boardManager.pegs, bumper)

-- Crear un anillo alrededor del bumper
local ring = Instance.new("Part")
ring.Shape = Enum.PartType.Cylinder
ring.Size = Vector3.new(0.5, bumperSize + 1, bumperSize + 1)
ring.CFrame = CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(90))
ring.BrickColor = BrickColor.new("Institutional white")
ring.Material = Enum.Material.Neon
ring.Transparency = 0.5
ring.Anchored = true
ring.CanCollide = false
ring.Parent = board
end
end
end

-- Función para crear paredes internas que dividen el tablero
function ObstacleManager:createInternalWalls(board, width, height, theme)
-- Determinar aspecto según tema
local wallColor
local wallMaterial

if theme == "FOREST" then
wallColor = BrickColor.new("Brown")
wallMaterial = Enum.Material.Wood
elseif theme == "DUNGEON" then
wallColor = BrickColor.new("Dark stone grey")
wallMaterial = Enum.Material.Concrete
else
wallColor = BrickColor.new("Medium stone grey")
wallMaterial = Enum.Material.SmoothPlastic
end

-- Crear 2-3 paredes diagonales/horizontales internas
local wallSettings = Config.BOARD_ELEMENTS.INTERNAL_WALLS
local wallCount = math.random(wallSettings.MIN_COUNT, wallSettings.MAX_COUNT)

for i = 1, wallCount do
local wallLength = math.random(wallSettings.MIN_LENGTH, wallSettings.MAX_LENGTH)
local wallThickness = 1

-- Calcular posición
local x = math.random(-width/3, width/3)
local y = (height / (wallCount + 1)) * i - (height / 2) + (height / 8)

-- Determinar ángulo (horizontal, diagonal a la izquierda o a la derecha)
local angle = math.random(1, 3)
local rotation = 0

if angle == 1 then
rotation = 0  -- Horizontal
elseif angle == 2 then
rotation = math.rad(30)  -- Diagonal a la derecha
else
rotation = math.rad(-30)  -- Diagonal a la izquierda
end

local wall = Instance.new("Part")
wall.Size = Vector3.new(wallLength, wallThickness, 2)
wall.CFrame = CFrame.new(x, y, 0) * CFrame.Angles(0, 0, rotation)
wall.BrickColor = wallColor
wall.Material = wallMaterial
wall.Anchored = true
wall.CanCollide = true

-- Propiedades físicas para interacción con orbes
wall.CustomPhysicalProperties = PhysicalProperties.new(
    1,      -- Densidad
    0.3,    -- Fricción
    0.7,    -- Elasticidad
    1,      -- Peso
    0.5     -- Fricción rotacional
)

-- Identificador para el sistema de colisiones
wall:SetAttribute("IsWall", true)

wall.Parent = board

-- Añadir decoración temática a las paredes
if theme == "FOREST" then
-- Añadir musgo o vegetación
local moss = Instance.new("Part")
moss.Size = Vector3.new(wallLength, 0.2, 2)
moss.CFrame = CFrame.new(x, y + (wallThickness/2) + 0.1, 0) * CFrame.Angles(0, 0, rotation)
moss.BrickColor = BrickColor.new("Bright green")
moss.Material = Enum.Material.Grass
moss.Transparency = 0.3
moss.Anchored = true
moss.CanCollide = false
moss.Parent = board
elseif theme == "DUNGEON" then
-- Añadir cadenas o antorchas
for j = 1, 2 do
local torch = Instance.new("Part")
torch.Size = Vector3.new(0.5, 2, 0.5)
local offset = (j * (wallLength / 3)) - (wallLength / 2)

-- Calcular la posición de la antorcha en relación a la pared
local torchX = x + math.cos(rotation) * offset
local torchY = y + math.sin(rotation) * offset + 1

torch.Position = Vector3.new(torchX, torchY, 0.5)
torch.BrickColor = BrickColor.new("Bright orange")
torch.Material = Enum.Material.Neon
torch.Anchored = true
torch.CanCollide = false

-- Efecto de fuego
local fire = Instance.new("Fire")
fire.Heat = 5
fire.Size = 3
fire.Color = Color3.fromRGB(255, 100, 0)
fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
fire.Parent = torch

torch.Parent = board
end
end
end
end

-- Función para crear zonas de multiplicador
function ObstacleManager:createMultiplierZones(board, width, height, theme)
-- Crear 2-3 zonas de multiplicador
local zoneSettings = Config.BOARD_ELEMENTS.MULTIPLIER_ZONES
local zoneCount = math.random(zoneSettings.MIN_COUNT, zoneSettings.MAX_COUNT)

for i = 1, zoneCount do
-- Calcular posición
local x = (width / (zoneCount + 1)) * i - (width / 2) + (width / (zoneCount + 1) / 2)
local y = -height / 3

-- Crear zona
local zone = Instance.new("Part")
zone.Shape = Enum.PartType.Cylinder
zone.Size = Vector3.new(0.5, zoneSettings.SIZE, zoneSettings.SIZE)
zone.CFrame = CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(90))
zone.BrickColor = BrickColor.new("Bright violet")
zone.Material = Enum.Material.Neon
zone.Transparency = 0.7
zone.Anchored = true
zone.CanCollide = false

local multiplier = math.random(zoneSettings.MIN_MULTIPLIER, zoneSettings.MAX_MULTIPLIER)
zone:SetAttribute("IsMultiplierZone", true)
zone:SetAttribute("Multiplier", multiplier)

-- Texto con el multiplicador
local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.new(0, 50, 0, 50)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.Adornee = zone
billboard.AlwaysOnTop = true

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextSize = 14
label.Text = "x" .. multiplier
label.Parent = billboard

billboard.Parent = zone
zone.Parent = board

-- Crear pegs dentro de la zona de multiplicador
local pegCount = math.random(4, 6)
local radius = 3.5

for j = 1, pegCount do
local angle = (j / pegCount) * math.pi * 2
local pegX = x + math.cos(angle) * radius * 0.7
local pegY = y + math.sin(angle) * radius * 0.7

local peg = Instance.new("Part")
peg.Shape = Enum.PartType.Cylinder
peg.Size = Vector3.new(0.8, 2.5, 0.8)
peg.Orientation = Vector3.new(0, 0, 90) -- Horizontal
peg.Position = Vector3.new(pegX, pegY, 0)
peg.BrickColor = BrickColor.new("Bright violet")
peg.Material = Enum.Material.Neon
peg.Anchored = true
peg.CanCollide = true

peg:SetAttribute("IsPeg", true)
peg:SetAttribute("IsCritical", true)
peg:SetAttribute("InMultiplierZone", true)
peg:SetAttribute("Multiplier", multiplier)
peg:SetAttribute("HitCount", 0)
peg:SetAttribute("MaxHits", 2)

peg.Parent = board
table.insert(self.boardManager.pegs, peg)
end
end
end

-- Función para crear carriles de aceleración
function ObstacleManager:createSpeedLanes(board, width, height, theme)
-- Crear 2-3 carriles de aceleración
local laneSettings = Config.BOARD_ELEMENTS.SPEED_LANES
local laneCount = math.random(laneSettings.MIN_COUNT, laneSettings.MAX_COUNT)

for i = 1, laneCount do
-- Calcular posición
local startX = math.random(-width/3, width/3)
local startY = height/3
local endX = startX + math.random(-width/4, width/4)
local endY = -height/3

-- Crear carril (línea de puntos)
local segmentCount = laneSettings.SEGMENT_COUNT
local direction = Vector3.new(endX - startX, endY - startY, 0).Unit
local distance = math.sqrt((endX - startX)^2 + (endY - startY)^2)
local segmentLength = distance / segmentCount

for j = 0, segmentCount - 1 do
local segmentStart = Vector3.new(
    startX + direction.X * j * segmentLength,
    startY + direction.Y * j * segmentLength,0)

local arrow = Instance.new("Part")
arrow.Shape = Enum.PartType.Ball
arrow.Size = Vector3.new(1, 2, 0.2)
arrow.CFrame = CFrame.new(segmentStart) * CFrame.Angles(0, 0, math.atan2(direction.Y, direction.X))
arrow.BrickColor = BrickColor.new("Bright yellow")
arrow.Material = Enum.Material.Neon
arrow.Transparency = 0.5
arrow.Anchored = true
arrow.CanCollide = false

arrow:SetAttribute("IsSpeedLane", true)
arrow:SetAttribute("Direction", {X = direction.X, Y = direction.Y, Z = 0})
arrow:SetAttribute("SpeedBoost", laneSettings.SPEED_BOOST)

arrow.Parent = board
end
end
end

-- Función para crear portales de teletransporte (solo en temas avanzados)
function ObstacleManager:createTeleportPortals(board, width, height)
-- Crear 1-2 pares de portales
local portalSettings = Config.BOARD_ELEMENTS.TELEPORT_PORTALS
local portalPairs = math.random(portalSettings.MIN_PAIRS, portalSettings.MAX_PAIRS)

for i = 1, portalPairs do
-- Calcular posiciones
local entryX = math.random(-width/3, width/3)
local entryY = height/3 - math.random(0, 10)

local exitX = math.random(-width/3, width/3)
local exitY = -height/3 + math.random(0, 10)

-- Asegurar que la entrada y salida estén suficientemente separadas
while math.sqrt((exitX - entryX)^2 + (exitY - entryY)^2) < height/3 do
exitX = math.random(-width/3, width/3)
exitY = -height/3 + math.random(0, 10)
end

-- Crear portal de entrada
local entryPortal = Instance.new("Part")
entryPortal.Shape = Enum.PartType.Cylinder
entryPortal.Size = Vector3.new(0.5, portalSettings.SIZE, portalSettings.SIZE)
entryPortal.CFrame = CFrame.new(entryX, entryY, 0) * CFrame.Angles(0, 0, math.rad(90))
entryPortal.BrickColor = BrickColor.new("Bright blue")
entryPortal.Material = Enum.Material.Neon
entryPortal.Transparency = 0.5
entryPortal.Anchored = true
entryPortal.CanCollide = false

entryPortal:SetAttribute("IsPortal", true)
entryPortal:SetAttribute("PortalType", "Entry")
entryPortal:SetAttribute("ExitPosition", {X = exitX, Y = exitY, Z = 0})

-- Efectos visuales para el portal de entrada
local attachment = Instance.new("Attachment")
attachment.Parent = entryPortal

local particles = Instance.new("ParticleEmitter")
particles.Color = ColorSequence.new(Color3.fromRGB(0, 100, 255))
particles.Size = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.5),
NumberSequenceKeypoint.new(1, 0)
})
particles.Lifetime = NumberRange.new(0.5, 1)
particles.Rate = 30
particles.Speed = NumberRange.new(1, 3)
particles.SpreadAngle = Vector2.new(180, 180)
particles.Parent = attachment

entryPortal.Parent = board

-- Crear portal de salida
local exitPortal = Instance.new("Part")
exitPortal.Shape = Enum.PartType.Cylinder
exitPortal.Size = Vector3.new(0.5, portalSettings.SIZE, portalSettings.SIZE)
exitPortal.CFrame = CFrame.new(exitX, exitY, 0) * CFrame.Angles(0, 0, math.rad(90))
exitPortal.BrickColor = BrickColor.new("Bright orange")
exitPortal.Material = Enum.Material.Neon
exitPortal.Transparency = 0.5
exitPortal.Anchored = true
exitPortal.CanCollide = false

exitPortal:SetAttribute("IsPortal", true)
exitPortal:SetAttribute("PortalType", "Exit")

-- Efectos visuales para el portal de salida
local exitAttachment = Instance.new("Attachment")
exitAttachment.Parent = exitPortal

local exitParticles = Instance.new("ParticleEmitter")
exitParticles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
exitParticles.Size = NumberSequence.new({
NumberSequenceKeypoint.new(0, 0.5),
NumberSequenceKeypoint.new(1, 0)
})
exitParticles.Lifetime = NumberRange.new(0.5, 1)
exitParticles.Rate = 30
exitParticles.Speed = NumberRange.new(1, 3)
exitParticles.SpreadAngle = Vector2.new(180, 180)
exitParticles.Parent = exitAttachment

exitPortal.Parent = board
end
end

return ObstacleManager