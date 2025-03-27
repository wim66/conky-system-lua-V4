#!/bin/bash

# Controleer of zenity is geïnstalleerd
if ! command -v zenity &>/dev/null; then
    zenity --error --title="Fout" --text="Zenity is niet geïnstalleerd.\nInstalleer het met: sudo apt-get install zenity"
    exit 1
fi

# Configuratiebestanden
SETTINGS_FILES=(
    "conky-clock-lua-V1/settings.lua"
    "conky-system-lua-V4/settings.lua"
    "conky-vnstat-lua/settings.lua"
)

# Vraag de nieuwe waarden
new_border_color=$(zenity --list --radiolist --title="Border Color" --text="Kies randkleur:" \
    --column="Select" --column="Color" \
    TRUE "orange" FALSE "green" FALSE "blue" FALSE "black" FALSE "red") || exit 0

new_bg_color=$(zenity --list --radiolist --title="Background Color" --text="Kies achtergrondkleur:" \
    --column="Select" --column="Color" \
    TRUE "black_50" FALSE "black_25" FALSE "black_75" FALSE "black_100" FALSE "dark_100" FALSE "blue") || exit 0

# Controleer of er een keuze is gemaakt
[[ -z "$new_border_color" || -z "$new_bg_color" ]] && {
    zenity --error --title="Fout" --text="Geen geldige keuze gemaakt."
    exit 1
}

# Functie om settings.lua aan te passen
update_settings() {
    local settings_file="$1"
    local tmp_file=$(mktemp) || {
        zenity --error --title="Fout" --text="Kon tijdelijk bestand niet aanmaken voor $settings_file."
        return 1
    }
    
    awk -v border_color="$new_border_color" -v bg_color="$new_bg_color" '
    /border_COLOR/ {if (border_color != "") { gsub(/".*"/, "\"" border_color "\"", $0) }}
    /bg_COLOR/ {if (bg_color != "") { gsub(/".*"/, "\"" bg_color "\"", $0) }}
    {print}
    ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"
}

# Update alle instellingenbestanden
success_count=0
for settings_file in "${SETTINGS_FILES[@]}"; do
    if [[ -f "$settings_file" ]]; then
        update_settings "$settings_file" && {
            echo "Updated $settings_file"
            ((success_count++))
        }
    else
        echo "Settings file not found: $settings_file"
    fi
done

# Feedback
total_files=${#SETTINGS_FILES[@]}
if [[ $success_count -eq $total_files ]]; then
    zenity --info --title="Voltooid" --text="Alle $total_files instellingen zijn bijgewerkt."
elif [[ $success_count -gt 0 ]]; then
    zenity --warning --title="Gedeeltelijk voltooid" --text="$success_count van $total_files bestanden bijgewerkt."
else
    zenity --error --title="Fout" --text="Geen bestanden konden worden bijgewerkt."
fi
