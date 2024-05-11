PlayerbotsPanelTabCommands = {}
PlayerbotsPanelTabCommands.id = "Commands"
PlayerbotsPanelTabCommands.useFullFrame = false
PlayerbotsPanelTabCommands.useBackground = true
PlayerbotsPanelTabCommands.rightSide = false
PlayerbotsPanelTabCommands.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-commands.tga"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabCommands:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function PlayerbotsPanelTabCommands:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabCommands:OnDeactivate(tab)
    _frame:Hide()
end