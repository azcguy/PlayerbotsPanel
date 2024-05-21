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
local _cfg = PlayerbotsPanelConfig
local _tooltips = PlayerbotsPanelTooltips
local _tab = nil
local _frame = nil
local _slots = {}
local _scrollBarId = 1

local _activeBagTab = nil
local _bagFrames = {} -- 1 bags, 2 bank
function PlayerbotsPanelTabInventory:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabInventory:OnDeactivate(tab)
    _frame:Hide()
end

function PlayerbotsPanelTabInventory:Init(tab)
    _tab = tab
    _frame = tab.innerframe

    _bagFrames[1] = _self.CreateBagsTab(false)


    _bagFrames[2] = _self.CreateBagsTab(true)

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Bag_08.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
        end, nil)

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Coin_02.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(2)
        end, nil)

    PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
    local step = 35
    local i = 1
    local frame = _bagFrames[1].bagsframe:GetScrollChild()
    for y=0, 16 do
        for x = 0, 10 do
            local slot = PlayerbotsPanel.CreateSlot(frame, 35, i, nil, nil)
            slot:SetPoint("TOPLEFT", x * step, y * step * -1)
            i = i + 1
        end
    end
end

function  PlayerbotsPanelTabInventory.ActivateBagsFrame(index) -- 1 bags, 2 bank
    local frame = _bagFrames[index]
    if frame then
        if frame == _activeBagTab then return end
        if _activeBagTab then
            _activeBagTab:Hide()
        end
        _activeBagTab = frame
        _activeBagTab:Show()
    end
end

function  PlayerbotsPanelTabInventory.CreateBagsTab(isBank)
    local topBarHeight = _cfg.inventory.topbarHeight
    -- create internal frame
    local width = _frame:GetWidth()
    local height = _frame:GetHeight()
    local level = _frame:GetFrameLevel()

    local iframe = CreateFrame("Frame", nil, _frame)
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

    --print(scrollbar:GetWidth(), scrollbar:GetHeight())
    --print(scrollupbutton:GetWidth(), scrollbar:GetHeight())
    --print(scrolldownbutton:GetWidth(), scrollbar:GetHeight())
    --print(scrollbar:GetPoint())
    --print(scrollbar:GetParent())
    --print(bagsframe)
    scrollbar:SetPoint("TOPLEFT", bagsframe, "TOPRIGHT", 0, -16)
    --scrollbar:SetWidth(14)
    --scrollupbutton:SetWidth(14)
    --scrolldownbutton:SetWidth(14)
    bagsframe.scroll = CreateFrame("Frame")
    bagsframe:SetScrollChild(iframe.bagsframe.scroll)
    bagsframe.scroll:SetSize(bagsframe:GetWidth(), bagsframe:GetHeight())
    iframe.bagslots = {}

    if isBank then
        local numSlots = 7
        for i=1, numSlots do
            local bagSlot = PlayerbotsPanel.CreateSlot(iframe.topbar, 24, i, nil, nil)
            bagSlot:SetPoint("TOPLEFT", 4 + (26 * (i-1)), -4)
            bagSlot:SetFrameLevel(150)
            iframe.bagslots[i] = bagSlot
        end


    else
        local numSlots = 5
        for i=1, numSlots do
            local bagSlot = PlayerbotsPanel.CreateSlot(iframe.topbar, 24, i, nil, nil)
            bagSlot:SetPoint("TOPRIGHT", - (26 * (i-1)), -4)
            bagSlot:SetFrameLevel(150)
            iframe.bagslots[i] = bagSlot
            if i == 1 then -- backpack
                bagSlot.bgTex:SetTexture("Interface\\ICONS\\INV_Misc_Bag_08.blp")
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
            print("click")
            _broker:StartQuery(QUERY_TYPE.INVENTORY, PlayerbotsPanel:GetSelectedBot())
        end)
        iframe.updateBagsBtn:EnableMouse(true)
        _tooltips:AddInfoTooltip(PlayerbotsGearView.updateGearButton, _data.strings.tooltips.gearViewUpdateGear)
    end


    iframe:Hide()
    return iframe
end

function PlayerbotsPanelTabInventory.SetupInventorySlot(id, x, y)
    --local slotSize = 38
    --local slot =  Create
    --slot.id = id
    --slot:SetPoint("TOPLEFT", x, y)
--
end