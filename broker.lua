-- this handles communication between bots and data structures / events
PlayerbotsBroker = {}

local _self = PlayerbotsBroker
local _util = PlayerbotsPanel.Util
local _updateHandler = PlayerbotsPanel.UpdateHandler
local _debug = PlayerbotsPanel.Debug
local _cfg = PlayerbotsPanel.Config

local _bots = {}
local _prefixCode = "pb8aj2" -- just something unique from other addons
-- Stores queues per query type, per bot
-- _queries[botName][QUERY_TYPE]
local _queries = {}
-- optimization, duplicates references to queries in _queries but accelerates lookup by int
local _activeQueriesById = {}
local _botStatus = {}
local _freeIdsStack = {}
local _freeIdsCount = 0
local _activeIdsCount = 0
local queryTemplates = {}
local MAX_IDS_COUNT = 999
local HEADER_LENGHT = 8
local MAX_PAYLOAD_LENGTH = 255 - HEADER_LENGHT -- header length is 8

-- ============================================================================================
-- ============== PUBLIC API
-- ============================================================================================

_self.EVENTS = {}
local _EVENTS = _self.EVENTS
-- UPDATED_STATUS (bot, status) 
_EVENTS.STATUS_CHANGED = _util.CreateEvent()

_EVENTS.STATS_CHANGED = _util.CreateEvent()
_EVENTS.STATS_CHANGED_BASE = _util.CreateEvent()
_EVENTS.STATS_CHANGED_RESISTS = _util.CreateEvent()
_EVENTS.STATS_CHANGED_MELEE = _util.CreateEvent()
_EVENTS.STATS_CHANGED_RANGED = _util.CreateEvent()
_EVENTS.STATS_CHANGED_SPELL = _util.CreateEvent()
_EVENTS.STATS_CHANGED_DEFENSES = _util.CreateEvent()

_EVENTS.MONEY_CHANGED = _util.CreateEvent()
-- (currencyItemID, count)
_EVENTS.CURRENCY_CHANGED = _util.CreateEvent()
_EVENTS.LEVEL_CHANGED = _util.CreateEvent()
_EVENTS.EXPERIENCE_CHANGED = _util.CreateEvent()
_EVENTS.SPEC_DATA_CHANGED = _util.CreateEvent()
_EVENTS.ZONE_CHANGED = _util.CreateEvent()
-- UPDATED_EQUIP_SLOT (bot, slotNum)            // bot equips a single item
_EVENTS.EQUIP_SLOT_CHANGED = _util.CreateEvent()
-- UPDATED_EQUIPMENT (bot)                      // full equipment update completed
_EVENTS.EQUIPMENT_CHANGED = _util.CreateEvent()
 -- full bags update 
_EVENTS.INVENTORY_CHANGED = _util.CreateEvent()

-- ============================================================================================
-- ============== Locals optimization, use in hotpaths
-- ============================================================================================

local _strbyte = string.byte
local _strchar = string.char
local _strsplit = strsplit
local _strsub = string.sub
local _strlen = string.len
local _tonumber = tonumber
local _strformat = string.format
local _pairs = pairs
local _tinsert = table.insert
local _tremove = table.remove
local _tconcat = table.concat
local _getn = getn
local _sendAddonMsg = SendAddonMessage
local _pow = math.pow
local _floor = math.floor
local _eval = _util.CompareAndReturn
local _wipe = wipe

local _evalEmptyString = function (val)
    if val == nil then
        return ""
    else
        return val
    end
end

-- ============================================================================================
-- SHARED BETWEEN EMU/BROKER

local MSG_SEPARATOR = ":"
local MSG_SEPARATOR_BYTE      = _strbyte(":")
local FLOAT_DOT_BYTE          =  _strbyte(".")
local BYTE_ZERO               = _strbyte("0")
local BYTE_MINUS              = _strbyte("-")
local BYTE_NULL_LINK          = _strbyte("~")
local MSG_HEADER = {}
local NULL_LINK = "~"
local UTF8_NUM_FIRST          = _strbyte("1") -- 49
local UTF8_NUM_LAST           = _strbyte("9") -- 57

MSG_HEADER.SYSTEM =             _strbyte("s")
MSG_HEADER.REPORT =             _strbyte("r")
MSG_HEADER.QUERY =              _strbyte("q")
MSG_HEADER.COMMAND =            _strbyte("c")

PlayerbotsBrokerReportType = {}
local REPORT_TYPE = PlayerbotsBrokerReportType
REPORT_TYPE.ITEM_EQUIPPED =     _strbyte("g") -- gear item equipped or unequipped
REPORT_TYPE.CURRENCY =          _strbyte("c") -- currency changed
REPORT_TYPE.INVENTORY =         _strbyte("i") -- inventory changed (bag changed, item added / removed / destroyed)
REPORT_TYPE.TALENTS =           _strbyte("t") -- talent learned / spec changed / talents reset
REPORT_TYPE.SPELLS =            _strbyte("s") -- spell learned
REPORT_TYPE.QUEST =             _strbyte("q") -- single quest accepted, abandoned, changed, completed
REPORT_TYPE.EXPERIENCE =        _strbyte("e") -- level, experience
REPORT_TYPE.STATS =             _strbyte("S") -- all stats and combat ratings

local SYS_MSG_TYPE = {}
SYS_MSG_TYPE.HANDSHAKE =        _strbyte("h")
SYS_MSG_TYPE.PING =             _strbyte("p")
SYS_MSG_TYPE.LOGOUT =           _strbyte("l")

PlayerbotsBrokerQueryType = {}
local QUERY_TYPE = PlayerbotsBrokerQueryType
QUERY_TYPE.WHO        =         _strbyte("w") -- level, class, spec, location, experience and more
QUERY_TYPE.CURRENCY   =         _strbyte("c") -- money, honor, tokens
QUERY_TYPE.CURRENCY_MONEY=      _strbyte("g") -- subtype: money
QUERY_TYPE.CURRENCY_OTHER=      _strbyte("c") -- subtype: other currency (with id)
QUERY_TYPE.GEAR       =         _strbyte("g") -- only what is equipped
QUERY_TYPE.INVENTORY  =         _strbyte("i") -- whats in the bags and bags themselves
QUERY_TYPE.TALENTS    =         _strbyte("t") -- talents and talent points 
QUERY_TYPE.SPELLS     =         _strbyte("s") -- spellbook
QUERY_TYPE.QUESTS     =         _strbyte("q") -- all quests
QUERY_TYPE.STRATEGIES =         _strbyte("S")
QUERY_TYPE.STATS      =         _strbyte("T") -- all stats
--[[ Stats are grouped and sent together 
    subtypes:
        b - base + resists
        m - melee
        r - ranged
        s - spell
        d - defenses
]] 
QUERY_TYPE.STATS_BASE     =         _strbyte("b") -- all stats
QUERY_TYPE.STATS_MELEE    =         _strbyte("m") -- all stats
QUERY_TYPE.STATS_RANGED   =         _strbyte("r") -- all stats
QUERY_TYPE.STATS_SPELL    =         _strbyte("s") -- all stats
QUERY_TYPE.STATS_DEFENSES =         _strbyte("d") -- all stats

PlayerbotsBrokerQueryOpcode = {}
local QUERY_OPCODE = PlayerbotsBrokerQueryOpcode
QUERY_OPCODE.PROGRESS =         _strbyte("p") -- query is in progress
QUERY_OPCODE.FINAL    =         _strbyte("f") -- final message of the query, contains the final payload, and closes query
-- bytes 49 - 57 are errors

PlayerbotsBrokerCommandType = {}
local COMMAND = PlayerbotsBrokerCommandType
COMMAND.STATE        =          _strbyte("s")
--[[ 
    subtypes:
        s - stay
        f - follow
        g - grind
        F - flee
        r - runaway (kite mob)
        l - leave party
]] 
COMMAND.ITEM          =         _strbyte("i")
COMMAND.ITEM_EQUIP    =         _strbyte("e")
COMMAND.ITEM_UNEQUIP  =         _strbyte("u")
COMMAND.ITEM_USE      =         _strbyte("U")
COMMAND.ITEM_USE_ON   =         _strbyte("t")
COMMAND.ITEM_DESTROY  =         _strbyte("d")
COMMAND.ITEM_SELL     =         _strbyte("s")
COMMAND.ITEM_SELL_JUNK=         _strbyte("j")
COMMAND.ITEM_BUY      =         _strbyte("b")
--[[ 
    subtypes:
        e - equip
        u - unequip
        U - use
        t - use on target
        d - destroy
        s - sell
        j - sell junk
        b - buy
]] 
COMMAND.GIVE_GOLD     =         _strbyte("g")
COMMAND.BANK          =         _strbyte("b")
--[[ 
    subtypes:
        d - bank deposit
        w - bank withdraw
        D - guild bank deposit 
        W - guild bank withdraw
]]
COMMAND.QUEST          =         _strbyte("b")
--[[ 
    subtypes:
        a - accept quest
        A - accept all
        d - drop quest
        r - choose reward item
        t - talk to quest npc
        u - use game object (use los query to obtain the game object link)
]]
COMMAND.MISC           =         _strbyte("m")
--[[ 
    subtypes:
        t - learn from trainer
        c - cast spell
        h - set home at innkeeper
        r - release spirit when dead
        R - revive when near spirit healer
        s - summon
]]


-- ============================================================================================
-- PARSER 

-- This is a forward parser, call next..() functions to get value of type required by the msg
-- If the payload is null, the parser is considered broken and functions will return default non null values
local _parser = {
    separator = MSG_SEPARATOR_BYTE,
    dotbyte = FLOAT_DOT_BYTE,
    buffer = {}
}

local BYTE_LINK_SEP = _strbyte("|")
local BYTE_LINK_TERMINATOR = _strbyte("r")

_parser.start = function (self, payload)
    if not payload then 
        self.broken = true
        return
    end
    self.payload = payload
    self.len = _strlen(payload)
    self.broken = false
    self.bufferCount = 0
    self.cursor = 1
end
_parser.nextString = function(self)
    if self.broken then
        return "NULL"
    end
    local strbyte = _strbyte
    local strchar = _strchar
    local buffer = self.buffer
    local p = self.payload
    for i = self.cursor, self.len+1 do
        local c = strbyte(p, i)
        if c == nil or c == self.separator then
            local bufferCount = self.bufferCount
            if bufferCount > 0 then
                self.cursor = i + 1
                if buffer[1] == NULL_LINK then
                    self.bufferCount = 0
                    return nil 
                end
                
                local result = _tconcat(buffer, nil, 1, bufferCount)
                self.bufferCount = 0
                return result
            else
                return nil
            end
        else
            self.cursor = i
            local bufferCount = self.bufferCount + 1
            self.bufferCount = bufferCount
            buffer[bufferCount] = strchar(c)
        end
    end
end

_parser.stringToEnd = function(self)
    if self.broken then
        return "NULL"
    end
    self.bufferCount = 0
    local p = self.payload
    local c = strbyte(p, self.cursor)
    if c == BYTE_NULL_LINK then
        return nil 
    else
        return _strsub(p, self.cursor)
    end
end

_parser.nextLink = function(self)
    if self.broken then
        return nil
    end
    local strbyte = _strbyte
    local strchar = _strchar
    local buffer = self.buffer
    local p = self.payload
    local start = self.cursor
    local v = false -- validate  the | char
    -- if after the validator proceeds an 'r' then we terminate the link
    for i = self.cursor, self.len+1 do
        local c = strbyte(p, i)
        self.cursor = i
        if v == true then
            if c == BYTE_LINK_TERMINATOR then
                local result = _strsub(p, start, i)
                self.cursor = i + 2 -- as we dont end on separator we jump 1 ahead
                return result
            else
                v = false
            end
        end

        if c == BYTE_LINK_SEP then
            v = true
        end

        if c == NULL_LINK then
            self.cursor = i + 1
            return nil
        end

        if c == nil then
            -- we reached the end of payload but didnt close the link, the link is either not a link or invalid
            -- return null?
            return nil
        end
    end
end

_parser.nextInt = function(self)
    if self.broken then
        return 0
    end
    local buffer = self.buffer
    local p = self.payload
    local strbyte = _strbyte
    local pow = _pow
    local floor = _floor
    for i = self.cursor, self.len + 1 do
        local c = strbyte(p, i)
        if c == nil or c == self.separator then
            local bufferCount = self.bufferCount
            if bufferCount > 0 then
                self.cursor = i + 1
                local result = 0
                local sign = 1
                local start = 1
                if buffer[1] == BYTE_MINUS then
                    sign = -1
                    start = 2
                end
                for t= start, bufferCount do
                    result = result + ((buffer[t]-48)*pow(10, bufferCount - t))
                end
                result = result * sign
                self.bufferCount = 0
                return floor(result)
            end
        else
            self.cursor = i
            local bufferCount = self.bufferCount + 1
            self.bufferCount = bufferCount
            buffer[bufferCount] = c
        end
    end
end
_parser.nextFloat = function(self)
    if self.broken then
        return 0.0
    end
    local tobyte = string.byte
    local buffer = self.buffer
    local p = self.payload
    local pow = _pow
    for i = self.cursor, self.len + 1 do
        local c = tobyte(p, i)
        if c == nil or c == self.separator then
            local bufferCount = self.bufferCount
            if bufferCount > 0 then
                self.cursor = i + 1
                local result = 0
                local dotPos = -1
                local sign = 1
                local start = 1
                if buffer[1] == BYTE_MINUS then
                    sign = -1
                    start = 2
                end
                -- find dot
                for t=1, bufferCount do
                    if buffer[t] == self.dotbyte then
                        dotPos = t
                        break
                    end
                end
                -- if no dot, use simplified int algo
                if dotPos == -1 then
                    for t=start, bufferCount do
                        result = result + ((buffer[t]-48)*pow(10, bufferCount - t))
                    end
                    result = result * sign
                    self.bufferCount = 0
                    return result -- still returns a float because of pow
                else
                    for t=start, dotPos-1 do -- int
                        result = result + ((buffer[t]-48)*pow(10, dotPos - t - 1))
                    end
                    for t=dotPos+1, bufferCount do -- decimal
                        result = result + ((buffer[t]-48)* pow(10, (t-dotPos) * -1))
                    end
                    result = result * sign
                    self.bufferCount = 0
                    return result
                end
            end
        else
            self.cursor = i
            local bufferCount = self.bufferCount + 1
            self.bufferCount = bufferCount
            buffer[bufferCount] = c
        end
    end
end
_parser.nextBool = function (self)
    if self.broken then
        return false
    end
    local strbyte = _strbyte
    local strchar = _strchar
    local buffer = self.buffer
    local p = self.payload
    for i = self.cursor, self.len+1 do
        local c = strbyte(p, i)
        if c == nil or c == self.separator then
            if self.bufferCount > 0 then
                self.cursor = i + 1
                self.bufferCount = 0
                if buffer[1] == BYTE_ZERO then
                    return false
                else
                    return true
                end
            else
                return nil
            end
        else
            self.cursor = i
            local bufferCount = self.bufferCount + 1
            self.bufferCount = bufferCount
            buffer[bufferCount] = c
        end
    end
end

_parser.nextChar = function (self)
    if self.broken then
        return false
    end
    local strbyte = _strbyte
    local strchar = _strchar
    local p = self.payload
    local result = nil
    for i = self.cursor, self.len+1 do
        local c = strbyte(p, i)
        if c == nil or c == self.separator then
            self.cursor = i + 1
            self.bufferCount = 0
            return result
        else
            self.cursor = i
            if not result then
                result = strchar(c)
            end
        end
    end
end

_parser.nextCharAsByte = function (self)
---@diagnostic disable-next-line: param-type-mismatch
    return _strbyte(self:nextChar())
end

_parser.validateLink = function(link)
    if link == nil then return false end
    local l = _strlen(link)
    local v1 = _strbyte(link, l) == BYTE_LINK_TERMINATOR
    local v2 = _strbyte(link, l-1) == BYTE_LINK_SEP
    return v1 and v2
end

-----------------------------------------------------------------------------
----- PARSER END / SHARED REGION END
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
----- QUERIES START
----- QUERIES START
----- QUERIES START
----- QUERIES START
----- QUERIES START
-----------------------------------------------------------------------------

-- pay attention not to capture anything in functions
queryTemplates[QUERY_TYPE.WHO] = 
{
    qtype = QUERY_TYPE.WHO,
    onStart          = function(query)
    end,
    onProgress       = function(query, payload)
        -- CLASS(token):LEVEL(1-80):SECOND_SPEC_UNLOCKED(0-1):ACTIVE_SPEC(1-2):POINTS1:POINTS2:POINTS3:POINTS4:POINTS5:POINTS6:FLOAT_EXP:LOCATION
        -- PALADIN:65:1:1:5:10:31:40:5:10:0.89:Blasted Lands 
        _parser:start(payload)
        local class = _parser:nextString()
        local level = _parser:nextInt()
        local secondSpecUnlocked = _parser:nextBool()
        local activeSpec = _parser:nextInt()
        local points1 = _parser:nextInt()
        local points2 = _parser:nextInt()
        local points3 = _parser:nextInt()
        local points4 = _parser:nextInt()
        local points5 = _parser:nextInt()
        local points6 = _parser:nextInt()
        local expLeft = _parser:nextFloat()
        local zone = _parser:nextString()
        if not _parser.broken then 
            -- this code is very verbose, but it is the most optimized way, think of it as inlining
            local bot = query.bot
            local botname = bot.name

            bot.class = class

            local changed_level = false
            local changed_spec_data = false
            local changed_exp = false
            local changed_zone = false

            local function evalChange(newval, obj, oldval)
                if newval ~= obj[oldval] then
                    obj[oldval] = newval
                    return true
                end
            end

            changed_level = evalChange(level, bot, "level")
            changed_spec_data = evalChange(secondSpecUnlocked, bot.talents, "dualSpecUnlocked")
            changed_spec_data = evalChange(activeSpec, bot.talents, "activeSpec")

            local spec1 = bot.talents.specs[1]
            local spec1tabs = spec1.tabs
            local p1 = 1
            if points2 > points1 then p1 = 2 end
            if points3 > points2 then p1 = 3 end
            
            changed_spec_data = evalChange(p1, spec1, "primary")
            changed_spec_data = evalChange(points1, spec1tabs[1], "points")
            changed_spec_data = evalChange(points2, spec1tabs[2], "points")
            changed_spec_data = evalChange(points3, spec1tabs[3], "points")

            local spec2 = bot.talents.specs[2]
            local spec2tabs = spec2.tabs
            local p2 = 1
            if points5 > points4 then p2 = 2 end
            if points6 > points5 then p2 = 3 end

            changed_spec_data = evalChange(p2, spec2, "primary")
            changed_spec_data = evalChange(points4, spec2tabs[1], "points")
            changed_spec_data = evalChange(points5, spec2tabs[2], "points")
            changed_spec_data = evalChange(points6, spec2tabs[3], "points")

            changed_exp = evalChange(expLeft, bot, "expLeft")
            
            changed_zone = evalChange(zone, bot, "zone")

            if changed_level then _EVENTS.LEVEL_CHANGED:Invoke(bot) end
            if changed_exp then _EVENTS.EXPERIENCE_CHANGED:Invoke(bot) end
            if changed_zone then _EVENTS.ZONE_CHANGED:Invoke(bot) end
            if changed_spec_data then _EVENTS.SPEC_DATA_CHANGED:Invoke(bot) end
        end
    end,
    onFinalize       = function(query) end,
}

queryTemplates[QUERY_TYPE.CURRENCY] = 
{
    qtype = QUERY_TYPE.CURRENCY,
    onStart          = function(query)

    end,
    onProgress       = function(query, payload)
        _parser:start(payload)
        local subtype = _parser:nextCharAsByte()
        local botCurrencies = query.bot.currency
        if subtype == QUERY_TYPE.CURRENCY_MONEY then
            local gold = _parser:nextInt()
            botCurrencies.gold = gold
            local silver = _parser:nextInt()
            botCurrencies.silver = silver
            local copper = _parser:nextInt()
            botCurrencies.copper = copper
            _EVENTS.MONEY_CHANGED:Invoke(query.bot, gold, silver, copper)
        elseif subtype == QUERY_TYPE.CURRENCY_OTHER then
            local currencyId = _parser:nextInt()
            local count = _parser:nextInt()
            local currency = botCurrencies[currencyId]
            if not currency then
                currency = {
                    itemId = currencyId,
                    count = count
                }
                botCurrencies[currencyId] = currency
            end
            _EVENTS.CURRENCY_CHANGED:Invoke(query.bot, currencyId, count)
        end
    end,
    onFinalize       = function(query)
    end,
}

queryTemplates[QUERY_TYPE.STATS] = 
{
    qtype = QUERY_TYPE.STATS,
    onStart          = function(query)

    end,
    onProgress       = function(query, payload)
        _parser:start(payload)
        local bot = query.bot
        local stats = bot.stats
        local subtype = _parser:nextCharAsByte()

        local c_base = false
        local c_resists = false
        local c_melee = false
        local c_ranged = false
        local c_spell = false
        local c_defenses = false

        local function evalChange(change, newval, obj, oldvalKey)
            if newval ~= obj[oldvalKey] then
                obj[oldvalKey] = newval
                return true
            else
                return change
            end
        end

        if subtype == QUERY_TYPE.STATS_BASE then
            local stats_base = stats.base
            local stats_res = stats.resists
            for i=1, 5 do -- loop basic stats
                --[[
                    index corresponds to blizzard index
                      1  Agility
                      2  Intellect
                      3  Spirit
                      4  Stamina
                      5  Strength
                ]]
                -- format > value : effectiveStat : positive : negative
                local statData = stats_base[i]
                c_base = evalChange(c_base, _parser:nextInt(), statData, "effectiveStat")
                c_base = evalChange(c_base, _parser:nextInt(), statData, "positive")
                c_base = evalChange(c_base, _parser:nextInt(), statData, "negative")

                if i == 1 then -- STRENGTH
                    c_base = evalChange(c_base,_parser:nextInt(), statData, "attackPower")
                elseif i == 2 then -- AGILITY
                    c_base = evalChange(c_base,_parser:nextInt(), statData, "attackPower")
                    c_base = evalChange(c_base,_parser:nextFloat(), statData, "agilityCritChance")
                elseif i == 3 then -- STAMINA
                    c_base = evalChange(c_base,_parser:nextInt(), statData, "maxHpModifier")
                elseif i == 4 then
                    c_base = evalChange(c_base,_parser:nextFloat(), statData, "intellectCritChance")
                elseif i == 5 then -- spirit
                    c_base = evalChange(c_base,_parser:nextInt(), statData, "healthRegenFromSpirit")
                    c_base = evalChange(c_base,_parser:nextFloat(), statData, "manaRegenFromSpirit")
                end
            end
            
            for i=1, 5 do -- loop resists
                --[[
                    1 - Arcane
                    2 - Fire
                    3 - Nature
                    4 - Frost
                    5 - Shadow
                ]]
                -- format > base : resistance : positive : negative

                local statData = stats_res[i]
                c_resists = evalChange(c_resists,_parser:nextInt(), statData, "resistance")
                c_resists = evalChange(c_resists,_parser:nextInt(), statData, "positive")
                c_resists = evalChange(c_resists,_parser:nextInt(), statData, "negative")
            end



        elseif subtype == QUERY_TYPE.STATS_MELEE then
            local melee = stats.melee

            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "minMeleeDamage")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "maxMeleeDamage")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "minMeleeOffHandDamage")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "maxMeleeOffHandDamage")
            c_melee = evalChange(c_melee, _parser:nextInt(), melee, "meleePhysicalBonusPositive")
            c_melee = evalChange(c_melee, _parser:nextInt(), melee, "meleePhysicalBonusNegative")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "meleeDamageBuffPercent")

            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeSpeed")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeOffhandSpeed")

            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeAtkPowerBase")
            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeAtkPowerPositive")
            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeAtkPowerNegative")

            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeHaste")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeHasteBonus")

            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeCritRating")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeCritRatingBonus")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeCritChance")

            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "meleeHit")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "meleeHitBonus")

            c_melee = evalChange(c_melee,_parser:nextInt(), melee, "armorPen")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "armorPenPercent")
            c_melee = evalChange(c_melee,_parser:nextFloat(), melee, "armorPenBonus")

            c_melee = evalChange(c_melee, _parser:nextInt(), melee, "expertise")
            c_melee = evalChange(c_melee, _parser:nextInt(), melee, "offhandExpertise")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "expertisePercent")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "expertiseOffhandPercent")
            c_melee = evalChange(c_melee, _parser:nextInt(), melee, "expertiseRating")
            c_melee = evalChange(c_melee, _parser:nextFloat(), melee, "expertiseRatingBonus")
        elseif subtype == QUERY_TYPE.STATS_RANGED then
            local ranged = stats.ranged

            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedAttackSpeed")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedMinDamage")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedMaxDamage")
            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedPhysicalBonusPositive")
            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedPhysicalBonusNegative")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedDamageBuffPercent")

            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedAttackPower")
            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedAttackPowerPositive")
            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedAttackPowerNegative")

            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedHaste")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedHasteBonus")

            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedCritRating")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedCritRatingBonus")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedCritChance")

            c_ranged = evalChange(c_ranged, _parser:nextInt(), ranged, "rangedHit")
            c_ranged = evalChange(c_ranged, _parser:nextFloat(), ranged, "rangedHitBonus")

        elseif subtype == QUERY_TYPE.STATS_SPELL then
            local spell = stats.spell

            for i=2, MAX_SPELL_SCHOOLS do -- skip physical, start at 2
                c_spell = evalChange(c_spell, _parser:nextInt(), spell.spellBonusDamage, i)
            end
        
            c_spell = evalChange(c_spell, _parser:nextInt(), spell, "spellBonusHealing")
        
            c_spell = evalChange(c_spell, _parser:nextInt(), spell, "spellHit")
            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "spellHitBonus")
            
            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "spellPenetration")

            for i=2, MAX_SPELL_SCHOOLS do -- skip physical, start at 2
                c_spell = evalChange(c_spell, _parser:nextFloat(), spell.spellCritChance, i)
            end
            
            c_spell = evalChange(c_spell, _parser:nextInt(), spell, "spellCritRating")
            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "spellCritRatingBonus")

            c_spell = evalChange(c_spell, _parser:nextInt(), spell, "spellHaste")
            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "spellHasteBonus")

            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "baseManaRegen")
            c_spell = evalChange(c_spell, _parser:nextFloat(), spell, "castingManaRegen")
        elseif subtype == QUERY_TYPE.STATS_DEFENSES then
            local defenses = stats.defenses
            
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "effectiveArmor")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "armorPositive")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "armorNegative")

            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "effectivePetArmor")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "armorPetPositive")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "armorPetNegative")

            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "baseDefense")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "modifierDefense")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "defenseRating")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "defenseRatingBonus")

            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "dodgeChance")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "dodgeRating")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "dodgeRatingBonus")

            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "blockChance")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "shieldBlock")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "blockRating")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "blockRatingBonus")

            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "parryChance")
            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "parryRating")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "parryRatingBonus")

            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "meleeResil")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "meleeResilBonus")

            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "rangedResil")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "rangedResilBonus")

            c_defenses = evalChange(c_defenses, _parser:nextInt(), defenses, "spellResil")
            c_defenses = evalChange(c_defenses, _parser:nextFloat(), defenses, "spellResilBonus")
        end
        if c_base then _EVENTS.STATS_CHANGED_BASE:Invoke(bot)  end
        if c_resists then _EVENTS.STATS_CHANGED_RESISTS:Invoke( bot)   end
        if c_melee then _EVENTS.STATS_CHANGED_MELEE:Invoke( bot)   end
        if c_ranged then _EVENTS.STATS_CHANGED_RANGED:Invoke( bot)   end
        if c_spell then _EVENTS.STATS_CHANGED_SPELL:Invoke( bot)   end
        if c_defenses then _EVENTS.STATS_CHANGED_DEFENSES:Invoke( bot)  end

        if c_base or c_defenses or c_melee or c_ranged or c_resists or c_spell then
            _EVENTS.STATS_CHANGED:Invoke(bot)
        end
    end,
    onFinalize       = function(query)
    end,
}

queryTemplates[QUERY_TYPE.GEAR] = 
{
    qtype = QUERY_TYPE.GEAR,
    onStart          = function(query)

    end,
    onProgress       = function(query, payload)
        _parser:start(payload)
        local slot = _parser:nextInt()
        local count = _parser:nextInt()
        local link = _parser:nextLink()
        query.ctx1[slot] = link
        query.ctx2[slot] = count
        query.ctx1.changed = true
    end,
    onFinalize       = function(query)
        if query.ctx1.changed then
            local items = query.bot.items
            for i=1, 19 do
                local link = query.ctx1[i]
                local item = items[i]
                if link then
                    item.link = link
                    item.count = query.ctx2[i]
                else
                    item.link = nil
                    item.count = 0
                end
            end
            _EVENTS.EQUIPMENT_CHANGED:Invoke( query.bot)
        end
    end,
}

queryTemplates[QUERY_TYPE.INVENTORY] = 
{
    qtype = QUERY_TYPE.INVENTORY,
    onStart          = function(query)
        PlayerbotsPanel.InitBag(query.bot.bags[-2], 32, nil) -- keyring
        for i=0, 4 do
            local size = _eval(i == 0, 16, 0)
            PlayerbotsPanel.InitBag(query.bot.bags[i], size, nil)
        end
    end,
    onProgress       = function(query, payload)
        _parser:start(payload)
        local bot = query.bot
        local subtype = _parser:nextChar()
        if subtype == 'b' then
            local bagNum = _parser:nextInt()
            local bagSize = _parser:nextInt()
            local bagLink = _parser:nextLink()

            local bag = bot.bags[bagNum]
            PlayerbotsPanel.InitBag(bag, bagSize, bagLink)
            query.ctx1[bagNum] = true -- track which bags are added by the query
        elseif subtype == 'i' then
            local bagNum = _parser:nextInt()
            local bagSlot = _parser:nextInt()
            local itemCount = _parser:nextInt()
            local itemLink = _parser:nextLink()

            local bag = bot.bags[bagNum]
            PlayerbotsPanel.SetBagItemData(bag, bagSlot, itemCount, itemLink)
        end
    end,
    onFinalize       = function(query)
        _EVENTS.INVENTORY_CHANGED:Invoke(query.bot)
    end,
}

-----------------------------------------------------------------------------
----- QUERIES END
----- QUERIES END
----- QUERIES END
----- QUERIES END
----- QUERIES END
-----------------------------------------------------------------------------

function _self:GetBotStatus(name)
    local status = _botStatus[name]
    if not status then
        status = {}
        status.lastMessageTime = 0.0
        status.lastPing = 0.0
        status.online = false
        status.party = false
        _botStatus[name] = status
    end
    return status
end

local _msgBuffer = {}

-- reuses a single table to construct strings
local function BufferConcat(separator, count, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
    local buffer = _msgBuffer
    buffer[1] = a1
    buffer[2] = separator
    buffer[3] = a2
    buffer[4] = separator
    buffer[5] = a3
    buffer[6] = separator
    buffer[7] = a4
    buffer[8] = separator
    buffer[9] = a5
    if count > 5 then
        buffer[10] = separator
        buffer[11] = a6
        buffer[12] = separator
        buffer[13] = a7
        buffer[14] = separator
        buffer[15] = a8
        buffer[16] = separator
        buffer[17] = a9
        buffer[18] = separator
        buffer[19] = a10
    end
    return _tconcat(buffer, nil, 1, count * 2 - 1)
end

-- ID must be uint16
---comment
---@param target string name of the bot
---@param header number byte header id
---@param subtype number byte subtype
---@param id number id, currently only used by queries
---@param payload string 
function _self:GenerateMessage(target, header, subtype, id, payload)
    if not id then id = 0 end
    local msg = BufferConcat(MSG_SEPARATOR, 4, _strchar(header), _strchar(subtype), _strformat("%03d", id), _eval(payload, payload, ""))
    _sendAddonMsg(_prefixCode, msg, "WHISPER", target)
    _debug:LevelDebug(2, "|cff7afffb >> " .. target .. " |r "..  msg)
end

-- bots - reference to _dbchar.bots
function _self:Init(bots)
    _bots = bots
    _updateHandler:RegisterHandler(_self.OnUpdate)

    for name, bot in _pairs(_bots) do
        local status = _self:GetBotStatus(bot.name)
        status.party = UnitInParty(bot.name) ~= nil
        _self:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function _self:OnEnable()
    for name, bot in _pairs(_bots) do
        _self:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function _self:OnDisable()
    for name, bot in _pairs(_bots) do
        _self:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.LOGOUT)
    end
end

function _self:OnUpdate(elapsed)
    local time = _updateHandler.totalTime

    local closeWindow = _cfg.queryCloseWindow
    for id, query in _pairs(_activeQueriesById) do
        if query ~= nil and query.lastMessageTime ~= nil then
            if query.lastMessageTime  + closeWindow < time then
                _self:FinalizeQuery(query)
            end
        end
    end
end

function _self:StartQuery(qtype, bot)
    if not bot then return end
    local status = _self:GetBotStatus(bot.name)
    if not status.online then return end -- abort query because the bot is either not available or offline

    _debug:LevelDebug(1, "PlayerbotsBroker:StartQuery", "QUERY_TYPE", qtype, "name", bot.name)
    local array = _self:GetQueriesArray(bot.name)
    local query = array[qtype]
    if query then
        return
    end
    query = _self:ConstructQuery(qtype, bot.name)
    if query then
        array[qtype] = query
        _activeQueriesById[query.id] = query
        query:onStart(query)
        _self:GenerateQueryMsg(query, nil)
    end
end

local function RentQueryID()
    local id = 0
    if _freeIdsCount == 0 then
        id = _activeIdsCount + 1
    else
        id = tremove(_freeIdsStack)
        _freeIdsCount = _freeIdsCount - 1
    end
    _activeIdsCount = _activeIdsCount + 1
    return id
end

local function ReleaseQueryID(id)
    _tinsert(_freeIdsStack, id)
    _freeIdsCount = _freeIdsCount + 1
    _activeIdsCount = _activeIdsCount - 1
end

local _queryPool = {}
local _queryPoolCount = 0
function _self:ConstructQuery(qtype, name)
    local template = queryTemplates[qtype]
    if template then
        local bot = PlayerbotsPanel:GetBot(name)
        if not bot then return end
        local query = nil
        if _queryPoolCount > 0 then
            query = _queryPool[_queryPoolCount]
            _queryPool[_queryPoolCount] = nil
            _queryPoolCount = _queryPoolCount - 1
        else
            query = {}
        end

        query.qtype = template.qtype
        query.hasError = false
        query.opcode = QUERY_OPCODE.PROGRESS
        query.bot = bot
        query.botStatus = _self:GetBotStatus(name)
        query.id = RentQueryID()
        query.lastMessageTime = _updateHandler.totalTime
        query.onStart = template.onStart
        query.onProgress = template.onProgress
        query.onFinalize = template.onFinalize
        
        if query.ctx1 == nil then
            query.ctx1 = {} -- context is a table any code can use for any reason that gets wiped when the query returns to the pool
        end

        if query.ctx2 == nil then
            query.ctx2 = {} -- context is a table any code can use for any reason that gets wiped when the query returns to the pool
        end

        if query.ctx3 == nil then
            query.ctx3 = {} -- context is a table any code can use for any reason that gets wiped when the query returns to the pool
        end
        return query
    end
    return nil
end

function _self:FinalizeQuery(query)
    if not query.hasError then
        query:onFinalize(query)
    end

    local queries = _self:GetQueriesArray(query.bot.name)
    queries[query.qtype] = nil
    _activeQueriesById[query.id] = nil
    ReleaseQueryID(query.id)

    wipe(query.ctx1)
    wipe(query.ctx2)
    wipe(query.ctx3)
    _queryPoolCount = _queryPoolCount + 1
    _queryPool[_queryPoolCount] = query
end

function _self:SendWhisper(msg, name)
    SendChatMessage(msg, "WHISPER", nil, name)
end

local SYS_MSG_HANDLERS = {}
SYS_MSG_HANDLERS[SYS_MSG_TYPE.HANDSHAKE] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil
        _EVENTS.STATUS_CHANGED:Invoke( bot, status)
    end
    _self:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.HANDSHAKE)
    _self:StartQuery(QUERY_TYPE.WHO, bot)
    _self:StartQuery(QUERY_TYPE.CURRENCY, bot)
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.PING] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil
        _EVENTS.STATUS_CHANGED:Invoke( bot, status)
    end
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.LOGOUT] = function(id,payload, bot, status)
    if status.online then
        status.online = false
        _EVENTS.STATUS_CHANGED:Invoke( bot, status)
    end
end

local function CompareAndReturn(eval, ifTrue, ifFalse)
    if eval then
        return ifTrue
    else
        return ifFalse
    end
end

local REP_MSG_HANDLERS = {}
REP_MSG_HANDLERS[REPORT_TYPE.ITEM_EQUIPPED] = function(id,payload,bot,status)
    _parser:start(payload)
    local slotNum = _parser:nextInt()
    local countNum = _parser:nextInt()
    local link = _parser:nextLink()
    local item = bot.items[slotNum]
    local changed = false;

    if not item then
        _debug:LevelDebug(1, "Tried to update non existing slot number?")
        return
    end

    local resultLink = _eval(link == NULL_LINK, nil, link)
    if resultLink ~= item.link then
        item.link = resultLink
        changed = true
    end

    if countNum ~= item.count then
        item.count = countNum
        changed = true
    end

    if changed then
        _EVENTS.EQUIP_SLOT_CHANGED:Invoke(  bot, slotNum)
    end
end
REP_MSG_HANDLERS[REPORT_TYPE.EXPERIENCE] = function(id,payload,bot,status) 
    _parser:start(payload)
    bot.level = _parser:nextInt()
    bot.expLeft = _parser:nextFloat()
    _EVENTS.EXPERIENCE_CHANGED:Invoke(  bot)
end
REP_MSG_HANDLERS[REPORT_TYPE.CURRENCY] = function(id,payload,bot,status) 
    _parser:start(payload)
    local subtype = _parser:nextCharAsByte()
    local botCurrencies = bot.currency
    if subtype == QUERY_TYPE.CURRENCY_MONEY then
        local gold = _parser:nextInt()
        botCurrencies.gold = gold
        local silver = _parser:nextInt()
        botCurrencies.silver = silver
        local copper = _parser:nextInt()
        botCurrencies.copper = copper
        _EVENTS.MONEY_CHANGED:Invoke(  bot, gold, silver, copper)
    elseif subtype == QUERY_TYPE.CURRENCY_OTHER then
        local currencyId = _parser:nextInt()
        local count = _parser:nextInt()
        local currency = botCurrencies[currencyId]
        if not currency then
            currency = {
                itemId = currencyId,
                count = count
            }
            botCurrencies[currencyId] = currency
        end
        _EVENTS.CURRENCY_CHANGED:Invoke(  bot, currencyId, count)
    end
end
REP_MSG_HANDLERS[REPORT_TYPE.INVENTORY] = function(id,payload,bot,status) 
    _parser:start(payload)
    local subtype = _parser:nextChar()

    if subtype == 'b' then
        local bagSlot = _parser:nextInt()
        local bagSize = _parser:nextInt()
        local bagLink = _parser:nextLink()
        local bag = bot.bags[bagSlot]
        PlayerbotsPanel.InitBag(bag, bagSize, bagLink)
    elseif subtype == 'i' then
        local bagSlot = _parser:nextInt()
        local itemSlot = _parser:nextInt()
        local itemCount = _parser:nextInt()
        local itemLink = _parser:nextLink()
        local bag = bot.bags[bagSlot]
        PlayerbotsPanel.SetBagItemData(bag, itemSlot, itemCount, itemLink)
    end

    _EVENTS.INVENTORY_CHANGED:Invoke(  bot)
end
REP_MSG_HANDLERS[REPORT_TYPE.TALENTS] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.SPELLS] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.QUEST] = function(id,payload,bot,status) end

local MSG_HANDLERS = {}
MSG_HANDLERS[MSG_HEADER.SYSTEM] = SYS_MSG_HANDLERS
MSG_HANDLERS[MSG_HEADER.REPORT] = REP_MSG_HANDLERS

function _self:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == _prefixCode then 
        local bot = _bots[sender]
        if bot then
            _debug:LevelDebug(2,  "|cffb4ff29 << " .. bot.name .. " |r " .. message)
            local status = _self:GetBotStatus(bot.name)
            if not status then return end
            status.lastMessageTime = _updateHandler.totalTime
            -- confirm that the message has valid format
            local header, sep1, subtype, sep2, idb1, idb2, idb3, sep3 = _strbyte(message, 1, 8)
            local _separatorByte = MSG_SEPARATOR_BYTE
            -- BYTES
            -- 1 [HEADER] 2 [SEPARATOR] 3 [SUBTYPE/QUERY_OPCODE] 4 [SEPARATOR] 5-6-7 [ID] 8 [SEPARATOR] 9 [PAYLOAD]
            -- s:p:999:payload
            if sep1 == _separatorByte and sep2 == _separatorByte and sep3 == _separatorByte then
                -- first determine if its an ongoing query response
                -- if it is we treat it differently, because format is differnt
                -- instead of subtype the bit3 carries error code 0-9, 0 == no error
                if header == MSG_HEADER.QUERY then
                    -- idb contains UTF8 0-9, so bytes 49-57, we offset them by 48, and mult by mag
                    local id = ((idb1-48) * 100) + ((idb2-48) * 10) + (idb3-48) 
                    local query = _activeQueriesById[id]
                    if query then
                        query.opcode = subtype -- grab the opcode, it can be (p), (f), (1-9), more later possible
                        if subtype == QUERY_OPCODE.PROGRESS then
                            local payload = _strsub(message, 9)
                            query.onProgress(query, payload)
                        elseif subtype == QUERY_OPCODE.FINAL then
                            local payload = _strsub(message, 9)
                            if payload and _strlen(payload) > 0 then
                                query.onProgress(query, payload)
                            end
                            _self:FinalizeQuery(query)
                        elseif subtype >= UTF8_NUM_FIRST and subtype <= UTF8_NUM_LAST then
                            query.hasError = true
                            _debug:LevelDebug(1, "Query:", query.id, " returned an error: ", query.opcode)
                            _self:FinalizeQuery(query)
                        end
                    end
                else
                    local handlers = MSG_HANDLERS[header]
                    if handlers then
                        local handler = handlers[subtype]
                        if handler then
                            local id = ((idb1-48) * 100) + ((idb2-48) * 10) + (idb3-48)
                            local payload = _strsub(message, 9)
                            handler(id, payload, bot, status)
                        end
                    end
                end
            end
        end
    end
end

function _self:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
end

-- for now the queue only allows a single query of one type to be ran at a time
function _self:GetQueriesArray(name)
    if not name then
        _debug:LevelDebug(2, "PlayerbotsBroker:GetQueries", "name is nil")
    end
    local array = _queries[name]
    if not array then
        array = {}
        _queries[name] = array
    end
    return array
end

function _self:GenerateCommand(bot, cmd, subcmd, arg1, arg2, arg3)
    local count = 1
    if arg1 then count = count + 1 end
    if arg2 then count = count + 1 end
    if arg3 then count = count + 1 end
    local payload = BufferConcat(MSG_SEPARATOR, count, _strchar(subcmd), arg1, arg2, arg3)
    _self:GenerateMessage(bot.name, MSG_HEADER.COMMAND, cmd, 0, payload)
end

function _self:GenerateQueryMsg(query, payload)
    _self:GenerateMessage(query.bot.name, MSG_HEADER.QUERY, query.qtype, query.id, payload)
end

function _self:DoHandshakeAfterRegistration(name)
    local bot = PlayerbotsPanel:GetBot(name)
    if bot then
        _self:GenerateMessage(name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.HANDSHAKE)
        _self:GenerateMessage(name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
        _updateHandler:DelayCall(1, function ()
            _self:StartQuery(QUERY_TYPE.WHO, bot)
        end)
    end
end

function _self:PARTY_MEMBERS_CHANGED()
    for name, bot in pairs(_bots) do
        local status = _self:GetBotStatus(name)
        local inparty =  UnitInParty(name) ~= nil
        if inparty ~= status.party then
            status.party = inparty
            _EVENTS.STATUS_CHANGED:Invoke( bot, status)
        end
    end
end

function _self:PARTY_MEMBER_ENABLE()

end

function _self:PARTY_MEMBER_DISABLE(id)
    print(id)
end

function _self:DebugMaxLengthMsg()
    local buffer = {}
    for i=1, MAX_PAYLOAD_LENGTH do
        _tinsert(buffer, _strchar(random(49, 59)))
    end
    _self:GenerateMessage(PlayerbotsPanel.selectedBot.name, 55, 55, 0, _tconcat(buffer))
end


