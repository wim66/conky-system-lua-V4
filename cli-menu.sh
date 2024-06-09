#!/bin/bash

# Functie om de variabelen in te stellen voor conky-system-lua-V3
configure_conky_system_lua() {
    read -p "Enter network interface (e.g., WLAN): " var_NETWORK

    read -p "Enter font name (e.g., zekton): " use_FONT
    read -p "Enter border color (options: green, orange, blue, black, red): " border_COLOR
    read -p "Enter background color (options: black, blue): " bg_COLOR

    for file in conky-system-lua-V3/settings.lua conky-vnstat-lua/settings.lua conky-clock-lua-V1/settings.lua; do
        sed -i "s/^use_FONT = .*/use_FONT = \"$use_FONT\"/" "$file"
        sed -i "s/^border_COLOR = .*/border_COLOR = \"$border_COLOR\"/" "$file"
        sed -i "s/^bg_COLOR = .*/bg_COLOR = \"$bg_COLOR\"/" "$file"
    done

    replace_variable_in_file "var_NETWORK" "$var_NETWORK" conky-system-lua-V3/settings.lua
    replace_variable_in_file "var_NETWORK" "$var_NETWORK" conky-vnstat-lua/settings.lua
    replace_variable_in_file "var_NETWORK" "$var_NETWORK" conky-clock-lua-V1/settings.lua

    echo "Variables updated for conky-system-lua-V3."
}

# Functie om een variabele te vervangen in een bestand
replace_variable_in_file() {
    local variable="$1"
    local value="$2"
    local file="$3"

    sed -i "s/${variable} = .*/${variable} = \"${value}\"/" "$file"
    sed -i "s/${variable}/${value}/g" "$file"
}

# Hoofdmenu
while true; do
    echo "Choose an option:"
    echo "1. Configure conky-system-lua-V3 variables"
    echo "2. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1) configure_conky_system_lua ;;
        2) echo "Exiting..."; exit ;;
        *) echo "Invalid choice. Please enter a valid option." ;;
    esac
done
