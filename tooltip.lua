PlayerbotsPanel.Tooltips = {}

local _self = PlayerbotsPanel.Tooltips
-- tooltip used for items
_self.tooltip = nil
_self.tooltipCompare1 = nil
_self.tooltipCompare2 = nil
-- tooltip used to display help/descriptions of what buttons do
_self.tooltipInfo = nil
-- for drawing stats
_self.tooltipStat = nil

function _self:Init(parentFrame)
    local scale = UIParent:GetScale()
    _self.tooltip = CreateFrame("GameTooltip", "PlayerbotsPanelTooltip", UIParent, "GameTooltipTemplate")
    _self.tooltip:SetScale(scale)

    _self.tooltipCompare1 = CreateFrame("GameTooltip", "PlayerbotsPanelTooltipCompare1", UIParent, "GameTooltipTemplate")
    _self.tooltipCompare1:SetScale(scale)
  
    _self.tooltipCompare2 = CreateFrame("GameTooltip", "PlayerbotsPanelTooltipCompare2", UIParent, "GameTooltipTemplate")
    _self.tooltipCompare2:SetScale(scale)

    _self.tooltipInfo = CreateFrame("GameTooltip", "PlayerbotsPanelTooltipInfo", UIParent, "GameTooltipTemplate")
    _self.tooltipInfo:SetScale(scale)

    _self.tooltipStat = CreateFrame("GameTooltip", "PlayerbotsPanelTooltipStat", UIParent, "GameTooltipTemplate")
    _self.tooltipStat:SetScale(scale)
end

-- Assumes whatever is passed as target is Frame/Button etc and will override OnEnter/OnLeave
function _self.AddInfoTooltip(target, strTooltip)
  if target == nil or strTooltip == nil then
    error("AddInfoTooltip - nil values passed")
    return
  end

  target:SetScript("OnEnter", function(self, motion)
    _self.tooltipInfo:SetOwner(target, "ANCHOR_BOTTOMRIGHT")
    _self.tooltipInfo:SetText(strTooltip)
  end)
  target:SetScript("OnLeave", function(self, motion)
    _self.tooltipInfo:Hide()
  end)
end