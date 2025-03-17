# PeglinRPG

A Roblox adaptation of the popular roguelike pachinko game "Peglin". This game combines the satisfying gameplay of pachinko with RPG elements, where players launch orbs into a board filled with pegs to damage enemies and progress through encounters.

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Core Modules](#core-modules)
3. [Board System](#board-system)
4. [Gameplay Flow](#gameplay-flow)
5. [Configuration](#configuration)
6. [Project Structure](#project-structure)
7. [Known Issues](#known-issues)
8. [Future Enhancements](#future-enhancements)

## System Architecture

PeglinRPG follows a modular architecture where functionalities are separated into specific modules with clear responsibilities. The main components are:

- **GameplayManager**: Central coordinator for the overall game flow
- **BoardManager**: Manages the pachinko board and its elements
- **PlayerManager**: Handles player data, inventory, and progression
- **EnemyManager**: Controls enemy behavior and combat mechanics
- **OrbManager**: Manages the different types of orbs and their effects
- **UIManager**: Handles all user interface elements

## Core Modules

### GameplayManager

The central coordinator that ties together all other managers. It controls:
- Game phases (player turn, enemy turn, etc.)
- Combat flow
- Event handling
- Scene transitions

```lua
-- Example of starting a new game
local gameManager = GameplayManager.new()
gameManager:startNewGame()
```

### PlayerManager

Manages all player-related data including:
- Health and stats
- Inventory (orbs, relics)
- Progression tracking
- Experience and leveling

```lua
-- Example of adding an orb to player inventory
playerManager:addOrb("FIRE")
```

### EnemyManager

Controls enemies in combat:
- Enemy stats and behavior
- Attack patterns
- Status effects
- Visual representation

```lua
-- Example of creating an enemy
local enemyManager = EnemyManager.new("GOBLIN", false)
```

### OrbManager

Handles the orbs that players launch:
- Orb types and properties
- Orb selection and pooling
- Orb physics and effects

```lua
-- Example of creating an orb
local orbVisual = orbManager:createOrbVisual(orbData, position)
```

## Board System

The board system has been modularized for better maintainability. It consists of:

### BoardManager

The main coordinator that uses specialized factories and handlers:

```lua
-- Example of generating a board
boardManager:generateBoard(width, height, pegCount, options)
```

### Board Modules

Located in `ReplicatedStorage/PeglinRPG/Board/`:

- **PegFactory**: Creates and manages pegs (standard, ball, critical)
- **BorderFactory**: Builds borders and glass panels
- **ObstacleManager**: Handles special obstacles (bumpers, walls, zones)
- **ThemeDecorator**: Adds theme-specific decorations
- **EntryPointFactory**: Creates the orb launch point
- **CollisionHandler**: Processes collisions and physics events

## Gameplay Flow

1. **Game Initialization**:
   - Player data is loaded or created
   - UI is set up
   - First encounter is prepared

2. **Encounter Setup**:
   - Enemy is generated
   - Board is created with appropriate theme
   - Orb pool is initialized

3. **Player Turn**:
   - Player selects direction to launch orb
   - Orb bounces through the board
   - Damage is calculated based on pegs hit
   - If all orbs are used, turn ends

4. **Enemy Turn**:
   - Enemy selects an attack
   - Attack animation plays
   - Damage is applied to player
   - Turn returns to player

5. **Victory/Defeat**:
   - If enemy is defeated, rewards are given
   - If player is defeated, game over screen appears
   - After victory, progress to next encounter

## Configuration

Game parameters are centralized in `Config.lua`:

### Major Configuration Sections

- `Config.GAME`: Basic game settings
- `Config.PHYSICS`: Physics parameters for orbs
- `Config.BOARD`: Board dimensions and properties
- `Config.COMBAT`: Combat mechanics
- `Config.ORBS`: Orb types and their properties
- `Config.ENEMIES`: Enemy definitions
- `Config.RELICS`: Relic item properties
- `Config.LEVELS`: Level themes and properties
- `Config.BOARD_ELEMENTS`: Special obstacle settings
- `Config.PEG_TYPES`: Different peg configurations
- `Config.EFFECTS`: Visual effect parameters

Example:
```lua
-- Change board size
Config.BOARD = {
    WIDTH = 60,
    HEIGHT = 70,
    DEFAULT_PEG_COUNT = 120,
    MIN_PEG_DISTANCE = 3.2,
}
```

## Project Structure

The project follows a modular structure with clear separation of concerns. Here's the complete file structure:

```
src/
├── ReplicatedStorage/
│   ├── PeglinRPG/
│   │   ├── Board/
│   │   │   ├── BorderFactory.lua        # Creates borders and glass panels
│   │   │   ├── CollisionHandler.lua     # Handles collision events
│   │   │   ├── EntryPointFactory.lua    # Creates orb launch points
│   │   │   ├── ObstacleManager.lua      # Manages special obstacles
│   │   │   ├── PegFactory.lua           # Creates and manages pegs
│   │   │   └── ThemeDecorator.lua       # Adds theme-specific decorations
│   │   │
│   │   ├── Gameplay/
│   │   │   ├── CombatManager.lua        # Manages combat mechanics
│   │   │   ├── EffectsManager.lua       # Controls visual effects
│   │   │   ├── PhaseManager.lua         # Handles game phases
│   │   │   ├── RewardManager.lua        # Distributes rewards
│   │   │   ├── UIManager.lua            # Controls user interface
│   │   │   └── init.meta.json           # Module metadata
│   │   │
│   │   ├── BoardManager.lua             # Coordinates board creation
│   │   ├── Config.lua                   # Central configuration
│   │   ├── EnemyManager.lua             # Manages enemies
│   │   ├── GameplayManager.lua          # Primary game coordinator
│   │   ├── OrbManager.lua               # Manages orb creation and behavior
│   │   ├── PeglinLauncher.lua           # Game entry point
│   │   ├── PeglinRPG_Initializer.lua    # Initializes game structure
│   │   ├── PlayerManager.lua            # Manages player data
│   │   └── init.meta.json               # Module metadata
│   │
│   └── Shared/
│       ├── Hello.lua                    # Example shared module
│       └── init.meta.json               # Module metadata
│
├── ServerScriptService/
│   └── PeglinLauncher.server.lua        # Server entry point
│
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── PeglinClient.client.lua      # Client controller
```

### Key Directories and Files

- **ReplicatedStorage/PeglinRPG/**: Core game modules shared between server and client
  - **Board/**: Modular components for board creation and management
  - **Gameplay/**: Managers for various gameplay aspects
  - **Config.lua**: Central configuration file for all game parameters
  - **GameplayManager.lua**: Main coordinator for the game system

- **ServerScriptService/PeglinLauncher.server.lua**: Server-side entry point that initializes the game

- **StarterPlayer/StarterPlayerScripts/PeglinClient.client.lua**: Client-side controller that handles user input and renders game elements

### Module Dependencies

- **GameplayManager** depends on all other managers (BoardManager, PlayerManager, etc.)
- **BoardManager** depends on modules in the Board/ directory
- Most managers require **Config.lua** for their configuration

## Known Issues

- Orbs may occasionally get stuck between glass panels
- Some visual effects may cause performance issues on low-end devices
- Multiplier zones don't stack correctly when overlapping

## Future Enhancements

- **New Orb Types**: Adding more specialized orbs with unique effects
- **Additional Enemies**: Expanding the enemy roster with new attack patterns
- **Board Elements**: More interactive obstacles like moving pegs and teleporters
- **Procedural Level Generation**: Dynamic board layouts based on difficulty
- **Achievements System**: In-game goals and rewards
- **Mobile Support**: Touch controls optimization
- **Multiplayer Mode**: PvP or cooperative gameplay options

---

Created by [Your Name/Team]. Last updated: [Date].