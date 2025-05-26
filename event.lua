local Event = {}

function Event:New()
    local obj = {
        listeners = {}
    }
    self.__index = self
    return setmetatable(obj, self)
end

-- EventObj:OnEvent("LevelCompleted", function() end)
function Event:OnEvent(name, callback)
    if not self.listeners[name] then
        self.listeners[name] = {}
    end
    table.insert(self.listeners[name], callback)
end

function Event:Fire(eventName, ...)
    if self.listeners and self.listeners[eventName] then
        for _, callback in ipairs(self.listeners[eventName]) do
            callback(...)
        end
    end

    -- resume any coroutines waiting on this event
    if self.waiting and self.waiting[eventName] then
        for _, co in ipairs(self.waiting[eventName]) do
            local ok, error = coroutine.resume(co, ...)

            if not ok then
                print("Coroutine error during thread wakeup:", err)
            end
        end
        --  clear waiting events after firing
        self.waiting[eventName] = nil
    end
end

-- if the event is currently being listened on so we dont try to disconnect nothing
function Event:IsListening(name) -- returns if the function is listening
    return self.listeners[name] ~= nil
end

function Event:Disconnect(name, functionToDisconnect)
    local callbacks = self.listeners[name]
    if not callbacks then
        error("Attempted to disconnect a nil Event: " .. tostring(name))
    end

    -- once again since we are using table.remove iterate backwards
    for i = #callbacks, 1, -1 do  -- iterate backwards when removing
        if callbacks[i] == functionToDisconnect then
            table.remove(callbacks, i)
            return  -- only one instance to remove
        end
    end
end


-- static functions
function Event.waitUntil(eventObject, eventName)
    local co = coroutine.running()
    -- get the current thread and error if its not inside a coroutine
    if not co then
        error("Event.waitUntil must be called inside a coroutine.")
    end

    -- create a waiting list for events
    if not eventObject.waiting then
        eventObject.waiting = {}
    end

    if not eventObject.waiting[eventName] then
        eventObject.waiting[eventName] = {}
    end

    -- add the calling event so it gets called later
    -- and we arent missing it
    table.insert(eventObject.waiting[eventName], co)

    -- and then anything thats called before will be called during fire()
    -- fire resumes all the coroutines or (threads) that have been waiting on it

    -- temporarily pause the current thread
    return coroutine.yield()
end

return Event