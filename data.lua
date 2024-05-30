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

local _sb_hexColor = PlayerbotsPanel.StringBuffer:Get("Data.hexColor")
local _b = PlayerbotsPanel.StringBuffer:Get("Data.stat")
local _hexFormat = "%02X"
local _format = string.format
local _max = math.max
local _min = math.min
local _floor = math.floor
local _ceil = math.ceil

local function _eval(eval, ifTrue, ifFalse)
    if eval then
        return ifTrue
    else
        return ifFalse
    end
end

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

    _sb_hexColor:Clear()
    _sb_hexColor:STRING("FF")
    _sb_hexColor:STRING(string.format(_hexFormat, r))
    _sb_hexColor:STRING(string.format(_hexFormat, g))
    _sb_hexColor:STRING(string.format(_hexFormat, b))
    color.hex = _sb_hexColor:ToString()

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

    _sb_hexColor:Clear()
    _sb_hexColor:STRING("FF")
    _sb_hexColor:STRING(string.format(_hexFormat, r))
    _sb_hexColor:STRING(string.format(_hexFormat, g))
    _sb_hexColor:STRING(string.format(_hexFormat, b))
    color.hex = _sb_hexColor:ToString()

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

_self.CLASS_DATA = {
    DEATHKNIGHT = {
        hasMana = false
    },
    DRUID = {
        hasMana = true
    },
    HUNTER  = {
        hasMana = true
    },
    MAGE  = {
        hasMana = true
    },
    PALADIN  = {
        hasMana = true
    },
    PRIEST  = {
        hasMana = true
    },
    ROGUE  = {
        hasMana = false
    },
    SHAMAN  = {
        hasMana = true
    },
    WARLOCK  = {
        hasMana = true
    },
    WARRIOR  = {
        hasMana = false
    }
}

local _red = _self.colors.red
local _green = _self.colors.green
local _white = _self.colors.white

local function ComputePetBonus(bot, stat, value)
	local class = bot.class
	if( class == "WARLOCK" ) then
		if( WARLOCK_PET_BONUS[stat] ) then
			return value * WARLOCK_PET_BONUS[stat];
		else
			return 0;
		end
	elseif( class == "HUNTER" ) then
		if( HUNTER_PET_BONUS[stat] ) then 
			return value * HUNTER_PET_BONUS[stat];
		else
			return 0;
		end
	end
	return 0;
end

local function GetArmorReduction(armor, attackerLevel)
	local levelModifier = attackerLevel;
	if ( levelModifier > 59 ) then
		levelModifier = levelModifier + (4.5 * (levelModifier-59));
	end
	local temp = 0.1*armor/(8.5*levelModifier + 40);
	temp = temp/(1+temp);

	if ( temp > 0.75 ) then
		return 75;
	end

	if ( temp < 0 ) then
		return 0;
	end

	return temp*100;
end

local function colorStatByVal(frame, positive, negative)
    local txt = frame.txtValue
    if positive > 0 or negative > 0 then
        if positive > negative then
            SetTextColor(txt, _green)
        else
            SetTextColor(txt, _red)
        end
    else
        SetTextColor(txt, _white)
    end
end

local function setValueTextAndColorByVal(frame, value, positive, negative)
    local txt = frame.txtValue
    txt:SetText(value)
    colorStatByVal(frame, positive, negative)
end

local function onResistTooltip(tooltip, group, name)
    if not group then return end
    tooltip:AddLine(name, 1,1,1)
    tooltip:AddLine("Current: " .. group.resistance)
    if group.positive > 0 then
        tooltip:AddLine("From buffs: " .. group.positive, _green.fr, _green.fg, _green.fb)
    end
    if group.negative > 0 then
        tooltip:AddLine("From debuffs: " .. group.negative, _red.fr, _red.fg, _red.fb)
    end
end

local function onUpdateResist(frame, group)
    if not group then return end
    frame.txtValue:SetText(group.resistance)
    colorStatByVal(frame, group.positive, group.negative)
end

local function onUpdateBaseStat(frame, value, positive, negative)
    setValueTextAndColorByVal(frame, value, positive, negative)
end

local function onTooltipBaseStat(tooltip, group, data)
    local stat = group
    if not group then return end
    _b:Clear()
    _b:PushColor()
    _b:STRING(data.name)
    _b:SPACE()
    _b:INT(stat.effectiveStat)
    _b:STRING(" (")
    _b:INT(stat.effectiveStat - stat.positive)
    _b:PushColor(_green.hex)
    _b:STRING("+")
    _b:INT(stat.positive)
    _b:PushColor()
    _b:STRING(") ")
    _b:PopColor()
    tooltip:AddLine(_b:ToString())
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
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[1], self.name)
        end
    },
    ["RESIST_FIRE"] = {
        name = "Fire Resistance",
        nameColor =  _self.CreateColor(226, 54, 54),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[2])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[2], self.name)
        end
    },
    ["RESIST_NATURE"] = {
        name = "Nature Resistance",
        nameColor =  _self.CreateColor(32, 217, 100),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[3])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[3], self.name)
        end
    },
    ["RESIST_FROST"] = {
        name = "Frost Resistance",
        nameColor =  _self.CreateColor(126, 217, 231),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[4])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[4], self.name)
        end
    },
    ["RESIST_SHADOW"] = {
        name = "Shadow Resistance",
        nameColor =  _self.CreateColor(140, 103, 213),
        onUpdateValue = function (frame, botstats)
            onUpdateResist(frame, botstats.resists[5])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[5], self.name)
        end
    },
    ["STRENGTH"] = {
        name = "Strength",
        onUpdateValue = function (frame, botstats)
            local g = botstats.base[1]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[1]
            onTooltipBaseStat(tooltip, group, self)
            if group.attackPower then
                tooltip:AddLine(_format(_G["DEFAULT_STAT1_TOOLTIP"], group.attackPower))
            end
            tooltip:AddLine(_format( STAT_BLOCK_TOOLTIP, _max(0, group.effectiveStat * BLOCK_PER_STRENGTH - 10) ))
        end
    },
    ["AGILITY"] = {
        name = "Agility",
        onUpdateValue = function (frame, botstats)
            local g = botstats.base[2]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[2]
            onTooltipBaseStat(tooltip, group, self)
            local defaultTooltip = _G["DEFAULT_STAT2_TOOLTIP"]
            local atkPow = _eval(group.attackPower, group.attackPower, 0)
            local agiCrit = _eval(group.agilityCritChance, group.agilityCritChance, 0)
            tooltip:AddLine(_format(STAT_ATTACK_POWER, atkPow) .. _format(defaultTooltip, agiCrit, group.effectiveStat * ARMOR_PER_AGILITY))
        end
    },
    ["STAMINA"] = {
        name = "Stamina",
        onUpdateValue = function (frame, botstats)
            local g = botstats.base[3]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[3]
            onTooltipBaseStat(tooltip, group, self)
            local defaultTooltip = _G["DEFAULT_STAT3_TOOLTIP"]
            local baseStam = _min(20, group.effectiveStat);
            local moreStam = group.effectiveStat - baseStam;
            _b:Clear()
            _b:STRING(_format(defaultTooltip, (baseStam + (moreStam * HEALTH_PER_STAMINA)) * group.maxHpModifier ))
            local petStam = ComputePetBonus(bot, "PET_BONUS_STAM", group.effectiveStat );
            if( petStam > 0 ) then
                _b:NEWLINE()
                _b:STRING(_format(PET_BONUS_TOOLTIP_STAMINA ,petStam ));
            end
            tooltip:AddLine(_b:ToString())
        end
    },
    ["INTELLECT"] = {
        name = "Intellect",
        onUpdateValue = function (frame, botstats)
            local g = botstats.base[4]
            onUpdateBaseStat(frame,  g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[4]
            onTooltipBaseStat(tooltip, group, self)

            local baseInt = _min(20, group.effectiveStat);
            local moreInt = group.effectiveStat - baseInt
            local hasMana = _self.CLASS_DATA[bot.class].hasMana
            local defaultTooltip = _G["DEFAULT_STAT4_TOOLTIP"]
            local intCrit = _eval(group.intellectCritChance, group.intellectCritChance, 0)
            _b:Clear()
            _b:STRING("")
            if ( hasMana ) then
                _b:STRING(_format( defaultTooltip, baseInt + moreInt * MANA_PER_INTELLECT, intCrit));
            end
            local petInt = ComputePetBonus("PET_BONUS_INT", group.effectiveStat );
            if( petInt > 0 ) then
                _b:NEWLINE()
                _b:STRING(_format( PET_BONUS_TOOLTIP_INTELLECT , petInt));
            end
            tooltip:AddLine(_b:ToString())
        end
    },
    ["SPIRIT"] = {
        name = "Spirit",
        onUpdateValue = function (frame, botstats)
            local g = botstats.base[5]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[5]
            onTooltipBaseStat(tooltip, group, self)
            local defaultTooltip = _G["DEFAULT_STAT5_TOOLTIP"]
            local healthRegenFromSpirit = _eval(group.healthRegenFromSpirit, group.healthRegenFromSpirit, 0)
            local hasMana = _self.CLASS_DATA[bot.class].hasMana

            _b:Clear()
            _b:STRING(_format(defaultTooltip, healthRegenFromSpirit))
            if ( hasMana ) then
                local manaRegenFromSpirit = _eval(group.manaRegenFromSpirit, group.manaRegenFromSpirit, 0)
                manaRegenFromSpirit = _floor( manaRegenFromSpirit * 5.0 );
                _b:NEWLINE()
                _b:STRING(_format(MANA_REGEN_FROM_SPIRIT, manaRegenFromSpirit));
            end
            tooltip:AddLine(_b:ToString())
        end
    },
    ["ARMOR"] = {
        name = "Armor",
        onUpdateValue = function (frame, botstats)
            local g = botstats.armor
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.armor
            if not group then return end
            onTooltipBaseStat(tooltip, group, self)
            local armorReduction = GetArmorReduction(group.effectiveStat, bot.level);
            _b:Clear()
            _b:STRING(_format(DEFAULT_STATARMOR_TOOLTIP, armorReduction))
            local petBonus = ComputePetBonus("PET_BONUS_ARMOR", group.effectiveStat);
            if( petBonus > 0 ) then
                _b:NEWLINE()
                _b:STRING(_format(PET_BONUS_TOOLTIP_ARMOR, petBonus))
            end
            tooltip:AddLine(_b:ToString())
        end
    },
    ["DAMAGE_MELEE"] = {
        name = "Melee Damage",
        onUpdateValue = function (frame, botstats)
            local g = botstats.melee
            local minDamage = g.minMeleeDamage
            local maxDamage = g.maxMeleeDamage
            local physicalBonusPos= g.meleePhysicalBonusPositive
            local physicalBonusNeg= g.meleePhysicalBonusNegative
            local percent= g.meleeDamageBuffPercent
            local displayMin = _max(_floor(minDamage),1)
            local displayMax = _max(_ceil(maxDamage),1)
        
            minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
            maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg
        
            local baseDamage = (minDamage + maxDamage) * 0.5
            local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
            local totalBonus = (fullDamage - baseDamage)

            if ( totalBonus < 0.1 and totalBonus > -0.1 ) then totalBonus = 0.0 end

            _b:Clear()
            local color = _eval(totalBonus > 0, _green, _red)

            if ( totalBonus == 0 ) then
                _b:INT(displayMin)
                _b:STRING(" - ")
                _b:INT(displayMax)
            else
                _b:PushColor(color)
                _b:INT(displayMin)
                _b:STRING(" - ")
                _b:INT(displayMax)
                _b:PopColor()
            end
            frame.txtValue:SetText(_b:ToString())
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            local speed = g.meleeSpeed;
            local offhandSpeed = g.meleeOffhandSpeed;
            local minDamage = g.minMeleeDamage;
            local maxDamage = g.maxMeleeDamage; 
            local minOffHandDamage= g.minMeleeOffHandDamage; 
            local maxOffHandDamage= g.maxMeleeOffHandDamage;  
            local physicalBonusPos= g.meleePhysicalBonusPositive; 
            local physicalBonusNeg= g.meleePhysicalBonusNegative; 
            local percent= g.meleeDamageBuffPercent; 
            local displayMin = _max(_floor(minDamage),1);
            local displayMax = _max(_ceil(maxDamage),1);
        
            minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
            maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
        
            local baseDamage = (minDamage + maxDamage) * 0.5;
            local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
            local totalBonus = (fullDamage - baseDamage);
            local damagePerSecond = (_max(fullDamage,1) / speed);
            -- damage tooltip
            tooltip:AddLine(INVTYPE_WEAPONMAINHAND, _white.r, _white.g, _white.b)

            _b:Clear()
            _b:INT(displayMin)
            _b:STRING(" - ")
            _b:INT(displayMax)


            if ( totalBonus < 0.1 and totalBonus > -0.1 ) then
                totalBonus = 0.0;
            end

            if ( totalBonus == 0 ) then
            else
                if ( physicalBonusPos > 0 ) then
                    _b:PushColor(_green)
                    _b:STRING(" +")
                    _b:INT(physicalBonusPos)
                    _b:PopColor()
                end
                if ( physicalBonusNeg < 0 ) then
                    _b:PushColor(_red)
                    _b:STRING(" +")
                    _b:INT(physicalBonusPos)
                    _b:PopColor()
                end
                if ( percent > 1 ) then
                    _b:PushColor(_green)
                    _b:STRING(" x")
                    _b:INT(_floor(percent*100+0.5))
                    _b:PopColor()
                elseif ( percent < 1 ) then
                    _b:PushColor(_red)
                    _b:STRING(" x")
                    _b:INT(_floor(percent*100+0.5))
                    _b:PopColor()
                end
            end

            tooltip:AddDoubleLine(_format(STAT_FORMAT, ATTACK_SPEED_SECONDS), _format("%.2f", speed))  
            tooltip:AddDoubleLine(_format(STAT_FORMAT, DAMAGE), _b:ToString())  
            tooltip:AddDoubleLine(_format(STAT_FORMAT, DAMAGE_PER_SECOND), _format("%.2f", damagePerSecond))  
            tooltip:AddLine("\n")

            if ( offhandSpeed > 0 ) then
                minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
                maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
        
                local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
                local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
                local offhandDamagePerSecond = (_max(offhandFullDamage,1) / offhandSpeed);

                _b:INT(_max(_floor(minOffHandDamage),1))
                _b:STRING(" - ")
                _b:INT(_max(_ceil(maxOffHandDamage),1))

                if ( physicalBonusPos > 0 ) then
                    _b:PushColor(_green)
                    _b:STRING(" +")
                    _b:INT(physicalBonusPos)
                    _b:PopColor()
                end
                if ( physicalBonusNeg < 0 ) then
                    _b:PushColor(_red)
                    _b:STRING(" ")
                    _b:INT(physicalBonusNeg)
                    _b:PopColor()
                end
                _b:NEWLINE()
                if ( percent > 1 ) then
                    _b:PushColor(_green)
                    _b:STRING(" x")
                    _b:INT(_floor(percent*100+0.5))
                    _b:PopColor()
                elseif ( percent < 1 ) then
                    _b:PushColor(_red)
                    _b:STRING(" x")
                    _b:INT(_floor(percent*100+0.5))
                    _b:PopColor()
                end

                tooltip:AddLine(INVTYPE_WEAPONOFFHAND, _white.r, _white.g, _white.b)
                tooltip:AddDoubleLine(_format(STAT_FORMAT, ATTACK_SPEED_SECONDS), _format("%.2f", offhandSpeed))
                tooltip:AddDoubleLine(_format(STAT_FORMAT, DAMAGE), _b:ToString())
                tooltip:AddDoubleLine(_format(STAT_FORMAT, DAMAGE_PER_SECOND), _format("%.1f", offhandDamagePerSecond))
            end
        end
    },
    ["SPEED_MELEE"] = {
        name = "Melee Speed",
        onUpdateValue = function (frame, botstats)
            local g = botstats.armor
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.armor
            if not group then return end
            onTooltipBaseStat(tooltip, group, self)
            local armorReduction = GetArmorReduction(group.effectiveStat, bot.level);
            _b:Clear()
            _b:STRING(_format(DEFAULT_STATARMOR_TOOLTIP, armorReduction))
            local petBonus = ComputePetBonus("PET_BONUS_ARMOR", group.effectiveStat);
            if( petBonus > 0 ) then
                _b:NEWLINE()
                _b:STRING(_format(PET_BONUS_TOOLTIP_ARMOR, petBonus))
            end
            tooltip:AddLine(_b:ToString())
        end
    },

}