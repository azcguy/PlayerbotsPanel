PlayerbotsPanelTabInventory = {}
PlayerbotsPanelTabInventory.id = "Items"
PlayerbotsPanelTabInventory.useFullFrame = false
PlayerbotsPanelTabInventory.useBackground = true
PlayerbotsPanelTabInventory.rightSide = false
PlayerbotsPanelTabInventory.iconTex = PlayerbotsPanelData.ROOT_PATH .. "textures\\icon-tab-inventory.tga"

local _data = PlayerbotsPanelData
local _util = PlayerbotsPanelUtil
local _tab = nil
local _frame = nil
local _slots = {}

function PlayerbotsPanelTabInventory:OnActivate(tab)
    _frame:Show()
end

function PlayerbotsPanelTabInventory:OnDeactivate(tab)
    _frame:Hide()
end

function PlayerbotsPanelTabInventory:Init(tab)
    _tab = tab
    _frame = tab.innerframe

    local step = 40
    local i = 1
    for y=0, 8 do
        for x = 0, 9 do
            PlayerbotsPanelTabInventory:SetupInventorySlot(i, x * step, y * step * -1)
        end
    end
end

function PlayerbotsPanelTabInventory:SetupInventorySlot(id, x, y)
    local slotSize = 38
    local slot =  CreateFrame("Button", nil, _frame)
    slot.id = id
    slot:SetPoint("TOPLEFT", x, y)
    slot:SetSize(slotSize, slotSize)
    slot:SetScript("OnEnter", function(self, motion)
      slot.hitex:Show()
      if slot.item ~= nil then
        --tooltip:SetOwner(slot, "ANCHOR_RIGHT")
        --tooltip:SetHyperlink("item:".. tostring(slot.item.id))
        _util:SetVertexColor(slot.hitex, slot.qColor)
      end
    end)
    slot:SetScript("OnLeave", function(self, motion)
      _util:SetVertexColor(slot.hitex, _data.colors.defaultSlotHighlight)
      slot.hitex:Hide()
      --tooltip:Hide()
    end)
    slot:SetScript("OnClick", function(self, button, down)
      if slot.item and slot.bot then
        if button == "LeftButton" then
          --SendChatMessage("ue " .. slot.item.link, "WHISPER", nil, slot.bot.name)
          PlayerbotsPanel:RefreshSelection()
        elseif button == "RightButton" then
        end
      end
    end)
  
    slot.bgTex = slot:CreateTexture(nil, "BACKGROUND")
    slot.bgTex:SetTexture(_data.textures.emptySlot)
    slot.bgTex:SetPoint("TOPLEFT", 0, 0)
    slot.bgTex:SetWidth(slotSize)
    slot.bgTex:SetHeight(slotSize)
    slot.bgTex:SetVertexColor(0.75,0.75,0.75)
  
    slot.itemTex = slot:CreateTexture(nil, "BORDER")
    slot.itemTex:SetTexture(_data.textures.emptySlot)
    slot.itemTex:SetPoint("TOPLEFT", 0, 0)
    slot.itemTex:SetWidth(slotSize)
    slot.itemTex:SetHeight(slotSize)
    slot.itemTex:Hide()
  
    slot.qTex = slot:CreateTexture(nil, "OVERLAY")
    slot.qTex:SetTexture(_data.textures.slotHi)
    slot.qTex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    slot.qTex:SetBlendMode("ADD")
    slot.qTex:SetPoint("TOPLEFT", 0, 0)
    slot.qTex:SetWidth(slotSize)
    slot.qTex:SetHeight(slotSize)
    slot.qTex:SetAlpha(0.75)
    slot.qTex:SetVertexColor(1,1,1)
    slot.qTex:Hide()
  
    slot.hitex = slot:CreateTexture(nil, "OVERLAY")
    slot.hitex:SetTexture(_data.textures.slotHi)
    slot.hitex:SetTexCoord(0.216, 0.768, 0.232, 0.784)
    slot.hitex:SetBlendMode("ADD")
    slot.hitex:SetPoint("TOPLEFT", 0, 0)
    slot.hitex:SetWidth(slotSize)
    slot.hitex:SetHeight(slotSize)
    slot.hitex:SetAlpha(0.75)
    _util:SetVertexColor(slot.hitex, _data.colors.defaultSlotHighlight)
    slot.hitex:Hide()
  end