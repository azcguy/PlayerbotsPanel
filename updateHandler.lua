-- this class abstracts things related to update loop and time
PlayerbotsPanelUpdateHandler = {}
local _updateHandler = PlayerbotsPanelUpdateHandler

-- array of callbacks
_updateHandler.onUpdate = {}
-- total time since addon initialized
_updateHandler.totalTime = 0

local _util = PlayerbotsPanelUtil
local _lastUpdate = 0.0
local _updateRate = 0.05
local _delayedCalls = {}
-- Selector frame (the list of bots) is refreshed in update loop if this counter > 0
local _bShouldUpdateSelector = 0

function PlayerbotsPanelUpdateHandler:Init()
    
end

-- func (elsapsed)
function PlayerbotsPanelUpdateHandler:RegisterHandler(func)
    tinsert(_updateHandler.onUpdate, func)
end

function PlayerbotsPanelUpdateHandler:UnregisterHandler(func)
    local index = _util:IndexOf(_updateHandler.onUpdate, func)
    if index > -1 then
        tremove(_updateHandler.onUpdate, index)
    end
end

-- Called by PlayerbotsPanel
function PlayerbotsPanelUpdateHandler:Update(elapsed)
    _updateHandler.totalTime = _updateHandler.totalTime + elapsed

    local handlersCount = getn(_updateHandler.onUpdate)
    if handlersCount > 0 then 
        for i=1, handlersCount do
            _updateHandler.onUpdate[i](elapsed)
        end
    end
  
    _lastUpdate = _lastUpdate + elapsed
    if(_lastUpdate > _updateRate) then
      _lastUpdate = 0
      if _bShouldUpdateSelector > 0 then
        PlayerbotsPanel:UpdateBotSelector()
        _bShouldUpdateSelector = _bShouldUpdateSelector - 1
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

function PlayerbotsPanelUpdateHandler:shouldUpdateSelector(times)
  if times == nil or times == 0 then
    times = 1
  end
  _bShouldUpdateSelector = _bShouldUpdateSelector + times
end

function PlayerbotsPanelUpdateHandler:DelayCall(seconds, func)
  local call = {
    callAt = _updateHandler.totalTime + seconds,
    callback = func
  }
  tinsert(_delayedCalls, call)
end