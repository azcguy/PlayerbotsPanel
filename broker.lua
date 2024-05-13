-- this handles communication between bots and data structures / events
PlayerbotsBroker = {}
local _broker = PlayerbotsBroker
local _updateHandler = PlayerbotsPanelUpdateHandler
local _bots = nil
local _debug = AceLibrary:GetInstance("AceDebug-2.0")
local _cfg = PlayerbotsPanelConfig

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
-- ..

PlayerbotsBrokerReportType = {}
local REPORT_TYPE = PlayerbotsBrokerReportType
--REPORT_TYPE.STATUS = 0 -- status changed
REPORT_TYPE.CURRENCY = 1 -- currency changed
REPORT_TYPE.GEAR = 2 -- gear changed (item equipped/ unequipped)
REPORT_TYPE.INVENTORY = 3 -- inventory changed (bag changed, item added / removed / destroyed)
REPORT_TYPE.TALENTS = 4 -- talent learned / spec changed / talents reset
REPORT_TYPE.SPELLS = 5 -- spell learned
REPORT_TYPE.QUEST = 6 -- single quest accepted, abandoned, changed, completed

local _pingFrequency = 1
local _considerOfflineTime = 2
local _nextQueryId = 0
local _prefixCode = "pb8aj2" -- just something unique from other addons
local _handshakeCode = "hs"
local _logoutCode = "lo"
local _ping = "p"
local _report = "r"

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

local function Send(msg, name)
    SendAddonMessage(_prefixCode, msg, "WHISPER", name)
end

-- bots - reference to _dbchar.bots
function PlayerbotsBroker:Init(bots)
    _bots = bots
    _updateHandler:RegisterHandler(PlayerbotsBroker.OnUpdate)

    for name, bot in pairs(_bots) do
        local status = PlayerbotsBroker:GetBotStatus(bot.name)
        status.party = UnitInParty(bot.name) ~= nil and true or false
        Send(_ping, bot.name)
    end
end

function PlayerbotsBroker:OnEnable()
    for name, bot in pairs(_bots) do
        Send(_ping, bot.name)
    end
end

function PlayerbotsBroker:OnDisable()
    for name, bot in pairs(_bots) do
        Send(_logoutCode, bot.name)
    end
end

local function PingBot(name)
    print("pinging bot: " .. name)
    Send(_ping, name)
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

function PlayerbotsBroker:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == _prefixCode then 
        local bot = _bots[sender]
        if bot then
            print("received from: " .. bot.name .. " msg: " .. message)
            local status = PlayerbotsBroker:GetBotStatus(bot.name)
            status.lastMessageTime = _updateHandler.totalTime
            if message == _ping then
                if not status.online then
                    status.online = true
                    status.party = UnitInParty(bot.name) ~= nil and true or false
                    PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
                end
            elseif message == _handshakeCode then
                if not status.online then
                    status.online = true
                    status.party = UnitInParty(bot.name) ~= nil and true or false
                    PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
                end
                Send(_handshakeCode, bot.name)
                --PlayerbotsBroker:NotifyQueryComplete(QUERY_TYPE.STATUS, bot.name)
            elseif message == _logoutCode then
                if status.online then
                    status.online = false
                    PlayerbotsBroker:NotifyStatusUpdated(bot.name, status)
                end
            end
        end
    end
end

function PlayerbotsBroker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
    --if message == "Hello!" then
    --    local bot = _bots[sender]
    --    if bot then
    --        bot.online = true
    --        return 
    --    end
    --end
--
    --if message == "Goodbye!" then
    --    local bot = _bots[sender]
    --    if bot then
    --        bot.online = false
    --        return 
    --    end
    --end
    --local queries = _queries[sender]
    --if queries then
    --    for qtype, query in pairs(queries) do -- iterate query types
    --        if query then
    --            if query.method == 1 then
    --                if query.onProgressLegacy then
    --                    query.lastMessageTime = _updateHandler.totalTime
    --                    query:onProgressLegacy(query, message)
    --                end
    --            end
    --        end
    --    end
    --end
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
