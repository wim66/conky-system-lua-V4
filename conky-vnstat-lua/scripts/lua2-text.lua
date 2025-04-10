-- conky-vnstat-lua V4
-- by @wim66
-- v4 6-April-2024

--[[TEXT WIDGET v1.42 by Wlourf 07 Feb. 2011

This widget can drawn texts set in the "text_settings" table with some parameters
http://u-scripts.blogspot.com/2010/06/text-widget.html

To call the script in a conky, use, before TEXT
	lua_load /path/to/the/script/graph.lua
	lua_draw_hook_pre main_graph
and add one line (blank or not) after TEXT

The parameters (all optionals) are :
text        - text to display, default = "Conky is good for you"
              it can be used with conky variables, i.e. text="my cpu1 is ${cpu cpu1} %")
            - coordinates below are relative to top left corner of the conky window
x           - x coordinate of first letter (bottom-left), default = center of conky window
y           - y coordinate of first letter (bottom-left), default = center of conky window
h_align		- horizontal alignement of text relative to point (x,y), default="l"
			  available values are "l": left, "c" : center, "r" : right
v_align		- vertical alignment of text relative to point (x,y), default="b"
			  available values "t" : top, "m" : middle, "b" : bottom
font_name   - name of font to use, default = Free Sans
font_size   - size of font to use, default = 14
italic      - display text in italic (true/false), default=false
oblique     - display text in oblique (true/false), default=false (I don' see the difference with italic!)
bold        - display text in bold (true/false), default=false
angle       - rotation of text in degrees, default = 0 (horizontal)
colour      - table of colours for text, default = plain white {{1,0xFFFFFF,1}}
			  this table contains one or more tables with format {P,C,A}
              P=position of gradient (0 = beginning of text, 1= end of text)
              C=hexadecimal colour 
              A=alpha (opacity) of color (0=invisible,1=opacity 100%)
              Examples :
              for a plain color {{1,0x00FF00,0.5}}
              for a gradient with two colours {{0,0x00FF00,0.5},{1,0x000033,1}}
              or {{0.5,0x00FF00,1},{1,0x000033,1}} -with this one, gradient will start in the middle of the text
              for a gradient with three colours {{0,0x00FF00,0.5},{0.5,0x000033,1},{1,0x440033,1}}
			  and so on ...
orientation	- in case of gradient, "orientation" defines the starting point of the gradient, default="ww"
			  there are 8 available starting points : "nw","nn","ne","ee","se","ss","sw","ww"
			  (n for north, w for west ...)
			  theses 8 points are the 4 corners + the 4 middles of text's outline
			  so a gradient "nn" will go from "nn" to "ss" (top to bottom, parallele to text)
			  a gradient "nw" will go from "nw" to "se" (left-top corner to right-bottom corner)
radial		- define a radial gradient (if present at the same time as "orientation", "orientation" will have no effect)
			  this parameter is a table with 6 numbers : {xa,ya,ra,xb,yb,rb}
			  they define two circle for the gradient :
			  xa, ya, xb and yb are relative to x and y values above
reflection_alpha    - add a reflection effect (values from 0 to 1) default = 0 = no reflection
                      other values = starting opacity
reflection_scale    - scale of the reflection (default = 1 = height of text)
reflection_length   - length of reflection, define where the opacity will be set to zero
					  calues from 0 to 1, default =1
skew_x,skew_y    - skew text around x or y axis
draw_me     - if set to false, text is not drawn (default = true or 1)
              it can be used with a conky string, if the string returns 1, the text is drawn :
              example : "${if_empty ${wireless_essid wlan0}}${else}1$endif",
              


v1.0	07/06/2010, Original release
v1.1	10/06/2010	Add "orientation" parameter
v1.2	15/06/2010  Add "h_align", "v_align" and "radial" parameters
v1.3	25/06/2010  Add "reflection_alpha", "reflection_length", "reflection_scale", 
                    "skew_x" et "skew_y"
v1.4    07/01/2011  Add draw_me parameter and correct memory leaks, thanks to "Creamy Goodness"
                    text is parsed inside the function, not in the array of settings
v1.41   26/01/2011  Correct bug for h_align="c"    
v1.42   09/02/2011  Correct bug for orientation="ee"                

--      This program is free software; you can redistribute it and/or modify
--      it under the terms of the GNU General Public License as published by
--      the Free Software Foundation version 3 (GPLv3)
--     
--      This program is distributed in the hope that it will be useful,
--      but WITHOUT ANY WARRANTY; without even the implied warranty of
--      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--      GNU General Public License for more details.
--     
--      You should have received a copy of the GNU General Public License
--      along with this program; if not, write to the Free Software
--      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
--      MA 02110-1301, USA.		

]]

-- Import the required Cairo libraries
require 'cairo'
-- Try to require the 'cairo_xlib' module safely
local status, cairo_xlib = pcall(require, 'cairo_xlib')

if not status then
    -- If the module is not found, fall back to a dummy table
    -- This dummy table redirects all unknown keys to the global namespace (_G)
    -- This allows usage of global Cairo functions like cairo_xlib_surface_create
    cairo_xlib = setmetatable({}, {
        __index = function(_, k)
            return _G[k]
        end
    })
end

-- Define rgb_to_r_g_b2 function before it is used
local function rgb_to_r_g_b2(tcolour)
    local colour, alpha = tcolour[2], tcolour[3]
    return ((colour / 0x10000) % 0x100) / 255, ((colour / 0x100) % 0x100) / 255, (colour % 0x100) / 255, alpha
end

local function load_vnstat_data()
    conky_parse("${execi 60 scripts/vnstat.sh}")
    local vnstat_lines = {}
    local file = io.open("scripts/vnstat.txt", "r")
    if file then
        for line in file:lines() do
            table.insert(vnstat_lines, line)
        end
        file:close()
    else
        print("Error: Could not open vnstat.txt")
    end
    return vnstat_lines
end

local function create_surface()
    return cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
end

local function display_text(cr, t)
    t.text = t.text or "Conky is good for you!"
    t.x = t.x or conky_window.width / 2
    t.y = t.y or conky_window.height / 2
    t.colour = t.colour or {{0, 0xE7660B, 1}}
    t.font_name = t.font_name or "Dejavu Sans Mono"
    t.font_size = t.font_size or 14
    t.h_align = t.h_align or "l"
    t.v_align = t.v_align or "b"
    t.bold = t.bold or false

    cairo_save(cr)
    cairo_translate(cr, t.x, t.y)
    
    local slant = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    cairo_select_font_face(cr, t.font_name, CAIRO_FONT_SLANT_NORMAL, slant)
    cairo_set_font_size(cr, t.font_size)
    
    local te = cairo_text_extents_t:create()
    tolua.takeownership(te)
    cairo_text_extents(cr, t.text, te)
    
    cairo_set_source_rgba(cr, rgb_to_r_g_b2(t.colour[1]))
    
    local mx = t.h_align == "c" and -te.width / 2 or t.h_align == "r" and -te.width or 0
    local my = t.v_align == "m" and -te.height / 2 or t.v_align == "t" and 0 or -te.y_bearing
    cairo_move_to(cr, mx, my)
    cairo_show_text(cr, t.text)
    
    cairo_restore(cr)
end

function conky_draw_text()
    if conky_window == nil then return end
    if tonumber(conky_parse("$updates")) < 3 then return end
    
    local w = conky_window.width
    local xc = w / 2

    local colors = {
        primary = {{0, 0xE7660B, 1}},
        secondary = {{0, 0xFAAD3E, 1}},
        highlight = {{0, 0xDCE142, 1}},
        success = {{0, 0x42E147, 1}}
    }

    local vnstat_lines = load_vnstat_data()
    
    local text_settings = {
        {text = "VNSTAT", x = 20, y = 30, font_size = 20, colour = colors.primary},
        {text = "network traffic", x = 120, y = 30, font_size = 14, colour = colors.success},
        {text = "Down", h_align = "r", x = 140, y = 50, colour = colors.highlight},
        {text = "Up", h_align = "r", x = 240, y = 50, colour = colors.highlight},
        {text = "Today", x = 20, y = 70, colour = colors.highlight},
        {text = vnstat_lines[1] or "N/A", font_name = "arial", h_align = "r", x = 140, y = 70, colour = colors.secondary},
        {text = vnstat_lines[2] or "N/A", font_name = "arial", h_align = "r", x = 240, y = 70, colour = colors.secondary},
        {text = "Week", x = 20, y = 90, colour = colors.highlight},
        {text = vnstat_lines[3] or "N/A", font_name = "arial", h_align = "r", x = 140, y = 90, colour = colors.secondary},
        {text = vnstat_lines[4] or "N/A", font_name = "arial", h_align = "r", x = 240, y = 90, colour = colors.secondary},
        {text = "Month", x = 20, y = 110, colour = colors.highlight},
        {text = vnstat_lines[5] or "N/A", font_name = "arial", h_align = "r", x = 140, y = 110, colour = colors.secondary},
        {text = vnstat_lines[6] or "N/A", font_name = "arial", h_align = "r", x = 240, y = 110, colour = colors.secondary},
    }

    local cs = create_surface()
    for _, v in pairs(text_settings) do
        local cr = cairo_create(cs)
        display_text(cr, v)
        cairo_destroy(cr)
    end
    cairo_surface_destroy(cs)
end