
function conky_vars()

    -- Set network interface for all scripts here
    wlan0 = "enp0s25"
    --for text
    
    var_NETUP = "${upspeed enp0s25}"
    var_NETDOWN = "${downspeed enp0s25}"
    
    var_TOTALUP = "${totalup enp0s25}"
    var_TOTALDOWN = "${totaldown enp0s25}"
    
    use_FONT = "zekton"
    -- https://www.dafont.com/zekton.font
  
    border_COLOR = ""  -- options, green, orange, blue, black, red
    bg_COLOR = ""      -- options balck, blue

end

-- Definieer de kleurinstellingen
color_options = {
    green = { {0, 0x003E00, 1}, {0.5, 0x03F404, 1}, {1, 0x003E00, 1} },
    orange = { {0, 0xE05700, 1}, {0.5, 0xFFD145, 1}, {1, 0xE05700, 1} },
    blue = { {0, 0x10000ba, 1}, {0.5, 0x8cc7ff, 1}, {1, 0x0000ba, 1} },
    black = { {0, 0x2b2b2b, 1}, {0.5, 0xa3a3a3, 1}, {1, 0x2b2b2b, 1} },
    red = { {0, 0x5c0000, 1}, {0.5, 0xff0000, 1}, {1, 0x5c0000, 1} }
}

bgcolor_options = {
    black_25 = { {1, 0x000000, 0.25} },
    black_50 = { {1, 0x000000, 0.5} },
    black_75 = { {1, 0x000000, 0.75} },
    black_100 = { {1, 0x000000, 1} },
    blue_25 = { {1, 0x0000ba, 0.25} },
    blue = { {1, 0x0000ba, 0.5} },
    blue_75 = { {1, 0x0000ba, 0.75} }
}

