-- this class abstracts things related to update loop and time
PlayerbotsPanel.UpdateHandler = {}
local _self = PlayerbotsPanel.UpdateHandler
local _util = PlayerbotsPanel.Util
local _eval = _util.CompareAndReturn

-- array of callbacks
_self.onUpdate = {}
-- total time since addon initialized
_self.totalTime = 0
-- fires when mouse button state changes (button, down)
_self.onMouseButton = _util.CreateEvent()
-- you can mark global clicks as consumed, this allows to check if input was processed in frame events like OnClick
local _consumedMouseClicks = {
    [1] = false,
    [2] = false,
    [3] = false
}

local _delayedCalls = {}

function _self:SetGlobalMouseButtonConsumed(buttonNum)
    _consumedMouseClicks[buttonNum] = true
end

function _self:GetGlobalMouseButtonConsumed(buttonNum)
    return _consumedMouseClicks[buttonNum]
end

local function CreateMouseButtonHandler(button)
    local handler = {}
    handler.button = button
    handler.isdown = false
    handler.onChanged = _self.onMouseButton
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

function _self:Init()
    
end

-- func (elsapsed)
function _self:RegisterHandler(func)
    tinsert(_self.onUpdate, func)
end

function _self:UnregisterHandler(func)
    local index = _util.IndexOf(_self.onUpdate, func)
    if index > -1 then
        tremove(_self.onUpdate, index)
    end
end

-- Called by PlayerbotsPanel
function _self:Update(elapsed)
    _self.totalTime = _self.totalTime + elapsed
    for i=1, 3 do
        _consumedMouseClicks[i] = false
        _mouseButtonHandlers[i]:update()
    end

    local handlersCount = getn(_self.onUpdate)
    if handlersCount > 0 then 
        for i=1, handlersCount do
            _self.onUpdate[i](elapsed)
        end
    end
  
    local len = getn(_delayedCalls)
    for i = len, 1, -1 do
      local call = _delayedCalls[i]
      if call.callAt < _self.totalTime then
        call:callback()
        tremove(_delayedCalls, i)
      end
    end
end

function _self:DelayCall(seconds, func)
  local call = {
    callAt = _self.totalTime + seconds,
    callback = func
  }
  tinsert(_delayedCalls, call)
end