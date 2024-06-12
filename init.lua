-- Runs first, creates root objects and configs
PlayerbotsPanel = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceHook-2.1", "AceDebug-2.0", "AceEvent-2.0")
PlayerbotsPanel.rootPath = "Interface\\AddOns\\PlayerbotsPanel\\"
PlayerbotsPanel.rootFrame = CreateFrame("Frame", "PlayerbotsPanelFrame", UIParent)
PlayerbotsPanel.tabs = {} -- table to inject ui objects
PlayerbotsPanel.debug = AceLibrary:GetInstance("AceDebug-2.0")
PlayerbotsPanel:RegisterDB("PlayerbotsPanelDb", "PlayerbotsPanelDbPerChar")
PlayerbotsPanel.broker = PlayerbotsBroker
PlayerbotsPanel.util = PlayerbotsPanel.broker.util
PlayerbotsPanel.updateHandler = PlayerbotsPanel.broker.util.updateHandler.Create()
