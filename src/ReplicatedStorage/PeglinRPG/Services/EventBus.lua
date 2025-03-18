-- EventBus.lua
-- Sistema centralizado de eventos para PeglinRPG
-- Permite comunicación desacoplada entre distintos servicios

local EventBus = {}
local subscribers = {}

-- Suscribe una función a un evento
-- Retorna una función para cancelar la suscripción
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

-- Publica un evento con cualquier número de parámetros
function EventBus:Publish(eventName, ...)
    local args = {...} -- Capturar argumentos variádicos en una tabla
    local eventSubscribers = subscribers[eventName]
    if not eventSubscribers then
        return -- No hay suscriptores para este evento
    end
    
    -- Llamar a cada suscriptor con los parámetros proporcionados
    for _, callback in ipairs(eventSubscribers) do
        local success, error = pcall(function()
            callback(unpack(args)) -- Usar unpack para pasar los argumentos
        end)
        
        if not success then
            warn("EventBus: Error al ejecutar suscriptor para evento '" .. eventName .. "': " .. tostring(error))
        end
    end
end

-- Cancela la suscripción de una función a un evento
function EventBus:Unsubscribe(eventName, callback)
    local eventSubscribers = subscribers[eventName]
    if not eventSubscribers then
        return -- No hay suscriptores para este evento
    end
    
    for i, subscribedCallback in ipairs(eventSubscribers) do
        if subscribedCallback == callback then
            table.remove(eventSubscribers, i)
            break
        end
    end
    
    -- Si no quedan suscriptores, eliminar la entrada del evento
    if #eventSubscribers == 0 then
        subscribers[eventName] = nil
    end
end

-- Elimina todos los suscriptores de un evento específico
function EventBus:ClearEvent(eventName)
    subscribers[eventName] = nil
end

-- Elimina todos los suscriptores de todos los eventos
function EventBus:ClearAll()
    subscribers = {}
end

-- Obtiene el número de suscriptores para un evento
function EventBus:GetSubscriberCount(eventName)
    local eventSubscribers = subscribers[eventName]
    if not eventSubscribers then
        return 0
    end
    
    return #eventSubscribers
end

return EventBus