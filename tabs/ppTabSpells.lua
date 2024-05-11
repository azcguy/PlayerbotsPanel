PlayerbotsPanelTabSpells = {}
PlayerbotsPanelTabSpells.id = "Spells"
PlayerbotsPanelTabSpells.useFullFrame = false
PlayerbotsPanelTabSpells.useBackground = true
PlayerbotsPanelTabSpells.rightSide = false
PlayerbotsPanelTabSpells.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-spells.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabSpells:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabSpells:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabSpells:OnDeactivate(tab)
    _frame:Hide()
end