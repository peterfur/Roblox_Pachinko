-- RewardManager.lua: Gestiona las recompensas del juego

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local RewardManager = {}
RewardManager.__index = RewardManager

-- Constructor del gestor de recompensas
function RewardManager.new(gameplayManager)
	local self = setmetatable({}, RewardManager)

	-- Referencia al gestor principal
	self.gameplayManager = gameplayManager

	return self
end

-- Modificación de la función giveRewards para manejar la transición de enemigos
function RewardManager:giveRewards()
	local gm = self.gameplayManager

	-- Calcular experiencia ganada
	local expGained = 50 + (gm.gameState.currentEncounter * 10)

	-- Calcular oro ganado
	local goldGained = 20 + (gm.gameState.currentEncounter * 5)

	-- Posibilidad de obtener un orbe nuevo
	local orbChance = 0.3 + (gm.gameState.currentEncounter * 0.05)
	local gotNewOrb = math.random() < orbChance

	-- Posibilidad de obtener una reliquia
	local relicChance = 0.1 + (gm.gameState.currentEncounter * 0.03)
	local gotRelic = math.random() < relicChance

	-- Aplicar recompensas al jugador
	gm.playerManager.stats.gold = gm.playerManager.stats.gold + goldGained
	local leveledUp, levelsGained = gm.playerManager:addExperience(expGained)

	-- Mostrar pantalla de recompensas
	local rewardScreen = Instance.new("ScreenGui")
	rewardScreen.Name = "PeglinRPG_RewardScreen"

	-- Fondo
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = rewardScreen

	-- Panel de recompensas
	local rewardPanel = Instance.new("Frame")
	rewardPanel.Size = UDim2.new(0, 500, 0, 300)
	rewardPanel.Position = UDim2.new(0.5, -250, 0.5, -150)
	rewardPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	rewardPanel.BorderSizePixel = 2
	rewardPanel.Parent = rewardScreen

	-- Título
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	titleLabel.BorderSizePixel = 0
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 24
	titleLabel.Text = "¡RECOMPENSAS!"
	titleLabel.Parent = rewardPanel

	-- Lista de recompensas
	local rewardsList = Instance.new("Frame")
	rewardsList.Size = UDim2.new(1, -40, 1, -100)
	rewardsList.Position = UDim2.new(0, 20, 0, 70)
	rewardsList.BackgroundTransparency = 1
	rewardsList.Parent = rewardPanel

	-- Experiencia
	local expLabel = Instance.new("TextLabel")
	expLabel.Size = UDim2.new(1, 0, 0, 30)
	expLabel.Position = UDim2.new(0, 0, 0, 0)
	expLabel.BackgroundTransparency = 1
	expLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	expLabel.Font = Enum.Font.SourceSans
	expLabel.TextSize = 18
	expLabel.TextXAlignment = Enum.TextXAlignment.Left
	expLabel.Text = "+ " .. expGained .. " EXP"
	expLabel.Parent = rewardsList

	-- Oro
	local goldLabel = Instance.new("TextLabel")
	goldLabel.Size = UDim2.new(1, 0, 0, 30)
	goldLabel.Position = UDim2.new(0, 0, 0, 40)
	goldLabel.BackgroundTransparency = 1
	goldLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	goldLabel.Font = Enum.Font.SourceSans
	goldLabel.TextSize = 18
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left
	goldLabel.Text = "+ " .. goldGained .. " Oro"
	goldLabel.Parent = rewardsList

	-- Nivel alcanzado
	if leveledUp then
		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(1, 0, 0, 30)
		levelLabel.Position = UDim2.new(0, 0, 0, 80)
		levelLabel.BackgroundTransparency = 1
		levelLabel.TextColor3 = Color3.fromRGB(255, 100, 255)
		levelLabel.Font = Enum.Font.SourceSansBold
		levelLabel.TextSize = 18
		levelLabel.TextXAlignment = Enum.TextXAlignment.Left
		levelLabel.Text = "¡SUBISTE " .. levelsGained .. " NIVEL" .. (levelsGained > 1 and "ES" or "") .. "!"
		levelLabel.Parent = rewardsList
	end

	-- Orbe nuevo
	if gotNewOrb then
		-- Seleccionar un orbe aleatorio
		local orbTypes = {"FIRE", "ICE", "LIGHTNING", "VOID"}
		local newOrbType = orbTypes[math.random(1, #orbTypes)]

		-- Añadir al jugador
		gm.playerManager:addOrb(newOrbType)

		local orbLabel = Instance.new("TextLabel")
		orbLabel.Size = UDim2.new(1, 0, 0, 30)
		orbLabel.Position = UDim2.new(0, 0, 0, leveledUp and 120 or 80)
		orbLabel.BackgroundTransparency = 1
		orbLabel.TextColor3 = Config.ORBS[newOrbType].COLOR
		orbLabel.Font = Enum.Font.SourceSansBold
		orbLabel.TextSize = 18
		orbLabel.TextXAlignment = Enum.TextXAlignment.Left
		orbLabel.Text = "+ Nuevo orbe: " .. Config.ORBS[newOrbType].NAME
		orbLabel.Parent = rewardsList
	end

	-- Reliquia nueva
	if gotRelic then
		-- Seleccionar una reliquia aleatoria
		local relicTypes = {"HEART_STONE", "DAMAGE_CRYSTAL", "LUCKY_CLOVER"}
		local newRelicType = relicTypes[math.random(1, #relicTypes)]

		-- Añadir al jugador
		gm.playerManager:addRelic(newRelicType)

		local relicLabel = Instance.new("TextLabel")
		relicLabel.Size = UDim2.new(1, 0, 0, 30)
		relicLabel.Position = UDim2.new(0, 0, 0, (leveledUp and 120 or 80) + (gotNewOrb and 40 or 0))
		relicLabel.BackgroundTransparency = 1
		relicLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		relicLabel.Font = Enum.Font.SourceSansBold
		relicLabel.TextSize = 18
		relicLabel.TextXAlignment = Enum.TextXAlignment.Left
		relicLabel.Text = "+ Reliquia: " .. Config.RELICS[newRelicType].NAME
		relicLabel.Parent = rewardsList
	end

	-- Botón de continuar
	local continueButton = Instance.new("TextButton")
	continueButton.Size = UDim2.new(0, 200, 0, 40)
	continueButton.Position = UDim2.new(0.5, -100, 1, -60)
	continueButton.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.Font = Enum.Font.SourceSansBold
	continueButton.TextSize = 18
	continueButton.Text = "Continuar"
	continueButton.Parent = rewardPanel

	-- Funcionalidad del botón - Eliminar el enemigo actual antes de continuar
	continueButton.MouseButton1Click:Connect(function()
		rewardScreen:Destroy()
		
		-- Eliminar el modelo del enemigo si existe
		if gm.visualElements.enemyModel and gm.visualElements.enemyModel.Parent then
			gm.visualElements.enemyModel:Destroy()
			gm.visualElements.enemyModel = nil
			gm.enemyManager = nil
		end
	end)

	-- Mostrar pantalla
	local player = Players.LocalPlayer
	if player then
		rewardScreen.Parent = player:WaitForChild("PlayerGui")
	else
		warn("No se pudo encontrar el jugador local para mostrar recompensas")
	end

	return rewardScreen
end

return RewardManager