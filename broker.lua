-- this handles communication between bots and data structures / events
PlayerbotsBroker = {}
local _broker = PlayerbotsBroker
local _updateHandler = PlayerbotsPanelUpdateHandler
local _bots = nil
local _debug = AceLibrary:GetInstance("AceDebug-2.0")
local _cfg = PlayerbotsPanelConfig
local _pingFrequency = 1
local _considerOfflineTime = 2
local _nextQueryId = 0
local _prefixCode = "pb8aj2" -- just something unique from other addons

-- ============================================================================================

local MSG_SEPARATOR = ":"
local MSG_SEPARATOR_BYTE = string.byte(":")
local MSG_HEADER = {}
MSG_HEADER.SYSTEM = string.byte("s")
MSG_HEADER.REPORT = string.byte("r")

PlayerbotsBrokerReportType = {}
local REPORT_TYPE = PlayerbotsBrokerReportType
REPORT_TYPE.ITEM_EQUIPPED = string.byte("g") -- gear item equipped or unequipped
REPORT_TYPE.CURRENCY = string.byte("c") -- currency changed
REPORT_TYPE.INVENTORY = string.byte("i") -- inventory changed (bag changed, item added / removed / destroyed)
REPORT_TYPE.TALENTS = string.byte("t") -- talent learned / spec changed / talents reset
REPORT_TYPE.SPELLS = string.byte("s") -- spell learned
REPORT_TYPE.QUEST = string.byte("q") -- single quest accepted, abandoned, changed, completed

local SYS_MSG_TYPE = {}
SYS_MSG_TYPE.HANDSHAKE = string.byte("h")
SYS_MSG_TYPE.PING = string.byte("p")
SYS_MSG_TYPE.LOGOUT = string.byte("l")

-- ============================================================================================


PlayerbotsBrokerQueryType = {}
local QUERY_TYPE = PlayerbotsBrokerQueryType
--QUERY_TYPE.STATUS = 0 -- online, in party
QUERY_TYPE.CURRENCY = 1 -- money, honor, tokens
QUERY_TYPE.GEAR = 2 -- only what is equipped
QUERY_TYPE.INVENTORY = 3 -- whats in the bags and bags themselves
QUERY_TYPE.TALENTS = 4 -- talents and talent points 
QUERY_TYPE.SPELLS = 5 -- spellbook
QUERY_TYPE.QUESTS = 6 -- all quests
QUERY_TYPE.QUESTS = 7 -- single quest
QUERY_TYPE.STRATEGIES = 8

PlayerbotsBrokerCommandType = {}
local CMD_TYPE = PlayerbotsBrokerCommandType
CMD_TYPE.SUMMON = 0 
CMD_TYPE.STAY = 1
CMD_TYPE.FOLLOW = 2

-- Stores queues per query type, per bot
-- _queries[botName][QUERY_TYPE]
local _queries = {}
-- optimization, duplicates references to queries in _queries but accelerates lookup by int
local _activeQueriesById = {}
local queryTemplates = {}
local _botStatus = {}

-- pay attention not to capture anything in functions
queryTemplates[QUERY_TYPE.CURRENCY] = 
{
    qtype = QUERY_TYPE.CURRENCY,
    bot = nil, -- target bot data
    id = 0, -- query id
    method = 1, -- 0 - ADDON_MSG | 1 - WHISPER ( LEGACY ),
    onStart          = function(query) end,
    onProgress       = function(query, payload) end,
    onFinalize       = function(query) end,

    onStartLegacy    = function(query)
        local bot = query.bot
        bot.online = UnitIsConnected(bot.name) 

        if bot.online then
            PlayerbotsBroker:FinalizeQuery(query)
            return
        else
        end
    end,
    onProgressLegacy = function(query, payload) 
        if payload then
            query.bot.online = true
            PlayerbotsBroker:FinalizeQuery(query)
        end
    end,
    onFinalizeLegacy = function(query)
        local bot = query.bot
        if bot.online then 
            bot.inParty =  UnitInParty(bot.name) ~= nil and true or false
            bot.level = UnitLevel(bot.name)
            if not bot.guid then bot.guid = UnitGUID(bot.name) end
            if not bot.class then 
                local class, classFileName = UnitClass(bot.name)
                bot.class = classFileName
                bot.classNice = class
            end
            if not bot.race then
                local race, raceFilename = UnitRace(bot.name)
                if racetoken ~= nil then
                    bot.race = strupper(raceFilename)
                end
                bot.raceNice = race
            end
        end
    end,
}

-----------------------------------------------------------------------------
----- NEW API START
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

function PlayerbotsBroker:print(t)
    DEFAULT_CHAT_FRAME:AddMessage("pp_broker: " .. t)
end

-- ID must be uint16
local function GenerateMessage(target, header, subtype, id, payload)
    if not id then id = 0 end
    local msg = table.concat({
        string.char(header),
        MSG_SEPARATOR,
        string.char(subtype),
        MSG_SEPARATOR,
        string.format("%05d", id),
        MSG_SEPARATOR,
        payload})
    SendAddonMessage(_prefixCode, msg, "WHISPER", target)
end

-- bots - reference to _dbchar.bots
function PlayerbotsBroker:Init(bots)
    _bots = bots
    _updateHandler:RegisterHandler(PlayerbotsBroker.OnUpdate)

    for name, bot in pairs(_bots) do
        local status = PlayerbotsBroker:GetBotStatus(bot.name)
        status.party = UnitInParty(bot.name) ~= nil and true or false
        GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function PlayerbotsBroker:OnEnable()
    for name, bot in pairs(_bots) do
        GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.PING)
    end
end

function PlayerbotsBroker:OnDisable()
    for name, bot in pairs(_bots) do
        GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.LOGOUT)
    end
end

function PlayerbotsBroker:OnUpdate(elapsed)
    local time = _updateHandler.totalTime

    local closeWindow = _cfg.queryCloseWindow
    for id, query in pairs(_activeQueriesById) do
        if query ~= nil and query.lastMessageTime ~= nil then
            if query.lastMessageTime  + closeWindow < time then
                PlayerbotsBroker:FinalizeQuery(query)
            end
        end
    end
end

function PlayerbotsBroker:StartQuery(qtype, name)
    _debug:LevelDebug(3, "PlayerbotsBroker:StartQuery", "QUERY_TYPE", QUERY_TYPE, "name", name)
    local bot = PlayerbotsPanel:GetBot(name)
    if bot == nil then
        _debug:LevelDebug(2, "PlayerbotsBroker:StartQuery - Queried bot was not found!", name)
        return
    end

    local queries = PlayerbotsBroker:GetQueries(name)
    local query = queries[qtype]
    if query then
        return
    end

    query = PlayerbotsBroker:ConstructQuery(qtype, name)
    queries[qtype] = query
    _activeQueriesById[query.id] = query
    if query.method == 0 then
        query:onStart(query)
    elseif query.method == 1 then
        query:onStartLegacy(query)
    end
end

function PlayerbotsBroker:ConstructQuery(qtype, name)
    local bot = PlayerbotsPanel:GetBot(name)
    if not bot then return end
    if queryTemplates[qtype] then
        local template = queryTemplates[qtype]
        local query = {
            qtype = template.qtype,
            bot = bot,
            id = _nextQueryId,
            method = template.method,
            lastMessageTime = _updateHandler.totalTime,
            onStart = template.onStart,
            onProgress = template.onProgress,
            onFinalize = template.onFinalize,

            onStartLegacy = template.onStartLegacy,
            onProgressLegacy = template.onProgressLegacy,
            onFinalizeLegacy = template.onFinalizeLegacy,
        }
        _nextQueryId = _nextQueryId + 1
        return query
    end
    return nil
end

function PlayerbotsBroker:FinalizeQuery(query)
    if query.method == 0 then
        query:onFinalize(query)
    elseif query.method == 1 then
        query:onFinalizeLegacy(query)
    end

    local queries = PlayerbotsBroker:GetQueries(query.bot.name)
    queries[query.qtype] = nil
    _activeQueriesById[query.id] = nil
    _debug:LevelDebug(3, "PlayerbotsBroker:FinalizeQuery", query.bot.name , queries[query.qtype],  _activeQueriesById[query.id])
    PlayerbotsBroker:NotifyQueryComplete(query.qtype, query.bot.name)
end

function PlayerbotsBroker:SendWhisper(msg, name)
    SendChatMessage(msg, "WHISPER", nil, name)
end

local SYS_MSG_HANDLERS = {}
SYS_MSG_HANDLERS[SYS_MSG_TYPE.HANDSHAKE] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil and true or false
        PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
    end
    GenerateMessage(bot.name, MSG_HEADER.SYSTEM, SYS_MSG_TYPE.HANDSHAKE)
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.PING] = function(id,payload, bot, status)
    if not status.online then
        status.online = true
        status.party = UnitInParty(bot.name) ~= nil and true or false
        PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
    end
end

SYS_MSG_HANDLERS[SYS_MSG_TYPE.LOGOUT] = function(id,payload, bot, status)
    if status.online then
        status.online = false
        PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
    end
end

local REP_MSG_HANDLERS = {}
REP_MSG_HANDLERS[REPORT_TYPE.ITEM_EQUIPPED] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.CURRENCY] = function(id,payload,bot,status) end
REP_MSG_HANDLERS[REPORT_TYPE.INVENTORY] = function(id,payload,bot,status) end
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
            print(bot.name .. " >> " .. message)
            local status = PlayerbotsBroker:GetBotStatus(bot.name)
            if not status then return end
            status.lastMessageTime = _updateHandler.totalTime

            -- confirm that the message has valid format
            local header, separator1, subtype, separator2 = strbyte(message, 1, 4)
            local separator3 = strbyte(message, 10)
            -- 1 [HEADER] 2 [SEPARATOR] 3 [SUBTYPE] 4 [SEPARATOR] 5 [ID1] 6 [ID2] 7 [ID3] 8 [ID4] 9 [ID5] 10 [SEPARATOR] [PAYLOAD]
            -- s:p:65000:payload
            if separator1 == MSG_SEPARATOR_BYTE and separator2 == MSG_SEPARATOR_BYTE and separator3 == MSG_SEPARATOR_BYTE then
                local handlers = MSG_HANDLERS[header]
                if handlers then
                    local handler = handlers[subtype]
                    if handler then
                        local id = tonumber(strsub(5, 9))
                        local payload = strsub(message, 7)
                        handler(id, payload, bot, status)
                    end
                end
            end
        end
    end
end

function PlayerbotsBroker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
end

-- for now the queue only allows a single query of one type to be ran at a time
function PlayerbotsBroker:GetQueries(name)
    if not name then
        _debug:LevelDebug(2, "PlayerbotsBroker:GetQueries", "name is nil")
    end
    local queryByBot = _queries[name]
    if not queryByBot then
        queryByBot = {}
        _queries[name] = queryByBot
    end
    return queryByBot
end

-- Stores report handlers per report type
local _reportHandlers = {}

-- Stores Query Complete handlers per  per bot, query type
local _completeHandlers = {}
local _statusUpdateHandlers = {}

function PlayerbotsBroker:NotifyQueryComplete(qtype, name)
    local handlers = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    local count = getn(handlers)
    if count > 0 then
        for i=1, count do
            handlers[i](name)
        end
    end
end

function PlayerbotsBroker:NotifyStatusUpdated(name, status)
    local handlers = PlayerbotsBroker:GetStatusUpdateHandlers(name)
    local count = getn(handlers)
    if not status then
        status = PlayerbotsBroker:GetBotStatus(name)
    end
    if count > 0 then
        for i=1, count do
            handlers[i](name)
        end
    end
end

-- callback(type, name (bot), payload)
function PlayerbotsBroker:RegisterCompleteHandler(qtype, name, callback)
    local array = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    tinsert(array, callback)
end

function PlayerbotsBroker:UnregisterCompleteHandler(qtype,name, callback)
    local array = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    local idx = _util:IndexOf(array, callback)
    if idx > 0 then
        tremove(array, idx)
    end
end

function PlayerbotsBroker:RegisterStatusUpdateHandler(name, callback)
    local array = PlayerbotsBroker:GetStatusUpdateHandlers(name)
    tinsert(array, callback)
end

function PlayerbotsBroker:UnregisterStatusUpdateHandler(name, callback)
    local array = PlayerbotsBroker:GetStatusUpdateHandlers(name)
    local idx = _util:IndexOf(array, callback)
    if idx > 0 then
        tremove(array, idx)
    end
end

function PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    if not _completeHandlers[name] then
        _completeHandlers[name] = {}
    end
    local handlersByBot = _completeHandlers[name]
    if not handlersByBot then
        handlersByBot = {}
        _completeHandlers[name] = handlersByBot
    end

    local handlersByType = handlersByBot[qtype]
    if not handlersByType then
        handlersByType = {}
        handlersByBot[qtype] = handlersByType
    end
    return handlersByType
end

function PlayerbotsBroker:GetStatusUpdateHandlers(name)
    if not _statusUpdateHandlers[name] then
        _statusUpdateHandlers[name] = {}
    end
    local handlersByBot = _statusUpdateHandlers[name]
    if not handlersByBot then
        handlersByBot = {}
        _statusUpdateHandlers[name] = handlersByBot
    end
    return handlersByBot
end

function PlayerbotsBroker:PARTY_MEMBERS_CHANGED()
    for name, bot in pairs(_bots) do
        local status = PlayerbotsBroker:GetBotStatus(name)
        local inparty =  UnitInParty(name) ~= nil and true or false
        if inparty ~= status.party then
            status.party = inparty
            PlayerbotsBroker:NotifyStatusUpdated(name, status)
        end
    end
end

function PlayerbotsBroker:PARTY_MEMBER_ENABLE()

end

function PlayerbotsBroker:PARTY_MEMBER_DISABLE(id)
    print(id)
end

-----------------------------------------------------------------------------
----- QUERIES IMPL
-----------------------------------------------------------------------------
