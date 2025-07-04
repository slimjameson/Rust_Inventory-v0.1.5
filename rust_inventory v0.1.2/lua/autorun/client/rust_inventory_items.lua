-- Rust Inventory UI - Item Detection and Management
-- This script handles detecting and managing player items

RustInventory = RustInventory or {}
RustInventory.Items = {}
RustInventory.PlayerInventory = {}

-- Item data structure
local playerItems = {
    hotbar = {}, -- 6 slots
    inventory = {}, -- 30 slots (5x6)
    equipment = {} -- 9 equipment slots
}

-- Item movement variables (moved to top for global access)
local pickedUpItem = nil
local pickedUpFromSlot = nil
local pickedUpFromType = nil -- "hotbar" or "inventory"

-- Active slot tracking for slot-based weapon switching
local activeHotbarSlot = 1 -- Currently selected hotbar slot (1-6)
local lastEquippedWeapon = nil -- Track the last equipped weapon to handle slot switching

-- Empty hands weapon for invisible placeholder in empty slots
local EMPTY_HANDS_CLASS = "weapon_empty_hands"

-- Item type detection based on weapon class
local function GetItemType(weapon)
    if not IsValid(weapon) then return "misc" end
    
    local class = weapon:GetClass()
    
    -- Tool detection
    if string.find(class, "tool") or string.find(class, "physgun") then
        return "tool"
    end
    
    -- Weapon detection
    if string.find(class, "weapon_") then
        return "weapon"
    end
    
    return "misc"
end

-- Get item icon based on weapon class
local function GetItemIcon(weapon)
    if not IsValid(weapon) then return nil end
    
    local class = weapon:GetClass()
    
    -- Specific weapon icons
    local iconMap = {
        ["weapon_physgun"] = "icon16/wand.png",
        ["gmod_tool"] = "icon16/wrench.png",
        ["weapon_pistol"] = "icon16/gun.png",
        ["weapon_smg1"] = "icon16/gun.png",
        ["weapon_ar2"] = "icon16/gun.png",
        ["weapon_shotgun"] = "icon16/gun.png",
        ["weapon_crossbow"] = "icon16/arrow_right.png",
        ["weapon_crowbar"] = "icon16/wrench_orange.png",
        ["weapon_stunstick"] = "icon16/lightning.png",
        ["weapon_frag"] = "icon16/bomb.png",
        ["weapon_slam"] = "icon16/bomb.png",
        ["weapon_rpg"] = "icon16/rocket.png"
    }
    
    return iconMap[class] or nil -- Return nil for unknown weapons to trigger text fallback
end

-- Get item name based on weapon
local function GetItemName(weapon)
    if not IsValid(weapon) then return "Unknown" end
    
    local class = weapon:GetClass()
    local printName = weapon.PrintName or class
    
    -- Clean up the name
    if printName == class then
        -- Convert class name to readable format
        printName = string.gsub(class, "weapon_", "")
        printName = string.gsub(printName, "gmod_", "")
        printName = string.gsub(printName, "_", " ")
        printName = string.gsub(printName, "(%a)(%a*)", function(first, rest)
            return string.upper(first) .. rest
        end)
    end
    
    return printName
end

-- Create item data from weapon
local function CreateItemData(weapon, slot)
    return {
        weapon = weapon,
        class = weapon:GetClass(),
        name = GetItemName(weapon),
        icon = GetItemIcon(weapon),
        type = GetItemType(weapon),
        slot = slot,
        ammo = IsValid(weapon) and weapon:Clip1() or 0,
        maxAmmo = IsValid(weapon) and weapon:GetMaxClip1() or 0
    }
end

-- Update active slot weapon when items are moved (moved here to be available earlier)
local function UpdateActiveSlotWeapon()
    -- Check if the currently active slot still has the same weapon
    local activeItem = RustInventory.Items.GetValidHotbarItem(activeHotbarSlot)
    
    if activeItem and activeItem.class == lastEquippedWeapon then
        -- Same weapon is still in the active slot, no change needed
        return
    elseif activeItem and activeItem.class ~= lastEquippedWeapon then
        -- Different weapon is now in the active slot, switch to it
        RunConsoleCommand("use", activeItem.class)
        lastEquippedWeapon = activeItem.class
    elseif not activeItem and lastEquippedWeapon then
        -- Active slot is now empty, switch to empty hands
        RunConsoleCommand("use", EMPTY_HANDS_CLASS)
        lastEquippedWeapon = EMPTY_HANDS_CLASS
    end
    
    -- Trigger UI update to show active slot changes
    hook.Run("RustInventory_ItemsUpdated")
end

-- Update player inventory by scanning weapons
function RustInventory.Items.UpdateInventory()
    local player = LocalPlayer()
    if not IsValid(player) then return end
    
    -- Get all current weapons
    local currentWeapons = player:GetWeapons()
    local weaponClasses = {}
    
    -- Create a set of current weapon classes for quick lookup
    for _, weapon in ipairs(currentWeapons) do
        if IsValid(weapon) then
            weaponClasses[weapon:GetClass()] = weapon
        end
    end
    
    -- Remove weapons that no longer exist from our inventory
    for slot, item in pairs(playerItems.hotbar) do
        if not weaponClasses[item.class] then
            playerItems.hotbar[slot] = nil
        end
    end
    
    for slot, item in pairs(playerItems.inventory) do
        if not weaponClasses[item.class] then
            playerItems.inventory[slot] = nil
        end
    end
    
    -- Find weapons that aren't in our inventory yet (new weapons)
    local existingWeapons = {}
    
    -- Check what weapons we already have placed
    for _, item in pairs(playerItems.hotbar) do
        if item then existingWeapons[item.class] = true end
    end
    for _, item in pairs(playerItems.inventory) do
        if item then existingWeapons[item.class] = true end
    end
    
    -- Also check if we have a picked up item to prevent duplication
    if pickedUpItem then
        existingWeapons[pickedUpItem.class] = true
    end
    
    -- Add new weapons in acquisition order
    for _, weapon in ipairs(currentWeapons) do
        if IsValid(weapon) and not existingWeapons[weapon:GetClass()] then
            -- Skip empty hands weapon from being added automatically
            if weapon:GetClass() == EMPTY_HANDS_CLASS then
                continue
            end
            
            -- This is a new weapon, find the first available slot
            local placed = false
            
            -- Try to place in hotbar first - prioritize replacing empty hands weapons
            local hotbarSlots = RustInventory.Constants.HOTBAR_SLOTS
            for i = 1, hotbarSlots do
                local currentItem = playerItems.hotbar[i]
                if not currentItem then
                    -- Completely empty slot
                    playerItems.hotbar[i] = CreateItemData(weapon, i)
                    placed = true
                    break
                elseif currentItem.class == EMPTY_HANDS_CLASS then
                    -- Replace empty hands with the new weapon
                    playerItems.hotbar[i] = CreateItemData(weapon, i)
                    placed = true
                    break
                end
            end
            
            -- If hotbar is full with real weapons, place in inventory
            if not placed then
                for i = 1, 30 do -- 5x6 = 30 slots
                    if not playerItems.inventory[i] then
                        playerItems.inventory[i] = CreateItemData(weapon, i)
                        placed = true
                        break
                    end
                end
            end
        end
    end
    
    -- Fill empty hotbar slots with empty hands weapons (invisible placeholders)
    local emptyHandsWeapon = nil
    for _, weapon in ipairs(currentWeapons) do
        if IsValid(weapon) and weapon:GetClass() == EMPTY_HANDS_CLASS then
            emptyHandsWeapon = weapon
            break
        end
    end
    
    if emptyHandsWeapon then
        local hotbarSlots = RustInventory.Constants.HOTBAR_SLOTS
        for i = 1, hotbarSlots do
            if not playerItems.hotbar[i] then
                playerItems.hotbar[i] = CreateItemData(emptyHandsWeapon, i)
            end
        end
    end
    
    -- Trigger update for UI
    hook.Run("RustInventory_ItemsUpdated")
    
    -- Update active slot weapon after inventory changes
    UpdateActiveSlotWeapon()
end

-- Get hotbar items
function RustInventory.Items.GetHotbarItems()
    return playerItems.hotbar
end

-- Get inventory items
function RustInventory.Items.GetInventoryItems()
    return playerItems.inventory
end

-- Get specific hotbar item
function RustInventory.Items.GetHotbarItem(slot)
    return playerItems.hotbar[slot]
end

-- Get specific inventory item
function RustInventory.Items.GetInventoryItem(slot)
    return playerItems.inventory[slot]
end

-- Check if hotbar slot has item (visible item, not empty hands)
function RustInventory.Items.HasHotbarItem(slot)
    local item = playerItems.hotbar[slot]
    return item ~= nil and item.class ~= EMPTY_HANDS_CLASS
end

-- Check if inventory slot has item
function RustInventory.Items.HasInventoryItem(slot)
    return playerItems.inventory[slot] ~= nil
end

-- Get item at hotbar slot with validation
function RustInventory.Items.GetValidHotbarItem(slot)
    local item = playerItems.hotbar[slot]
    if item and IsValid(item.weapon) and item.class ~= EMPTY_HANDS_CLASS then
        return item
    end
    return nil
end

-- Switch to weapon in hotbar slot (slot-based switching)
function RustInventory.Items.SwitchToHotbarItem(slot)
    if not slot or slot < 1 or slot > 6 then return end
    
    -- Set this as the active slot
    activeHotbarSlot = slot
    
    -- Get the item currently in this slot
    local item = RustInventory.Items.GetValidHotbarItem(slot)
    
    if item then
        -- There's a weapon in this slot, equip it
        RunConsoleCommand("use", item.class)
        lastEquippedWeapon = item.class
    else
        -- Slot is empty, equip empty hands
        RunConsoleCommand("use", EMPTY_HANDS_CLASS)
        lastEquippedWeapon = EMPTY_HANDS_CLASS
    end
    
    -- Trigger UI update to show active slot change
    hook.Run("RustInventory_ItemsUpdated")
end

-- Add function to get active slot (exposed for UI)
function RustInventory.Items.GetActiveHotbarSlot()
    return activeHotbarSlot
end

-- Initialize active slot tracking
local function InitializeActiveSlot()
    -- Ensure player has empty hands weapon
    local player = LocalPlayer()
    if not IsValid(player) then return end
    
    -- Check if player has empty hands weapon, if not give it to them
    local hasEmptyHands = false
    local weapons = player:GetWeapons()
    for _, weapon in pairs(weapons) do
        if IsValid(weapon) and weapon:GetClass() == EMPTY_HANDS_CLASS then
            hasEmptyHands = true
            break
        end
    end
    
    if not hasEmptyHands then
        -- Give the player empty hands weapon
        RunConsoleCommand("give", EMPTY_HANDS_CLASS)
    end
    
    -- Check what weapon is currently equipped
    local currentWeapon = player:GetActiveWeapon()
    if IsValid(currentWeapon) then
        local weaponClass = currentWeapon:GetClass()
        
        -- Don't track empty hands as a "real" equipped weapon
        if weaponClass == EMPTY_HANDS_CLASS then
            activeHotbarSlot = 1
            lastEquippedWeapon = EMPTY_HANDS_CLASS
            return
        end
        
        -- Find which hotbar slot contains this weapon
        for i = 1, 6 do
            local item = RustInventory.Items.GetValidHotbarItem(i)
            if item and item.class == weaponClass then
                activeHotbarSlot = i
                lastEquippedWeapon = weaponClass
                return
            end
        end
    end
    
    -- No weapon equipped or weapon not in hotbar, default to slot 1 with empty hands
    activeHotbarSlot = 1
    lastEquippedWeapon = EMPTY_HANDS_CLASS
end

-- Initialize inventory scanning
hook.Add("InitPostEntity", "RustInventory_InitItems", function()
    timer.Simple(1, function()
        RustInventory.Items.UpdateInventory()
        InitializeActiveSlot()
    end)
end)

-- Update inventory when weapons change
hook.Add("WeaponEquipped", "RustInventory_WeaponEquipped", function(weapon, owner)
    if owner == LocalPlayer() then
        timer.Simple(0.1, function()
            RustInventory.Items.UpdateInventory()
        end)
    end
end)

-- Update inventory when weapons are dropped
hook.Add("PlayerDroppedWeapon", "RustInventory_WeaponDropped", function(owner, weapon)
    if owner == LocalPlayer() then
        timer.Simple(0.1, function()
            RustInventory.Items.UpdateInventory()
        end)
    end
end)

-- Update inventory periodically and on spawn
hook.Add("PlayerSpawn", "RustInventory_PlayerSpawn", function(ply)
    if ply == LocalPlayer() then
        timer.Simple(0.5, function()
            RustInventory.Items.UpdateInventory()
        end)
    end
end)

-- Update inventory every few seconds to catch any changes
timer.Create("RustInventory_UpdateTimer", 3, 0, function()
    RustInventory.Items.UpdateInventory()
end)

-- Check active slot weapon every second to ensure it's correct
timer.Create("RustInventory_ActiveSlotCheck", 1, 0, function()
    if RustInventory.Items and RustInventory.Items.GetValidHotbarItem then
        UpdateActiveSlotWeapon()
    end
end)

-- Console command to manually update inventory
concommand.Add("rust_inventory_update", function()
    RustInventory.Items.UpdateInventory()
    print("Rust Inventory updated")
end)

-- Console command to print current inventory
concommand.Add("rust_inventory_debug", function()
    print("=== Rust Inventory Debug ===")
    print("Hotbar items:")
    for i, item in pairs(playerItems.hotbar) do
        print(string.format("  [%d] %s (%s)", i, item.name, item.class))
    end
    print("Inventory items:")
    for i, item in pairs(playerItems.inventory) do
        print(string.format("  [%d] %s (%s)", i, item.name, item.class))
    end
    print("=== End Debug ===")
end)

-- Console command to debug active slot system
concommand.Add("rust_inventory_debug_slots", function()
    print("=== Rust Inventory Slot Debug ===")
    print("Active hotbar slot:", activeHotbarSlot)
    print("Last equipped weapon:", lastEquippedWeapon or "none")
    
    local player = LocalPlayer()
    if IsValid(player) then
        local currentWeapon = player:GetActiveWeapon()
        local currentClass = IsValid(currentWeapon) and currentWeapon:GetClass() or "none"
        print("Actually equipped weapon:", currentClass)
    end
    
    print("Hotbar slot contents:")
    for i = 1, 6 do
        local item = RustInventory.Items.GetValidHotbarItem(i)
        if item then
            print(string.format("  [%d] %s (%s)%s", i, item.name, item.class, (i == activeHotbarSlot and " <- ACTIVE" or "")))
        else
            local rawItem = playerItems.hotbar[i]
            if rawItem and rawItem.class == EMPTY_HANDS_CLASS then
                print(string.format("  [%d] Empty (invisible hands)%s", i, (i == activeHotbarSlot and " <- ACTIVE" or "")))
            else
                print(string.format("  [%d] Empty%s", i, (i == activeHotbarSlot and " <- ACTIVE" or "")))
            end
        end
    end
    print("=== End Slot Debug ===")
end)

-- Handle hotkey switching (1-6 keys)
local hotkeys = {KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6}
local lastHotkeyState = {}

hook.Add("Think", "RustInventory_HotkeyCheck", function()
    -- Only check hotkeys if inventory is closed
    if IsValid(inventoryPanel) then return end
    
    for i, key in ipairs(hotkeys) do
        local isPressed = input.IsKeyDown(key)
        local wasPressed = lastHotkeyState[key] or false
        
        -- Check if key was just pressed (not held)
        if isPressed and not wasPressed then
            -- Check if we're not typing in a text field
            local keyboardFocus = vgui.GetKeyboardFocus()
            if not keyboardFocus or not keyboardFocus.IsTextEntry then
                -- Switch to weapon in hotbar slot
                if RustInventory.Items then
                    RustInventory.Items.SwitchToHotbarItem(i)
                end
            end
        end
        
        lastHotkeyState[key] = isPressed
    end
end)

-- Tooltip system for items
RustInventory.Tooltip = {}

function RustInventory.Tooltip.Show(item, x, y)
    if not item then return end
    
    -- Create tooltip text
    local tooltipText = item.name
    if item.ammo and item.ammo > 0 and item.maxAmmo > 0 then
        tooltipText = tooltipText .. "\nAmmo: " .. item.ammo .. "/" .. item.maxAmmo
    end
    
    -- Draw tooltip background
    surface.SetFont("RustInventory_Small")
    local textW, textH = surface.GetTextSize(tooltipText)
    local tooltipW = textW + 20
    local tooltipH = textH + 10
    
    -- Position tooltip near cursor
    local tooltipX = math.min(x + 10, ScrW() - tooltipW - 10)
    local tooltipY = math.min(y - tooltipH - 10, ScrH() - tooltipH - 10)
    
    -- Draw tooltip
    draw.RoundedBox(4, tooltipX, tooltipY, tooltipW, tooltipH, RustInventory.Colors.bg_dark)
    draw.RoundedBox(4, tooltipX + 1, tooltipY + 1, tooltipW - 2, tooltipH - 2, RustInventory.Colors.bg_secondary)
    
    -- Draw text
    draw.SimpleText(tooltipText, "RustInventory_Small", tooltipX + 10, tooltipY + 5, RustInventory.Colors.text_primary)
end

-- Configuration for disabling default HUD
local disableDefaultHUD = true

-- Console command to toggle default HUD
concommand.Add("rust_inventory_toggle_default_hud", function()
    disableDefaultHUD = not disableDefaultHUD
    print("Default GMod weapon HUD " .. (disableDefaultHUD and "disabled" or "enabled"))
end)

-- Update the HUD disable function to use the toggle
hook.Remove("HUDShouldDraw", "RustInventory_DisableDefaultHUD")
hook.Add("HUDShouldDraw", "RustInventory_DisableDefaultHUD", function(name)
    if not disableDefaultHUD then return end
    
    -- Hide the default weapon selection HUD
    if name == "CHudWeaponSelection" then
        return false
    end
    
    -- Hide the default ammo display
    if name == "CHudAmmo" then
        return false
    end
end)

-- Alternative method: Override the weapon selection system
local function DisableWeaponSelection()
    -- Override the weapon selection functions to prevent default behavior
    local oldSelectWeapon = input.SelectWeapon
    input.SelectWeapon = function() end
    
    -- Disable the weapon selection wheel
    local oldCancelSelect = input.CancelSelect
    input.CancelSelect = function() end
end

-- Apply the override
hook.Add("Initialize", "RustInventory_DisableSelection", DisableWeaponSelection)

-- Disable default weapon switching keys and selection
hook.Add("PlayerBindPress", "RustInventory_DisableDefaultKeys", function(ply, bind, pressed)
    if ply != LocalPlayer() then return end
    
    -- Disable default weapon selection keys
    if string.find(bind, "slot") then
        -- Don't allow default slot binds (slot1, slot2, etc.)
        return true -- Return true to suppress the default action
    end
    
    -- Disable invnext and invprev (scroll wheel weapon switching)
    if bind == "invnext" or bind == "invprev" then
        return true -- Suppress default weapon scrolling
    end
    
    -- Disable lastinv (last weapon switching)
    if bind == "lastinv" then
        return true -- Suppress last weapon switching
    end
end)

-- Override the weapon selection input to prevent the default HUD from showing
local function OverrideWeaponInput()
    -- Hook into the weapon selection system
    hook.Add("Think", "RustInventory_SuppressWeaponHUD", function()
        -- Force hide the weapon selection if it's shown
        if input.IsKeyDown(KEY_Q) then
            -- Prevent the default behavior of Q key
            return
        end
    end)
end

-- Apply the input override
hook.Add("InitPostEntity", "RustInventory_OverrideInput", OverrideWeaponInput)

-- Item movement system
RustInventory.ItemMovement = {}
-- Variables were moved to the top of the file for global access

-- Pick up an item
function RustInventory.ItemMovement.PickupItem(item, slotIndex, slotType)
    pickedUpItem = item
    pickedUpFromSlot = slotIndex
    pickedUpFromType = slotType
    
    -- Remove item from its current location
    if slotType == "hotbar" then
        playerItems.hotbar[slotIndex] = nil
        -- If we picked up an item from the active slot, update weapon immediately
        if slotIndex == activeHotbarSlot then
            UpdateActiveSlotWeapon()
        end
    elseif slotType == "inventory" then
        playerItems.inventory[slotIndex] = nil
    end
    
    -- Trigger UI update
    hook.Run("RustInventory_ItemsUpdated")
end

-- Drop an item into a slot
function RustInventory.ItemMovement.DropItem(targetSlot, targetType)
    if not pickedUpItem then return false end
    
    -- Check if target slot is occupied
    local targetOccupied = false
    local targetItem = nil
    
    if targetType == "hotbar" then
        targetOccupied = playerItems.hotbar[targetSlot] ~= nil
        targetItem = playerItems.hotbar[targetSlot]
    elseif targetType == "inventory" then
        targetOccupied = playerItems.inventory[targetSlot] ~= nil
        targetItem = playerItems.inventory[targetSlot]
    end
    
    if targetOccupied then
        -- Special case: If dropping inventory item on hotbar slot with empty hands,
        -- remove the empty hands instead of swapping
        if pickedUpFromType == "inventory" and targetType == "hotbar" and 
           targetItem and targetItem.class == "weapon_empty_hands" then
            -- Remove empty hands weapon instead of swapping (use console command)
            RunConsoleCommand("drop", "weapon_empty_hands")
            -- Clear the pickup source slot (don't put empty hands in inventory)
            playerItems.inventory[pickedUpFromSlot] = nil
        else
            -- Normal swap behavior for all other cases
            if pickedUpFromType == "hotbar" then
                playerItems.hotbar[pickedUpFromSlot] = targetItem
            elseif pickedUpFromType == "inventory" then
                playerItems.inventory[pickedUpFromSlot] = targetItem
            end
        end
    else
        -- Target slot is empty, just clear the pickup source
        if pickedUpFromType == "hotbar" then
            playerItems.hotbar[pickedUpFromSlot] = nil
        elseif pickedUpFromType == "inventory" then
            playerItems.inventory[pickedUpFromSlot] = nil
        end
    end
    
    -- Place the picked up item in the target slot
    if targetType == "hotbar" then
        playerItems.hotbar[targetSlot] = pickedUpItem
    elseif targetType == "inventory" then
        playerItems.inventory[targetSlot] = pickedUpItem
    end
    
    -- Clear pickup state
    pickedUpItem = nil
    pickedUpFromSlot = nil
    pickedUpFromType = nil
    
    -- Update active slot weapon if hotbar was affected
    if targetType == "hotbar" or pickedUpFromType == "hotbar" then
        UpdateActiveSlotWeapon()
    end
    
    -- Trigger UI update
    hook.Run("RustInventory_ItemsUpdated")
    return true
end

-- Cancel pickup (return item to original slot)
function RustInventory.ItemMovement.CancelPickup()
    if not pickedUpItem then return end
    
    -- Return item to original slot
    if pickedUpFromType == "hotbar" then
        playerItems.hotbar[pickedUpFromSlot] = pickedUpItem
        -- If we returned an item to the active slot, update weapon
        if pickedUpFromSlot == activeHotbarSlot then
            UpdateActiveSlotWeapon()
        end
    elseif pickedUpFromType == "inventory" then
        playerItems.inventory[pickedUpFromSlot] = pickedUpItem
    end
    
    -- Clear pickup state
    pickedUpItem = nil
    pickedUpFromSlot = nil
    pickedUpFromType = nil
    
    -- Trigger UI update
    hook.Run("RustInventory_ItemsUpdated")
end

-- Get currently picked up item
function RustInventory.ItemMovement.GetPickedUpItem()
    return pickedUpItem
end

-- Check if an item is picked up
function RustInventory.ItemMovement.HasPickedUpItem()
    return pickedUpItem ~= nil
end
