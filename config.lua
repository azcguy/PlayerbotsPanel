PlayerbotsPanel.config = {}
local _self = PlayerbotsPanel.config

--=================================================================================
-- GENERAL 
_self.panelStrata = "HIGH"
_self.defaultOpenTab = "Items"

--=================================================================================
-- DEV
_self.debugLevel = 2

--=================================================================================
-- INVENTORY TAB
if not _self.inventory then _self.inventory = {} end
_self.inventory.topbarHeight = 32
_self.inventory.hideEmptySlots = true

--=================================================================================
-- ITEM CACHE
_self.itemCacheAsyncItemsPerSecond = 60