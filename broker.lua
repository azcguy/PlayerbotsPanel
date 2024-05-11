-- this handles communication between bots and data structures / events
PlayerbotsBroker = {}
local _broker = PlayerbotsBroker
local _updateHandler = PlayerbotsPanelUpdateHandler
local _bots = nil
local _debug = AceLibrary:GetInstance("AceDebug-2.0")
local _cfg = PlayerbotsPanelConfig
local _nextQueryId = 0

PlayerbotsBrokerQueryType = {}
local QUERY_TYPE = PlayerbotsBrokerQueryType
QUERY_TYPE.STATUS = 0 -- online, in party
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
REPORT_TYPE.STATUS = 0 -- status changed
REPORT_TYPE.CURRENCY = 1 -- currency changed
REPORT_TYPE.GEAR = 2 -- gear changed (item equipped/ unequipped)
REPORT_TYPE.INVENTORY = 3 -- inventory changed (bag changed, item added / removed / destroyed)
REPORT_TYPE.TALENTS = 4 -- talent learned / spec changed / talents reset
REPORT_TYPE.SPELLS = 5 -- spell learned
REPORT_TYPE.QUEST = 6 -- single quest accepted, abandoned, changed, completed


-- Stores queues per query type, per bot
-- _queries[botName][QUERY_TYPE]
local _queries = {}
-- optimization, duplicates references to queries in _queries but accelerates lookup by int
local _activeQueriesById = {}

-- Stores report handlers per report type
local _reportHandlers = {}

-- Stores Query Complete handlers per  per bot, query type
local _completeHandlers = {}

local queryTemplates = {}

-- pay attention not to capture anything in functions
queryTemplates[QUERY_TYPE.STATUS] = 
{
    qtype = QUERY_TYPE.STATUS,
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
            InviteUnit(bot.name)
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

-- ------------------ OLD API
local botQueryQueues = {}
local botActiveQueries = {}
-- ------------------ OLD API


-----------------------------------------------------------------------------
----- NEW API START
-----------------------------------------------------------------------------

-- bots - reference to _dbchar.bots
function PlayerbotsBroker:Init(bots)
    _bots = bots
    _updateHandler:RegisterHandler(PlayerbotsBroker.OnUpdate)
end

function PlayerbotsBroker:OnUpdate(elapsed)
    -- OLD
    local time = _updateHandler.totalTime
    local closeWindow = _cfg.queryCloseWindow
    for id, query in pairs(_activeQueriesById) do
        if query ~= nil and query.lastMessageTime ~= nil then
            if query.lastMessageTime  + closeWindow < time then
                PlayerbotsBroker:FinalizeQuery(query)
            end
        end
    end

    --if activeBotQuery ~= nil then
    --    for k, q in pairs(botActiveQueries) do
    --        if q ~= nil then
    --            if q.anyMsgReceived then
    --                if q.lastMessageTime < q.lastMessageTime + q.timeWindow then
    --                  PlayerbotsPanel:FinishActiveQuery()
    --                end
    --            end
    --        end
    --    end
    --end
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

function PlayerbotsBroker:NotifyQueryComplete(qtype, name)
    local handlers = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    local count = getn(handlers)
    if count > 0 then
        for i=1, count do
            handlers[i](name)
        end
    end
end

function PlayerbotsBroker:SendWhisper(msg, name)
    SendChatMessage(msg, "WHISPER", nil, name)
end

function PlayerbotsBroker:SendAddonMsg(msg, name)
    SendAddonMessage("pp", msg, "WHISPER", name)
end

function PlayerbotsBroker:CHAT_MSG_ADDON(prefix, message, channel, sender)
    SendChatMessage("MSG ADDON START -----")
    SendChatMessage(prefix)
    SendChatMessage(message)
    SendChatMessage(sender)
    SendChatMessage("MSG ADDON END   -----")

    if prefix == "pbot.qr" then -- process bot query response messages

    elseif prefix == "pbot.re" then -- process bot reports

    end
end

function PlayerbotsBroker:CHAT_MSG_WHISPER(message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
    if message == "Hello!" then
        local bot = _bots[sender]
        if bot then
            bot.online = true
            return 
        end
    end

    if message == "Goodbye!" then
        local bot = _bots[sender]
        if bot then
            bot.online = false
            return 
        end
    end
    local queries = _queries[sender]
    if queries then
        for qtype, query in pairs(queries) do -- iterate query types
            if query then
                if query.method == 1 then
                    if query.onProgressLegacy then
                        query.lastMessageTime = _updateHandler.totalTime
                        query:onProgressLegacy(query, message)
                    end
                end
            end
        end
    end

    --local q = botActiveQueries[sender]
    --if q == nil then return end
    --q.anyMsgReceived = true
    --q.lastMessageTime = _updateHandler._totalTime
    --if q.mode == 1 then -- STATS cmd
    --    local bot = PlayerbotsPanel:GetBot(sender)
    --    local money, bag, durability, xp = strsplit(",", message)
    --    if money then
    --        local gold, silver, copper = strsplit(" ", money)
    --        if copper then bot.currency.copper = copper end
    --        if silver then bot.currency.silver = silver end
    --        if gold then bot.currency.gold = gold end
    --    end
    --    if bag then
    --    
    --    end
    --    PlayerbotsBroker:FinishActiveQuery(sender)
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

-- callback(type, name (bot), payload)
function PlayerbotsBroker:RegisterCompleteHandler(qtype, name, callback)
    local array = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    tinsert(array, callback)
end

function PlayerbotsBroker:UnregisterCompleteHandler(qtype,name, callback)
    local array = PlayerbotsBroker:GetCompleteHandlers(qtype, name)
    tinsert(array, callback)
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

-----------------------------------------------------------------------------
----- QUERIES IMPL
-----------------------------------------------------------------------------








-----------------------------------------------------------------------------
----- NEW API END
-----------------------------------------------------------------------------



-- ------------------ OLD API


-- mode: 0 STANDBY, 1 STATS, 2 INVENTORY
-- name: bot name
-- timeWindow: once at least one message is received, how long since last received message til the query is considered complete
-- callback: called when query is finished
function PlayerbotsBroker:StartBotQuery(mode, name, timeWindow, callback) --
  if mode < 1 or mode > 2 then return end
  local bot = PlayerbotsPanel:GetBot(name)
  if bot == nil then return end
  if not bot.online then return end
  if timeWindow == nil then timeWindow = 0.1 end -- default time window
  local query = {    
    mode = mode, 
    name = name,
    callback = callback,
    anyMsgReceived = false,
    lastMessageTime = nil,
    timeWindow = timeWindow,
  }
  if botQueryQueues[name] == nil then
    botQueryQueues[name] = {}
  end

  tinsert(botQueryQueues[name], query)
  if botActiveQueries[name] == nil then
    PlayerbotsBroker:StartNextBotQuery(name)
  end
end

function PlayerbotsBroker:StartNextBotQuery(name)
    if botQueryQueues[name] == nil then return end
    local qt = botQueryQueues[name]
    local qnum = getn(qt)
    if qnum > 0 then
        botActiveQueries[name] = tremove(qt, 1)
        local active = botActiveQueries[name]
        if active.mode == 1 then
            SendChatMessage("stats", "WHISPER", nil, active.name)
        end
    end
end







-- ------------------ OLD API
