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
  
-- border_COLOR: Defines the gradient border for the Conky widget.
    -- Format: "start_angle,color1,opacity1,midpoint,color2,opacity2,steps,color3,opacity3"
    -- Example: "0,0x390056,1.00,0.5,0xff007f,1.00,1,0x390056,1.00" creates a purple-pink gradient.
    border_COLOR = "0,0x003e00,1.00,0.5,0x03f404,1.00,1,0x003e00,1.00"

    -- bg_COLOR: Background color and opacity for the widget.
    -- Format: "color,opacity"
    -- Example: "0x1d1e28,0.75" sets a dark purple background with 75% opacity.
    bg_COLOR = "0x1d1d2e,0.90"

    -- layer_2: Defines the gradient for the second layer of the Conky widget.
    -- Format: "start_angle,color1,opacity1,midpoint,color2,opacity2,steps,color3,opacity3"
    -- Example: "0,0x00007f,0.50,0.5,0x00aaff,0.50,1,0x00007f,0.50" creates a blue gradient with 50% opacity.
    layer_2 = "0,0xffffff,0.05,0.5,0xc2c2c2,0.20,1,0xffffff,0.05"
end

