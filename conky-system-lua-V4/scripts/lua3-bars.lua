--[[
  #########################
  # conky-system-lua-V3   #
  # by +WillemO @wim66    #
  # v1.5 23-dec-17        #
  # Aangepast door Grok 3 #
  # (xAI) op 01-mrt-2025  #
  #########################
]]

--[[ BARGRAPH WIDGET
	v2.1 by wlourf (07 Jan. 2011)
	this widget draws a bargraph with different effects 
	http://u-scripts.blogspot.com/2010/07/bargraph-widget.html
	
To call the script in a conky, use, before TEXT
	lua_load /path/to/the/script/bargraph.lua
	lua_draw_hook_pre main_rings
and add one line (blank or not) after TEXT

	
Parameters are :
3 parameters are mandatory
name	- the name of the conky variable to display, for example for {$cpu cpu0}, just write name="cpu"
arg		- the argument of the above variable, for example for {$cpu cpu0}, just write arg="cpu0"
		  arg can be a numerical value if name=""
max		- the maximum value the above variable can reach, for example, for {$cpu cpu0}, just write max=100
	
Optional parameters:
x,y		- coordinates of the starting point of the bar, default = middle of the conky window
cap		- end of cap line, ossibles values are r,b,s (for round, butt, square), default="b"
		  http://www.cairographics.org/samples/set_line_cap/
angle	- angle of rotation of the bar in degress, default = 0 (i.e. a vertical bar)
		  set to 90 for an horizontal bar
skew_x	- skew bar around x axis, default = 0
skew_y	- skew bar around y axis, default = 0
blocks  - number of blocks to display for a bar (values >0) , default= 10
height	- height of a block, default=10 pixels
width	- width of a block, default=20 pixels
space	- space between 2 blocks, default=2 pixels
angle_bar	- this angle is used to draw a bar on a circular way (ok, this is no more a bar !) default=0
radius		- for cicular bars, internal radius, default=0
			  with radius, parameter width has no more effect.

Colours below are defined into braces {colour in hexadecimal, alpha}
fg_colour	- colour of a block ON, default= {0x00FF00,1}
bg_colour	- colour of a block OFF, default = {0x00FF00,0.5}
alarm		- threshold, values after this threshold will use alarm_colour colour , default=max
alarm_colour - colour of a block greater than alarm, default=fg_colour
smooth		- (true or false), create a gradient from fg_colour to bg_colour, default=false 
mid_colour	- colours to add to gradient, with this syntax {position into the gradient (0 to1), colour hexa, alpha}
			  for example, this table {{0.25,0xff0000,1},{0.5,0x00ff00,1},{0.75,0x0000ff,1}} will add
			  3 colurs to gradient created by fg_colour and alarm_colour, default=no mid_colour
led_effect	- add LED effects to each block, default=no led_effect
			  if smooth=true, led_effect is not used
			  possibles values : "r","a","e" for radial, parallelel, perdendicular to the bar (just try!)
			  led_effect has to be used with theses colours :
fg_led		- middle colour of a block ON, default = fg_colour
bg_led		- middle colour of a block OFF, default = bg_colour
alarm_led	- middle colour of a block > ALARM,  default = alarm_colour

reflection parameters, not avaimable for circular bars
reflection_alpha    - add a reflection effect (values from 0 to 1) default = 0 = no reflection
                      other values = starting opacity
reflection_scale    - scale of the reflection (default = 1 = height of text)
reflection_length   - length of reflection, define where the opacity will be set to zero
					  calues from 0 to 1, default =1
reflection			- position of reflection, relative to a vertical bar, default="b"
					  possibles values are : "b","t","l","r" for bottom, top, left, right
draw_me     - if set to false, text is not drawn (default = true or 1)
              it can be used with a conky string, if the string returns 1, the text is drawn :
              example : "${if_empty ${wireless_essid wlan0}}${else}1$endif",

v1.0 (10 Feb. 2010) original release
v1.1 (13 Feb. 2010) numeric values can be passed instead conky stats with parameters name="", arg = numeric_value	
v1.2 (28 Feb. 2010) just renamed the widget to bargraph
v1.3 (03 Mar. 2010) added parameters radius & angle_bar to draw the bar in a circular way
v2.0 (12 Jul. 2010) rewrite script + add reflection effects and parameters are now set into tables
v2.1 (07 Jan. 2011) Add draw_me parameter and correct memory leaks, thanks to "Creamy Goodness"

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

-- Hulpfunctie om tabellen samen te voegen (defaultwaarden met gebruikersinstellingen)
local function merge_tables(defaults, user_settings)
  local result = {}
  for k, v in pairs(defaults) do result[k] = v end
  for k, v in pairs(user_settings) do result[k] = v end
  return result
end

-- Gecentraliseerde standaardwaarden voor bargraph-instellingen
local defaults = {
  x = conky_window and conky_window.width / 2 or 0,    -- Standaard x-positie (midden van venster)
  y = conky_window and conky_window.height / 2 or 0,   -- Standaard y-positie (midden van venster)
  blocks = 10,                                         -- Aantal blokken in de bar
  height = 10,                                         -- Hoogte van elk blok
  width = 20,                                          -- Breedte van elk blok
  space = 2,                                           -- Ruimte tussen blokken
  angle = 0,                                           -- Rotatiehoek van de bar (graden)
  cap = "b",                                           -- Lijnkap: "b" (butt), "r" (round), "s" (square)
  bg_colour = {0x00FF00, 0.5},                         -- Achtergrondkleur (groen, halve opacity)
  fg_colour = {0x00FF00, 1},                           -- Voorgrondkleur (groen, volle opacity)
  alarm_colour = nil,                                   -- Alarmkleur (valt terug naar fg_colour)
  smooth = false,                                      -- Gradiënt-effect inschakelen
  led_effect = nil,                                    -- LED-effect: "r", "a", "e" of nil
  radius = 0,                                          -- Straal voor circulaire bars
  angle_bar = 0,                                       -- Hoek voor circulaire bars
  skew_x = 0,                                          -- Scheefheid op x-as
  skew_y = 0,                                          -- Scheefheid op y-as
  reflection_alpha = 0,                                -- Transparantie van reflectie
  reflection_length = 1,                               -- Lengte van reflectie
  reflection_scale = 1                                 -- Schaal van reflectie
}

-- Hoofdfunctie die de bars tekent
function conky_main_bars()
  local bars_settings = {
    -- CPU-gebruik voor cpu0
    {
      name = "cpu",
      arg = "cpu0",
      max = 100,
      alarm = 90,
      bg_colour = {0xE6E6E6, 0.3},
      fg_colour = {0x00FF00, 1},
      mid_colour = {{0.25, 0x137333, 1}, {0.8, 0x083015, 1}, {0.9, 0xFF0000, 1}},
      alarm_colour = {0xff0000, 0.5},
      smooth = true,
      led_effect = "r",
      x = 26, y = 136,
      height = 10, width = 0,
      blocks = 20,
      space = 1,
      cap = "r",
      angle = 90,
    },
    -- Geheugengebruik in percentage
    {
      name = "memperc",
      arg = '',
      max = 100,
      alarm = 90,
      bg_colour = {0xE6E6E6, 0.3},
      fg_colour = {0x00FF00, 1},
      mid_colour = {{0.25, 0x137333, 1}, {0.8, 0x083015, 1}, {0.9, 0xFF0000, 1}},
      alarm_colour = {0xff0000, 0.5},
      smooth = true,
      led_effect = "r",
      x = 20, y = 230,
      height = 5, width = 15,
      blocks = 32,
      space = 2,
      cap = "r",
      angle = 90,
    },
    -- Gebruik van root-filesystem (/)
    {
      name = "fs_used_perc",
      arg = "/",
      max = 100,
      bg_colour = {0x005C00, 0.15},
      fg_colour = {0x005C00, 1},
      x = 25, y = 298,
      blocks = 17,
      space = 1,
      height = 12, width = 12,
      angle = 90,
      led_effect = "r",
      bg_led = {0x00ff00, 0.5},
      fg_led = {0x02FA02, 1},
    },
    -- Gebruik van /home filesystem
    {
      name = "fs_used_perc",
      arg = "/home/",
      max = 100,
      bg_colour = {0x005C00, 0.15},
      fg_colour = {0x005C00, 1},
      x = 25, y = 332,
      blocks = 17,
      space = 1,
      height = 12, width = 12,
      angle = 90,
      led_effect = "r",
      bg_led = {0x00ff00, 0.5},
      fg_led = {0x02FA02, 1},
    },
  }
  
  if conky_window == nil then return end
  
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  cr = cairo_create(cs)
  
  -- Wacht tot Conky een paar updates heeft uitgevoerd om segmentatiefouten te voorkomen
  if tonumber(conky_parse('${updates}')) > 3 then
    for i in pairs(bars_settings) do
      draw_multi_bar_graph(bars_settings[i])
    end
  end
  
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
  cr = nil
end

-- Functie om een bargraph te tekenen met meerdere blokken of een enkele balk
function draw_multi_bar_graph(t)
  cairo_save(cr)
  
  -- Combineer standaardwaarden met gebruikersinstellingen
  t = merge_tables(defaults, t)
  
  -- Controleer of de bar getekend moet worden
  if t.draw_me == true then t.draw_me = nil end
  if t.draw_me ~= nil and conky_parse(tostring(t.draw_me)) ~= "1" then return end    
  if t.name == nil and t.arg == nil then 
    print("No input values ... use parameters 'name' with 'arg' or only parameter 'arg'") 
    return
  end
  if t.max == nil then
    print("No maximum value defined, use 'max'")
    return
  end
  if t.name == nil then t.name = "" end
  if t.arg == nil then t.arg = "" end

  -- Stel lijnkap en delta in voor ronde of vierkante uiteinden
  local cap = "b"
  for i, v in ipairs({"s", "r", "b"}) do 
    if v == t.cap then cap = v end
  end
  local delta = 0
  if t.cap == "r" or t.cap == "s" then delta = t.height end
  if cap == "s" then cap = CAIRO_LINE_CAP_SQUARE
  elseif cap == "r" then cap = CAIRO_LINE_CAP_ROUND
  elseif cap == "b" then cap = CAIRO_LINE_CAP_BUTT
  end

  -- Valideer en stel kleuren in
  if #t.bg_colour ~= 2 then t.bg_colour = {0x00FF00, 0.5} end
  if #t.fg_colour ~= 2 then t.fg_colour = {0x00FF00, 1} end
  if t.alarm_colour == nil then t.alarm_colour = t.fg_colour end
  if #t.alarm_colour ~= 2 then t.alarm_colour = t.fg_colour end

  if t.mid_colour ~= nil then    
    for i = 1, #t.mid_colour do    
      if #t.mid_colour[i] ~= 3 then 
        print("error in mid_color table")
        t.mid_colour[i] = {1, 0xFFFFFF, 1} 
      end
    end
  end
  
  if t.bg_led ~= nil and #t.bg_led ~= 2 then t.bg_led = t.bg_colour end
  if t.fg_led ~= nil and #t.fg_led ~= 2 then t.fg_led = t.fg_colour end
  if t.alarm_led ~= nil and #t.alarm_led ~= 2 then t.alarm_led = t.fg_led end
  
  if t.led_effect ~= nil then
    if t.bg_led == nil then t.bg_led = t.bg_colour end
    if t.fg_led == nil then t.fg_led = t.fg_colour end
    if t.alarm_led == nil then t.alarm_led = t.fg_led end
  end

  if t.alarm == nil then t.alarm = t.max end
  t.angle = t.angle * math.pi / 180
  t.angle_bar = t.angle_bar * math.pi / 360
  t.skew_x = math.pi * t.skew_x / 180
  t.skew_y = math.pi * t.skew_y / 180

  -- Converteer hex-kleur naar RGBA
  local function rgb_to_r_g_b(col_a)
    return ((col_a[1] / 0x10000) % 0x100) / 255., ((col_a[1] / 0x100) % 0x100) / 255., (col_a[1] % 0x100) / 255., col_a[2]
  end
  
  -- Maak een lineaire gradiënt voor smooth-effect
  local function create_smooth_linear_gradient(x0, y0, x1, y1)
    local pat = cairo_pattern_create_linear(x0, y0, x1, y1)
    cairo_pattern_add_color_stop_rgba(pat, 0, rgb_to_r_g_b(t.fg_colour))
    cairo_pattern_add_color_stop_rgba(pat, 1, rgb_to_r_g_b(t.alarm_colour))
    if t.mid_colour ~= nil then
      for i = 1, #t.mid_colour do
        cairo_pattern_add_color_stop_rgba(pat, t.mid_colour[i][1], rgb_to_r_g_b({t.mid_colour[i][2], t.mid_colour[i][3]}))
      end
    end
    return pat
  end

  -- Maak een radiale gradiënt voor smooth-effect
  local function create_smooth_radial_gradient(x0, y0, r0, x1, y1, r1)
    local pat = cairo_pattern_create_radial(x0, y0, r0, x1, y1, r1)
    cairo_pattern_add_color_stop_rgba(pat, 0, rgb_to_r_g_b(t.fg_colour))
    cairo_pattern_add_color_stop_rgba(pat, 1, rgb_to_r_g_b(t.alarm_colour))
    if t.mid_colour ~= nil then
      for i = 1, #t.mid_colour do
        cairo_pattern_add_color_stop_rgba(pat, t.mid_colour[i][1], rgb_to_r_g_b({t.mid_colour[i][2], t.mid_colour[i][3]}))
      end
    end
    return pat
  end
  
  -- Maak een lineaire LED-gradiënt
  local function create_led_linear_gradient(x0, y0, x1, y1, col_alp, col_led)
    local pat = cairo_pattern_create_linear(x0, y0, x1, y1)
    cairo_pattern_add_color_stop_rgba(pat, 0.0, rgb_to_r_g_b(col_alp))
    cairo_pattern_add_color_stop_rgba(pat, 0.5, rgb_to_r_g_b(col_led))
    cairo_pattern_add_color_stop_rgba(pat, 1.0, rgb_to_r_g_b(col_alp))
    return pat
  end

  -- Maak een radiale LED-gradiënt
  local function create_led_radial_gradient(x0, y0, r0, x1, y1, r1, col_alp, col_led, mode)
    local pat = cairo_pattern_create_radial(x0, y0, r0, x1, y1, r1)
    if mode == 3 then
      cairo_pattern_add_color_stop_rgba(pat, 0, rgb_to_r_g_b(col_alp))                
      cairo_pattern_add_color_stop_rgba(pat, 0.5, rgb_to_r_g_b(col_led))
      cairo_pattern_add_color_stop_rgba(pat, 1, rgb_to_r_g_b(col_alp))                
    else
      cairo_pattern_add_color_stop_rgba(pat, 0, rgb_to_r_g_b(col_led))
      cairo_pattern_add_color_stop_rgba(pat, 1, rgb_to_r_g_b(col_alp))                
    end
    return pat
  end

  -- Teken een enkele balk (voor blocks=1)
  local function draw_single_bar(pct)
    local function create_pattern(col_alp, col_led, bg)
      local pat
      if not t.smooth then
        if t.led_effect == "e" then
          pat = create_led_linear_gradient(-delta, 0, delta + t.width, 0, col_alp, col_led)
        elseif t.led_effect == "a" then
          pat = create_led_linear_gradient(t.width / 2, 0, t.width / 2, -t.height, col_alp, col_led)
        elseif t.led_effect == "r" then
          pat = create_led_radial_gradient(t.width / 2, -t.height / 2, 0, t.width / 2, -t.height / 2, t.height / 1.5, col_alp, col_led, 2)
        else
          pat = cairo_pattern_create_rgba(rgb_to_r_g_b(col_alp))
        end
      else
        if bg then
          pat = cairo_pattern_create_rgba(rgb_to_r_g_b(t.bg_colour))
        else
          pat = create_smooth_linear_gradient(t.width / 2, 0, t.width / 2, -t.height)
        end
      end
      return pat
    end
    
    local y1 = -t.height * pct / 100
    local y2, y3
    if pct > (100 * t.alarm / t.max) then 
      y1 = -t.height * t.alarm / 100
      y2 = -t.height * pct / 100
      if t.smooth then y1 = y2 end
    end
    
    if t.angle_bar == 0 then
      local pat = create_pattern(t.fg_colour, t.fg_led, false)
      cairo_set_source(cr, pat)
      cairo_rectangle(cr, 0, 0, t.width, y1)
      cairo_fill(cr)
      cairo_pattern_destroy(pat)
    
      if not t.smooth and y2 ~= nil then 
        pat = create_pattern(t.alarm_colour, t.alarm_led, false)
        cairo_set_source(cr, pat)
        cairo_rectangle(cr, 0, y1, t.width, y2 - y1)
        cairo_fill(cr)
        y3 = y2
        cairo_pattern_destroy(pat)
      else
        y2, y3 = y1, y1
      end
      cairo_rectangle(cr, 0, y2, t.width, -t.height - y3)
      pat = create_pattern(t.bg_colour, t.bg_led, true)
      cairo_set_source(cr, pat)
      cairo_pattern_destroy(pat)
      cairo_fill(cr)
    end        
  end

  -- Teken meerdere blokken (voor blocks > 1)
  local function draw_multi_bar(pct, pcb)
    for pt = 1, t.blocks do 
      local y1 = -(pt - 1) * (t.height + t.space)
      local light_on = false
      
      local col_alp = t.bg_colour
      local col_led = t.bg_led
      if pct >= (100 / t.blocks) or pct > 0 then
        if pct >= (pcb * (pt - 1)) then 
          light_on = true
          col_alp = t.fg_colour
          col_led = t.fg_led
          if pct >= (100 * t.alarm / t.max) and (pcb * pt) > (100 * t.alarm / t.max) then 
            col_alp = t.alarm_colour 
            col_led = t.alarm_led 
          end
        end
      end

      local pat 
      if not t.smooth then
        if t.angle_bar == 0 then
          if t.led_effect == "e" then
            pat = create_led_linear_gradient(-delta, 0, delta + t.width, 0, col_alp, col_led)
          elseif t.led_effect == "a" then
            pat = create_led_linear_gradient(t.width / 2, -t.height / 2 + y1, t.width / 2, 0 + t.height / 2 + y1, col_alp, col_led)                    
          elseif t.led_effect == "r" then
            pat = create_led_radial_gradient(t.width / 2, y1, 0, t.width / 2, y1, t.width / 1.5, col_alp, col_led, 2)    
          else
            pat = cairo_pattern_create_rgba(rgb_to_r_g_b(col_alp))
          end
        else
          if t.led_effect == "a" then
            pat = create_led_radial_gradient(0, 0, t.radius + (t.height + t.space) * (pt - 1),
                                            0, 0, t.radius + (t.height + t.space) * (pt),                         
                                            col_alp, col_led, 3)    
          else
            pat = cairo_pattern_create_rgba(rgb_to_r_g_b(col_alp))                    
          end
        end
      else
        if light_on then
          if t.angle_bar == 0 then
            pat = create_smooth_linear_gradient(t.width / 2, t.height / 2, t.width / 2, -(t.blocks - 0.5) * (t.height + t.space))
          else
            pat = create_smooth_radial_gradient(0, 0, (t.height + t.space), 0, 0, (t.blocks + 1) * (t.height + t.space), 2)
          end
        else        
          pat = cairo_pattern_create_rgba(rgb_to_r_g_b(t.bg_colour))
        end
      end
      cairo_set_source(cr, pat)
      cairo_pattern_destroy(pat)

      if t.angle_bar == 0 then
        cairo_move_to(cr, 0, y1)
        cairo_line_to(cr, t.width, y1)
      else        
        cairo_arc(cr, 0, 0,
                  t.radius + (t.height + t.space) * (pt) - t.height / 2,
                  -t.angle_bar - math.pi / 2,
                  t.angle_bar - math.pi / 2)
      end
      cairo_stroke(cr)
    end    
  end
  
  -- Stel de bargraph in en teken deze
  local function setup_bar_graph()
    if t.blocks ~= 1 then t.y = t.y - t.height / 2 end
    
    local value = 0
    if t.name ~= "" then
      value = tonumber(conky_parse(string.format('${%s %s}', t.name, t.arg)))
    else
      value = tonumber(t.arg)
    end

    if value == nil then value = 0 end
    
    local pct = 100 * value / t.max
    local pcb = 100 / t.blocks
    
    cairo_set_line_width(cr, t.height)
    cairo_set_line_cap(cr, cap)
    cairo_translate(cr, t.x, t.y)
    cairo_rotate(cr, t.angle)

    local matrix0 = cairo_matrix_t:create()
    tolua.takeownership(matrix0)
    cairo_matrix_init(matrix0, 1, t.skew_y, t.skew_x, 1, 0, 0)
    cairo_transform(cr, matrix0)

    if t.blocks == 1 and t.angle_bar == 0 then
      draw_single_bar(pct)
      if t.reflection == "t" or t.reflection == "b" then cairo_translate(cr, 0, -t.height) end
    else
      draw_multi_bar(pct, pcb)
    end

    -- Voeg reflectie toe indien ingesteld
    if t.reflection_alpha > 0 and t.angle_bar == 0 then
      local pat2
      local matrix1 = cairo_matrix_t:create()
      tolua.takeownership(matrix1)
      if t.angle_bar == 0 then
        pts = {-delta / 2, (t.height + t.space) / 2, t.width + delta, -(t.height + t.space) * (t.blocks)}
        if t.reflection == "t" then
          cairo_matrix_init(matrix1, 1, 0, 0, -t.reflection_scale, 0, -(t.height + t.space) * (t.blocks - 0.5) * 2 * (t.reflection_scale + 1) / 2)
          pat2 = cairo_pattern_create_linear(t.width / 2, -(t.height + t.space) * (t.blocks), t.width / 2, (t.height + t.space) / 2)
        elseif t.reflection == "r" then
          cairo_matrix_init(matrix1, -t.reflection_scale, 0, 0, 1, delta + 2 * t.width, 0)
          pat2 = cairo_pattern_create_linear(delta / 2 + t.width, 0, -delta / 2, 0)
        elseif t.reflection == "l" then
          cairo_matrix_init(matrix1, -t.reflection_scale, 0, 0, 1, -delta, 0)
          pat2 = cairo_pattern_create_linear(-delta / 2, 0, delta / 2 + t.width, -0)
        else
          cairo_matrix_init(matrix1, 1, 0, 0, -1 * t.reflection_scale, 0, (t.height + t.space) * (t.reflection_scale + 1) / 2)
          pat2 = cairo_pattern_create_linear(t.width / 2, (t.height + t.space) / 2, t.width / 2, -(t.height + t.space) * (t.blocks))
        end
      end
      cairo_transform(cr, matrix1)

      if t.blocks == 1 and t.angle_bar == 0 then
        draw_single_bar(pct)
        cairo_translate(cr, 0, -t.height / 2) 
      else
        draw_multi_bar(pct, pcb)
      end
      
      cairo_set_line_width(cr, 0.01)
      cairo_pattern_add_color_stop_rgba(pat2, 0, 0, 0, 0, 1 - t.reflection_alpha)
      cairo_pattern_add_color_stop_rgba(pat2, t.reflection_length, 0, 0, 0, 1)
      if t.angle_bar == 0 then
        cairo_rectangle(cr, pts[1], pts[2], pts[3], pts[4])
      end
      cairo_clip_preserve(cr)
      cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
      cairo_stroke(cr)
      cairo_mask(cr, pat2)
      cairo_pattern_destroy(pat2)
      cairo_set_operator(cr, CAIRO_OPERATOR_OVER)
    end
  end
  
  setup_bar_graph()
  cairo_restore(cr)
end
