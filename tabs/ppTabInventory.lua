PlayerbotsPanelTabInventory = {}
local _self = PlayerbotsPanelTabInventory
PlayerbotsPanelTabInventory.id = "Items"
PlayerbotsPanelTabInventory.useFullFrame = false
PlayerbotsPanelTabInventory.useBackground = true
PlayerbotsPanelTabInventory.rightSide = false
PlayerbotsPanelTabInventory.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-inventory.tga"
PlayerbotsPanelTabInventory.customSound = "BAGMENUBUTTONPRESS"

local _broker = PlayerbotsBroker
local _updateHandler = PlayerbotsPanelUpdateHandler
local _data = PlayerbotsPanelData
local _util = PlayerbotsPanelUtil
local _eval = _util.CompareAndReturn
local _floor = math.floor
local _cfg = PlayerbotsPanelConfig
local _tooltips = PlayerbotsPanelTooltips

local QUERY_TYPE = PlayerbotsBrokerQueryType
local COMMAND = PlayerbotsBrokerCommandType

local _tab = nil
local _frame = nil
local _slots = {}
local _scrollBarId = 1
local _slotsPerRow = 11
local _activeBagTab = nil
local _bagFrames = {} -- 1 bags, 2 bank
local _frameUseItemOnItem = {}
local _item_toBeUsedOnAnotherItem = nil

local function  SetItemToUseOnAnotherItem(item)
    if item and item.link then
        -- print(IsUsableItem(item.link))
        -- cant implement usable check because it applies local player restrictions, so it should actually be UsableByPlayer()
        -- there is another more convoluted way i will implement later
        _frameUseItemOnItem:Show()
        _frameUseItemOnItem.slot:SetItem(item)
        _frame.useBtn:LockHighlight()
    else
        _frameUseItemOnItem:Hide()
        _frameUseItemOnItem.slot:SetItem(nil)
        _frame.useBtn:UnlockHighlight()
    end
    _item_toBeUsedOnAnotherItem = item
end

local function HandleSlotClicks(slot, button, down)
    local item = slot.item
    if _item_toBeUsedOnAnotherItem and _item_toBeUsedOnAnotherItem.link and not down then
        if button == "LeftButton" and not _updateHandler:GetGlobalMouseButtonConsumed(1) then
            _broker:GenerateCommand(PlayerbotsPanel.selectedBot, COMMAND.ITEM, COMMAND.ITEM_USE_ON, _item_toBeUsedOnAnotherItem.link, item.link)
            SetItemToUseOnAnotherItem(nil)
            _updateHandler:SetGlobalMouseButtonConsumed(1)
        end
    else
        if not down and item and item.link then
            if button == "RightButton" then
                if not _updateHandler:GetGlobalMouseButtonConsumed(2) then
                    _broker:GenerateCommand(PlayerbotsPanel.selectedBot, COMMAND.ITEM, COMMAND.ITEM_USE, item.link)
                    PlaySound("SPELLBOOKCLOSE")
                end
            elseif button == "LeftButton" then
                if IsShiftKeyDown() then
                    print(item.link)
                else
                    SetItemToUseOnAnotherItem(item)
                end
            end
        end
    end
end

local function HandleGlobalMouseClick(button, down)
    if button == "RightButton" and not down then
        if _item_toBeUsedOnAnotherItem then
            SetItemToUseOnAnotherItem(nil)
        end
    end
end

local _pool_itemSlots = _util.CreatePool(
    function ()
        local slot = PlayerbotsPanel.CreateSlot(nil, 35, 0, nil)
        slot.bgTex:SetVertexColor(0.4,0.4,0.4)

        slot.onClick:Add(function (self, button, down)
            HandleSlotClicks(self, button, down)
        end)

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
    _updateHandler.onMouseButton:Add(HandleGlobalMouseClick)
    SetItemToUseOnAnotherItem(nil)
end

function PlayerbotsPanelTabInventory:OnDeactivate(tab)
    _frame:Hide()
    _broker:UnregisterGlobalCallback(PlayerbotsBrokerCallbackType.INVENTORY_CHANGED, HandleQuery_INVENTORY_CHANGED)
    _updateHandler.onMouseButton:Remove(HandleGlobalMouseClick)
    SetItemToUseOnAnotherItem(nil)
end

function PlayerbotsPanelTabInventory:Init(tab)
    _tab = tab
    _frame = tab.innerframe

    _bagFrames[1] = _self.CreateBagsTab(1) -- bags
    _bagFrames[2] = _self.CreateBagsTab(2) -- bank
    _bagFrames[3] = _self.CreateBagsTab(3) -- keyring

    _frameUseItemOnItem = CreateFrame("Frame", nil, _frame)
    print()
    _frameUseItemOnItem:SetPoint("TOPLEFT", 90, 40)
    _frameUseItemOnItem:SetFrameLevel(10)
    _frameUseItemOnItem:SetSize(45, 45)
    _util.SetBackdrop(_frameUseItemOnItem, _data.textures.useItemOnItemFrame)

    _frameUseItemOnItem.slot = PlayerbotsPanel.CreateSlot(_frameUseItemOnItem, 32, 0, nil)
    _frameUseItemOnItem.slot:SetSize(32,32)
    _frameUseItemOnItem.slot:SetPoint("CENTER", 0, 0)
    _frameUseItemOnItem.slot:SetFrameLevel(11)
    _frameUseItemOnItem:Hide()


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

    _frame.updateBagsBtn = CreateFrame("Button", nil, _frame)
    local updateBtn = _frame.updateBagsBtn
    --updateBtn:SetFrameStrata("DIALOG")
    updateBtn:SetFrameLevel(6)
    updateBtn:SetPoint("TOPLEFT", 0, 0)
    updateBtn:SetSize(32,32)
    updateBtn:SetNormalTexture(_data.textures.updateBotsUp)
    updateBtn:SetPushedTexture(_data.textures.updateBotsDown)
    updateBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    updateBtn:SetScript("OnClick", function(self, button, down)
        _broker:StartQuery(QUERY_TYPE.INVENTORY, PlayerbotsPanel.selectedBot)
        PlaySound("GAMEGENERICBUTTONPRESS")
    end)
    updateBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(updateBtn, _data.strings.tooltips.inventoryTabUpdate)

    _frame.hideEmptyBtn = CreateFrame("Button", nil, _frame)
    local hideEmptyBtn = _frame.hideEmptyBtn
    --hideEmptyBtn:SetFrameStrata("DIALOG")
    hideEmptyBtn:SetFrameLevel(6)
    hideEmptyBtn:SetPoint("TOPLEFT",  32, 0)
    hideEmptyBtn:SetSize(32,32)
    hideEmptyBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnUp)
    hideEmptyBtn:SetScript("OnClick", function(self, button, down)
        _cfg.inventory.hideEmptySlots = not _cfg.inventory.hideEmptySlots
        if _activeBagTab then
            _activeBagTab:Refresh(PlayerbotsPanel.selectedBot)
        end
        PlaySound("GAMEGENERICBUTTONPRESS")
    end)
    hideEmptyBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(hideEmptyBtn, _data.strings.tooltips.inventoryTabHideEmptySlots)

    _frame.tradeBtn = CreateFrame("Button", nil, _frame)
    local tradeBtn = _frame.tradeBtn
    --tradeBtn:SetFrameStrata("DIALOG")
    tradeBtn:SetFrameLevel(6)
    tradeBtn:SetPoint("TOPLEFT", 64, 0)
    tradeBtn:SetSize(32,32)
    tradeBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    tradeBtn:SetNormalTexture(_data.textures.tradeBtnUp)
    tradeBtn:SetPushedTexture(_data.textures.tradeBtnDown)
    tradeBtn:SetScript("OnClick", function(self, button, down)
        if PlayerbotsPanel.isTrading then
            CloseTrade()
        else
            InitiateTrade(PlayerbotsPanel.selectedBot.name) 
        end
        --PlaySound("GAMEGENERICBUTTONPRESS")
    end)
    tradeBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(tradeBtn, _data.strings.tooltips.inventoryTabTradeBtn)

    _frame.useBtn = CreateFrame("Button", nil, _frame)
    local useBtn = _frame.useBtn
    --useBtn:SetFrameStrata("DIALOG")
    useBtn:SetFrameLevel(6)
    useBtn:SetPoint("TOPLEFT",   96, 0)
    useBtn:SetSize(32,32)
    useBtn:SetHighlightTexture(_data.textures.updateBotsHi)
    useBtn:SetNormalTexture(_data.textures.useBtnUp)
    useBtn:SetPushedTexture(_data.textures.useBtnDown)
    --useBtn:SetScript("OnClick", function(self, button, down) end)
    useBtn:EnableMouse(true)
    _tooltips.AddInfoTooltip(useBtn, _data.strings.tooltips.inventoryTabUseBtn)

    _frame.helpIcon = CreateFrame("Frame", nil, _frame)
    local helpIcon = _frame.helpIcon
    helpIcon:SetFrameLevel(6)
    helpIcon:Show()
    helpIcon:SetPoint("TOPLEFT", 128, -8)
    helpIcon:SetSize(16, 16)
    helpIcon:EnableMouse(true)

    helpIcon.tex = helpIcon:CreateTexture(nil, "OVERLAY")
    helpIcon.tex:SetAllPoints(helpIcon)
    helpIcon.tex:SetTexture("Interface\\GossipFrame\\IncompleteQuestIcon.blp")
    _tooltips.AddInfoTooltip(helpIcon, _data.strings.tooltips.inventoryTabHelp)

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
    local iframe = CreateFrame("Frame", "pp_bagframe_" .. tostring(bagtype), _frame)
    iframe.bagtype = bagtype
    iframe:SetPoint("TOPLEFT", 0, 0)
    iframe:SetSize(width, height)
    --iframe:SetFrameStrata("DIALOG")
    iframe:SetFrameLevel(3)
    -- create top bar frame
    iframe.topbar = CreateFrame("Frame", "pp_invtab_topbar", iframe)
    iframe.topbar:SetFrameLevel(5)
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
    bagsframe:SetFrameLevel(4)
    bagsframe:SetPoint("TOPLEFT", 0, -topBarHeight)
    bagsframe:SetSize(width - 14, height - topBarHeight - 5)
    bagsframe.scrollbackground = CreateFrame("Frame", nil, bagsframe)
    --bagsframe.scrollbackground:SetFrameStrata("DIALOG")
    bagsframe.scrollbackground:SetFrameLevel(3)
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

    

    local function CreateTotalFreeSlotsText( x)
        iframe.totalFreeSlotsText = iframe.topbar:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
        local text = iframe.totalFreeSlotsText
        text:SetPoint("TOPRIGHT", x, -2)
        text:SetSize(32, 32)
        --text:SetJustifyH("RIGHT")
        --text:SetJustifyV("BOTTOM")
    end

    if bagtype == 1 then -- bags

        local numSlots = 4
        for i=0, numSlots do
            local bagSlot = CreateBagSlot(iframe, 24, i, nil)
            bagSlot:SetPoint("TOPRIGHT", - (26 * (i)), -4)
            bagSlot:SetFrameLevel(6)
            bagSlot.showBagFreeSlots = true
            iframe.bagslots[i] = bagSlot
            bagSlot.bgTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag.blp")
            if i == 0 then -- backpack
                bagSlot.itemTex:SetTexture("Interface\\ICONS\\INV_Misc_Bag_08.blp")
                bagSlot.itemTex:Show()
            end
        end

        CreateTotalFreeSlotsText(- (26 * (5)))
        
    elseif bagtype == 2 then -- bank

        local numSlots = 8
        local offset = 4 + (26 * numSlots) * -1
        for i=1, numSlots do
            local bagSlot = CreateBagSlot(iframe, 24, i, nil)
            bagSlot:SetPoint("TOPRIGHT", offset - (4 + (26 * (i) * -1)), -4)
            bagSlot:SetFrameLevel(6)
            bagSlot.showBagFreeSlots = true

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
        CreateTotalFreeSlotsText(offset)
    elseif bagtype == 3 then -- keyring
        -- no bagslots
        CreateTotalFreeSlotsText(0)
    end

    iframe.Refresh = function (self, bot)
        if not bot then return end
        local hideEmptyBtn = _frame.hideEmptyBtn
        if _cfg.inventory.hideEmptySlots then
            hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnDown)
        else
            hideEmptyBtn:SetNormalTexture(_data.textures.hideEmptyBtnUp)
        end
        
        local bagtype = self.bagtype
        local bagslots = self.bagslots
        local itemslots = self.itemslots

        for i=0, self.itemSlotsCount-1 do -- release used slots
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
            local stepPixels = 35
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
                    slot:SetPoint("TOPLEFT", x * stepPixels, y * stepPixels * -1)
                    slot:SetItem(item)
                    slotcount = slotcount + 1
                end
            end
            if bagSlot then
                bagSlot.itemEnd = slotcount - 1
            end
        end

        local totalFreeSlots = 0
        -- update bags
        if bagtype == 1 then -- backpack
            local bag = bot.bags[0]
            local bagslot = bagslots[0]
            bagslot:SetItemCountOverride(bag.freeSlots)
            totalFreeSlots = totalFreeSlots + bag.freeSlots
            for i = 1, 4 do
                bag = bot.bags[i]
                bagslot = bagslots[i]
                bagslot:SetItem(bag)
                totalFreeSlots = totalFreeSlots + bag.freeSlots
            end
            for i=0, 4 do -- populate slots
                populateSlots(i)
            end
            iframe.totalFreeSlotsText:SetText(tostring(totalFreeSlots))
        elseif bagtype == 2 then -- bank
            local bag = bot.bags[-1]
            local bagslot = bagslots[-1]
            bagslot:SetItemCountOverride(bag.freeSlots)
            totalFreeSlots = totalFreeSlots + bag.freeSlots

            for i = 5, 11 do
                bag = bot.bags[i]
                bagslot = bagslots[i]
                bagslot:SetItem(bag)
                totalFreeSlots = totalFreeSlots + bag.freeSlots
            end
            populateSlots(-1)
            for i=5, 11 do -- populate slots
                populateSlots(i)
            end
            iframe.totalFreeSlotsText:SetText(tostring(totalFreeSlots))
        elseif bagtype == 3 then -- keyring
            totalFreeSlots = totalFreeSlots + bot.bags[-2].freeSlots
            iframe.totalFreeSlotsText:SetText(tostring(totalFreeSlots))
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