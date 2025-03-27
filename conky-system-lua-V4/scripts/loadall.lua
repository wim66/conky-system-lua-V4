
-- Set the path to the scripts folder
package.path = "./scripts/?.lua"
-- ###################################


require 'background'
require 'lua1-graphs'
require 'lua2-text'
require 'lua3-bars'

function conky_main()
     conky_draw_background()
     conky_main_graph()
     conky_draw_text()
     conky_main_bars()
end

--[[
#########################
# conky-system-lua-V3   #
# by +WillemO @wim66    #
# v1.5 23-dec-17        #
#                       #
#########################
]]
