-- conky-clock-lua V4
-- by @wim66
-- v4 6-April-2024

function conky_vars()
    
    use_FONT = "zekton"
    -- https://www.dafont.com/zekton.font

-- border_COLOR: Defines the gradient border for the Conky widget.
    -- Format: "start_angle,color1,opacity1,midpoint,color2,opacity2,steps,color3,opacity3"
    -- Example: "0,0x390056,1.00,0.5,0xff007f,1.00,1,0x390056,1.00" creates a purple-pink gradient.
    border_COLOR = "0,0x003e00,1.00,0.5,0x03f404,1.00,1,0x003e00,1.00"

    -- bg_COLOR: Background color and opacity for the widget.
    -- Format: "color,opacity"
    -- Example: "0x1d1e28,0.75" sets a dark purple background with 75% opacity.
    bg_COLOR = "0x1d1d2e,0.78"
end
