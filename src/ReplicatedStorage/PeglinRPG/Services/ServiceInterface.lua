-- ServiceInterface.lua
-- Define la interfaz base para todos los servicios en PeglinRPG
-- Establece métodos de ciclo de vida estándar

local ServiceInterface = {}
ServiceInterface.__index = ServiceInterface

-- Constructor
function ServiceInterface.new()
    local self = setmetatable({}, ServiceInterface)
    self.initialized = false
    self.running = false
    return self
end

-- Inicialización del servicio
-- Este método debe ser llamado una vez antes de usar el servicio
function ServiceInterface:Initialize()
    if self.initialized then
        warn(self.Name .. ": Ya está inicializado")
        return
    end
    
    self.initialized = true
end

-- Iniciar el servicio
-- Este método puede ser llamado después de Initialize
function ServiceInterface:Start()
    if not self.initialized then
        warn(self.Name .. ": No está inicializado, llamando a Initialize primero")
        self:Initialize()
    end
    
    self.running = true
end

-- Actualizar el servicio (llamado cada frame si es necesario)
function ServiceInterface:Update(deltaTime)
    -- Implementación vacía, los servicios que necesiten actualización
    -- deben sobreescribir este método
end

-- Detener el servicio
function ServiceInterface:Stop()
    self.running = false
end

-- Limpieza del servicio
-- Este método debe ser llamado cuando ya no se necesita el servicio
function ServiceInterface:Cleanup()
    if self.running then
        self:Stop()
    end
    
    self.initialized = false
end

-- Obtener el estado del servicio
function ServiceInterface:GetStatus()
    return {
        initialized = self.initialized,
        running = self.running
    }
end

-- Método de extensión para crear un nuevo servicio que herede de ServiceInterface
function ServiceInterface:Extend(serviceName)
    local newService = {}
    newService.__index = newService
    setmetatable(newService, self)
    
    newService.Name = serviceName or "UnnamedService"
    
    return newService
end

return ServiceInterface