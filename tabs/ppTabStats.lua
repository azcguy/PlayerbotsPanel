local _self = {}
PlayerbotsPanel.Objects.PlayerbotsPanelTabStats = _self
local _data = PlayerbotsPanel.Data
local _util = PlayerbotsPanel.Util
local _broker = PlayerbotsBroker
local _tooltips = PlayerbotsPanel.Tooltips

_self.id = "Stats"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = false
_self.iconTex = PlayerbotsPanel.rootPath .. "textures\\icon-tab-stats.tga"
_self.customSound = "GAMEDIALOGOPEN"

local _tab = nil
local _frame = nil
local _defaultNameColor = _data.colors.gold

local _rowColor = _data.CreateColorF(1,1,1,0.06)

function _self:Init(tab)
    _tab = tab
    _frame = tab.innerframe
    --(self, icon, stringTooltip, name, onActivate, onDeactivate)
    local subtab = tab:CreateSubTab("Interface\\ICONS\\Spell_Nature_Strength.blp", "Stats", "Stats", 
        function (subtab)
            print("SUBTAB ACTIVATE")
            _broker:StartQuery(PlayerbotsBrokerQueryType.STATS, PlayerbotsPanel.selectedBot)
            _broker.EVENTS.STATS_CHANGED:Add(subtab.Update, subtab)
            PlayerbotsPanel.events.onBotSelectionChanged:Add(subtab.Update, subtab)
        end, 
        function (subtab)
            _broker.EVENTS.STATS_CHANGED:Remove(subtab.Update)
            PlayerbotsPanel.events.onBotSelectionChanged:Remove(subtab.Update)
        end)

    self:SetupSubtab_Stats(subtab)

    tab:CreateSubTab("Interface\\ICONS\\Ability_Repair.blp",  "Skills", "Skills", 
        function (subtab)
        end, nil)

    tab:CreateSubTab("Interface\\ICONS\\INV_Misc_Coin_16.blp", "Currencies", "Currencies", 
        function (subtab)
        end, nil)

    tab:CreateSubTab("Interface\\ICONS\\Achievement_Reputation_01.blp", "Reputation", "Reputation", 
        function (subtab)
        end, nil)

end


function _self:OnActivate(tab)
end

function _self:OnDeactivate(tab)
end

--- Split the frame into multiple vertical colums, populate it with stat rendering row objects
---@param subtab table
function _self:SetupSubtab_Stats(subtab)
    local bot = PlayerbotsPanel.selectedBot
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

    local column1 = subtab.columns[1]
    _self.CreateSeparator(column1, "Resistances")
    _self.CreateStatRow(column1, _data.stats.RESIST_ARCANE)
    _self.CreateStatRow(column1, _data.stats.RESIST_FIRE)
    _self.CreateStatRow(column1, _data.stats.RESIST_NATURE)
    _self.CreateStatRow(column1, _data.stats.RESIST_FROST)
    _self.CreateStatRow(column1, _data.stats.RESIST_SHADOW)

    _self.CreateSeparator(column1, "Base Stats")
    _self.CreateStatRow(column1, _data.stats.STRENGTH)
    _self.CreateStatRow(column1, _data.stats.AGILITY)
    _self.CreateStatRow(column1, _data.stats.STAMINA)
    _self.CreateStatRow(column1, _data.stats.INTELLECT)
    _self.CreateStatRow(column1, _data.stats.SPIRIT)
    _self.CreateStatRow(column1, _data.stats.ARMOR)

    _self.CreateSeparator(column1, "Melee")
    _self.CreateStatRow(column1, _data.stats.DAMAGE_MELEE)


    subtab.Update = function (self)
        print("UPDATE")
        local bot = PlayerbotsPanel.selectedBot
        for c=1, getn(subtab.columns) do
            local rows = subtab.columns[c].rows
            if rows then
                for r=1, getn(rows) do
                    local row = rows[r]
                    if row.onUpdate then
                        row:onUpdate(bot)
                    end
                end
            end
        end
    end

    subtab:Update()
end

function _self.CreateStatRow(parent, statData)
    local vertIdx = parent.vertIdx
    if not vertIdx then vertIdx = 1 end
    if not parent.rows then parent.rows = {} end

    local frame = CreateFrame("Frame", nil, parent)
    local drawRowColor = vertIdx % 2 > 0
    local height = 16
    local padding = 10
    local width = parent:GetWidth() - (padding * 2)
    local posX  = padding
    local posY  = (vertIdx - 1) * height * -1 - padding 

    frame.statData = statData

    frame:SetFrameLevel(parent:GetFrameLevel() + 1)
    frame:SetPoint("TOPLEFT", posX, posY)
    frame:SetHeight(height)
    frame:SetWidth(width)
    frame:EnableMouse(true)

    frame:SetScript("OnEnter", function(self, motion)
        local tooltip = _tooltips.tooltipStat
        tooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        self.statData:onTooltip(self.bot, self.botstats, tooltip)
        tooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self, motion)
        _tooltips.tooltipStat:Hide()
    end)

    if drawRowColor then
        local bgTex = frame:CreateTexture(nil, "ARTWORK", nil, -7)
        bgTex:SetAllPoints(frame)
        bgTex:SetTexture(_data.textures.white)
        _util.SetVertexColor(bgTex, _rowColor)
    end
        
    local txtName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.txtName = txtName
    txtName:SetAllPoints(frame)
    txtName:SetJustifyH("LEFT")
    txtName:SetText(statData.name)

    if statData.nameColor then
        _util.SetTextColor(txtName, statData.nameColor)
    end

    local txtValue = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.txtValue = txtValue
    txtValue:SetAllPoints(frame)
    txtValue:SetJustifyH("RIGHT")
    txtValue:SetText("Value")

    frame.onUpdate = function (self, bot)
        self.bot = bot
        self.botstats = bot.stats
        local statData = self.statData
        if not statData.nameColor then
            _util.SetTextColor(txtName, _defaultNameColor)
        end
        self.statData.onUpdateValue(self, bot.stats)
    end

    parent.rows[vertIdx] = frame
    parent.vertIdx = vertIdx + 1
    return frame
end

function _self.CreateSeparator(parent, text)
    local vertIdx = parent.vertIdx
    if not vertIdx then vertIdx = 1 end
    if not parent.rows then parent.rows = {} end

    local frame = CreateFrame("Frame", nil, parent)
    local height = 16
    local padding = 10
    local width = parent:GetWidth() - (padding * 2)
    local posX  = padding
    local posY  = (vertIdx - 1) * height * -1 - padding 
    frame:SetFrameLevel(parent:GetFrameLevel() + 1)
    frame:SetPoint("TOPLEFT", posX, posY)
    frame:SetHeight(height)
    frame:SetWidth(width)

    local txtName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.txtName = txtName
    txtName:SetAllPoints(frame)
    txtName:SetJustifyH("CENTER")
    txtName:SetText(text)
    _util.SetTextColor(txtName, _data.colors.white)

    parent.rows[vertIdx] = frame
    parent.vertIdx = vertIdx + 1
    return frame
end

