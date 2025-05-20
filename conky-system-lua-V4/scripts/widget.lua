-- widget.lua
-- conky-system-lua V4.1
-- by @wim66
-- May 20, 2025

-- === Required Cairo Modules ===
require 'cairo'
local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = function(_, k) return _G[k] end })
end

-- === Load external modules ===
package.path = "./scripts/?.lua"
local function try_require(modname)
    local ok, err = pcall(require, modname)
    if not ok then
        print("Error loading " .. modname .. ": " .. tostring(err))
        os.exit(1)
    end
end
try_require("lua1-graphs")
try_require("lua2-text")
try_require("lua3-bars")

-- === Load settings.lua from parent directory ===
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])resources[\\/].*$") or ""
package.path = package.path .. ";" .. parent_path .. "?.lua"

local ok, err = pcall(function() require("settings") end)
if not ok then print("Error loading settings.lua: " .. err) os.exit(1) end
if not conky_vars then print("conky_vars function is not defined in settings.lua") os.exit(1) end
conky_vars()

-- === Helpers ===
local unpack = table.unpack or unpack

local function parse_color_gradient(str, default_gradient)
    local gradient = {}
    if type(str) == "string" then
        for position, color, alpha in str:gmatch("([%d%.]+),0x(%x+),([%d%.]+)") do
            table.insert(gradient, {tonumber(position), tonumber(color, 16), tonumber(alpha)})
        end
    end
    return (#gradient >= 3) and gradient or default_gradient
end

local function parse_single_color(str, default_color)
    if type(str) == "string" then
        local hex, alpha = str:match("0x(%x+),([%d%.]+)")
        if hex and alpha then
            return {{1, tonumber(hex, 16), tonumber(alpha)}}
        end
    end
    return default_color
end

local function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end

local function draw_custom_rounded_rectangle(cr, x, y, w, h, r)
    local tl, tr, br, bl = unpack(r)
    cairo_new_path(cr)
    cairo_move_to(cr, x + tl, y)
    cairo_line_to(cr, x + w - tr, y)
    if tr > 0 then cairo_arc(cr, x + w - tr, y + tr, tr, -math.pi/2, 0) else cairo_line_to(cr, x + w, y) end
    cairo_line_to(cr, x + w, y + h - br)
    if br > 0 then cairo_arc(cr, x + w - br, y + h - br, br, 0, math.pi/2) else cairo_line_to(cr, x + w, y + h) end
    cairo_line_to(cr, x + bl, y + h)
    if bl > 0 then cairo_arc(cr, x + bl, y + h - bl, bl, math.pi/2, math.pi) else cairo_line_to(cr, x, y + h) end
    cairo_line_to(cr, x, y + tl)
    if tl > 0 then cairo_arc(cr, x + tl, y + tl, tl, math.pi, 3*math.pi/2) else cairo_line_to(cr, x, y) end
    cairo_close_path(cr)
end

local function get_centered_x(canvas_width, box_width)
    return (canvas_width - box_width) / 2
end

-- === Color values from settings.lua variables ===
local border_color = parse_color_gradient(border_COLOR or "0,0x003E00,1,0.5,0x03F404,1,1,0x003E00,1",
    {{0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1}})
local bg_color = parse_single_color(bg_COLOR or "0x000000,0.5", {{1, 0x000000, 0.5}})
local layer2_color = parse_color_gradient(layer_2 or "0,0x55007f,0.5,0.5,0xff69ff,0.5,1,0x55007f,0.5",
    {{0, 0x55007f, 0.5}, {0.5, 0xff69ff, 0.5}, {1, 0x55007f, 0.5}})

-- === Layout import ===
local layout = require("background-layout")
local boxes_settings = layout.boxes_settings

-- === Main drawing function ===
function conky_draw_background()
    if not conky_window then return end
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    local canvas_width = conky_window.width

    for _, box in ipairs(boxes_settings) do
        if box.draw_me then
            local x, y, w, h = box.x, box.y, box.w, box.h
            if box.centre_x then x = get_centered_x(canvas_width, w) end

            local cx, cy = x + w / 2, y + h / 2
            local angle = (box.rotation or 0) * math.pi / 180

            if box.type == "background" then
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)
                cairo_set_source_rgba(cr, hex_to_rgba(box.colour[1][2], box.colour[1][3]))
                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)
                cairo_restore(cr)
            elseif box.type == "layer2" then
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colours) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)
                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)
                cairo_restore(cr)
                cairo_pattern_destroy(grad)
            elseif box.type == "border" then
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)
                cairo_set_line_width(cr, box.border)
                draw_custom_rounded_rectangle(
                    cr,
                    x + box.border / 2,
                    y + box.border / 2,
                    w - box.border,
                    h - box.border,
                    {
                        math.max(0, box.corners[1] - box.border / 2),
                        math.max(0, box.corners[2] - box.border / 2),
                        math.max(0, box.corners[3] - box.border / 2),
                        math.max(0, box.corners[4] - box.border / 2)
                    }
                )
                cairo_stroke(cr)
                cairo_restore(cr)
                cairo_pattern_destroy(grad)
            end
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

function conky_main()
    conky_draw_background()
    conky_draw_text()
    conky_main_bars()
    conky_draw_graph()
end
