PlayerbotsPanelTabQuests = {}
PlayerbotsPanelTabQuests.id = "Quests"
PlayerbotsPanelTabQuests.useFullFrame = false
PlayerbotsPanelTabQuests.useBackground = true
PlayerbotsPanelTabQuests.rightSide = false
PlayerbotsPanelTabQuests.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-quest.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabQuests:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabQuests:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabQuests:OnDeactivate(tab)
    _frame:Hide()
end