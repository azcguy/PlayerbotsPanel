PlayerbotsPanelUtil = {}
local _data = PlayerbotsPanelData
local _eval = PlayerbotsPanelUtil.CompareAndReturn


function  PlayerbotsPanelUtil.CompareAndReturn(eval, ifTrue, ifFalse)
    if eval then
        return ifTrue
    else
        return ifFalse
    end
end

function PlayerbotsPanelUtil.SetTextColor(text, c)
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function PlayerbotsPanelUtil.SetVertexColor(tex, c)
    tex:SetVertexColor(c.r, c.g, c.b)
end

function PlayerbotsPanelUtil.SetTextColorToClass(text, class)
    local c = PlayerbotsPanelUtil.CompareAndReturn(class == nil, _data.colors.white, _data.colors.classes[strupper(class)])
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function PlayerbotsPanelUtil.Where(_table, predicate)
    for k,v in pairs(_table) do
        if(predicate(k,v)) then
            return _table[k]
        end    
    end
end

function PlayerbotsPanelUtil.FindIndex(_table, obj)
    local t = 1
    for k,v in pairs(_table) do
        if v == obj then
            return t
        end    
        t = t + 1
    end
    return -1
end

function PlayerbotsPanelUtil.IndexOf(_table, predicate)
    local t = 1
    for k,v in pairs(_table) do
        if(predicate(k,v)) then
            return t
        end    
        t = t + 1
    end
    return -1
end

-- copies the table and returns a new one
function PlayerbotsPanelUtil.RemoveByKey(_table, key)
    local n = {}
    for k,v in pairs(_table) do
        if k ~= key then
            n[k] = v
        end
    end
    return n
end

function PlayerbotsPanelUtil.DumpTable(_table)
    PlayerbotsPanelUtil.Where(_table, function(k,v)
        print(k, v)
    end)
end

function PlayerbotsPanelUtil.SetBackdrop(frame, tex, texBorder)

    local insets = nil
    if texBorder then
        insets = {
            left = 11,
            right = 12,
            top = 12,
            bottom = 11
        }
    else
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    end
    local backdrop = {
        -- path to the background texture
        bgFile = tex,  
        -- path to the border texture
        edgeFile = texBorder, -- "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        -- true to repeat the background texture to fill the frame, false to scale it
        tile = false,
        -- size (width or height) of the square repeating background tiles (in pixels)
        tileSize = 32,
        -- thickness of edge segments and square size of edge corners (in pixels)
        edgeSize = 32,
        -- distance from the edges of the frame to those of the background texture (in pixels)
        insets = insets
      }
      frame:SetBackdrop(backdrop)
end


function PlayerbotsPanelUtil.CreatePool(onNew, onClear)
    local pool = {}
    pool.elems = {}
    pool.count = 0
    pool.onNew = onNew
    pool.onClear = onClear
    pool.Get = function (self)
        local elems = self.elems
        local count = self.count
        if self.count == 0 then
            return self.onNew()
        else
            local elem = elems[count]
            elems[count] = nil
            self.count = count - 1
            return elem
        end
    end

    pool.Release = function  (self, elem)
        if not elem then return end
        local count = self.count
        count = count + 1
        self.elems[count] = elem
        self.count = count
        if onClear then
            self.onClear(elem)
        end
    end

    return pool
end

local _itemCache = {}
-- Using big strings as keys is fine in lua, since all strings are interned by default and the table uses reference as key
function  PlayerbotsPanelUtil.GetItemCache(link)
    local cache = _itemCache[link]
    if not cache then
        cache = {}
        cache.name, _, cache.quality, cache.iLevel, cache.reqLevel, cache.class, cache.subclass, cache.maxStack, cache.equipSlot, cache.texture, cache.vendorPrice = GetItemInfo(link)
    end
    return cache
end

function PlayerbotsPanelUtil.CreateEvent()
    local event = {}
    event.callbacks = {}
    event.Invoke = function (self, arg1, arg2, arg3, arg4)
        for k,cb in pairs(self.callbacks) do
            if cb then
                cb(arg1, arg2, arg3, arg4)
            end
        end
    end

    event.Add = function (self, callback)
        self.callbacks[callback] = callback
    end

    event.Remove = function (self, callback)
        self.callbacks[callback] = nil        
    end

    return event
end



