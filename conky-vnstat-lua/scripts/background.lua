-- conky-vnstat-lua V4
-- by @wim66
-- v4 6-April-2024

require 'cairo'
require 'cairo_xlib'

-- Get the path of the current script using debug info
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[/\])[^/\]-$]]

-- Extract parent directory path up to 'scripts', works cross-platform (Windows/Linux)
local parent_path = script_path:match("^(.*[/\\])scripts[/\\].*$") or ""

-- Add the parent path to the Lua package path so we can require files from it
package.path = package.path .. ";" .. parent_path .. "?.lua"

-- Try to safely load settings.lua
local status, err = pcall(require, "settings")
if not status then
    local log_file = io.open(parent_path .. "error.log", "a")
    log_file:write("Error loading settings.lua: " .. err .. "\n")
    log_file:close()
    return
end

-- Ensure the function conky_vars exists and call it to initialize variables
if conky_vars then
    conky_vars()
else
    print("conky_vars function is not defined in settings.lua")
end

-- Parse a border color string like "0,0xRRGGBB,alpha,..." into a gradient table
local function parse_border_color(border_color_str)
    local gradient = {}
    for position, color, alpha in border_color_str:gmatch("([%d%.]+),0x(%x+),([%d%.]+)") do
        table.insert(gradient, {tonumber(position), tonumber(color, 16), tonumber(alpha)})
    end
    -- Return a default gradient if parsing fails
    if #gradient == 3 then
        return gradient
    end
    return { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} }
end

-- Parse a background color string like "0xRRGGBB,alpha" into a table
local function parse_bg_color(bg_color_str)
    local hex, alpha = bg_color_str:match("0x(%x+),([%d%.]+)")
    if hex and alpha then
        return { {1, tonumber(hex, 16), tonumber(alpha)} }
    end
    -- Fallback to solid black if parsing fails
    return { {1, 0x000000, 1} }
end

-- Read color values from settings.lua variables
local border_color = parse_border_color(border_COLOR)
local bg_color = parse_bg_color(bg_COLOR)

-- UI box definitions with their drawing properties
local boxes_settings = {
    {
        type = "base",
        x = 2, y = 2, w = 254, h = 128,
        colour = bg_color,
        corners = { {0, 0, 20, 20} }, -- top left, top right, bottom right, bottom left
        draw_me = true,
    },
    {
        type = "border",
        x = 2, y = 2, w = 254, h = 128,
        colour = border_color,
        linear_gradient = {0, 64, 254, 64},
        corners = { {0, 0, 20, 20} }, -- Same corner styling as above
        border = 4,
        draw_me = true,
    },
}

-- Draw a rectangle with **independent** corner radii
local function draw_custom_corners(cr, x, y, w, h, corners)
    local tl, tr, br, bl = table.unpack(corners)

    cairo_new_path(cr)
    cairo_move_to(cr, x + tl, y)
    cairo_line_to(cr, x + w - tr, y)
    cairo_arc(cr, x + w - tr, y + tr, tr, -math.pi/2, 0)
    cairo_line_to(cr, x + w, y + h - br)
    cairo_arc(cr, x + w - br, y + h - br, br, 0, math.pi/2)
    cairo_line_to(cr, x + bl, y + h)
    cairo_arc(cr, x + bl, y + h - bl, bl, math.pi/2, math.pi)
    cairo_line_to(cr, x, y + tl)
    cairo_arc(cr, x + tl, y + tl, tl, math.pi, 3*math.pi/2)
    cairo_close_path(cr)
end

-- Main drawing function to be called by Conky
function conky_draw_background()
    if conky_window == nil then return end

    -- Create Cairo context based on Conky window
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    -- Draw each box based on its type
    for _, box in ipairs(boxes_settings) do
        if box.draw_me then
            local corners = box.corners[1] -- corners = { TL, TR, BR, BL }

            if box.type == "base" then
                local r, g, b = ((box.colour[1][2] >> 16) & 0xFF) / 255, ((box.colour[1][2] >> 8) & 0xFF) / 255, (box.colour[1][2] & 0xFF) / 255
                cairo_set_source_rgba(cr, r, g, b, box.colour[1][3])
                draw_custom_corners(cr, box.x, box.y, box.w, box.h, corners)
                cairo_fill(cr)

            elseif box.type == "border" then
                local gradient = cairo_pattern_create_linear(table.unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    local r, g, b = ((color[2] >> 16) & 0xFF) / 255, ((color[2] >> 8) & 0xFF) / 255, (color[2] & 0xFF) / 255
                    cairo_pattern_add_color_stop_rgba(gradient, color[1], r, g, b, color[3])
                end
                cairo_set_source(cr, gradient)
                cairo_set_line_width(cr, box.border)
                draw_custom_corners(cr, box.x + box.border/2, box.y + box.border/2, box.w - box.border, box.h - box.border, {
                    math.max(0, corners[1] - box.border/2),
                    math.max(0, corners[2] - box.border/2),
                    math.max(0, corners[3] - box.border/2),
                    math.max(0, corners[4] - box.border/2)
                })
                cairo_stroke(cr)
                cairo_pattern_destroy(gradient)
            end
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
