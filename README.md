# PeglinRPG

Una adaptación para Roblox del popular juego roguelike de pachinko "Peglin". Este juego combina la satisfactoria mecánica del pachinko con elementos RPG, donde los jugadores lanzan orbes a un tablero lleno de clavijas para dañar a los enemigos y avanzar a través de diversos encuentros.

## Tabla de Contenidos

1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Módulos Principales](#módulos-principales)
3. [Sistema de Tablero](#sistema-de-tablero)
4. [Flujo de Juego](#flujo-de-juego)
5. [Configuración](#configuración)
6. [Estructura del Proyecto](#estructura-del-proyecto)
7. [Problemas Conocidos y Soluciones](#problemas-conocidos-y-soluciones)
8. [Plan de Refactorización](#plan-de-refactorización)
9. [Mejoras Futuras](#mejoras-futuras)

## Arquitectura del Sistema

PeglinRPG sigue una arquitectura modular donde las funcionalidades están separadas en módulos específicos con responsabilidades claras. Los componentes principales son:

- **GameplayManager**: Coordinador central para el flujo general del juego
- **BoardManager**: Gestiona el tablero de pachinko y sus elementos
- **PlayerManager**: Maneja los datos del jugador, inventario y progresión
- **EnemyManager**: Controla el comportamiento de los enemigos y mecánicas de combate
- **OrbManager**: Gestiona los diferentes tipos de orbes y sus efectos
- **UIManager**: Maneja todos los elementos de la interfaz de usuario

## Módulos Principales

### GameplayManager

El coordinador central que conecta todos los demás gestores. Controla:
- Fases del juego (turno del jugador, turno del enemigo, etc.)
- Flujo de combate
- Manejo de eventos
- Transiciones de escena

```lua
-- Ejemplo de inicio de un nuevo juego
local gameManager = GameplayManager.new()
gameManager:startNewGame()
```

### PlayerManager

Gestiona todos los datos relacionados con el jugador incluyendo:
- Salud y estadísticas
- Inventario (orbes, reliquias)
- Seguimiento de progresión
- Experiencia y nivelación

```lua
-- Ejemplo de añadir un orbe al inventario del jugador
playerManager:addOrb("FIRE")
```

### EnemyManager

Controla los enemigos en combate:
- Estadísticas y comportamiento del enemigo
- Patrones de ataque
- Efectos de estado
- Representación visual

```lua
-- Ejemplo de crear un enemigo
local enemyManager = EnemyManager.new("GOBLIN", false)
```

### OrbManager

Maneja los orbes que los jugadores lanzan:
- Tipos y propiedades de los orbes
- Selección y agrupación de orbes
- Física y efectos de los orbes

```lua
-- Ejemplo de crear un orbe visual
local orbVisual = orbManager:createOrbVisual(orbData, position)
```

## Sistema de Tablero

El sistema de tablero ha sido modularizado para una mejor mantenibilidad. Consiste en:

### BoardManager

El coordinador principal que utiliza factorías y manejadores especializados:

```lua
-- Ejemplo de generación de un tablero
boardManager:generateBoard(width, height, pegCount, options)
```

### Módulos del Tablero

Ubicados en `ReplicatedStorage/PeglinRPG/Board/`:

- **PegFactory**: Crea y gestiona clavijas (estándar, esférica, crítica)
- **BorderFactory**: Construye bordes y paneles de vidrio
- **ObstacleManager**: Maneja obstáculos especiales (bumpers, paredes, zonas)
- **ThemeDecorator**: Añade decoraciones específicas del tema
- **EntryPointFactory**: Crea el punto de lanzamiento del orbe
- **CollisionHandler**: Procesa colisiones y eventos físicos

## Flujo de Juego

1. **Inicialización del Juego**:
   - Se cargan o crean los datos del jugador
   - Se configura la UI
   - Se prepara el primer encuentro

2. **Configuración del Encuentro**:
   - Se genera el enemigo
   - Se crea el tablero con el tema apropiado
   - Se inicializa el pool de orbes

3. **Turno del Jugador**:
   - El jugador selecciona la dirección para lanzar el orbe
   - El orbe rebota en el tablero
   - El daño se calcula basado en las clavijas golpeadas
   - Si se usan todos los orbes, el turno termina

4. **Turno del Enemigo**:
   - El enemigo selecciona un ataque
   - Se reproduce la animación del ataque
   - Se aplica el daño al jugador
   - El turno vuelve al jugador

5. **Victoria/Derrota**:
   - Si el enemigo es derrotado, se entregan recompensas
   - Si el jugador es derrotado, aparece la pantalla de fin de juego
   - Después de la victoria, se avanza al siguiente encuentro

## Configuración

Los parámetros del juego están centralizados en `Config.lua`:

### Secciones Principales de Configuración

- `Config.GAME`: Configuraciones básicas del juego
- `Config.PHYSICS`: Parámetros físicos para los orbes
- `Config.BOARD`: Dimensiones y propiedades del tablero
- `Config.COMBAT`: Mecánicas de combate
- `Config.ORBS`: Tipos de orbes y sus propiedades
- `Config.ENEMIES`: Definiciones de enemigos
- `Config.RELICS`: Propiedades de los objetos reliquia
- `Config.LEVELS`: Temas y propiedades de los niveles
- `Config.BOARD_ELEMENTS`: Configuraciones de obstáculos especiales
- `Config.PEG_TYPES`: Diferentes configuraciones de clavijas
- `Config.EFFECTS`: Parámetros de efectos visuales

Ejemplo:
```lua
-- Cambiar el tamaño del tablero
Config.BOARD = {
    WIDTH = 60,
    HEIGHT = 70,
    DEFAULT_PEG_COUNT = 120,
    MIN_PEG_DISTANCE = 3.2,
}
```

## Estructura del Proyecto

El proyecto sigue una estructura modular con clara separación de responsabilidades. Aquí está la estructura completa de archivos:

```
src/
├── ReplicatedStorage/
│   ├── PeglinRPG/
│   │   ├── Board/
│   │   │   ├── BorderFactory.lua        # Crea bordes y paneles de vidrio
│   │   │   ├── CollisionHandler.lua     # Maneja eventos de colisión
│   │   │   ├── EntryPointFactory.lua    # Crea puntos de lanzamiento de orbes
│   │   │   ├── ObstacleManager.lua      # Gestiona obstáculos especiales
│   │   │   ├── PegFactory.lua           # Crea y gestiona clavijas
│   │   │   └── ThemeDecorator.lua       # Añade decoraciones específicas del tema
│   │   │
│   │   ├── Gameplay/
│   │   │   ├── CombatManager.lua        # Gestiona mecánicas de combate
│   │   │   ├── EffectsManager.lua       # Controla efectos visuales
│   │   │   ├── PhaseManager.lua         # Maneja fases del juego
│   │   │   ├── RewardManager.lua        # Distribuye recompensas
│   │   │   ├── UIManager.lua            # Controla la interfaz de usuario
│   │   │   └── init.meta.json           # Metadatos del módulo
│   │   │
│   │   ├── BoardManager.lua             # Coordina la creación del tablero
│   │   ├── Config.lua                   # Configuración central
│   │   ├── EnemyManager.lua             # Gestiona enemigos
│   │   ├── GameplayManager.lua          # Coordinador principal del juego
│   │   ├── OrbManager.lua               # Gestiona creación y comportamiento de orbes
│   │   ├── PeglinLauncher.lua           # Punto de entrada del juego
│   │   ├── PeglinRPG_Initializer.lua    # Inicializa la estructura del juego
│   │   ├── PlayerManager.lua            # Gestiona datos del jugador
│   │   └── init.meta.json               # Metadatos del módulo
│   │
│   └── Shared/
│       ├── Hello.lua                    # Módulo compartido de ejemplo
│       └── init.meta.json               # Metadatos del módulo
│
├── ServerScriptService/
│   └── PeglinLauncher.server.lua        # Punto de entrada del servidor
│
└── StarterPlayer/
    └── StarterPlayerScripts/
        └── PeglinClient.client.lua      # Controlador del cliente
```

## Problemas Conocidos y Soluciones

### Problemas físicos y de comportamiento:

1. **Orbes que se atascan en obstáculos**
   - *Solución implementada*: Sistema de detección y liberación automática en `CollisionHandler.lua`
   - *Propiedades físicas mejoradas* en `OrbManager.lua` y `Config.lua`

2. **Orbes que se salen del tablero**
   - *Solución implementada*: Bordes y contenedores mejorados en `BorderFactory.lua`
   - *Sistema anti-fuga* con límites externos invisibles

3. **Lanzamientos sin daño**
   - *Solución implementada*: Sistema de daño mínimo garantizado en `CombatManager.lua`
   - Asegura que cada lanzamiento cause algún daño, incluso si no golpea ninguna clavija

4. **Problemas de carga de módulos**
   - *Solución implementada*: Manejo mejorado de errores y verificaciones de nil en `GameplayManager.lua`
   - Sistema de recuperación para componentes faltantes o corruptos

## Plan de Refactorización

Para mejorar la modularidad y el mantenimiento del código, se propone el siguiente plan de refactorización:

### 1. Implementar Arquitectura por Servicios

Reorganizar el código siguiendo un patrón de Servicios:

```lua
-- Estructura de servicios propuesta
src/
├── ReplicatedStorage/
│   ├── PeglinRPG/
│   │   ├── Services/               # Nuevo nivel de organización
│   │   │   ├── BoardService/       # Todo lo relacionado con el tablero
│   │   │   ├── CombatService/      # Servicios de combate 
│   │   │   ├── PlayerService/      # Gestión del jugador
│   │   │   ├── EnemyService/       # Gestión de enemigos
│   │   │   ├── PhysicsService/     # Simulación física independiente
│   │   │   ├── VisualService/      # Efectos visuales y feedback
│   │   │   └── UIService/          # Interfaces de usuario
```

### 2. Implementar Inyección de Dependencias

Crear un sistema de inyección de dependencias:

```lua
-- Ejemplo de cómo funciona el sistema de inyección de dependencias
local ServiceLocator = {}
local services = {}

function ServiceLocator:RegisterService(serviceName, serviceInstance)
    services[serviceName] = serviceInstance
end

function ServiceLocator:GetService(serviceName)
    return services[serviceName]
end

-- Uso:
local boardService = ServiceLocator:GetService("BoardService")
```

### 3. Mejorar el Sistema de Eventos

Implementar un bus de eventos centralizado:

```lua
-- Sistema de eventos mejorado
local EventBus = {}
local subscribers = {}

function EventBus:Subscribe(eventName, callback)
    if not subscribers[eventName] then
        subscribers[eventName] = {}
    end
    table.insert(subscribers[eventName], callback)
    
    -- Devolver una función para cancelar la suscripción
    return function() 
        self:Unsubscribe(eventName, callback) 
    end
end

function EventBus:Publish(eventName, ...)
    local eventSubscribers = subscribers[eventName]
    if eventSubscribers then
        for _, callback in ipairs(eventSubscribers) do
            callback(...)
        end
    end
end

function EventBus:Unsubscribe(eventName, callback)
    local eventSubscribers = subscribers[eventName]
    if eventSubscribers then
        for i, subscribedCallback in ipairs(eventSubscribers) do
            if subscribedCallback == callback then
                table.remove(eventSubscribers, i)
                break
            end
        end
    end
end
```

### 4. Mejorar el Manejo de Estado

Implementar un patrón similar a Flux/Redux para la gestión de estado:

```lua
-- Sistema de estado centralizado
local Store = {}
Store.__index = Store

function Store.new(initialState, reducer)
    local self = setmetatable({}, Store)
    self.state = initialState or {}
    self.reducer = reducer
    self.listeners = {}
    return self
end

function Store:GetState()
    return self.state
end

function Store:Dispatch(action)
    self.state = self.reducer(self.state, action)
    self:NotifyListeners()
end

function Store:Subscribe(listener)
    table.insert(self.listeners, listener)
    
    -- Devolver una función para cancelar la suscripción
    return function()
        for i, l in ipairs(self.listeners) do
            if l == listener then
                table.remove(self.listeners, i)
                break
            end
        end
    end
end

function Store:NotifyListeners()
    for _, listener in ipairs(self.listeners) do
        listener(self.state)
    end
end
```

### 5. Implementar Testing Automático

Crear una estructura de pruebas unitarias:

```lua
-- Framework de testing simple
local TestRunner = {}

function TestRunner:RunTests(tests)
    local passCount, failCount = 0, 0
    
    for testName, testFunc in pairs(tests) do
        local success, errorMsg = pcall(testFunc)
        
        if success then
            print("✓ " .. testName)
            passCount = passCount + 1
        else
            print("✗ " .. testName .. ": " .. errorMsg)
            failCount = failCount + 1
        end
    end
    
    print("Resultados: " .. passCount .. " pasados, " .. failCount .. " fallados")
end

-- Ejemplo de uso:
TestRunner:RunTests({
    ["La salud del jugador debe inicializarse correctamente"] = function()
        local playerManager = PlayerManager.new()
        assert(playerManager.stats.health == Config.COMBAT.PLAYER_STARTING_HEALTH, 
               "La salud inicial no coincide con la configuración")
    end
})
```

### 6. Implementar Ciclo de Vida de los Módulos

Establecer métodos de ciclo de vida estándar para todos los módulos:

```lua
-- Interface de ciclo de vida para los módulos
local ModuleInterface = {}
ModuleInterface.__index = ModuleInterface

function ModuleInterface.new()
    local self = setmetatable({}, ModuleInterface)
    return self
end

function ModuleInterface:Initialize()
    -- Configuración inicial
end

function ModuleInterface:Start()
    -- Comenzar funcionalidad
end

function ModuleInterface:Update(deltaTime)
    -- Actualización por frame
end

function ModuleInterface:Cleanup()
    -- Limpieza de recursos
end
```

## Mejoras Futuras

- **Nuevos Tipos de Orbes**: Añadir más orbes especializados con efectos únicos
- **Enemigos Adicionales**: Expandir el roster de enemigos con nuevos patrones de ataque
- **Elementos del Tablero**: Más obstáculos interactivos como clavijas móviles y teletransportadores
- **Generación Procedural de Niveles**: Diseños dinámicos de tablero basados en la dificultad
- **Sistema de Logros**: Metas y recompensas dentro del juego
- **Soporte para Dispositivos Móviles**: Optimización de controles táctiles
- **Modo Multijugador**: Opciones de juego PvP o cooperativo
- **Sistema de Guardado de Progreso**: Persistencia de datos del jugador

---

## Próximos Pasos para la Refactorización

1. Comenzar con la creación del sistema de Servicios y ServiceLocator
2. Migrar BoardManager a BoardService manteniendo compatibilidad con versiones anteriores
3. Implementar EventBus para desacoplar las comunicaciones entre servicios
4. Migrar GameplayManager para usar el nuevo sistema de servicios
5. Implementar tests unitarios comenzando por los módulos más críticos
6. Migrar progresivamente los restantes gestores al nuevo sistema de servicios
7. Documentar los nuevos patrones y estructuras de código

Creado por el equipo de desarrollo de PeglinRPG. Última actualización: Marzo 2025.