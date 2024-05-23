PlayerbotsPanelItemCache = {}
local _itemCache = PlayerbotsPanelItemCache
local _data = PlayerbotsPanelData
local _cfg = PlayerbotsPanelConfig
local _updateHandler = PlayerbotsPanelUpdateHandler
local _cacheTable = {}
local _queryTooltip = CreateFrame("GameTooltip", "PlayerbotsPanelTooltip_query", UIParent, "GameTooltipTemplate")
local _pairs = pairs
local _util = PlayerbotsPanelUtil
-- Using big strings as keys is fine in lua, since all strings are interned by default and the table uses reference as key

local _queue = {}
local _tickrate = 1.0 / _cfg.itemCacheAsyncItemsPerSecond
local _nextTick = 0

function PlayerbotsPanelItemCache:Init()
    _updateHandler:RegisterHandler(PlayerbotsPanelItemCache.ProcessQueue)
end

function PlayerbotsPanelItemCache.ProcessQueue(elapsed)
    local time = _updateHandler.totalTime
    if _nextTick < time then -- max 1 query per tick
        _nextTick = time + _tickrate

        local completeQuery = nil

        for link, cache in _pairs(_queue) do
            local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(link)
            if texture ~= nil then -- query complete
                cache.name = name
                --cache.link = link
                cache.quality = quality
                cache.iLevel = iLevel
                cache.reqLevel = reqLevel
                cache.class = class
                cache.subclass = subclass
                cache.maxStack = maxStack
                cache.equipSlot = equipSlot
                cache.texture = texture
                cache.vendorPrice = vendorPrice
                completeQuery = cache
                break
            end
        end
        if completeQuery then
            completeQuery.updating = false;
            completeQuery.onQueryComplete:Invoke()
            completeQuery.onQueryComplete:Clear()
            _queue[completeQuery.link] = nil
        end
    end
end

function  PlayerbotsPanelItemCache.GetItemCache(itemLink)
    local cache = _cacheTable[itemLink]
    if not cache then
        cache = {}
        _queryTooltip:SetHyperlink(itemLink)
        cache.updating = true
        cache.onQueryComplete = _util.CreateEvent()
        cache.name = "Updating ..."
        cache.link = itemLink
        cache.quality = 0
        cache.iLevel = 0
        cache.reqLevel = 0
        cache.texture = _data.textures.slotLoading
        cache.vendorPrice = 0
        _cacheTable[itemLink] = cache
        _queue[itemLink] = cache
    end
    return cache
end

function PlayerbotsPanelItemCache:QueryItemID(id)
	SetItemRef(('item:%d'):format(tonumber(id)))
end