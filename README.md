# conky-system-lua-V4

## Description

A collection of Conky configurations for system monitoring using Lua scripts. These Conkies offer visually appealing and customizable widgets to monitor system performance, networking, and more.

Conky is a lightweight system monitor that displays information on your desktop. With Lua, you can create beautiful, dynamic, and functional Conky widgets.

## Features

- System performance monitoring (CPU, RAM, Disk usage)
- Network statistics (via vnstat)
- Customizable visual themes using Lua scripts
- Easy setup and autostart script

## Requirements

To use these Conkies, ensure the following dependencies are installed:

- **Conky** (with Lua and Cairo enabled)
- **lm-sensors**: For temperature monitoring
- **vnstat**: For network statistics
- **bc** and **jq**: For command-line calculations and JSON parsing
- **Fonts**:
    - Candlescript
    - Zekton
    - DejaVu fonts (installable via your package manager)

## Installation

1. Clone the repository:

    ```sh
    git clone https://github.com/wim66/conky-system-lua-V4.git
    ```

2. Install the required fonts:
    - Download and install Candlescript and Zekton from the links provided.
    - Install DejaVu fonts via your package manager:

    ```sh
    sudo apt install fonts-dejavu
    ```

3. Install dependencies:

    ```sh
    sudo apt install conky lm-sensors vnstat bc jq
    ```

4. Run `lm-sensors` configuration:

    ```sh
    sudo sensors-detect
    ```

## Usage

1. Edit the `settings.lua` files located inside the Conky folders using **ConkySettingsUpdater** to customize your setup.
   
2. Start the Conkies using the provided autostart script:

    ```sh
    ./autostart-All.sh
    ```

3. Preview:

    ![Sample conky-preview](preview.png)

## Troubleshooting

- **Fonts not displaying correctly**: Ensure the required fonts are installed and available in your system.
- **Missing data in widgets**: Verify that `lm-sensors` and `vnstat` are configured correctly.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
