PlayerbotsPanelTabStats = {}
PlayerbotsPanelTabStats.id = "Stats"
PlayerbotsPanelTabStats.useFullFrame = false
PlayerbotsPanelTabStats.useBackground = true
PlayerbotsPanelTabStats.rightSide = false
PlayerbotsPanelTabStats.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-stats.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabStats:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabStats:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabStats:OnDeactivate(tab)
    _frame:Hide()
end