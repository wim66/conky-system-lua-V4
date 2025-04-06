-- conky-clock-lua V4
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

require 'cairo'
require 'cairo_xlib'

function conky_draw_text()
    if conky_window == nil then return end
    
    local w = conky_window.width
    local h = conky_window.height
    local xc = w / 2
    local yc = h / 2
    local color1 = {{0, 0xE7660B, 1}}
    local color2 = {{0, 0xFAAD3E, 1}}
    local color3 = {{0, 0xDCE142, 1}}

    local text_settings = {
        {
            text = conky_parse("${time %A}"),
            font_name = "Candlescript Demo Version",
            font_size = 44,
            h_align = "r",
            v_align = "m",
            bold = false,
            x = 248,
            y = 56,
            orientation = "nn",
            colour = {{0, 0x000000, 0.5}},
        },
        {
            text = conky_parse("${time %A}"),
            font_name = "Candlescript Demo Version",
            font_size = 44,
            h_align = "r",
            v_align = "m",
            bold = false,
            x = 244,
            y = 52,
            colour = color1,
        },
        {
            text = conky_parse("${time %d %B}"),
            font_size = 18,
            h_align = "r",
            v_align = "m",
            bold = false,
            x = 237,
            y = 91,
            orientation = "nn",
            colour = {{0, 0x000000, 0.5}},
        },
        {
            text = conky_parse("${time %d %B}"),
            font_size = 18,
            h_align = "r",
            v_align = "m",
            bold = false,
            x = 234,
            y = 88,
            orientation = "nn",
            colour = color2,
        },
    }

    if tonumber(conky_parse("$updates")) < 3 then return end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    
    for i, v in pairs(text_settings) do
        local cr = cairo_create(cs)
        display_text(v)
        cairo_destroy(cr)
    end
    
    cairo_surface_destroy(cs)
end

function rgb_to_r_g_b2(tcolour)
    local colour, alpha = tcolour[2], tcolour[3]
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

function display_text(t)
    if t.draw_me == true then t.draw_me = nil end
    if t.draw_me ~= nil and conky_parse(tostring(t.draw_me)) ~= "1" then return end

    -- Set default values if needed
    t.text = t.text or "Conky is good for you !"
    t.x = t.x or conky_window.width / 2
    t.y = t.y or conky_window.height / 2
    t.colour = t.colour or {{1, 0xFFFFFF, 1}}
    t.font_name = t.font_name or use_FONT
    t.font_size = t.font_size or 14
    t.angle = t.angle or 0
    t.italic = t.italic or false
    t.oblique = t.oblique or false
    t.bold = t.bold or false
    t.radial = t.radial and #t.radial == 6 and t.radial or nil
    t.orientation = t.orientation or "ww"
    t.h_align = t.h_align or "l"
    t.v_align = t.v_align or "b"
    t.reflection_alpha = t.reflection_alpha or 0
    t.reflection_length = t.reflection_length or 1
    t.reflection_scale = t.reflection_scale or 1
    t.skew_x = t.skew_x or 0
    t.skew_y = t.skew_y or 0

    cairo_translate(cr, t.x, t.y)
    cairo_rotate(cr, t.angle * math.pi / 180)
    cairo_save(cr)

    local slant = t.italic and CAIRO_FONT_SLANT_ITALIC or CAIRO_FONT_SLANT_NORMAL
    local weight = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL

    cairo_select_font_face(cr, t.font_name, slant, weight)
    cairo_set_font_size(cr, t.font_size)

    local te = cairo_text_extents_t:create()
    tolua.takeownership(te)
    t.text = conky_parse(t.text)
    cairo_text_extents(cr, t.text, te)

    set_pattern(te, t.colour)

    local mx, my = calculate_alignment_offsets(t, te)
    cairo_move_to(cr, mx, my)
    cairo_show_text(cr, t.text)

    if t.reflection_alpha ~= 0 then
        draw_reflection(t, te, mx, my)
    end
end

function set_pattern(te, colours)
    if #colours == 1 then
        cairo_set_source_rgba(cr, rgb_to_r_g_b2(colours[1]))
    else
        local pat = t.radial and cairo_pattern_create_radial(t.radial[1], t.radial[2], t.radial[3], t.radial[4], t.radial[5], t.radial[6]) or
                    cairo_pattern_create_linear(linear_orientation(te))
        for i = 1, #colours do
            cairo_pattern_add_color_stop_rgba(pat, colours[i][1], rgb_to_r_g_b2(colours[i]))
        end
        cairo_set_source(cr, pat)
        cairo_pattern_destroy(pat)
    end
end

function calculate_alignment_offsets(t, te)
    local mx, my = 0, 0
    if t.h_align == "c" then
        mx = -te.width / 2 - te.x_bearing
    elseif t.h_align == "r" then
        mx = -te.width
    end
    if t.v_align == "m" then
        my = -te.height / 2 - te.y_bearing
    elseif t.v_align == "t" then
        my = -te.y_bearing
    end
    return mx, my
end

function draw_reflection(t, te, mx, my)
    local matrix1 = cairo_matrix_t:create()
    tolua.takeownership(matrix1)
    cairo_set_font_size(cr, t.font_size)
    cairo_matrix_init(matrix1, 1, 0, 0, -t.reflection_scale, 0, (te.height + te.y_bearing + my) * (1 + t.reflection_scale))
    cairo_transform(cr, matrix1)
    set_pattern(te, t.colour)
    cairo_move_to(cr, mx, my)
    cairo_show_text(cr, t.text)

    local pat2 = cairo_pattern_create_linear(0, (te.y_bearing + te.height + my), 0, te.y_bearing + my)
    cairo_pattern_add_color_stop_rgba(pat2, 0, 1, 0, 0, 1 - t.reflection_alpha)
    cairo_pattern_add_color_stop_rgba(pat2, t.reflection_length, 0, 0, 0, 1)

    cairo_set_line_width(cr, 1)
    local dy = te.x_bearing
    if dy < 0 then dy = -dy end
    cairo_rectangle(cr, mx + te.x_bearing, te.y_bearing + te.height + my, te.width + dy, -te.height * 1.05)
    cairo_clip_preserve(cr)
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
    cairo_mask(cr, pat2)
    cairo_pattern_destroy(pat2)
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
end

function linear_orientation(te)
    local xb, yb = te.x_bearing, te.y_bearing
    if t.h_align == "c" then
        xb = xb - te.width / 2
    elseif t.h_align == "r" then
        xb = xb - te.width
    end
    if t.v_align == "m" then
        yb = -te.height / 2
    elseif t.v_align == "t" then
        yb = 0
    end
    local p
    if t.orientation == "nn" then
        p = {xb + te.width / 2, yb, xb + te.width / 2, yb + te.height}
    elseif t.orientation == "ne" then
        p = {xb + te.width, yb, xb, yb + te.height}
    elseif t.orientation == "ww" then
        p = {xb, te.height / 2, xb + te.width, te.height / 2}
    elseif t.orientation == "se" then
        p = {xb + te.width, yb + te.height, xb, yb}
    elseif t.orientation == "ss" then
        p = {xb + te.width / 2, yb + te.height, xb + te.width / 2, yb}
    elseif t.orientation == "ee" then
        p = {xb + te.width, te.height / 2, xb, te.height / 2}
    elseif t.orientation == "sw" then
        p = {xb, yb + te.height, xb + te.width, yb}
    elseif t.orientation == "nw" then
        p = {xb, yb, xb + te.width, yb + te.height}
    end
    return p
end