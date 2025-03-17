-- ThemeDecorator.lua: Añade decoraciones temáticas al tablero según su tema

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local ThemeDecorator = {}
ThemeDecorator.__index = ThemeDecorator

function ThemeDecorator.new(boardManager)
	local self = setmetatable({}, ThemeDecorator)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

-- Añade decoraciones temáticas al tablero según el tema
function ThemeDecorator:addThemeDecorations(board, theme, width, height)
	if theme == "FOREST" then
		self:addForestDecorations(board, width, height)
	elseif theme == "DUNGEON" then
		self:addDungeonDecorations(board, width, height)
	else
		self:addStandardDecorations(board, width, height)
	end
end

-- Añade decoraciones específicas para el tema de bosque
function ThemeDecorator:addForestDecorations(board, width, height)
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
	
	-- Añadir plantas y flores
	for i = 1, 10 do
		local x = math.random(-width/2 + 8, width/2 - 8)
		local y = math.random(-height/2 + 8, height/2 - 8)
		
		-- Verificar que no haya clavijas cercanas
		local validPos = true
		for _, peg in ipairs(self.boardManager.pegs) do
			local distance = math.sqrt((peg.Position.X - x)^2 + (peg.Position.Y - y)^2)
			if distance < 5 then
				validPos = false
				break
			end
		end
		
		if validPos then
			self:createFlower(Vector3.new(x, y, 0), board)
		end
	end
	
	-- Añadir efectos de niebla o partículas en el fondo
	self:createForestAmbience(board, width, height)
end

-- Crea un árbol decorativo
function ThemeDecorator:createTree(position, parent)
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
	
	-- Añadir efectos de partículas para las hojas
	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 4, 0)
	attachment.Parent = trunk
	
	local leafParticles = Instance.new("ParticleEmitter")
	leafParticles.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
	leafParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	leafParticles.Lifetime = NumberRange.new(1, 2)
	leafParticles.Rate = 2
	leafParticles.Speed = NumberRange.new(0.5, 1)
	leafParticles.SpreadAngle = Vector2.new(180, 180)
	leafParticles.Parent = attachment
end

-- Crea una flor o planta decorativa
function ThemeDecorator:createFlower(position, parent)
	-- Tallo
	local stem = Instance.new("Part")
	stem.Size = Vector3.new(0.2, 1.5, 0.2)
	stem.Position = position
	stem.BrickColor = BrickColor.new("Bright green")
	stem.Material = Enum.Material.Grass
	stem.Anchored = true
	stem.CanCollide = false
	stem.Parent = parent
	
	-- Flor
	local flower = Instance.new("Part")
	flower.Shape = Enum.PartType.Ball
	flower.Size = Vector3.new(0.8, 0.8, 0.8)
	flower.Position = Vector3.new(position.X, position.Y + 1, position.Z)
	
	-- Color aleatorio para las flores
	local flowerColors = {
		BrickColor.new("Bright red"),
		BrickColor.new("Bright yellow"),
		BrickColor.new("Bright blue"),
		BrickColor.new("Bright violet"),
		BrickColor.new("Hot pink")
	}
	
	flower.BrickColor = flowerColors[math.random(1, #flowerColors)]
	flower.Material = Enum.Material.Neon
	flower.Transparency = 0.2
	flower.Anchored = true
	flower.CanCollide = false
	flower.Parent = parent
	
	-- Brillo suave
	local light = Instance.new("PointLight")
	light.Brightness = 0.2
	light.Color = flower.Color
	light.Range = 2
	light.Parent = flower
end

-- Añade efectos ambientales al tablero de bosque
function ThemeDecorator:createForestAmbience(board, width, height)
	-- Crear partículas de niebla/polvo
	for i = 1, 5 do
		local x = math.random(-width/2 + 10, width/2 - 10)
		local y = math.random(-height/2 + 10, height/2 - 10)
		
		local emitter = Instance.new("Part")
		emitter.Size = Vector3.new(0.1, 0.1, 0.1)
		emitter.Position = Vector3.new(x, y, -1)
		emitter.Transparency = 1
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.Parent = board
		
		local attachment = Instance.new("Attachment")
		attachment.Parent = emitter
		
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(200, 255, 200))
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(0.5, 0.9),
			NumberSequenceKeypoint.new(1, 1)
		})
		particles.Lifetime = NumberRange.new(3, 5)
		particles.Rate = 1
		particles.Speed = NumberRange.new(0.2, 0.5)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = attachment
	end
end

-- Añade decoraciones específicas para el tema de mazmorra
function ThemeDecorator:addDungeonDecorations(board, width, height)
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
	
	-- Añadir huesos y calaveras
	for i = 1, 8 do
		local x = math.random(-width/2 + 5, width/2 - 5)
		local y = math.random(-height/2 + 5, -height/2 + 15)
		
		-- Verificar que no haya clavijas cercanas
		local validPos = true
		for _, peg in ipairs(self.boardManager.pegs) do
			local distance = math.sqrt((peg.Position.X - x)^2 + (peg.Position.Y - y)^2)
			if distance < 5 then
				validPos = false
				break
			end
		end
		
		if validPos then
			if math.random(1, 2) == 1 then
				self:createBones(Vector3.new(x, y, 0), board)
			else
				self:createSkull(Vector3.new(x, y, 0), board)
			end
		end
	end
	
	-- Niebla y partículas de mazmorra
	self:createDungeonAmbience(board, width, height)
end

-- Crea una antorcha decorativa
function ThemeDecorator:createTorch(position, parent)
	-- Soporte
	local handle = Instance.new("Part")
-- Continuación de ThemeDecorator.lua
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
function ThemeDecorator:createChain(position, length, parent)
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

-- Crea decoración de huesos
function ThemeDecorator:createBones(position, parent)
-- Crear huesos esparcidos
local boneCount = math.random(2, 4)

for i = 1, boneCount do
    local bone = Instance.new("Part")
    bone.Size = Vector3.new(0.3, 2, 0.3)
    
    -- Posición ligeramente aleatoria alrededor del punto principal
    local offsetX = math.random(-10, 10) / 10
    local offsetY = math.random(-10, 10) / 10
    bone.Position = Vector3.new(position.X + offsetX, position.Y + offsetY, position.Z)
    
    -- Rotación aleatoria
    bone.Orientation = Vector3.new(0, 0, math.random(0, 180))
    
    bone.BrickColor = BrickColor.new("Institutional white")
    bone.Material = Enum.Material.Marble
    bone.Anchored = true
    bone.CanCollide = false
    bone.Parent = parent
end
end

-- Crea una calavera decorativa
function ThemeDecorator:createSkull(position, parent)
-- Base de la calavera
local skull = Instance.new("Part")
skull.Shape = Enum.PartType.Ball
skull.Size = Vector3.new(1.5, 1.5, 1.5)
skull.Position = position
skull.BrickColor = BrickColor.new("Institutional white")
skull.Material = Enum.Material.Marble
skull.Anchored = true
skull.CanCollide = false
skull.Parent = parent

-- Ojos
for i = -1, 1, 2 do
    local eye = Instance.new("Part")
    eye.Shape = Enum.PartType.Ball
    eye.Size = Vector3.new(0.4, 0.4, 0.2)
    eye.Position = Vector3.new(position.X + (i * 0.3), position.Y + 0.2, position.Z + 0.6)
    eye.BrickColor = BrickColor.new("Really black")
    eye.Material = Enum.Material.Slate
    eye.Anchored = true
    eye.CanCollide = false
    eye.Parent = parent
end

-- Mandíbula
local jaw = Instance.new("Part")
jaw.Size = Vector3.new(1, 0.3, 0.7)
jaw.Position = Vector3.new(position.X, position.Y - 0.4, position.Z + 0.3)
jaw.BrickColor = BrickColor.new("Institutional white")
jaw.Material = Enum.Material.Marble
jaw.Anchored = true
jaw.CanCollide = false
jaw.Parent = parent
end

-- Crea efectos de ambiente para mazmorra
function ThemeDecorator:createDungeonAmbience(board, width, height)
-- Niebla baja
for i = 1, 8 do
    local x = math.random(-width/2 + 10, width/2 - 10)
    local y = math.random(-height/2 + 5, height/2 - 5)
    
    local fog = Instance.new("Part")
    fog.Size = Vector3.new(0.1, 0.1, 0.1)
    fog.Position = Vector3.new(x, y, -1)
    fog.Transparency = 1
    fog.Anchored = true
    fog.CanCollide = false
    fog.Parent = board
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = fog
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(50, 50, 80))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 3),
        NumberSequenceKeypoint.new(0.5, 5),
        NumberSequenceKeypoint.new(1, 3)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.9),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Lifetime = NumberRange.new(4, 6)
    particles.Rate = 0.5
    particles.Speed = NumberRange.new(0.1, 0.3)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Parent = attachment
end

-- Polvo y partículas flotantes
for i = 1, 10 do
    local x = math.random(-width/2 + 5, width/2 - 5)
    local y = math.random(-height/2 + 5, height/2 - 5)
    
    local dust = Instance.new("Part")
    dust.Size = Vector3.new(0.1, 0.1, 0.1)
    dust.Position = Vector3.new(x, y, 0)
    dust.Transparency = 1
    dust.Anchored = true
    dust.CanCollide = false
    dust.Parent = board
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = dust
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Lifetime = NumberRange.new(2, 4)
    particles.Rate = 2
    particles.Speed = NumberRange.new(0.3, 0.8)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Parent = attachment
end
end

-- Añade decoraciones para el tema estándar
function ThemeDecorator:addStandardDecorations(board, width, height)
-- Añadir estrellas/brillos en las esquinas
for i = 1, 4 do
    local x, y
    
    -- Posiciones en las cuatro esquinas
    if i == 1 then
        x, y = width/2 - 8, height/2 - 8
    elseif i == 2 then
        x, y = -width/2 + 8, height/2 - 8
    elseif i == 3 then
        x, y = width/2 - 8, -height/2 + 8
    else
        x, y = -width/2 + 8, -height/2 + 8
    end
    
    self:createStar(Vector3.new(x, y, 0), board)
end

-- Añadir algunas estrellas aleatorias
for i = 1, 10 do
    local x = math.random(-width/2 + 10, width/2 - 10)
    local y = math.random(-height/2 + 10, height/2 - 10)
    
    -- Verificar que no haya clavijas cercanas
    local validPos = true
    for _, peg in ipairs(self.boardManager.pegs) do
        local distance = math.sqrt((peg.Position.X - x)^2 + (peg.Position.Y - y)^2)
        if distance < 5 then
            validPos = false
            break
        end
    end
    
    if validPos then
        self:createStar(Vector3.new(x, y, 0), board, 0.5) -- Tamaño más pequeño
    end
end

-- Añadir partículas de ambiente
self:createStandardAmbience(board, width, height)
end

-- Crea una decoración de estrella
function ThemeDecorator:createStar(position, parent, scale)
scale = scale or 1

-- Centro de la estrella
local center = Instance.new("Part")
center.Shape = Enum.PartType.Ball
center.Size = Vector3.new(0.8 * scale, 0.8 * scale, 0.8 * scale)
center.Position = position
center.BrickColor = BrickColor.new("Institutional white")
center.Material = Enum.Material.Neon
center.Transparency = 0.2
center.Anchored = true
center.CanCollide = false
center.Parent = parent

-- Brillo
local light = Instance.new("PointLight")
light.Brightness = 0.5
light.Color = Color3.fromRGB(255, 255, 255)
light.Range = 5 * scale
light.Parent = center

-- Rayos de la estrella
for i = 1, 4 do
    local ray = Instance.new("Part")
    ray.Size = Vector3.new(2 * scale, 0.2 * scale, 0.2 * scale)
    ray.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(45 * i))
    ray.BrickColor = BrickColor.new("Institutional white")
    ray.Material = Enum.Material.Neon
    ray.Transparency = 0.5
    ray.Anchored = true
    ray.CanCollide = false
    ray.Parent = parent
end

-- Animación de brillo (pulsación)
spawn(function()
    while center and center.Parent do
        for i = 1, 10 do
            if not center or not center.Parent then break end
            
            local pulse = math.sin(i / 3) * 0.2 + 0.8
            center.Transparency = 0.1 + ((1 - pulse) * 0.4)
            
            if light then
                light.Brightness = 0.5 * pulse
            end
            
            wait(0.1)
        end
        wait(math.random(1, 3)) -- Pausa aleatoria entre pulsaciones
    end
end)
end

-- Crea efectos de ambiente para el tema estándar
function ThemeDecorator:createStandardAmbience(board, width, height)
-- Partículas flotantes brillantes
for i = 1, 3 do
    local x = math.random(-width/3, width/3)
    local y = math.random(-height/3, height/3)
    
    local emitter = Instance.new("Part")
    emitter.Size = Vector3.new(0.1, 0.1, 0.1)
    emitter.Position = Vector3.new(x, y, -1)
    emitter.Transparency = 1
    emitter.Anchored = true
    emitter.CanCollide = false
    emitter.Parent = board
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = emitter
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 150, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 255))
    })
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1, 0)
    })
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.5, 0.8),
        NumberSequenceKeypoint.new(1, 1)
    })
    particles.Lifetime = NumberRange.new(3, 5)
    particles.Rate = 3
    particles.Speed = NumberRange.new(0.5, 1)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.Parent = attachment
end

-- Efecto de luz ambiental sutil
local ambientLight = Instance.new("Part")
ambientLight.Size = Vector3.new(0.1, 0.1, 0.1)
ambientLight.Position = Vector3.new(0, 0, -5)
ambientLight.Transparency = 1
ambientLight.Anchored = true
ambientLight.CanCollide = false
ambientLight.Parent = board

local light = Instance.new("PointLight")
light.Brightness = 0.3
light.Color = Color3.fromRGB(100, 100, 150)
light.Range = math.max(width, height) * 1.5
light.Parent = ambientLight
end

return ThemeDecorator