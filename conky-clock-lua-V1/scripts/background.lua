-- background.lua
-- by @wim66
-- v2 v2 27-march-2024

-- Make sure to set the correct path to settings.lua
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])scripts[\\/].*$")

package.path = package.path .. ";" .. parent_path .. "?.lua"

-- Attempt to load settings.lua from the parent directory
local status, err = pcall(function() require("settings") end)
if not status then
    print("Error loading settings.lua: " .. err)
end

-- Make sure the conky_vars function is called to set the variables
if conky_vars then
    conky_vars()
else
    print("conky_vars function is not defined in settings.lua")
end

-- Select the color based on the variable from settings.lua
local color_options = {
    green = { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} },
    orange = { {0, 0xE05700, 1}, {0.5, 0xFFD145, 1}, {1, 0xE05700, 1} },
    blue = { {0, 0x0000ba, 1}, {0.5, 0x8cc7ff, 1}, {1, 0x0000ba, 1} },
    black = { {0, 0x2b2b2b, 1}, {0.5, 0xa3a3a3, 1}, {1 ,0x2b2b2b, 1} },
    red = { {0, 0x5c0000, 1}, {0.5, 0xff0000, 1}, {1 ,0x5c0000, 1} }
}

local bgcolor_options = {
    black_50 = { {1, 0x000000, 0.5} },
    black_25 = { {1, 0x000000, 0.25} },
    black_75 = { {1, 0x000000, 0.75} },
    black_100 = { {1, 0x000000, 1} },
    dark_100 = { {1, 0x23263A, 1} },
    blue = { {1, 0x0000ba, 0.5} }
}

local border_color = color_options[border_COLOR] or color_options.green  -- default to green if border_COLOR does not exist
local bg_color = bgcolor_options[bg_COLOR] or bgcolor_options.black      -- default to black if bg_COLOR does not exist

local boxes_settings = {
    -- Base background
    {
        type = "base",
        x = 2, y = 2, w = 254, h = 128,
        colour = bg_color,
        corners = { {"circle", 15} },
        draw_me = true,
    },
    -- Border
    {
        type = "border",
        x = 2, y = 2, w = 254, h = 128,
        colour = border_color,
        linear_gradient = {0,64,254,64},
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

local function draw_base(cr, box)
    cairo_set_source_rgba(cr, ((box.colour[1][2] & 0xFF0000) >> 16) / 255, ((box.colour[1][2] & 0x00FF00) >> 8) / 255, (box.colour[1][2] & 0x0000FF) / 255, box.colour[1][3])
    draw_rounded_rectangle(cr, box.x, box.y, box.w, box.h, box.corners[1][2])
    cairo_fill(cr)
end

local function draw_border(cr, box)
    local gradient = cairo_pattern_create_linear(table.unpack(box.linear_gradient))
    for _, color in ipairs(box.colour) do
        cairo_pattern_add_color_stop_rgba(gradient, color[1], ((color[2] & 0xFF0000) >> 16) / 255, ((color[2] & 0x00FF00) >> 8) / 255, (color[2] & 0x0000FF) / 255, color[3])
    end
    cairo_set_source(cr, gradient)
    cairo_set_line_width(cr, box.border)
    draw_rounded_rectangle(cr, box.x + box.border/2, box.y + box.border/2, box.w - box.border, box.h - box.border, box.corners[1][2] - box.border/2)
    cairo_stroke(cr)
    cairo_pattern_destroy(gradient)
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
                draw_base(cr, box)
            elseif box.type == "border" then
                draw_border(cr, box)
            end
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end