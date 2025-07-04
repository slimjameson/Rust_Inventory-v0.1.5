-- Rust Inventory UI - Styling and Constants
-- This file contains all the styling constants and helper functions

-- Create global namespace
RustInventory = RustInventory or {}

-- Color scheme matching Rust's inventory UI
RustInventory.Colors = {
    -- Main background colors
    bg_main = Color(20, 18, 16, 250),
    bg_secondary = Color(30, 28, 26, 240),
    bg_dark = Color(15, 13, 11, 230),
    bg_light = Color(40, 38, 36, 220),
    
    -- Slot colors - lighter and more translucent for blur effect
    slot_bg = Color(90, 88, 86, 140),
    slot_border = Color(120, 118, 116, 180),
    slot_hover = Color(130, 128, 126, 160),
    slot_selected = Color(200, 160, 120, 180),
    slot_occupied = Color(110, 105, 100, 150),
    
    -- Text colors
    text_primary = Color(255, 255, 255, 255),
    text_secondary = Color(200, 200, 200, 255),
    text_tertiary = Color(160, 160, 160, 255),
    text_accent = Color(255, 200, 100, 255),
    
    -- UI elements
    button_bg = Color(80, 75, 70, 255),
    button_hover = Color(100, 95, 90, 255),
    button_pressed = Color(60, 55, 50, 255),
    
    -- Item rarity colors (for future use)
    rarity_common = Color(255, 255, 255, 255),
    rarity_uncommon = Color(100, 255, 100, 255),
    rarity_rare = Color(100, 100, 255, 255),
    rarity_epic = Color(255, 100, 255, 255),
    rarity_legendary = Color(255, 200, 100, 255)
}

-- UI Constants
RustInventory.Constants = {
    -- Slot dimensions
    SLOT_SIZE = 72, -- Increased from 64 to reduce visual gap
    SLOT_SPACING = 4,
    SLOT_SMALL_SIZE = 54, -- Increased proportionally from 48
    
    -- Inventory dimensions
    INVENTORY_ROWS = 5,
    INVENTORY_COLS = 6,
    HOTBAR_SLOTS = 6,
    
    -- Panel dimensions
    PANEL_PADDING = 20,
    PANEL_SPACING = 10,
    
    -- Player model dimensions
    PLAYER_MODEL_WIDTH = 280,
    PLAYER_MODEL_HEIGHT = 400,
    
    -- Equipment panel dimensions
    EQUIPMENT_PANEL_WIDTH = 200,
    EQUIPMENT_PANEL_HEIGHT = 400,
    
    -- Fonts
    FONT_MAIN = "DermaDefault",
    FONT_SMALL = "DermaDefaultBold",
    FONT_LARGE = "DermaLarge"
}

-- Helper functions for drawing
RustInventory.Draw = {}

-- Draw a slot with Rust-style appearance
function RustInventory.Draw.Slot(x, y, w, h, isHovered, isSelected, hasItem)
    local bgColor = RustInventory.Colors.slot_bg
    
    if isSelected then
        bgColor = RustInventory.Colors.slot_selected
    elseif isHovered then
        bgColor = RustInventory.Colors.slot_hover
    elseif hasItem then
        bgColor = RustInventory.Colors.slot_occupied
    end
    
    -- Draw solid color background (no blur on individual slots)
    draw.RoundedBox(2, x, y, w, h, bgColor)
    
    -- Add subtle inner glow effect for better definition
    if isHovered or isSelected then
        draw.RoundedBox(2, x + 1, y + 1, w - 2, h - 2, Color(bgColor.r, bgColor.g, bgColor.b, math.min(bgColor.a + 40, 255)))
    end
end

-- Draw a panel with Rust-style background
function RustInventory.Draw.Panel(x, y, w, h, bgColor)
    bgColor = bgColor or RustInventory.Colors.bg_secondary
    draw.RoundedBox(8, x, y, w, h, bgColor)
end

-- Draw text with Rust-style appearance
function RustInventory.Draw.Text(text, font, x, y, color, align)
    font = font or RustInventory.Constants.FONT_MAIN
    color = color or RustInventory.Colors.text_primary
    align = align or TEXT_ALIGN_LEFT
    
    draw.SimpleText(text, font, x, y, color, align, TEXT_ALIGN_CENTER)
end

-- Equipment slot positions (relative to equipment panel)
RustInventory.EquipmentSlots = {
    {name = "Hat", x = 72, y = 20, icon = "🎩"},
    {name = "Mask", x = 72, y = 90, icon = "😷"},
    {name = "Shirt", x = 72, y = 160, icon = "👕"},
    {name = "Jacket", x = 20, y = 160, icon = "🧥"},
    {name = "Vest", x = 124, y = 160, icon = "🦺"},
    {name = "Pants", x = 72, y = 230, icon = "👖"},
    {name = "Boots", x = 72, y = 300, icon = "👢"},
    {name = "Gloves", x = 20, y = 230, icon = "🧤"},
    {name = "Belt", x = 124, y = 230, icon = "🔗"}
}

-- Item categories for organization
RustInventory.ItemCategories = {
    WEAPON = "Weapon",
    TOOL = "Tool",
    CLOTHING = "Clothing",
    CONSUMABLE = "Consumable",
    RESOURCE = "Resource",
    COMPONENT = "Component",
    MISC = "Miscellaneous"
}

-- Initialize fonts
hook.Add("Initialize", "RustInventory_InitFonts", function()
    surface.CreateFont("RustInventory_Main", {
        font = "Roboto",
        size = 14,
        weight = 500,
        antialias = true,
        shadow = false
    })
    
    surface.CreateFont("RustInventory_Small", {
        font = "Roboto",
        size = 12,
        weight = 400,
        antialias = true,
        shadow = false
    })
    
    surface.CreateFont("RustInventory_Large", {
        font = "Roboto",
        size = 18,
        weight = 600,
        antialias = true,
        shadow = false
    })
    
    surface.CreateFont("RustInventory_Title", {
        font = "Roboto",
        size = 20,
        weight = 700,
        antialias = true,
        shadow = false
    })
end)
