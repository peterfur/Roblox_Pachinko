-- BorderFactory.lua: Responsable de crear los bordes y paneles de cristal del tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local BorderFactory = {}
BorderFactory.__index = BorderFactory

function BorderFactory.new(boardManager)
	local self = setmetatable({}, BorderFactory)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

function BorderFactory:createBorders(board, width, height, theme)
    -- Determinar apariencia según tema
    local borderColor
    local borderMaterial

    -- Asegurar que theme siempre tenga un valor válido
    theme = theme or "FOREST" -- Valor predeterminado si theme es nil

    if theme == "FOREST" then
        borderColor = BrickColor.new("Reddish brown")
        borderMaterial = Enum.Material.Wood
    elseif theme == "DUNGEON" then
        borderColor = BrickColor.new("Dark stone grey")
        borderMaterial = Enum.Material.Slate
    else
        borderColor = BrickColor.new("Medium stone grey")
        borderMaterial = Enum.Material.SmoothPlastic
    end

    -- ARREGLO: Dimensiones ampliadas de bordes para prevenir fugas
    local borderThickness = 5        -- Más grueso
    local borderHeight = height + 15  -- Mucho más alto para evitar que la bola salte por encima
    local extendedWidth = width + 10  -- Mayor ancho para cubrir esquinas
    
    -- CRÍTICO: Crear un sistema anti-fuga externo
    self:createOuterBoundary(board, width + 20, height + 20, borderColor, borderMaterial)
    
    -- Definir la función createBorder aquí, antes de usarla
    local function createBorder(position, size, isGlass)
        local border = Instance.new("Part")
        border.Size = size
        border.Position = position
        
        if isGlass then
            border.BrickColor = BrickColor.new("Institutional white")
            border.Material = Enum.Material.Glass
            border.Transparency = 0.7
            -- IMPORTANTE: Hacer que el cristal no bloquee los raycast ni los clics
            border.CanCollide = true     -- Aún colisiona con el orbe
            border.CanQuery = false      -- No intercepta raycast para clics
        else
            border.BrickColor = borderColor
            border.Material = borderMaterial
            border.CanCollide = true
        end
        
        -- ARREGLO: Añadir CustomPhysicalProperties más sólidas para evitar penetraciones
        border.CustomPhysicalProperties = PhysicalProperties.new(
            15,    -- Densidad (aumentada significativamente)
            0.1,   -- Fricción (baja para que los orbes se deslicen bien)
            0.7,   -- Elasticidad (alta para buenos rebotes)
            15,    -- Peso (aumentado significativamente)
            0.1    -- Fricción rotacional (baja)
        )
        
        border.Anchored = true
        border.Parent = board
        
        -- ARREGLO: Añadir atributo para identificar los bordes en el sistema de colisiones
        border:SetAttribute("IsBorder", true)
        
        return border
    end

    -- Bordes superior e inferior - Más altos y anchos
    createBorder(Vector3.new(0, height/2 + borderThickness/2, 0), Vector3.new(extendedWidth, borderThickness, 5))
    createBorder(Vector3.new(0, -height/2 - borderThickness/2, 0), Vector3.new(extendedWidth, borderThickness, 5))
    
    -- Bordes laterales más altos para evitar que las pelotas salgan
    createBorder(Vector3.new(width/2 + borderThickness/2, 0, 0), Vector3.new(borderThickness, borderHeight, 5))
    createBorder(Vector3.new(-width/2 - borderThickness/2, 0, 0), Vector3.new(borderThickness, borderHeight, 5))
    
    -- ARREGLO: Añadir bordes adicionales en ángulo en las esquinas para evitar escapes
    local cornerSize = 10
    createBorder(Vector3.new(width/2 - cornerSize/2, height/2 + borderThickness + cornerSize/2, 0), 
                 Vector3.new(cornerSize, cornerSize, 5))
    createBorder(Vector3.new(-width/2 + cornerSize/2, height/2 + borderThickness + cornerSize/2, 0), 
                 Vector3.new(cornerSize, cornerSize, 5))
    
    -- ARREGLO: Añadir techo "invisible" para contener orbes con mucho impulso vertical
    local ceiling = createBorder(Vector3.new(0, height/2 + 20, 0), Vector3.new(width + 20, 3, 10))
    ceiling.Transparency = 0.9  -- Casi invisible
    
    -- Paredes de cristal más grandes y alejadas para evitar la sensación de encierro
    createBorder(Vector3.new(0, 0, 2), Vector3.new(width + 20, borderHeight, 0.5), true)  -- Cristal delantero
    createBorder(Vector3.new(0, 0, -2), Vector3.new(width + 20, borderHeight, 0.5), true) -- Cristal trasero
    
    -- Añadir guías adicionales en las esquinas para redirigir las bolas
    self:createCornerGuides(board, width, height, borderColor, borderMaterial)
    
    -- Crear esquinas decorativas
    self:createCorners(board, width, height, borderColor, borderMaterial)
    
    -- ARREGLO: Crear guías laterales reforzadas para ayudar a que los orbes fluyan correctamente
    self:createSideGuides(board, width, height, theme)
    
    -- ARREGLO: Crear pendientes en la parte inferior para que los orbes no se queden atascados
    self:createBottomSlopes(board, width, height, borderColor, borderMaterial)
end

-- ARREGLO: Nueva función para crear un límite externo de seguridad
function BorderFactory:createOuterBoundary(board, width, height, borderColor, borderMaterial)
    -- Crear un borde invisible de seguridad alrededor de todo el tablero
    -- Este borde capturará cualquier orbe que de alguna manera logre "escapar" del tablero principal
    
    -- Borde superior (más allá del borde visible)
    local topBoundary = Instance.new("Part")
    topBoundary.Size = Vector3.new(width + 20, 5, 10)
    topBoundary.Position = Vector3.new(0, height/2 + 30, 0)
    topBoundary.BrickColor = borderColor
    topBoundary.Transparency = 0.9  -- Casi invisible
    topBoundary.Anchored = true
    topBoundary.CanCollide = true
    topBoundary:SetAttribute("IsOuterBoundary", true)
    topBoundary.Parent = board
    
    -- Bordes laterales extremos (más allá de los bordes visibles)
    local leftBoundary = Instance.new("Part")
    leftBoundary.Size = Vector3.new(5, height + 60, 10)
    leftBoundary.Position = Vector3.new(-width/2 - 15, 0, 0)
    leftBoundary.BrickColor = borderColor
    leftBoundary.Transparency = 0.9
    leftBoundary.Anchored = true
    leftBoundary.CanCollide = true
    leftBoundary:SetAttribute("IsOuterBoundary", true)
    leftBoundary.Parent = board
    
    local rightBoundary = Instance.new("Part")
    rightBoundary.Size = Vector3.new(5, height + 60, 10)
    rightBoundary.Position = Vector3.new(width/2 + 15, 0, 0)
    rightBoundary.BrickColor = borderColor
    rightBoundary.Transparency = 0.9
    rightBoundary.Anchored = true
    rightBoundary.CanCollide = true
    rightBoundary:SetAttribute("IsOuterBoundary", true)
    rightBoundary.Parent = board
    
    -- Borde inferior de seguridad (para capturar orbes que caen)
    local bottomBoundary = Instance.new("Part")
    bottomBoundary.Size = Vector3.new(width + 50, 5, 10)
    bottomBoundary.Position = Vector3.new(0, -height/2 - 15, 0)
    bottomBoundary.BrickColor = borderColor
    bottomBoundary.Transparency = 0.9
    bottomBoundary.Anchored = true
    bottomBoundary.CanCollide = true
    bottomBoundary.CustomPhysicalProperties = PhysicalProperties.new(100, 1, 0, 100, 1)  -- Sin rebote
    bottomBoundary:SetAttribute("IsOuterBoundary", true)
    bottomBoundary:SetAttribute("IsCatcher", true)  -- Marca especial para el sistema de detección de caída
    bottomBoundary.Parent = board
end

-- Nueva función para crear guías en las esquinas
function BorderFactory:createCornerGuides(board, width, height, borderColor, borderMaterial)
    -- ARREGLO: Mejorar las guías en las esquinas para un mejor rebote
    local cornerGuidePositions = {
        {pos = Vector3.new(width/2 - 6, height/2 - 6, 0), rot = 45},  -- Esquina superior derecha
        {pos = Vector3.new(-width/2 + 6, height/2 - 6, 0), rot = -45}, -- Esquina superior izquierda
        -- ARREGLO: Añadir guías en esquinas inferiores para evitar atascamientos
        {pos = Vector3.new(width/2 - 6, -height/2 + 6, 0), rot = -45},  -- Esquina inferior derecha
        {pos = Vector3.new(-width/2 + 6, -height/2 + 6, 0), rot = 45}   -- Esquina inferior izquierda
    }
    
    for _, guide in ipairs(cornerGuidePositions) do
        local cornerGuide = Instance.new("Part")
        cornerGuide.Size = Vector3.new(12, 2, 3)  -- ARREGLO: Guías más gruesas y largas
        cornerGuide.CFrame = CFrame.new(guide.pos) * CFrame.Angles(0, 0, math.rad(guide.rot))
        cornerGuide.BrickColor = borderColor
        cornerGuide.Material = borderMaterial
        cornerGuide.Anchored = true
        cornerGuide.CanCollide = true
        
        -- ARREGLO: Propiedades físicas mejoradas para mejor rebote
        cornerGuide.CustomPhysicalProperties = PhysicalProperties.new(
            5,    -- Densidad (aumentada)
            0.1,  -- Fricción (baja)
            0.85, -- Elasticidad (alta)
            5,    -- Peso (aumentado)
            0.1   -- Fricción rotacional (baja)
        )
        
        -- ARREGLO: Marcamos estas guías para identificación en collisionHandler
        cornerGuide:SetAttribute("IsGuide", true)
        
        cornerGuide.Parent = board
        
        -- ARREGLO: Añadir efecto visual para mejorar el feedback
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.5
        highlight.FillColor = borderColor.Color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = cornerGuide
    end
end

-- Crea las esquinas decorativas del tablero
function BorderFactory:createCorners(board, width, height, borderColor, borderMaterial)
	local cornerSize = 4  -- Aumentado ligeramente
	local cornerPositions = {
		Vector3.new(width/2 + 3, height/2 + 3, 0),
		Vector3.new(-width/2 - 3, height/2 + 3, 0),
		Vector3.new(width/2 + 3, -height/2 - 3, 0),
		Vector3.new(-width/2 - 3, -height/2 - 3, 0)
	}

	for _, pos in ipairs(cornerPositions) do
		local corner = Instance.new("Part")
		corner.Shape = Enum.PartType.Ball
		corner.Size = Vector3.new(cornerSize, cornerSize, cornerSize)
		corner.Position = pos
		corner.BrickColor = borderColor
		corner.Material = borderMaterial
		corner.Anchored = true
		corner.CanCollide = true
		corner.Parent = board
	end
end

-- ARREGLO: Creación de pendientes en la parte inferior para evitar atascamientos
function BorderFactory:createBottomSlopes(board, width, height, borderColor, borderMaterial)
    -- Crear pendientes que dirigen los orbes hacia el centro-abajo
    local leftSlope = Instance.new("Part")
    leftSlope.Size = Vector3.new(width/2 - 5, 2, 3)
    leftSlope.Position = Vector3.new(-width/4, -height/2 + 3, 0)
    leftSlope.Orientation = Vector3.new(0, 0, -10)  -- Pendiente hacia la derecha
    leftSlope.BrickColor = borderColor
    leftSlope.Material = borderMaterial
    leftSlope.Transparency = 0.4
    leftSlope.Anchored = true
    leftSlope.CanCollide = true
    leftSlope:SetAttribute("IsGuide", true)
    leftSlope.Parent = board
    
    local rightSlope = Instance.new("Part")
    rightSlope.Size = Vector3.new(width/2 - 5, 2, 3)
    rightSlope.Position = Vector3.new(width/4, -height/2 + 3, 0)
    rightSlope.Orientation = Vector3.new(0, 0, 10)  -- Pendiente hacia la izquierda
    rightSlope.BrickColor = borderColor
    rightSlope.Material = borderMaterial
    rightSlope.Transparency = 0.4
    rightSlope.Anchored = true
    rightSlope.CanCollide = true
    rightSlope:SetAttribute("IsGuide", true)
    rightSlope.Parent = board
    
    -- Rampa central para dirigir hacia abajo
    local centerSlope = Instance.new("Part")
    centerSlope.Size = Vector3.new(10, 1, 3)
    centerSlope.Position = Vector3.new(0, -height/2 + 1, 0)
    centerSlope.Orientation = Vector3.new(0, 0, 0)
    centerSlope.BrickColor = borderColor
    centerSlope.Material = borderMaterial
    centerSlope.Transparency = 0.4
    centerSlope.Anchored = true
    centerSlope.CanCollide = true
    centerSlope:SetAttribute("IsGuide", true)
    centerSlope.Parent = board
end

-- Crea guías laterales para ayudar a dirigir los orbes
function BorderFactory:createSideGuides(board, width, height, theme)
	local guideColor
	local guideMaterial
	
	if theme == "FOREST" then
		guideColor = BrickColor.new("Bright green")
		guideMaterial = Enum.Material.Neon
	elseif theme == "DUNGEON" then
		guideColor = BrickColor.new("Bright orange")
		guideMaterial = Enum.Material.Neon
	else
		guideColor = BrickColor.new("Bright yellow")
		guideMaterial = Enum.Material.Neon
	end
	
	-- ARREGLO: Guías laterales mejoradas - más largas y mejor posicionadas
	-- Guía izquierda
	local leftGuide = Instance.new("Part")
	leftGuide.Size = Vector3.new(0.8, height * 0.9, 0.5)  -- Más largo y ligeramente más grueso
	leftGuide.Position = Vector3.new(-width/2 + 4, 0, 0)
	leftGuide.Orientation = Vector3.new(0, 0, -8) -- Ligera inclinación
	leftGuide.BrickColor = guideColor
	leftGuide.Material = guideMaterial
	leftGuide.Transparency = 0.5  -- Menos transparente para mejor visibilidad
	leftGuide.Anchored = true
	leftGuide.CanCollide = true
	
	-- Para que el orbe rebote pero la cámara pueda ver a través
	leftGuide.CanQuery = false
	
	-- ARREGLO: Propiedades físicas mejoradas
	leftGuide.CustomPhysicalProperties = PhysicalProperties.new(
		3,    -- Densidad (aumentada)
		0.05, -- Fricción (muy baja para permitir que el orbe se deslice fácilmente)
		0.9,  -- Elasticidad (muy alta para buen rebote)
		3,    -- Peso (aumentado)
		0.1   -- Fricción rotacional (baja)
	)
	
	leftGuide:SetAttribute("IsGuide", true)
	leftGuide.Parent = board
	
	-- Guía derecha
	local rightGuide = Instance.new("Part")
	rightGuide.Size = Vector3.new(0.8, height * 0.9, 0.5)  -- Más largo y ligeramente más grueso
	rightGuide.Position = Vector3.new(width/2 - 4, 0, 0)
	rightGuide.Orientation = Vector3.new(0, 0, 8) -- Ligera inclinación en sentido opuesto
	rightGuide.BrickColor = guideColor
	rightGuide.Material = guideMaterial
	rightGuide.Transparency = 0.5  -- Menos transparente para mejor visibilidad
	rightGuide.Anchored = true
	rightGuide.CanCollide = true
	
	-- Para que el orbe rebote pero la cámara pueda ver a través
	rightGuide.CanQuery = false
	
	-- ARREGLO: Propiedades físicas mejoradas
	rightGuide.CustomPhysicalProperties = PhysicalProperties.new(
		3,    -- Densidad (aumentada)
		0.05, -- Fricción (muy baja para permitir que el orbe se deslice fácilmente)
		0.9,  -- Elasticidad (muy alta para buen rebote)
		3,    -- Peso (aumentado)
		0.1   -- Fricción rotacional (baja)
	)
	
	rightGuide:SetAttribute("IsGuide", true)
	rightGuide.Parent = board
	
	-- ARREGLO: Añadir más guías en el cuerpo del tablero para evitar atascamientos
	-- Guía media-izquierda
	local midLeftGuide = Instance.new("Part")
	midLeftGuide.Size = Vector3.new(0.8, height * 0.6, 0.5)
	midLeftGuide.Position = Vector3.new(-width/4, 0, 0)
	midLeftGuide.Orientation = Vector3.new(0, 0, -10)
	midLeftGuide.BrickColor = guideColor
	midLeftGuide.Material = guideMaterial
	midLeftGuide.Transparency = 0.7
	midLeftGuide.Anchored = true
	midLeftGuide.CanCollide = true
	midLeftGuide.CanQuery = false
	midLeftGuide.CustomPhysicalProperties = PhysicalProperties.new(3, 0.05, 0.9, 3, 0.1)
	midLeftGuide:SetAttribute("IsGuide", true)
	midLeftGuide.Parent = board
	
	-- Guía media-derecha
	local midRightGuide = Instance.new("Part")
	midRightGuide.Size = Vector3.new(0.8, height * 0.6, 0.5)
	midRightGuide.Position = Vector3.new(width/4, 0, 0)
	midRightGuide.Orientation = Vector3.new(0, 0, 10)
	midRightGuide.BrickColor = guideColor
	midRightGuide.Material = guideMaterial
	midRightGuide.Transparency = 0.7
	midRightGuide.Anchored = true
	midRightGuide.CanCollide = true
	midRightGuide.CanQuery = false
	midRightGuide.CustomPhysicalProperties = PhysicalProperties.new(3, 0.05, 0.9, 3, 0.1)
	midRightGuide:SetAttribute("IsGuide", true)
	midRightGuide.Parent = board
end

return BorderFactory