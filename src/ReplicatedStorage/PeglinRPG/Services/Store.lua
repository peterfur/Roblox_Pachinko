-- Store.lua
-- Sistema de gestión de estado inspirado en Flux/Redux para PeglinRPG
-- Proporciona un flujo unidireccional de datos y estado predecible

local Store = {}
Store.__index = Store

-- Crea una nueva instancia de Store
-- initialState: estado inicial (tabla)
-- reducer: función que recibe (state, action) y devuelve nuevo estado
function Store.new(initialState, reducer)
    local self = setmetatable({}, Store)
    self.state = initialState or {}
    self.reducer = reducer
    self.listeners = {}
    return self
end

-- Obtiene el estado actual
function Store:GetState()
    return self.state
end

-- Despacha una acción para modificar el estado
-- action: tabla con type y payload opcionales {type = "ACTION_TYPE", payload = {...}}
function Store:Dispatch(action)
    if type(action) ~= "table" or not action.type then
        error("Store: La acción debe ser una tabla con una propiedad 'type'")
    end
    
    -- Aplicar el reducer para obtener el nuevo estado
    local newState = self.reducer(self.state, action)
    
    -- Validar que el reducer devolvió un nuevo estado
    if type(newState) ~= "table" then
        error("Store: El reducer debe devolver una tabla")
    end
    
    -- Actualizar el estado
    self.state = newState
    
    -- Notificar a los suscriptores
    self:NotifyListeners()
end

-- Suscribe una función para recibir actualizaciones cuando cambia el estado
-- Retorna una función para cancelar la suscripción
function Store:Subscribe(listener)
    if type(listener) ~= "function" then
        error("Store: El suscriptor debe ser una función")
    end
    
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

-- Notifica a todos los suscriptores del cambio de estado
function Store:NotifyListeners()
    for _, listener in ipairs(self.listeners) do
        local success, error = pcall(function()
            listener(self.state)
        end)
        
        if not success then
            warn("Store: Error al notificar a un suscriptor: " .. tostring(error))
        end
    end
end

-- Crea un selector para acceder a partes específicas del estado
function Store:CreateSelector(selectorFn)
    return function()
        return selectorFn(self.state)
    end
end

return Store