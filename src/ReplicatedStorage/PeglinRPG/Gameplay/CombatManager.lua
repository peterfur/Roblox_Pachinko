-- CombatManager.lua: Gestiona el sistema de combate y colisiones

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local CombatManager = {}
CombatManager.__index = CombatManager

-- Constructor del gestor de combate
function CombatManager.new(gameplayManager)
	local self = setmetatable({}, CombatManager)

	-- Referencia al gestor principal
	self.gameplayManager = gameplayManager

	-- ARREGLO: Almacenar la conexión actual del orbe para poder desconectarla
	self.currentOrbConnection = nil
    
    -- ARREGLO: Registro de clavijas golpeadas para asegurar que se registre el daño
    self.hitPegs = {}
    self.damageDealt = 0
    self.minDamagePerLaunch = 10 -- Daño mínimo garantizado por lanzamiento

	return self
end

-- Configura la detección de colisiones para un orbe lanzado
function CombatManager:setupOrbCollisions(orbVisual, orbData)
	-- Referencias directas para mejor acceso
	local gm = self.gameplayManager
	local effectsManager = gm.effectsManager

	-- ARREGLO: Reiniciar el registro de clavijas golpeadas y daño acumulado
	self.hitPegs = {}
	self.damageDealt = 0

	-- Conectar evento de colisión
	local bounceCount = 0
	local lastHitPeg = nil
	local comboCount = 0
	local lastHitTime = 0

	-- Referencia al sonido de rebote
	local bounceSound = orbVisual:FindFirstChildOfClass("Sound")

	-- Desconectar conexión anterior si existe
	if self.currentOrbConnection then
		self.currentOrbConnection:Disconnect()
		self.currentOrbConnection = nil
	end

	-- ARREGLO: Verificar constantemente si el orbe está activo pero no ha golpeado nada
	spawn(function()
		local launchTime = tick()
		local checkInterval = 0.5 -- Verificar cada medio segundo
		local maxTimeWithoutHit = 3.0 -- Si después de 3 segundos no ha golpeado nada, aplicar daño mínimo
		
		while orbVisual and orbVisual.Parent do
			-- Si ha pasado suficiente tiempo sin golpes y no se ha acumulado daño, aplicar daño mínimo
			if tick() - launchTime > maxTimeWithoutHit and self.damageDealt == 0 and #self.hitPegs == 0 then
				print("No se detectaron golpes, aplicando daño mínimo garantizado:", self.minDamagePerLaunch)
				
				-- Aplicar daño mínimo garantizado
				local killed, _ = gm.enemyManager:takeDamage(self.minDamagePerLaunch, "NORMAL")
				
				-- Actualizar UI del enemigo
				gm.enemyManager.updateHealthBar()
				
				-- Mostrar mensaje de "¡Golpe automático!" para informar al usuario
				effectsManager:showDamageNumber(Vector3.new(0, 0, -30), self.minDamagePerLaunch, false, "¡Golpe automático!")
				
				-- Verificar si el enemigo murió
				if killed then
					self:handleVictory()
				end
				
				-- Marcar que ya aplicamos daño para evitar duplicados
				self.damageDealt = self.minDamagePerLaunch
				break
			end
			
			wait(checkInterval)
		end
	end)

	-- Conectar evento de colisión principal con mejor manejo
	self.currentOrbConnection = orbVisual.Touched:Connect(function(hit)
		-- Verificar si es una clavija
		if hit:GetAttribute("IsPeg") then
			-- ARREGLO: Verificar si ya se golpeó esta clavija (evitar conteo doble)
			local pegId = hit:GetFullName()
			if self.hitPegs[pegId] then
				return
			end
			
			-- Registrar esta clavija como golpeada
			self.hitPegs[pegId] = true

			-- Evitar golpear la misma clavija repetidamente
			if hit == lastHitPeg then
				return
			end

			-- Reproducir sonido
			if bounceSound then
				bounceSound:Play()
			end

			-- Registrar esta clavija como la última golpeada
			lastHitPeg = hit
			bounceCount = bounceCount + 1

			-- Calcular combo
			local currentTime = tick()
			if currentTime - lastHitTime < 1.5 then
				comboCount = comboCount + 1
			else
				comboCount = 1
			end
			lastHitTime = currentTime

			-- Procesar golpe según tipo de orbe
			local damageType, damageAmount = gm.orbManager:processPegHit(orbData, hit, gm.enemyManager)

			-- Aplicar multiplicador de combo
			local comboMultiplier = math.min(3, 1 + (comboCount * 0.1))
			damageAmount = math.floor(damageAmount * comboMultiplier)

			-- ARREGLO: Acumular el daño total realizado
			self.damageDealt = self.damageDealt + damageAmount

			-- Aplicar daño al enemigo
			local killed, actualDamage = gm.enemyManager:takeDamage(damageAmount, damageType)

			-- Mostrar número de daño flotante
			effectsManager:showDamageNumber(hit.Position, actualDamage, comboMultiplier > 1.5)

			-- Actualizar UI del enemigo
			gm.enemyManager.updateHealthBar()

			-- Mostrar efectos visuales según el tipo de orbe
			effectsManager:showOrbEffect(orbData.type, hit.Position)

			-- Verificar si el enemigo murió
			if killed then
				-- Desconectar la detección de colisiones
				if self.currentOrbConnection then
					self.currentOrbConnection:Disconnect()
					self.currentOrbConnection = nil
				end

				-- Manejar victoria
				self:handleVictory()
			end

			-- Animar clavija golpeada
			self:animatePegHit(hit, damageType)

			-- Disparar eventos
			for _, callback in ipairs(gm.events.onDamageDealt) do
				callback(damageAmount, orbData, hit)
			end
		end
	end)

	-- Verificar si el orbe se detiene o cae fuera del tablero
	local checkStopOrFall = function()
		local checkConnection
		checkConnection = game:GetService("RunService").Heartbeat:Connect(function()
			if not orbVisual or not orbVisual.Parent then
				checkConnection:Disconnect()
				return
			end

			-- Verificar si cayó fuera del tablero
			if orbVisual.Position.Y < -50 then
				print("Orbe cayó fuera del tablero")
				
				-- ARREGLO: Si no ha hecho daño, aplicar daño mínimo garantizado
				if self.damageDealt == 0 then
					print("No se registró daño, aplicando daño mínimo:", self.minDamagePerLaunch)
					local killed, _ = gm.enemyManager:takeDamage(self.minDamagePerLaunch, "NORMAL")
					gm.enemyManager.updateHealthBar()
					
					-- Mostrar mensaje de daño automático
					effectsManager:showDamageNumber(Vector3.new(0, 0, -30), self.minDamagePerLaunch, false, "¡Golpe automático!")
					
					if killed then
						self:handleVictory()
					end
				end
				
				
				orbVisual:Destroy()
				checkConnection:Disconnect()

				-- Verificar si hay más orbes
				if #gm.orbManager.orbPoolForBattle == 0 then
					-- No hay más orbes, cambiar al turno del enemigo
					wait(1) -- Esperar un poco para que el jugador vea lo que pasó
					gm:changePhase("ENEMY_TURN")
				else
					-- Hay más orbes, continuar turno del jugador
					gm.phaseManager:startPlayerTurn()
				end
				return
			end

			-- Verificar si el orbe se detuvo
			local velocity = orbVisual.Velocity
			if velocity.Magnitude < Config.PHYSICS.MIN_BOUNCE_VELOCITY then
				local stillCounter = 0
				-- Verificar durante varios frames para asegurarse
				local stillCheckConnection
				stillCheckConnection = game:GetService("RunService").Heartbeat:Connect(function()
					if not orbVisual or not orbVisual.Parent then
						stillCheckConnection:Disconnect()
						return
					end

					if orbVisual.Velocity.Magnitude < Config.PHYSICS.MIN_BOUNCE_VELOCITY then
						stillCounter = stillCounter + 1

						-- Si se mantiene detenido por suficiente tiempo
						if stillCounter > 30 then
							print("Orbe se detuvo")
							
							-- ARREGLO: Si no ha hecho daño, aplicar daño mínimo garantizado
							if self.damageDealt == 0 then
								print("No se registró daño, aplicando daño mínimo:", self.minDamagePerLaunch)
								local killed, _ = gm.enemyManager:takeDamage(self.minDamagePerLaunch, "NORMAL")
								gm.enemyManager.updateHealthBar()
								
								-- Mostrar mensaje de daño automático
								effectsManager:showDamageNumber(Vector3.new(0, 0, -30), self.minDamagePerLaunch, false, "¡Golpe automático!")
								
								if killed then
									self:handleVictory()
									stillCheckConnection:Disconnect()
									checkConnection:Disconnect()
									return
								end
							end
							
							orbVisual:Destroy()
							stillCheckConnection:Disconnect()
							checkConnection:Disconnect()

							-- Verificar si hay más orbes
							if #gm.orbManager.orbPoolForBattle == 0 then
								-- No hay más orbes, cambiar al turno del enemigo
								wait(1)
								gm:changePhase("ENEMY_TURN")
							else
								-- Hay más orbes, continuar turno del jugador
								gm.phaseManager:startPlayerTurn()
							end
						end
					else
						-- Se movió de nuevo, resetear contador
						stillCounter = 0
					end
				end)
			end
		end)
	end

	-- Iniciar verificación de detención
	checkStopOrFall()
end

-- Anima una clavija cuando es golpeada
function CombatManager:animatePegHit(pegPart, damageType)
	-- ARREGLO: Esta función está implementada en CollisionHandler.lua
	-- Aquí solo manejamos los aspectos del daño
	self.gameplayManager.boardManager:registerPegHit(pegPart)
end

-- Maneja la victoria sobre un enemigo con mejor feedback
function CombatManager:handleVictory()
	print("¡Victoria sobre el enemigo!")

	-- Actualizar estado del juego
	local gm = self.gameplayManager
	gm.gameState.battleResult = "WIN"

	-- ARREGLO: Mensaje de victoria más visual y satisfactorio
	-- Mostrar mensaje de victoria
	local victoryMessage = Instance.new("BillboardGui")
	victoryMessage.Size = UDim2.new(0, 500, 0, 120)
	victoryMessage.StudsOffset = Vector3.new(0, 0, 0)
	victoryMessage.Adornee = workspace.Terrain
	victoryMessage.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 0.3
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 80, 0)
	textLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextSize = 48
	textLabel.Text = "¡VICTORIA!"
	textLabel.Parent = victoryMessage

	victoryMessage.Parent = workspace

	-- Reproducir sonido de victoria
	local victorySound = Instance.new("Sound")
	victorySound.SoundId = "rbxassetid://9120903079" -- Sonido de victoria
	victorySound.Volume = 0.8
	victorySound.Parent = workspace
	victorySound:Play()

	-- Animar mensaje
	spawn(function()
		for i = 1, 10 do
			victoryMessage.StudsOffset = Vector3.new(0, i, 0)
			wait(0.1)
		end

		wait(1)

		for i = 10, 1, -1 do
			victoryMessage.StudsOffset = Vector3.new(0, i, 0)
			wait(0.05)
		end

		victoryMessage:Destroy()
	end)

	-- Animación de desvanecimiento para el enemigo
	if gm.visualElements.enemyModel then
		spawn(function()
			local enemyParts = {}
			for _, part in pairs(gm.visualElements.enemyModel:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(enemyParts, part)
				end
			end

			-- Animar desvanecimiento
			for transparency = 0, 1, 0.1 do
				for _, part in ipairs(enemyParts) do
					if part.Transparency < 1 then -- No afectar a partes ya transparentes
						part.Transparency = transparency
					end
				end
				wait(0.05)
			end
		end)
	end

	-- Esperar un momento antes de mostrar recompensas
	wait(3)

	-- Dar recompensas al jugador
	gm.rewardManager:giveRewards()

	-- Avanzar al siguiente encuentro
	local completedLevel = gm.playerManager:advanceProgress()

	if completedLevel then
		-- Completó el nivel, mostrar mensaje y cambiar a pantalla de nivel
		gm.uiManager:showLevelCompletedScreen()
	else
		-- Solo pasó al siguiente encuentro, preparar nuevo encuentro
		wait(1)
		gm:setupEncounter()
	end
end

return CombatManager