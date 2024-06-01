-- Write buffer, wrapper for tconcat with easy to use api

PlayerbotsPanel.StringBuffer = {}
PlayerbotsPanel.StringBuffer.globalDebug = false

local _self = PlayerbotsPanel.StringBuffer
local _concat = table.concat
local _globaldebug = _self.globalDebug
--- Creates new buffer

function _self:Get(debugName)
    local sbuffer = {}
    sbuffer.name = debugName
    sbuffer.buffer = {}
    sbuffer.count = 0
    sbuffer.debug = false

    --- Defaults to white
    sbuffer.PushColor = function (self, colorHex)
        self:_STRING_INTERNAL('\124c')
        if colorHex then
            if type(colorHex) == "table" then -- when using pp color table 
                colorHex = colorHex.hex
            end
            if colorHex then
                self:_STRING_INTERNAL(colorHex)
            else
                self:_STRING_INTERNAL("FFFFFFFF")
            end
        else
            self:_STRING_INTERNAL("FFFFFFFF")
        end
    end

    sbuffer.PopColor = function (self)
        self:_STRING_INTERNAL("\124r")
    end

    sbuffer.NEWLINE = function (self)
        self:_STRING_INTERNAL("\n")
    end

    sbuffer.STRING = function(self, str, colorHex, debugName)
        if colorHex then
            self:_STRING_INTERNAL('\124c')
            self:_STRING_INTERNAL(colorHex)
        end
        if debugName and (self.debug or _globaldebug) then
            print("BUFFER " .. self.name .. " > " .. debugName .. " - " .. str)
        end
        self:_STRING_INTERNAL(str)
        if colorHex then
            self:_STRING_INTERNAL("\124r")
        end
    end

    sbuffer.LINE = function(self, str, colorHex, debugName)
        self:STRING(str, colorHex, debugName)
        self:_STRING_INTERNAL("\n")
    end

    sbuffer.SPACE = function(self, count)
        if not count then
            self:_STRING_INTERNAL(" ")
        else
            for i=1, count do
                self:_STRING_INTERNAL(" ")
            end
        end
    end

    sbuffer._STRING_INTERNAL = function (self, str)
        if str == nil then
            return
        end
        local count = self.count + 1
        self.count = count
        self.buffer[count] = str
    end

    sbuffer.INT = function (self, value, colorHex, debugName)
        if value == nil then
            value = 0
        elseif type(value) == "number" then
            value = math.floor(value)
        end
        self:STRING(tostring(value), colorHex, debugName)
    end

    sbuffer.FLOAT = function (self, value, colorHex, debugName)
        if value == nil then
            value = 0
        elseif type(value) == "number" then
            value = math.floor(value * 100 ) / 100
        end
        self:STRING(tostring(value), colorHex, debugName)
    end

    sbuffer.Clear = function (self)
        if self.count == 0 then return end
        wipe(self.buffer)
        self.count = 0
        self.debug = false
    end

    sbuffer.ToString = function (self, separator)
        local result = _concat(self.buffer, separator)
        self:Clear()
        return result
    end

    sbuffer.Dump = function(self)
        print("buffer.count = "..self.count)
        print("buffer.count actual = "..getn(self.buffer))
        for i=1, getn(self.buffer) do
            print(self.buffer[i])
        end
    end

    return sbuffer
end