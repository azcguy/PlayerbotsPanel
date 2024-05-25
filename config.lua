PlayerbotsPanelConfig = {}
local _cfg = PlayerbotsPanelConfig

-- general
_cfg.panelStrata = "HIGH"

-- dev
_cfg.debugLevel = 2

-- BROKER
_cfg.queryCloseWindow = 0.25 -- seconds

-- ITEM INVENTORY TAB
if not _cfg.inventory then _cfg.inventory = {} end
_cfg.inventory.topbarHeight = 32
_cfg.inventory.hideEmptySlots = true

-- ITEM CACHE
_cfg.itemCacheAsyncItemsPerSecond = 60