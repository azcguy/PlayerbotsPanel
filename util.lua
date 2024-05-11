PlayerbotsPanelUtil = {}
local _data = PlayerbotsPanelData

function PlayerbotsPanelUtil:SetTextColor(text, c)
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function PlayerbotsPanelUtil:SetVertexColor(tex, c)
    tex:SetVertexColor(c.r, c.g, c.b)
end

function PlayerbotsPanelUtil:SetTextColorToClass(text, class)
    local c = class == nil and _data.colors.white or _data.colors.classes[strupper(class)]
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function PlayerbotsPanelUtil:Where(_table, predicate)
    for k,v in pairs(_table) do
        if(predicate(k,v)) then
            return _table[k]
        end    
    end
end

function PlayerbotsPanelUtil:IndexOf(_table, predicate)
    local t = 1
    for k,v in pairs(_table) do
        if(predicate(k,v)) then
            return t
        end    
        t = t + 1
    end
    return -1
end

-- copies the table and returns a new one
function PlayerbotsPanelUtil:RemoveByKey(_table, key)
    local n = {}
    for k,v in pairs(_table) do
        if k ~= key then
            n[k] = v
        end
    end
    return n
end

function PlayerbotsPanelUtil:DumpTable(_table)
    PlayerbotsPanelUtil:Where(_table, function(k,v)
        print(k, v)
    end)
end






