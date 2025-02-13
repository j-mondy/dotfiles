-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("FiraCodeNerdFontMono")

-- Windows changes
-- Use Powershell 7 by default instead of CMD
-- config.default_prog = { 'C:/Program Files/PowerShell/7/pwsh.exe', '-NoLogo' }

-- and finally, return the configuration to wezterm
return config

-- TODO: Starship terminal

