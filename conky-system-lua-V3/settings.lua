
function conky_vars()

    -- Set network interface for all scripts here
    var_NETWORK = "enp0s25"
    --for text
    
    var_NETUP = "${upspeed enp0s25}"
    var_NETDOWN = "${downspeed enp0s25}"
    
    var_TOTALUP = "${totalup enp0s25}"
    var_TOTALDOWN = "${totaldown enp0s25}"
    
    use_FONT = "zekton"
    -- https://www.dafont.com/zekton.font
  
    border_COLOR = "orange"  -- options, green, orange, blue, black, red
    bg_COLOR = "black_100"      -- options balck, blue

end

