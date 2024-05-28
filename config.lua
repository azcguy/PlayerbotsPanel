PlayerbotsPanel.Config = {}
local _self = PlayerbotsPanel.Config

-- general
_self.panelStrata = "HIGH"
_self.defaultOpenTab = "Items"

-- dev
_self.debugLevel = 2

-- BROKER
_self.queryCloseWindow = 0.25 -- seconds

-- ITEM INVENTORY TAB
if not _self.inventory then _self.inventory = {} end
_self.inventory.topbarHeight = 32
_self.inventory.hideEmptySlots = true

-- ITEM CACHE
_self.itemCacheAsyncItemsPerSecond = 60