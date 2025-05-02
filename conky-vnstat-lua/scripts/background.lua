-- background.lua
-- by @wim66
-- April 17 2025

-- === Required Cairo Modules ===
require 'cairo'
-- Try to require the 'cairo_xlib' module safely
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

-- === Load settings.lua from parent directory ===
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])resources[\\/].*$") or ""
package.path = package.path .. ";" .. parent_path .. "?.lua"

local status, err = pcall(function() require("settings") end)
if not status then print("Error loading settings.lua: " .. err); return end
if not conky_vars then print("conky_vars function is not defined in settings.lua"); return end
conky_vars()

-- === Utility ===
local unpack = table.unpack or unpack  -- Compatibility for Lua 5.1 and newer

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

-- === All drawable elements ===
local boxes_settings = {
    -- Background
    {
        type = "background",
        x = 0, y = 5, w = 254, h = 128,
        centre_x = true,  -- Optioneel centreren
        corners = {0, 0, 20 ,20},  -- TL, TR, BR, BL
        rotation = 0,  -- Toegevoegd voor rotatiemogelijkheid
        draw_me = true,
        colour = bg_color
    },
    -- Second background layer with linear gradient
    {
        type = "layer2",
        x = 0, y = 5, w = 254, h = 128,
        centre_x = true,
        corners = {0, 0, 20 ,20},  -- TL, TR, BR, BL
        rotation = 0,  -- Toegevoegd voor rotatiemogelijkheid
        draw_me = true,
        linear_gradient = {127, 0, 127, 128}, -- Aangepast aan x en w
        colours = {{0, 0xFFFFFF, 0.05},{0.5, 0xC2C2C2, 0.2},{1, 0xFFFFFF, 0.05}},
    },
    -- Border
    {
        type = "border",
        x = 0, y = 5, w = 254, h = 128,
        centre_x = true,
        corners = {0, 0, 20 ,20},  -- TL, TR, BR, BL
        rotation = 0,  -- Toegevoegd voor rotatiemogelijkheid
        draw_me = true,
        border = 4,
        colour = border_color,
        linear_gradient = {127, 0, 127, 128}  -- Aangepast aan x en w
    }
}

-- === Helper: Convert hex to RGBA ===
local function hex_to_rgba(hex, alpha)
    return ((hex >> 16) & 0xFF) / 255, ((hex >> 8) & 0xFF) / 255, (hex & 0xFF) / 255, alpha
end
-- === Helper: Draw custom rounded rectangle ===
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

-- === Helper: Center X position ===
local function get_centered_x(canvas_width, box_width)
    return (canvas_width - box_width) / 2
end

-- === Main drawing function ===
function conky_draw_background()
    if conky_window == nil then return end

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
                -- Apply rotation for the background
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                cairo_set_source_rgba(cr, hex_to_rgba(box.colour[1][2], box.colour[1][3]))
                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)

                cairo_restore(cr)

            elseif box.type == "layer2" then
                -- Create the gradient in the original coordinate system
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colours) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                -- Apply rotation only to the shape
                cairo_save(cr)
                cairo_translate(cr, cx, cy)
                cairo_rotate(cr, angle)
                cairo_translate(cr, -cx, -cy)

                draw_custom_rounded_rectangle(cr, x, y, w, h, box.corners)
                cairo_fill(cr)

                cairo_restore(cr)
                cairo_pattern_destroy(grad)

            elseif box.type == "border" then
                -- Create the gradient in the original coordinate system
                local grad = cairo_pattern_create_linear(unpack(box.linear_gradient))
                for _, color in ipairs(box.colour) do
                    cairo_pattern_add_color_stop_rgba(grad, color[1], hex_to_rgba(color[2], color[3]))
                end
                cairo_set_source(cr, grad)

                -- Apply rotation only to the shape
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
