PlayerbotsPanel.Data = {}
local _self = PlayerbotsPanel.Data
_self.textures = {}
_self.colors = {}
_self.sounds = {}
_self.strings = {}
_self.ROOT_PATH = "Interface\\AddOns\\PlayerbotsPanel\\"
_self.TEX_ROOT_PATH = "Interface\\AddOns\\PlayerbotsPanel\\textures\\"

-----------------------------------------------------------------------------
----- Colors 
-----------------------------------------------------------------------------

function _self.CreateColor(r,g,b,a, hex)
    local color = {}
    if a == nil then a = 255 end
    color.fr = r / 255
    color.fg = g / 255
    color.fb = b / 255
    color.fa = a / 255
    color.r = r
    color.g = g
    color.b = b
    color.a = a
    color.hex = hex
    return color
end
function _self.CreateColorF(r,g,b,a, hex)
    local color = {}
    if a == nil then a = 1 end
    color.fr = r 
    color.fg = g
    color.fb = b 
    color.fa = a 
    color.r = r * 255
    color.g = g * 255
    color.b = b * 255
    color.a = a * 255
    color.hex = hex
    return color
end 

_self.colors.defaultSlotHighlight = {
  r = 94/255, 
  g = 147/255,
  b = 243/255
}

_self.colors.quality = {}
for i=0, 7 do
    local r,g,b = GetItemQualityColor(i)
    _self.colors.quality[i] = _self.CreateColorF(r,g,b)
end

_self.colors.white = _self.CreateColor(255,255,255,255,"#FFFFFF")
_self.colors.gold = _self.CreateColor(255,215,0,255,"#FFD700")
_self.colors.red = _self.CreateColor(255,0,0,255,"#FF0000")
_self.colors.green = _self.CreateColor(0,255,0,255,"#FF0000")
_self.colors.gray = _self.CreateColor(55,55,55,255,"#848484")
_self.colors.classes = {
    DEATHKNIGHT = _self.CreateColor(196, 30, 58, 255, "#C41E3A"),
    DRUID = _self.CreateColor(255, 124, 10, 255, "#FF7C0A"),
    HUNTER = _self.CreateColor(170, 211, 114, 255, "#AAD372"),
    MAGE = _self.CreateColor(63, 199, 235, 255, "#3FC7EB"),
    PALADIN = _self.CreateColor(244, 140, 186, 255, "#F48CBA"),
    PRIEST = _self.CreateColor(255, 255, 255, 255, "#FFFFFF"),
    ROGUE = _self.CreateColor(255, 244, 104, 255, "#FFF468"),
    SHAMAN = _self.CreateColor(0, 112, 221, 255, "#0070DD"),
    WARLOCK = _self.CreateColor(135, 136, 238, 255, "#8788EE"),
    WARRIOR = _self.CreateColor(198, 155, 109, 255, "#C69B6D"),
}

-----------------------------------------------------------------------------
----- Textures 
-----------------------------------------------------------------------------
---generate local texture path
---@param texFileName string
local function texPath(texFileName)
    return _self.TEX_ROOT_PATH .. texFileName
end

-- placeholder and debug texture
_self.textures.white = "Interface\\BUTTONS\\WHITE8X8.BLP" 
-- highlight tex for gear slot
_self.textures.slotHi = "Interface\\Buttons\\UI-ActionButton-Border"
_self.textures.emptySlot = "Interface\\PaperDoll\\UI-Backpack-EmptySlot.blp"
-- background tex for gear slot, array
_self.textures.slotIDbg = {
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-RFinger.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-RFinger.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-REar.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-REar.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged.blp",
  "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard.blp",
--  INVSLOT_RELIC           = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Relic.blp"
}

_self.textures.updateBotsUp =  texPath("button_update_up.tga")
_self.textures.updateBotsDown =   texPath("button_update_down.tga")
_self.textures.updateBotsHi = texPath("UI-RotationRight-Big-Hi.tga")
-- inventory tab
_self.textures.inventoryTopbar = texPath("inventory_topbar.tga")
_self.textures.hideEmptyBtnDown = texPath("inventory_button_hide_empty_down.tga")
_self.textures.hideEmptyBtnUp = texPath("inventory_button_hide_empty_up.tga")
_self.textures.tradeBtnDown = texPath("button_trade_down.tga")
_self.textures.tradeBtnUp = texPath("button_trade_up.tga")
_self.textures.useBtnDown = texPath("button_use_down.tga")
_self.textures.useBtnUp = texPath("button_use_up.tga")
_self.textures.useItemOnItemFrame = texPath("frame_item_use_on_item.tga")
_self.textures.statsTabColumn = texPath("stats_tab_column.tga")
_self.textures.slotLoading = texPath("slot_loading.tga")

_self.raceData =
{
    ORC = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Orc1.blp"
    },
    TROLL = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Orc1.blp"
    },
    TAUREN = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Tauren1.blp"
    },
    UNDEAD = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Scourge1.blp"
    },
    BLOODELF = {
        background = "Interface\\DressUpFrame\\DressUpBackground-BloodElf1.blp"
    },

    HUMAN = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Human1.blp"
    },
    NIGHTELF = {
        background = "Interface\\DressUpFrame\\DressUpBackground-NightElf1.blp"
    },
    DWARF = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Dwarf1.blp"
    },
    GNOME = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Dwarf1.blp"
    },
    DRAENEI = {
        background = "Interface\\DressUpFrame\\DressUpBackground-Draenei1.blp"
    },
}

-----------------------------------------------------------------------------
----- Sounds
-----------------------------------------------------------------------------

_self.sounds.onAddonShow = ""--"KeyRingOpen"
_self.sounds.onAddonHide = "gsTitleQuit"
_self.sounds.onTabSwitch = "igAbilityOpen"
_self.sounds.onBotSelect = "INTERFACESOUND_GAMESCROLLBUTTON"

-----------------------------------------------------------------------------
----- Strings
-----------------------------------------------------------------------------

-- bot list
_self.strings.tooltips = {}
_self.strings.tooltips.updateBots = "Update bots - forces full a scan on all bots registered and online.\nThis can be quite heavy with lots of bots."
_self.strings.tooltips.addBot = "Add bot command. Bot will come online."
_self.strings.tooltips.removeBot = "Remove bot, it will go offline"
_self.strings.tooltips.inviteBot = "Invite bot to party / raid"
_self.strings.tooltips.uninviteBot = "Uninvite from party / raid"
-- gear view
_self.strings.tooltips.gearViewHelp = "Right click to unequip item\nDrag items from your bag on the portrait to trade them"
_self.strings.tooltips.gearViewUpdateGear = "Update all selected bot gear\nUse if you notice desync due to bugs or network"
-- inventory tab
_self.strings.tooltips.inventoryTabUpdate = "Update all bot items and bags, including bank and keychain\nUse if you notice desync due to bugs or network"
_self.strings.tooltips.inventoryTabHelp = "Right click to use or equip item. If trade is opened, will put it in trade.\nLeft click to start \" Use item on item\" action and right click to abort\nShift + Left click to print item link in chat"
_self.strings.tooltips.inventoryTabHideEmptySlots = "Hide empty slots"
_self.strings.tooltips.inventoryTabTradeBtn = "Open / Close trade panel"
_self.strings.tooltips.inventoryTabUseBtn = "Use item on item mode, left click first then second item.\nRight click to cancel"


-----------------------------------------------------------------------------
----- Stats
-----------------------------------------------------------------------------

local function SetTextColor(text, c)
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

_self.STAT_KEY = {
    "RESIST_FIRE",
    "RESIST_NATURE",
    "RESIST_FROST",
    "RESIST_SHADOW",
    "RESIST_ARCANE",
    "AGILITY",
    "INTELLECT",
    "SPIRIT",
    "STAMINA",
    "STRENGTH"
}

local _red = _self.colors.red
local _green = _self.colors.green

local function colorStatByVal(frame, positive, negative)
    local txt = frame.txtValue
    if positive > 0 or negative > 0 then
        if positive > negative then
            SetTextColor(txt, _green)
        else
            SetTextColor(txt, _red)
        end
    end
end

local function onResistTooltip(tooltip, group)
    tooltip:AddLine("Base: " .. group.base)
    tooltip:AddLine("Current: " .. group.resistance)
    if group.positive > 0 then
        tooltip:AddLine("From buffs: " .. group.positive, _green.fr, _green.fg, _green.fb)
    end

    if group.negative > 0 then
        tooltip:AddLine("From debuffs: " .. group.negative, _red.fr, _red.fg, _red.fb)
    end
end

local function onUpdateResist(frame, group)
    frame.txtValue:SetText(group.resistance)
    colorStatByVal(frame, group.positive, group.negative)
end

--- Used by stat rows 
_self.stats = {
    --[[
        1 - Arcane
        2 - Fire
        3 - Nature
        4 - Frost
        5 - Shadow
    ]]
    ["RESIST_ARCANE"] = {
        name = "Arcane Resistance",
        nameColor =  _self.CreateColor(64, 173, 203),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[1])
        end,
        onTooltip = function (botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[1])
        end
    },
    ["RESIST_FIRE"] = {
        name = "Fire Resistance",
        nameColor =  _self.CreateColor(226, 54, 54),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[2])
        end,
        onTooltip = function (botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[2])
        end
    },
    ["RESIST_NATURE"] = {
        name = "Nature Resistance",
        nameColor =  _self.CreateColor(32, 217, 100),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[3])
        end,
        onTooltip = function (botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[3])
        end
    },
    ["RESIST_FROST"] = {
        name = "Frost Resistance",
        nameColor =  _self.CreateColor(126, 217, 231),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[4])
        end,
        onTooltip = function (botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[4])
        end
    },
    ["RESIST_SHADOW"] = {
        name = "Shadow Resistance",
        nameColor =  _self.CreateColor(140, 103, 213),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[5])
        end,
        onTooltip = function (botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[5])
        end
    },
    

}