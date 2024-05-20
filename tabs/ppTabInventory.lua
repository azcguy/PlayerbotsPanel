PlayerbotsPanelTabInventory = {}
local _self = PlayerbotsPanelTabInventory
PlayerbotsPanelTabInventory.id = "Items"
PlayerbotsPanelTabInventory.useFullFrame = false
PlayerbotsPanelTabInventory.useBackground = true
PlayerbotsPanelTabInventory.rightSide = false
PlayerbotsPanelTabInventory.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-inventory.tga"
PlayerbotsPanelTabInventory.customSound = "BAGMENUBUTTONPRESS"


local _data = PlayerbotsPanelData
local _util = PlayerbotsPanelUtil
local _eval = _util.CompareAndReturn
local _cfg = PlayerbotsPanelConfig
local _tooltips = PlayerbotsPanelTooltips
local _tab = nil
local _frame = nil
local _slots = {}

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

    _bagFrames[1] = _self.CreateBagsTab()
    _bagFrames[2] = _self.CreateBagsTab()

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Bag_08.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
        end, nil)

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Coin_02.blp", 
        function ()
            PlayerbotsPanelTabInventory.ActivateBagsFrame(2)
        end, nil)

    PlayerbotsPanelTabInventory.ActivateBagsFrame(1)
    local step = 34
    local i = 1
    local frame = _bagFrames[1].bagsframe:GetScrollChild()
    for y=0, 16 do
        for x = 0, 10 do
            local slot = PlayerbotsPanel.CreateSlot(frame, 34, i, nil, nil)
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

    local bagsframe = CreateFrame("ScrollFrame", "ppInventoryBagsScroll", iframe, "UIPanelScrollFrameTemplate")--CreateFrame("Frame", nil, iframe)
    iframe.bagsframe = bagsframe
    iframe.bagsframe.scrollbackground = CreateFrame("Frame", nil, bagsframe)
    iframe.bagsframe.scrollbackground:SetFrameStrata("DIALOG")
    iframe.bagsframe.scrollbackground:SetFrameLevel(100)
    iframe.bagsframe.scrollbackground:SetSize(22, 330)
    iframe.bagsframe.scrollbackground:SetPoint("TOPRIGHT", iframe.bagsframe, 24, 2)
    _util.SetBackdrop(iframe.bagsframe.scrollbackground, _data.ROOT_PATH .. "textures\\inventory_scroll.tga")
    bagsframe:SetFrameLevel(144)
    bagsframe:SetPoint("TOPLEFT", 0, -topBarHeight)
    bagsframe:SetSize(width - 18, height - topBarHeight - 5)

    bagsframe.scroll = CreateFrame("Frame")
    bagsframe:SetScrollChild(iframe.bagsframe.scroll)
    bagsframe.scroll:SetSize(bagsframe:GetWidth(), bagsframe:GetHeight())
    iframe.bagslots = {}
    local numSlots = _eval(isBank, 7, 5)
    for i=1, numSlots do
        local bagSlot = {}
    end
    return iframe
end

function PlayerbotsPanelTabInventory.SetupInventorySlot(id, x, y)
    --local slotSize = 38
    --local slot =  Create
    --slot.id = id
    --slot:SetPoint("TOPLEFT", x, y)
--
end