-- ServiceLocator.lua
-- Sistema de inyección de dependencias para PeglinRPG
-- Permite registrar y obtener servicios en toda la aplicación

local ServiceLocator = {}
local services = {}

-- Registra un servicio en el localizador
function ServiceLocator:RegisterService(serviceName, serviceInstance)
    if services[serviceName] then
        warn("ServiceLocator: Sobrescribiendo servicio existente: " .. serviceName)
    end
    
    services[serviceName] = serviceInstance
    print("ServiceLocator: Servicio registrado: " .. serviceName)
    return serviceInstance
end

-- Obtiene un servicio del localizador
function ServiceLocator:GetService(serviceName)
    local service = services[serviceName]
    
    if not service then
        warn("ServiceLocator: Servicio no encontrado: " .. serviceName)
        return nil
    end
    
    return service
end

-- Devuelve todos los servicios registrados
function ServiceLocator:GetAllServices()
    return services
end

-- Comprueba si un servicio está registrado
function ServiceLocator:HasService(serviceName)
    return services[serviceName] ~= nil
end

-- Inicia todos los servicios que implementan el método Initialize
function ServiceLocator:InitializeAll()
    for name, service in pairs(services) do
        if type(service) == "table" and type(service.Initialize) == "function" then
            local success, error = pcall(function()
                service:Initialize()
            end)
            
            if not success then
                warn("ServiceLocator: Error al inicializar servicio " .. name .. ": " .. tostring(error))
            else
                print("ServiceLocator: Servicio inicializado: " .. name)
            end
        end
    end
end

-- Limpia todos los servicios que implementan el método Cleanup
function ServiceLocator:CleanupAll()
    for name, service in pairs(services) do
        if type(service) == "table" and type(service.Cleanup) == "function" then
            local success, error = pcall(function()
                service:Cleanup()
            end)
            
            if not success then
                warn("ServiceLocator: Error al limpiar servicio " .. name .. ": " .. tostring(error))
            else
                print("ServiceLocator: Servicio limpiado: " .. name)
            end
        end
    end
    
    -- Limpiar la tabla de servicios
    services = {}
end

return ServiceLocator