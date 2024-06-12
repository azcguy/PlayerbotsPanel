PlayerbotsPanel.uiutil = {}
local _self = PlayerbotsPanel.uiutil
local _util = PlayerbotsPanel.broker.util
local _data = PlayerbotsPanel.data
local _colorStringBuffer = _util.stringBuffer.Create("Util.colorString")

function _self.ColorString(str, color)
    _colorStringBuffer:Clear()
    _colorStringBuffer:STRING('\124')
    _colorStringBuffer:STRING(color.hex)
    _colorStringBuffer:STRING(str)
    _colorStringBuffer:STRING('\124r')
    return _colorStringBuffer:ToString()
end

function _self.SetTextColor(text, c)
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function _self.SetVertexColor(tex, c)
    if c == nil then
        c = _data.colors.red
        print("ERROR SETTING COLOR")
    end
    tex:SetVertexColor(c.fr, c.fg, c.fb, c.fa)
end

function _self.SetTextColorToClass(text, class)
    local c = _util.CompareAndReturn(class == nil, _data.colors.white, _data.colors.classes[strupper(class)])
    text:SetTextColor(c.fr, c.fg, c.fb, c.fa)
end

function _self.SetBackdrop(frame, tex, texBorder)

    local insets = nil
    if texBorder then
        insets = {
            left = 11,
            right = 12,
            top = 12,
            bottom = 11
        }
    else
        insets = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0
        }
    end
    local backdrop = {
        -- path to the background texture
        bgFile = tex,  
        -- path to the border texture
        edgeFile = texBorder, -- "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        -- true to repeat the background texture to fill the frame, false to scale it
        tile = false,
        -- size (width or height) of the square repeating background tiles (in pixels)
        tileSize = 32,
        -- thickness of edge segments and square size of edge corners (in pixels)
        edgeSize = 32,
        -- distance from the edges of the frame to those of the background texture (in pixels)
        insets = insets
      }
      frame:SetBackdrop(backdrop)
end