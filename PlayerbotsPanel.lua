local _self = PlayerbotsPanel
local ROOT_FRAME = PlayerbotsPanel.rootFrame
local ROOT_PATH  = PlayerbotsPanel.rootPath
local _cfg = PlayerbotsPanel.Config
local _data = PlayerbotsPanel.Data
local _util = PlayerbotsPanel.Util
local _updateHandler = PlayerbotsPanel.UpdateHandler
local _tooltips = PlayerbotsPanel.Tooltips
local _itemCache = PlayerbotsPanel.ItemCache
local _debug = PlayerbotsPanel.Debug
local _broker = PlayerbotsBroker
local _dbchar = {}
local _dbaccount = {}
local CALLBACK_TYPE = PlayerbotsBrokerCallbackType
local QUERY_TYPE = PlayerbotsBrokerQueryType
local COMMAND = PlayerbotsBrokerCommandType
local _eval = _util.CompareAndReturn
local _pairs = pairs
_self.selectedBot = nil
_self.isTrading = false
_self.events = {}
_self.events.onBotSelectionChanged = _util.CreateEvent()

-- references to tab objects that will be initialized, declared in corresponding files
_self.tabInitList = 
{
    _self.Objects.PlayerbotsPanelTabCommands,
    _self.Objects.PlayerbotsPanelTabInventory,
    _self.Objects.PlayerbotsPanelTabQuests,
    _self.Objects.PlayerbotsPanelTabSettings,
    _self.Objects.PlayerbotsPanelTabSpells,
    _self.Objects.PlayerbotsPanelTabStats,
    _self.Objects.PlayerbotsPanelTabStrategies,
    _self.Objects.PlayerbotsPanelTabTalents,
}

_self.mainTabGroup = { }

-- when target switches this gets populated
_self.targetData =
{
    isPlayer = false,
    isRegistered = false,
    isOnline = false,
    race = "",
    raceNice = "",
    name = "",
    class = "",
    level = 0,
}

-- chat commands to control addon itself
_self.commands = {
    type = 'group',
    args = {
        toggle = {
            name = "toggle",
            desc = "Toggle PlayerbotsPanel",
            type = 'execute',
            func = function() _self:OnClick() end
        },
        clearAll = {
            name = "clearall",
            desc = "Clears all bot data",
            type = 'execute',
            func = function() 
                print("Clearing all bot data")
                if _dbchar then
                    _dbchar.bots = {}
                end
                ReloadUI()
            end
        },
        dumpStatus = {
            name = "dumpstatus",
            desc = "dumps status for all bots",
            type = 'execute',
            func = function() 
                for k,bot in pairs(_dbchar.bots) do
                    local status = _broker:GetBotStatus(bot.name)
                    print("-----> " .. bot.name)
                    print("online:" .. tostring(status.online))
                    print("party:" .. tostring(status.party))
                end
            end
        },
        queryWho = {
            name = "querywho",
            desc = "who query for all bots",
            type = 'execute',
            func = function() 
                for name, bot in pairs(_dbchar.bots) do
                    PlayerbotsBroker:StartQuery(QUERY_TYPE.WHO, bot)
                end
            end
        }
    }
}

local _gearView = {}
-- root frame of the paperdoll view for bots
local PlayerbotsGear     = CreateFrame("Frame", "PlayerbotsGear", ROOT_FRAME)
_gearView.frame = PlayerbotsGear
-- renders the bot 3d model
local ModelViewFrame     = CreateFrame("PlayerModel", "ModelViewFrame", ROOT_FRAME)
_gearView.modelView = ModelViewFrame

function _self:OnInitialize()
    _debug:SetDebugging(true)
    _debug:SetDebugLevel(_cfg.debugLevel)
    _dbchar = _self.db.char
    if _dbchar.bots == nil then
      _dbchar.bots = {}
    end
    for name, bot in pairs(_dbchar.bots) do
        _self:ValidateBotData(bot)
    end
    _dbaccount = _self.db.account
    _updateHandler:Init()
    _broker:Init(_dbchar.bots)
    _itemCache:Init()
    self:CreateWindow()
    self:RegisterChatCommand("/pp", self.commands)
    --self:RegisterEvent("PLAYER_LOGIN")
    --self:RegisterEvent("PLAYER_LOGOUT")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("UNIT_MODEL_CHANGED")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self:RegisterEvent("PARTY_MEMBER_DISABLE")
    self:RegisterEvent("PARTY_MEMBER_ENABLE")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("TRADE_CLOSED")
    self:RegisterEvent("TRADE_SHOW")

end

function _self:OnEnable()
    self:SetDebugging(true)

    ROOT_FRAME:Show()
    _self:UpdateBotSelector()
    _broker:OnEnable()
end

function _self:OnDisable()
    self:SetDebugging(false)
    _broker:OnDisable()
end

function _self:OnShow()
    PlaySound(_data.sounds.onAddonShow)

end

function _self:OnHide()
    PlaySound(_data.sounds.onAddonHide)
end

function _self:Update(elapsed)
    _updateHandler:Update(elapsed)
end

function _self:ClosePanel()
	HideUIPanel(ROOT_FRAME)
end

function _self:print(t)
    DEFAULT_CHAT_FRAME:AddMessage("PlayerbotsPanel: " .. t)
end

function _self:PLAYER_TARGET_CHANGED()
    if UnitIsPlayer("target") then
        _self:ExtractTargetData()
        _self:SetSelectedBot(UnitName("target"))
    end
end

function _self:PARTY_MEMBERS_CHANGED()
    _broker:PARTY_MEMBERS_CHANGED()
end

function _self:PARTY_MEMBER_ENABLE()
    _broker:PARTY_MEMBER_ENABLE()
end

function _self:PARTY_MEMBER_DISABLE()
    _broker:PARTY_MEMBER_DISABLE()
end

function _self:TRADE_CLOSED()
    _self.isTrading = false
end

function _self:TRADE_SHOW()
    _self.isTrading = true
end

function _self:UNIT_MODEL_CHANGED()
end

function _self:PLAYER_LOGIN()
    _broker:PLAYER_LOGIN()
end

function _self:PLAYER_LOGOUT()
    _broker:PLAYER_LOGOUT()
end

function _self:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
    _broker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
end

function _self:CHAT_MSG_ADDON(prefix, message, channel, sender)
    _broker:CHAT_MSG_ADDON(prefix, message, channel, sender)
end

function _self:CHAT_MSG_SYSTEM(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter)
    --_broker:CHAT_MSG_SYSTEM(prefix, message, channel, sender)
end

function _self:GetBot(name)
    if _dbchar.bots ~= nil then
        return _dbchar.bots[name]
    end
    return nil
end

function _self:ExtractTargetData()
    local _name = UnitName("target")
    local race, racetoken = UnitRace("target")
    _self.targetData = {
        isPlayer = UnitIsPlayer("target"),
        guid = UnitGUID("target"),
        isRegistered = _util.Where(_dbchar.bots, function(k,v)
            if k == _name then return true end
        end),
        isOnline = UnitIsConnected("target"),
        name = _name,
        raceNice = race,
        race = strupper(racetoken),
        class = UnitClass("target"),
        level = UnitLevel("target")
    }
end


function _self:CreateBotData(name)
    if not name then
        error("Invalid name")
        return
    end
        
    if _dbchar.bots[name] then
        print("Bot ".. name .. " is already registered!")
        return
    end
    
    local bot = {}
    bot.name = name
    _self:ValidateBotData(bot)
    _dbchar.bots[name] = bot
    return bot
end


local _pool_bagslotdata = _util.CreatePool(
    function ()
        return { link = nil, count = 0 }
    end,
    function (elem)
        elem.link = nil
        elem.count = 0
    end )

function  _self.InitBag(bag, size, link)
    bag.link = link
    bag.size = size
    bag.freeSlots = size
    local contents = bag.contents
    for k,v in _pairs(contents) do
        _pool_bagslotdata:Release(v)
    end
    wipe(bag.contents)
end

function _self.SetBagItemData(bag, slotNum, count, link)
    local size = bag.size
    local contents = bag.contents
    if slotNum > size then
        _debug.LevelDebug(1, "Slot num is larger than bag size!")
        return
    end

    local slot = contents[slotNum]

    if not link then
        if not slot then return end -- no incoming link and no existing slot, do nothing
        local existingLink = slot.link
        if existingLink then -- removed an item
            bag.freeSlots = bag.freeSlots + 1
        end
        contents[slotNum] = nil
        _pool_bagslotdata:Release(slot)
    else
        local added = false
        if not slot then 
            slot = _pool_bagslotdata:Get()
            contents[slotNum] = slot
            added = true
        else
            local existingLink = slot.link
            if not existingLink then -- added item
                added = true
            end
        end
        slot.link = link
        slot.count = count
        if added then
            bag.freeSlots = bag.freeSlots - 1
        end
    end
end

function _self:CreateBagData(name, size)
    local bag = {}
    bag.name = name
    bag.link = nil
    bag.freeSlots = size
    bag.size = size
    bag.contents = {}
    _self.InitBag(bag, bag.size, nil)
    return bag
end

--- May seem overboard but it allows to adjust the layout of the data after it was already serialized
function _self:ValidateBotData(bot)
    local function EnsureField(owner, name, value)
        if not owner[name] then
            owner[name] = value
        end
    end

    EnsureField(bot, "race", "HUMAN")
    EnsureField(bot, "class", "PALADIN")
    EnsureField(bot, "level", 1)
    EnsureField(bot, "expLeft", 0.0)
    EnsureField(bot, "zone", "Unknown")
    EnsureField(bot, "talents", {})
    EnsureField(bot.talents, "dualSpecUnlocked", false)
    EnsureField(bot.talents, "activeSpec", 1)
    EnsureField(bot.talents, "specs", {})

    EnsureField(bot.talents.specs,1, {})
    EnsureField(bot.talents.specs[1],"primary", 1)
    EnsureField(bot.talents.specs[1],"tabs", {})
    EnsureField(bot.talents.specs[1].tabs,1, {})
    EnsureField(bot.talents.specs[1].tabs[1], "points", 0)
    EnsureField(bot.talents.specs[1].tabs,2, {})
    EnsureField(bot.talents.specs[1].tabs[2], "points", 0)
    EnsureField(bot.talents.specs[1].tabs,3, {})
    EnsureField(bot.talents.specs[1].tabs[3], "points", 0)

    EnsureField(bot.talents.specs,2, {})
    EnsureField(bot.talents.specs[2],"primary", 1)
    EnsureField(bot.talents.specs[2],"tabs", {})
    EnsureField(bot.talents.specs[2].tabs,1, {})
    EnsureField(bot.talents.specs[2].tabs[1], "points", 0)
    EnsureField(bot.talents.specs[2].tabs,2, {})
    EnsureField(bot.talents.specs[2].tabs[2], "points", 0)
    EnsureField(bot.talents.specs[2].tabs,3, {})
    EnsureField(bot.talents.specs[2].tabs[3], "points", 0)

    EnsureField(bot, "currency", {})
    EnsureField(bot.currency, "copper", 0)
    EnsureField(bot.currency, "silver", 0)
    EnsureField(bot.currency, "gold", 0)
    EnsureField(bot.currency, "other", {})

    EnsureField(bot, "items", {})
    for i=0, 19 do
        EnsureField(bot.items, i, {})
    end
    
    EnsureField(bot, "bags", {})
    EnsureField(bot.bags, -2, _self:CreateBagData("Keyring", 32))
    EnsureField(bot.bags, -1, _self:CreateBagData("Bank Storage", 28)) -- bank 0
    EnsureField(bot.bags, 0,  _self:CreateBagData("Backpack", 16)) 
    EnsureField(bot.bags, 1,  _self:CreateBagData(nil, 0))
    EnsureField(bot.bags, 2,  _self:CreateBagData(nil, 0))
    EnsureField(bot.bags, 3,  _self:CreateBagData(nil, 0))
    EnsureField(bot.bags, 4,  _self:CreateBagData(nil, 0))
    EnsureField(bot.bags, 5,  _self:CreateBagData(nil, 0)) -- bank 1
    EnsureField(bot.bags, 6,  _self:CreateBagData(nil, 0)) 
    EnsureField(bot.bags, 7,  _self:CreateBagData(nil, 0)) 
    EnsureField(bot.bags, 8,  _self:CreateBagData(nil, 0)) 
    EnsureField(bot.bags, 9,  _self:CreateBagData(nil, 0)) 
    EnsureField(bot.bags, 10, _self:CreateBagData(nil, 0)) 
    EnsureField(bot.bags, 11, _self:CreateBagData(nil, 0)) -- bank 7

    EnsureField(bot, "stats", {})
    EnsureField(bot.stats, "base", {})
    EnsureField(bot.stats, "resists", {})
    EnsureField(bot.stats, "melee", {})
    EnsureField(bot.stats, "ranged", {})
    EnsureField(bot.stats, "spell", {})
    EnsureField(bot.stats, "defenses", {})
end

function _self:RegisterByName(name)
    if _dbchar.bots[name] == nil then
        _dbchar.bots[name] = _self:CreateBotData(name)
        _broker:DoHandshakeAfterRegistration(name)
    end
    _self:UpdateBotSelector()
    _self:SetSelectedBot(name)
end

function _self:UnregisterByName(name)
    if _dbchar.bots[name] ~= nil then
        _dbchar.bots = _util.RemoveByKey(_dbchar.bots, name)
    end
    _self:ClearSelection()
    _self:UpdateBotSelector()
end

function _self:RefreshSelection()
    _updateHandler:DelayCall(0.25, function()
        if self.selectedBot ~= nil then
            _self:SetSelectedBot(self.selectedBot.name)
        end
    end)
end

function _self:ClearSelection()
    _self:UpdateBotSelector()
    _self:UpdateGearView(nil)
    _self.events.onBotSelectionChanged:Invoke(_self.selectedBot)
end

function _self:SetSelectedBot(botname)
    local bot = _self:GetBot(botname)
    if bot == nil then return end
    self.selectedBot = bot
    _dbchar.lastSelectedBot = botname
    _self:UpdateBotSelector()
    _self:UpdateGearView(botname)
    PlaySound(_data.sounds.onBotSelect)
    _self.events.onBotSelectionChanged:Invoke(bot)
end

function _self:OnClick()
    if ROOT_FRAME:IsVisible() then
        ROOT_FRAME:Hide()
    else 
        ROOT_FRAME:Show()
    end
end

local function UpdateGearSlot(bot, slotNum)
    local slot = _gearView.slots[slotNum + 1]
    local item = nil
    if bot then
        item = bot.items[slotNum]
        slot:SetItem(item)
    end
end


function _self.CreateSlot(frame, slotSize, id, bgTex, isEquipSlot)
    local slot =  CreateFrame("Button", "pp_slot", frame)
    slot.id = id
    slot.isEquipSlot = isEquipSlot
    slot.onClick = _util.CreateEvent()
    slot.onEnter = _util.CreateEvent()
    slot.onLeave = _util.CreateEvent()
    slot:RegisterForClicks("AnyUp", "AnyDown")
    slot.updating = false
    slot.showBagFreeSlots = false
    slot.itemCountOverrideActive = false
    slot:SetSize(slotSize, slotSize)
    slot:SetScript("OnEnter", function(self, motion)
        self.hitex:Show()
        if self.updating then return end
        local item = self.item
        if item ~= nil and item.link ~= nil then
            _tooltips.tooltip:SetOwner(self, "ANCHOR_LEFT")
            _tooltips.tooltip:SetHyperlink(self.item.link)

            -- compare tooltips with currently equipped
            if not self.isEquipSlot then
                local cache = _itemCache.GetItemCache(item.link)
                if cache and not cache.updating then
                    local equipSlot = cache.equipSlot
                    if equipSlot and equipSlot <= 19 and equipSlot >= 0 then
                        local bot = _self.selectedBot
                        if bot then
                            local equipped1 = bot.items[equipSlot]
                            if equipped1 and equipped1.link then
                                _tooltips.tooltipCompare1:SetOwner(_tooltips.tooltip, "ANCHOR_NONE")
                                _tooltips.tooltipCompare1:SetPoint("TOPRIGHT", _tooltips.tooltip, "TOPLEFT")
                                _tooltips.tooltipCompare1:SetHyperlink(equipped1.link)
                            end
                        
                            local associatedSlot = _itemCache.associatedSlots[equipSlot]
                            if associatedSlot then
                                local equipped2 = bot.items[associatedSlot]
                                if equipped2 and equipped2.link then
                                    _tooltips.tooltipCompare2:SetOwner(_tooltips.tooltipCompare1, "ANCHOR_NONE")
                                    _tooltips.tooltipCompare2:SetPoint("TOPRIGHT", _tooltips.tooltipCompare1, "TOPLEFT")
                                    _tooltips.tooltipCompare2:SetHyperlink(equipped2.link)
                                end
                            end
                        end
                    end
                end
            end 

            _util.SetVertexColor(self.hitex, self.qColor)
        else
            _util.SetVertexColor(self.hitex, _data.colors.defaultSlotHighlight)
        end
        if self.onEnter then
            self.onEnter:Invoke(self, motion)
        end
    end)
    slot:SetScript("OnLeave", function(self, motion)
        if self.updating then return end
        _tooltips.tooltip:Hide()
        _tooltips.tooltipCompare1:Hide()
        _tooltips.tooltipCompare2:Hide()
        _util.SetVertexColor(self.hitex, _data.colors.defaultSlotHighlight)
        self.hitex:Hide()
        if self.onLeave then
            self.onLeave:Invoke(self, motion)
        end
    end)
    slot:SetScript("OnClick", function(self, button, down)
        if self.updating then return end
        self.onClick:Invoke(self, button, down)
    end)

    slot.SetItem = function (self, item)
        self.item = item
        if not item or not item.link then
            local cache = self.cache
            if cache and cache.updating then
                slot.updating = false
                cache.onQueryComplete:Remove(self.AwaitCacheComplete)
            end
            self.cache = nil
            self.item = nil
        else
            self.item = item
            local cache = self.cache
            if cache and cache.updating then
                slot.updating = false
                cache.onQueryComplete:Remove(self.AwaitCacheComplete)
            end

            local cache = _itemCache.GetItemCache(item.link)
            self.cache = cache
            if cache.updating then
                cache.onQueryComplete:Add(self.AwaitCacheComplete)
                slot.updating = true
            end
        end
        self:Redraw()
    end

    slot.LockHighlight = function (self, lock)
        if lock then
            self.hitex:Show()
        else
            self.hitex:Hide()
        end
    end

    slot.AwaitCacheComplete = function (self)
        slot.cache.onQueryComplete:Remove(slot.AwaitCacheComplete)
        slot.updating = false
        slot:Redraw()
    end

    slot.Redraw = function (self)
        local item = slot.item
        local cache = slot.cache
        if not item or not item.link or not cache then
            self.itemTex:Hide()
            self.qTex:Hide()
            self.countText:Hide()
            return
        else
            local quality = _eval(cache.quality ~= nil, cache.quality, 0)
            slot.itemTex:Show()
            slot.itemTex:SetTexture(cache.texture)
            slot.qColor = _data.colors.quality[quality]
            _util.SetVertexColor(slot.qTex, slot.qColor)
            if quality > 1 then
                slot.qTex:Show()
            else
                slot.qTex:Hide()
            end
            if not slot.itemCountOverrideActive then
                if slot.showBagFreeSlots then
                    if not item.freeSlots then
                        slot.countText:Hide()
                    else
                        slot.countText:Show()
                        slot.countText:SetText(tostring(item.freeSlots))
                    end
                else
                    if not item.count or item.count <= 1 then
                        slot.countText:Hide()
                    else
                        slot.countText:Show()
                        slot.countText:SetText(tostring(item.count))
                    end
                end
            end
        end
    end

    slot.SetItemCountOverride = function(self, count)
        self.itemCountOverrideActive = true
        self.countText:Show()
        self.countText:SetText(tostring(count))
    end

    slot.ClearItemCountOverride = function (self)
        self.itemCountOverrideActive = false
        self:Redraw()
    end

    slot.bgTex = slot:CreateTexture(nil, "BACKGROUND", -7)
    local slotBgTex = slot.bgTex
    bgTex = _eval(bgTex, bgTex, _data.textures.emptySlot)
    slotBgTex:SetTexture(bgTex)
    slotBgTex:SetPoint("TOPLEFT", 0, 0)
    slotBgTex:SetWidth(slotSize)
    slotBgTex:SetHeight(slotSize)
    slotBgTex:SetVertexColor(0.75,0.75,0.75)
  
    slot.itemTex = slot:CreateTexture(nil, "BORDER", -6)
    local itemTex = slot.itemTex
    itemTex:SetTexture(_data.textures.emptySlot)
    itemTex:SetPoint("TOPLEFT", 0, 0)
    itemTex:SetWidth(slotSize)
    itemTex:SetHeight(slotSize)
    itemTex:Hide()
  
    slot.qTex = slot:CreateTexture(nil, "OVERLAY", -5)
    local qTex = slot.qTex
    qTex:SetTexture(_data.textures.slotHi)
    qTex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    qTex:SetBlendMode("ADD")
    qTex:SetAlpha(1)
    qTex:SetPoint("TOPLEFT", 0, 0)
    qTex:SetWidth(slotSize)
    qTex:SetHeight(slotSize)
    qTex:SetVertexColor(1,1,1)
    qTex:Hide()
  
    slot.hitex = slot:CreateTexture(nil, "OVERLAY", -4)
    local hitex = slot.hitex
    hitex:SetTexture(_data.textures.slotHi)
    hitex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    hitex:SetBlendMode("ADD")
    hitex:SetPoint("TOPLEFT", 0, 0)
    hitex:SetWidth(slotSize)
    hitex:SetHeight(slotSize)
    hitex:SetAlpha(0.75)
    _util.SetVertexColor(hitex, _data.colors.defaultSlotHighlight)
    hitex:Hide()

    slot.countText = slot:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
    local countText = slot.countText
    countText:SetPoint("TOPLEFT", slot)
    countText:SetPoint("BOTTOMRIGHT", slot, -3, 3)
    countText:SetJustifyH("RIGHT")
    countText:SetJustifyV("BOTTOM")
    return slot
end

-- supports NIL as arg, will clear everything
function _self:UpdateGearView(name)
    -- get bot 
    local clearMode = false
    if name == nil then 
      clearMode = true
    end

    if clearMode then
        _gearView.modelView:Hide()
        _gearView.botName:SetText("")
        _gearView.botDescription:SetText("")
        _gearView.dropFrame:Hide()
        for i=1, 19 do 
            UpdateGearSlot(nil, i)
        end
    else
        local bot = _self:GetBot(name)
        if bot == nil then return end
        
        local status = _broker:GetBotStatus(name)

        if status.online  then
            _gearView.modelView:Show()
            if status.party then
                _gearView.modelView:SetUnit(name)
                _gearView.dropFrame:Show()
            end
            _gearView.modelView.bgTex:SetTexture(_data.raceData[bot.race].background)
        else
            _gearView.modelView:Hide()
        end

        local statusStr = "Level " .. bot.level 
        _util.SetTextColor(_gearView.botDescription, _data.colors.gold)
      
        if not status.online then
            statusStr = statusStr .. " (Cached)"
            _util.SetTextColor(_gearView.botDescription, _data.colors.gray)
        end
      
        _gearView.botName:SetText(bot.name)
        _gearView.botDescription:SetText(statusStr)
        _util.SetTextColorToClass(_gearView.botName, bot.class)
      
        if bot.currency then
            _gearView.txtGold:SetText(bot.currency.gold)
            _gearView.txtSilver:SetText(bot.currency.silver)
            _gearView.txtCopper:SetText(bot.currency.copper)
        else
            _gearView.txtGold:SetText("?")
            _gearView.txtSilver:SetText("?")
            _gearView.txtCopper:SetText("?")
        end
        
        for i=1, 19 do 
            UpdateGearSlot(bot, i)
        end
    end
end

function _self:SetupGearSlot(id, x, y)
    if _gearView.slots == nil then
        _gearView.slots = {}
    end

    local slots = _gearView.slots
    if slots[id] == nil then
        local bgTex = _data.textures.slotIDbg[id]
        local slot = _self.CreateSlot(_gearView.frame, 38, id, bgTex, true)
        slots[id] = slot 
        slot:SetPoint("TOPLEFT", x, y)
        slot.onClick:Add(function (slot, button, down)
            if slot.item and slot.item.link then
                if not down then
                    if button == "RightButton" then
                        _broker:GenerateCommand(_self.selectedBot, COMMAND.ITEM, COMMAND.ITEM_UNEQUIP, slot.item.link)
                        PlaySound("SPELLBOOKCLOSE")
                    elseif button == "LeftButton" then
                        --_broker:GenerateCommand(PlayerbotsPanel.selectedBot, COMMAND.ITEM, COMMAND.ITEM_TRADE, slot.item.link)
                        --PlaySound("SPELLBOOKCLOSE")
                    end
                end
            end
        end)
    end
end

function _self:DropItemSelected()
    if self.selectedBot then
        DropItemOnUnit(self.selectedBot.name)
        _updateHandler:DelayCall(0.25, function()
            AcceptTrade()
        end)
    end
end

function _self:SetupGearFrame()
    --ModelViewFrame:SetFrameStrata("DIALOG")
    ModelViewFrame:SetWidth(200)
    ModelViewFrame:SetHeight(300)
    ModelViewFrame:SetPoint("CENTER", -125, 0)

    --PlayerbotsGear:SetFrameStrata("DIALOG")
    PlayerbotsGear:SetFrameLevel(5)
    PlayerbotsGear:SetPoint("TOPLEFT", 169, -26)
    PlayerbotsGear:SetWidth(219)
    PlayerbotsGear:SetHeight(362)

    local gearView = _gearView
    
    gearView.dropFrame = CreateFrame("Button", "pp_gear_dropFrame", PlayerbotsGear)
    local dropFrame = _gearView.dropFrame
    dropFrame:SetFrameLevel(6)
    dropFrame:SetPoint("TOPLEFT", 46, -32)
    dropFrame:SetWidth(123)
    dropFrame:SetHeight(285)
    dropFrame:EnableMouse(true)
    dropFrame:RegisterForClicks("AnyUp")
    dropFrame:SetScript("OnEnter", function(self, motion)
        if CursorHasItem() then
            dropFrame.dropTex:Show()
            dropFrame.dropText:Show()
        end
    end)
  
    dropFrame:SetScript("OnLeave", function(self, motion)
        dropFrame.dropTex:Hide()
        dropFrame.dropText:Hide()
    end)

    dropFrame:SetScript("OnReceiveDrag", function(self)
        if CursorHasItem() then
            _self:DropItemSelected()
        end
    end)
    dropFrame:Hide()

    dropFrame.dropTex = dropFrame:CreateTexture(nil, "OVERLAY")
    local dropTex = dropFrame.dropTex
    dropTex:SetBlendMode("ADD")
    dropTex:SetPoint("TOPLEFT", 0, 0)
    dropTex:SetWidth(dropFrame:GetWidth())
    dropTex:SetHeight(dropFrame:GetHeight())
    dropTex:SetTexture("Interface\\QUESTFRAME\\UI-QuestTitleHighlight.blp")
    dropTex:SetVertexColor(1,1,0.2)
    dropTex:SetAlpha(1)
    dropTex:Hide()

    dropFrame.dropText = dropFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    dropFrame.dropText:SetText("Drop Items here")
    dropFrame.dropText:SetJustifyH("CENTER")
    dropFrame.dropText:SetPoint("TOP", 0, 0)
    dropFrame.dropText:SetSize(dropFrame:GetWidth(), dropFrame:GetHeight())
    dropFrame.dropText:SetTextColor(1,1,0.2, 1)
    dropFrame.dropText:Hide()

    local gearTex = PlayerbotsGear:CreateTexture(nil, "ARTWORK")
    gearTex:SetTexture(ROOT_PATH .. "textures\\gearSlots.tga")
    gearTex:SetPoint("TOPLEFT", 0, 0)
    gearTex:SetWidth(PlayerbotsGear:GetWidth())
    gearTex:SetHeight(PlayerbotsGear:GetHeight())

    ModelViewFrame.bgTex = ModelViewFrame:CreateTexture(nil, "BACKGROUND")
    ModelViewFrame.bgTex:SetTexture(_data.raceData["TAUREN"].background)
    ModelViewFrame.bgTex:SetAlpha(0.5)
    ModelViewFrame.bgTex:SetTexCoord(0.2, 0.78, 0.075, 1)
    ModelViewFrame.bgTex:SetPoint("TOPLEFT", 0, 0)
    ModelViewFrame.bgTex:SetWidth(ModelViewFrame:GetWidth())
    ModelViewFrame.bgTex:SetHeight(ModelViewFrame:GetHeight())

    _gearView.updateGearButton = CreateFrame("Button", "pp_updateGearButton", PlayerbotsGear)
    local updateGearBtn = _gearView.updateGearButton
    --updateGearBtn:SetFrameStrata("DIALOG")
    updateGearBtn:SetFrameLevel(7)
    updateGearBtn:SetPoint("BOTTOMLEFT", PlayerbotsGear,  48, 43)
    updateGearBtn:SetSize(24,24)
    updateGearBtn:SetNormalTexture(_data.textures.updateBotsUp)
    updateGearBtn:SetPushedTexture(_data.textures.updateBotsDown)
    updateGearBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    updateGearBtn:SetScript("OnClick", function(self, button, down)
        _broker:StartQuery(QUERY_TYPE.GEAR, _self.selectedBot)
    end)
    updateGearBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(updateGearBtn, _data.strings.tooltips.gearViewUpdateGear)

    gearView.botName = PlayerbotsGear:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    gearView.botName:SetText("No selection")
    gearView.botName:SetJustifyH("LEFT")
    gearView.botName:SetPoint("TOPLEFT", PlayerbotsGear, 5, -5)
    gearView.botName:SetTextColor(1, 1, 1, 1)

    gearView.botDescription = PlayerbotsGear:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    gearView.botDescription:SetText("No selection")
    gearView.botDescription:SetJustifyH("LEFT")
    gearView.botDescription:SetPoint("TOPLEFT", PlayerbotsGear, 5, -18)
    _util.SetTextColor(gearView.botDescription, _data.colors.gold)

    gearView.onBotExperienceChanged = function(bot)
        if bot == _self.selectedBot then
            gearView.botDescription:SetText("Level " .. bot.level)
        end
    end

    _broker:RegisterGlobalCallback(CALLBACK_TYPE.EXPERIENCE_CHANGED, gearView.onBotExperienceChanged)

    local moneyposY = -15
    gearView.iconCopper = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    gearView.iconCopper:SetPoint("TOPLEFT", PlayerbotsGear, 190, moneyposY)
    gearView.iconCopper:SetTexture("Interface\\MONEYFRAME\\UI-CopperIcon.blp")
    gearView.iconCopper:SetSize(12, 12)

    gearView.txtCopper = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    gearView.txtCopper:SetPoint("TOPLEFT", PlayerbotsGear,"TOPLEFT", 170, moneyposY)
    gearView.txtCopper:SetPoint("BOTTOMRIGHT", PlayerbotsGear,"TOPLEFT", 191, moneyposY- 13 )
    gearView.txtCopper:SetJustifyH("RIGHT")
    gearView.txtCopper:SetText("99")

    gearView.iconSilver = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    gearView.iconSilver:SetPoint("TOPLEFT", PlayerbotsGear, 161, moneyposY)
    gearView.iconSilver:SetTexture("Interface\\MONEYFRAME\\UI-SilverIcon.blp")
    gearView.iconSilver:SetSize(12, 12)

    gearView.txtSilver = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    gearView.txtSilver:SetPoint("TOPLEFT", PlayerbotsGear,"TOPLEFT", 140, moneyposY)
    gearView.txtSilver:SetPoint("BOTTOMRIGHT", PlayerbotsGear,"TOPLEFT", 161, moneyposY- 13)
    gearView.txtSilver:SetJustifyH("RIGHT")
    gearView.txtSilver:SetText("99")

    gearView.iconGold = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    gearView.iconGold:SetPoint("TOPLEFT", PlayerbotsGear, 130, moneyposY)
    gearView.iconGold:SetTexture("Interface\\MONEYFRAME\\UI-GoldIcon.blp")
    gearView.iconGold:SetSize(12, 12)

    gearView.txtGold = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    gearView.txtGold:SetPoint("TOPLEFT", PlayerbotsGear, "TOPLEFT",  10, moneyposY)
    gearView.txtGold:SetPoint("BOTTOMRIGHT", PlayerbotsGear,"TOPLEFT", 130, moneyposY - 13)
    gearView.txtGold:SetJustifyH("RIGHT")
    gearView.txtGold:SetText("99999")

    gearView.onCurrencyChanged = function (bot)
        gearView.txtGold:SetText(bot.currency.gold)
        gearView.txtSilver:SetText(bot.currency.silver)
        gearView.txtCopper:SetText(bot.currency.copper)
    end

    _broker:RegisterGlobalCallback(CALLBACK_TYPE.MONEY_CHANGED, gearView.onCurrencyChanged)


    _gearView.helpIcon = CreateFrame("Frame", nil, PlayerbotsGear)
    local helpIcon = _gearView.helpIcon
    helpIcon:SetFrameLevel(7)
    helpIcon:Show()
    helpIcon:SetPoint("TOPRIGHT", -5, -5)
    helpIcon:SetSize(15, 15)
    helpIcon:EnableMouse(true)

    helpIcon.tex = helpIcon:CreateTexture(nil, "OVERLAY")
    helpIcon.tex:SetPoint("TOPLEFT")
    helpIcon.tex:SetSize(helpIcon:GetWidth(), helpIcon:GetHeight())
    helpIcon.tex:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon.blp")
    _tooltips.AddInfoTooltip(helpIcon, _data.strings.tooltips.gearViewHelp)
  
-- Inventory slots
-- INVSLOT_AMMO    = 0;
-- INVSLOT_HEAD    = 1; INVSLOT_FIRST_EQUIPPED = INVSLOT_HEAD;
-- INVSLOT_NECK    = 2;
-- INVSLOT_SHOULDER  = 3;
-- INVSLOT_BODY    = 4;
-- INVSLOT_CHEST   = 5;
-- INVSLOT_WAIST   = 6;
-- INVSLOT_LEGS    = 7;
-- INVSLOT_FEET    = 8;
-- INVSLOT_WRIST   = 9;
-- INVSLOT_HAND    = 10;
-- INVSLOT_FINGER1   = 11;
-- INVSLOT_FINGER2   = 12;
-- INVSLOT_TRINKET1  = 13;
-- INVSLOT_TRINKET2  = 14;
-- INVSLOT_BACK    = 15;
-- INVSLOT_MAINHAND  = 16;
-- INVSLOT_OFFHAND   = 17;
-- INVSLOT_RANGED    = 18;
-- INVSLOT_TABARD    = 19;
-- INVSLOT_LAST_EQUIPPED = INVSLOT_TABARD;

    local slotOffsetY = 41
    -- left column
    local slotPosY = -32
    local slotPosX = 5
    local intOffset = 1
    _self:SetupGearSlot(INVSLOT_HEAD + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_NECK+ intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_SHOULDER + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_BACK + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_CHEST + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_BODY + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_TABARD + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_WRIST + intOffset, slotPosX, slotPosY)
    -- lower row
    slotPosX = 48
    _self:SetupGearSlot(INVSLOT_MAINHAND + intOffset, slotPosX, slotPosY)
    slotPosX = slotPosX + slotOffsetY
    _self:SetupGearSlot(INVSLOT_OFFHAND + intOffset, slotPosX, slotPosY)
    slotPosX = slotPosX + slotOffsetY
    _self:SetupGearSlot(INVSLOT_RANGED + intOffset, slotPosX, slotPosY)
    -- right column
    slotPosY = -32
    slotPosX = 172
    _self:SetupGearSlot(INVSLOT_HAND + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_WAIST + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_LEGS + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_FEET + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_FINGER1 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_FINGER2 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_TRINKET1 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    _self:SetupGearSlot(INVSLOT_TRINKET2 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY

    _gearView.onUpdatedEquipSlot = function(bot, slotNum)
        if bot == _self.selectedBot then 
            UpdateGearSlot(bot, slotNum)
        end
    end

    _broker:RegisterGlobalCallback(CALLBACK_TYPE.EQUIP_SLOT_CHANGED, _gearView.onUpdatedEquipSlot)

    _gearView.onUpdateAllSlots = function (bot)
        if _self.selectedBot and bot == _self.selectedBot then
            _self:UpdateGearView(bot.name)
        end
    end

    _broker:RegisterGlobalCallback(CALLBACK_TYPE.EQUIPMENT_CHANGED, _gearView.onUpdateAllSlots)
end

function _self:CreateWindow()
    UIPanelWindows[ROOT_FRAME:GetName()] = { area = "center", pushable = 0, whileDead = 1 }
    tinsert(UISpecialFrames, ROOT_FRAME:GetName())
    ROOT_FRAME:HookScript("OnUpdate", _self.Update)
    ROOT_FRAME:SetFrameStrata(_cfg.panelStrata)
    ROOT_FRAME:SetWidth(800)
    ROOT_FRAME:SetHeight(420)
    ROOT_FRAME:SetPoint("CENTER")
    ROOT_FRAME:SetMovable(true)
    ROOT_FRAME:RegisterForDrag("LeftButton")
    ROOT_FRAME:SetScript("OnDragStart", ROOT_FRAME.StartMoving)
    ROOT_FRAME:SetScript("OnDragStop", ROOT_FRAME.StopMovingOrSizing)
    ROOT_FRAME:SetScript("OnShow", _self.OnShow)
    ROOT_FRAME:SetScript("OnHide", _self.OnHide)
    ROOT_FRAME:EnableMouse(true)

    _tooltips:Init(UIParent)

    _self:SetupGearFrame()
    _self:AddWindowStyling(ROOT_FRAME)

    _self.botSelectorParentFrame = CreateFrame("ScrollFrame", "botSelector", ROOT_FRAME, "FauxScrollFrameTemplate")
    _self.botSelectorParentFrame:SetPoint("TOPLEFT", 0, -24)
    _self.botSelectorParentFrame:SetSize(140, 368)
    
    _self.botSelectorFrame = CreateFrame("Frame", "pp_botselector_scroll", _self.botSelectorParentFrame)
    _self.botSelectorParentFrame:SetScrollChild(_self.botSelectorFrame)
    _self.botSelectorFrame:SetPoint("TOPLEFT", 10,0)
    _self.botSelectorFrame:SetWidth(_self.botSelectorParentFrame:GetWidth()-18)
    _self.botSelectorFrame:SetHeight(1) 
    if _dbchar.lastSelectedBot then
        _self:SetSelectedBot(_dbchar.lastSelectedBot)
    end
    _self:SetupTabs()
end



local botSelectorButtons = {}

-- rather complicated frame structure
--  - rootFrame
--     - secureBtn
--     - insecureBtn
--     - overlayFrame
--         - txtName
--         - btnAdd
--         - btnRemove
--         - btnInvite

-- secureBtn acts as unitframe, allows selection of units in game in safe manner
-- insecureBtn is like an offline/out of reach, button that selects the CACHED bot data
-- they swap depending on situation
function _self:CreateBotSelectorButton(name)
    local bot = _self:GetBot(name)
    if not bot then
        error("FATAL: PlayerbotsPanel:CreateBotSelectorButton() missing bot!" .. name)
        return
    end

    local rootFrame = nil
    
    rootFrame = CreateFrame("Frame", nil, _self.botSelectorFrame)
    botSelectorButtons[name] = rootFrame
    rootFrame.name = name

    rootFrame.statusUpdateHandler = function(bot, status)
        local name = bot.name
        _self:UpdateBotSelectorButton(name)
        if bot == _self.selectedBot then
            _self:UpdateGearView(name)
        end
    end
    _broker:RegisterCallback(CALLBACK_TYPE.STATUS_CHANGED, name, rootFrame.statusUpdateHandler)
    _broker:RegisterCallback(CALLBACK_TYPE.LEVEL_CHANGED, name, rootFrame.statusUpdateHandler)
    _broker:RegisterCallback(CALLBACK_TYPE.EXPERIENCE_CHANGED, name, rootFrame.statusUpdateHandler)


    if rootFrame.secureBtn == nil then
        rootFrame.secureBtn = CreateFrame("Button", "ppBotSelector_" .. name, rootFrame, "SecureUnitButtonTemplate")
        rootFrame.secureBtn:SetAttribute("unit", bot.name)
        rootFrame.secureBtn:SetAttribute("*type1", "target") -- Target unit on left click
        rootFrame.secureBtn:SetAttribute("*type2", "togglemenu") -- Toggle units menu on left click
        rootFrame.secureBtn:SetAttribute("*type3", "assist") -- On middle click, target 
        rootFrame.secureBtn:RegisterForClicks("AnyUp", "AnyDown")
        rootFrame.secureBtn:SetText(bot.name)
    end

    if rootFrame.insecureBtn == nil then
        rootFrame.insecureBtn = CreateFrame("Button", nil, rootFrame)
        rootFrame.insecureBtn:RegisterForClicks("AnyUp", "AnyDown")
        rootFrame.insecureBtn:SetScript("OnClick", function(self, button, down)
            _self:SetSelectedBot(bot.name)
        end)
    end

    if rootFrame.overlayFrame == nil then
        rootFrame.overlayFrame = CreateFrame("Frame", nil, rootFrame)
    end
    
    local oFrame = rootFrame.overlayFrame
    if oFrame.txtName == nil then
        oFrame.txtName = oFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        oFrame.txtName:SetSize(100,20)
        oFrame.txtName:SetJustifyH("LEFT")
        oFrame.txtName:SetPoint("TOPLEFT", oFrame, 5, 0)
    end

    if oFrame.btnAdd == nil then
        oFrame.btnAdd = CreateFrame("Button", nil, oFrame)
        _tooltips.AddInfoTooltip(oFrame.btnAdd, _data.strings.tooltips.addBot)
        oFrame.btnAdd:SetNormalTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Up")
        oFrame.btnAdd:SetPushedTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Down.blp")
        oFrame.btnAdd:SetHighlightTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Hilight.blp")
        oFrame.btnAdd:SetScript("OnClick", function(self, button, down)
            SendChatMessage(".playerbots bot add " .. name)
            _self:RefreshSelection()
        end)
    end

    if oFrame.btnInvite == nil then
        oFrame.btnInvite = CreateFrame("Button", nil, oFrame)
        oFrame.btnInvite:SetNormalTexture("Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon.blp")
        oFrame.btnInvite:SetPushedTexture("Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon.blp")
        _tooltips.AddInfoTooltip(oFrame.btnInvite, _data.strings.tooltips.inviteBot)
        oFrame.btnInvite:SetScript("OnClick", function(self, button, down)
            InviteUnit(name)
            _self:RefreshSelection()
        end)
    end

    if oFrame.btnUninvite == nil then
        oFrame.btnUninvite = CreateFrame("Button", nil, oFrame)
        oFrame.btnUninvite:SetNormalTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up.blp")
        oFrame.btnUninvite:SetHighlightTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up.blp")
        _tooltips.AddInfoTooltip(oFrame.btnUninvite,_data.strings.tooltips.uninviteBot )
        oFrame.btnUninvite:SetScript("OnClick", function(self, button, down)
            UninviteUnit(name)
            _self:RefreshSelection()
        end)
    end

    if oFrame.btnRemove == nil then
        oFrame.btnRemove = CreateFrame("Button", nil, oFrame)
        oFrame.btnRemove:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp")
        oFrame.btnRemove:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp")
        _tooltips.AddInfoTooltip(oFrame.btnRemove, _data.strings.tooltips.removeBot)
        oFrame.btnRemove:SetScript("OnClick", function(self, button, down)
            SendChatMessage(".playerbots bot remove " .. name)
            _self:RefreshSelection()
      end)
    end

    return rootFrame
end

function _self:UpdateBotSelectorButton(name)
    local bot = _self:GetBot(name)
    if not bot then
        error("FATAL: PlayerbotsPanel:UpdateBotSelectorButton(name) Missing bot! ")
        return end

    local rootFrame = botSelectorButtons[name]
    local idx = rootFrame.ppidx
    local width = rootFrame.ppwidth
    local height = rootFrame.ppheight
    local isTarget = UnitName("target") == bot.name
    local selected = self.selectedBot == bot

    local status = _broker:GetBotStatus(bot.name)
    local online = status.online
    local inParty = status.party

    local rootFrame = botSelectorButtons[name]
    rootFrame:Show()
    rootFrame:SetPoint("TOPLEFT", 5, height * idx * -1)
    rootFrame:SetSize(width,height)

    local secureBtn = rootFrame.secureBtn
    secureBtn:SetSize(width,height)
    secureBtn:SetPoint("TOPLEFT", 0, 0)

    if inParty and not isTarget then -- use it only for selecting online, in party Bots, THAT ARE NOT A TARGET otherwise it should be hidden
        secureBtn:Show()
        secureBtn:SetHighlightTexture(ROOT_PATH .. "textures\\botListBtnHi.tga")
        if online then
            secureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm_InParty.tga")
        else
            secureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm_InPartyOffline.tga")
        end
    else
        secureBtn:Hide()
    end
    
    local insecureBtn = rootFrame.insecureBtn
    insecureBtn:SetPoint("TOPLEFT", 0, 0)
    insecureBtn:SetButtonState("NORMAL", false)
    insecureBtn:SetSize(width,height)
    insecureBtn:SetText(bot.name)

    if inParty and not isTarget then
        insecureBtn:Hide()
    else
        insecureBtn:Show()
    end

    insecureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm.tga")
    insecureBtn:SetHighlightTexture(ROOT_PATH .. "textures\\botListBtnHi.tga")
    if selected then
        insecureBtn:SetButtonState("PUSHED", true)
    end
    
    if online then
        if inParty then
            insecureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm_InParty.tga")
            insecureBtn:SetPushedTexture(ROOT_PATH .. "textures\\botListBtnPush_inparty.tga")
        else
            insecureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm_online.tga")
            insecureBtn:SetPushedTexture(ROOT_PATH .. "textures\\botListBtnPush_online.tga")
        end
    else
        insecureBtn:SetNormalTexture(ROOT_PATH .. "textures\\botListBtnNorm_InPartyOffline.tga")
        insecureBtn:SetPushedTexture(ROOT_PATH .. "textures\\botListBtnPush_Offline.tga")
    end
    
    local oFrame = rootFrame.overlayFrame
    oFrame:SetPoint("TOPLEFT", 0, 0)
    oFrame:SetSize(width, height)
    
    oFrame.txtName:SetText(name .. " (" .. tostring(bot.level) .. ")")
    _util.SetTextColorToClass(oFrame.txtName, bot.class)
    
    oFrame.btnAdd:SetSize(14,14)
    oFrame.btnAdd:SetPoint("BOTTOMLEFT", 4, 5)
    if inParty then
        if online then
            oFrame.btnAdd:Hide()
        else
            oFrame.btnAdd:Show()
        end
    else
        if online then
            oFrame.btnAdd:Hide()
        else
            oFrame.btnAdd:Show()
        end
    end
    
    oFrame.btnInvite:SetSize(14,14)
    oFrame.btnInvite:SetPoint("BOTTOMLEFT", 20, 5)
    if inParty then
        oFrame.btnInvite:Hide()
    else
        oFrame.btnInvite:Show()
    end

    oFrame.btnUninvite:SetSize(12,12)
    oFrame.btnUninvite:SetPoint("TOPRIGHT", -5, -5)
    
    if inParty then
        oFrame.btnUninvite:Show()
    else
        oFrame.btnUninvite:Hide()
    end 
    
    oFrame.btnRemove:SetSize(14,14)
    oFrame.btnRemove:SetPoint("BOTTOMRIGHT", -5, 5)
    
    if inParty then
        if online then
            oFrame.btnRemove:Show()
        else
            oFrame.btnRemove:Hide()
        end
    else
        oFrame.btnRemove:Show()
    end
end

-- Called when :
-- on load
-- when the registered bots list changes
-- when sorting changes
function _self:UpdateBotSelector()
    local height = 40
    local width = 125
    
    -- clean up removed bots
    for name, button in pairs(botSelectorButtons) do
        if _dbchar.bots[name] == nil then
            button:Hide()
        end
    end
  
    local idx = 0
    for name, bot in pairs(_dbchar.bots) do
        local rootFrame = nil
        if botSelectorButtons[name] == nil then 
            _self:CreateBotSelectorButton(name)
        end
        rootFrame = botSelectorButtons[name]
        rootFrame.ppidx = idx
        rootFrame.ppwidth = width
        rootFrame.ppheight = height
        _self:UpdateBotSelectorButton(name)
        idx = idx + 1
    end
end

function _self:AddWindowStyling(frame)
    local sizeFactor = 48
    local frameWidth = frame:GetWidth()
    local frameHeight = frame:GetHeight()

    --local whiteTex = frame:CreateTexture(nil, "BACKGROUND")
		--whiteTex:SetTexture("Interface\\BUTTONS\\WHITE8X8.BLP")
		--whiteTex:SetPoint("TOPLEFT", 0, 0)
    --whiteTex:SetWidth(frameWidth)
    --whiteTex:SetHeight(frameHeight)

    local bgLeft = frame:CreateTexture(nil, "BACKGROUND")
    bgLeft:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-Left.blp")
    bgLeft:SetPoint("TOPLEFT", -14, 14)
    bgLeft:SetWidth(frameWidth - 250)
    bgLeft:SetHeight(frameHeight + 28)
	bgLeft:SetTexCoord(0, 1, 0, 0.88)

    local bgRight = frame:CreateTexture(nil, "BACKGROUND")
    bgRight:SetTexture("Interface\\GuildBankFrame\\UI-GuildBankFrame-Right.blp")
    bgRight:SetPoint("TOPLEFT", frameWidth - 250 - 14, 3)
    bgRight:SetWidth(540)
    bgRight:SetHeight(frameHeight + 28)
	bgRight:SetTexCoord(0, 1, 0, 0.88)

    -- BOT LIST
    local botlistHalf = (frameHeight - 23 - 28) * 0.5
    -- top
    local listTexTop = frame:CreateTexture(nil, "BORDER")
    listTexTop:SetTexture("Interface\\AUCTIONFRAME\\UI-AUCTIONFRAME-BROWSE-TOPLEFT.BLP")
    listTexTop:SetPoint("TOPLEFT", 10, -23)
    listTexTop:SetWidth(155)
    listTexTop:SetHeight(botlistHalf)
	listTexTop:SetTexCoord(0.07, 0.715, 0.395, 1)
    listTexTop:SetVertexColor(0.5,0.5,0.5)
    -- bottom
    local listTexBot = frame:CreateTexture(nil, "BORDER")
    listTexBot:SetTexture("Interface\\AUCTIONFRAME\\UI-AUCTIONFRAME-BROWSE-BOTLEFT.BLP")
    listTexBot:SetPoint("BOTTOMLEFT", 10, 28)
    listTexBot:SetWidth(155)
    listTexBot:SetHeight(botlistHalf)
    listTexBot:SetTexCoord(0.07, 0.715, 0, 0.598)
    listTexBot:SetVertexColor(0.5,0.5,0.5)
    -- BOT LIST SCROLLBAR
    -- top
    local listScrollTexOffsetX = 155-12;
    local listScrollTexWidth = 20;
    local listScrollTexMiddleHeight = 60;
    local listScrollTexTop = frame:CreateTexture(nil, "ARTWORK")
    listScrollTexTop:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ClassSkillsTab-R1.blp")
    listScrollTexTop:SetPoint("TOPLEFT", listScrollTexOffsetX, -22)
    listScrollTexTop:SetWidth(listScrollTexWidth)
    listScrollTexTop:SetHeight(botlistHalf - listScrollTexMiddleHeight * 0.5)
	listScrollTexTop:SetTexCoord(0.504, 0.692, 0.280, 1)
    -- bottom
    local listScrollTexBot = frame:CreateTexture(nil, "ARTWORK")
    listScrollTexBot:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ClassSkillsTab-R2.blp")
    listScrollTexBot:SetPoint("BOTTOMLEFT", listScrollTexOffsetX, 28)
    listScrollTexBot:SetWidth(listScrollTexWidth)
    listScrollTexBot:SetHeight(botlistHalf - listScrollTexMiddleHeight * 0.5)
    listScrollTexBot:SetTexCoord(0.508, 0.686, 0, 0.695)
    -- middle
    local listScrollTexMid = frame:CreateTexture(nil, "ARTWORK")
    listScrollTexMid:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ClassSkillsTab-R2.blp")
    listScrollTexMid:SetPoint("TOPLEFT", listScrollTexTop, "BOTTOMLEFT", 0,0)
    listScrollTexMid:SetWidth(listScrollTexWidth)
    listScrollTexMid:SetHeight(listScrollTexMiddleHeight+1)
    listScrollTexMid:SetTexCoord(0.504, 0.691, 0, 0.471)

    -- TAB BACKGROUND
    local tabBgStartX = 165;
    local tabBg = frame:CreateTexture(nil, "BORDER")
    tabBg:SetTexture(ROOT_PATH .. "textures\\tabBg.tga")
    tabBg:SetPoint("TOPLEFT", tabBgStartX, -22)
    tabBg:SetWidth(630)
    tabBg:SetHeight(370)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 10, 6)
    close:SetScript("OnClick", _self.ClosePanel)

    local addonNameLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    addonNameLabel:SetText("Playerbots Panel")
	addonNameLabel:SetJustifyH("RIGHT")
	addonNameLabel:SetPoint("TOPRIGHT", frame, -70, -5)
	addonNameLabel:SetTextColor(0.6, 0.6, 1, 1)
	_util.SetTextColor(addonNameLabel, _data.colors.gold)

    local versionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    versionLabel:SetText(_self.version)
	versionLabel:SetJustifyH("RIGHT")
	versionLabel:SetPoint("TOPRIGHT", frame, -30, -5)
	_util.SetTextColor(versionLabel, _data.colors.gray)

    frame.activeTabLabel = frame:CreateFontString(nil, "ARTWORK", "WorldMapTextFont")
    local activeTabLabel = frame.activeTabLabel
    activeTabLabel:SetText("TABNAME")
	activeTabLabel:SetJustifyH("CENTER")
	activeTabLabel:SetPoint("TOP", frame, 0, -3)
    activeTabLabel:SetTextHeight(14)
    _util.SetTextColor(activeTabLabel, _data.colors.gold)

    frame.updateBotsBtn = CreateFrame("Button", nil, frame)
    local updateBotsBtn = frame.updateBotsBtn
    updateBotsBtn:SetPoint("TOPLEFT", -3, 3)
    updateBotsBtn:SetSize(24,24)
    updateBotsBtn:SetNormalTexture(_data.textures.updateBotsUp)
    updateBotsBtn:SetPushedTexture(_data.textures.updateBotsDown)
    updateBotsBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    updateBotsBtn:SetScript("OnClick", function(self, button, down)
        --PlayerbotsPanel:UpdateBots()
        print("This will start queries in the future, now does nothing")
    end)
    _tooltips.AddInfoTooltip(frame.updateBotsBtn, _data.strings.tooltips.updateBots)
end

local tabOffsetLeft = 0
local tabOffsetRight = 0
local tabStartLeft = 5
local tabStartRight = 5

-- TAB BUTTON OBJECT --
local function CreateTabButton(name, frame, tab)
    local button = {}
    button.onclick = function(self, button, down)
        tab.group.setTabActive(tab.name)
    end

    local iconSize = 14
    button.frame = CreateFrame("Button", "pp_tabButton_" .. name, frame)
    local buttonframe = button.frame

    buttonframe:SetText("") -- hide button built in text
    button.text = buttonframe:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local buttontext = button.text
    buttontext:SetText(name)
    local strWidth = buttontext:GetWidth()
    buttontext:SetPoint("TOPRIGHT", buttonframe, "TOPRIGHT")
    buttontext:SetSize(strWidth + 24, 32)
    local sizeX = strWidth + 42
    local padding = -8

    buttonframe:SetNormalTexture(ROOT_PATH .. "textures\\UI-CHARACTER-INACTIVETAB.tga")
    buttonframe:SetPushedTexture(ROOT_PATH .. "textures\\UI-CHARACTER-ACTIVETAB.tga")
    buttonframe:SetScript("OnClick", button.onclick)
    buttonframe:RegisterForClicks("AnyUp")
    buttonframe:SetSize(sizeX,32)

    button.icon = buttonframe:CreateTexture(nil, "OVERLAY")
    button.icon:SetSize(iconSize, iconSize)
    button.icon:SetPoint("LEFT", buttonframe, "LEFT", 12, 0)

    if tab.object and tab.object.iconTex then
        button.icon:SetTexture(tab.object.iconTex)
    else
        button.icon:Hide()
    end

    local rightSide = tab.object and tab.object.rightSide

    if rightSide then
        button.frame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", (tabStartRight + tabOffsetRight) * -1, 12)
        tabOffsetRight = tabOffsetRight + sizeX + padding
    else
        button.frame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", tabStartLeft + tabOffsetLeft, 12)
        tabOffsetLeft = tabOffsetLeft + sizeX + padding
    end

    return button
end

-- tab is a frame that wraps an object that has actual implementation and
-- receives events, objects are references in tabInitList
local function CreateTab(name, frame, tabNum, tabGroup)
    local tab = {}
    tab.name = name
    tab.num = tabNum
    tab.group = tabGroup
    tab.object = _util.Where(_self.tabInitList, function(k,v)
        if v.id == name then return true end
    end)
    tab.button = CreateTabButton(name, ROOT_FRAME, tab)


    local bUseFullFrame = false
    local bUseBackground = false
    if tab.object ~= nil then
        bUseFullFrame = tab.object.useFullFrame
        bUseBackground = tab.object.useBackground
    end
    tab.outerframe = CreateFrame("Frame", "pp_tab_outer_" .. name, frame)
    local outerframe = tab.outerframe
    outerframe:SetFrameLevel(2)

    if bUseFullFrame then
        outerframe:SetPoint("TOPLEFT", 169, -26)
        outerframe:SetWidth(625)
        outerframe:SetHeight(362)
    else
        outerframe:SetPoint("TOPLEFT", 390, -26)
        outerframe:SetWidth(400)
        outerframe:SetHeight(362)
    end

    if bUseBackground then
        local frameBg = outerframe:CreateTexture(nil)
        frameBg:SetTexture(ROOT_PATH .. "textures\\tabBg.tga")
        frameBg:SetPoint("TOPLEFT", 0, 0)
        frameBg:SetWidth(outerframe:GetWidth())
        frameBg:SetHeight(outerframe:GetHeight())
    end

    tab.innerframe = CreateFrame("Frame", "pp_tab_inner_" .. name, tab.outerframe)
    local innerframe = tab.innerframe
    --tab.innerframe:SetFrameStrata("HIGH")
    innerframe:SetFrameLevel(3)
    innerframe:SetPoint("TOPLEFT", 0, 0)
    innerframe:SetWidth(outerframe:GetWidth())
    innerframe:SetHeight(outerframe:GetHeight())

    tab.subtabs = {}
    tab.activeSubTab = nil


    tab.SetSubTab = function (self, index)
        for i=0, getn(self.subtabs) do
            local subtab = self.subtabs[i]
            if subtab and subtab:IsShown() then 
                subtab.button:SetButtonState("NORMAL", false)
                subtab.onDeactivate:Invoke(subtab)
                subtab:Hide()
            end
        end

        self.activeSubTab = self.subtabs[index]
        if self.activeSubTab then
            self.activeSubTab.button:SetButtonState("PUSHED", true)
            PlaySound("INTERFACESOUND_CHARWINDOWTAB")
            self.activeSubTab:Show()
            self.activeSubTab.onActivate:Invoke(self.activeSubTab)
        end
    end

    -- creates and returns a side button
    tab.CreateSubtabButton = function (self, icon, subtab, stringTooltip)
        local button = CreateFrame("Button", "pp_tab_sidebtn_" .. subtab.name, self.outerframe)
        local size = 54
        button.tab = self
        button.subtab = subtab
        
        button:SetPoint("TOPRIGHT", self.outerframe, 65, 55 - (subtab.idx * (size - 4)))
        button:SetSize(size,size)
        button:SetNormalTexture(ROOT_PATH .. "textures\\sideTab_norm.tga")
        button:SetHighlightTexture(ROOT_PATH .. "textures\\sideTab_hi.tga")
        button:SetPushedTexture(ROOT_PATH .. "textures\\sideTab_push.tga")
        button.icon = button:CreateTexture(nil, "OVERLAY", nil, -7)
        button.icon:SetPoint("TOPLEFT", 3, -9)
        button.icon:SetSize(37,37)
        button.icon:SetTexture(icon)
        button:EnableMouse(true)
        button.stringTooltip = stringTooltip
        _tooltips.AddInfoTooltip(button, stringTooltip)

        button:SetScript("OnClick", function(self, button, down)
            if self.tab.activeSubTab == self.subtab then return end
            self.tab:SetSubTab(self.subtab.idx)
        end)

        return button
    end

    -- creates a subtab and links it to the side button
    tab.CreateSubTab = function (self, icon, stringTooltip, name, onActivate, onDeactivate)
        local subtab = CreateFrame("Frame", "pp_subtab_" .. name, self.innerframe) 
        subtab.name = name
        subtab:SetAllPoints(self.innerframe)
        subtab:SetFrameLevel(self.innerframe:GetFrameLevel() + 1)
        subtab.idx = getn(self.subtabs) + 1
        subtab.onActivate = _util.CreateEvent()
        if onActivate then
            subtab.onActivate:Add(onActivate)
        end
        subtab.onDeactivate = _util.CreateEvent()
        if onDeactivate then
            subtab.onDeactivate:Add(onDeactivate)
        end
        subtab.button = self:CreateSubtabButton(icon, subtab, stringTooltip)

        tinsert(self.subtabs, subtab)
        return subtab
    end

    if tab.object ~= nil then
        tab.object:Init(tab)
    end

    tab.activate = function(self)
        self.button.frame:SetButtonState("PUSHED", true)
        _util.SetTextColor(self.button.text, _data.colors.white)
        if self.object ~= nil then
            self.outerframe:Show()
            frame.activeTabLabel:SetText(tab.name)
            self.object:OnActivate(tab)

            if not self.activeSubTab then
                local defaultSubtab = _eval(self.object.defaultSubTab, self.object.defaultSubTab, 1)
                self:SetSubTab(defaultSubtab)
            end
        end
    end
    tab.deactivate = function(self)
        self.button.frame:SetButtonState("NORMAL", false)
        _util.SetTextColor(self.button.text, _data.colors.gold)
        if self.object ~= nil then
            self.outerframe:Hide()
            self.object:OnDeactivate(self)

            if self.activeSubTab then
                self:SetSubTab(-1)
            end
        end
    end

    tab.outerframe:Hide()
    return tab
end

local function CreateTabGroup(tabsList, defaultTabName)
    local i = 0
    local group = {}
    group.tabs = {}
    group.activeTab = nil
    group.setTabActive = function(name)
        local foundTab = _util.Where(group.tabs, function(k,v)
            if k == name then return true end
        end)
        if group.activeTab == foundTab then
            return -- if already active
        end
      
        if foundTab ~= nil then
            if foundTab ~= group.activeTab and group.activeTab ~= nil then
                group.activeTab:deactivate() -- disable active tab first
            end
            group.activeTab = foundTab
            group.activeTab:activate()
            if group.activeTab.object.customSound then
                PlaySound(group.activeTab.object.customSound)
            else
                PlaySound(_data.sounds.onTabSwitch)
            end
        end
    end
    
    for k,v in pairs(tabsList) do
        group.tabs[v] = CreateTab(v, ROOT_FRAME, i, group)
        i = i + 1
    end
    group.setTabActive(defaultTabName)
    return group
end

function _self:SetupTabs()
    _self.mainTabGroup = CreateTabGroup({ "Stats", "Items", "Quests", "Spells", "Talents", "Strategies", "Commands", "Settings"}, _cfg.defaultOpenTab)
end



