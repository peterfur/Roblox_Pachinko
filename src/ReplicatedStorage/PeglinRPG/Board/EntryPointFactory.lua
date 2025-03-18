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

function EntryPointFactory:createEntryPoints(parent, width, height, theme)
    local entryPoints = {}
    
    -- Posiciones mejoradas para los tres tubos - más centrados y no tan cerca de los bordes
    local positions = {
        Vector3.new(-width/6, height/2 - 6, 0),  -- Izquierda
        Vector3.new(0, height/2 - 6, 0),         -- Centro (un poco más abajo)
        Vector3.new(width/6, height/2 - 6, 0)    -- Derecha
    }
    
    for i, position in ipairs(positions) do
        -- Base del tubo
        local base = Instance.new("Part")
        base.Shape = Enum.PartType.Cylinder
        base.Size = Vector3.new(5, 5, 5)
        -- Orientar correctamente el tubo para que apunte hacia abajo
        base.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
        
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
        indicator.Size = Vector3.new(3, 3, 3)
        indicator.Position = Vector3.new(position.X, position.Y, position.Z + 1)
        indicator.BrickColor = BrickColor.new("Lime green")
        indicator.Material = Enum.Material.Neon
        indicator.Transparency = 0.5
        indicator.Anchored = true
        indicator.CanCollide = false
        
        -- Guardar posición y orientación para el lanzamiento
        indicator:SetAttribute("LaunchPosition", position)
        indicator:SetAttribute("EntryPointIndex", i)
        
        indicator.Parent = parent
        table.insert(entryPoints, indicator)
        
        -- Añadir luz
        local light = Instance.new("PointLight")
        light.Brightness = 2
        light.Color = Color3.fromRGB(100, 255, 100)
        light.Range = 5
        light.Parent = indicator
    end
    
    return entryPoints
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