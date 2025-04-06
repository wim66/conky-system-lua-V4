-- conky-system-lua V4
-- by @wim66
-- v4 6-April-2024

-- Set the path to the scripts folder
package.path = "./scripts/?.lua"

-- Import modules
local success, background = pcall(require, 'background')
if not success then print("Error loading background module: "..background) end

local success, lua1_graphs = pcall(require, 'lua1-graphs')
if not success then print("Error loading lua1-graphs module: "..lua1_graphs) end

local success, lua2_text = pcall(require, 'lua2-text')
if not success then print("Error loading lua2-text module: "..lua2_text) end

local success, lua3_bars = pcall(require, 'lua3-bars')
if not success then print("Error loading lua3-bars module: "..lua3_bars) end

-- Main function to draw Conky elements
function conky_main()
    if background then conky_draw_background() end
    if lua1_graphs then conky_main_graph() end
    if lua2_text then conky_draw_text() end
    if lua3_bars then conky_main_bars() end
end
