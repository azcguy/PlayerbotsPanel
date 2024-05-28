local _self = {}
PlayerbotsPanel.Objects.PlayerbotsPanelTabSpells = _self

_self.id = "Spells"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = false
_self.iconTex = PlayerbotsPanel.rootPath .. "textures\\icon-tab-spells.tga"

local _tab = nil
local _frame = nil

function _self:Init(tab)
    _tab = tab
    _frame = tab.innerframe
end

function _self:OnActivate(tab)
end

function _self:OnDeactivate(tab)
end