PlayerbotsPanelTooltips = {}

local _tooltips = PlayerbotsPanelTooltips
-- tooltip used for items
_tooltips.tooltip = nil
-- tooltip used to display help/descriptions of what buttons do
_tooltips.tooltipInfo = nil

function PlayerbotsPanelTooltips:Init(parentFrame)
    _tooltips.tooltip = CreateFrame("GameTooltip", "PlayerbotsPanelTooltip", UIParent, "GameTooltipTemplate")
    _tooltips.tooltip:SetScale(UIParent:GetScale())
  
    _tooltips.tooltipInfo = CreateFrame("GameTooltip", "PlayerbotsPanelTooltipInfo", UIParent, "GameTooltipTemplate")
    _tooltips.tooltipInfo:SetScale(UIParent:GetScale())
end

-- Assumes whatever is passed as target is Frame/Button etc and will override OnEnter/OnLeave
function PlayerbotsPanelTooltips:AddInfoTooltip(target, strTooltip)
  if target == nil or strTooltip == nil then
    error("AddInfoTooltip - nil values passed")
    return
  end

  target:SetScript("OnEnter", function(self, motion)
    _tooltips.tooltipInfo:SetOwner(target, "ANCHOR_BOTTOMRIGHT")
    _tooltips.tooltipInfo:SetText(strTooltip)
  end)
  target:SetScript("OnLeave", function(self, motion)
    _tooltips.tooltipInfo:Hide()
  end)
end