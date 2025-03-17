-- UIManager.lua: Gestor de interfaces de usuario para el juego

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

local UIManager = {}
UIManager.__index = UIManager

-- Constructor del gestor de UI
function UIManager.new(gameplayManager)
	local self = setmetatable({}, UIManager)

	-- Referencia al gestor principal
	self.gameplayManager = gameplayManager

	return self
end

-- Configura la interfaz de usuario para la batalla
function UIManager:setupBattleUI()
	local player = Players.LocalPlayer
	if not player then
		warn("No se pudo encontrar el jugador local")
		return false
	end

	-- Limpiar UI existente
	if player.PlayerGui:FindFirstChild("PeglinRPG_BattleUI") then
		player.PlayerGui:FindFirstChild("PeglinRPG_BattleUI"):Destroy()
	end

	-- Crear UI principal
	local battleUI = Instance.new("ScreenGui")
	battleUI.Name = "PeglinRPG_BattleUI"

	-- Panel de jugador (salud, orbes, etc.)
	local playerPanel = Instance.new("Frame")
	playerPanel.Size = UDim2.new(0, 200, 0, 150)
	playerPanel.Position = UDim2.new(0, 10, 0, 10)
	playerPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	playerPanel.BackgroundTransparency = 0.2
	playerPanel.BorderSizePixel = 0
	playerPanel.Parent = battleUI

	-- Título del panel
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 0.5
	titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "Jugador"
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.Parent = playerPanel

	-- Barra de salud del jugador
	local healthBackground = Instance.new("Frame")
	healthBackground.Size = UDim2.new(0.9, 0, 0, 20)
	healthBackground.Position = UDim2.new(0.05, 0, 0, 40)
	healthBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	healthBackground.BorderSizePixel = 0
	healthBackground.Parent = playerPanel

	local healthBar = Instance.new("Frame")
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	healthBar.BorderSizePixel = 0
	healthBar.Name = "HealthFill"
	healthBar.Parent = healthBackground

	local healthText = Instance.new("TextLabel")
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.Text = self.gameplayManager.playerManager.stats.health .. "/" .. self.gameplayManager.playerManager.stats.maxHealth
	healthText.TextSize = 14
	healthText.Font = Enum.Font.SourceSansBold
	healthText.Name = "HealthText"
	healthText.Parent = healthBackground

	-- Orbes restantes
	local orbsLabel = Instance.new("TextLabel")
	orbsLabel.Size = UDim2.new(1, 0, 0, 25)
	orbsLabel.Position = UDim2.new(0, 0, 0, 70)
	orbsLabel.BackgroundTransparency = 1
	orbsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	orbsLabel.Text = "Orbes Restantes: " .. #self.gameplayManager.orbManager.orbPoolForBattle + 1
	orbsLabel.TextSize = 14
	orbsLabel.Font = Enum.Font.SourceSans
	orbsLabel.Name = "OrbCountLabel"
	orbsLabel.Parent = playerPanel

	-- Nivel actual
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(1, 0, 0, 25)
	levelLabel.Position = UDim2.new(0, 0, 0, 95)
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
	levelLabel.Text = "Nivel: " .. Config.LEVELS[self.gameplayManager.playerManager.progression.currentLevel].NAME
	levelLabel.TextSize = 14
	levelLabel.Font = Enum.Font.SourceSans
	levelLabel.Parent = playerPanel

	-- Encuentro actual
	local encounterLabel = Instance.new("TextLabel")
	encounterLabel.Size = UDim2.new(1, 0, 0, 25)
	encounterLabel.Position = UDim2.new(0, 0, 0, 120)
	encounterLabel.BackgroundTransparency = 1
	encounterLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	encounterLabel.Text = "Encuentro: " .. self.gameplayManager.gameState.currentEncounter .. "/" .. self.gameplayManager.playerManager.progression.totalEncounters
	encounterLabel.TextSize = 14
	encounterLabel.Font = Enum.Font.SourceSans
	encounterLabel.Parent = playerPanel

	-- Panel de orbe actual
	local orbPanel = Instance.new("Frame")
	orbPanel.Size = UDim2.new(0, 150, 0, 100)
	orbPanel.Position = UDim2.new(0, 10, 1, -110)
	orbPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	orbPanel.BackgroundTransparency = 0.2
	orbPanel.BorderSizePixel = 0
	orbPanel.Parent = battleUI

	local orbTitleLabel = Instance.new("TextLabel")
	orbTitleLabel.Size = UDim2.new(1, 0, 0, 25)
	orbTitleLabel.Position = UDim2.new(0, 0, 0, 0)
	orbTitleLabel.BackgroundTransparency = 0.5
	orbTitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	orbTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	orbTitleLabel.Text = "Orbe Actual"
	orbTitleLabel.TextSize = 16
	orbTitleLabel.Font = Enum.Font.SourceSansSemibold
	orbTitleLabel.Parent = orbPanel

	local orbNameLabel = Instance.new("TextLabel")
	orbNameLabel.Size = UDim2.new(1, 0, 0, 20)
	orbNameLabel.Position = UDim2.new(0, 0, 0, 30)
	orbNameLabel.BackgroundTransparency = 1
	orbNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	orbNameLabel.Text = "Seleccionando..."
	orbNameLabel.TextSize = 14
	orbNameLabel.Font = Enum.Font.SourceSansBold
	orbNameLabel.Name = "OrbNameLabel"
	orbNameLabel.Parent = orbPanel

	local orbDescLabel = Instance.new("TextLabel")
	orbDescLabel.Size = UDim2.new(1, -10, 0, 40)
	orbDescLabel.Position = UDim2.new(0, 5, 0, 55)
	orbDescLabel.BackgroundTransparency = 1
	orbDescLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	orbDescLabel.Text = "Haz clic para lanzar el orbe"
	orbDescLabel.TextSize = 12
	orbDescLabel.Font = Enum.Font.SourceSans
	orbDescLabel.TextWrapped = true
	orbDescLabel.Name = "OrbDescLabel"
	orbDescLabel.Parent = orbPanel

	-- Instrucciones
	local instructionsLabel = Instance.new("TextLabel")
	instructionsLabel.Size = UDim2.new(0, 400, 0, 40)
	instructionsLabel.Position = UDim2.new(0.5, -200, 0, 10)
	instructionsLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	instructionsLabel.BackgroundTransparency = 0.5
	instructionsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	instructionsLabel.Text = "Haz clic para lanzar el orbe en esa dirección"
	instructionsLabel.TextSize = 18
	instructionsLabel.Font = Enum.Font.SourceSansBold
	instructionsLabel.Parent = battleUI

	-- Guardar referencia para poder actualizar
	self.battleUI = battleUI

	-- Registrar la UI
	battleUI.Parent = player.PlayerGui

	return battleUI
end

-- Actualiza la interfaz de usuario
function UIManager:updateUI()
	if not self.battleUI then return end

	local gm = self.gameplayManager
	local orbsLabel = self.battleUI:FindFirstChild("OrbCountLabel", true)
	local healthBar = self.battleUI:FindFirstChild("HealthFill", true)
	local healthText = self.battleUI:FindFirstChild("HealthText", true)
	local orbNameLabel = self.battleUI:FindFirstChild("OrbNameLabel", true)
	local orbDescLabel = self.battleUI:FindFirstChild("OrbDescLabel", true)

	if healthBar and healthText then
		-- Actualizar salud del jugador
		local healthRatio = gm.playerManager.stats.health / gm.playerManager.stats.maxHealth
		healthBar.Size = UDim2.new(healthRatio, 0, 1, 0)
		healthText.Text = gm.playerManager.stats.health .. "/" .. gm.playerManager.stats.maxHealth

		-- Cambiar color según la salud
		if healthRatio < 0.3 then
			healthBar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		elseif healthRatio < 0.6 then
			healthBar.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
		else
			healthBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		end
	end

	if orbsLabel then
		-- Actualizar contador de orbes
		orbsLabel.Text = "Orbes Restantes: " .. (#gm.orbManager.orbPoolForBattle + (gm.visualElements.currentOrbVisual and 1 or 0))
	end

	if orbNameLabel and orbDescLabel then
		-- Actualizar información del orbe actual
		if gm.orbManager.currentOrb then
			orbNameLabel.Text = gm.orbManager.currentOrb.name
			orbDescLabel.Text = gm.orbManager.currentOrb.description

			-- Cambiar color según tipo de orbe
			orbNameLabel.TextColor3 = gm.orbManager.currentOrb.color
		else
			orbNameLabel.Text = "Seleccionando..."
			orbDescLabel.Text = "Haz clic para lanzar el orbe"
		end
	end
end

-- Muestra una pantalla de fin de nivel
function UIManager:showLevelCompletedScreen()
	local gm = self.gameplayManager

	-- Pantalla de nivel completado
	local levelScreen = Instance.new("ScreenGui")
	levelScreen.Name = "PeglinRPG_LevelCompleted"

	-- Fondo
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.Parent = levelScreen

	-- Panel de nivel
	local levelPanel = Instance.new("Frame")
	levelPanel.Size = UDim2.new(0, 600, 0, 400)
	levelPanel.Position = UDim2.new(0.5, -300, 0.5, -200)
	levelPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	levelPanel.BorderSizePixel = 2
	levelPanel.Parent = levelScreen

	-- Título
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	titleLabel.BorderSizePixel = 0
	titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 32
	titleLabel.Text = "¡NIVEL COMPLETADO!"
	titleLabel.Parent = levelPanel

	-- Verificar que hay niveles completados
	if #gm.playerManager.progression.completedLevels > 0 then
		-- Detalles del nivel
		local completedLevel = gm.playerManager.progression.completedLevels[#gm.playerManager.progression.completedLevels]
		local levelConfig = Config.LEVELS[completedLevel]

		if levelConfig then
			local levelName = Instance.new("TextLabel")
			levelName.Size = UDim2.new(1, 0, 0, 40)
			levelName.Position = UDim2.new(0, 0, 0, 80)
			levelName.BackgroundTransparency = 1
			levelName.TextColor3 = Color3.fromRGB(255, 255, 255)
			levelName.Font = Enum.Font.SourceSansSemibold
			levelName.TextSize = 24
			levelName.Text = "Has completado: " .. levelConfig.NAME
			levelName.Parent = levelPanel
		end
	end

	-- Estadísticas
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(1, 0, 0, 30)
	statsTitle.Position = UDim2.new(0, 0, 0, 140)
	statsTitle.BackgroundTransparency = 1
	statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsTitle.Font = Enum.Font.SourceSansSemibold
	statsTitle.TextSize = 20
	statsTitle.Text = "Estadísticas:"
	statsTitle.Parent = levelPanel

	-- Lista de estadísticas
	local statsList = Instance.new("Frame")
	statsList.Size = UDim2.new(1, -100, 0, 150)
	statsList.Position = UDim2.new(0.5, -250, 0, 180)
	statsList.BackgroundTransparency = 1
	statsList.Parent = levelPanel

	-- Enemigos derrotados
	local enemiesLabel = Instance.new("TextLabel")
	enemiesLabel.Size = UDim2.new(0.5, 0, 0, 30)
	enemiesLabel.Position = UDim2.new(0, 0, 0, 0)
	enemiesLabel.BackgroundTransparency = 1
	enemiesLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
	enemiesLabel.Font = Enum.Font.SourceSans
	enemiesLabel.TextSize = 18
	enemiesLabel.TextXAlignment = Enum.TextXAlignment.Left
	enemiesLabel.Text = "Enemigos derrotados: " .. gm.playerManager.progression.totalEncounters
	enemiesLabel.Parent = statsList

	-- Siguiente nivel
	if gm.playerManager.progression.currentLevel ~= "COMPLETED_GAME" then
		local levelConfig = Config.LEVELS[gm.playerManager.progression.currentLevel]
		if levelConfig then
			local nextLevelLabel = Instance.new("TextLabel")
			nextLevelLabel.Size = UDim2.new(1, 0, 0, 30)
			nextLevelLabel.Position = UDim2.new(0, 0, 0, 270)
			nextLevelLabel.BackgroundTransparency = 1
			nextLevelLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
			nextLevelLabel.Font = Enum.Font.SourceSansSemibold
			nextLevelLabel.TextSize = 18
			nextLevelLabel.Text = "Siguiente nivel: " .. levelConfig.NAME
			nextLevelLabel.Parent = levelPanel
		end
	else
		local gameCompletedLabel = Instance.new("TextLabel")
		gameCompletedLabel.Size = UDim2.new(1, 0, 0, 30)
		gameCompletedLabel.Position = UDim2.new(0, 0, 0, 270)
		gameCompletedLabel.BackgroundTransparency = 1
		gameCompletedLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		gameCompletedLabel.Font = Enum.Font.SourceSansBold
		gameCompletedLabel.TextSize = 24
		gameCompletedLabel.Text = "¡HAS COMPLETADO EL JUEGO!"
		gameCompletedLabel.Parent = levelPanel
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
	continueButton.Parent = levelPanel

	-- Funcionalidad del botón
	continueButton.MouseButton1Click:Connect(function()
		levelScreen:Destroy()

		if gm.playerManager.progression.currentLevel ~= "COMPLETED_GAME" then
			-- Continuar al siguiente nivel
			gm:setupEncounter()
		else
			-- Mostrar pantalla de fin de juego
			gm.gameState.battleResult = "COMPLETE"
			gm:changePhase("GAME_OVER")
		end
	end)

	-- Mostrar pantalla
	local player = Players.LocalPlayer
	if player then
		levelScreen.Parent = player:WaitForChild("PlayerGui")
	else
		warn("No se pudo encontrar el jugador local para mostrar pantalla de nivel completado")
	end

	return levelScreen
end

-- Muestra la pantalla de fin de juego
function UIManager:showGameOverScreen(result)
	local gm = self.gameplayManager

	-- Pantalla de fin de juego
	local gameOverScreen = Instance.new("ScreenGui")
	gameOverScreen.Name = "PeglinRPG_GameOver"

	-- Fondo
	local background = Instance.new("Frame")
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.3
	background.Parent = gameOverScreen

	-- Panel principal
	local mainPanel = Instance.new("Frame")
	mainPanel.Size = UDim2.new(0, 600, 0, 400)
	mainPanel.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mainPanel.BorderSizePixel = 2
	mainPanel.Parent = gameOverScreen

	-- Título
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 80)
	titleLabel.BackgroundColor3 = result == "COMPLETE" and Color3.fromRGB(60, 100, 60) or (result == "WIN" and Color3.fromRGB(60, 60, 100) or Color3.fromRGB(100, 60, 60))
	titleLabel.BorderSizePixel = 0
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextSize = 36

	if result == "COMPLETE" then
		titleLabel.Text = "¡JUEGO COMPLETADO!"
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	elseif result == "WIN" then
		titleLabel.Text = "¡VICTORIA!"
		titleLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		titleLabel.Text = "FIN DEL JUEGO"
		titleLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end

	titleLabel.Parent = mainPanel

	-- Mensaje
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -100, 0, 120)
	messageLabel.Position = UDim2.new(0.5, -250, 0, 100)
	messageLabel.BackgroundTransparency = 1
	messageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	messageLabel.Font = Enum.Font.SourceSans
	messageLabel.TextSize = 18
	messageLabel.TextWrapped = true

	if result == "COMPLETE" then
		messageLabel.Text = "¡Felicidades! Has completado todos los niveles de Peglin RPG. ¡Eres un verdadero maestro de los orbes!"
	elseif result == "WIN" then
		messageLabel.Text = "Has derrotado a todos los enemigos en este encuentro. ¡Bien hecho!"
	else
		messageLabel.Text = "Has sido derrotado. Los enemigos han prevalecido esta vez, pero puedes intentarlo de nuevo."
	end

	messageLabel.Parent = mainPanel

	-- Estadísticas finales
	local statsTitle = Instance.new("TextLabel")
	statsTitle.Size = UDim2.new(1, 0, 0, 30)
	statsTitle.Position = UDim2.new(0, 0, 0, 230)
	statsTitle.BackgroundTransparency = 1
	statsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	statsTitle.Font = Enum.Font.SourceSansSemibold
	statsTitle.TextSize = 20
	statsTitle.Text = "Estadísticas Finales:"
	statsTitle.Parent = mainPanel

	-- Lista de estadísticas
	local statsPanel = Instance.new("Frame")
	statsPanel.Size = UDim2.new(0.8, 0, 0, 100)
	statsPanel.Position = UDim2.new(0.1, 0, 0, 260)
	statsPanel.BackgroundTransparency = 1
	statsPanel.Parent = mainPanel

	-- Nivel del jugador
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Size = UDim2.new(0.5, 0, 0, 25)
	levelLabel.Position = UDim2.new(0, 0, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	levelLabel.Font = Enum.Font.SourceSans
	levelLabel.TextSize = 16
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = "Nivel alcanzado: " .. gm.playerManager.stats.level
	levelLabel.Parent = statsPanel

	-- Oro acumulado
	local goldLabel = Instance.new("TextLabel")
	goldLabel.Size = UDim2.new(0.5, 0, 0, 25)
	goldLabel.Position = UDim2.new(0.5, 0, 0, 0)
	goldLabel.BackgroundTransparency = 1
	goldLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	goldLabel.Font = Enum.Font.SourceSans
	goldLabel.TextSize = 16
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left
	goldLabel.Text = "Oro acumulado: " .. gm.playerManager.stats.gold
	goldLabel.Parent = statsPanel

	-- Orbes obtenidos
	local orbsCount = 0
	for _, orb in ipairs(gm.playerManager.inventory.orbs) do
		orbsCount = orbsCount + orb.count
	end

	local orbsLabel = Instance.new("TextLabel")
	orbsLabel.Size = UDim2.new(0.5, 0, 0, 25)
	orbsLabel.Position = UDim2.new(0, 0, 0, 30)
	orbsLabel.BackgroundTransparency = 1
	orbsLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
	orbsLabel.Font = Enum.Font.SourceSans
	orbsLabel.TextSize = 16
	orbsLabel.TextXAlignment = Enum.TextXAlignment.Left
	orbsLabel.Text = "Orbes obtenidos: " .. orbsCount
	orbsLabel.Parent = statsPanel

	-- Reliquias encontradas
	local relicsLabel = Instance.new("TextLabel")
	relicsLabel.Size = UDim2.new(0.5, 0, 0, 25)
	relicsLabel.Position = UDim2.new(0.5, 0, 0, 30)
	relicsLabel.BackgroundTransparency = 1
	relicsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	relicsLabel.Font = Enum.Font.SourceSans
	relicsLabel.TextSize = 16
	relicsLabel.TextXAlignment = Enum.TextXAlignment.Left
	relicsLabel.Text = "Reliquias encontradas: " .. #gm.playerManager.inventory.relics
	relicsLabel.Parent = statsPanel

	-- Botones
	local buttonsPanel = Instance.new("Frame")
	buttonsPanel.Size = UDim2.new(1, 0, 0, 50)
	buttonsPanel.Position = UDim2.new(0, 0, 1, -70)
	buttonsPanel.BackgroundTransparency = 1
	buttonsPanel.Parent = mainPanel

	-- Botón de reiniciar
	local restartButton = Instance.new("TextButton")
	restartButton.Size = UDim2.new(0, 180, 0, 40)
	restartButton.Position = UDim2.new(0.5, -190, 0, 0)
	restartButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	restartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	restartButton.Font = Enum.Font.SourceSansBold
	restartButton.TextSize = 16
	restartButton.Text = "Reiniciar Juego"
	restartButton.Parent = buttonsPanel

	-- Botón de salir
	local exitButton = Instance.new("TextButton")
	exitButton.Size = UDim2.new(0, 180, 0, 40)
	exitButton.Position = UDim2.new(0.5, 10, 0, 0)
	exitButton.BackgroundColor3 = Color3.fromRGB(100, 60, 60)
	exitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	exitButton.Font = Enum.Font.SourceSansBold
	exitButton.TextSize = 16
	exitButton.Text = "Salir"
	exitButton.Parent = buttonsPanel

	-- Funcionalidad de los botones
	restartButton.MouseButton1Click:Connect(function()
		gameOverScreen:Destroy()
		gm:startNewGame()
	end)

	exitButton.MouseButton1Click:Connect(function()
		gameOverScreen:Destroy()
		-- Aquí podrías implementar lógica para volver al menú principal
		-- o cualquier otra acción de "salida"
	end)

	-- Mostrar pantalla
	local player = Players.LocalPlayer
	if player then
		gameOverScreen.Parent = player:WaitForChild("PlayerGui")
	else
		warn("No se pudo encontrar el jugador local para mostrar pantalla de fin de juego")
	end

	return gameOverScreen
end

return UIManager