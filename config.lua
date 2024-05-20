PlayerbotsPanelConfig = {}
local _cfg = PlayerbotsPanelConfig

_cfg.debugLevel = 2
_cfg.queryCloseWindow = 0.25 -- seconds

if not _cfg.inventory then
    _cfg.inventory = {}
end

_cfg.inventory.topbarHeight = 32