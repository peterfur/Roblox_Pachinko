-- PegFactory.lua: Responsable de crear y gestionar las clavijas del tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local PegFactory = {}
PegFactory.__index = PegFactory

function PegFactory.new(boardManager)
	local self = setmetatable({}, PegFactory)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

-- Genera las clavijas en el tablero
function PegFactory:generatePegs(board, width, height, pegCount, pegColors, theme)
	-- Resetear contadores en el BoardManager
	self.boardManager.pegCount = 0
	self.boardManager.criticalPegCount = 0

	-- Calcular distribución de clavijas
	local minDistance = 4 -- Distancia mínima entre clavijas
	local pegPositions = {}

	-- Patrones según el tema
	local patternFunc

	if theme == "FOREST" then
		patternFunc = function(x, y)
			-- Patrón de bosque mejorado: más denso en el centro y patrones de arco
			local centerDist = math.sqrt((x)^2 + (y)^2)
			local bottomBias = (y + height/4) / height
            
            -- Patrón de arco en la parte superior
            local arcPattern = false
            if y > 0 then
                local arcY = height/4
                local arcRadius = width/3
                local distToArc = math.abs(math.sqrt((x)^2 + (y - arcY)^2) - arcRadius)
                arcPattern = distToArc < 3
            end
            
			return arcPattern or math.random() < (0.7 - centerDist/60 + bottomBias*0.4)
		end
	elseif theme == "DUNGEON" then
		patternFunc = function(x, y)
			-- Patrón de mazmorra mejorado: rejilla más estructurada y patrones diagonales
			local gridSize = 8
			local onGrid = (math.abs(x) % gridSize < 2) or (math.abs(y) % gridSize < 2)
            
            -- Patrones diagonales
            local diagonalPattern = false
            if (x + y) % 15 < 2 or (x - y) % 15 < 2 then
                diagonalPattern = true
            end
            
			return (onGrid or diagonalPattern) and math.random() < 0.75
		end
	else
		patternFunc = function(x, y)
			-- Patrón estándar mejorado: distribución aleatoria con mayor densidad en zonas clave
            -- Crear algunas secciones más densas
            local denseZone = false
            local zones = {
                {x = width/4, y = height/4, radius = 10},
                {x = -width/4, y = -height/4, radius = 10},
                {x = 0, y = 0, radius = 15}
            }
            
            for _, zone in ipairs(zones) do
                local dist = math.sqrt((x - zone.x)^2 + (y - zone.y)^2)
                if dist < zone.radius then
                    denseZone = true
                    break
                end
            end
            
			return denseZone or math.random() < 0.6
		end
	end

	-- Intentar colocar el número deseado de clavijas
	for i = 1, pegCount * 2 do -- Intentamos más veces para asegurar buena cobertura
		if self.boardManager.pegCount >= pegCount then break end

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

			-- 25% de probabilidad de ser clavija crítica (aumentado de 20%)
			local isCritical = math.random(1, 100) <= 25
			if isCritical then
				self.boardManager.criticalPegCount = self.boardManager.criticalPegCount + 1
			end

			-- Decidir si crear una clavija esférica o cilíndrica
			local isPegBall = math.random(1, 100) <= Config.PEG_TYPES.BALL.SPAWN_CHANCE

			-- Crear la clavija
			local peg
			if isPegBall then
				peg = self:createBallPeg(Vector3.new(x, y, 0), isCritical, pegColors, theme)
			else
				peg = self:createStandardPeg(Vector3.new(x, y, 0), isCritical, pegColors, theme)
			end
			
			peg.Parent = board

			-- Añadir a la lista de clavijas
			table.insert(self.boardManager.pegs, peg)
			self.boardManager.pegCount = self.boardManager.pegCount + 1
		end
	end

	return self.boardManager.pegCount
end

-- Crea una clavija estándar (cilíndrica)
function PegFactory:createStandardPeg(position, isCritical, pegColors, theme)
	local peg = Instance.new("Part")
	peg.Shape = Enum.PartType.Cylinder
	peg.Size = Config.PEG_TYPES.STANDARD.SIZE
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
	peg:SetAttribute("PegType", "STANDARD")
    peg:SetAttribute("MaxHits", Config.PEG_TYPES.STANDARD.MAX_HITS)

	-- Efecto visual para clavijas críticas
	if isCritical then
		local light = Instance.new("PointLight")
		light.Brightness = 1
		light.Color = Color3.fromRGB(255, 100, 100)
		light.Range = 4
		light.Parent = peg
        
        -- Partículas para clavijas críticas
        local attachment = Instance.new("Attachment")
        attachment.Parent = peg
        
        local particles = Instance.new("ParticleEmitter")
        particles.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
        })
        particles.Lifetime = NumberRange.new(0.5, 1)
        particles.Rate = 10
        particles.Speed = NumberRange.new(0.5, 1)
        particles.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 0)
        })
        particles.Parent = attachment
	end
    
    -- Añadir pequeña rotación aleatoria para más variedad visual
    local randomRotation = math.random(-10, 10)
    peg.Orientation = Vector3.new(randomRotation, 0, 90)

	return peg
end

-- Crea una clavija esférica
function PegFactory:createBallPeg(position, isCritical, pegColors, theme)
	local peg = Instance.new("Part")
	peg.Shape = Enum.PartType.Ball
	peg.Size = Config.PEG_TYPES.BALL.SIZE
	peg.Position = position

	-- Apariencia basada en si es crítica
	if isCritical then
		peg.BrickColor = BrickColor.new("Really red")
		peg.Material = Enum.Material.Neon
	else
		-- Seleccionar color aleatorio del tema pero ligeramente más claro para diferenciarse
		local baseColor = pegColors[math.random(1, #pegColors)]
		peg.BrickColor = baseColor
		
		-- Material según tema, pero más brillante
		if theme == "FOREST" then
			peg.Material = Enum.Material.Plastic
		elseif theme == "DUNGEON" then
			peg.Material = Enum.Material.SmoothPlastic
		else
			peg.Material = Enum.Material.Glass
		end
	end

	-- Propiedades físicas
	peg.Anchored = true
	peg.CanCollide = true

	-- Propiedades para interacción con orbes
	peg:SetAttribute("IsPeg", true)
	peg:SetAttribute("IsCritical", isCritical)
	peg:SetAttribute("HitCount", 0)
	peg:SetAttribute("PegType", "BALL")
	peg:SetAttribute("IsBall", true)
    peg:SetAttribute("BounceBonus", Config.PEG_TYPES.BALL.BOUNCE_BONUS)
    peg:SetAttribute("MaxHits", Config.PEG_TYPES.BALL.MAX_HITS)

	-- Efecto visual para clavijas esféricas (brillo suave)
	local light = Instance.new("PointLight")
	if isCritical then
		light.Brightness = 1
		light.Color = Color3.fromRGB(255, 100, 100)
	else
		light.Brightness = 0.5
		light.Color = peg.Color
	end
	light.Range = 5
	light.Parent = peg
	
	-- Si es crítica, añadir partículas
	if isCritical then
		local attachment = Instance.new("Attachment")
		attachment.Parent = peg
		
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
		})
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Rate = 10
		particles.Speed = NumberRange.new(0.5, 1)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0)
		})
		particles.Parent = attachment
	end

	return peg
end

return PegFactory