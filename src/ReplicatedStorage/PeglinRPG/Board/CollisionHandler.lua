-- CollisionHandler.lua: Maneja las colisiones y eventos físicos del tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local CollisionHandler = {}
CollisionHandler.__index = CollisionHandler

function CollisionHandler.new(boardManager)
	local self = setmetatable({}, CollisionHandler)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	return self
end

-- Registra un golpe en una clavija
function CollisionHandler:registerPegHit(pegPart)
	if not pegPart:GetAttribute("IsPeg") then
		return false
	end

	-- Incrementar contador de golpes
	local hitCount = pegPart:GetAttribute("HitCount") or 0
	hitCount = hitCount + 1
	pegPart:SetAttribute("HitCount", hitCount)

	-- Efectos visuales mejorados al golpear
	local originalColor = pegPart.Color
	local originalSize = pegPart.Size
	
	-- Efecto de "pulsación" al golpear
	spawn(function()
		-- Aumentar tamaño brevemente
		pegPart.Size = originalSize * Config.EFFECTS.PEG_HIT.EXPANSION
		pegPart.Color = Color3.fromRGB(255, 255, 255)
		
		-- Crear un efecto de onda expansiva
		local waveEffect = Instance.new("Part")
		waveEffect.Shape = Enum.PartType.Ball
		waveEffect.Size = Vector3.new(1, 1, 1)
		waveEffect.Position = pegPart.Position
		waveEffect.Anchored = true
		waveEffect.CanCollide = false
		waveEffect.Transparency = 0.7
		waveEffect.Material = Enum.Material.Neon
		waveEffect.Color = pegPart.Color
		waveEffect.Parent = pegPart.Parent
		
		-- Animación de la onda
		for i = 1, 10 do
			waveEffect.Size = Vector3.new(i * Config.EFFECTS.PEG_HIT.WAVE_SIZE, i * Config.EFFECTS.PEG_HIT.WAVE_SIZE, i * Config.EFFECTS.PEG_HIT.WAVE_SIZE)
			waveEffect.Transparency = 0.7 + (i * 0.03)
			wait(0.02)
		end
		waveEffect:Destroy()
		
		-- Restaurar tamaño y color original
		wait(Config.EFFECTS.PEG_HIT.DURATION)
		pegPart.Size = originalSize
		pegPart.Color = originalColor
	end)
	
	-- Efectos adicionales para tipos especiales de clavijas
	if pegPart:GetAttribute("IsBumper") then
		-- Efectos para bumpers
		spawn(function()
			local bumperLight = pegPart:FindFirstChildOfClass("PointLight")
			if bumperLight then
				local originalBrightness = bumperLight.Brightness
				bumperLight.Brightness = originalBrightness * 3
				wait(0.3)
				bumperLight.Brightness = originalBrightness
			end
			
			-- Sonido especial para bumpers
			local bumperSound = Instance.new("Sound")
			bumperSound.SoundId = "rbxassetid://5801647765" -- Reemplazar con un ID de sonido apropiado
			bumperSound.Volume = 0.8
			bumperSound.Parent = pegPart
			bumperSound:Play()
			
			-- Auto-limpieza del sonido
			game:GetService("Debris"):AddItem(bumperSound, 1)
		end)
	elseif pegPart:GetAttribute("IsCritical") then
		-- Efectos adicionales para clavijas críticas
		spawn(function()
			-- Crear relámpagos entre clavijas cercanas
			local nearbyPegs = {}
			
			-- Buscar clavijas cercanas
			for _, peg in ipairs(self.boardManager.pegs) do
				if peg ~= pegPart then
					local distance = (peg.Position - pegPart.Position).Magnitude
					if distance < Config.EFFECTS.CRITICAL_HIT.LIGHTNING_RANGE then
						table.insert(nearbyPegs, peg)
					end
				end
			end
			
			-- Limitar a máximo número configurado de clavijas cercanas
			if #nearbyPegs > Config.EFFECTS.CRITICAL_HIT.MAX_CONNECTIONS then
				-- Mantener solo las más cercanas
				table.sort(nearbyPegs, function(a, b)
                    return (a.Position - pegPart.Position).Magnitude < (b.Position - pegPart.Position).Magnitude
				end)
				
				while #nearbyPegs > Config.EFFECTS.CRITICAL_HIT.MAX_CONNECTIONS do
					table.remove(nearbyPegs)
				end
			end
			
			-- Crear efectos de relámpago
			for _, nearbyPeg in ipairs(nearbyPegs) do
				local bolt = Instance.new("Beam")
				local a0 = Instance.new("Attachment")
				local a1 = Instance.new("Attachment")
				
				a0.Parent = pegPart
				a1.Parent = nearbyPeg
				
				bolt.Attachment0 = a0
				bolt.Attachment1 = a1
				bolt.Width0 = 0.3
				bolt.Width1 = 0.1
				bolt.LightEmission = 1
				bolt.FaceCamera = true
				bolt.Texture = "rbxassetid://446111271" -- Textura de relámpago
				bolt.TextureLength = 0.5
				bolt.TextureSpeed = 3
				bolt.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
				bolt.Parent = pegPart.Parent
				
				-- Auto-destrucción
				spawn(function()
					wait(Config.EFFECTS.CRITICAL_HIT.DURATION)
					bolt:Destroy()
					a0:Destroy()
					a1:Destroy()
				end)
			end
		end)
	end
	
	-- Verificar si la clavija es parte de una zona de multiplicador
	if pegPart:GetAttribute("InMultiplierZone") then
		-- Efecto visual para zonas de multiplicador
		spawn(function()
			local multiplier = pegPart:GetAttribute("Multiplier") or 2
			
			-- Mostrar texto con multiplicador
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Size = UDim2.new(0, 70, 0, 40)
			billboardGui.StudsOffset = Vector3.new(0, 2, 0)
			billboardGui.Adornee = pegPart
			billboardGui.AlwaysOnTop = true
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 1
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextScaled = true
			textLabel.Text = "x" .. multiplier .. "!"
			textLabel.Parent = billboardGui
			
			billboardGui.Parent = pegPart
			
			-- Animación del texto
			for i = 1, 10 do
				textLabel.Position = UDim2.new(0, 0, 0, -i*0.5)
				textLabel.TextTransparency = i / 10
				wait(0.05)
			end
			
			billboardGui:Destroy()
		end)
	end

	-- Si la clavija ha sido golpeada suficientes veces, desactivarla
	local maxHitCount = pegPart:GetAttribute("MaxHits") or 2
	
	if hitCount >= maxHitCount then
		spawn(function()
			-- Efecto de desvanecimiento
			for i = 1, 10 do
				pegPart.Transparency = i * 0.1
				wait(0.03)
			end
			
			pegPart.CanCollide = false
			pegPart:SetAttribute("IsPeg", false)
			
			-- Efecto de explosión de partículas
			local explosion = Instance.new("ParticleEmitter")
			explosion.Color = ColorSequence.new(pegPart.Color)
			explosion.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			})
			explosion.Lifetime = NumberRange.new(0.5, 1)
			explosion.Speed = NumberRange.new(5, 10)
			explosion.SpreadAngle = Vector2.new(180, 180)
			explosion.Acceleration = Vector3.new(0, -10, 0)
			explosion.Rate = 0  -- Emitir de una vez
			explosion.Enabled = false
			explosion.Parent = pegPart
			
			-- Emitir partículas de golpe
			explosion:Emit(20)
			
			-- Reducir contadores
			if pegPart:GetAttribute("IsCritical") then
				self.boardManager.criticalPegCount = self.boardManager.criticalPegCount - 1
			end
			
			self.boardManager.pegCount = self.boardManager.pegCount - 1
		end)
	end

	return true
end

-- Maneja colisiones con elementos especiales del tablero
function CollisionHandler:handleSpecialCollisions(orbPart, contactPoint)
	-- Verificar si el orbe tocó un carril de aceleración
	self:checkSpeedLaneCollision(orbPart, contactPoint)
	
	-- Verificar si el orbe tocó un portal
	self:checkPortalCollision(orbPart, contactPoint)
	
	-- Verificar si el orbe está en una zona de multiplicador
	self:checkMultiplierZoneCollision(orbPart, contactPoint)
end

-- Verifica colisiones con carriles de aceleración
function CollisionHandler:checkSpeedLaneCollision(orbPart, contactPoint)
	local speedLanes = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(2, 2, 2),
			contactPoint + Vector3.new(2, 2, 2)
		),
		{self.boardManager.currentBoard}
	)
	
    for _, part in ipairs(speedLanes) do
        if part:GetAttribute("IsSpeedLane") then
            -- Aplicar impulso en la dirección del carril
            local dirX = part:GetAttribute("DirectionX")
            local dirY = part:GetAttribute("DirectionY")
            local dirZ = part:GetAttribute("DirectionZ")
            
            if dirX and dirY then
                local directionVector = Vector3.new(dirX, dirY, dirZ or 0)
                local speedBoost = part:GetAttribute("SpeedBoost") or 1.5
                
                -- Aplicar impulso
                orbPart.Velocity = directionVector * speedBoost * orbPart.Velocity.Magnitude
                
				
				-- Efecto visual
				spawn(function()
					local originalColor = part.Color
					part.Color = Color3.fromRGB(255, 255, 255)
					wait(0.1)
					part.Color = originalColor
				end)
				
				-- Mostrar efecto de velocidad
				self:createSpeedEffect(orbPart, directionVector)
				
				break
			end
		end
	end
end

-- Verifica colisiones con portales
function CollisionHandler:checkPortalCollision(orbPart, contactPoint)
	local portals = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(3, 3, 3),
			contactPoint + Vector3.new(3, 3, 3)
		),
		{self.boardManager.currentBoard}
	)
	
    for _, part in ipairs(portals) do
        if part:GetAttribute("IsPortal") and part:GetAttribute("PortalType") == "Entry" then
            -- Obtener posición de salida desde los atributos individuales
            local exitX = part:GetAttribute("ExitPositionX")
            local exitY = part:GetAttribute("ExitPositionY")
            local exitZ = part:GetAttribute("ExitPositionZ")
            
            if exitX and exitY then
                -- Teletransportar el orbe
                local currentVelocity = orbPart.Velocity
                
                orbPart.Position = Vector3.new(exitX, exitY, exitZ or 0)
				
				-- Mantener la velocidad (posiblemente girada)
				orbPart.Velocity = currentVelocity * 0.9  -- Ligera pérdida de velocidad
				
				-- Efectos visuales
				self:createPortalEffect(part, exitPos)
				
				break
			end
		end
	end
end

-- Verifica si el orbe está en una zona de multiplicador
function CollisionHandler:checkMultiplierZoneCollision(orbPart, contactPoint)
	local multiplierZones = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(5, 5, 5),
			contactPoint + Vector3.new(5, 5, 5)
		),
		{self.boardManager.currentBoard}
	)
	
	for _, part in ipairs(multiplierZones) do
		if part:GetAttribute("IsMultiplierZone") then
			-- Efecto visual sutil para indicar que está en la zona
			spawn(function()
				local originalTransparency = part.Transparency
				part.Transparency = originalTransparency - 0.2
				wait(0.2)
				part.Transparency = originalTransparency
			end)
			
			break
		end
	end
end

-- Crea un efecto visual para el impulso de velocidad
function CollisionHandler:createSpeedEffect(orbPart, direction)
	-- Crear estela de velocidad
	local trailPart = Instance.new("Part")
	trailPart.Size = Vector3.new(0.1, 0.1, 0.1)
	trailPart.Position = orbPart.Position
	trailPart.Transparency = 1
	trailPart.Anchored = true
	trailPart.CanCollide = false
	trailPart.Parent = workspace
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = trailPart
	
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Lifetime = NumberRange.new(0.3, 0.5)
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(5, 5)  -- Estrecho para mostrar dirección
	-- Configurar dirección de las partículas
	particles.Acceleration = Vector3.new(direction.X, direction.Y, 0) * 10
	particles.Rate = 30
	particles.Parent = attachment
	
	-- Auto-destrucción después de un tiempo
	spawn(function()
		wait(0.5)
		particles.Enabled = false
		wait(1)
		trailPart:Destroy()
	end)
end

-- Crea efectos visuales para la teletransportación de portal
function CollisionHandler:createPortalEffect(entryPortal, exitPosition)
	-- Efecto en portal de entrada
	local entryEffect = Instance.new("ParticleEmitter")
	entryEffect.Color = ColorSequence.new(Color3.fromRGB(0, 100, 255))
	entryEffect.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	entryEffect.Lifetime = NumberRange.new(0.5, 1)
	entryEffect.Speed = NumberRange.new(5, 10)
	entryEffect.SpreadAngle = Vector2.new(180, 180)
	entryEffect.Rate = 0
	entryEffect.Parent = entryPortal
	entryEffect:Emit(30)
	
	-- Efecto en portal de salida
	local exitPortals = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			Vector3.new(exitPosition.X, exitPosition.Y, exitPosition.Z) - Vector3.new(3, 3, 3),
			Vector3.new(exitPosition.X, exitPosition.Y, exitPosition.Z) + Vector3.new(3, 3, 3)
		),
		{self.boardManager.currentBoard}
	)
	
	for _, exitPortal in ipairs(exitPortals) do
		if exitPortal:GetAttribute("IsPortal") and exitPortal:GetAttribute("PortalType") == "Exit" then
			local exitEffect = Instance.new("ParticleEmitter")
			exitEffect.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
			exitEffect.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			})
			exitEffect.Lifetime = NumberRange.new(0.5, 1)
			exitEffect.Speed = NumberRange.new(5, 10)
			exitEffect.SpreadAngle = Vector2.new(180, 180)
			exitEffect.Rate = 0
			exitEffect.Parent = exitPortal
			exitEffect:Emit(30)
			
			-- Efecto de luz pulsante
			local light = exitPortal:FindFirstChildOfClass("PointLight")
			if light then
				local originalBrightness = light.Brightness or 1
				spawn(function()
					for i = 1, 5 do
						light.Brightness = originalBrightness * 3
						wait(0.1)
						light.Brightness = originalBrightness
						wait(0.1)
					end
				end)
			end
			
			break
		end
	end
	
	-- Sonido de teletransporte
	local teleportSound = Instance.new("Sound")
	teleportSound.SoundId = "rbxassetid://3835727243" -- Sonido de teletransporte
	teleportSound.Volume = 0.8
	teleportSound.Parent = entryPortal
	teleportSound:Play()
	
	-- Auto-limpieza del sonido
	game:GetService("Debris"):AddItem(teleportSound, 2)
end

return CollisionHandler