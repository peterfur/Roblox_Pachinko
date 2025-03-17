-- BoardManager.lua: Gestiona el tablero de juego y las clavijas

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local BoardManager = {}
BoardManager.__index = BoardManager

-- Constructor del gestor de tablero
function BoardManager.new()
	local self = setmetatable({}, BoardManager)

	-- Propiedades
	self.currentBoard = nil
	self.pegCount = 0
	self.criticalPegCount = 0
	self.activeBoard = nil
	self.pegs = {}

	return self
end

-- Genera un nuevo tablero de juego
function BoardManager:generateBoard(width, height, pegCount, options)
	-- Limpiar tablero existente si lo hay
	if self.currentBoard then
		self.currentBoard:Destroy()
	end

	-- Opciones por defecto
	options = options or {}
	local theme = options.theme or "FOREST"
	local pegColors = options.pegColors or {
		BrickColor.new("Bright blue"),
		BrickColor.new("Cyan"),
		BrickColor.new("Royal blue")
	}
	local backgroundColor = options.backgroundColor or Color3.fromRGB(30, 30, 50)

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

	-- Crear bordes
	self:createBorders(board, width, height, theme)

	-- Generar clavijas
	self:generatePegs(board, width, height, pegCount, pegColors, theme)

	-- Añadir decoraciones temáticas
	self:addThemeDecorations(board, theme, width, height)

	-- Posicionar el tablero en el mundo
	board.Parent = workspace

	return board
end

-- Crea los bordes del tablero
function BoardManager:createBorders(board, width, height, theme)
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
	local function createBorder(position, size)
		local border = Instance.new("Part")
		border.Size = size
		border.Position = position
		border.BrickColor = borderColor
		border.Material = borderMaterial
		border.Anchored = true
		border.CanCollide = true

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

	-- Añadir esquinas decorativas
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

-- Genera las clavijas en el tablero
function BoardManager:generatePegs(board, width, height, pegCount, pegColors, theme)
	-- Resetear contadores
	self.pegCount = 0
	self.criticalPegCount = 0

	-- Calcular distribución de clavijas
	local minDistance = 4 -- Distancia mínima entre clavijas
	local pegPositions = {}

	-- Listas para almacenar clavijas
	self.pegs = {}

	-- Patrones según el tema
	local patternFunc

	if theme == "FOREST" then
		patternFunc = function(x, y)
			-- Patrón de bosque: más denso en el centro y abajo
			local centerDist = math.sqrt((x)^2 + (y)^2)
			local bottomBias = (y + height/4) / height
			return math.random() < (0.7 - centerDist/50 + bottomBias*0.3)
		end
	elseif theme == "DUNGEON" then
		patternFunc = function(x, y)
			-- Patrón de mazmorra: rejilla más estructurada
			local gridSize = 10
			local onGrid = (math.abs(x) % gridSize < 2) or (math.abs(y) % gridSize < 2)
			return onGrid and math.random() < 0.7
		end
	else
		patternFunc = function(x, y)
			-- Patrón estándar: distribución aleatoria
			return math.random() < 0.5
		end
	end

	-- Intentar colocar el número deseado de clavijas
	for i = 1, pegCount * 2 do -- Intentamos más veces para asegurar buena cobertura
		if self.pegCount >= pegCount then break end

		-- Generar posición candidata
		local x = math.random(-width/2 + 5, width/2 - 5)
		local y = math.random(-height/2 + 5, height/2 - 5)

		-- Verificar patrón específico del tema
		if not patternFunc(x, y) then
			-- No cumple el patrón, saltar esta posición
			continue
		end

		-- Comprobar distancia con otras clavijas
		local tooClose = false
		for _, pos in ipairs(pegPositions) do
			local distance = math.sqrt((pos.X - x)^2 + (pos.Y - y)^2)
			if distance < minDistance then
				tooClose = true
				break
			end
		end

		if not tooClose then
			-- Posición válida, añadir a la lista
			table.insert(pegPositions, Vector3.new(x, y, 0))

			-- 20% de probabilidad de ser clavija crítica
			local isCritical = math.random(1, 100) <= 20
			if isCritical then
				self.criticalPegCount = self.criticalPegCount + 1
			end

			-- Crear la clavija
			local peg = self:createPeg(Vector3.new(x, y, 0), isCritical, pegColors, theme)
			peg.Parent = board

			-- Añadir a la lista de clavijas
			table.insert(self.pegs, peg)
			self.pegCount = self.pegCount + 1
		end
	end

	return self.pegCount
end

-- Crea una clavija individual
function BoardManager:createPeg(position, isCritical, pegColors, theme)
	local peg = Instance.new("Part")
	peg.Shape = Enum.PartType.Cylinder
	peg.Size = Vector3.new(0.8, 2.5, 0.8)
	peg.Orientation = Vector3.new(0, 0, 90) -- Horizontal
	peg.Position = position

	-- Apariencia basada en si es crítica
	if isCritical then
		peg.BrickColor = BrickColor.new("Really red")
		peg.Material = Enum.Material.Neon
	else
		-- Seleccionar color aleatorio del tema
		peg.BrickColor = pegColors[math.random(1, #pegColors)]

		-- Material según tema
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

	-- Efecto visual para clavijas críticas
	if isCritical then
		local light = Instance.new("PointLight")
		light.Brightness = 1
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Range = 4
		light.Parent = peg
	end

	return peg
end

-- Añade decoraciones temáticas al tablero
function BoardManager:addThemeDecorations(board, theme, width, height)
	if theme == "FOREST" then
		-- Añadir árboles en las esquinas
		local treePositions = {
			Vector3.new(width/2 - 5, height/2 - 5, 0),
			Vector3.new(-width/2 + 5, height/2 - 5, 0),
			Vector3.new(width/2 - 5, -height/2 + 5, 0),
			Vector3.new(-width/2 + 5, -height/2 + 5, 0)
		}

		for _, pos in ipairs(treePositions) do
			self:createTree(pos, board)
		end

		-- Añadir hojas caídas aleatorias
		for i = 1, 15 do
			local x = math.random(-width/2 + 3, width/2 - 3)
			local y = math.random(-height/2 + 3, height/2 - 3)

			local leaf = Instance.new("Part")
			leaf.Shape = Enum.PartType.Ball
			leaf.Size = Vector3.new(0.5, 0.1, 0.5)
			leaf.Position = Vector3.new(x, y, 0.2)
			leaf.Rotation = Vector3.new(0, math.random(0, 360), 0)
			leaf.BrickColor = BrickColor.new("Lime green")
			leaf.Material = Enum.Material.Grass
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.Transparency = 0.3
			leaf.Parent = board
		end

	elseif theme == "DUNGEON" then
		-- Añadir antorchas en las paredes
		local torchPositions = {
			Vector3.new(width/2 - 5, height/2 - 10, 0),
			Vector3.new(-width/2 + 5, height/2 - 10, 0),
			Vector3.new(width/2 - 5, -height/2 + 10, 0),
			Vector3.new(-width/2 + 5, -height/2 + 10, 0),
			Vector3.new(width/2 - 15, height/2 - 5, 0),
			Vector3.new(-width/2 + 15, height/2 - 5, 0),
			Vector3.new(width/2 - 15, -height/2 + 5, 0),
			Vector3.new(-width/2 + 15, -height/2 + 5, 0)
		}

		for _, pos in ipairs(torchPositions) do
			self:createTorch(pos, board)
		end

		-- Añadir cadenas colgando
		for i = 1, 5 do
			local x = math.random(-width/2 + 10, width/2 - 10)
			local y = height/2 - 3
			self:createChain(Vector3.new(x, y, 0), math.random(5, 10), board)
		end
	end

	-- Añadir punto de entrada para la bola
	self:createEntryPoint(Vector3.new(0, height/2 - 4, 0), board, theme)
end

-- Crea un árbol decorativo
function BoardManager:createTree(position, parent)
	-- Tronco
	local trunk = Instance.new("Part")
	trunk.Size = Vector3.new(1, 4, 1)
	trunk.Position = position
	trunk.BrickColor = BrickColor.new("Reddish brown")
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.CanCollide = false
	trunk.Parent = parent

	-- Copa del árbol (3 niveles)
	for i = 1, 3 do
		local leaves = Instance.new("Part")
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(5 - i, 2, 5 - i)
		leaves.Position = Vector3.new(position.X, position.Y + 2 + i, position.Z)
		leaves.BrickColor = BrickColor.new("Forest green")
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Transparency = 0.2
		leaves.Parent = parent
	end
end

-- Crea una antorcha decorativa
function BoardManager:createTorch(position, parent)
	-- Soporte
	local handle = Instance.new("Part")
	handle.Size = Vector3.new(0.5, 1.5, 0.5)
	handle.Position = position
	handle.BrickColor = BrickColor.new("Dark stone grey")
	handle.Material = Enum.Material.Metal
	handle.Anchored = true
	handle.CanCollide = false
	handle.Parent = parent

	-- Fuego
	local fire = Instance.new("Part")
	fire.Shape = Enum.PartType.Ball
	fire.Size = Vector3.new(1, 1, 1)
	fire.Position = Vector3.new(position.X, position.Y + 1, position.Z)
	fire.BrickColor = BrickColor.new("Bright orange")
	fire.Material = Enum.Material.Neon
	fire.Transparency = 0.3
	fire.Anchored = true
	fire.CanCollide = false
	fire.Parent = parent

	-- Efecto de luz
	local light = Instance.new("PointLight")
	light.Brightness = 5
	light.Color = Color3.fromRGB(255, 180, 100)
	light.Range = 10
	light.Parent = fire

	-- Efecto de fuego
	local fireEffect = Instance.new("Fire")
	fireEffect.Heat = 10
	fireEffect.Size = 3
	fireEffect.Color = Color3.fromRGB(255, 100, 0)
	fireEffect.SecondaryColor = Color3.fromRGB(255, 200, 0)
	fireEffect.Parent = fire
end

-- Crea una cadena decorativa
function BoardManager:createChain(position, length, parent)
	local chainWidth = 0.3

	for i = 1, length do
		local link = Instance.new("Part")
		link.Size = Vector3.new(chainWidth, chainWidth, 0.8)
		link.Position = Vector3.new(position.X, position.Y - i, position.Z)
		link.BrickColor = BrickColor.new("Dark grey metallic")
		link.Material = Enum.Material.Metal
		link.Anchored = true
		link.CanCollide = false

		-- Alternar orientación para simular cadena
		if i % 2 == 0 then
			link.Orientation = Vector3.new(0, 90, 0)
		end

		link.Parent = parent
	end
end

-- Crea el punto de entrada para la bola
function BoardManager:createEntryPoint(position, parent, theme)
	-- Base
	local base = Instance.new("Part")
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(4, 4, 4)
	base.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))

	if theme == "FOREST" then
		base.BrickColor = BrickColor.new("Dark green")
		base.Material = Enum.Material.Grass
	elseif theme == "DUNGEON" then
		base.BrickColor = BrickColor.new("Dark stone grey")
		base.Material = Enum.Material.Slate
	else
		base.BrickColor = BrickColor.new("Medium stone grey")
		base.Material = Enum.Material.SmoothPlastic
	end

	base.Anchored = true
	base.CanCollide = true
	base.Parent = parent

	-- Indicador visual
	local indicator = Instance.new("Part")
	indicator.Shape = Enum.PartType.Ball
	indicator.Size = Vector3.new(2, 2, 2)
	indicator.Position = Vector3.new(position.X, position.Y, position.Z + 1)
	indicator.BrickColor = BrickColor.new("Lime green")
	indicator.Material = Enum.Material.Neon
	indicator.Transparency = 0.5
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.Parent = parent

	-- Añadir luz
	local light = Instance.new("PointLight")
	light.Brightness = 2
	light.Color = Color3.fromRGB(100, 255, 100)
	light.Range = 5
	light.Parent = indicator

	-- Etiqueta "LANZA AQUÍ"
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Adornee = indicator
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = "LANZA AQUÍ"
	label.Parent = billboard

	billboard.Parent = indicator
end

-- Registra un golpe en una clavija
function BoardManager:registerPegHit(pegPart)
	if not pegPart:GetAttribute("IsPeg") then
		return false
	end

	-- Incrementar contador de golpes
	local hitCount = pegPart:GetAttribute("HitCount") or 0
	hitCount = hitCount + 1
	pegPart:SetAttribute("HitCount", hitCount)

	-- Si la clavija ha sido golpeada suficientes veces, desactivarla
	if hitCount >= 2 then
		pegPart.Transparency = 0.8
		pegPart.CanCollide = false
		pegPart:SetAttribute("IsPeg", false)

		-- Si era una clavija crítica, reducir el contador
		if pegPart:GetAttribute("IsCritical") then
			self.criticalPegCount = self.criticalPegCount - 1
		end

		self.pegCount = self.pegCount - 1
	end

	return true
end

-- Devuelve estadísticas del tablero actual
function BoardManager:getBoardStats()
	return {
		totalPegs = self.pegCount,
		criticalPegs = self.criticalPegCount,
		pegsHit = 0, -- Esto se actualizaría durante el juego
		boardWidth = self.currentBoard and self.currentBoard.Size.X or 0,
		boardHeight = self.currentBoard and self.currentBoard.Size.Y or 0
	}
end

return BoardManager