-- conky-vnstat-lua V4
-- by @wim66
-- v4 6-April-2024

-- Set the path to the scripts foder
package.path = "./scripts/?.lua"
-- ###################################


require 'background'
require 'lua2-text'

function conky_main()
     conky_draw_background()
     conky_draw_text()

end

