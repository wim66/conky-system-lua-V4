#!/bin/bash

# Controleer of zenity is geïnstalleerd
if ! command -v zenity &> /dev/null
then
    echo "Zenity is niet geïnstalleerd. Installeer het eerst met: sudo apt-get install zenity"
    exit 1
fi

# Vraag de nieuwe waarden voor de variabelen via zenity dialoogvensters
new_border_color=$(zenity --list --radiolist --title="Border Color" --text="Choose border colour:" --column="Select" --column="Color" TRUE "orange" FALSE "green" FALSE "blue" FALSE "black" FALSE "red")
new_bg_color=$(zenity --list --radiolist --title="Background Color" --text="Choose background colour:" --column="Select" --column="Color" TRUE "black" FALSE "blue")


# Functie om settings.lua aan te passen
update_settings() {
    local settings_file="$1"

    # Maak een tijdelijke bestand voor de aangepaste settings
    tmp_file=$(mktemp)

    # Pas de waarden aan in het settings.lua bestand
    awk -v border_color="$new_border_color" -v bg_color="$new_bg_color" '
    function update_value(key, value) {
        if (value != "" && value != "null") {
            gsub(/".*"/, "\"" value "\"", $0)
        }
    }
    /border_COLOR/ {if (border_color != "") { gsub(/".*"/, "\"" border_color "\"", $0) }}
    /bg_COLOR/ {if (bg_color != "") { gsub(/".*"/, "\"" bg_color "\"", $0) }}
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

zenity --info --title="Voltooid" --text="Alle instellingen zijn bijgewerkt."
