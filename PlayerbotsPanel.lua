ROOT_PATH     = "Interface\\AddOns\\PlayerbotsPanel\\"
PlayerbotsPanel    = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceHook-2.1", "AceDebug-2.0", "AceEvent-2.0")
PlayerbotsFrame    = CreateFrame("Frame", "PlayerbotsPanelFrame", UIParent)
PlayerbotsPanel:RegisterDB("PlayerbotsPanelDb", "PlayerbotsPanelDbPerChar")

local _cfg = PlayerbotsPanelConfig
local _data = PlayerbotsPanelData
local _util = PlayerbotsPanelUtil
local _debug = AceLibrary:GetInstance("AceDebug-2.0")
local _updateHandler = PlayerbotsPanelUpdateHandler
local _broker = PlayerbotsBroker
local _tooltips = PlayerbotsPanelTooltips
local _dbchar = {}
local _dbaccount = {}
local CALLBACK_TYPE = PlayerbotsBrokerCallbackType
local QUERY_TYPE = PlayerbotsBrokerQueryType

-- references to tab objects that will be initialized, declared in corresponding files
PlayerbotsPanel.tabInitList = 
{
    PlayerbotsPanelTabCommands,
    PlayerbotsPanelTabInventory,
    PlayerbotsPanelTabQuests,
    PlayerbotsPanelTabSettings,
    PlayerbotsPanelTabSpells,
    PlayerbotsPanelTabStats,
    PlayerbotsPanelTabStrategies,
    PlayerbotsPanelTabTalents,
}

PlayerbotsPanel.mainTabGroup = { }

-- when target switches this gets populated
PlayerbotsPanel.targetData =
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
PlayerbotsPanel.commands = {
    type = 'group',
    args = {
        toggle = {
            name = "toggle",
            desc = "Toggle PlayerbotsPanel",
            type = 'execute',
            func = function() PlayerbotsPanel:OnClick() end
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



PlayerbotsGearView = {}
-- root frame of the paperdoll view for bots
local PlayerbotsGear     = CreateFrame("Frame", "PlayerbotsGear", PlayerbotsFrame)
PlayerbotsGearView.frame = PlayerbotsGear
-- renders the bot 3d model
local ModelViewFrame     = CreateFrame("PlayerModel", "ModelViewFrame", PlayerbotsFrame)
PlayerbotsGearView.modelView = ModelViewFrame

function PlayerbotsPanel:OnInitialize()
    _debug:SetDebugging(true)
    _debug:SetDebugLevel(_cfg.debugLevel)
    _dbchar = PlayerbotsPanel.db.char
    if _dbchar.bots == nil then
      _dbchar.bots = {}
    end
    for name, bot in pairs(_dbchar.bots) do
        PlayerbotsPanel:ValidateBotData(bot)
    end
    _dbaccount = PlayerbotsPanel.db.account
    _updateHandler:Init()
    _broker:Init(_dbchar.bots)

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

end

function PlayerbotsPanel:OnEnable()
    self:SetDebugging(true)

    PlayerbotsFrame:Show()
    PlayerbotsPanel:UpdateBotSelector()
    print("onEnable")
    _broker:OnEnable()
end

function PlayerbotsPanel:OnDisable()
    self:SetDebugging(false)
    print("onDisable")
    _broker:OnDisable()
end

function PlayerbotsPanel:OnShow()
    PlaySound(_data.sounds.onAddonShow)
    PlayerbotsPanel:UpdateBots()
end

function PlayerbotsPanel:OnHide()
    PlaySound(_data.sounds.onAddonHide)
end

function PlayerbotsPanel:Update(elapsed)
    _updateHandler:Update(elapsed)
end

function PlayerbotsPanel:ClosePanel()
	HideUIPanel(PlayerbotsFrame)
end

function PlayerbotsPanel:print(t)
    DEFAULT_CHAT_FRAME:AddMessage("PlayerbotsPanel: " .. t)
end

function PlayerbotsPanel:PLAYER_TARGET_CHANGED()
    if UnitIsPlayer("target") then
        PlayerbotsPanel:ExtractTargetData()
        PlayerbotsPanel:SetSelectedBot(UnitName("target"))
    end
end

function PlayerbotsPanel:PARTY_MEMBERS_CHANGED()
    _broker:PARTY_MEMBERS_CHANGED()
    PlayerbotsPanel:UpdateBots()
end

function PlayerbotsPanel:PARTY_MEMBER_ENABLE()
    _broker:PARTY_MEMBER_ENABLE()
    PlayerbotsPanel:UpdateBots()
end

function PlayerbotsPanel:PARTY_MEMBER_DISABLE()
    _broker:PARTY_MEMBER_DISABLE()
end

function PlayerbotsPanel:TRADE_CLOSED()
    --_updateHandler:DelayCall(0.25, function()
    --    PlayerbotsPanel:UpdateBots()
    --    PlayerbotsPanel:RefreshSelection()
    --end)
end

function PlayerbotsPanel:UNIT_MODEL_CHANGED()
end

function PlayerbotsPanel:PLAYER_LOGIN()
    _broker:PLAYER_LOGIN()
end

function PlayerbotsPanel:PLAYER_LOGOUT()
    _broker:PLAYER_LOGOUT()
end

function PlayerbotsPanel:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
    _broker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
end

function PlayerbotsPanel:CHAT_MSG_ADDON(prefix, message, channel, sender)
    _broker:CHAT_MSG_ADDON(prefix, message, channel, sender)
end

function PlayerbotsPanel:CHAT_MSG_SYSTEM(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter)
    --_broker:CHAT_MSG_SYSTEM(prefix, message, channel, sender)
end

function PlayerbotsPanel:GetBot(name)
    if _dbchar.bots ~= nil then
        return _dbchar.bots[name]
    end
    return nil
end

function PlayerbotsPanel:ExtractTargetData()
    local _name = UnitName("target")
    local race, racetoken = UnitRace("target")
    PlayerbotsPanel.targetData = {
        isPlayer = UnitIsPlayer("target"),
        guid = UnitGUID("target"),
        isRegistered = _util:Where(_dbchar.bots, function(k,v)
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


function PlayerbotsPanel:CreateBotData(name)
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
    PlayerbotsPanel:ValidateBotData(bot)
    _dbchar.bots[name] = bot
    return bot
end

--- May seem overboard but it allows to adjust the layout of the data after it was already serialized
function PlayerbotsPanel:ValidateBotData(bot)
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
    EnsureField(bot.currency, "honor", 0)
    EnsureField(bot.currency, "other", {})

    EnsureField(bot, "items", {})
    
    EnsureField(bot, "bags", {})
    EnsureField(bot.bags,1, {})
    EnsureField(bot.bags[1], "link", nil)
    EnsureField(bot.bags[1], "count", 0)
    EnsureField(bot.bags[1], "max", 16)
    EnsureField(bot.bags[1], "contents", {})
end

-- Update single bot
function PlayerbotsPanel:UpdateBot(name, bot)
    local status = _broker:GetBotStatus(name)

    if status.party and status.online then
        if CanInspect(name, true) and CheckInteractDistance(name, 1) then
            NotifyInspect(name)
            for slot=1, 19 do
                bot.items[slot] = {}
                local item = bot.items[slot]
                item.link = GetInventoryItemLink(name, slot)
                if item.link ~= nil then
                    item.count = GetInventoryItemCount(name, slot)
                end
            end
            ClearInspectPlayer()
        end
    end
end

-- Update all bots
-- BOT DATA IS ONLY UPDATED IF THE BOT IS IN PARTY
function PlayerbotsPanel:UpdateBots()
    for k, bot in pairs(_dbchar.bots) do
        PlayerbotsPanel:UpdateBot(k, bot)
    end
end

function PlayerbotsPanel:RegisterByName(name)
    if _dbchar.bots[name] == nil then
        _dbchar.bots[name] = PlayerbotsPanel:CreateBotData(name)
    end
    PlayerbotsPanel:UpdateBots()
    PlayerbotsPanel:UpdateBotSelector()
    PlayerbotsPanel:SetSelectedBot(name)
end

function PlayerbotsPanel:UnregisterByName(name)
    if _dbchar.bots[name] ~= nil then
        _dbchar.bots = _util:RemoveByKey(_dbchar.bots, name)
    end
    PlayerbotsPanel:ClearSelection()
    PlayerbotsPanel:UpdateBotSelector()
end

function PlayerbotsPanel:RefreshSelection()
    _updateHandler:DelayCall(0.25, function()
        local selected = PlayerbotsPanel:GetSelectedBot()
        if selected ~= nil then
            PlayerbotsPanel:UpdateBots()
            PlayerbotsPanel:SetSelectedBot(selected.name)
        end
    end)
end

function PlayerbotsPanel:ClearSelection()
    PlayerbotsPanel:UpdateBots()
    for name, bot in pairs(_dbchar.bots) do
        if bot.selected then
            bot.selected = false
            PlayerbotsPanel:UpdateBotSelectorButton(name)
        end
    end
    PlayerbotsPanel:UpdateGearView(nil)
end

function PlayerbotsPanel:GetSelectedBot()
    for name, bot in pairs(_dbchar.bots) do
        if bot.selected then
            return bot
        end
    end
    return nil
end

function PlayerbotsPanel:SetSelectedBot(botname)
    local bot = PlayerbotsPanel:GetBot(botname)
    if bot == nil then return end
    PlayerbotsPanel:UpdateBots()
    for name, bot in pairs(_dbchar.bots) do
        if name == botname then
            if not bot.selected then
                bot.selected = true
                PlayerbotsPanel:UpdateBotSelectorButton(botname)
            end
        else
            if bot.selected then
                bot.selected = false
                PlayerbotsPanel:UpdateBotSelectorButton(bot.name)
            end
        end
    end

    PlayerbotsPanel:UpdateGearView(botname)
    PlaySound(_data.sounds.onBotSelect)
end

function PlayerbotsPanel:OnClick()
    if PlayerbotsFrame:IsVisible() then
        PlayerbotsFrame:Hide()
    else 
        PlayerbotsFrame:Show()
    end
end

local function UpdateGearSlot(bot, slotNum)
    local slot = PlayerbotsGearView.slots[slotNum + 1]
    local botItem = nil

    if bot then
        botItem = bot.items[slotNum]
    end

    if bot == nil or botItem == nil or botItem.link == nil then -- if empty
        slot.item = nil
        slot.itemTex:Hide()
        slot.qTex:Hide()
    else 
        slot.bot = bot
        if slot.item == nil then
            slot.item = {}
        end

        local sitem = slot.item
        sitem.name, sitem.link, sitem.quality, sitem.iLevel, sitem.reqLevel, sitem.class, sitem.subclass, sitem.maxStack, sitem.equipSlot, sitem.texture, sitem.vendorPrice = GetItemInfo(botItem.link)
        slot.itemTex:Show()
        slot.itemTex:SetTexture(sitem.texture)
        local r, g, b, _ = GetItemQualityColor(sitem.quality)
        slot.qColor = { r = r, g = g, b = b }
        slot.qTex:Show()
        slot.qTex:SetVertexColor(r,g,b)
    end
end

-- supports NIL as arg, will clear everything
function PlayerbotsPanel:UpdateGearView(name)
    -- get bot 
    local clearMode = false
    if name == nil then 
      clearMode = true
    end

    if clearMode then
        PlayerbotsGearView.modelView:Hide()
        PlayerbotsGearView.botName:SetText("")
        PlayerbotsGearView.botDescription:SetText("")
        PlayerbotsGearView.dropFrame:Hide()
        for i=1, 19 do 
            UpdateGearSlot(nil, i)
        end
    else
        local bot = PlayerbotsPanel:GetBot(name)
        if bot == nil then return end
        
        local status = _broker:GetBotStatus(name)

        if status.online  then
            PlayerbotsGearView.modelView:Show()
            if status.party then
                PlayerbotsGearView.modelView:SetUnit(name)
                PlayerbotsGearView.dropFrame:Show()
            end
            PlayerbotsGearView.modelView.bgTex:SetTexture(_data.raceData[bot.race].background)
        else
            PlayerbotsGearView.modelView:Hide()
        end

        local statusStr = "Level " .. bot.level 
        _util:SetTextColor(PlayerbotsGearView.botDescription, _data.colors.gold)
      
        if not status.online then
            statusStr = statusStr .. " (Cached)"
            _util:SetTextColor(PlayerbotsGearView.botDescription, _data.colors.gray)
        end
      
        PlayerbotsGearView.botName:SetText(bot.name)
        PlayerbotsGearView.botDescription:SetText(statusStr)
        _util:SetTextColorToClass(PlayerbotsGearView.botName, bot.class)
      
        if bot.currency then
            PlayerbotsGearView.txtGold:SetText(bot.currency.gold)
            PlayerbotsGearView.txtSilver:SetText(bot.currency.silver)
            PlayerbotsGearView.txtCopper:SetText(bot.currency.copper)
        else
            PlayerbotsGearView.txtGold:SetText("?")
            PlayerbotsGearView.txtSilver:SetText("?")
            PlayerbotsGearView.txtCopper:SetText("?")
        end
      
        for i=1, 19 do 
            UpdateGearSlot(bot, i)
        end
    end
end

function PlayerbotsPanel:SetupGearSlot(id, x, y)
    if PlayerbotsGearView.slots == nil then
        PlayerbotsGearView.slots = {}
    end

    local slots = PlayerbotsGearView.slots
    if slots[id] == nil then
        slots[id] = CreateFrame("Button", nil, PlayerbotsGearView.frame)
    end

    local slot = slots[id]
    slot.id = id
    local slotSize = 38
    slot:SetPoint("TOPLEFT", x, y)
    slot:SetSize(slotSize, slotSize)
    slot:SetScript("OnEnter", function(self, motion)
        slot.hitex:Show()
        if slot.item ~= nil and slot.item.link ~= nil then
            _tooltips.tooltip:SetOwner(slot, "ANCHOR_RIGHT")
            _tooltips.tooltip:SetHyperlink(slot.item.link)
            slot.hitex:SetVertexColor(slot.qColor.r, slot.qColor.g, slot.qColor.b)
        end
    end)
    slot:SetScript("OnLeave", function(self, motion)
        local c = _data.colors.defaultSlotHighlight
        slot.hitex:SetVertexColor( c.r, c.g, c.b)
        slot.hitex:Hide()
        _tooltips.tooltip:Hide()
    end)
    slot:SetScript("OnClick", function(self, button, down)
        if slot.item and slot.bot then
            if button == "LeftButton" then
                SendChatMessage("ue " .. slot.item.link, "WHISPER", nil, slot.bot.name)
                PlayerbotsPanel:RefreshSelection()
            elseif button == "RightButton" then
            end
        end
    end)

    slot.bgTex = slot:CreateTexture(nil, "BACKGROUND")
    slot.bgTex:SetTexture(_data.textures.slotIDbg[id])
    slot.bgTex:SetPoint("TOPLEFT", 0, 0)
    slot.bgTex:SetWidth(slotSize)
    slot.bgTex:SetHeight(slotSize)
    slot.bgTex:SetVertexColor(0.75,0.75,0.75)

    slot.itemTex = slot:CreateTexture(nil, "BORDER")
    slot.itemTex:SetTexture(_data.textures.slotIDbg[id])
    slot.itemTex:SetPoint("TOPLEFT", 0, 0)
    slot.itemTex:SetWidth(slotSize)
    slot.itemTex:SetHeight(slotSize)
    slot.itemTex:Hide()

    slot.qTex = slot:CreateTexture(nil, "OVERLAY")
    slot.qTex:SetTexture(_data.textures.slotHi)
    slot.qTex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    slot.qTex:SetBlendMode("ADD")
    slot.qTex:SetPoint("TOPLEFT", 0, 0)
    slot.qTex:SetWidth(slotSize)
    slot.qTex:SetHeight(slotSize)
    slot.qTex:SetAlpha(0.75)
    slot.qTex:SetVertexColor(1,1,1)
    slot.qTex:Hide()

    slot.hitex = slot:CreateTexture(nil, "OVERLAY")
    slot.hitex:SetTexture(_data.textures.slotHi)
    slot.hitex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    slot.hitex:SetBlendMode("ADD")
    slot.hitex:SetPoint("TOPLEFT", 0, 0)
    slot.hitex:SetWidth(slotSize)
    slot.hitex:SetHeight(slotSize)
    slot.hitex:SetAlpha(0.75)
    local c = _data.colors.defaultSlotHighlight
    slot.hitex:SetVertexColor( c.r, c.g, c.b)
    slot.hitex:Hide()
end

function PlayerbotsPanel:DropItemSelected()
    DropItemOnUnit(PlayerbotsPanel:GetSelectedBot().name)
    _updateHandler:DelayCall(0.25, function()
        AcceptTrade()
    end)
end

function PlayerbotsPanel:SetupGearFrame()
    ModelViewFrame:SetFrameStrata("DIALOG")
    ModelViewFrame:SetWidth(200)
    ModelViewFrame:SetHeight(300)
    ModelViewFrame:SetPoint("CENTER", -125, 0)

    PlayerbotsGear:SetFrameStrata("DIALOG")
    PlayerbotsGear:SetFrameLevel(100)
    	PlayerbotsGear:SetPoint("TOPLEFT", 169, -26)
    PlayerbotsGear:SetWidth(219)
    PlayerbotsGear:SetHeight(362)

    PlayerbotsGearView.dropFrame = CreateFrame("Button", nil, PlayerbotsGear)
    local dropFrame = PlayerbotsGearView.dropFrame
    dropFrame:SetFrameLevel(1000)
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
            PlayerbotsPanel:DropItemSelected()
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

    PlayerbotsGearView.botName = PlayerbotsGear:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    PlayerbotsGearView.botName:SetText("No selection")
    PlayerbotsGearView.botName:SetJustifyH("LEFT")
    PlayerbotsGearView.botName:SetPoint("TOPLEFT", PlayerbotsGear, 5, -5)
    PlayerbotsGearView.botName:SetTextColor(1, 1, 1, 1)

    PlayerbotsGearView.botDescription = PlayerbotsGear:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    PlayerbotsGearView.botDescription:SetText("No selection")
    PlayerbotsGearView.botDescription:SetJustifyH("LEFT")
    PlayerbotsGearView.botDescription:SetPoint("TOPLEFT", PlayerbotsGear, 5, -18)
    _util:SetTextColor(PlayerbotsGearView.botDescription, _data.colors.gold)

    local moneyposY = -15
    PlayerbotsGearView.iconCopper = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    PlayerbotsGearView.iconCopper:SetPoint("TOPLEFT", PlayerbotsGear, 100, moneyposY)
    PlayerbotsGearView.iconCopper:SetTexture("Interface\\MONEYFRAME\\UI-CopperIcon.blp")
    PlayerbotsGearView.iconCopper:SetSize(12, 12)

    PlayerbotsGearView.txtCopper = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    PlayerbotsGearView.txtCopper:SetPoint("TOPLEFT", PlayerbotsGear, 111, moneyposY)
    PlayerbotsGearView.txtCopper:SetJustifyH("LEFT")
    PlayerbotsGearView.txtCopper:SetSize(20, 12)
    PlayerbotsGearView.txtCopper:SetText("99")

    PlayerbotsGearView.iconSilver = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    PlayerbotsGearView.iconSilver:SetPoint("TOPLEFT", PlayerbotsGear, 127, moneyposY)
    PlayerbotsGearView.iconSilver:SetTexture("Interface\\MONEYFRAME\\UI-SilverIcon.blp")
    PlayerbotsGearView.iconSilver:SetSize(12, 12)

    PlayerbotsGearView.txtSilver = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    PlayerbotsGearView.txtSilver:SetPoint("TOPLEFT", PlayerbotsGear, 137, moneyposY)
    PlayerbotsGearView.txtSilver:SetJustifyH("LEFT")
    PlayerbotsGearView.txtSilver:SetSize(20, 12)
    PlayerbotsGearView.txtSilver:SetText("99")

    PlayerbotsGearView.iconGold = PlayerbotsGear:CreateTexture(nil, "OVERLAY")
    PlayerbotsGearView.iconGold:SetPoint("TOPLEFT", PlayerbotsGear, 155, moneyposY)
    PlayerbotsGearView.iconGold:SetTexture("Interface\\MONEYFRAME\\UI-GoldIcon.blp")
    PlayerbotsGearView.iconGold:SetSize(12, 12)

    PlayerbotsGearView.txtGold = PlayerbotsGear:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    PlayerbotsGearView.txtGold:SetPoint("TOPLEFT", PlayerbotsGear, 165, moneyposY)
    PlayerbotsGearView.txtGold:SetJustifyH("LEFT")
    PlayerbotsGearView.txtGold:SetSize(40, 12)
    PlayerbotsGearView.txtGold:SetText("99999")


    PlayerbotsGearView.helpIcon = CreateFrame("Frame", nil, PlayerbotsGear)
    local helpIcon = PlayerbotsGearView.helpIcon
    helpIcon:SetFrameLevel(5000)
    helpIcon:Show()
    helpIcon:SetPoint("TOPRIGHT", -5, -5)
    helpIcon:SetSize(15, 15)
    helpIcon:EnableMouse(true)

    helpIcon.tex = helpIcon:CreateTexture(nil, "OVERLAY")
    helpIcon.tex:SetPoint("TOPLEFT")
    helpIcon.tex:SetSize(helpIcon:GetWidth(), helpIcon:GetHeight())
    helpIcon.tex:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon.blp")
    _tooltips:AddInfoTooltip(helpIcon, _data.strings.tooltips.gearViewHelp)
  
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
    PlayerbotsPanel:SetupGearSlot(INVSLOT_HEAD + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_NECK+ intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_SHOULDER + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_BACK + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_CHEST + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_BODY + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_TABARD + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_WRIST + intOffset, slotPosX, slotPosY)
    -- lower row
    slotPosX = 48
    PlayerbotsPanel:SetupGearSlot(INVSLOT_MAINHAND + intOffset, slotPosX, slotPosY)
    slotPosX = slotPosX + slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_OFFHAND + intOffset, slotPosX, slotPosY)
    slotPosX = slotPosX + slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_RANGED + intOffset, slotPosX, slotPosY)
    -- right column
    slotPosY = -32
    slotPosX = 172
    PlayerbotsPanel:SetupGearSlot(INVSLOT_HAND + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_WAIST + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_LEGS + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_FEET + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_FINGER1 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_FINGER2 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_TRINKET1 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY
    PlayerbotsPanel:SetupGearSlot(INVSLOT_TRINKET2 + intOffset, slotPosX, slotPosY)
    slotPosY = slotPosY - slotOffsetY

    PlayerbotsGearView.onUpdatedEquipSlot = function(bot, slotNum, itemLink)
        if bot.selected then 
            UpdateGearSlot(bot, slotNum)
        end
    end

    _broker:RegisterGlobalCallback(CALLBACK_TYPE.UPDATED_EQUIP_SLOT, PlayerbotsGearView.onUpdatedEquipSlot)

end

function PlayerbotsPanel:CreateWindow()
    UIPanelWindows[PlayerbotsFrame:GetName()] = { area = "center", pushable = 0, whileDead = 1 }
    tinsert(UISpecialFrames, PlayerbotsFrame:GetName())
    PlayerbotsFrame:HookScript("OnUpdate", PlayerbotsPanel.Update)
    PlayerbotsFrame:SetFrameStrata("DIALOG")
    PlayerbotsFrame:SetWidth(800)
    PlayerbotsFrame:SetHeight(420)
    PlayerbotsFrame:SetPoint("CENTER")
    PlayerbotsFrame:SetMovable(true)
    PlayerbotsFrame:RegisterForDrag("LeftButton")
    PlayerbotsFrame:SetScript("OnDragStart", PlayerbotsFrame.StartMoving)
    PlayerbotsFrame:SetScript("OnDragStop", PlayerbotsFrame.StopMovingOrSizing)
    PlayerbotsFrame:SetScript("OnShow", PlayerbotsPanel.OnShow)
    PlayerbotsFrame:SetScript("OnHide", PlayerbotsPanel.OnHide)
    PlayerbotsFrame:EnableMouse(true)

    _tooltips:Init(UIParent)

    PlayerbotsPanel:SetupGearFrame()
    PlayerbotsPanel:AddWindowStyling(PlayerbotsFrame)

    PlayerbotsPanel.botSelectorParentFrame = CreateFrame("ScrollFrame", "botSelector", PlayerbotsFrame, "FauxScrollFrameTemplate")
    PlayerbotsPanel.botSelectorParentFrame:SetPoint("TOPLEFT", 0, -24)
    PlayerbotsPanel.botSelectorParentFrame:SetSize(140, 368)
    
    PlayerbotsPanel.botSelectorFrame = CreateFrame("Frame")
    PlayerbotsPanel.botSelectorParentFrame:SetScrollChild(PlayerbotsPanel.botSelectorFrame)
    PlayerbotsPanel.botSelectorFrame:SetPoint("TOPLEFT", 10,0)
    PlayerbotsPanel.botSelectorFrame:SetWidth(PlayerbotsPanel.botSelectorParentFrame:GetWidth()-18)
    PlayerbotsPanel.botSelectorFrame:SetHeight(1) 

    PlayerbotsPanel:SetupTabs()
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
function PlayerbotsPanel:CreateBotSelectorButton(name)
    local bot = PlayerbotsPanel:GetBot(name)
    if not bot then
        error("FATAL: PlayerbotsPanel:CreateBotSelectorButton() missing bot!" .. name)
        return
    end

    local rootFrame = nil
    
    rootFrame = CreateFrame("Frame", nil, PlayerbotsPanel.botSelectorFrame)
    botSelectorButtons[name] = rootFrame

    rootFrame.statusUpdateHandler = function(bot, status)
        PlayerbotsPanel:UpdateBotSelectorButton(bot.name)
    end
    _broker:RegisterCallback(CALLBACK_TYPE.UPDATED_STATUS, name, rootFrame.statusUpdateHandler)


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
            PlayerbotsPanel:SetSelectedBot(bot.name)
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
        _tooltips:AddInfoTooltip(oFrame.btnAdd, _data.strings.tooltips.addBot)
        oFrame.btnAdd:SetNormalTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Up")
        oFrame.btnAdd:SetPushedTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Down.blp")
        oFrame.btnAdd:SetHighlightTexture("Interface\\BUTTONS\\UI-AttributeButton-Encourage-Hilight.blp")
        oFrame.btnAdd:SetScript("OnClick", function(self, button, down)
            SendChatMessage(".playerbots bot add " .. name)
            PlayerbotsPanel:RefreshSelection()
        end)
    end

    if oFrame.btnInvite == nil then
        oFrame.btnInvite = CreateFrame("Button", nil, oFrame)
        oFrame.btnInvite:SetNormalTexture("Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon.blp")
        oFrame.btnInvite:SetPushedTexture("Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon.blp")
        _tooltips:AddInfoTooltip(oFrame.btnInvite, _data.strings.tooltips.inviteBot)
        oFrame.btnInvite:SetScript("OnClick", function(self, button, down)
            InviteUnit(name)
            PlayerbotsPanel:RefreshSelection()
        end)
    end

    if oFrame.btnUninvite == nil then
        oFrame.btnUninvite = CreateFrame("Button", nil, oFrame)
        oFrame.btnUninvite:SetNormalTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up.blp")
        oFrame.btnUninvite:SetHighlightTexture("Interface\\BUTTONS\\UI-GroupLoot-Pass-Up.blp")
        _tooltips:AddInfoTooltip(oFrame.btnUninvite,_data.strings.tooltips.uninviteBot )
        oFrame.btnUninvite:SetScript("OnClick", function(self, button, down)
            UninviteUnit(name)
            PlayerbotsPanel:RefreshSelection()
        end)
    end

    if oFrame.btnRemove == nil then
        oFrame.btnRemove = CreateFrame("Button", nil, oFrame)
        oFrame.btnRemove:SetNormalTexture("Interface\\BUTTONS\\UI-MinusButton-Up.blp")
        oFrame.btnRemove:SetPushedTexture("Interface\\BUTTONS\\UI-MinusButton-Down.blp")
        _tooltips:AddInfoTooltip(oFrame.btnRemove, _data.strings.tooltips.removeBot)
        oFrame.btnRemove:SetScript("OnClick", function(self, button, down)
            SendChatMessage(".playerbots bot remove " .. name)
            PlayerbotsPanel:RefreshSelection()
      end)
    end

    return rootFrame
end

function PlayerbotsPanel:UpdateBotSelectorButton(name)
    local bot = PlayerbotsPanel:GetBot(name)
    if not bot then
        error("FATAL: PlayerbotsPanel:UpdateBotSelectorButton(name) Missing bot! ")
        return end

    local rootFrame = botSelectorButtons[name]
    local idx = rootFrame.ppidx
    local width = rootFrame.ppwidth
    local height = rootFrame.ppheight
    local isTarget = UnitName("target") == bot.name
    local selected = bot.selected

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
    _util:SetTextColorToClass(oFrame.txtName, bot.class)
    
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
function PlayerbotsPanel:UpdateBotSelector()
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
            PlayerbotsPanel:CreateBotSelectorButton(name)
        end
        rootFrame = botSelectorButtons[name]
        rootFrame.ppidx = idx
        rootFrame.ppwidth = width
        rootFrame.ppheight = height
        PlayerbotsPanel:UpdateBotSelectorButton(name)
        idx = idx + 1
    end
end

function PlayerbotsPanel:AddWindowStyling(frame)
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
    close:SetScript("OnClick", PlayerbotsPanel.ClosePanel)

    local addonNameLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    addonNameLabel:SetText("Playerbots Panel")
	addonNameLabel:SetJustifyH("RIGHT")
	addonNameLabel:SetPoint("TOPRIGHT", frame, -70, -5)
	addonNameLabel:SetTextColor(0.6, 0.6, 1, 1)
	_util:SetTextColor(addonNameLabel, _data.colors.gold)

    local versionLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    versionLabel:SetText(PlayerbotsPanel.version)
	versionLabel:SetJustifyH("RIGHT")
	versionLabel:SetPoint("TOPRIGHT", frame, -30, -5)
	_util:SetTextColor(versionLabel, _data.colors.gray)

    frame.activeTabLabel = frame:CreateFontString(nil, "ARTWORK", "WorldMapTextFont")
    frame.activeTabLabel:SetText("TABNAME")
	frame.activeTabLabel:SetJustifyH("CENTER")
	frame.activeTabLabel:SetPoint("TOP", frame, 0, -3)
    frame.activeTabLabel:SetTextHeight(14)
    _util:SetTextColor(frame.activeTabLabel, _data.colors.gold)

    frame.updateBotsBtn = CreateFrame("Button", nil, frame)
    frame.updateBotsBtn:SetPoint("TOPLEFT", -5, 5)
    frame.updateBotsBtn:SetSize(30,30)
    frame.updateBotsBtn:SetNormalTexture(_data.textures.updateBotsUp)
    frame.updateBotsBtn:SetPushedTexture(_data.textures.updateBotsDown)
    frame.updateBotsBtn:SetScript("OnClick", function(self, button, down)
        PlayerbotsPanel:UpdateBots()
    end)
    _tooltips:AddInfoTooltip(frame.updateBotsBtn, _data.strings.tooltips.updateBots)
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
    button.frame = CreateFrame("Button", nil, frame)
    button.frame:SetText("") -- hide button built in text
    button.text = button.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetText(name)
    local strWidth = button.text:GetWidth()
    button.text:SetPoint("TOPRIGHT", button.frame, "TOPRIGHT")
    button.text:SetSize(strWidth + 24, 32)
    local sizeX = strWidth + 42
    local padding = -8

    button.frame:SetFrameStrata("DIALOG")
    button.frame:SetNormalTexture(ROOT_PATH .. "textures\\UI-CHARACTER-INACTIVETAB.tga")
    button.frame:SetPushedTexture(ROOT_PATH .. "textures\\UI-CHARACTER-ACTIVETAB.tga")
    button.frame:SetScript("OnClick", button.onclick)
    button.frame:RegisterForClicks("AnyUp")
    button.frame:SetSize(sizeX,32)

    button.icon = button.frame:CreateTexture(nil, "OVERLAY")
    button.icon:SetSize(iconSize, iconSize)
    button.icon:SetPoint("LEFT", button.frame, "LEFT", 12, 0)

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
    tab.object = _util:Where(PlayerbotsPanel.tabInitList, function(k,v)
        if v.id == name then return true end
    end)
    tab.button = CreateTabButton(name, PlayerbotsFrame, tab)


    local bUseFullFrame = false
    local bUseBackground = false
    if tab.object ~= nil then
        bUseFullFrame = tab.object.useFullFrame
        bUseBackground = tab.object.useBackground
    end
    tab.outerframe = CreateFrame("Frame", nil, frame)
    tab.outerframe:SetFrameStrata("DIALOG")

    if bUseFullFrame then
        tab.outerframe:SetPoint("TOPLEFT", 169, -26)
        tab.outerframe:SetWidth(625)
        tab.outerframe:SetHeight(362)
    else
        tab.outerframe:SetPoint("TOPLEFT", 390, -26)
        tab.outerframe:SetWidth(400)
        tab.outerframe:SetHeight(362)
    end

    if bUseBackground then
        local frameBg = tab.outerframe:CreateTexture(nil, "BACKGROUND")
        frameBg:SetTexture(ROOT_PATH .. "textures\\tabBg.tga")
        frameBg:SetPoint("TOPLEFT", 0, 0)
        frameBg:SetWidth(tab.outerframe:GetWidth())
        frameBg:SetHeight(tab.outerframe:GetHeight())
    end

    tab.innerframe = CreateFrame("Frame", nil, tab.outerframe)
    tab.innerframe:SetFrameStrata("DIALOG")
    tab.innerframe:SetFrameLevel(200)
    tab.innerframe:SetPoint("TOPLEFT", 0, 0)
    tab.innerframe:SetWidth(tab.outerframe:GetWidth())
    tab.innerframe:SetHeight(tab.outerframe:GetHeight())

    if tab.object ~= nil then
        tab.object:Init(tab)
    end

    tab.activate = function()
        tab.button.frame:SetButtonState("PUSHED", true)
        _util:SetTextColor(tab.button.text, _data.colors.white)
        if tab.object ~= nil then
            tab.outerframe:Show()
            frame.activeTabLabel:SetText(tab.name)
            tab.object:OnActivate(tab)
        end
    end
    tab.deactivate = function()
        tab.button.frame:SetButtonState("NORMAL", false)
        _util:SetTextColor(tab.button.text, _data.colors.gold)
        if tab.object ~= nil then
            tab.outerframe:Hide()
            tab.object:OnDeactivate(tab)
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
        local foundTab = _util:Where(group.tabs, function(k,v)
            if k == name then return true end
        end)
        if group.activeTab == foundTab then
            return -- if already active
        end
      
        if foundTab ~= nil then
            if foundTab ~= group.activeTab and group.activeTab ~= nil then
                group.activeTab.deactivate() -- disable active tab first
            end
            group.activeTab = foundTab
            group.activeTab.activate()
            PlaySound(_data.sounds.onTabSwitch)
        end
    end
    
    for k,v in pairs(tabsList) do
        group.tabs[v] = CreateTab(v, PlayerbotsFrame, i, group)
        i = i + 1
    end
    group.setTabActive(defaultTabName)
    return group
end

function PlayerbotsPanel:SetupTabs()
    PlayerbotsPanel.mainTabGroup = CreateTabGroup({ "Stats", "Items", "Quests", "Spells", "Talents", "Strategies", "Commands", "Settings"}, "Items")
end



