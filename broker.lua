-- this handles communication between bots and data structures / events
PlayerbotsBroker = {}
local _broker = PlayerbotsBroker
local _updateHandler = PlayerbotsPanelUpdateHandler
local _util = PlayerbotsPanelUtil
local _bots = {}
local _debug = AceLibrary:GetInstance("AceDebug-2.0")
local _cfg = PlayerbotsPanelConfig
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



-- ============================================================================================
-- ============== PUBLIC API
-- ============================================================================================

PlayerbotsBrokerCallbackType = {}
local CALLBACK_TYPE = PlayerbotsBrokerCallbackType
local _callbacks = {} -- callbacks PER bot
local _globalCallbacks = {} -- callbacks called for ANY bot

-- UPDATED_STATUS (bot, status)                 // Online/offline/party
CALLBACK_TYPE.STATUS_CHANGED = {}
-- UPDATED_STATUS (bot, status)                 // Class, Spec, Level, Experience, Location, 
CALLBACK_TYPE.LEVEL_CHANGED = {}
CALLBACK_TYPE.EXPERIENCE_CHANGED = {}
CALLBACK_TYPE.SPEC_DATA_CHANGED = {}
CALLBACK_TYPE.ZONE_CHANGED = {}
-- UPDATED_EQUIP_SLOT (bot, slotNum)            // bot equips a single item
CALLBACK_TYPE.EQUIP_SLOT_CHANGED = {}
-- UPDATED_EQUIPMENT (bot)                      // full equipment update completed
CALLBACK_TYPE.EQUIPMENT_CHANGED = {}

CALLBACK_TYPE.INVENTORY_CHANGED = {} -- // full bags update 


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
QUERY_TYPE.GEAR       =         _strbyte("g") -- only what is equipped
QUERY_TYPE.INVENTORY  =         _strbyte("i") -- whats in the bags and bags themselves
QUERY_TYPE.TALENTS    =         _strbyte("t") -- talents and talent points 
QUERY_TYPE.SPELLS     =         _strbyte("s") -- spellbook
QUERY_TYPE.QUESTS     =         _strbyte("q") -- all quests
QUERY_TYPE.STRATEGIES =         _strbyte("S")

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

-- This is a forward parser, call next..() methods to get value of type required by the msg
-- If the payload is null, the parser is considered broken and methods will return default non null values
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

local function GetCallbackArray(ctype, name)
    local cbs = _callbacks[name]
    if not cbs then
        cbs = {}
        _callbacks[name] = cbs
    end

    local array = cbs[ctype]
    if not array then
        array = {}
        cbs[ctype] = array
    end
    return array
end

local function GetGlobalCallbackArray(ctype)
    local array = _globalCallbacks[ctype]
    if not array then
        array = {}
        _globalCallbacks[ctype] = array
    end
    return array
end

function PlayerbotsBroker:RegisterGlobalCallback(ctype, callback)
    if not ctype then return end
    if not callback then return end
    local array = GetGlobalCallbackArray(ctype)
    _tinsert(array, callback)
end

function PlayerbotsBroker:UnregisterGlobalCallback(ctype, callback)
    if not ctype then return end
    if not callback then return end
    local array = GetGlobalCallbackArray(ctype)
    local idx = _util.FindIndex(array, callback)
    if idx > 0 then
        _tremove(array, idx)
    end
end

function PlayerbotsBroker:RegisterCallback(ctype, botName, callback)
    if not ctype then return end
    if not botName then return end
    if not callback then return end
    
    local array = GetCallbackArray(ctype, botName)
    _tinsert(array, callback)
end

function PlayerbotsBroker:UnegisterCallback(ctype, botName, callback)
    if not ctype then return end
    if not botName then return end
    if not callback then return end
    local array = GetCallbackArray(ctype, botName)
    local idx = _util.FindIndex(array, callback)
    if idx > 0 then
        _tremove(array, idx)
    end
end

local function InvokeCallback(ctype, bot, arg1, arg2, arg3, arg4)
    if not ctype then return end
    if not bot then return end

    local name = bot.name
    local array = GetCallbackArray(ctype, name)
    local count = _getn(array)
    for i=1, count do
        local callback = array[i]
        if callback then
            callback(bot, arg1, arg2, arg3, arg4)
        end
    end

    array = GetGlobalCallbackArray(ctype)
    count = _getn(array)
    for i=1, count do
        local callback = array[i]
        if callback then
            callback(bot, arg1, arg2, arg3, arg4)
        end
    end

end

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

            if bot.level ~= level then
                bot.level = level
                changed_level = true
            end

            if bot.talents.dualSpecUnlocked ~= secondSpecUnlocked then
                bot.talents.dualSpecUnlocked = secondSpecUnlocked
                changed_spec_data = true
            end

            if bot.talents.activeSpec ~= activeSpec then
                bot.talents.activeSpec = activeSpec
                changed_spec_data = true
            end

            local spec1 = bot.talents.specs[1]
            local spec1tabs = spec1.tabs
            local p1 = 1
            if points2 > points1 then p1 = 2 end
            if points3 > points2 then p1 = 3 end
            
            if spec1.primary ~= p1 then
                spec1.primary = p1
                changed_spec_data = true
            end

            if spec1tabs[1].points ~= points1 then
                spec1tabs[1].points = points1
                changed_spec_data = true
            end

            if spec1tabs[2].points ~= points2 then
                spec1tabs[2].points = points2
                changed_spec_data = true
            end

            if spec1tabs[3].points ~= points3 then
                spec1tabs[3].points = points3
                changed_spec_data = true
            end

            local spec2 = bot.talents.specs[2]
            local spec2tabs = spec2.tabs
            local p2 = 1
            if points5 > points4 then p2 = 2 end
            if points6 > points5 then p2 = 3 end

            if spec2.primary ~= p2 then
                spec2.primary = p2
                changed_spec_data = true
            end

            if spec2tabs[1].points ~= points4 then
                spec2tabs[1].points = points4
                changed_spec_data = true
            end

            if spec2tabs[2].points ~= points5 then
                spec2tabs[2].points = points5
                changed_spec_data = true
            end

            if spec2tabs[3].points ~= points6 then
                spec2tabs[3].points = points6
                changed_spec_data = true
            end

            if bot.expLeft ~= expLeft then
                bot.expLeft = expLeft
                changed_exp = true
            end

            if bot.zone ~= zone then
                bot.zone = zone
                changed_zone = true
            end

            if changed_level then InvokeCallback(CALLBACK_TYPE.LEVEL_CHANGED, bot) end
            if changed_exp then InvokeCallback(CALLBACK_TYPE.EXPERIENCE_CHANGED, bot) end
            if changed_zone then InvokeCallback(CALLBACK_TYPE.ZONE_CHANGED, bot) end
            if changed_spec_data then InvokeCallback(CALLBACK_TYPE.SPEC_DATA_CHANGED, bot) end
        end
    end,
    onFinalize       = function(query) end,
}

queryTemplates[QUERY_TYPE.GEAR] = 
{
    qtype = QUERY_TYPE.GEAR,
    callbackType = CALLBACK_TYPE.EQUIPMENT_CHANGED,
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
            InvokeCallback(CALLBACK_TYPE.EQUIPMENT_CHANGED, query.bot)
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
        InvokeCallback(CALLBACK_TYPE.INVENTORY_CHANGED, query.bot)
    end,
}

-----------------------------------------------------------------------------
----- QUERIES END
----- QUERIES END
----- QUERIES END
----- QUERIES END
----- QUERIES END
-----------------------------------------------------------------------------

function PlayerbotsBroker:GetBotStatus(name)
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

-- ID must be uint16
function PlayerbotsBroker:GenerateMessage(target, header, subtype, id, payload)
    if not id then id = 0 end
    local msg = _tconcat({
        _strchar(header),
        MSG_SEPARATOR,
        _strchar(subtype),
        MSG_SEPARATOR,
        _strformat("%03d", id),
        MSG_SEPARATOR,
        payload})
    _sendAddonMsg(_prefixCode, msg, "WHISPER", target)
    _debug:LevelDebug(2, "|cff7afffb >> " .. target .. " |r "..  msg)
end

-- bots - reference to _dbchar.bots
function PlayerbotsBroker:Init(bots)
    _bots = bots
    _updateHandler:RegisterHandler(PlayerbotsBroker.OnUpdate)

    for name, bot in _pairs(_bots) do
        local status = PlayerbotsBroker:GetBotStatus(bot.name)
        status.party = UnitInParty(bot.name) ~= nil
        PlayerbotsBroker:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function PlayerbotsBroker:OnEnable()
    for name, bot in _pairs(_bots) do
        PlayerbotsBroker:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function PlayerbotsBroker:OnDisable()
    for name, bot in _pairs(_bots) do
        PlayerbotsBroker:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.LOGOUT)
    end
end

function PlayerbotsBroker:OnUpdate(elapsed)
    local time = _updateHandler.totalTime

    local closeWindow = _cfg.queryCloseWindow
    for id, query in _pairs(_activeQueriesById) do
        if query ~= nil and query.lastMessageTime ~= nil then
            if query.lastMessageTime  + closeWindow < time then
                PlayerbotsBroker:FinalizeQuery(query)
            end
        end
    end
end

function PlayerbotsBroker:StartQuery(qtype, bot)
    if not bot then return end
    local status = PlayerbotsBroker:GetBotStatus(bot.name)
    if not status.online then return end -- abort query because the bot is either not available or offline

    _debug:LevelDebug(1, "PlayerbotsBroker:StartQuery", "QUERY_TYPE", qtype, "name", bot.name)
    local array = PlayerbotsBroker:GetQueriesArray(bot.name)
    local query = array[qtype]
    if query then
        return
    end

    query = PlayerbotsBroker:ConstructQuery(qtype, bot.name)
    if query then
        array[qtype] = query
        _activeQueriesById[query.id] = query
        query:onStart(query)
        PlayerbotsBroker:GenerateQueryMsg(query, nil)
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
function PlayerbotsBroker:ConstructQuery(qtype, name)
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
        query.botStatus = PlayerbotsBroker:GetBotStatus(name)
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

function PlayerbotsBroker:FinalizeQuery(query)
    if not query.hasError then
        query:onFinalize(query)
    end

    local queries = PlayerbotsBroker:GetQueriesArray(query.bot.name)
    queries[query.qtype] = nil
    _activeQueriesById[query.id] = nil
    ReleaseQueryID(query.id)

    wipe(query.ctx1)
    wipe(query.ctx2)
    wipe(query.ctx3)
    _queryPoolCount = _queryPoolCount + 1
    _queryPool[_queryPoolCount] = query

    --_debug:LevelDebug(3, "PlayerbotsBroker:FinalizeQuery", query.bot.name , queries[query.qtype],  _activeQueriesById[query.id])
end

function PlayerbotsBroker:SendWhisper(msg, name)
    SendChatMessage(msg, "WHISPER", nil, name)
end

local SYS_MSG_HANDLERS = {}
SYS_MSG_HANDLERS[SYS_MSG_TYPE.HANDSHAKE] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil
        InvokeCallback(CALLBACK_TYPE.STATUS_CHANGED, bot, status)
    end
    PlayerbotsBroker:GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.HANDSHAKE)
    PlayerbotsBroker:StartQuery(QUERY_TYPE.WHO, bot)
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.PING] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil
        InvokeCallback(CALLBACK_TYPE.STATUS_CHANGED, bot, status)
    end
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.LOGOUT] = function(id,payload, bot, status)
    if status.online then
        status.online = false
        InvokeCallback(CALLBACK_TYPE.STATUS_CHANGED, bot, status)
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
        InvokeCallback(CALLBACK_TYPE.EQUIP_SLOT_CHANGED, bot, slotNum)
    end
end
REP_MSG_HANDLERS[REPORT_TYPE.CURRENCY] = function(id,payload,bot,status) end
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

    InvokeCallback(CALLBACK_TYPE.INVENTORY_CHANGED, bot)
end
REP_MSG_HANDLERS[REPORT_TYPE.TALENTS] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.SPELLS] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.QUEST] = function(id,payload,bot,status) end

local MSG_HANDLERS = {}
MSG_HANDLERS[MSG_HEADER.SYSTEM] = SYS_MSG_HANDLERS
MSG_HANDLERS[MSG_HEADER.REPORT] = REP_MSG_HANDLERS

function PlayerbotsBroker:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == _prefixCode then 
        local bot = _bots[sender]
        if bot then
            _debug:LevelDebug(2,  "|cffb4ff29 << " .. bot.name .. " |r " .. message)
            local status = PlayerbotsBroker:GetBotStatus(bot.name)
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
                            PlayerbotsBroker:FinalizeQuery(query)
                        elseif subtype >= UTF8_NUM_FIRST and subtype <= UTF8_NUM_LAST then
                            query.hasError = true
                            _debug.LevelDebug(1, "Query:", query.id, " returned an error: ", query.opcode)
                            PlayerbotsBroker:FinalizeQuery(query)
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

function PlayerbotsBroker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
end

-- for now the queue only allows a single query of one type to be ran at a time
function PlayerbotsBroker:GetQueriesArray(name)
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

function PlayerbotsBroker:GenerateCommand(bot, cmd, subcmd, arg2, arg3, arg4)
    PlayerbotsBroker:GenerateMessage(bot.name, MSG_HEADER.COMMAND, cmd, 0, _tconcat({ _strchar(subcmd), arg2, arg3, arg4}, MSG_SEPARATOR))
end

function PlayerbotsBroker:GenerateQueryMsg(query, payload)
    --_debug:LevelDebug(2, "generating query: ", query.bot.name, MSG_HEADER.QUERY, query.qtype, query.id, payload)
    PlayerbotsBroker:GenerateMessage(query.bot.name, MSG_HEADER.QUERY, query.qtype, query.id, payload)
end

function PlayerbotsBroker:DoHandshakeAfterRegistration(name)
    local bot = PlayerbotsPanel:GetBot(name)
    if bot then
        PlayerbotsBroker:GenerateMessage(name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.HANDSHAKE)
        PlayerbotsBroker:GenerateMessage(name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
        _updateHandler:DelayCall(1, function ()
            PlayerbotsBroker:StartQuery(QUERY_TYPE.WHO, bot)
        end)
    end
end

function PlayerbotsBroker:PARTY_MEMBERS_CHANGED()
    for name, bot in pairs(_bots) do
        local status = PlayerbotsBroker:GetBotStatus(name)
        local inparty =  UnitInParty(name) ~= nil
        if inparty ~= status.party then
            status.party = inparty
            InvokeCallback(CALLBACK_TYPE.STATUS_CHANGED, bot, status)
        end
    end
end

function PlayerbotsBroker:PARTY_MEMBER_ENABLE()

end

function PlayerbotsBroker:PARTY_MEMBER_DISABLE(id)
    print(id)
end


