-- PhaseManager.lua: Gestiona las fases del juego y transiciones

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local PhaseManager = {}
PhaseManager.__index = PhaseManager

-- Constructor del gestor de fases
function PhaseManager.new(gameplayManager)
	local self = setmetatable({}, PhaseManager)

	-- Referencia al gestor principal
	self.gameplayManager = gameplayManager

	return self
end

-- Cambia la fase actual del juego
function PhaseManager:changePhase(newPhase)
	local gm = self.gameplayManager

	local oldPhase = gm.gameState.currentPhase
	gm.gameState.currentPhase = newPhase

	print("Cambiando fase: " .. oldPhase .. " -> " .. newPhase)

	-- Lógica específica para cada fase
	if newPhase == "PLAYER_TURN" then
		-- Iniciar turno del jugador
		self:startPlayerTurn()
	elseif newPhase == "ENEMY_TURN" then
		-- Iniciar turno del enemigo
		self:startEnemyTurn()
	elseif newPhase == "REWARD" then
		-- Mostrar pantalla de recompensas
		gm.rewardManager:giveRewards()
	elseif newPhase == "GAME_OVER" then
		-- Mostrar pantalla de fin de juego
		gm.uiManager:showGameOverScreen(gm.gameState.battleResult)
	end

	-- Disparar eventos
	for _, callback in ipairs(gm.events.onPhaseChanged) do
		callback(oldPhase, newPhase)
	end

	return true
end

-- Inicia el turno del jugador
function PhaseManager:startPlayerTurn()
	local gm = self.gameplayManager

	print("Iniciando turno del jugador")

	-- Incrementar contador de turnos
	gm.gameState.turnCount = gm.gameState.turnCount + 1

	-- Seleccionar próximo orbe
	local nextOrb = gm.orbManager:selectNextOrb()

	-- Crear representación visual del orbe
	if gm.visualElements.currentOrbVisual then
		gm.visualElements.currentOrbVisual:Destroy()
	end

	-- Posición inicial para el orbe
	local startPosition = Vector3.new(0, 20, 0)

	-- Crear orbe visual
	gm.visualElements.currentOrbVisual = gm.orbManager:createOrbVisual(nextOrb, startPosition)

	-- Actualizar UI
	gm.uiManager:updateUI()

	return true
end

-- Maneja el turno del enemigo
function PhaseManager:startEnemyTurn()
	local gm = self.gameplayManager

	print("Iniciando turno del enemigo")

	-- Procesar efectos activos
	gm.enemyManager:processEffects()

	-- Decidir el próximo ataque
	local attackType, attackDamage = gm.enemyManager:decideNextAttack()

	-- Mostrar visualización del ataque
	self:visualizeEnemyAttack(attackType, attackDamage)

	-- Después de un retraso, aplicar el daño
	wait(1.5)

	-- Aplicar daño al jugador si es un ataque ofensivo
	if attackDamage > 0 then
		local died, result = gm.playerManager:takeDamage(attackDamage)

		-- Actualizar UI
		gm.uiManager:updateUI()

		-- Verificar si el jugador murió
		if died then
			gm.gameState.battleResult = "LOSE"
			gm:changePhase("GAME_OVER")
			return
		elseif result == "REVIVED" then
			-- Mostrar efecto de resurrección
			gm.effectsManager:showResurrectionEffect()
		end
	end

	-- Volver al turno del jugador
	wait(1)
	gm:changePhase("PLAYER_TURN")
end

-- Visualiza el ataque del enemigo
function PhaseManager:visualizeEnemyAttack(attackType, damage)
	local gm = self.gameplayManager

	-- Crear el contenedor para la información de ataque
	local attackInfo = Instance.new("BillboardGui")
	attackInfo.Size = UDim2.new(0, 150, 0, 50)
	attackInfo.StudsOffset = Vector3.new(0, 5, 0)

	-- Asegurar que el enemyModel existe y tiene un PrimaryPart
	if gm.visualElements.enemyModel and gm.visualElements.enemyModel.PrimaryPart then
		attackInfo.Adornee = gm.visualElements.enemyModel.PrimaryPart
	else
		-- Si no hay un enemyModel válido, usar un objeto alternativo
		local dummyPart = Instance.new("Part")
		dummyPart.Anchored = true
		dummyPart.CanCollide = false
		dummyPart.Transparency = 1
		dummyPart.Position = Vector3.new(0, 5, -30)
		dummyPart.Parent = workspace
		attackInfo.Adornee = dummyPart

		-- Limpiar después de un tiempo
		spawn(function()
			wait(3)
			dummyPart:Destroy()
		end)
	end

	attackInfo.AlwaysOnTop = true

	-- Crear la etiqueta del ataque
	local attackLabel = Instance.new("TextLabel")
	attackLabel.Size = UDim2.new(1, 0, 1, 0)
	attackLabel.BackgroundTransparency = 0.5
	attackLabel.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
	attackLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	attackLabel.Font = Enum.Font.SourceSansBold
	attackLabel.TextSize = 16

	-- Personalizar según tipo de ataque
	if attackType == "TACKLE" or attackType == "SLASH" or attackType == "SMASH" then
		attackLabel.Text = attackType .. "\n" .. damage .. " daño"
		attackLabel.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
	elseif attackType == "BOUNCE" or attackType == "BONE_THROW" or attackType == "THROW" then
		attackLabel.Text = attackType .. "\n" .. damage .. " daño"
		attackLabel.BackgroundColor3 = Color3.fromRGB(120, 50, 0)
	elseif attackType == "DEFEND" or attackType == "BLOCK" then
		attackLabel.Text = attackType .. "\n+Defensa"
		attackLabel.BackgroundColor3 = Color3.fromRGB(0, 50, 100)
	elseif attackType == "ROAR" then
		attackLabel.Text = "ROAR\n+Daño"
		attackLabel.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
	elseif attackType == "REASSEMBLE" then
		attackLabel.Text = "REASSEMBLE\nCuración"
		attackLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
	elseif attackType == "STUNNED" then
		attackLabel.Text = "ATURDIDO"
		attackLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
	else
		attackLabel.Text = tostring(attackType) .. "\n" .. damage .. " daño"
	end

	attackLabel.Parent = attackInfo
	attackInfo.Parent = workspace

	-- Animar el enemigo
	if gm.visualElements.enemyModel and gm.visualElements.enemyModel.PrimaryPart then
		local model = gm.visualElements.enemyModel
		local originalPosition = model:GetPrimaryPartCFrame().Position

		if attackType == "TACKLE" or attackType == "SLASH" or attackType == "SMASH" then
			-- Animación de embestida
			for i = 1, 5 do
				model:SetPrimaryPartCFrame(CFrame.new(originalPosition + Vector3.new(0, 0, 5 - i)))
				wait(0.05)
			end

			for i = 1, 5 do
				model:SetPrimaryPartCFrame(CFrame.new(originalPosition + Vector3.new(0, 0, i - 5)))
				wait(0.03)
			end

			model:SetPrimaryPartCFrame(CFrame.new(originalPosition))
		elseif attackType == "BOUNCE" or attackType == "THROW" then
			-- Animación de salto
			for i = 1, 5 do
				model:SetPrimaryPartCFrame(CFrame.new(originalPosition + Vector3.new(0, i*0.5, 0)))
				wait(0.05)
			end

			for i = 5, 1, -1 do
				model:SetPrimaryPartCFrame(CFrame.new(originalPosition + Vector3.new(0, i*0.5, 0)))
				wait(0.03)
			end

			model:SetPrimaryPartCFrame(CFrame.new(originalPosition))
		elseif attackType == "ROAR" then
			-- Animación de rugido (escala)
			local originalSize = model.PrimaryPart.Size

			for i = 1, 5 do
				local scale = 1 + (i * 0.1)
				model.PrimaryPart.Size = originalSize * scale
				wait(0.05)
			end

			for i = 5, 1, -1 do
				local scale = 1 + (i * 0.1)
				model.PrimaryPart.Size = originalSize * scale
				wait(0.03)
			end

			model.PrimaryPart.Size = originalSize
		end
	end

	-- Eliminar la información después de un tiempo
	spawn(function()
		wait(1.5)
		attackInfo:Destroy()
	end)
end

return PhaseManager