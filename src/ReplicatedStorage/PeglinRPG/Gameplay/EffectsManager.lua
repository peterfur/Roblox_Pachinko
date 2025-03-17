-- EffectsManager.lua: Gestiona los efectos visuales y sonoros

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local EffectsManager = {}
EffectsManager.__index = EffectsManager

-- Constructor del gestor de efectos
function EffectsManager.new(gameplayManager)
	local self = setmetatable({}, EffectsManager)

	-- Referencia al gestor principal
	self.gameplayManager = gameplayManager

	return self
end

-- Muestra un número de daño flotante
function EffectsManager:showDamageNumber(position, amount, isCritical)
	-- Crear el indicador visual
	local damageText = Instance.new("BillboardGui")
	damageText.Size = UDim2.new(0, 100, 0, 40)
	damageText.StudsOffset = Vector3.new(0, 2, 0)
	damageText.Adornee = nil -- No adjuntar a ningún objeto
	damageText.AlwaysOnTop = true
	damageText.MaxDistance = 50
	damageText.Parent = workspace

	-- Posicionar correctamente
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	damageText.Adornee = attachment

	-- Texto con el daño
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.Text = tostring(amount)

	-- Color basado en la fuerza del daño/crítico
	if isCritical then
		textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Rojo para críticos
		textLabel.Text = textLabel.Text .. "!"
	else
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Blanco para normal
	end

	textLabel.Parent = damageText

	-- Animación del texto de daño
	spawn(function()
		for i = 1, 20 do
			textLabel.Position = UDim2.new(0, 0, 0, -i*2)
			textLabel.TextTransparency = i / 20
			wait(0.05)
		end
		damageText:Destroy()
		attachment:Destroy()
	end)
end

-- Muestra efectos visuales según el tipo de orbe
function EffectsManager:showOrbEffect(orbType, position)
	if orbType == "FIRE" then
		-- Efecto de fuego
		local fire = Instance.new("Fire")
		fire.Heat = 10
		fire.Size = 5
		fire.Color = Color3.fromRGB(255, 100, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 200, 0)

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(1, 1, 1)
		part.Position = position
		fire.Parent = part
		part.Parent = workspace

		-- Eliminar después de un tiempo
		game:GetService("Debris"):AddItem(part, 1.5)

	elseif orbType == "ICE" then
		-- Efecto de hielo
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 0.5
		part.Size = Vector3.new(2, 2, 2)
		part.Position = position
		part.Color = Color3.fromRGB(100, 200, 255)
		part.Material = Enum.Material.Ice
		part.Parent = workspace

		-- Partículas de hielo
		local attachment = Instance.new("Attachment")
		attachment.Parent = part

		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(200, 240, 255))
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 0)
		})
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Rate = 50
		particles.Speed = NumberRange.new(3, 5)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = attachment

		-- Desvanecimiento gradual
		spawn(function()
			for i = 1, 10 do
				part.Transparency = 0.5 + (i * 0.05)
				wait(0.1)
			end
			part:Destroy()
		end)

	elseif orbType == "LIGHTNING" then
		-- Efecto de rayo
		for i = 1, 3 do
			local startPos = position
			local endPos = position + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-2, 2))

			local bolt = Instance.new("Beam")
			local a0 = Instance.new("Attachment")
			local a1 = Instance.new("Attachment")

			-- Crear partes para los attachments
			local p0 = Instance.new("Part")
			p0.Anchored = true
			p0.CanCollide = false
			p0.Transparency = 1
			p0.Position = startPos
			p0.Parent = workspace

			local p1 = Instance.new("Part")
			p1.Anchored = true
			p1.CanCollide = false
			p1.Transparency = 1
			p1.Position = endPos
			p1.Parent = workspace

			a0.Parent = p0
			a1.Parent = p1

			bolt.Attachment0 = a0
			bolt.Attachment1 = a1
			bolt.Width0 = 0.5
			bolt.Width1 = 0.2
			bolt.LightEmission = 1
			bolt.FaceCamera = true
			bolt.Texture = "rbxassetid://446111271"
			bolt.TextureLength = 0.5
			bolt.TextureSpeed = 2
			bolt.Color = ColorSequence.new(Color3.fromRGB(150, 150, 255))
			bolt.Parent = workspace

			-- Eliminar después de un tiempo
			spawn(function()
				wait(0.3)
				bolt:Destroy()
				p0:Destroy()
				p1:Destroy()
			end)
		end

	elseif orbType == "VOID" then
		-- Efecto de vacío
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 0.3
		part.Size = Vector3.new(3, 3, 3)
		part.Position = position
		part.Color = Color3.fromRGB(100, 0, 100)
		part.Material = Enum.Material.Neon
		part.Parent = workspace

		-- Animación de implosión
		spawn(function()
			for i = 1, 10 do
				part.Size = Vector3.new(3 - i*0.25, 3 - i*0.25, 3 - i*0.25)
				part.Transparency = 0.3 + (i * 0.07)
				wait(0.05)
			end
			part:Destroy()
		end)
	end
end

-- Muestra un efecto de resurrección
function EffectsManager:showResurrectionEffect()
	-- Efecto de resurrección para el jugador
	local effect = Instance.new("Part")
	effect.Shape = Enum.PartType.Ball
	effect.Size = Vector3.new(10, 10, 10)
	effect.Position = Vector3.new(0, 5, 0) -- Posición del jugador
	effect.Anchored = true
	effect.CanCollide = false
	effect.Transparency = 0.5
	effect.Color = Color3.fromRGB(255, 200, 100)
	effect.Material = Enum.Material.Neon
	effect.Parent = workspace

	-- Partículas
	local attachment = Instance.new("Attachment")
	attachment.Parent = effect

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = 100
	particles.Speed = NumberRange.new(10, 15)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment

	-- Animación de expansión y desaparición
	spawn(function()
		for i = 1, 10 do
			effect.Size = Vector3.new(10 + i, 10 + i, 10 + i)
			effect.Transparency = 0.5 + (i * 0.05)
			wait(0.1)
		end
		effect:Destroy()
	end)

	-- Mostrar mensaje
	local message = Instance.new("BillboardGui")
	message.Size = UDim2.new(0, 300, 0, 100)
	message.StudsOffset = Vector3.new(0, 10, 0)
	message.Adornee = workspace.Terrain
	message.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 0.5
	textLabel.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
	textLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextSize = 24
	textLabel.Text = "¡RESURRECCIÓN!"
	textLabel.Parent = message

	message.Parent = workspace

	spawn(function()
		wait(3)
		message:Destroy()
	end)
end

return EffectsManager