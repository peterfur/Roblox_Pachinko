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

-- Crea los bordes del tablero y paneles de cristal
function BorderFactory:createBorders(board, width, height, theme)
	-- Determinar apariencia según tema
	local borderColor
	local borderMaterial

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

	-- Crear bordes
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
		
		border.Anchored = true

		-- Propiedades físicas personalizadas para los bordes
		border.CustomPhysicalProperties = PhysicalProperties.new(
			1,    -- Densidad
			0.3,  -- Fricción
			0.6,  -- Elasticidad
			1,    -- Peso
			0.5   -- Fricción rotacional
		)

		border.Parent = board
	end

	-- Bordes superior e inferior
	createBorder(Vector3.new(0, height/2 + 1, 0), Vector3.new(width + 8, 2, 2))
	createBorder(Vector3.new(0, -height/2 - 1, 0), Vector3.new(width + 8, 2, 2))

	-- Bordes laterales
	createBorder(Vector3.new(width/2 + 3, 0, 0), Vector3.new(2, height + 6, 2))
	createBorder(Vector3.new(-width/2 - 3, 0, 0), Vector3.new(2, height + 6, 2))

	-- Paredes de cristal para mantener el orbe dentro del área de juego
	createBorder(Vector3.new(0, 0, 2), Vector3.new(width + 8, height + 6, 0.5), true)  -- Cristal delantero
	createBorder(Vector3.new(0, 0, -2), Vector3.new(width + 8, height + 6, 0.5), true) -- Cristal trasero

	-- Añadir esquinas decorativas
	self:createCorners(board, width, height, borderColor, borderMaterial)
	
	-- Añadir guías laterales si se desea
	if Config.BOARD.ADD_SIDE_GUIDES then
		self:createSideGuides(board, width, height, theme)
	end
end

-- Crea las esquinas decorativas del tablero
function BorderFactory:createCorners(board, width, height, borderColor, borderMaterial)
	local cornerSize = 3
	local cornerPositions = {
		Vector3.new(width/2 + 2, height/2 + 2, 0),
		Vector3.new(-width/2 - 2, height/2 + 2, 0),
		Vector3.new(width/2 + 2, -height/2 - 2, 0),
		Vector3.new(-width/2 - 2, -height/2 - 2, 0)
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
	
	-- Guía izquierda
	local leftGuide = Instance.new("Part")
	leftGuide.Size = Vector3.new(0.5, height * 0.7, 0.1)
	leftGuide.Position = Vector3.new(-width/2 + 5, 0, 0)
	leftGuide.Orientation = Vector3.new(0, 0, -10) -- Ligera inclinación
	leftGuide.BrickColor = guideColor
	leftGuide.Material = guideMaterial
	leftGuide.Transparency = 0.6
	leftGuide.Anchored = true
	leftGuide.CanCollide = true
	
	-- Para que el orbe rebote pero la cámara pueda ver a través
	leftGuide.CanQuery = false
	
	-- Propiedades físicas
	leftGuide.CustomPhysicalProperties = PhysicalProperties.new(
		1,    -- Densidad
		0.1,  -- Fricción (baja para permitir que el orbe se deslice)
		0.8,  -- Elasticidad (alta para buen rebote)
		1,    -- Peso
		0.2   -- Fricción rotacional
	)
	
	leftGuide.Parent = board
	
	-- Guía derecha
	local rightGuide = Instance.new("Part")
	rightGuide.Size = Vector3.new(0.5, height * 0.7, 0.1)
	rightGuide.Position = Vector3.new(width/2 - 5, 0, 0)
	rightGuide.Orientation = Vector3.new(0, 0, 10) -- Ligera inclinación en sentido opuesto
	rightGuide.BrickColor = guideColor
	rightGuide.Material = guideMaterial
	rightGuide.Transparency = 0.6
	rightGuide.Anchored = true
	rightGuide.CanCollide = true
	
	-- Para que el orbe rebote pero la cámara pueda ver a través
	rightGuide.CanQuery = false
	
	-- Propiedades físicas
	rightGuide.CustomPhysicalProperties = PhysicalProperties.new(
		1,    -- Densidad
		0.1,  -- Fricción (baja para permitir que el orbe se deslice)
		0.8,  -- Elasticidad (alta para buen rebote)
		1,    -- Peso
		0.2   -- Fricción rotacional
	)
	
	rightGuide.Parent = board
end

return BorderFactory