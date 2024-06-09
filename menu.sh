#!/bin/bash

# Vraag de nieuwe waarden voor de variabelen
read -p "Voer je nieuwe border_COLOR (options: green, orange, blue, black, red) in: " new_border_color
read -p "Voer je nieuwe bg_COLOR (options: black, blue) in: " new_bg_color

# Functie om settings.lua aan te passen
update_settings() {
    local settings_file="$1"

    # Maak een tijdelijke bestand voor de aangepaste settings
    tmp_file=$(mktemp)

    # Pas de waarden aan in het settings.lua bestand
    awk -v border_color="$new_border_color" -v bg_color="$new_bg_color" '
    /border_COLOR/ {sub(/".*"/, "\"" border_color "\"")}
    /bg_COLOR/ {sub(/".*"/, "\"" bg_color "\"")}
    {print}
    ' "$settings_file" > "$tmp_file"

    # Vervang het oude settings.lua bestand met het nieuwe
    mv "$tmp_file" "$settings_file"
}

# Update settings.lua voor elke conky configuratie
    settings_file="conky-clock-lua-V1/settings.lua"
    if [[ -f "$settings_file" ]]; then
        update_settings "$settings_file"
        echo "Updated $settings_file"
    else
        echo "Settings file not found: $settings_file"
    fi
    settings_file="conky-system-lua-V3/settings.lua"
    if [[ -f "$settings_file" ]]; then
        update_settings "$settings_file"
        echo "Updated $settings_file"
    else
        echo "Settings file not found: $settings_file"
    fi    
    settings_file="conky-vnstat-lua/settings.lua"
    if [[ -f "$settings_file" ]]; then
        update_settings "$settings_file"
        echo "Updated $settings_file"
    else
        echo "Settings file not found: $settings_file"
    fi
echo "Alle instellingen zijn bijgewerkt."
