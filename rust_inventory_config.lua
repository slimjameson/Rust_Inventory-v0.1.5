-- Rust Inventory UI - Configuration
-- Edit these settings to customize the inventory UI

RustInventory = RustInventory or {}
RustInventory.Config = {}

-- General Settings
RustInventory.Config.EnableSounds = true              -- Enable UI sounds
RustInventory.Config.EnableAnimations = true          -- Enable smooth animations
RustInventory.Config.CloseOnEscape = true            -- Allow ESC key to close
RustInventory.Config.ShowPlayerStats = true          -- Show player information
RustInventory.Config.EnableMouseControls = true      -- Enable mouse controls for player model

-- Models
RustInventory.Config.ModelMap = {
    ["weapon_physgun"] = "models/weapons/w_physics.mdl",
    ["weapon_pistol"] = "models/weapons/w_pistol.mdl",
    ["weapon_smg1"] = "models/weapons/w_smg1.mdl",
    ["weapon_ar2"] = "models/weapons/w_irifle.mdl",
    ["weapon_shotgun"] = "models/weapons/w_shotgun.mdl",
    ["weapon_crossbow"] = "models/weapons/w_crossbow.mdl",
    ["weapon_crowbar"] = "models/weapons/w_crowbar.mdl",
    ["weapon_stunstick"] = "models/weapons/w_stunbaton.mdl",
    ["weapon_frag"] = "models/weapons/w_grenade.mdl",
    ["weapon_slam"] = "models/weapons/w_slam.mdl",
    ["weapon_rpg"] = "models/weapons/w_rocket_launcher.mdl"
}

-- UI Scale Settings
RustInventory.Config.UIScale = 1.0                   -- Overall UI scale multiplier
RustInventory.Config.MinScale = 0.8                  -- Minimum scale for small screens
RustInventory.Config.MaxScale = 1.2                  -- Maximum scale for large screens

-- Inventory Grid Settings
RustInventory.Config.InventoryRows = 6               -- Number of inventory rows
RustInventory.Config.InventoryCols = 6               -- Number of inventory columns
RustInventory.Config.HotbarSlots = 6                 -- Number of hotbar slots
RustInventory.Config.ShowSlotNumbers = true         -- Show numbers on hotbar slots

-- Visual Settings
RustInventory.Config.ShowGrid = true                 -- Show grid lines
RustInventory.Config.ShowTooltips = true            -- Show hover tooltips
RustInventory.Config.BackgroundBlur = true          -- Blur background when open
RustInventory.Config.ShowVignette = true            -- Show vignette effect

-- Player Model Settings
RustInventory.Config.PlayerModelFOV = 45             -- Field of view for player model
RustInventory.Config.PlayerModelHeight = 400         -- Height of player model panel
RustInventory.Config.PlayerModelWidth = 280          -- Width of player model panel
RustInventory.Config.EnableModelRotation = true     -- Allow mouse rotation of model

-- Equipment Slots
RustInventory.Config.EquipmentSlots = {
    {name = "Hat", enabled = true, x = 72, y = 20},
    {name = "Mask", enabled = true, x = 72, y = 90},
    {name = "Shirt", enabled = true, x = 72, y = 160},
    {name = "Jacket", enabled = true, x = 20, y = 160},
    {name = "Vest", enabled = true, x = 124, y = 160},
    {name = "Pants", enabled = true, x = 72, y = 230},
    {name = "Boots", enabled = true, x = 72, y = 300},
    {name = "Gloves", enabled = true, x = 20, y = 230},
    {name = "Belt", enabled = true, x = 124, y = 230}
}

-- Crafting Settings
RustInventory.Config.EnableCrafting = true          -- Show crafting panel
RustInventory.Config.CraftingGridSize = 3           -- Size of crafting grid (3x3)
RustInventory.Config.ShowCraftButton = true         -- Show craft button

-- Keybind Settings
RustInventory.Config.InventoryKey = KEY_I           -- Key to open inventory
RustInventory.Config.AlternateKeys = {              -- Alternative keys
    KEY_TAB,    -- Tab key
    KEY_B       -- B key
}

-- Color Theme (can be overridden)
RustInventory.Config.ColorTheme = "default"         -- "default", "dark", "light", "custom"

-- Custom color theme (only used if ColorTheme is "custom")
RustInventory.Config.CustomColors = {
    bg_main = Color(44, 42, 40, 240),
    bg_secondary = Color(52, 50, 48, 220),
    slot_bg = Color(68, 66, 64, 200),
    slot_hover = Color(120, 118, 116, 255),
    text_primary = Color(255, 255, 255, 255),
    text_secondary = Color(200, 200, 200, 255)
}

-- Performance Settings
RustInventory.Config.MaxFPS = 60                    -- Limit UI refresh rate
RustInventory.Config.EnableVSync = true             -- Enable vertical sync
RustInventory.Config.LowEndMode = false             -- Disable effects for low-end systems

-- Debug Settings
RustInventory.Config.DebugMode = false              -- Enable debug output
RustInventory.Config.ShowBounds = false             -- Show element boundaries
RustInventory.Config.ShowFPS = false                -- Show FPS counter

-- Apply configuration
hook.Add("Initialize", "RustInventory_ApplyConfig", function()
    -- Apply UI scale
    if RustInventory.Config.UIScale ~= 1.0 then
        for k, v in pairs(RustInventory.Constants) do
            if type(v) == "number" and string.find(k, "SIZE") then
                RustInventory.Constants[k] = v * RustInventory.Config.UIScale
            end
        end
    end
    
    -- Apply color theme
    if RustInventory.Config.ColorTheme == "custom" then
        for k, v in pairs(RustInventory.Config.CustomColors) do
            if RustInventory.Colors[k] then
                RustInventory.Colors[k] = v
            end
        end
    end
    
    -- Apply performance settings
    if RustInventory.Config.LowEndMode then
        RustInventory.Config.EnableAnimations = false
        RustInventory.Config.BackgroundBlur = false
        RustInventory.Config.ShowVignette = false
    end
end)

-- Console commands for runtime configuration
concommand.Add("rust_inventory_config", function(ply, cmd, args)
    if not args[1] then
        print("Usage: rust_inventory_config <setting> <value>")
        print("Example: rust_inventory_config EnableSounds 0")
        return
    end
    
    local setting = args[1]
    local value = args[2]
    
    if RustInventory.Config[setting] ~= nil then
        -- Convert value to appropriate type
        if type(RustInventory.Config[setting]) == "boolean" then
            RustInventory.Config[setting] = tobool(value)
        elseif type(RustInventory.Config[setting]) == "number" then
            RustInventory.Config[setting] = tonumber(value) or RustInventory.Config[setting]
        else
            RustInventory.Config[setting] = value
        end
        
        print("Set " .. setting .. " to " .. tostring(RustInventory.Config[setting]))
    else
        print("Unknown setting: " .. setting)
    end
end)

-- Reset configuration to defaults
concommand.Add("rust_inventory_reset_config", function()
    -- This would reload the default configuration
    print("Configuration reset to defaults")
end)
