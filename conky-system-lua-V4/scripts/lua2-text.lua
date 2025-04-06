-- conky-system-lua V4
-- by @wim66
-- v4 6-April-2024

require 'cairo'
require 'cairo_xlib'

-- Configuration constants
local CONFIG = {
    NET_INTERFACE = var_NETWORK,  -- Set in settings.lua
    FONT_DEFAULT = "Dejavu Sans Mono",
    UPDATE_INTERVAL = 3
}

-- Color definitions
local COLORS = {
    PRIMARY = {{0, 0xE7660B, 1}},
    SECONDARY = {{0, 0xFAAD3E, 1}},
    HIGHLIGHT = {{0, 0xDCE142, 1}},
    SUCCESS = {{0, 0x42E147, 1}},
    PROCESS = {{0, 0x42E147, 1}},  -- Color for process names and CPU usage
    GRADIENT = {{0., 0xE7660B, 1}, {0.5, 0xDCE142, 1}, {1, 0xE7660B, 1}}
}

-- Network variables
local NET_VARS = {
    UP = "${upspeed " .. CONFIG.NET_INTERFACE .. "}",
    DOWN = "${downspeed " .. CONFIG.NET_INTERFACE .. "}",
    TOTAL_UP = "${totalup " .. CONFIG.NET_INTERFACE .. "}",
    TOTAL_DOWN = "${totaldown " .. CONFIG.NET_INTERFACE .. "}"
}

-- Main function
function conky_draw_text()
    local updates = tonumber(conky_parse("$updates")) or 0
    if updates < CONFIG.UPDATE_INTERVAL then 
        return 
    end

    if not conky_window then 
        print("Error: No conky window available")
        return 
    end

    local w, h = conky_window.width, conky_window.height
    local xc = w / 2

    local status, cs = pcall(function()
        return cairo_xlib_surface_create(
            conky_window.display,
            conky_window.drawable,
            conky_window.visual,
            w, h
        )
    end)
    
    if not status then
        error("Error creating cairo surface: " .. cs)
    end

    local text_settings = generate_text_settings(xc)
    
    for _, v in ipairs(text_settings) do    
        local cr = cairo_create(cs)
        display_text(cr, v)
        cairo_destroy(cr)
    end
    
    cairo_surface_destroy(cs)
end

-- Generate text settings
function generate_text_settings(xc)
    return concatenate_tables({
        -- System info
        {{
            text = conky_parse("${if_existing /usr/bin/lsb_release}${execi 10000 lsb_release -d | cut -f 2}${else}$distribution${endif}"),
            font_name = "Dejavu Sans Mono",
            font_size = 22,
            bold = true,
            h_align = "c",
            x = xc,
            y = 25,
            colour = COLORS.GRADIENT
        }, {
            text = conky_parse("$sysname ${kernel}"),
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            x = 20,
            y = 50,
            colour = COLORS.SECONDARY
        }, {
            text = conky_parse("Uptime: ${uptime}"),
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            x = 20,
            y = 67,
            colour = COLORS.SECONDARY
        }},
        
        -- CPU block
        cpu_block(xc),
        
        -- Memory block
        memory_block(xc),
        
        -- Disk block
        disk_block(xc),
        
        -- Network block
        network_block(xc),
        
        -- Processes block
        processes_block(xc),
        
        -- Updates
        updates_block(xc),
        
        -- Bitcoin price
        bitcoin_price_block(xc)
    })
end

-- Helper function to concatenate tables
function concatenate_tables(tables)
    local result = {}
    for _, t in ipairs(tables) do
        if type(t) == "function" then t = t() end
        for _, v in ipairs(t) do
            table.insert(result, v)
        end
    end
    return result
end

-- Block functions
function cpu_block(xc)
    return {
        {
            text = conky_parse("${execi 6000 cat /proc/cpuinfo | grep -i 'Model name' -m 1 | cut -c13- | sed 's/CPU.*$//' | sed 's/  */ /g'}"),
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            x = 12,
            y = 87,
            colour = COLORS.SECONDARY
        },
        {
            text = conky_parse("CPU: ${execi 5 sensors|grep 'Package'|awk '{print $4}'} ${cpu cpu1}%"),
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            bold = true,
            h_align = "c",
            x = xc,
            y = 112,
            colour = COLORS.HIGHLIGHT
        }
    }
end

function memory_block(xc)
    local base_y = 195
    return {
        {text = "Memory", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "c", x = xc, y = base_y + 9, colour = COLORS.HIGHLIGHT},
        {text = "Used", font_name = "Dejavu Sans Mono", font_size = 14, x = 20, y = base_y, colour = COLORS.SECONDARY},
        {text = conky_parse("${mem}"), font_name = "Dejavu Sans Mono", font_size = 14, x = 20, y = base_y + 18, colour = COLORS.SUCCESS},
        {text = "Free", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y, colour = COLORS.SECONDARY},
        {text = conky_parse("${memeasyfree}"), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y + 18, colour = COLORS.SUCCESS}
    }
end

function disk_block(xc)
    local base_y = 261
    return {
        {text = "Disks", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "c", x = xc, y = base_y, colour = COLORS.HIGHLIGHT},
        {text = "Used", font_name = "Dejavu Sans Mono", font_size = 14, x = 20, y = base_y, colour = COLORS.SECONDARY},
        {text = conky_parse("${fs_used /}"), font_name = "Dejavu Sans Mono", font_size = 14, x = 20, y = base_y + 19, colour = COLORS.SUCCESS},
        {text = "ROOT", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "c", x = xc, y = base_y + 19, colour = COLORS.SECONDARY},
        {text = "Free", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y, colour = COLORS.SECONDARY},
        {text = conky_parse("${fs_free /}"), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y + 19, colour = COLORS.SUCCESS},
        {text = "Home", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "c", x = xc, y = base_y + 54, colour = COLORS.SECONDARY},
        {text = conky_parse("${fs_used /home/}"), font_name = "Dejavu Sans Mono", font_size = 14, x = 20, y = base_y + 54, colour = COLORS.SUCCESS},
        {text = conky_parse("${fs_free /home/}"), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y + 54, colour = COLORS.SUCCESS}
    }
end

function network_block(xc)
    local base_y = 355
    return {
        {text = "Network speed", font_name = "Dejavu Sans Mono", font_size = 14, h_align = "c", x = xc, y = base_y, colour = COLORS.HIGHLIGHT},
        {text = "Up", font_name = "Dejavu Sans Mono", font_size = 14, x = 23, y = base_y + 20, colour = COLORS.SECONDARY},
        {text = conky_parse(NET_VARS.UP), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 120, y = base_y + 20, colour = COLORS.SUCCESS},
        {text = "Down", font_name = "Dejavu Sans Mono", font_size = 14, x = 142, y = base_y + 20, colour = COLORS.SECONDARY},
        {text = conky_parse(NET_VARS.DOWN), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y + 20, colour = COLORS.SUCCESS},
        {text = "Session", font_name = "Dejavu Sans Mono", font_size = 14, x = 23, y = base_y + 82, colour = COLORS.SECONDARY},
        {text = conky_parse(NET_VARS.TOTAL_UP), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 124, y = base_y + 82, colour = COLORS.SUCCESS},
        {text = conky_parse(NET_VARS.TOTAL_DOWN), font_name = "Dejavu Sans Mono", font_size = 14, h_align = "r", x = 240, y = base_y + 82, colour = COLORS.SUCCESS}
    }
end

function processes_block(xc)
    local base_y = 459
    local process_entries = {}
    local max_width = 15  -- Maximum width of the process name, corresponding to top_name_width

    for i = 1, 6 do
        local alpha = 1 - (i-1) * 0.15
        local process_name = conky_parse("${top name " .. i .. "}")
        process_name = string.sub(process_name, 1, max_width)  -- Limit to 18 characters
        
        insert_process_entry(process_entries, process_name, "Dejavu Sans Mono", 16, 20, base_y + 16 + (i-1) * 18, {{0, COLORS.PROCESS[1][2], alpha}}, "l")
        insert_process_entry(process_entries, conky_parse("${top cpu " .. i .. "}%"), "Dejavu Sans Mono", 16, 228, base_y + 16 + (i-1) * 18, {{0, COLORS.PROCESS[1][2], alpha}}, "r")
    end
    
    table.insert(process_entries, 1, {
        text = "Processes",
        font_name = "Dejavu Sans Mono",
        font_size = 14,
        h_align = "c",
        x = xc,
        y = base_y,
        colour = COLORS.HIGHLIGHT
    })

    return process_entries
end

-- Helper function to insert process entry
function insert_process_entry(entries, text, font_name, font_size, x, y, color, h_align)
    table.insert(entries, {
        text = text,
        font_name = font_name,
        font_size = font_size,
        x = x,
        y = y,
        colour = color,
        h_align = h_align
    })
end

function updates_block(xc)
    local updates_text, security_text = "", ""
    
    -- Check if the file exists (for Ubuntu)
    if os.execute("test -f /usr/lib/update-notifier/apt-check") == 0 then
        updates_text = conky_parse("${execi 1800 /usr/lib/update-notifier/apt-check --human-readable | awk 'NR==1'}")
        security_text = conky_parse("${execi 1800 /usr/lib/update-notifier/apt-check --human-readable | awk 'NR==2'}")
    else
        -- For Arch Linux or other systems
        updates_text = "Available updates: " .. conky_parse("${execi 1800 checkupdates | wc -l}")
        security_text = "" -- No second line needed for Arch
    end

    return {
        {
            text = updates_text,
            font_name = "arial",
            font_size = 12,
            bold = true,
            h_align = "c",
            x = xc,
            y = 595,
            colour = COLORS.HIGHLIGHT
        },
        {
            text = security_text,
            font_name = "arial",
            font_size = 12,
            bold = true,
            h_align = "c",
            x = xc,
            y = 615,
            colour = COLORS.HIGHLIGHT
        }
    }
end

-- New Bitcoin price function
function bitcoin_price_block(xc)
    local base_y = 610
    return {
        {
            text = "Bitcoin Price",
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            h_align = "c",
            x = xc,
            y = base_y,
            colour = COLORS.HIGHLIGHT
        },
        {
            text = conky_parse("${execi 300 ./scripts/get_bitcoin_price.sh}${cat ./bitcoin_price.txt}"),
            font_name = "Dejavu Sans Mono",
            font_size = 14,
            h_align = "c",
            x = xc,
            y = base_y + 15,
            colour = COLORS.SUCCESS
        }
    }
end

-- Display text function
function display_text(cr, t)
    if t.draw_me and conky_parse(tostring(t.draw_me)) ~= "1" then return end
    
    local defaults = {
        text = "Conky is good for you!",
        x = conky_window.width/2,
        y = conky_window.height/2,
        colour = COLORS.PRIMARY,
        font_name = "Dejavu Sans Mono",
        font_size = 14,
        angle = 0,
        h_align = "l",
        v_align = "b",
        bold = false,
        italic = false,
        oblique = false
    }
    for k, v in pairs(defaults) do
        t[k] = t[k] or v
    end

    cairo_save(cr)
    cairo_translate(cr, t.x, t.y)
    cairo_rotate(cr, t.angle * math.pi / 180)

    local slant = t.italic and CAIRO_FONT_SLANT_ITALIC or t.oblique and CAIRO_FONT_SLANT_OBLIQUE or CAIRO_FONT_SLANT_NORMAL
    local weight = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    
    cairo_select_font_face(cr, t.font_name, slant, weight)
    cairo_set_font_size(cr, t.font_size)
    
    local te = cairo_text_extents_t:create()
    tolua.takeownership(te)
    cairo_text_extents(cr, t.text, te)
    
    if #t.colour == 1 then
        cairo_set_source_rgba(cr, rgb_to_r_g_b2(t.colour[1]))
    else
        local pat = cairo_pattern_create_linear(0, 0, te.width, 0)
        for _, c in ipairs(t.colour) do
            cairo_pattern_add_color_stop_rgba(pat, c[1], rgb_to_r_g_b2(c))
        end
        cairo_set_source(cr, pat)
        cairo_pattern_destroy(pat)
    end
    
    local mx = t.h_align == "c" and -te.width/2 or t.h_align == "r" and -te.width or 0
    local my = t.v_align == "m" and -te.height/2 or t.v_align == "t" and 0 or -te.y_bearing
    cairo_move_to(cr, mx, my)
    cairo_show_text(cr, t.text)
    
    cairo_restore(cr)
end

-- RGB conversion
function rgb_to_r_g_b2(tcolour)
    local colour, alpha = tcolour[2], tcolour[3]
    return ((colour / 0x10000) % 0x100) / 255,
           ((colour / 0x100) % 0x100) / 255,
           (colour % 0x100) / 255,
           alpha
end

-- End of script
