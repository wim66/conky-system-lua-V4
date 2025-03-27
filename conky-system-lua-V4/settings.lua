
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
  
border_COLOR = "orange" --options are green, blue, black, orange or default
bg_COLOR = "black_75"      -- options balck, blue

end

