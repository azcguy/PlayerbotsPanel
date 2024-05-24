PlayerbotsPanelTabInventory = {}
local _self = PlayerbotsPanelTabInventory
PlayerbotsPanelTabInventory.id = "Items"
PlayerbotsPanelTabInventory.useFullFrame = false
PlayerbotsPanelTabInventory.useBackground = true
PlayerbotsPanelTabInventory.rightSide = false
PlayerbotsPanelTabInventory.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-inventory.tga"
PlayerbotsPanelTabInventory.customSound = "BAGMENUBUTTONPRESS"

local _broker = PlayerbotsBroker
local QUERY_TYPE = PlayerbotsBrokerQueryType
local _data = PlayerbotsPanelData
local _util = PlayerbotsPanelUtil
local _eval = _util.CompareAndReturn
local _floor = math.floor
local _cfg = PlayerbotsPanelConfig
local _tooltips = PlayerbotsPanelTooltips
local _tab = nil
local _frame = nil
local _slots = {}
local _scrollBarId = 1
local _slotsPerRow = 11

local _activeBagTab = nil
local _bagFrames = {} -- 1 bags, 2 bank

local _pool_itemSlots = _util.CreatePool(
    function ()
        local slot = PlayerbotsPanel.CreateSlot(nil, 35, 0, nil)
        slot.bgTex:SetVertexColor(0.4,0.4,0.4)
        return slot
    end,
    function (elem)
        elem:SetParent(nil)
        elem:SetItem(nil)
        elem:LockHighlight(false)
        elem:Hide()
    end
)

local function HandleSelectionChange(bot)
    if not bot then
        if _activeBagTab then
            _activeBagTab:Hide()
        end
    else 
        if _activeBagTab then
            _activeBagTab:Refresh(bot)
        end
    end
end

local function HandleQuery_INVENTORY_CHANGED(bot)
    if bot == PlayerbotsPanel.selectedBot then
        HandleSelectionChange(bot)
    end
end

function PlayerbotsPanelTabInventory:OnActivate(tab)
    _frame:Show()
    _broker:RegisterGlobalCallback(PlayerbotsBrokerCallbackType.INVENTORY_CHANGED, HandleQuery_INVENTORY_CHANGED)
end

function PlayerbotsPanelTabInventory:OnDeactivate(tab)
    _frame:Hide()
    _broker:UnregisterGlobalCallback(PlayerbotsBrokerCallbackType.INVENTORY_CHANGED, HandleQuery_INVENTORY_CHANGED)
end

function PlayerbotsPanelTabInventory:Init(tab)
    _tab = tab
    _frame = tab.innerframe

    _bagFrames[1] = _self.CreateBagsTab(1) -- bags
    _bagFrames[2] = _self.CreateBagsTab(2) -- bank
    _bagFrames[3] = _self.CreateBagsTab(3) -- keyring

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Bag_08.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
        end, nil, "Bags")

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Coin_02.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(2)
        end, nil, "Bank")

    tab:CreateSideButton("Interface\\ContainerFrame\\KeyRing-Bag-Icon.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(3)
        end, nil, "Keyring")

    PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
    PlayerbotsPanel.events.onBotSelectionChanged:Add(HandleSelectionChange)
end


function  PlayerbotsPanelTabInventory.ActivateBagsFrame(index) -- 1 bags, 2 bank
    local frame = _bagFrames[index]
    if frame then
        if frame == _activeBagTab and _activeBagTab then 
            _activeBagTab:Show()
            return
        end
        if _activeBagTab then
            _activeBagTab:Hide()
        end
        _activeBagTab = frame
        _activeBagTab:Show()
        _activeBagTab:Refresh(PlayerbotsPanel.selectedBot)
    end
end

local function  CreateBagSlot(iframe, size, id, bgtex)
    local bagSlot = PlayerbotsPanel.CreateSlot(iframe.topbar, 24, id, nil)
    bagSlot.itemStart = 0
    bagSlot.itemEnd = 0
    bagSlot.itemslots = iframe.itemslots
    bagSlot.onEnter:Add(function(self, motion)
        local length = self.itemEnd - self.itemStart
        if length == 0 then return end
        for i = self.itemStart, self.itemEnd do
            local islot = self.itemslots[i]
            if islot then
                islot:LockHighlight(true)
            end
        end
      end)
    bagSlot.onLeave:Add(function(self, motion)
        local length = self.itemEnd - self.itemStart
        if length == 0 then return end
        for i = self.itemStart, self.itemEnd do
            local islot = self.itemslots[i]
            if islot then
                islot:LockHighlight(false)
            end
        end
    end)
    return bagSlot
end

function  PlayerbotsPanelTabInventory.CreateBagsTab(bagtype)
    local topBarHeight = _cfg.inventory.topbarHeight
    -- create internal frame
    local width = _frame:GetWidth()
    local height = _frame:GetHeight()
    local iframe = CreateFrame("Frame", nil, _frame)
    iframe.bagtype = bagtype
    iframe:SetPoint("TOPLEFT", 0, 0)
    iframe:SetSize(width, height)
    iframe:SetFrameStrata("DIALOG")
    iframe:SetFrameLevel(140)
    -- create top bar frame
    iframe.topbar = CreateFrame("Frame", nil, iframe)
    iframe.topbar:SetFrameLevel(145)
    iframe.topbar:SetPoint("TOPLEFT")
    iframe.topbar:SetSize(width, topBarHeight)

    iframe.topbar.tex = iframe.topbar:CreateTexture(nil, "BORDER", nil, -7)
    iframe.topbar.tex:SetTexture(_data.textures.inventoryTopbar)
    iframe.topbar.tex:SetPoint("TOPLEFT")
    iframe.topbar.tex:SetSize(width + 4, topBarHeight + 12)
    -- create bag space frame with scroll

    local scrollBarName = "ppInventoryBagsScroll" .. _scrollBarId
    _scrollBarId = _scrollBarId + 1
    local bagsframe = CreateFrame("ScrollFrame", scrollBarName, iframe, "UIPanelScrollFrameTemplate")--CreateFrame("Frame", nil, iframe)
    iframe.bagsframe = bagsframe
    bagsframe:SetFrameLevel(144)
    bagsframe:SetPoint("TOPLEFT", 0, -topBarHeight)
    bagsframe:SetSize(width - 14, height - topBarHeight - 5)
    bagsframe.scrollbackground = CreateFrame("Frame", nil, bagsframe)
    bagsframe.scrollbackground:SetFrameStrata("DIALOG")
    bagsframe.scrollbackground:SetFrameLevel(100)
    bagsframe.scrollbackground:SetSize(18, 330)
    bagsframe.scrollbackground:SetPoint("TOPRIGHT", iframe.bagsframe, 16, 2)
    _util.SetBackdrop(iframe.bagsframe.scrollbackground, _data.ROOT_PATH .. "textures\\inventory_scroll.tga")

    local scrollbar = _G[scrollBarName .."ScrollBar"];
    local scrollupbutton = _G[scrollBarName.."ScrollBarScrollUpButton"];
    local scrolldownbutton = _G[scrollBarName.."ScrollBarScrollDownButton"];
    scrollbar:SetPoint("TOPLEFT", bagsframe, "TOPRIGHT", 0, -16)
    bagsframe.scroll = CreateFrame("Frame")
    bagsframe:SetScrollChild(iframe.bagsframe.scroll)
    bagsframe.scroll:SetSize(bagsframe:GetWidth(), bagsframe:GetHeight())
    iframe.bagslots = {}
    iframe.itemslots = {}
    iframe.itemSlotsCount = 0

    iframe.updateBagsBtn = CreateFrame("Button", nil, iframe.topbar)
    local updateBtn = iframe.updateBagsBtn
    updateBtn:SetFrameStrata("DIALOG")
    updateBtn:SetFrameLevel(1000)
    updateBtn:SetPoint("TOPLEFT", iframe.topbar,  0, 0)
    updateBtn:SetSize(32,32)
    updateBtn:SetNormalTexture(_data.textures.updateBotsUp)
    updateBtn:SetPushedTexture(_data.textures.updateBotsDown)
    updateBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    updateBtn:SetScript("OnClick", function(self, button, down)
        _broker:StartQuery(QUERY_TYPE.INVENTORY, PlayerbotsPanel.selectedBot)
    end)
    updateBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(updateBtn, _data.strings.tooltips.inventoryTabUpdate)

    iframe.hideEmptyBtn = CreateFrame("Button", nil, iframe.topbar)
    local hideEmptyBtn = iframe.hideEmptyBtn
    hideEmptyBtn:SetFrameStrata("DIALOG")
    hideEmptyBtn:SetFrameLevel(1000)
    hideEmptyBtn:SetPoint("TOPLEFT", iframe.topbar,  32, 0)
    hideEmptyBtn:SetSize(32,32)
    hideEmptyBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnUp)
    hideEmptyBtn:SetScript("OnClick", function(self, button, down)
        _cfg.inventory.hideEmptySlots = not _cfg.inventory.hideEmptySlots
        if _activeBagTab then
            _activeBagTab:Refresh(PlayerbotsPanel.selectedBot)
        end
    end)
    hideEmptyBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(hideEmptyBtn, _data.strings.tooltips.inventoryTabHideEmptySlots)

    iframe.helpIcon = CreateFrame("Frame", nil, iframe)
    local helpIcon = iframe.helpIcon
    helpIcon:SetFrameLevel(1000)
    helpIcon:Show()
    helpIcon:SetPoint("TOPLEFT", 64, -8)
    helpIcon:SetSize(16, 16)
    helpIcon:EnableMouse(true)

    helpIcon.tex = helpIcon:CreateTexture(nil, "OVERLAY")
    helpIcon.tex:SetAllPoints(helpIcon)
    helpIcon.tex:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon.blp")
    _tooltips.AddInfoTooltip(helpIcon, _data.strings.tooltips.inventoryTabHelp)

    if bagtype == 1 then -- bags

        local numSlots = 4
        for i=0, numSlots do
            local bagSlot = CreateBagSlot(iframe, 24, i, nil)
            bagSlot:SetPoint("TOPRIGHT", - (26 * (i)), -4)
            bagSlot:SetFrameLevel(150)
            iframe.bagslots[i] = bagSlot
            bagSlot.bgTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag.blp")
            if i == 0 then -- backpack
                bagSlot.itemTex:SetTexture("Interface\\ICONS\\INV_Misc_Bag_08.blp")
                bagSlot.itemTex:Show()
            end
        end

    elseif bagtype == 2 then -- bank

        local numSlots = 8
        local offset = 4 + (26 * numSlots) * -1
        for i=1, numSlots do
            local bagSlot = CreateBagSlot(iframe, 24, i, nil)
            bagSlot:SetPoint("TOPRIGHT", offset - (4 + (26 * (i) * -1)), -4)
            bagSlot:SetFrameLevel(150)

            local actualId = 0 -- store the bags using actual ContainerID 
            if i == 1 then 
                actualId = -1
            else
                actualId = i + 3
            end

            iframe.bagslots[actualId] = bagSlot
            bagSlot.id = actualId

            bagSlot.bgTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag.blp")
            if i == 1 then -- bank space
                bagSlot.itemTex:SetTexture("Interface\\ICONS\\INV_Misc_Coin_02.blp")
                bagSlot.itemTex:Show()
            end
        end

    elseif bagtype == 3 then -- keyring
        -- no bagslots
    end

    iframe.Refresh = function (self, bot)
        if not bot then return end
        local hideEmptyBtn = self.hideEmptyBtn
        if _cfg.inventory.hideEmptySlots then
            hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnDown)
        else
            hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnUp)
        end
        
        local bagtype = self.bagtype
        local bagslots = self.bagslots
        local itemslots = self.itemslots

        for i=0, self.itemSlotsCount do -- release used slots
            local slot = itemslots[i]
            _pool_itemSlots:Release(slot)
            itemslots[i] = nil
        end
        wipe(itemslots)
        self.itemSlotsCount = 0
        local slotcount = 0
        local function populateSlots(bagNum)
            local bag = bot.bags[bagNum]
            local bagSlot = bagslots[bagNum]
            if bagSlot then
                bagSlot.itemStart = slotcount
            end
            local step = 35
            local hideEmtpy = _cfg.inventory.hideEmptySlots
            for i=1, bag.size do
                local item = bag.contents[i]
                local shouldHide = hideEmtpy and ( not item or not item.link)
                if not shouldHide then
                    local slot = _pool_itemSlots:Get()
                    itemslots[slotcount] = slot
                    self.itemSlotsCount = self.itemSlotsCount + 1
                    local x = slotcount % _slotsPerRow
                    local y = _floor(slotcount / _slotsPerRow)
                    slot:Show()
                    slot:SetParent(self.bagsframe.scroll)
                    slot:SetPoint("TOPLEFT", x * step, y * step * -1)
                    slot:SetItem(item)
                    slotcount = slotcount + 1
                end
            end
            if bagSlot then
                bagSlot.itemEnd = slotcount
            end
        end

        -- update bags
        if bagtype == 1 then -- backpack
            for i = 1, 4 do
                local bag = bot.bags[i]
                local bagslot = bagslots[i]
                bagslot:SetItem(bag)
            end
            for i=0, 4 do -- populate slots
                populateSlots(i)
            end
        elseif bagtype == 2 then -- bank
            for i = 5, 11 do
                local bag = bot.bags[i]
                local bagslot = bagslots[i]
                bagslot:SetItem(bag)
            end
            populateSlots(-1)
            for i=5, 11 do -- populate slots
                populateSlots(i)
            end

        elseif bagtype == 3 then -- keyring
            populateSlots(-2)
        end

        --for y=0, 16 do
        --    for x = 0, 10 do
        --        local slot = _pool_itemSlots:Get()
        --        slot:SetParent(frame)
        --        slot:SetPoint("TOPLEFT", x * step, y * step * -1)
        --        i = i + 1
        --    end
        --end
    end

    iframe:Hide()
    return iframe
end