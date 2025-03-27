-- background.lua
-- by @wim66
-- June 8 2024

-- Zorg ervoor dat je het juiste pad naar settings.lua instelt
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]] -- Haalt het pad van het huidige script op
local parent_path = script_path:match("^(.*[\\/])scripts[\\/].*$")             -- Extraheert het bovenliggende pad tot aan de 'scripts'-map

package.path = package.path .. ";" .. parent_path .. "?.lua"                   -- Voegt het pad toe aan Lua's zoekpad voor modules

-- Probeer settings.lua te laden vanuit de parent directory
local status, err = pcall(function() require("settings") end)                  -- Veilige poging om settings.lua te laden
if not status then
    print("Error loading settings.lua: " .. err)                              -- Geeft een foutmelding als het laden mislukt
end

-- Zorg ervoor dat de conky_vars functie wordt aangeroepen om de variabelen in te stellen
if conky_vars then
    conky_vars()                                                              -- Roept conky_vars aan als deze bestaat in settings.lua
else
    print("conky_vars function is not defined in settings.lua")               -- Waarschuwing als conky_vars niet is gedefinieerd
end

-- Selecteer de kleur op basis van de variabele uit settings.lua
local color_options = {
    green = { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} },     -- Kleurverloop voor rand: donker groen -> fel groen -> donker groen
    orange = { {0, 0xE05700, 1}, {0.5, 0xFFD145, 1}, {1, 0xE05700, 1} },    -- Kleurverloop: oranje -> geel -> oranje
    blue = { {0, 0x0000ba, 1}, {0.5, 0x8cc7ff, 1}, {1, 0x0000ba, 1} },      -- Kleurverloop: donker blauw -> licht blauw -> donker blauw
    black = { {0, 0x2b2b2b, 1}, {0.5, 0xa3a3a3, 1}, {1 ,0x2b2b2b, 1} },    -- Kleurverloop: donkergrijs -> lichtgrijs -> donkergrijs
    red = { {0, 0x5c0000, 1}, {0.5, 0xff0000, 1}, {1 ,0x5c0000, 1} }        -- Kleurverloop: donker rood -> fel rood -> donker rood
}

local bgcolor_options = {
    black_50 = { {1, 0x000000, 0.5} },                                      -- Achtergrond: zwart met 50% transparantie
    black_25 = { {1, 0x000000, 0.25} },                                     -- Achtergrond: zwart met 25% transparantie
    black_75 = { {1, 0x000000, 0.75} },                                     -- Achtergrond: zwart met 75% transparantie
    black_100 = { {1, 0x000000, 1} },                                       -- Achtergrond: volledig ondoorzichtig zwart
    dark_100 = { {1, 0x23263A, 1} },                                        -- Achtergrond: donkere paars/grijze tint, volledig ondoorzichtig
    blue = { {1, 0x0000ba, 0.5} }                                           -- Achtergrond: blauw met 50% transparantie
}

local border_color = color_options[border_COLOR] or color_options.green      -- Kies borderkleur uit settings.lua, fallback naar groen
local bg_color = bgcolor_options[bg_COLOR] or bgcolor_options.black_100      -- Kies achtergrondkleur, fallback naar volledig zwart

local boxes_settings = {
    -- Base background
    {
        type = "base",                                                       -- Type box: achtergrondlaag
        x = 2, y = 2, w = 254, h = 650,                                      -- Positie (x,y) en afmetingen (breedte, hoogte)
        colour = bg_color,                                                   -- Achtergrondkleur uit bgcolor_options
        corners = { {"circle", 15} },                                        -- Afgeronde hoeken met straal 15 pixels
        draw_me = true,                                                      -- Vlag om te tekenen
    },
    -- Border
    {
        type = "border",                                                     -- Type box: randlaag
        x = 2, y = 2, w = 254, h = 650,                                      -- Zelfde positie en afmetingen als achtergrond
        colour = border_color,                                               -- Randkleur met kleurverloop uit color_options
        linear_gradient = {0,325,254,325},                                   -- Gradient van links (0,325) naar rechts (254,325)
        corners = { {"circle", 15} },                                        -- Afgeronde hoeken met straal 15 pixels
        border = 4,                                                          -- Dikte van de rand in pixels
        draw_me = true,                                                      -- Vlag om te tekenen
    },
}

-- Functie om een rechthoek met afgeronde hoeken te tekenen
local function draw_rounded_rectangle(cr, x, y, w, h, r)
    -- Teken een pad voor een rechthoek met afgeronde hoeken
    cairo_new_path(cr)                                                       -- Start een nieuw tekenpad in Cairo
    cairo_move_to(cr, x + r, y)                                              -- Begin bij de bovenkant, iets naar rechts (voor de ronde hoek)
    cairo_line_to(cr, x + w - r, y)                                          -- Teken rechte lijn naar rechts, stop voor de hoek
    cairo_arc(cr, x + w - r, y + r, r, -math.pi/2, 0)                        -- Teken rechterbovenhoek (boog van -90° naar 0°)
    cairo_line_to(cr, x + w, y + h - r)                                      -- Teken rechte lijn naar beneden
    cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi/2)                     -- Teken rechteronderhoek (boog van 0° naar 90°)
    cairo_line_to(cr, x + r, y + h)                                          -- Teken rechte lijn naar links
    cairo_arc(cr, x + r, y + h - r, r, math.pi/2, math.pi)                   -- Teken linksonderhoek (boog van 90° naar 180°)
    cairo_line_to(cr, x, y + r)                                              -- Teken rechte lijn naar boven
    cairo_arc(cr, x + r, y + r, r, math.pi, 3*math.pi/2)                     -- Teken linkerbovenhoek (boog van 180° naar 270°)
    cairo_close_path(cr)                                                     -- Sluit het pad om een volledige vorm te maken
end

function conky_draw_background()
    if conky_window == nil then
        return                                                               -- Stop als er geen Conky-venster beschikbaar is
    end

    -- Maak een Cairo-tekenoppervlak gebaseerd op het Conky-venster
    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)                                              -- Maak een Cairo-context om mee te tekenen

    for _, box in ipairs(boxes_settings) do                                  -- Loop door alle boxen in boxes_settings
        if box.draw_me then                                                  -- Controleer of de box getekend moet worden
            if box.type == "base" then
                -- Teken de achtergrond met een effen kleur
                -- Converteer hex-kleur naar RGBA (rood, groen, blauw, alpha)
                cairo_set_source_rgba(cr, 
                    ((box.colour[1][2] & 0xFF0000) >> 16) / 255,             -- Rood: extracteer bits en normaliseer naar 0-1
                    ((box.colour[1][2] & 0x00FF00) >> 8) / 255,              -- Groen: extracteer bits en normaliseer naar 0-1
                    (box.colour[1][2] & 0x0000FF) / 255,                     -- Blauw: extracteer bits en normaliseer naar 0-1
                    box.colour[1][3])                                        -- Alpha: transparantie (0-1)
                draw_rounded_rectangle(cr, box.x, box.y, box.w, box.h, box.corners[1][2]) -- Teken de afgeronde rechthoek
                cairo_fill(cr)                                               -- Vul de rechthoek met de ingestelde kleur
            elseif box.type == "border" then
                -- Teken de rand met een lineair kleurverloop
                local gradient = cairo_pattern_create_linear(table.unpack(box.linear_gradient)) -- Maak een lineair gradientpatroon
                for _, color in ipairs(box.colour) do                        -- Loop door de kleurstappen van het verloop
                    -- Voeg een kleurstop toe aan het gradientpatroon
                    cairo_pattern_add_color_stop_rgba(gradient, 
                        color[1],                                            -- Positie in het verloop (0-1)
                        ((color[2] & 0xFF0000) >> 16) / 255,                -- Rood
                        ((color[2] & 0x00FF00) >> 8) / 255,                 -- Groen
                        (color[2] & 0x0000FF) / 255,                        -- Blauw
                        color[3])                                            -- Alpha
                end
                cairo_set_source(cr, gradient)                               -- Stel het gradientpatroon in als bron voor tekenen
                cairo_set_line_width(cr, box.border)                         -- Stel de dikte van de rand in
                -- Teken de rand, iets kleiner dan de achtergrond om overlap te vermijden
                draw_rounded_rectangle(cr, 
                    box.x + box.border/2, box.y + box.border/2,              -- Verschuif startpositie met halve borderdikte
                    box.w - box.border, box.h - box.border,                  -- Verklein breedte en hoogte met borderdikte
                    box.corners[1][2] - box.border/2)                       -- Verklein de straal van de hoeken
                cairo_stroke(cr)                                             -- Teken alleen de omtrek (geen vulling)
                cairo_pattern_destroy(gradient)                              -- Ruim het gradientpatroon op om geheugen te besparen
            end
        end
    end

    cairo_destroy(cr)                                                    -- Vernietig de Cairo-context om resources vrij te maken
    cairo_surface_destroy(cs)                                            -- Vernietig het tekenoppervlak
end
