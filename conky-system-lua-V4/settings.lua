-- conky-system-lua V4
-- by @wim66
-- v4 6-April-2024

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
  
border_COLOR = "0,0xff5500,0.5,0xffd7c3,1,0xff5500"
bg_COLOR = "0x1d1d2e,0.78"
end

