
-- Set the path to the scripts folder
package.path = "./scripts/?.lua"
-- ###################################


require 'background'
require 'text'
require 'clock'

function conky_main()
     conky_draw_background()
     conky_draw_text()
     conky_main_clock()     
end

--[[
#########################
# conky-clock-lua-V1    #
# by +WillemO @wim66    #
# v1.5 23-dec-17        #
#                       #
#########################
]]

