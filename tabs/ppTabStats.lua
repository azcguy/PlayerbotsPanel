PlayerbotsPanelTabStats = {}
PlayerbotsPanelTabStats.id = "Stats"
PlayerbotsPanelTabStats.useFullFrame = false
PlayerbotsPanelTabStats.useBackground = true
PlayerbotsPanelTabStats.rightSide = false
PlayerbotsPanelTabStats.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-stats.tga"
PlayerbotsPanelTabStats.customSound = "GAMEDIALOGOPEN"

local _tab = nil
local _frame = nil

function PlayerbotsPanelTabStats:Init(tab)
    _tab = tab
    _frame = tab.innerframe
    --(self, icon, stringTooltip, name, onActivate, onDeactivate)
    tab:CreateSubTab("Interface\\ICONS\\Spell_Nature_Strength.blp", "Stats", "Stats", 
    function ()
    end, nil)

    tab:CreateSubTab("Interface\\ICONS\\Ability_Repair.blp",  "Skills", "Skills", 
        function ()
        end, nil)

    tab:CreateSubTab("Interface\\ICONS\\INV_Misc_Coin_16.blp", "Currencies", "Currencies", 
        function ()
        end, nil)

    tab:CreateSubTab("Interface\\ICONS\\Achievement_Reputation_01.blp", "Reputation", "Reputation", 
        function ()
        end, nil)
end

function PlayerbotsPanelTabStats:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabStats:OnDeactivate(tab)
    _frame:Hide()
end