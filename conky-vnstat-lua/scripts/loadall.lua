
-- Set the path to the scripts foder
package.path = "./scripts/?.lua"
-- ###################################


require 'background'
require 'lua2-text'

function conky_main()
     conky_draw_background()
     conky_draw_text()

end

--[[
#########################
# conky-vnstat-lua      #
# by +WillemO @wim66    #
#  v1.5 23-dec-17       #
#                       #
#########################
]]
