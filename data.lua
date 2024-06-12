PlayerbotsPanel.data = {}
local _self = PlayerbotsPanel.data
_self.textures = {}
_self.colors = {}
_self.sounds = {}
_self.strings = {}
_self.ROOT_PATH = "Interface\\AddOns\\PlayerbotsPanel\\"
_self.TEX_ROOT_PATH = "Interface\\AddOns\\PlayerbotsPanel\\textures\\"

-----------------------------------------------------------------------------
----- Colors 
-----------------------------------------------------------------------------

local _util = PlayerbotsPanel.broker.util
local _sb_hexColor = _util.stringBuffer.Create("Data.hexColor")
local _b = _util.stringBuffer.Create("Data.stat")
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

function _self.BotHasRangedWeapon(bot)
    if bot.items then
        local ranged = bot.items[INVSLOT_RANGED]
        if ranged and ranged.link then
            return true
        end
    end
    return false
end

local _botPowerTypes = {
    DEATHKNIGHT = { 6, "RUNIC_POWER" },
    DRUID = { 0, "MANA" },
    HUNTER = { 0, "MANA" },
    MAGE =  { 0, "MANA" },
    PALADIN = { 0, "MANA" },
    PRIEST = { 0, "MANA" },
    ROGUE = { 3, "ENERGY" }, 
    SHAMAN = { 0, "MANA" },
    WARLOCK = { 0, "MANA" },
    WARRIOR = { 1, "RAGE" }
}

function _self.GetBotPowerType(bot)
    if bot and bot.class then
        local power = _botPowerTypes[bot.class]
        return power[1], power[2]
    end
end

function _self.BotHasMana(bot)
    local powerid, powertoken = _self.GetBotPowerType(bot)
    return powerid == 0
end

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

local function GetDodgeBlockParryChanceFromDefense(base, modifier, level)
	local defensePercent = DODGE_PARRY_BLOCK_PERCENT_PER_DEFENSE * ((base + modifier) - (level*5));
	defensePercent = _max(defensePercent, 0);
	return defensePercent;
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

local function onTooltipBaseStat(tooltip, name, value, positive, negative)
    _b:Clear()
    _b:PushColor()
    _b:STRING(name)
    _b:SPACE()
    _b:INT(value)
    if positive > 0 then
        _b:STRING(" (")
        _b:INT(value - positive)
        _b:PushColor(_green.hex)
        _b:STRING("+")
        _b:INT(positive)
        _b:PushColor()
        _b:STRING(") ")
        _b:PopColor()
    end
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
        name = RESISTANCE6_NAME,
        nameColor =  _self.CreateColor(64, 173, 203),
        onUpdateValue = function (frame, bot, botstats)
            onUpdateResist(frame, botstats.resists[1])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[1], self.name)
        end
    },
    ["RESIST_FIRE"] = {
        name = RESISTANCE2_NAME,
        nameColor =  _self.CreateColor(226, 54, 54),
        onUpdateValue = function (frame, bot, botstats)
            onUpdateResist(frame, botstats.resists[2])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[2], self.name)
        end
    },
    ["RESIST_NATURE"] = {
        name = RESISTANCE3_NAME,
        nameColor =  _self.CreateColor(32, 217, 100),
        onUpdateValue = function (frame, bot, botstats)
            onUpdateResist(frame, botstats.resists[3])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[3], self.name)
        end
    },
    ["RESIST_FROST"] = {
        name = RESISTANCE4_NAME,
        nameColor =  _self.CreateColor(126, 217, 231),
        onUpdateValue = function (frame, bot, botstats)
            onUpdateResist(frame, botstats.resists[4])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[4], self.name)
        end
    },
    ["RESIST_SHADOW"] = {
        name = RESISTANCE5_NAME,
        nameColor =  _self.CreateColor(140, 103, 213),
        onUpdateValue = function (frame, bot, botstats)
            onUpdateResist(frame, botstats.resists[5])
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            onResistTooltip(tooltip, botstats.resists[5], self.name)
        end
    },
    ["STRENGTH"] = {
        name = SPELL_STAT1_NAME,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.base[1]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[1]
            onTooltipBaseStat(tooltip, self.name, group.effectiveStat, group.positive, group.negative)
            if group.attackPower then
                tooltip:AddLine(_format(_G["DEFAULT_STAT1_TOOLTIP"], group.attackPower))
            end
            tooltip:AddLine(_format( STAT_BLOCK_TOOLTIP, _max(0, group.effectiveStat * BLOCK_PER_STRENGTH - 10) ))
        end
    },
    ["AGILITY"] = {
        name = SPELL_STAT2_NAME,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.base[2]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[2]
            onTooltipBaseStat(tooltip, self.name, group.effectiveStat, group.positive, group.negative)
            local defaultTooltip = _G["DEFAULT_STAT2_TOOLTIP"]
            local atkPow = _eval(group.attackPower, group.attackPower, 0)
            local agiCrit = _eval(group.agilityCritChance, group.agilityCritChance, 0)
            tooltip:AddLine(_format(STAT_ATTACK_POWER, atkPow) .. _format(defaultTooltip, agiCrit, group.effectiveStat * ARMOR_PER_AGILITY))
        end
    },
    ["STAMINA"] = {
        name = SPELL_STAT3_NAME,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.base[3]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[3]
            onTooltipBaseStat(tooltip, self.name, group.effectiveStat, group.positive, group.negative)
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
        name = SPELL_STAT4_NAME,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.base[4]
            onUpdateBaseStat(frame,  g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[4]
            onTooltipBaseStat(tooltip, self.name, group.effectiveStat, group.positive, group.negative)

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
        name = SPELL_STAT5_NAME,
        onUpdateValue = function (frame,  bot, botstats)
            local g = botstats.base[5]
            onUpdateBaseStat(frame, g.effectiveStat, g.positive, g.negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.base[5]
            onTooltipBaseStat(tooltip, self.name, group.effectiveStat, group.positive, group.negative)
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
        name = RESISTANCE0_NAME,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            onUpdateBaseStat(frame, g.effectiveArmor, g.armorPositive, g.armorNegative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local group = botstats.defenses
            if not group then return end
            onTooltipBaseStat(tooltip, self.name, group.effectiveArmor, group.armorPositive, group.armorNegative)
            local armorReduction = GetArmorReduction(group.effectiveArmor, bot.level);
            _b:Clear()
            _b:STRING(_format(DEFAULT_STATARMOR_TOOLTIP, armorReduction))
            local petBonus = ComputePetBonus("PET_BONUS_ARMOR", group.effectiveArmor);
            if( petBonus > 0 ) then
                _b:NEWLINE()
                _b:STRING(_format(PET_BONUS_TOOLTIP_ARMOR, petBonus))
            end
            tooltip:AddLine(_b:ToString())
        end
    },
    ["DAMAGE_MELEE"] = {
        name = DAMAGE,
        onUpdateValue = function (frame, bot, botstats)
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
        name = WEAPON_SPEED,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.melee
            if not g then return end

            local speed = g.meleeSpeed;
            local offhandSpeed = g.meleeOffhandSpeed;

            _b:Clear()
            _b:STRING(_format("%.2f", speed))
            if ( offhandSpeed ) then
                _b:STRING(" / ");
                _b:STRING(_format("%.2f", offhandSpeed))
            end
            frame.txtValue:SetText(_b:ToString())
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            if not g then return end


            local speed = g.meleeSpeed;
            local offhandSpeed = g.meleeOffhandSpeed;

            _b:Clear()
            _b:STRING(_format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED))
            _b:SPACE()
            _b:STRING(_format("%.2f", speed))
            if ( offhandSpeed ) then
                _b:STRING(" / ");
                _b:STRING(_format("%.2f", offhandSpeed))
            end
            tooltip:AddLine(_b:ToString(), _white.r, _white.g, _white.b)
            tooltip:AddLine(_format(CR_HASTE_RATING_TOOLTIP, g.meleeHaste, g.meleeHasteBonus))
        end
    },
    ["ATTACK_POWER"] = {
        name = ATTACK_POWER,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.melee
            if not g then return end
            local base = g.meleeAtkPowerBase
            local positive = g.meleeAtkPowerPositive
            local negative = g.meleeAtkPowerNegative
            onUpdateBaseStat(frame, base+positive, positive, negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            if not g then return end

            local base = g.meleeAtkPowerBase
            local positive = g.meleeAtkPowerPositive
            local negative = g.meleeAtkPowerNegative

            onTooltipBaseStat(tooltip, MELEE_ATTACK_POWER, _max((base+positive+negative), 0), positive, negative)
            tooltip:AddLine(_format(MELEE_ATTACK_POWER_TOOLTIP, _max((base+positive+negative), 0) / ATTACK_POWER_MAGIC_NUMBER))
        end
    },
    ["MELEE_HIT_RATING"] = {
        name = COMBAT_RATING_NAME6,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.melee
            if not g then return end
            local value = g.meleeHit
            onUpdateBaseStat(frame, value, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            if not g then return end
            local value = g.meleeHit
            local bonus = g.meleeHitBonus

            onTooltipBaseStat(tooltip, COMBAT_RATING_NAME6, value, 0, 0)
            tooltip:AddLine(_format(CR_HIT_MELEE_TOOLTIP, bot.level, bonus, g.armorPen, g.armorPenBonus, g.armorPenPercent))
        end
    },    
    ["MELEE_CRIT"] = {
        name = MELEE_CRIT_CHANCE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.melee
            if not g then return end
            local value = g.meleeCritChance
            onUpdateBaseStat(frame, value, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            if not g then return end
            local critChance = g.meleeCritChance

            onTooltipBaseStat(tooltip, MELEE_CRIT_CHANCE, critChance, 0, 0)
            tooltip:AddLine(_format(CR_CRIT_MELEE_TOOLTIP, g.meleeCritRating, g.meleeCritRatingBonus))
        end
    },
    ["EXPERTISE"] = {
        name = STAT_EXPERTISE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.melee
            if not g then return end
            local expertise = g.expertise
            local offhandExpertise = g.offhandExpertise
            _b:Clear()
            _b:INT(expertise)
            _b:STRING(" / ")
            _b:INT(offhandExpertise)
            frame.txtValue:SetText(_b:ToString())
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.melee
            if not g then return end
            local expertise = g.expertise
            local offhandExpertise = g.offhandExpertise
            local offhandSpeed = g.meleeOffhandSpeed
            local expertisePercent = g.expertisePercent
            local offhandExpertisePercent = g.offhandExpertisePercent
            _b:Clear()
            _b:STRING(self.name)
            _b:SPACE()
            _b:INT(expertise)
            _b:STRING(" / ")
            _b:INT(offhandExpertise)
            tooltip:AddLine(_b:ToString(), _white.r, _white.g, _white.b)

            _b:FLOAT(expertisePercent)
            _b:STRING("%")
            if offhandSpeed > 0 then
                _b:STRING(" / ")
                _b:FLOAT(offhandExpertisePercent)
                _b:STRING("%")
            end
            tooltip:AddLine(_format(CR_EXPERTISE_TOOLTIP, _b:ToString(), g.expertiseRating, g.expertiseRatingBonus))
        end
    },
    ["DAMAGE_RANGED"] = {
        name = DAMAGE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.ranged
            if not g then return end

            if not _self.BotHasRangedWeapon(bot) then
                frame.txtValue:SetText(NOT_APPLICABLE)
                return
            end

            local minDamage = g.rangedMinDamage
            if not minDamage then return end

            local maxDamage = g.rangedMaxDamage
            local physicalBonusPos= g.rangedPhysicalBonusPositive
            local physicalBonusNeg= g.rangedPhysicalBonusNegative
            local percent= g.rangedDamageBuffPercent
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
            local g = botstats.ranged
            local speed = g.rangedAttackSpeed;
            local minDamage = g.rangedMinDamage;
            local maxDamage = g.rangedMaxDamage; 
            local physicalBonusPos= g.rangedPhysicalBonusPositive; 
            local physicalBonusNeg= g.rangedPhysicalBonusNegative; 
            local percent= g.rangedDamageBuffPercent; 
            local displayMin = _max(_floor(minDamage),1);
            local displayMax = _max(_ceil(maxDamage),1);
        
            minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
            maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;
        
            local baseDamage = (minDamage + maxDamage) * 0.5;
            local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
            local totalBonus = (fullDamage - baseDamage);
            local damagePerSecond = (_max(fullDamage,1) / speed);
            -- damage tooltip
            tooltip:AddLine(INVTYPE_RANGED, _white.r, _white.g, _white.b)

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
        end
    },
    ["SPEED_RANGED"] = {
        name = ATTACK_SPEED,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.ranged
            if not g then return end
            if not _self.BotHasRangedWeapon(bot) then
                frame.txtValue:SetText(NOT_APPLICABLE)
                return
            end
            local speed = g.rangedAttackSpeed;
            frame.txtValue:SetText(_format("%.2f", speed))
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.ranged
            if not g then return end

            local speed = g.rangedAttackSpeed;

            _b:Clear()
            _b:STRING(_format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED))
            _b:SPACE()
            _b:STRING(_format("%.2f", speed))
            tooltip:AddLine(_b:ToString(), _white.r, _white.g, _white.b)
            tooltip:AddLine(_format(CR_HASTE_RATING_TOOLTIP, g.rangedHaste, g.rangedHasteBonus))
        end
    },
    ["RANGED_ATTACK_POWER"] = {
        name = ATTACK_POWER,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.ranged
            if not g then return end
            local base = g.rangedAttackPower
            local positive = g.rangedAttackPowerPositive
            local negative = g.rangedAttackPowerNegative
            onUpdateBaseStat(frame, base+positive, positive, negative)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.ranged
            if not g then return end

            local base = g.rangedAttackPower
            local positive = g.rangedAttackPowerPositive
            local negative = g.rangedAttackPowerNegative

            onTooltipBaseStat(tooltip, RANGED_ATTACK_POWER, _max((base+positive+negative), 0), positive, negative)
            tooltip:AddLine(_format(RANGED_ATTACK_POWER_TOOLTIP, _max((base+positive+negative), 0) / ATTACK_POWER_MAGIC_NUMBER))
        end
    },
    ["RANGED_HIT_RATING"] = {
        name = COMBAT_RATING_NAME7,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.ranged
            if not g then return end
            local value = g.rangedHit
            onUpdateBaseStat(frame, value, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.ranged
            local m = botstats.melee
            if not g then return end
            if not m then return end
            local value = g.rangedHit
            local bonus = g.rangedHitBonus

            onTooltipBaseStat(tooltip, COMBAT_RATING_NAME7, value, 0, 0)
            tooltip:AddLine(_format(CR_HIT_RANGED_TOOLTIP, bot.level, bonus, m.armorPen, m.armorPenBonus, m.armorPenPercent))
        end
    },    
    ["RANGED_CRIT"] = {
        name = RANGED_CRIT_CHANCE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.ranged
            if not g then return end
            local value = g.rangedCritChance
            onUpdateBaseStat(frame, value, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.ranged
            if not g then return end
            local critChance = g.rangedCritChance

            onTooltipBaseStat(tooltip, RANGED_CRIT_CHANCE, critChance, 0, 0)
            tooltip:AddLine(_format(CR_CRIT_RANGED_TOOLTIP, g.rangedCritRating, g.rangedCritRatingBonus))
        end
    },    
    ["SPELL_BONUS_DAMAGE"] = {
        name = BONUS_DAMAGE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            
            local minModifier = g.spellBonusDamage[2];
            for i=2, MAX_SPELL_SCHOOLS do
                minModifier = _min(minModifier, g.spellBonusDamage[i]);
            end
            onUpdateBaseStat(frame, minModifier, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end
            local minModifier = g.spellBonusDamage[2];
            local bonusDamage = 0
            for i=2, MAX_SPELL_SCHOOLS do
                bonusDamage = g.spellBonusDamage[i]
                minModifier = _min(minModifier, bonusDamage);
            end

            onTooltipBaseStat(tooltip, BONUS_DAMAGE, minModifier, 0, 0)

            for i=2, MAX_SPELL_SCHOOLS do
                tooltip:AddDoubleLine(_G["DAMAGE_SCHOOL"..i], g.spellBonusDamage[i]);
                tooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
            end

            local petStr, damage;
            if( g.spellBonusDamage[6] > g.spellBonusDamage[3] ) then
                petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_SHADOW;
                damage = g.spellBonusDamage[6];
            else
                petStr = PET_BONUS_TOOLTIP_WARLOCK_SPELLDMG_FIRE;
                damage = g.spellBonusDamage[3];
            end

            local petBonusAP = ComputePetBonus("PET_BONUS_SPELLDMG_TO_AP", damage );
            local petBonusDmg = ComputePetBonus("PET_BONUS_SPELLDMG_TO_SPELLDMG", damage );
            
            if( petBonusAP > 0 or petBonusDmg > 0 ) then
                tooltip:AddLine("\n" .. _format(petStr, petBonusAP, petBonusDmg), nil, nil, nil, 1 );
            end
        end
    },    
    ["SPELL_BONUS_HEALING"] = {
        name = BONUS_HEALING,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            onUpdateBaseStat(frame, g.spellBonusHealing , 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end
            tooltip:AddLine(_format(BONUS_HEALING_TOOLTIP, g.spellBonusHealing))
        end
    },    
    ["SPELL_HIT_RATING"] = {
        name = COMBAT_RATING_NAME8,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            onUpdateBaseStat(frame, g.spellHit, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end

            onTooltipBaseStat(tooltip, COMBAT_RATING_NAME8, value, 0, 0)
            tooltip:AddLine(_format(CR_HIT_SPELL_TOOLTIP, bot.level, g.spellHitBonus, g.spellPenetration, g.spellPenetration))
        end
    },    
    ["SPELL_CRIT"] = {
        name = SPELL_CRIT_CHANCE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            local spellCrit;
            local minCrit = g.spellCritChance[2];
            for i=2, MAX_SPELL_SCHOOLS do
                spellCrit = g.spellCritChance[i];
                minCrit = _min(minCrit, spellCrit);
            end
            onUpdateBaseStat(frame, minCrit, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end
            local spellCrit;
            local minCrit = g.spellCritChance[2];
            for i=2, MAX_SPELL_SCHOOLS do
                spellCrit = g.spellCritChance[i];
                minCrit = _min(minCrit, spellCrit);
            end
            onTooltipBaseStat(tooltip, COMBAT_RATING_NAME11, g.spellCritRating, 0, 0)
            for i=2, MAX_SPELL_SCHOOLS do
                tooltip:AddDoubleLine(_G["DAMAGE_SCHOOL"..i], g.spellCritChance[i]);
                tooltip:AddTexture("Interface\\PaperDollInfoFrame\\SpellSchoolIcon"..i);
            end
            --tooltip:AddLine(_format(CR_HIT_SPELL_TOOLTIP, bot.level, g.spellHitBonus, g.spellPenetration, g.spellPenetration))
        end
    },    
    ["SPELL_HASTE"] = {
        name = SPELL_HASTE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            onUpdateBaseStat(frame, g.spellHaste, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end
            
            tooltip:AddLine(SPELL_HASTE, 1,1,1)
            tooltip:AddLine(_format(SPELL_HASTE_TOOLTIP, g.spellHasteBonus))
        end
    },
    ["MANA_REGEN"] = {
        name = MANA_REGEN,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.spell
            if not g then return end
            if not _self.BotHasMana(bot) then
                frame.txtValue:SetText(NOT_APPLICABLE)
                return
            end
            local base = g.baseManaRegen
            base = _floor( base * 5.0 );
            onUpdateBaseStat(frame, base, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.spell
            if not g then return end
            if not _self.BotHasMana(bot) then
                return
            end

            local base = g.baseManaRegen
            local casting = g.castingManaRegen
            -- All mana regen stats are displayed as mana/5 sec.
            base = _floor( base * 5.0 );
            casting = _floor( casting * 5.0 );

            tooltip:AddLine(MANA_REGEN, 1,1,1)
            tooltip:AddLine(_format(MANA_REGEN_TOOLTIP, base, casting))
        end
    },
    ["DEFENSE"] = {
        name = DEFENSE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            if not g then return end
            local base = g.baseDefense
            local modifier = g.modifierDefense
            local posBuff = 0;
            local negBuff = 0;

            if ( modifier > 0 ) then
                posBuff = modifier;
            elseif ( modifier < 0 ) then
                negBuff = modifier;
            end

            onUpdateBaseStat(frame, base+modifier, posBuff, negBuff)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.defenses
            if not g then return end

            local base = g.baseDefense
            local modifier = g.modifierDefense
	        local defensePercent = GetDodgeBlockParryChanceFromDefense(base, modifier, bot.level)
            local posBuff = 0;
            local negBuff = 0;
            if ( modifier > 0 ) then
                posBuff = modifier;
            elseif ( modifier < 0 ) then
                negBuff = modifier;
            end
            onTooltipBaseStat(tooltip, DEFENSE, base+modifier, posBuff, negBuff)
            tooltip:AddLine(_format(DEFAULT_STATDEFENSE_TOOLTIP, g.defenseRating, g.defenseRatingBonus, defensePercent, defensePercent))
        end
    },
    ["DODGE"] = {
        name = STAT_DODGE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            if not g then return end
            onUpdateBaseStat(frame, g.dodgeChance, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.defenses
            if not g then return end

            onTooltipBaseStat(tooltip, _format(PAPERDOLLFRAME_TOOLTIP_FORMAT, DODGE_CHANCE), g.dodgeChance, 0, 0)
            tooltip:AddLine(_format(CR_DODGE_TOOLTIP, g.dodgeRating, g.dodgeRatingBonus))
        end
    },
    ["PARRY"] = {
        name = STAT_PARRY,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            if not g then return end
            onUpdateBaseStat(frame, g.parryChance, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.defenses
            if not g then return end

            onTooltipBaseStat(tooltip, format(PAPERDOLLFRAME_TOOLTIP_FORMAT, PARRY_CHANCE), g.parryChance, 0, 0)
            tooltip:AddLine(_format(CR_PARRY_TOOLTIP, g.parryRating, g.parryRatingBonus))
        end
    },
    ["BLOCK"] = {
        name = STAT_BLOCK,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            if not g then return end
            onUpdateBaseStat(frame, g.parryChance, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.defenses
            if not g then return end

            onTooltipBaseStat(tooltip, format(PAPERDOLLFRAME_TOOLTIP_FORMAT, BLOCK_CHANCE), g.blockChance, 0, 0)
            tooltip:AddLine(_format(CR_BLOCK_TOOLTIP, g.blockRating, g.blockRatingBonus, g.shieldBlock))
        end
    },
    ["RESILIENCE"] = {
        name = STAT_RESILIENCE,
        onUpdateValue = function (frame, bot, botstats)
            local g = botstats.defenses
            if not g then return end

            local melee = g.meleeResil
            local ranged = g.rangedResil
            local spell = g.spellResil
            local minResilience = _min(melee, ranged)
            minResilience = _min(minResilience, spell)
            onUpdateBaseStat(frame, minResilience, 0, 0)
        end,
        onTooltip = function (self, bot, botstats, tooltip)
            local g = botstats.defenses
            if not g then return end

            local melee = g.meleeResil
            local ranged = g.rangedResil
            local spell = g.spellResil
            local meleeBonus = g.meleeResilBonus
            local rangedBonus = g.rangedResilBonus
            local spellBonus = g.spellResilBonus

            local minResilience = _min(melee, ranged)
            minResilience = _min(minResilience, spell)

            local lowestRating = CR_CRIT_TAKEN_MELEE;
            local lowestRatingBonus = 0
            if ( melee == minResilience ) then
                lowestRating = CR_CRIT_TAKEN_MELEE;
                lowestRatingBonus = meleeBonus
            elseif ( ranged == minResilience ) then
                lowestRating = CR_CRIT_TAKEN_RANGED
                lowestRatingBonus = rangedBonus
            else
                lowestRating = CR_CRIT_TAKEN_SPELL
                lowestRatingBonus = spellBonus
            end

	        local maxRatingBonus = GetMaxCombatRatingBonus(lowestRating)

            onTooltipBaseStat(tooltip, _format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_RESILIENCE), minResilience, 0, 0)
            tooltip:AddLine(_format(RESILIENCE_TOOLTIP, lowestRatingBonus, _min(lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_DAMAGE_REDUCTION_MULTIPLIER, maxRatingBonus), lowestRatingBonus * RESILIENCE_CRIT_CHANCE_TO_CONSTANT_DAMAGE_REDUCTION_MULTIPLIER))
        end
    },
}