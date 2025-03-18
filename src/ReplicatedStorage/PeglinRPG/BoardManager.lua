-- BoardManager.lua: Clase base para gestionar el tablero de juego
-- Actúa como punto de entrada principal y coordinador

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Config"))

-- Importar módulos de elementos del tablero
local PegFactory = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("PegFactory"))
local BorderFactory = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("BorderFactory"))
local ObstacleManager = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("ObstacleManager"))
local ThemeDecorator = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("ThemeDecorator"))
local EntryPointFactory = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("EntryPointFactory"))
local CollisionHandler = require(ReplicatedStorage:WaitForChild("PeglinRPG"):WaitForChild("Board"):WaitForChild("CollisionHandler"))

local BoardManager = {}
BoardManager.__index = BoardManager

-- Constructor del gestor de tablero
function BoardManager.new()
	local self = setmetatable({}, BoardManager)

	-- Propiedades
	self.currentBoard = nil
	self.pegCount = 0
	self.criticalPegCount = 0
	self.activeBoard = nil
	self.pegs = {}
	self.entryPoints = {} -- Para almacenar múltiples puntos de entrada

	-- Inicializar submódulos
	self.pegFactory = PegFactory.new(self)
	self.borderFactory = BorderFactory.new(self)
	self.obstacleManager = ObstacleManager.new(self)
	self.themeDecorator = ThemeDecorator.new(self)
	self.entryPointFactory = EntryPointFactory.new(self)
	self.collisionHandler = CollisionHandler.new(self)

	return self
end

-- Genera un nuevo tablero de juego
function BoardManager:generateBoard(width, height, pegCount, options)
	-- Limpiar tablero existente si lo hay
	if self.currentBoard then
		self.currentBoard:Destroy()
	end

	-- Opciones por defecto
	options = options or {}
	local theme = options.theme or "FOREST" -- Asegurar que siempre haya un tema
	local pegColors = options.pegColors or {
		BrickColor.new("Bright blue"),
		BrickColor.new("Cyan"),
		BrickColor.new("Royal blue")
	}
	local backgroundColor = options.backgroundColor or Color3.fromRGB(30, 30, 50)

	-- Imprimir información de depuración
	print("BoardManager: Generando tablero...")
	print("Dimensiones:", width, height)
	print("Tema:", theme)

	-- Crear contenedor para el tablero
	local board = Instance.new("Folder")
	board.Name = "PeglinBoard_" .. theme

	-- Registrar tablero actual
	self.currentBoard = board
	self.pegs = {}

	-- Crear fondo del tablero
	local background = Instance.new("Part")
	background.Size = Vector3.new(width + 4, height + 4, 1)
	background.Position = Vector3.new(0, 0, 0.5)
	background.Anchored = true
	background.CanCollide = false
	background.Transparency = 0.3
	background.Color = backgroundColor
	background.Material = Enum.Material.SmoothPlastic
	background.Parent = board

	-- Crear bordes usando BorderFactory
	self.borderFactory:createBorders(board, width, height, theme)

	-- Generar clavijas usando PegFactory
	self.pegFactory:generatePegs(board, width, height, pegCount, pegColors, theme)
	
	-- Añadir obstáculos especiales usando ObstacleManager
	-- Envolvemos en pcall para evitar que los errores interrumpan la generación
	pcall(function()
		self.obstacleManager:addSpecialObstacles(board, width, height, theme)
	end)

	-- Añadir decoraciones temáticas usando ThemeDecorator
	self.themeDecorator:addThemeDecorations(board, theme, width, height)

	-- Crear puntos de entrada usando EntryPointFactory (actualizado para múltiples puntos)
	self.entryPoints = self.entryPointFactory:createEntryPoints(board, width, height, theme)

	-- Posicionar el tablero en el mundo
	board.Parent = workspace

	return board
end

-- Registra un golpe en una clavija (delegado a CollisionHandler)
function BoardManager:registerPegHit(pegPart)
	return self.collisionHandler:registerPegHit(pegPart)
end

-- Maneja colisiones con elementos especiales (delegado a CollisionHandler)
function BoardManager:handleSpecialCollisions(orbPart, contactPoint)
	return self.collisionHandler:handleSpecialCollisions(orbPart, contactPoint)
end

-- Devuelve estadísticas del tablero actual
function BoardManager:getBoardStats()
	return {
		totalPegs = self.pegCount,
		criticalPegs = self.criticalPegCount,
		pegsHit = 0, -- Esto se actualizaría durante el juego
		boardWidth = self.currentBoard and self.currentBoard.Size.X or 0,
		boardHeight = self.currentBoard and self.currentBoard.Size.Y or 0
	}
end

return BoardManager