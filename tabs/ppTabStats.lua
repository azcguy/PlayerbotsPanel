local _self = {}
PlayerbotsPanel.Objects.PlayerbotsPanelTabStats = _self
local _data = PlayerbotsPanel.Data

_self.id = "Stats"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = false
_self.iconTex = PlayerbotsPanel.rootPath .. "textures\\icon-tab-stats.tga"
_self.customSound = "GAMEDIALOGOPEN"

local _tab = nil
local _frame = nil

function _self:Init(tab)
    _tab = tab
    _frame = tab.innerframe
    --(self, icon, stringTooltip, name, onActivate, onDeactivate)
    local subtab = tab:CreateSubTab("Interface\\ICONS\\Spell_Nature_Strength.blp", "Stats", "Stats", 
        function ()
        end, nil)
    self:SetupStatsSubtab(subtab)

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

--- Split the frame into multiple vertical colums, populate it with stat rendering row objects
---@param subtab table
function _self:SetupStatsSubtab(subtab)
    local numColumns = 2
    local width = subtab:GetWidth()
    local height = subtab:GetHeight()

    local columnWidth = width / numColumns
    local columnHeight = height

    subtab.columns = {}

    for i=1, numColumns do
        local column = CreateFrame("Frame", "pp_stats_column_" .. i, subtab)
        tinsert(subtab.columns, column)
        column:SetPoint("TOPLEFT", (i-1) * columnWidth, 0)
        column:SetSize(columnWidth, columnHeight)
        local bgTex = column:CreateTexture(nil, "BACKGROUND", -7)
        column.bgTex = bgTex
        bgTex:SetTexture(_data.textures.statsTabColumn)
        bgTex:SetAllPoints(column)
    end
end

