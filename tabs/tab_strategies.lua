local _self = {}
PlayerbotsPanel.tabs.strategies = _self

_self = {}
_self.id = "Strategies"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = false
_self.iconTex = PlayerbotsPanel.rootPath .. "textures\\icon-tab-strategies.tga"

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