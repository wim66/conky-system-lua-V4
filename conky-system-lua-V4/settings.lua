
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
  
border_COLOR = "0,0x003e00,0.5,0x03f404,1,0x003e00"
bg_COLOR = "0x161825,0.71"
end

