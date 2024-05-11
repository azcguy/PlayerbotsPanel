PlayerbotsPanelTabTalents = {}
PlayerbotsPanelTabTalents.id = "Talents"
PlayerbotsPanelTabTalents.useFullFrame = false
PlayerbotsPanelTabTalents.useBackground = true
PlayerbotsPanelTabTalents.rightSide = false
PlayerbotsPanelTabTalents.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-talents.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabTalents:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabTalents:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabTalents:OnDeactivate(tab)
    _frame:Hide()
end