-- EntryPointFactory.lua: Crea el punto de entrada para los orbes en el tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local EntryPointFactory = {}
EntryPointFactory.__index = EntryPointFactory

function EntryPointFactory.new(boardManager)
	local self = setmetatable({}, EntryPointFactory)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

-- Crea el punto de entrada para la bola
function EntryPointFactory:createEntryPoint(position, parent, theme)
	-- Base
	local base = Instance.new("Part")
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(5, 5, 5)
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

	-- Indicador visual mejorado
	local indicator = Instance.new("Part")
	indicator.Shape = Enum.PartType.Ball
	indicator.Size = Vector3.new(3, 3, 3)
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
	
	-- Añadir efectos de partículas
	local attachment = Instance.new("Attachment")
	attachment.Parent = indicator
	
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 50))
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 20
	particles.Speed = NumberRange.new(1, 2)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment

	-- Etiqueta "LANZA AQUÍ" mejorada
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.Adornee = indicator
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 0.5
	label.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Text = "¡LANZA AQUÍ!"
	label.Parent = billboard

	billboard.Parent = indicator
	
	-- Añadir animación al indicador
	spawn(function()
		while indicator and indicator.Parent do
			for i = 1, 20 do
				if not indicator or not indicator.Parent then break end
				
				-- Pulsar suavemente
				indicator.Size = Vector3.new(3 + math.sin(i/3) * 0.5, 3 + math.sin(i/3) * 0.5, 3 + math.sin(i/3) * 0.5)
				
				-- Girar lentamente
				billboard.StudsOffset = Vector3.new(math.sin(i/10) * 0.3, 2.5 + math.sin(i/5) * 0.2, 0)
				
				wait(0.05)
			end
		end
	end)
	
	-- Añadir vías de guía si está configurado
	if Config.BOARD.ADD_LAUNCH_GUIDES then
		self:createLaunchGuides(position, parent, theme)
	end
	
	return indicator
end

-- Crea guías visuales para ayudar a apuntar al lanzar
function EntryPointFactory:createLaunchGuides(position, parent, theme)
	-- Determinar colores según tema
	local guideColor
	local guideMaterial
	
	if theme == "FOREST" then
		guideColor = BrickColor.new("Bright orange")
		guideMaterial = Enum.Material.Neon
	elseif theme == "DUNGEON" then
		guideColor = BrickColor.new("Bright blue")
		guideMaterial = Enum.Material.Neon
	else
		guideColor = BrickColor.new("Bright yellow")
		guideMaterial = Enum.Material.Neon
	end
	
	-- Guía izquierda
	local leftGuideLine = Instance.new("Part")
	leftGuideLine.Size = Vector3.new(0.5, position.Y * 1.5, 0.1)
	leftGuideLine.Position = Vector3.new(position.X - 2, position.Y / 2, position.Z)
	leftGuideLine.Orientation = Vector3.new(0, 0, 0)
	leftGuideLine.BrickColor = guideColor
	leftGuideLine.Material = guideMaterial
	leftGuideLine.Transparency = 0.7
	leftGuideLine.Anchored = true
	leftGuideLine.CanCollide = false
	leftGuideLine.Parent = parent
	
	-- Guía derecha
	local rightGuideLine = Instance.new("Part")
	rightGuideLine.Size = Vector3.new(0.5, position.Y * 1.5, 0.1)
	rightGuideLine.Position = Vector3.new(position.X + 2, position.Y / 2, position.Z)
	rightGuideLine.Orientation = Vector3.new(0, 0, 0)
	rightGuideLine.BrickColor = guideColor
	rightGuideLine.Material = guideMaterial
	rightGuideLine.Transparency = 0.7
	rightGuideLine.Anchored = true
	rightGuideLine.CanCollide = false
	rightGuideLine.Parent = parent
	
	-- Marcadores de dirección
	local markerCount = 5
	local markerSpacing = position.Y / markerCount
	
	for i = 1, markerCount do
		local y = position.Y - (i * markerSpacing)
		
		-- Marcador izquierdo
		local leftMarker = Instance.new("Part")
		leftMarker.Size = Vector3.new(1, 0.3, 0.1)
		leftMarker.Position = Vector3.new(position.X - 2, y, position.Z)
		leftMarker.BrickColor = guideColor
		leftMarker.Material = guideMaterial
		leftMarker.Transparency = 0.5
		leftMarker.Anchored = true
		leftMarker.CanCollide = false
		leftMarker.Parent = parent
		
		-- Marcador derecho
		local rightMarker = Instance.new("Part")
		rightMarker.Size = Vector3.new(1, 0.3, 0.1)
		rightMarker.Position = Vector3.new(position.X + 2, y, position.Z)
		rightMarker.BrickColor = guideColor
		rightMarker.Material = guideMaterial
		rightMarker.Transparency = 0.5
		rightMarker.Anchored = true
		rightMarker.CanCollide = false
		rightMarker.Parent = parent
	end
	
	-- Animación sutil de pulso para las guías
	spawn(function()
		while parent and parent.Parent do
			for i = 1, 10 do
				if not leftGuideLine or not leftGuideLine.Parent then break end
				
				local alpha = math.sin(i / 3) * 0.2
				leftGuideLine.Transparency = 0.7 - alpha
				rightGuideLine.Transparency = 0.7 - alpha
				
				wait(0.1)
			end
		end
	end)
end

return EntryPointFactory