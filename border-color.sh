#!/bin/bash

# Check if zenity is installed
if ! command -v zenity &>/dev/null; then
    zenity --error --title="Error" --text="Zenity is not installed.\nInstall it with: sudo apt-get install zenity"
    exit 1
fi

# Configuration files
SETTINGS_FILES=(
    "conky-clock-lua-V1/settings.lua"
    "conky-system-lua-V4/settings.lua"
    "conky-vnstat-lua/settings.lua"
)

# Function to prompt for color selection
prompt_color_selection() {
    local title=$1
    local text=$2
    local colors=("${@:3}")  # All arguments from the third onwards are colors
    local color_selection

    color_selection=$(zenity --list --radiolist --title="$title" --text="$text" \
        --column="Select" --column="Color" TRUE "${colors[0]}" FALSE "${colors[1]}" FALSE "${colors[2]}" FALSE "${colors[3]}" FALSE "${colors[4]}" FALSE "${colors[5]}") || exit 0

    echo "$color_selection"
}

# Prompt for new values
new_border_color=$(prompt_color_selection "Border Color" "Choose border color:" "orange" "green" "blue" "black" "red")
new_bg_color=$(prompt_color_selection "Background Color" "Choose background color:" "black_50" "black_25" "black_75" "black_100" "dark_100" "blue")

# Check if a selection was made
if [[ -z "$new_border_color" || -z "$new_bg_color" ]]; then
    zenity --error --title="Error" --text="No valid selection made."
    exit 1
fi

# Function to update settings.lua
update_settings() {
    local settings_file="$1"
    local tmp_file=$(mktemp) || {
        zenity --error --title="Error" --text="Could not create temporary file for $settings_file."
        return 1
    }

    awk -v border_color="$new_border_color" -v bg_color="$new_bg_color" '
    /border_COLOR/ {if (border_color != "") { gsub(/".*"/, "\"" border_color "\"", $0) }}
    /bg_COLOR/ {if (bg_color != "") { gsub(/".*"/, "\"" bg_color "\"", $0) }}
    {print}
    ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file" || {
        zenity --error --title="Error" --text="Failed to move temporary file to $settings_file."
        return 1
    }
}

# Update all configuration files
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
    zenity --info --title="Complete" --text="All $total_files settings have been updated."
elif [[ $success_count -gt 0 ]]; then
    zenity --warning --title="Partially Complete" --text="$success_count of $total_files files updated."
else
    zenity --error --title="Error" --text="No files could be updated."
fi