PlayerbotsPanelTabStats = {}
local _self = PlayerbotsPanelTabStats

_self.id = "Stats"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = false
_self.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-stats.tga"
_self.customSound = "GAMEDIALOGOPEN"

local _tab = nil
local _frame = nil

function _self:Init(tab)
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

function _self:OnActivate(tab)
end

function _self:OnDeactivate(tab)
end



