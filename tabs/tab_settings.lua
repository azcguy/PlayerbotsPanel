PlayerbotsPanel.tabs.settings = {}
local _self = PlayerbotsPanel.tabs.settings

_self.id = "Settings"
_self.useFullFrame = false
_self.useBackground = true
_self.rightSide = true
_self.iconTex = PlayerbotsPanel.rootPath .. "textures\\icon-tab-settings.tga"

local _tab = nil
local _frame = nil
local _tooltips = PlayerbotsPanel.tooltips
local _inputRegisterByName
local _inputUnRegisterByName

function _self:Init(tab)
    _tab = tab
    _frame = tab.innerframe

    local caret = 0
    local vcaret = 0
    local rowHeight = 22
    -- ROW REGISTER
    local btnRegisterSelected = CreateFrame("Button", nil, _frame, "UIPanelButtonTemplate")
    btnRegisterSelected:SetPoint("TOPLEFT", caret, 0)
    btnRegisterSelected:SetSize(120,rowHeight)
    caret = caret + 120
    btnRegisterSelected:SetText("Reg Selected")
    btnRegisterSelected:SetScript("OnClick", function(self, button, down)
        PlayerbotsPanel:RegisterByName(UnitName("target"))
    end)
    btnRegisterSelected:RegisterForClicks("AnyUp")

    local btnRegisterByName = CreateFrame("Button", nil, _frame, "UIPanelButtonTemplate")
    btnRegisterByName:SetPoint("TOPLEFT", caret, 0)
    btnRegisterByName:SetSize(120,rowHeight)
    caret = caret + 120

    btnRegisterByName:SetText("Reg By Name")
    btnRegisterByName:SetScript("OnClick", function(self, button, down)
        --local guid = UnitGUID()
        --print(guid)
        --if guid == nil then return end
        --local class, classFilename, race, raceFilename, sex, name, realm = GetPlayerInfoByGUID(guid)    
        --print(class, classFilename, race, raceFilename, sex, name, realm)
        _inputRegisterByName:ClearFocus()
        PlayerbotsPanel:RegisterByName(_inputRegisterByName:GetText())
    end)
    btnRegisterByName:RegisterForClicks("AnyUp")

    _inputRegisterByName = CreateFrame("EditBox", nil, _frame, "InputBoxTemplate")
    _inputRegisterByName:SetPoint("TOPLEFT", caret, 0)
    _inputRegisterByName:SetSize(150,rowHeight)
    _inputRegisterByName:SetText("")
    _inputRegisterByName:SetAutoFocus(false)

    -- ROW UNREGISTER
    caret = 0
    vcaret = -25
    local btnUnRegisterSelected = CreateFrame("Button", nil, _frame, "UIPanelButtonTemplate")
    btnUnRegisterSelected:SetPoint("TOPLEFT", caret, vcaret)
    btnUnRegisterSelected:SetSize(120,rowHeight)
    caret = caret + 120
    btnUnRegisterSelected:SetText("Unreg Selected")
    btnUnRegisterSelected:SetScript("OnClick", function(self, button, down)
        PlayerbotsPanel:UnregisterByName(UnitName("target"))
    end)
    btnUnRegisterSelected:RegisterForClicks("AnyUp")

    local btnUnRegisterByName = CreateFrame("Button", nil, _frame, "UIPanelButtonTemplate")
    btnUnRegisterByName:SetPoint("TOPLEFT", caret, vcaret)
    btnUnRegisterByName:SetSize(120,rowHeight)
    caret = caret + 120

    btnUnRegisterByName:SetText("Unreg By Name")
    btnUnRegisterByName:SetScript("OnClick", function(self, button, down)
        _inputUnRegisterByName:ClearFocus()
        PlayerbotsPanel:UnregisterByName(_inputUnRegisterByName:GetText())
    end)
    btnUnRegisterByName:RegisterForClicks("AnyUp")

    _inputUnRegisterByName = CreateFrame("EditBox", nil, _frame, "InputBoxTemplate")
    _inputUnRegisterByName:SetPoint("TOPLEFT", caret, vcaret)
    _inputUnRegisterByName:SetSize(150,rowHeight)
    _inputUnRegisterByName:SetText("")
    _inputUnRegisterByName:SetAutoFocus(false)
end

function _self:OnActivate(tab)
end

function _self:OnDeactivate(tab)
end