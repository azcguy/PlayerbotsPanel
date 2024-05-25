-- this class abstracts things related to update loop and time
PlayerbotsPanelUpdateHandler = {}
local _updateHandler = PlayerbotsPanelUpdateHandler
local _util = PlayerbotsPanelUtil
local _eval = _util.CompareAndReturn

-- array of callbacks
_updateHandler.onUpdate = {}
-- total time since addon initialized
_updateHandler.totalTime = 0
-- fires when mouse button state changes (button, down)
_updateHandler.onMouseButton = _util.CreateEvent()
-- you can mark global clicks as consumed, this allows to check if input was processed in frame events like OnClick
local _consumedMouseClicks = {
    [1] = false,
    [2] = false,
    [3] = false
}

local _delayedCalls = {}

function PlayerbotsPanelUpdateHandler:SetGlobalMouseButtonConsumed(buttonNum)
    _consumedMouseClicks[buttonNum] = true
end

function PlayerbotsPanelUpdateHandler:GetGlobalMouseButtonConsumed(buttonNum)
    return _consumedMouseClicks[buttonNum]
end

local function CreateMouseButtonHandler(button)
    local handler = {}
    handler.button = button
    handler.isdown = false
    handler.onChanged = _updateHandler.onMouseButton
    handler.update = function (self)
        local down = IsMouseButtonDown(button)
        local state = _eval(down, true, false)
        if state ~= self.isdown then -- state changed
            self.isdown = state
            self.onChanged:Invoke(self.button, state)
        end
    end
    return handler
end

local _mouseButtonHandlers = {}
_mouseButtonHandlers[1] = CreateMouseButtonHandler("LeftButton")
_mouseButtonHandlers[2] = CreateMouseButtonHandler("RightButton")
_mouseButtonHandlers[3] = CreateMouseButtonHandler("MiddleButton")

function PlayerbotsPanelUpdateHandler:Init()
    
end

-- func (elsapsed)
function PlayerbotsPanelUpdateHandler:RegisterHandler(func)
    tinsert(_updateHandler.onUpdate, func)
end

function PlayerbotsPanelUpdateHandler:UnregisterHandler(func)
    local index = _util.IndexOf(_updateHandler.onUpdate, func)
    if index > -1 then
        tremove(_updateHandler.onUpdate, index)
    end
end

-- Called by PlayerbotsPanel
function PlayerbotsPanelUpdateHandler:Update(elapsed)
    _updateHandler.totalTime = _updateHandler.totalTime + elapsed
    for i=1, 3 do
        _consumedMouseClicks[i] = false
        _mouseButtonHandlers[i]:update()
    end

    local handlersCount = getn(_updateHandler.onUpdate)
    if handlersCount > 0 then 
        for i=1, handlersCount do
            _updateHandler.onUpdate[i](elapsed)
        end
    end
  
    local len = getn(_delayedCalls)
    for i = len, 1, -1 do
      local call = _delayedCalls[i]
      if call.callAt < _updateHandler.totalTime then
        call:callback()
        tremove(_delayedCalls, i)
      end
    end
end

function PlayerbotsPanelUpdateHandler:DelayCall(seconds, func)
  local call = {
    callAt = _updateHandler.totalTime + seconds,
    callback = func
  }
  tinsert(_delayedCalls, call)
end