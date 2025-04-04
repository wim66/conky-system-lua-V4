-- background.lua
-- by @wim66
-- v2.1 4-April-2024

require 'cairo'
require 'cairo_xlib'

-- Ensure the correct path to settings.lua is set
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]] -- Get the path of the current script
local parent_path = script_path:match("^(.*[\\/])scripts[\\/].*$") -- Extract the parent path up to the 'scripts' directory

package.path = package.path .. ";" .. parent_path .. "?.lua" -- Add the path to Lua's module search path

-- Try to load settings.lua from the parent directory
local status, err = pcall(require, "settings") -- Safe attempt to load settings.lua
if not status then
    local log_file = io.open(parent_path .. "error.log", "a")
    log_file:write("Error loading settings.lua: " .. err .. "\n")
    log_file:close()
    return
end

-- Ensure conky_vars function is called to set variables
if conky_vars then
    conky_vars()
else
    print("conky_vars function is not defined in settings.lua")
end

-- Select color based on variable from settings.lua
-- Parse border_COLOR string in format "0,0x000000,0.5,0xFFFFFF,1,0x000000"
local function parse_border_color(border_color_str)
    local gradient = {}
    for position, color in border_color_str:gmatch("([%d%.]+),0x(%x+)") do
        table.insert(gradient, {tonumber(position), tonumber(color, 16), 1})
    end

    if #gradient == 3 then
        return gradient
    end

    -- Fallback naar standaard groen-gradiënt als parsing mislukt
    return { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} }
end

-- Parse bg_COLOR string into a Conky-compatible table
local function parse_bg_color(bg_color_str)
    local hex, alpha = bg_color_str:match("0x(%x+),(%d+%.%d+)")
    if hex and alpha then
        return { {1, tonumber(hex, 16), tonumber(alpha)} } -- Enkele kleur met alpha
    end
    -- Fallback naar zwart, volledig ondoorzichtig
    return { {1, 0x000000, 1} }
end

-- Stel de variabelen in op basis van settings.lua
local border_color = parse_border_color(border_COLOR) -- Gradiënt voor de rand
local bg_color = parse_bg_color(bg_COLOR)             -- Achtergrondkleur
local boxes_settings = {
    {
        type = "base",
        x = 2, y = 2, w = 254, h = 650,
        colour = bg_color,
        corners = { {"circle", 15} },
        draw_me = true,
    },
    {
        type = "border",
        x = 2, y = 2, w = 254, h = 650,
        colour = border_color,
        linear_gradient = {0,325,254,325},
        corners = { {"circle", 15} },
        border = 4,
        draw_me = true,
    },
}

-- Function to draw a rectangle with rounded corners
local function draw_rounded_rectangle(cr, x, y, w, h, r)
    cairo_new_path(cr)
    cairo_move_to(cr, x + r, y)
    cairo_line_to(cr, x + w - r, y)
    cairo_arc(cr, x + w - r, y + r, r, -math.pi/2, 0)
    cairo_line_to(cr, x + w, y + h - r)
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi/2)
    cairo_line_to(cr, x + r, y + h)
    cairo_arc(cr, x + r, y + h - r, r, math.pi/2, math.pi)
    cairo_line_to(cr, x, y + r)
    cairo_arc(cr, x + r, y + r, r, math.pi, 3*math.pi/2)
    cairo_close_path(cr)
end

function conky_draw_background()
    if conky_window == nil then
        return
    end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    for _, box in ipairs(boxes_settings) do
        if box.draw_me then
            if box.type == "base" then
                cairo_set_source_rgba(cr, 
                    ((box.colour[1][2] & 0xFF0000) >> 16) / 255,
                    ((box.colour[1][2] & 0x00FF00) >> 8) / 255,
                    (box.colour[1][2] & 0x0000FF) / 255,
                    box.colour[1][3])
                draw_rounded_rectangle(cr, box.x, box.y, box.w, box.h, box.corners[1][2])
                cairo_fill(cr)
            elseif box.type == "border" then
                local gradient = cairo_pattern_create_linear(table.unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(gradient, 
                        color[1],
                        ((color[2] & 0xFF0000) >> 16) / 255,
                        ((color[2] & 0x00FF00) >> 8) / 255,
                        (color[2] & 0x0000FF) / 255,
                        color[3])
                end
                cairo_set_source(cr, gradient)
                cairo_set_line_width(cr, box.border)
                draw_rounded_rectangle(cr, 
                    box.x + box.border/2, box.y + box.border/2,
                    box.w - box.border, box.h - box.border,
                    box.corners[1][2] - box.border/2)
                cairo_stroke(cr)
                cairo_pattern_destroy(gradient)
            end
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
