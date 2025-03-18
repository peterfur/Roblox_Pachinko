-- CollisionHandler.lua: Maneja las colisiones y eventos físicos del tablero

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local CollisionHandler = {}
CollisionHandler.__index = CollisionHandler

function CollisionHandler.new(boardManager)
	local self = setmetatable({}, CollisionHandler)
	
	-- Referencia al BoardManager principal
	self.boardManager = boardManager
	
	-- ARREGLO: Añadir contador de colisiones para mejor gestión
	self.collisionCounters = {}
	self.lastHitTime = {}
	
	return self
end

-- Registra un golpe en una clavija
function CollisionHandler:registerPegHit(pegPart)
	if not pegPart:GetAttribute("IsPeg") then
		return false
	end

	-- ARREGLO: Implementar sistema anti-rebote para evitar golpes múltiples rápidos
	local partId = pegPart:GetFullName()
	local currentTime = tick()
	
	if self.lastHitTime[partId] and (currentTime - self.lastHitTime[partId]) < 0.2 then
		return false -- Ignorar golpes muy rápidos en la misma clavija
	end
	
	self.lastHitTime[partId] = currentTime

	-- Incrementar contador de golpes
	local hitCount = pegPart:GetAttribute("HitCount") or 0
	hitCount = hitCount + 1
	pegPart:SetAttribute("HitCount", hitCount)

	-- ARREGLO: Reproducir sonido mejorado de golpe
	local hitSound = pegPart:FindFirstChild("HitSound")
	if not hitSound then
		hitSound = Instance.new("Sound")
		hitSound.Name = "HitSound"
		hitSound.SoundId = "rbxassetid://6732690176" -- Sonido más satisfactorio
		hitSound.Volume = 0.7 
		hitSound.PlaybackSpeed = math.random(90, 110) / 100 -- Ligera variación
		hitSound.Parent = pegPart
	end
	hitSound:Play()

	-- Efectos visuales mejorados al golpear
	local originalColor = pegPart.Color
	local originalSize = pegPart.Size
	
	-- ARREGLO: Efecto de "pulsación" más notable al golpear
	spawn(function()
		-- Aumentar tamaño brevemente
		pegPart.Size = originalSize * 1.3 -- Mayor expansión
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
		
		-- ARREGLO: Animación de la onda más fluida y visible
		for i = 1, 12 do
			waveEffect.Size = Vector3.new(i * 0.5, i * 0.5, i * 0.5)
			waveEffect.Transparency = 0.7 + (i * 0.025)
			wait(0.015) -- Más rápido para mayor fluidez
		end
		waveEffect:Destroy()
		
		-- ARREGLO: Restaurar tamaño de manera más dinámica
		for i = 30, 0, -3 do
			local scaleFactor = 1 + (i/100)
			pegPart.Size = originalSize * scaleFactor
			wait(0.01)
		end
		
		pegPart.Size = originalSize
		pegPart.Color = originalColor
	end)
	
	-- Efectos adicionales para tipos especiales de clavijas
	if pegPart:GetAttribute("IsBumper") then
		-- ARREGLO: Efectos mejorados para bumpers
		spawn(function()
			local bumperLight = pegPart:FindFirstChildOfClass("PointLight")
			if bumperLight then
				local originalBrightness = bumperLight.Brightness
				bumperLight.Brightness = originalBrightness * 5 -- Brillo más intenso
				
				-- ARREGLO: Animación de pulso para mayor feedback
				for i = 10, 0, -1 do
					bumperLight.Brightness = originalBrightness * (1 + i/2)
					wait(0.02)
				end
				
				bumperLight.Brightness = originalBrightness
			end
			
			-- ARREGLO: Sonido especial más satisfactorio para bumpers
			local bumperSound = Instance.new("Sound")
			bumperSound.SoundId = "rbxassetid://5869422451" -- Sonido más impactante
			bumperSound.Volume = 1.2
			bumperSound.PlaybackSpeed = math.random(90, 110) / 100 -- Ligera variación
			bumperSound.Parent = pegPart
			bumperSound:Play()
			
			-- Auto-limpieza del sonido
			game:GetService("Debris"):AddItem(bumperSound, 1)
		end)
	elseif pegPart:GetAttribute("IsCritical") then
		-- ARREGLO: Efectos adicionales mejorados para clavijas críticas
		spawn(function()
			-- ARREGLO: Crear un destello más visible
			local flash = Instance.new("Part")
			flash.Shape = Enum.PartType.Ball
			flash.Size = Vector3.new(3, 3, 3)
			flash.Position = pegPart.Position
			flash.Anchored = true
			flash.CanCollide = false
			flash.Transparency = 0.5
			flash.Material = Enum.Material.Neon
			flash.Color = Color3.fromRGB(255, 50, 50)
			flash.Parent = pegPart.Parent
			
			-- Animación del destello
			for i = 10, 0, -1 do
				flash.Transparency = 0.5 + ((10-i)/20)
				flash.Size = Vector3.new(3 + i/3, 3 + i/3, 3 + i/3)
				wait(0.02)
			end
			flash:Destroy()
			
			-- ARREGLO: Crear relámpagos entre clavijas cercanas (mejorado)
			local nearbyPegs = {}
			
			-- Buscar clavijas cercanas
			for _, peg in ipairs(self.boardManager.pegs) do
				if peg ~= pegPart then
					local distance = (peg.Position - pegPart.Position).Magnitude
					if distance < 10 then -- Radio más amplio
						table.insert(nearbyPegs, peg)
					end
				end
			end
			
			-- Limitar a máximo número configurado de clavijas cercanas
			if #nearbyPegs > 3 then
				-- Mantener solo las más cercanas
				table.sort(nearbyPegs, function(a, b)
                    return (a.Position - pegPart.Position).Magnitude < (b.Position - pegPart.Position).Magnitude
				end)
				
				while #nearbyPegs > 3 do
					table.remove(nearbyPegs)
				end
			end
			
			-- ARREGLO: Sonido especial para críticos
			local critSound = Instance.new("Sound")
			critSound.SoundId = "rbxassetid://2690846439" -- Sonido crítico satisfactorio 
			critSound.Volume = 0.9
			critSound.Parent = pegPart
			critSound:Play()
			
			-- ARREGLO: Crear efectos de relámpago más atractivos
			for _, nearbyPeg in ipairs(nearbyPegs) do
				local bolt = Instance.new("Beam")
				local a0 = Instance.new("Attachment")
				local a1 = Instance.new("Attachment")
				
				a0.Parent = pegPart
				a1.Parent = nearbyPeg
				
				bolt.Attachment0 = a0
				bolt.Attachment1 = a1
				bolt.Width0 = 0.4
				bolt.Width1 = 0.2
				bolt.LightEmission = 1
				bolt.FaceCamera = true
				bolt.Texture = "rbxassetid://446111271" -- Textura de relámpago
				bolt.TextureLength = 0.5
				bolt.TextureSpeed = 5 -- Más rápido
				bolt.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 150)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))
				})
				bolt.Parent = pegPart.Parent
				
				-- Animación del rayo para hacerlo más dinámico
				spawn(function()
					for i = 1, 6 do
						bolt.Width0 = 0.4 * (1 + math.sin(i/2))
						bolt.Width1 = 0.2 * (1 + math.sin(i/2))
						wait(0.05)
					end
					bolt:Destroy()
					a0:Destroy()
					a1:Destroy()
				end)
			end
		end)
	end
	
	-- Verificar si la clavija es parte de una zona de multiplicador
	if pegPart:GetAttribute("InMultiplierZone") then
		-- ARREGLO: Efecto visual mejorado para zonas de multiplicador
		spawn(function()
			local multiplier = pegPart:GetAttribute("Multiplier") or 2
			
			-- ARREGLO: Mostrar texto con multiplicador más vistoso
			local billboardGui = Instance.new("BillboardGui")
			billboardGui.Size = UDim2.new(0, 100, 0, 60)
			billboardGui.StudsOffset = Vector3.new(0, 2, 0)
			billboardGui.Adornee = pegPart
			billboardGui.AlwaysOnTop = true
			
			local textLabel = Instance.new("TextLabel")
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.BackgroundTransparency = 0.3
			textLabel.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
			textLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			textLabel.Font = Enum.Font.GothamBold
			textLabel.TextScaled = true
			textLabel.Text = "x" .. multiplier .. "!"
			textLabel.TextStrokeTransparency = 0.5
			textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			textLabel.Parent = billboardGui
			
			billboardGui.Parent = pegPart
			
			-- ARREGLO: Animación del texto más dinámica
			for i = 1, 20 do
				textLabel.Position = UDim2.new(0, 0, 0, -i*0.7)
				textLabel.TextTransparency = i / 20
				textLabel.BackgroundTransparency = 0.3 + (i / 15)
				textLabel.Size = UDim2.new(1 + (i/20), 0, 1 + (i/20), 0)
				textLabel.Rotation = i * 3
				wait(0.04)
			end
			
			billboardGui:Destroy()
		end)
	end

	-- ARREGLO: Si la clavija ha sido golpeada suficientes veces, desactivarla con efectos mejorados
	local maxHitCount = pegPart:GetAttribute("MaxHits") or 2
	
	if hitCount >= maxHitCount then
		spawn(function()
			-- ARREGLO: Sonido de desactivación
			local breakSound = Instance.new("Sound")
			breakSound.SoundId = "rbxassetid://4809574295" -- Sonido de ruptura
			breakSound.Volume = 0.8
			breakSound.Parent = pegPart
			breakSound:Play()
			
			-- ARREGLO: Efecto de desvanecimiento más dramático
			for i = 1, 10 do
				pegPart.Transparency = i * 0.1
				pegPart.Size = originalSize * (1 - (i * 0.08))
				wait(0.03)
			end
			
			pegPart.CanCollide = false
			pegPart:SetAttribute("IsPeg", false)
			
			-- ARREGLO: Efecto de explosión de partículas mejorado
			local explosion = Instance.new("ParticleEmitter")
			explosion.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, pegPart.Color),
				ColorSequenceKeypoint.new(0.5, pegPart.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.5)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
			})
			explosion.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.8),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			})
			explosion.Lifetime = NumberRange.new(0.8, 1.5)
			explosion.Speed = NumberRange.new(8, 15) -- Partículas más rápidas
			explosion.SpreadAngle = Vector2.new(180, 180)
			explosion.Acceleration = Vector3.new(0, -15, 0)
			explosion.Rate = 0  -- Emitir de una vez
			explosion.Enabled = false
			explosion.Parent = pegPart
			
			-- Emitir más partículas para efecto más satisfactorio
			explosion:Emit(30)
			
			-- Reducir contadores
			if pegPart:GetAttribute("IsCritical") then
				self.boardManager.criticalPegCount = self.boardManager.criticalPegCount - 1
			end
			
			self.boardManager.pegCount = self.boardManager.pegCount - 1

            -- Esperar un poco antes de destruir la partícula
            wait(1.5)
            explosion.Enabled = false
            wait(0.5)
            if pegPart and pegPart.Parent then
                pegPart.Transparency = 1
            end
		end)
	end

	return true
end

-- ARREGLO: Maneja colisiones con elementos especiales del tablero
function CollisionHandler:handleSpecialCollisions(orbPart, contactPoint)
	-- Verificar si el orbe está atascado
	self:checkIfStuck(orbPart)
	
	-- Verificar si el orbe tocó un borde o guía para mejorar feedback
	self:checkBorderCollision(orbPart, contactPoint)
	
	-- Verificar si el orbe tocó un carril de aceleración
	self:checkSpeedLaneCollision(orbPart, contactPoint)
	
	-- Verificar si el orbe tocó un portal
	self:checkPortalCollision(orbPart, contactPoint)
	
	-- Verificar si el orbe está en una zona de multiplicador
	self:checkMultiplierZoneCollision(orbPart, contactPoint)
end

-- ARREGLO: Nueva función para detectar y resolver atascamientos
function CollisionHandler:checkIfStuck(orbPart)
	-- Obtener ID único para el orbe
	local orbId = orbPart:GetFullName()
	
	-- Inicializar contador si no existe
	if not self.collisionCounters[orbId] then
		self.collisionCounters[orbId] = {
			lastPosition = orbPart.Position,
			stuckTime = 0,
			lastCheck = tick(),
			stuckCount = 0
		}
		return
	end
	
	local counter = self.collisionCounters[orbId]
	local currentTime = tick()
	
	-- Solo verificar periódicamente
	if currentTime - counter.lastCheck < 0.5 then
		return
	end
	
	counter.lastCheck = currentTime
	
	-- Verificar si el orbe se ha movido significativamente
	local distance = (orbPart.Position - counter.lastPosition).Magnitude
	local velocity = orbPart.Velocity.Magnitude
	
	-- Si el orbe está moviéndose muy poco y tiene velocidad baja
	if distance < 1 and velocity < 3 then
		counter.stuckTime = counter.stuckTime + 0.5
		counter.stuckCount = counter.stuckCount + 1
		
		-- Si lleva más de 2 segundos atascado, intentar liberarlo
		if counter.stuckTime >= 2 then
			print("Orbe atascado detectado, intentando liberarlo...")
			
			-- Aplicar una fuerza aleatoria para desatascar
			local randomDirection = Vector3.new(
				math.random(-10, 10),
				math.random(-10, 10),
				0
			).Unit
			
			orbPart:ApplyImpulse(randomDirection * 20 * orbPart:GetMass())
			
			-- Crear efecto visual de liberación
			spawn(function()
				local effect = Instance.new("Part")
				effect.Shape = Enum.PartType.Ball
				effect.Size = Vector3.new(1, 1, 1)
				effect.Position = orbPart.Position
				effect.Anchored = true
				effect.CanCollide = false
				effect.Transparency = 0.5
				effect.Material = Enum.Material.Neon
				effect.Color = orbPart.Color
				effect.Parent = workspace
				
				for i = 1, 8 do
					effect.Size = Vector3.new(i * 0.3, i * 0.3, i * 0.3)
					effect.Transparency = 0.5 + (i * 0.06)
					wait(0.02)
				end
				
				effect:Destroy()
			end)
			
			-- Tocar un sonido de liberación
			local unstuckSound = Instance.new("Sound")
			unstuckSound.SoundId = "rbxassetid://6894580681"  -- Sonido de "whoosh"
			unstuckSound.Volume = 0.8
			unstuckSound.Parent = orbPart
			unstuckSound:Play()
			
			-- Reiniciar contador
			counter.stuckTime = 0
			
			-- Si ha estado atascado más de 3 veces, darle un impulso extra
			if counter.stuckCount > 3 then
				-- Aplicar un impulso hacia abajo para ayudar a salir del tablero
				orbPart:ApplyImpulse(Vector3.new(0, -30, 0) * orbPart:GetMass())
				counter.stuckCount = 0
			end
		end
	else
		-- Si se está moviendo bien, reiniciar el contador
		counter.stuckTime = 0
	end
	
	-- Actualizar la última posición conocida
	counter.lastPosition = orbPart.Position
end

-- ARREGLO: Nueva función para mejorar feedback en colisiones con bordes
function CollisionHandler:checkBorderCollision(orbPart, contactPoint)
	-- Buscar bordes o guías cercanas al punto de contacto
	local bordersAndGuides = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(2, 2, 2),
			contactPoint + Vector3.new(2, 2, 2)
		),
		{self.boardManager.currentBoard}
	)
	
	for _, part in ipairs(bordersAndGuides) do
		if part:GetAttribute("IsBorder") or part:GetAttribute("IsGuide") then
			-- Obtener un ID único para esta combinación de orbe y parte
			local collisionId = orbPart:GetFullName() .. "-" .. part:GetFullName()
			local currentTime = tick()
			
			-- Evitar reproducir efectos de colisión para la misma parte demasiado rápido
			if self.lastHitTime[collisionId] and (currentTime - self.lastHitTime[collisionId]) < 0.2 then
				continue
			end
			
			self.lastHitTime[collisionId] = currentTime
			
			-- Reproducir sonido de golpe contra borde
			local borderSound = Instance.new("Sound")
			borderSound.SoundId = "rbxassetid://2828611988" -- Sonido de golpe sólido
			borderSound.Volume = 0.5 * (orbPart.Velocity.Magnitude / 50) -- Volumen proporcional a la velocidad
			borderSound.PlaybackSpeed = math.random(90, 110) / 100 -- Ligera variación
			borderSound.Parent = part
			borderSound:Play()
			
			-- Auto-destrucción del sonido después de reproducirse
			game:GetService("Debris"):AddItem(borderSound, 1)
			
			-- Crear un pequeño efecto visual en el punto de contacto
			spawn(function()
				local effect = Instance.new("Part")
				effect.Shape = Enum.PartType.Ball
				effect.Size = Vector3.new(0.5, 0.5, 0.5)
				effect.Position = contactPoint
				effect.Anchored = true
				effect.CanCollide = false
				effect.Transparency = 0.5
				effect.Material = Enum.Material.Neon
				effect.Color = part:GetAttribute("IsBorder") and Color3.fromRGB(255, 255, 255) or part.Color
				effect.Parent = workspace
				
				for i = 1, 5 do
					effect.Size = Vector3.new(0.5 + i*0.1, 0.5 + i*0.1, 0.5 + i*0.1)
					effect.Transparency = 0.5 + (i * 0.1)
					wait(0.02)
				end
				
				effect:Destroy()
			end)
			
			break -- Solo procesar una colisión a la vez
		end
	end
end

-- ARREGLO: Verifica colisiones con carriles de aceleración con mejor feedback
function CollisionHandler:checkSpeedLaneCollision(orbPart, contactPoint)
	local speedLanes = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(3, 3, 3), -- Área de detección más grande
			contactPoint + Vector3.new(3, 3, 3)
		),
		{self.boardManager.currentBoard}
	)
	
    for _, part in ipairs(speedLanes) do
        if part:GetAttribute("IsSpeedLane") then
            -- Obtener un ID único para esta combinación de orbe y carril
            local collisionId = orbPart:GetFullName() .. "-" .. part:GetFullName()
            local currentTime = tick()
            
            -- Evitar activar el mismo carril demasiado rápido
            if self.lastHitTime[collisionId] and (currentTime - self.lastHitTime[collisionId]) < 0.5 then
                continue
            end
            
            self.lastHitTime[collisionId] = currentTime
            
            -- Aplicar impulso en la dirección del carril
            local dirX = part:GetAttribute("DirectionX")
            local dirY = part:GetAttribute("DirectionY")
            local dirZ = part:GetAttribute("DirectionZ")
            
            if dirX and dirY then
                local directionVector = Vector3.new(dirX, dirY, dirZ or 0)
                local speedBoost = part:GetAttribute("SpeedBoost") or 1.5
                
                -- Obtener velocidad actual
                local currentSpeed = orbPart.Velocity.Magnitude
                
                -- ARREGLO: Conservar algo de momentum original
                local originalDirection = orbPart.Velocity.Unit
                local blendedDirection = (directionVector + originalDirection * 0.3).Unit
                
                -- ARREGLO: Aplicar impulso con velocidad mínima garantizada
                local targetSpeed = math.max(currentSpeed, 30) * speedBoost
                orbPart.Velocity = blendedDirection * targetSpeed
                
                -- ARREGLO: Sonido de aceleración mejorado
                local speedSound = Instance.new("Sound")
                speedSound.SoundId = "rbxassetid://5273189969" -- Sonido de woosh
                speedSound.Volume = 0.8
                speedSound.PlaybackSpeed = 1.2
                speedSound.Parent = orbPart
                speedSound:Play()
                
                -- Auto-destrucción del sonido
                game:GetService("Debris"):AddItem(speedSound, 1)
				
				-- ARREGLO: Efecto visual mejorado
				spawn(function()
					-- Efecto de pulso en el carril
					local originalColor = part.Color
					local originalTransparency = part.Transparency
					
					for i = 1, 5 do
						part.Color = Color3.fromRGB(255, 255, 255):Lerp(originalColor, i/5)
						part.Transparency = math.max(0, originalTransparency - 0.3 + (i * 0.06))
						wait(0.03)
					end
					
					part.Color = originalColor
					part.Transparency = originalTransparency
				end)
				
				-- ARREGLO: Mostrar efecto de velocidad mejorado
				self:createSpeedEffect(orbPart, blendedDirection)
				
				break
			end
		end
	end
end

-- ARREGLO: Crea un efecto visual mejorado para el impulso de velocidad
function CollisionHandler:createSpeedEffect(orbPart, direction)
	-- ARREGLO: Crear una estela de velocidad más dinámica y visible
	local trailPart = Instance.new("Part")
	trailPart.Size = Vector3.new(0.1, 0.1, 0.1)
	trailPart.Position = orbPart.Position
	trailPart.Transparency = 1
	trailPart.Anchored = true
	trailPart.CanCollide = false
	trailPart.Parent = workspace
	
	-- ARREGLO: Seguir al orbe durante un tiempo
	spawn(function()
		local startTime = tick()
		local duration = 0.8
		
		while tick() - startTime < duration and orbPart and orbPart.Parent do
			trailPart.Position = orbPart.Position
			game:GetService("RunService").Heartbeat:Wait()
		end
	end)
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = trailPart
	
	-- ARREGLO: Partículas más visibles y dinámicas
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 50)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Lifetime = NumberRange.new(0.4, 0.7)
	particles.Speed = NumberRange.new(3, 8)
	particles.SpreadAngle = Vector2.new(8, 8)  -- Ligeramente más amplio pero aún direccional
	particles.Acceleration = Vector3.new(direction.X, direction.Y, 0) * 15
	particles.Rate = 50
	particles.LightEmission = 0.8
	particles.LightInfluence = 0
	particles.Parent = attachment
	
	-- ARREGLO: Añadir un destello para mayor impacto visual
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(2, 2, 2)
	flash.Position = orbPart.Position
	flash.Transparency = 0.5
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 255, 0)
	flash.Anchored = true
	flash.CanCollide = false
	flash.Parent = workspace
	
	-- Animación del destello
	spawn(function()
		for i = 1, 10 do
			flash.Size = Vector3.new(2 + i*0.3, 2 + i*0.3, 2 + i*0.3)
			flash.Transparency = 0.5 + (i * 0.05)
			
			-- Mover el destello con el orbe durante un corto tiempo
			if i <= 3 and orbPart and orbPart.Parent then
				flash.Position = orbPart.Position
			end
			
			wait(0.02)
		end
		flash:Destroy()
	end)
	
	-- ARREGLO: Auto-destrucción después de un tiempo con desvanecimiento
	spawn(function()
		wait(0.5)
		
		-- Desvanecer partículas gradualmente
		for i = 1, 5 do
			particles.Rate = 50 * (1 - i/5)
			wait(0.1)
		end
		
		particles.Enabled = false
		wait(1)
		trailPart:Destroy()
	end)
end

-- ARREGLO: Verifica colisiones con portales con mejor feedback
function CollisionHandler:checkPortalCollision(orbPart, contactPoint)
	local portals = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(4, 4, 4), -- Radio más grande
			contactPoint + Vector3.new(4, 4, 4)
		),
		{self.boardManager.currentBoard}
	)
	
    for _, part in ipairs(portals) do
        if part:GetAttribute("IsPortal") and part:GetAttribute("PortalType") == "Entry" then
            -- Obtener un ID único para esta combinación de orbe y portal
            local portalId = orbPart:GetFullName() .. "-" .. part:GetFullName()
            local currentTime = tick()
            
            -- Evitar activar el mismo portal demasiado rápido
            if self.lastHitTime[portalId] and (currentTime - self.lastHitTime[portalId]) < 1.0 then
                continue
            end
            
            self.lastHitTime[portalId] = currentTime
            
            -- Obtener posición de salida desde los atributos
            local exitX = part:GetAttribute("ExitPositionX")
            local exitY = part:GetAttribute("ExitPositionY")
            local exitZ = part:GetAttribute("ExitPositionZ")
            
            if exitX and exitY then
                -- ARREGLO: Ralentizar el tiempo por un momento para mejor feedback
                spawn(function()
                    local originalVelocity = orbPart.Velocity
                    
                    -- Congelar brevemente el orbe
                    orbPart.Anchored = true
                    
                    -- Efecto de congelación de tiempo
                    local freezeEffect = Instance.new("Part")
                    freezeEffect.Shape = Enum.PartType.Ball
                    freezeEffect.Size = Vector3.new(3, 3, 3)
                    freezeEffect.Position = orbPart.Position
                    freezeEffect.Transparency = 0.5
                    freezeEffect.Material = Enum.Material.Neon
                    freezeEffect.Color = part.Color
                    freezeEffect.Anchored = true
                    freezeEffect.CanCollide = false
                    freezeEffect.Parent = workspace
                    
                    -- Crear onda expansiva
                    for i = 1, 10 do
                        freezeEffect.Size = Vector3.new(3 + i*0.5, 3 + i*0.5, 3 + i*0.5)
                        freezeEffect.Transparency = 0.5 + (i * 0.05)
                        wait(0.01)
                    end
                    
                    -- ARREGLO: Sonido de teletransporte
                    local teleportSound = Instance.new("Sound")
                    teleportSound.SoundId = "rbxassetid://168513088"
                    teleportSound.Volume = 1.0
                    teleportSound.Parent = part
                    teleportSound:Play()
                    
                    -- ARREGLO: Posición de salida con vector completo
                    local exitPos = Vector3.new(exitX, exitY, exitZ or 0)
                    
                    -- Teletransportar el orbe
                    wait(0.1)
                    orbPart.Position = exitPos
                    
                    -- Desanclar y aplicar velocidad preservada
                    orbPart.Anchored = false
                    orbPart.Velocity = originalVelocity * 1.1 -- Ligero aumento de velocidad
                    
                    -- ARREGLO: Efectos visuales mejorados
                    self:createPortalEffect(part, exitPos)
                    
                    -- Crear efecto en el punto de salida
                    local exitFlash = Instance.new("Part")
                    exitFlash.Shape = Enum.PartType.Ball
                    exitFlash.Size = Vector3.new(4, 4, 4)
                    exitFlash.Position = exitPos
                    exitFlash.Transparency = 0.3
                    exitFlash.Material = Enum.Material.Neon
                    exitFlash.Color = Color3.fromRGB(255, 150, 0) -- Color de salida diferente
                    exitFlash.Anchored = true
                    exitFlash.CanCollide = false
                    exitFlash.Parent = workspace
                    
                    -- Animación del destello de salida
                    spawn(function()
                        for i = 1, 12 do
                            exitFlash.Size = Vector3.new(4 + i*0.3, 4 + i*0.3, 4 + i*0.3)
                            exitFlash.Transparency = 0.3 + (i * 0.06)
                            wait(0.02)
                        end
                        exitFlash:Destroy()
                    end)
                    
                    freezeEffect:Destroy()
                end)
                
                break
            end
        end
    end
end

-- ARREGLO: Crea efectos visuales mejorados para la teletransportación de portal
function CollisionHandler:createPortalEffect(entryPortal, exitPosition)
	-- ARREGLO: Efectos de partículas mejorados en portal de entrada
	local entryEffect = Instance.new("ParticleEmitter")
	entryEffect.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
	})
	entryEffect.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	})
	entryEffect.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	entryEffect.Lifetime = NumberRange.new(0.5, 1)
	entryEffect.Speed = NumberRange.new(8, 12)
	entryEffect.SpreadAngle = Vector2.new(180, 180)
	entryEffect.Rate = 0
	entryEffect.Acceleration = Vector3.new(0, -5, 0)
	entryEffect.Parent = entryPortal
	entryEffect:Emit(50) -- Más partículas
	
	-- ARREGLO: Búsqueda mejorada del portal de salida
	local exitPortals = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			exitPosition - Vector3.new(5, 5, 5),
			exitPosition + Vector3.new(5, 5, 5)
		),
		{self.boardManager.currentBoard}
	)
	
	for _, exitPortal in ipairs(exitPortals) do
		if exitPortal:GetAttribute("IsPortal") and exitPortal:GetAttribute("PortalType") == "Exit" then
			-- ARREGLO: Efectos visuales mejorados en portal de salida
			local exitEffect = Instance.new("ParticleEmitter")
			exitEffect.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100))
			})
			exitEffect.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.2),
				NumberSequenceKeypoint.new(0.5, 0.8),
				NumberSequenceKeypoint.new(1, 0)
			})
			exitEffect.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 1)
			})
			exitEffect.Lifetime = NumberRange.new(0.5, 1)
			exitEffect.Speed = NumberRange.new(8, 12)
			exitEffect.SpreadAngle = Vector2.new(180, 180)
			exitEffect.Rate = 0
			exitEffect.Acceleration = Vector3.new(0, -5, 0)
			exitEffect.Parent = exitPortal
			exitEffect:Emit(50)
			
			-- ARREGLO: Efectos de luz pulsante mejorados
			local light = exitPortal:FindFirstChildOfClass("PointLight")
			if not light then
				light = Instance.new("PointLight")
				light.Range = 10
				light.Brightness = 2
				light.Color = Color3.fromRGB(255, 150, 0)
				light.Parent = exitPortal
			end
			
			local originalBrightness = light.Brightness or 1
			spawn(function()
				-- Más pulsos y más dinámicos
				for i = 1, 8 do
					light.Brightness = originalBrightness * (3 + math.sin(i))
					light.Range = 10 + (i * 0.5)
					wait(0.06)
				end
				
				-- Volver a valores normales
				for i = 5, 1, -1 do
					light.Brightness = originalBrightness * (1 + i/5)
					light.Range = 10 + i
					wait(0.05)
				end
				
				light.Brightness = originalBrightness
				light.Range = 10
			end)
			
			break
		end
	end
	
	-- ARREGLO: Sonido de teletransporte mejorado (adicional al reproducido en el punto de colisión)
	local teleportExitSound = Instance.new("Sound")
	teleportExitSound.SoundId = "rbxassetid://1839764671" -- Sonido de teletransporte de salida
	teleportExitSound.Volume = 0.9
	teleportExitSound.PlaybackSpeed = math.random(95, 105) / 100 -- Pequeña variación
	teleportExitSound.Parent = workspace
	
	-- Retraso para sincronizar con la llegada del orbe
	spawn(function()
		wait(0.2)
		teleportExitSound.Position = exitPosition
		teleportExitSound:Play()
		
		-- Auto-limpieza
		game:GetService("Debris"):AddItem(teleportExitSound, 2)
	end)
end

-- ARREGLO: Verifica si el orbe está en una zona de multiplicador con mejor feedback
function CollisionHandler:checkMultiplierZoneCollision(orbPart, contactPoint)
	local multiplierZones = workspace:FindPartsInRegion3WithWhiteList(
		Region3.new(
			contactPoint - Vector3.new(8, 8, 8), -- Radio más grande para mejor detección
			contactPoint + Vector3.new(8, 8, 8)
		),
		{self.boardManager.currentBoard}
	)
	
	for _, part in ipairs(multiplierZones) do
		if part:GetAttribute("IsMultiplierZone") then
			-- Obtener un ID único para esta combinación de orbe y zona
			local zoneId = orbPart:GetFullName() .. "-" .. part:GetFullName()
			local currentTime = tick()
			
			-- Evitar activar la misma zona demasiado rápido
			if self.lastHitTime[zoneId] and (currentTime - self.lastHitTime[zoneId]) < 0.5 then
				continue
			end
			
			self.lastHitTime[zoneId] = currentTime
			
			-- ARREGLO: Efecto visual mejorado para indicar que está en la zona
			spawn(function()
				local originalTransparency = part.Transparency
				local originalColor = part.Color
				
				-- Efecto de flash más dinámico
				for i = 1, 4 do
					part.Transparency = math.max(0, originalTransparency - 0.3)
					part.Color = Color3.fromRGB(255, 255, 255):Lerp(originalColor, i/4)
					wait(0.05)
				end
				
				part.Transparency = originalTransparency
				part.Color = originalColor
				
				-- ARREGLO: Mostrar un texto flotante con el multiplicador
				local multiplier = part:GetAttribute("Multiplier") or 2
				
				local billboardGui = Instance.new("BillboardGui")
				billboardGui.Size = UDim2.new(0, 70, 0, 35)
				billboardGui.StudsOffset = Vector3.new(0, 0, 0)
				billboardGui.Adornee = orbPart
				billboardGui.AlwaysOnTop = true
				
				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 0.3
				textLabel.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
				textLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				textLabel.Font = Enum.Font.GothamBold
				textLabel.TextScaled = true
				textLabel.Text = "x" .. multiplier
				textLabel.Parent = billboardGui
				
				billboardGui.Parent = workspace
				
				-- Animación del texto
				for i = 1, 10 do
					textLabel.Position = UDim2.new(0, 0, 0, -i*0.5)
					textLabel.TextTransparency = i / 10
					textLabel.BackgroundTransparency = 0.3 + (i / 10)
					wait(0.04)
				end
				
				billboardGui:Destroy()
			end)
			
			-- ARREGLO: Reproducir un sonido para indicar multiplicador
			local multiSound = Instance.new("Sound")
			multiSound.SoundId = "rbxassetid://6518811702" -- Sonido de campanilla
			multiSound.Volume = 0.7
			multiSound.Parent = part
			multiSound:Play()
			
			-- Eliminar automáticamente el sonido
			game:GetService("Debris"):AddItem(multiSound, 1)
			
			break
		end
	end
end

return CollisionHandler