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

    tab:CreateSideButton("Interface\\ICONS\\Spell_Nature_Strength.blp", 
    function ()
    end, nil, "Stats")

    tab:CreateSideButton("Interface\\ICONS\\Ability_Repair.blp", 
        function ()
        end, nil, "Skills")

    tab:CreateSideButton("Interface\\ICONS\\INV_Misc_Coin_16.blp", 
        function ()
        end, nil, "Currencies")

    tab:CreateSideButton("Interface\\ICONS\\Achievement_Reputation_01.blp", 
        function ()
        end, nil, "Reputation")
end

function PlayerbotsPanelTabStats:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabStats:OnDeactivate(tab)
    _frame:Hide()
end