---
-- Commands for the hypertext module.
module('_m.hypertext.commands', package.seeall)

require 'hypertext.zen'

local function tabkey()
        if _m.textadept.snippets._insert() == true then return true end
        if #buffer:get_sel_text() == 0
                        and _m.hypertext.zen.process_zen() == true then
                return true
        else
                return false
        end
end

-- hypertext-specific key commands.
local keys = _G.keys
if type(keys) == 'table' then
        keys.hypertext = {
                al = {
                        m = { io.open_file,
                        (_USERHOME..'/modules/hypertext/init.lua'):iconv('UTF-8', _CHARSET) },
                },
                ['\t']= {tabkey},
        }
end