-- lua2-text.lua
-- conky-system-lua V4.1
-- by @wim66
-- May 17, 2025

-- Import the required Cairo libraries
require 'cairo'
-- Try to require the 'cairo_xlib' module safely
local status, cairo_xlib = pcall(require, 'cairo_xlib')
if not status then
    cairo_xlib = setmetatable({}, { __index = function(_, k) return _G[k] end })
end

-- === Load settings.lua from parent directory ===
local script_path = debug.getinfo(1, 'S').source:match[[^@?(.*[\/])[^\/]-$]]
local parent_path = script_path:match("^(.*[\\/])resources[\\/].*$") or ""
package.path = package.path .. ";" .. parent_path .. "?.lua"

local status, err = pcall(function() require("settings") end)
if not status then print("Error loading settings.lua: " .. err) return end
if not conky_vars then print("conky_vars function is not defined in settings.lua") return end
conky_vars()

-- Configuration constants
local CONFIG = {
    NET_INTERFACE = var_NETWORK,  -- Set in settings.lua
    FONT_DEFAULT = "Dejavu Sans Mono",
    FONT_SIZE_DEFAULT = 14,
    UPDATE_INTERVAL = 3,
    TEXT_MARGIN = 20,
    TEXT_WIDTH = 240,
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

-- Helper function to concatenate tables
local function concatenate_tables(tables)
    local result = {}
    for _, t in ipairs(tables) do
        if type(t) == "function" then t = t() end
        for _, v in ipairs(t) do table.insert(result, v) end
    end
    return result
end

-- Helper function to set font
local function set_font(cr, t)
    local font_name = t.font_name or CONFIG.FONT_DEFAULT
    local font_size = t.font_size or CONFIG.FONT_SIZE_DEFAULT
    local slant = CAIRO_FONT_SLANT_NORMAL
    if t.italic then slant = CAIRO_FONT_SLANT_ITALIC
    elseif t.oblique then slant = CAIRO_FONT_SLANT_OBLIQUE end
    local weight = t.bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL
    cairo_select_font_face(cr, font_name, slant, weight)
    cairo_set_font_size(cr, font_size)
end

-- Helper function to set color
local function set_color(cr, t)
    if #t.colour == 1 then
        cairo_set_source_rgba(cr, rgb_to_r_g_b2(t.colour[1]))
    else
        local pat = cairo_pattern_create_linear(0, 0, t.te.width, 0)
        for _, c in ipairs(t.colour) do
            cairo_pattern_add_color_stop_rgba(pat, c[1], rgb_to_r_g_b2(c))
        end
        cairo_set_source(cr, pat)
        cairo_pattern_destroy(pat)
    end
end

-- Display text function
function display_text(cr, t)
    if t.draw_me and conky_parse(tostring(t.draw_me)) ~= "1" then return end
    local defaults = {
        text = "Conky is good for you!",
        x = conky_window.width/2,
        y = conky_window.height/2,
        colour = COLORS.PRIMARY,
        font_name = CONFIG.FONT_DEFAULT,
        font_size = CONFIG.FONT_SIZE_DEFAULT,
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

    -- Parse conky vars
        t.text = conky_parse(t.text)

    -- Truncate text if max_width is specified
    if t.max_width then
        local max_width = tonumber(t.max_width)
        t.text = t.text:sub(1, max_width)
    end

    cairo_save(cr)
    cairo_translate(cr, t.x, t.y)
    cairo_rotate(cr, t.angle * math.pi / 180)
    set_font(cr, t)
    local te = cairo_text_extents_t:create()
    if tolua and tolua.takeownership then tolua.takeownership(te) end
    cairo_text_extents(cr, t.text, te)
    t.te = te
    set_color(cr, t)
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

-- Block functions
function cpu_block(xc)
    return {
        {
            text = "${execi 6000 cat /proc/cpuinfo | grep -i 'Model name' -m 1 | cut -c13- | sed 's/CPU.*$//' | sed 's/  */ /g'}",
            font_size = CONFIG.FONT_SIZE_DEFAULT,
            x = CONFIG.TEXT_MARGIN,
            y = 87,
            colour = COLORS.SECONDARY
        },
        {
            text = "CPU: ${execi 5 sensors|grep 'Package'|awk '{print $4}'} ${cpu cpu1}%",
            font_size = CONFIG.FONT_SIZE_DEFAULT,
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
        {text = "Memory", h_align = "c", x = xc, y = base_y + 9, colour = COLORS.HIGHLIGHT},
        {text = "Used", x = CONFIG.TEXT_MARGIN, y = base_y, colour = COLORS.SECONDARY},
        {text = "${mem}", x = CONFIG.TEXT_MARGIN, y = base_y + 18, colour = COLORS.SUCCESS},
        {text = "Free", h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y, colour = COLORS.SECONDARY},
        {text = "${memeasyfree}", h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y + 18, colour = COLORS.SUCCESS}
    }
end

function disk_block(xc)
    local base_y = 261
    return {
        {text = "Disks", h_align = "c", x = xc, y = base_y, colour = COLORS.HIGHLIGHT},
        {text = "Used", x = CONFIG.TEXT_MARGIN, y = base_y, colour = COLORS.SECONDARY},
        {text = "${fs_used /}", x = CONFIG.TEXT_MARGIN, y = base_y + 19, colour = COLORS.SUCCESS},
        {text = "ROOT", h_align = "c", x = xc, y = base_y + 19, colour = COLORS.SECONDARY},
        {text = "Free", h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y, colour = COLORS.SECONDARY},
        {text = "${fs_free /}", h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y + 19, colour = COLORS.SUCCESS},
        {text = "Home", h_align = "c", x = xc, y = base_y + 54, colour = COLORS.SECONDARY},
        {text = "${fs_used /home/}", x = CONFIG.TEXT_MARGIN, y = base_y + 54, colour = COLORS.SUCCESS},
        {text = "${fs_free /home/}", h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y + 54, colour = COLORS.SUCCESS}
    }
end

function network_block(xc)
    local base_y = 355
    return {
        {text = "Network speed", h_align = "c", x = xc, y = base_y, colour = COLORS.HIGHLIGHT},
        {text = "Up", x = CONFIG.TEXT_MARGIN + 3, y = base_y + 20, colour = COLORS.SECONDARY},
        {text = NET_VARS.UP, h_align = "r", x = 120, y = base_y + 20, colour = COLORS.SUCCESS},
        {text = "Down", x = 142, y = base_y + 20, colour = COLORS.SECONDARY},
        {text = NET_VARS.DOWN, h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y + 20, colour = COLORS.SUCCESS},
        {text = "Session", x = CONFIG.TEXT_MARGIN + 3, y = base_y + 82, colour = COLORS.SECONDARY},
        {text = NET_VARS.TOTAL_UP, h_align = "r", x = 124, y = base_y + 82, colour = COLORS.SUCCESS},
        {text = NET_VARS.TOTAL_DOWN, h_align = "r", x = CONFIG.TEXT_WIDTH, y = base_y + 82, colour = COLORS.SUCCESS}
    }
end

function processes_block(xc)
    local base_y = 459
    local process_entries = {}
    local max_width = 17
    for i = 1, 6 do
        local alpha = 1 - (i-1) * 0.15
        local process_name = "${top name " .. i .. "}"
        table.insert(process_entries, {
            text = process_name,
            font_size = 16,
            x = CONFIG.TEXT_MARGIN,
            y = base_y + 16 + (i-1)*18,
            colour = {{0, COLORS.PROCESS[1][2], alpha}},
            h_align = "l",
            max_width = max_width,
        })
        table.insert(process_entries, {
            text = "${top cpu " .. i .. "}%",
            font_size = 16,
            x = 228,
            y = base_y + 16 + (i-1)*18,
            colour = {{0, COLORS.PROCESS[1][2], alpha}},
            h_align = "r"
        })
    end
    table.insert(process_entries, 1, {
        text = "Processes",
        h_align = "c",
        x = xc,
        y = base_y,
        colour = COLORS.HIGHLIGHT
    })
    return process_entries
end

--- Updates block
local cache_file_apt = "/tmp/package_updates_cache_apt.txt"
local cache_file_pacman = "/tmp/package_updates_cache_pacman.txt"
local cache_file_aur = "/tmp/package_updates_cache_aur.txt"
local cache_duration = 3600  -- 1 hour

-- Refresh cache for package updates
local function update_cache()
    local function last_update(file)
        local h = io.popen("stat -c %Y " .. file .. " 2>/dev/null"); local t = tonumber(h:read("*a")) or 0; h:close(); return t
    end
    if (os.time() - last_update(cache_file_apt)) > cache_duration then
        os.execute("apt list --upgradable > " .. cache_file_apt .. " 2>/dev/null")
    end
    if (os.time() - last_update(cache_file_pacman)) > cache_duration then
        os.execute("checkupdates > " .. cache_file_pacman .. " 2>/dev/null")
    end
    if (os.time() - last_update(cache_file_aur)) > cache_duration then
        local aur_helper = io.popen("command -v yay >/dev/null 2>&1 && echo yay || echo paru")
        local aur_helper_type = aur_helper:read("*a"):gsub("\n", "")
        aur_helper:close()
        if aur_helper_type == "yay" then
            os.execute("yay -Qua > " .. cache_file_aur .. " 2>/dev/null")
        elseif aur_helper_type == "paru" then
            os.execute("paru -Qua > " .. cache_file_aur .. " 2>/dev/null")
        end
    end
end

-- Load package lines from cache
local function load_package_lines()
    local original_lines = {}
    update_cache()
    local package_manager = io.popen("command -v apt >/dev/null 2>&1 && echo apt || echo pacman")
    local package_manager_type = package_manager:read("*a"):gsub("\n", "")
    package_manager:close()
    if package_manager_type == "apt" then
        local file = io.open(cache_file_apt, "r")
        if file then
            for line in file:lines() do
                -- Skip the first line ("Listing...") and parse package names
                if not line:match("^Listing...") then
                    local package_name = line:match("^%S+/") -- Package name before the first slash
                    if package_name then
                        package_name = package_name:gsub("/.*", "") -- Remove everything after the slash
                        if #package_name > 20 then
                            package_name = package_name:sub(1, 17) .. "..."
                        end
                        table.insert(original_lines, package_name)
                    end
                end
            end
            file:close()
        end
    elseif package_manager_type == "pacman" then
        local file = io.open(cache_file_pacman, "r")
        if file then
            for line in file:lines() do
                table.insert(original_lines, line:match("([^ ]+)"))
            end
            file:close()
        end
        local aur_helper = io.popen("command -v yay >/dev/null 2>&1 && echo yay || echo paru")
        local aur_helper_type = aur_helper:read("*a"):gsub("\n", "")
        aur_helper:close()
        local file = io.open(cache_file_aur, "r")
        if file then
            for line in file:lines() do
                table.insert(original_lines, line:match("([^ ]+)"))
            end
            file:close()
        end
    end
    local update_count = #original_lines
    local updates_text = (update_count == 0) and "System is up-to-date" or tostring(update_count) .. " updates available"
    return {{
        text = updates_text,
        font_size = 12,
        bold = true,
        h_align = "c",
        colour = COLORS.HIGHLIGHT
    }}
end

function updates_block(xc)
    local updates_settings = load_package_lines()
    updates_settings[1].x = xc
    updates_settings[1].y = 595
    updates_settings[1].colour = COLORS.HIGHLIGHT
    return updates_settings
end

-- Bitcoin price function
function bitcoin_price_block(xc)
    local base_y = 615
    return {
        {
            text = "Bitcoin Price",
            h_align = "c",
            x = xc,
            y = base_y,
            colour = COLORS.HIGHLIGHT
        },
        {
            text = "${execi 300 ./scripts/get_bitcoin_price.sh}${cat ./bitcoin_price.txt}",
            h_align = "c",
            x = xc,
            y = base_y + 15,
            colour = COLORS.SUCCESS
        }
    }
end

local blocks = {
    cpu_block = cpu_block,
    memory_block = memory_block,
    disk_block = disk_block,
    network_block = network_block,
    processes_block = processes_block,
    updates_block = updates_block,
    bitcoin_price_block = bitcoin_price_block,
}

function generate_text_settings(xc)
    return concatenate_tables({
        -- System info
        {{
            text = "${if_existing /usr/bin/lsb_release}${execi 10000 lsb_release -d | cut -f 2}${else}$distribution${endif}",
            font_size = 22,
            bold = true,
            h_align = "c",
            x = xc,
            y = 25,
            colour = COLORS.GRADIENT
        }, {
            text = "$sysname ${kernel}",
            x = CONFIG.TEXT_MARGIN,
            y = 50,
            colour = COLORS.SECONDARY
        }, {
            text = "Uptime: ${uptime}",
            x = CONFIG.TEXT_MARGIN,
            y = 67,
            colour = COLORS.SECONDARY
        }},
        blocks.cpu_block(xc),
        blocks.memory_block(xc),
        blocks.disk_block(xc),
        blocks.network_block(xc),
        blocks.processes_block(xc),
        blocks.updates_block(xc),
    --    blocks.bitcoin_price_block(xc)
    })
end

-- Main function
function conky_draw_text()
    local updates = tonumber(conky_parse("$updates")) or 0
    if updates < CONFIG.UPDATE_INTERVAL then return end
    if not conky_window then print("Error: No conky window available") return end
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
    if not status then error("Error creating cairo surface: " .. cs) end
    local cr = cairo_create(cs)
    local text_settings = generate_text_settings(xc)
    for _, v in ipairs(text_settings) do display_text(cr, v) end
    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end