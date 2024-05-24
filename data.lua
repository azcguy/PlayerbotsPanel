PlayerbotsPanelData = {}
local _data = PlayerbotsPanelData
_data.textures = {}
_data.colors = {}
_data.sounds = {}
_data.strings = {}
_data.ROOT_PATH = "Interface\\AddOns\\PlayerbotsPanel\\"

-----------------------------------------------------------------------------
----- Colors 
-----------------------------------------------------------------------------

function PlayerbotsPanelData.CreateColor(r,g,b,a, hex)
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
function PlayerbotsPanelData.CreateColorF(r,g,b,a, hex)
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

_data.colors.defaultSlotHighlight = {
  r = 94/255, 
  g = 147/255,
  b = 243/255
}

_data.colors.quality = {}
for i=0, 7 do
    local r,g,b = GetItemQualityColor(i)
    _data.colors.quality[i] = _data.CreateColor(r,g,b)
end

_data.colors.white = _data.CreateColor(255,255,255,255,"#FFFFFF")
_data.colors.gold = _data.CreateColor(255,215,0,255,"#FFD700")
_data.colors.red = _data.CreateColor(255,0,0,255,"#FF0000")
_data.colors.gray = _data.CreateColor(55,55,55,255,"#848484")
_data.colors.classes = {
    DEATHKNIGHT = _data.CreateColor(196, 30, 58, 255, "#C41E3A"),
    DRUID = _data.CreateColor(255, 124, 10, 255, "#FF7C0A"),
    HUNTER = _data.CreateColor(170, 211, 114, 255, "#AAD372"),
    MAGE = _data.CreateColor(63, 199, 235, 255, "#3FC7EB"),
    PALADIN = _data.CreateColor(244, 140, 186, 255, "#F48CBA"),
    PRIEST = _data.CreateColor(255, 255, 255, 255, "#FFFFFF"),
    ROGUE = _data.CreateColor(255, 244, 104, 255, "#FFF468"),
    SHAMAN = _data.CreateColor(0, 112, 221, 255, "#0070DD"),
    WARLOCK = _data.CreateColor(135, 136, 238, 255, "#8788EE"),
    WARRIOR = _data.CreateColor(198, 155, 109, 255, "#C69B6D"),
}

-----------------------------------------------------------------------------
----- Textures 
-----------------------------------------------------------------------------

-- placeholder and debug texture
_data.textures.white = "Interface\\BUTTONS\\WHITE8X8.BLP" 
-- highlight tex for gear slot
_data.textures.slotHi = "Interface\\Buttons\\UI-ActionButton-Border"
_data.textures.emptySlot = "Interface\\PaperDoll\\UI-Backpack-EmptySlot.blp"
-- background tex for gear slot, array
_data.textures.slotIDbg = {
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

_data.textures.updateBotsUp =  _data.ROOT_PATH .. "textures\\button_update_up.tga"
_data.textures.updateBotsDown =   _data.ROOT_PATH .. "textures\\button_update_down.tga"
_data.textures.updateBotsHi = _data.ROOT_PATH .. "textures\\UI-RotationRight-Big-Hi.tga"
-- inventory tab
_data.textures.inventoryTopbar = _data.ROOT_PATH .. "textures\\inventory_topbar.tga"
_data.textures.hideEmptyBtnDown = _data.ROOT_PATH .. "textures\\inventory_button_hide_empty_down.tga"
_data.textures.hideEmptyBtnUp = _data.ROOT_PATH .. "textures\\inventory_button_hide_empty_up.tga"

_data.textures.slotLoading = _data.ROOT_PATH .. "textures\\slot_loading.tga"



_data.raceData =
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

_data.sounds.onAddonShow = "KeyRingOpen"
_data.sounds.onAddonHide = "gsTitleQuit"
_data.sounds.onTabSwitch = "igAbilityOpen"
_data.sounds.onBotSelect = "INTERFACESOUND_GAMESCROLLBUTTON"

-----------------------------------------------------------------------------
----- Strings
-----------------------------------------------------------------------------

-- bot list
_data.strings.tooltips = {}
_data.strings.tooltips.updateBots = "Update bots - forces full a scan on all bots registered and online.\nThis can be quite heavy with lots of bots."
_data.strings.tooltips.addBot = "Add bot command. Bot will come online."
_data.strings.tooltips.removeBot = "Remove bot, it will go offline"
_data.strings.tooltips.inviteBot = "Invite bot to party / raid"
_data.strings.tooltips.uninviteBot = "Uninvite from party / raid"
-- gear view
_data.strings.tooltips.gearViewHelp = "Left click to unequip item \nRight click to put item in trade\nDrag items on the portrait to trade them"
_data.strings.tooltips.gearViewUpdateGear = "Update all selected bot gear\nUse if you notice desync due to bugs or network"
-- inventory tab
_data.strings.tooltips.inventoryTabUpdate = "Update all bot items and bags, including bank and keychain\nUse if you notice desync due to bugs or network"
_data.strings.tooltips.inventoryTabHelp = "Right click to use or equip item\nLeft click to start \" Use item on item\" action and right click to abort\nShift + Left click to print item link in chat"
_data.strings.tooltips.inventoryTabHideEmptySlots = "Hide empty slots"
