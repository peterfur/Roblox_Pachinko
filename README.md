# PeglinRPG - Documentación de Refactorización

## Introducción

Este documento describe la refactorización completa de la arquitectura de PeglinRPG, siguiendo el plan establecido en el archivo README original. El objetivo principal ha sido transformar la estructura basada en "Manager" a una arquitectura orientada a servicios con mejor mantenibilidad, escalabilidad y separación de responsabilidades.

## Cambios Principales

La refactorización se ha centrado en los siguientes aspectos:

1. **Arquitectura por Servicios**: Reemplazo de los gestores monolíticos por servicios especializados.
2. **Inyección de Dependencias**: Implementación de un ServiceLocator para gestionar dependencias.
3. **Sistema de Eventos Centralizado**: Implementación de un EventBus para comunicación desacoplada.
4. **Manejo de Estado Centralizado**: Implementación de un Store inspirado en Flux/Redux.
5. **Interfaces de Servicios**: Definición de ciclos de vida estándar para todos los servicios.

## Nueva Estructura de Archivos

```
src/
├── ReplicatedStorage/
│   ├── PeglinRPG/
│   │   ├── Services/                    # Nueva carpeta para servicios
│   │   │   ├── ServiceLocator.lua       # Sistema de inyección de dependencias
│   │   │   ├── EventBus.lua             # Sistema de eventos centralizado
│   │   │   ├── Store.lua                # Sistema de manejo de estado
│   │   │   ├── ServiceInterface.lua     # Interfaz base para servicios
│   │   │   ├── BoardService/            # Servicios especializados
│   │   │   ├── CombatService/
│   │   │   ├── PlayerService/
│   │   │   ├── EnemyService/
│   │   │   ├── PhysicsService/
│   │   │   ├── VisualService/
│   │   │   ├── UIService/
│   │   │   ├── EffectsService.lua
│   │   │   ├── GameplayService.lua
│   │   │   └── ...
│   │   ├── Board/                       # Módulos específicos del tablero
│   │   │   ├── BorderFactory.lua        
│   │   │   ├── CollisionHandler.lua     
│   │   │   ├── ...
│   │   ├── ServicesLoader.lua           # Cargador de servicios centralizado
│   │   ├── Config.lua                   # Configuración central
│   │   └── PeglinRPG_Initializer.lua    # Punto de entrada refactorizado
```

## Componentes Principales

### ServiceLocator

El ServiceLocator es el sistema central de inyección de dependencias que permite:

- Registrar servicios con nombres únicos
- Obtener servicios cuando sean necesarios
- Inicializar todos los servicios de forma centralizada
- Limpiar recursos cuando sea necesario

```lua
-- Ejemplo de uso del ServiceLocator
local boardService = ServiceLocator:GetService("BoardService")
local enemyService = ServiceLocator:GetService("EnemyService")
```

### EventBus

El EventBus facilita la comunicación entre servicios, permitiendo que componentes independientes se comuniquen sin acoplamiento directo:

- Publicar eventos con cualquier número de parámetros
- Suscribirse a eventos específicos
- Cancelar suscripciones cuando no sean necesarias
- Gestionar errores en los suscriptores sin afectar al resto del sistema

```lua
-- Ejemplo de publicación de eventos
EventBus:Publish("OrbLaunched", orbVisual, orbData)

-- Ejemplo de suscripción a eventos
local unsubscribe = EventBus:Subscribe("OrbLaunched", function(orbVisual, orbData)
    -- Código para manejar el evento
end)
```

### Store

El Store proporciona un manejo de estado centralizado inspirado en Flux/Redux:

- Almacena el estado de la aplicación en una única fuente de verdad
- Modifica el estado a través de acciones y reducers
- Notifica a los suscriptores cuando el estado cambia
- Permite crear selectores para acceder a partes específicas del estado

```lua
-- Ejemplo de creación de un Store
local gameStore = Store.new(initialState, function(state, action)
    if action.type == "CHANGE_PHASE" then
        return {
            ...state,
            currentPhase = action.payload
        }
    end
    return state
end)

-- Ejemplo de dispatch de una acción
gameStore:Dispatch({
    type = "CHANGE_PHASE",
    payload = "PLAYER_TURN"
})
```

### ServiceInterface

El ServiceInterface define un ciclo de vida estándar para todos los servicios:

- `Initialize()`: Configuración inicial del servicio
- `Start()`: Activación del servicio
- `Update(deltaTime)`: Actualización por frame (si es necesario)
- `Stop()`: Detención del servicio
- `Cleanup()`: Limpieza de recursos

```lua
-- Ejemplo de creación de un servicio personalizado
local MyService = ServiceInterface:Extend("MyService")

function MyService.new(serviceLocator, eventBus)
    local self = setmetatable({}, MyService)
    self.serviceLocator = serviceLocator
    self.eventBus = eventBus
    return self
end

function MyService:Initialize()
    ServiceInterface.Initialize(self) -- Llamar al método de la clase base
    -- Código de inicialización personalizado
end
```

## Servicios Principales

### BoardService

Gestiona el tablero de juego, reemplazando al antiguo BoardManager:

- Genera y limpia el tablero
- Coordina los diferentes componentes del tablero
- Gestiona las clavijas y los puntos de entrada
- Maneja las colisiones y eventos físicos

### OrbService

Gestiona los orbes del juego, reemplazando al antiguo OrbManager:

- Crea instancias de orbes según su tipo
- Genera representaciones visuales de los orbes
- Procesa golpes contra clavijas
- Aplica efectos especiales según el tipo de orbe

### CombatService

Gestiona el sistema de combate, reemplazando al antiguo CombatManager:

- Configura la detección de colisiones para orbes
- Monitorea el estado de los orbes (si caen o se detienen)
- Aplica daño a los enemigos
- Maneja la victoria en combate

### GameplayService

Coordina el flujo general del juego, reemplazando al antiguo GameplayManager:

- Inicia nuevos juegos
- Configura encuentros
- Cambia las fases del juego
- Maneja eventos de victoria o derrota

### EffectsService

Gestiona los efectos visuales y sonoros:

- Muestra números de daño flotantes
- Crea efectos visuales según el tipo de orbe
- Muestra efectos de resurrección y victoria
- Mejora el feedback visual para el jugador

## ServicesLoader

El ServicesLoader actúa como punto de entrada para inicializar todo el sistema:

- Carga todos los servicios disponibles
- Inicializa los servicios en el orden correcto
- Inicia el juego a través del GameplayService
- Proporciona métodos para limpiar recursos cuando sea necesario

## Comparación con la Arquitectura Original

### Antes:

- Managers acoplados entre sí con referencias directas
- Comunicación a través de llamadas directas entre componentes
- Estado distribuido en múltiples managers
- Ciclo de vida inconsistente entre componentes
- Difícil de probar y modificar partes individuales

### Después:

- Servicios desacoplados que se comunican a través del EventBus
- Dependencias explícitas a través del ServiceLocator
- Estado centralizado en Stores
- Ciclo de vida estandarizado para todos los servicios
- Mayor facilidad para probar y modificar componentes individuales

## Beneficios de la Refactorización

1. **Mayor Modularidad**: Cada servicio tiene una responsabilidad única y bien definida.
2. **Mejor Testabilidad**: Los servicios pueden probarse de forma aislada con dependencias simuladas.
3. **Escalabilidad Mejorada**: Es más fácil añadir nuevas funcionalidades sin afectar al código existente.
4. **Mantenibilidad Superior**: El código es más legible y tiene una estructura más predecible.
5. **Facilidad para Depurar**: Los problemas se pueden localizar más fácilmente en servicios específicos.

## Integración con el Código Actual

Los servicios refactorizados mantienen compatibilidad con el código actual, permitiendo una migración gradual:

1. Los módulos específicos del tablero (PegFactory, BorderFactory, etc.) siguen funcionando como antes, pero ahora son coordinados por BoardService.
2. La configuración central sigue residiendo en Config.lua, permitiendo ajustes fáciles.
3. El flujo de juego sigue el mismo patrón, pero ahora está organizado de forma más modular y mantenible.

## Próximos Pasos

1. **Migración Completa**: Continuar migrando los managers restantes a la arquitectura de servicios.
2. **Tests Unitarios**: Implementar pruebas unitarias para cada servicio.
3. **Documentación Detallada**: Ampliar la documentación de la API para cada servicio.
4. **Optimización de Rendimiento**: Analizar y optimizar el rendimiento con la nueva arquitectura.
5. **Nuevas Funcionalidades**: Utilizar la nueva arquitectura para implementar las mejoras futuras mencionadas en el README original.

## Conclusión

Esta refactorización transforma PeglinRPG en un sistema más robusto, mantenible y escalable, sentando las bases para futuras mejoras y expansiones del juego. La nueva arquitectura basada en servicios facilita el desarrollo colaborativo y reduce la complejidad del código, permitiendo a los desarrolladores centrarse en crear nuevas funcionalidades en lugar de luchar con el código existente.