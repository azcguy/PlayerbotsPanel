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
        print(self.itemStart, self.itemEnd)
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
    iframe.itemslotsCount = 0

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

        iframe.updateBagsBtn = CreateFrame("Button", nil, iframe.topbar)
        iframe.updateBagsBtn:SetFrameStrata("DIALOG")
        iframe.updateBagsBtn:SetFrameLevel(1000)
        iframe.updateBagsBtn:SetPoint("TOPLEFT", iframe.topbar,  0, 0)
        iframe.updateBagsBtn:SetSize(32,32)
        iframe.updateBagsBtn:SetNormalTexture(_data.textures.updateBotsUp)
        iframe.updateBagsBtn:SetPushedTexture(_data.textures.updateBotsDown)
        iframe.updateBagsBtn:SetHighlightTexture(_data.textures.updateBotsHi)
        iframe.updateBagsBtn:SetScript("OnClick", function(self, button, down)
            _broker:StartQuery(QUERY_TYPE.INVENTORY, PlayerbotsPanel.selectedBot)
        end)
        iframe.updateBagsBtn:EnableMouse(true)
        _tooltips.AddInfoTooltip(PlayerbotsGearView.updateGearButton, _data.strings.tooltips.gearViewUpdateGear)

    elseif bagtype == 2 then -- bank

        local numSlots = 8
        for i=1, numSlots do
            local bagSlot = CreateBagSlot(iframe, 24, i, nil)
            bagSlot:SetPoint("TOPLEFT", 4 + (26 * (i-1)), -4)
            bagSlot:SetFrameLevel(150)

            local actualId = 0 -- store the bags using actual ContainerID 
            if i == 1 then 
                actualId = -1
            else
                actualId = i + 4
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
        
        local bagtype = self.bagtype
        local bagslots = self.bagslots
        -- update bags
        if bagtype == 1 then -- backpack
            for i = 1, 4 do
                local bag = bot.bags[i]
                local bagslot = bagslots[i]
                bagslot:SetItem(bag)
            end

            for i=0, self.itemslotsCount do -- release used slots
                local slot = self.itemslots[i]
                _pool_itemSlots:Release(slot)
                self.itemslots[i] = nil
            end
            wipe(self.itemslots)
            self.itemslotsCount = 0
            local slotcount = 0
            for i=0, 4 do -- populate slots
                local bag = bot.bags[i]
                local bagSlot = bagslots[i]
                bagSlot.itemStart = slotcount
                local step = 35
                for i=1, bag.size do
                    local slot = _pool_itemSlots:Get()
                    self.itemslots[slotcount] = slot
                    self.itemslotsCount = self.itemslotsCount + 1
                    local x = slotcount % _slotsPerRow
                    local y = _floor(slotcount / _slotsPerRow)
                    slot:Show()
                    slot:SetParent(self.bagsframe.scroll)
                    slot:SetPoint("TOPLEFT", x * step, y * step * -1)
                    local item = bag.contents[i]
                    slot:SetItem(item)
                    slotcount = slotcount + 1
                end
                bagSlot.itemEnd = slotcount
            end
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