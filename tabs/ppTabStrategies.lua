PlayerbotsPanelTabStrategies = {}
PlayerbotsPanelTabStrategies.id = "Strategies"
PlayerbotsPanelTabStrategies.useFullFrame = false
PlayerbotsPanelTabStrategies.useBackground = true
PlayerbotsPanelTabStrategies.rightSide = false
PlayerbotsPanelTabStrategies.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-strategies.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabStrategies:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabStrategies:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabStrategies:OnDeactivate(tab)
    _frame:Hide()
end