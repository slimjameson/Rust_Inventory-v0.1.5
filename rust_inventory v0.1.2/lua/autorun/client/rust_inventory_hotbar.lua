-- Rust Inventory UI - Persistent Hotbar
-- This script handles the always-visible hotbar at the bottom of the screen

local HOTBAR_PANEL = {}

function HOTBAR_PANEL:Init()
    -- Wait for RustInventory to be initialized
    if not RustInventory then
        timer.Simple(0.1, function()
            if IsValid(self) then
                self:Init()
            end
        end)
        return
    end
    
    local screenW, screenH = ScrW(), ScrH()
    local hotbarSlots = RustInventory.Constants.HOTBAR_SLOTS
    local slotSize = RustInventory.Constants.SLOT_SIZE
    local slotSpacing = RustInventory.Constants.SLOT_SPACING
    local hotbarWidth = (slotSize + slotSpacing) * hotbarSlots - slotSpacing + 20
    
    -- Position at bottom center of screen
    local hotbarX = (screenW - hotbarWidth) / 2
    local hotbarY = screenH - 90 -- 90 pixels from bottom
    
    self:SetPos(hotbarX, hotbarY)
    self:SetSize(hotbarWidth, slotSize + 20)
    self:SetPaintBackground(false)
    self:SetMouseInputEnabled(true)
    
    -- Create hotbar slots
    self.HotbarSlots = {}
    
    for i = 1, hotbarSlots do
        local slotPanel = vgui.Create("DPanel", self)
        local x = 10 + (i - 1) * (slotSize + slotSpacing)
        local y = 10
        
        slotPanel:SetPos(x, y)
        slotPanel:SetSize(slotSize, slotSize)
        slotPanel.SlotIndex = i
        slotPanel.IsHovered = false
        slotPanel.Paint = function(s, w, h)
            -- Check if we have an item for this slot
            local hasItem = false
            local item = nil
            local isActiveSlot = false
            
            if RustInventory.Items then
                hasItem = RustInventory.Items.HasHotbarItem(i)
                item = RustInventory.Items.GetHotbarItem(i)
                isActiveSlot = (RustInventory.Items.GetActiveHotbarSlot() == i)
            end
            
            RustInventory.Draw.Slot(0, 0, w, h, s.IsHovered, isActiveSlot, hasItem)
            
            -- Draw slot number in top-left corner
            draw.SimpleText(tostring(i), "RustInventory_Small", 3, 3, RustInventory.Colors.text_secondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Draw item if present
            if hasItem and item then
                -- Check if we have a valid icon
                local hasValidIcon = false
                local iconMaterial = nil
                
                if item.icon then
                    iconMaterial = Material(item.icon)
                    hasValidIcon = iconMaterial and not iconMaterial:IsError()
                end
                
                if hasValidIcon then
                    -- Draw the icon if it's valid
                    local iconSize = w * 0.6
                    local iconX = (w - iconSize) / 2
                    local iconY = (h - iconSize) / 2
                    
                    surface.SetDrawColor(255, 255, 255, 255)
                    surface.SetMaterial(iconMaterial)
                    surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
                else
                    -- Fallback: draw the item name if no valid icon
                    local itemName = item.name or item.class
                    -- Make text smaller to fit in slot
                    surface.SetFont("RustInventory_Small")
                    local textW, textH = surface.GetTextSize(itemName)
                    
                    -- Scale text to fit in the slot
                    local maxTextW = w - 6
                    local maxTextH = h - 6
                    
                    if textW > maxTextW then
                        -- Truncate text if too long
                        local chars = string.len(itemName)
                        local avgCharWidth = textW / chars
                        local maxChars = math.floor(maxTextW / avgCharWidth)
                        itemName = string.sub(itemName, 1, maxChars - 2) .. ".."
                    end
                    
                    -- Draw text centered in slot
                    draw.SimpleText(itemName, "RustInventory_Small", w/2, h/2, RustInventory.Colors.text_primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                
                -- Draw ammo count if weapon has ammo
                if item.ammo and item.ammo > 0 and item.maxAmmo > 0 then
                    local ammoText = tostring(item.ammo)
                    draw.SimpleText(ammoText, "RustInventory_Small", w - 3, h - 3, RustInventory.Colors.text_accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                end
            end
            
            -- Draw hotkey number
            draw.SimpleText(tostring(i), "RustInventory_Small", w - 5, 5, RustInventory.Colors.text_accent, TEXT_ALIGN_RIGHT)
        end
        
        slotPanel.OnCursorEntered = function(s)
            s.IsHovered = true
            
            -- Store item for potential tooltip
            if RustInventory.Items then
                s.HoveredItem = RustInventory.Items.GetHotbarItem(i)
            end
        end
        
        slotPanel.OnCursorExited = function(s)
            s.IsHovered = false
            s.HoveredItem = nil
        end
        
        slotPanel.OnMousePressed = function(s, keyCode)
            if keyCode == MOUSE_LEFT then
                -- Only allow item movement when inventory is open
                if not IsValid(inventoryPanel) then return end
                
                -- Check if we have a picked up item to drop
                if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
                    -- Drop the picked up item here
                    RustInventory.ItemMovement.DropItem(i, "hotbar")
                else
                    -- Pick up the item in this slot
                    if RustInventory.Items and RustInventory.Items.HasHotbarItem(i) then
                        local item = RustInventory.Items.GetHotbarItem(i)
                        if item then
                            RustInventory.ItemMovement.PickupItem(item, i, "hotbar")
                        end
                    end
                end
            end
        end
        
        self.HotbarSlots[i] = slotPanel
    end
end

function HOTBAR_PANEL:Paint(w, h)
    -- Draw tooltips for hovered items
    for i, slot in pairs(self.HotbarSlots) do
        if IsValid(slot) and slot.IsHovered and slot.HoveredItem then
            local mx, my = gui.MousePos()
            if RustInventory.Tooltip then
                RustInventory.Tooltip.Show(slot.HoveredItem, mx, my)
            end
        end
    end
end

vgui.Register("RustPersistentHotbar", HOTBAR_PANEL, "DPanel")

-- Global variable to store the persistent hotbar
local persistentHotbar = nil

-- Create the persistent hotbar when the player spawns
local function CreatePersistentHotbar()
    if IsValid(persistentHotbar) then
        persistentHotbar:Remove()
    end
    
    persistentHotbar = vgui.Create("RustPersistentHotbar")
    persistentHotbar:SetParent(GetHUDPanel())
end

-- Initialize the hotbar
hook.Add("InitPostEntity", "RustInventory_CreateHotbar", CreatePersistentHotbar)

-- Recreate hotbar on resolution change
hook.Add("OnScreenSizeChanged", "RustInventory_RecreateHotbar", CreatePersistentHotbar)

-- Handle hiding the hotbar when inventory opens
hook.Add("RustInventory_HideHotbar", "RustInventory_HideHotbar", function()
    if IsValid(persistentHotbar) then
        persistentHotbar:SetVisible(false)
    end
end)

-- Handle showing the hotbar when inventory closes
hook.Add("RustInventory_ShowHotbar", "RustInventory_ShowHotbar", function()
    if IsValid(persistentHotbar) then
        persistentHotbar:SetVisible(true)
    end
end)

-- Clean up hotbar when needed
hook.Add("ShutDown", "RustInventory_CleanupHotbar", function()
    if IsValid(persistentHotbar) then
        persistentHotbar:Remove()
        persistentHotbar = nil
    end
end)

-- Function to refresh hotbar display
local function RefreshHotbar()
    if IsValid(persistentHotbar) then
        -- Force repaint of all hotbar slots
        for i = 1, RustInventory.Constants.HOTBAR_SLOTS do
            if IsValid(persistentHotbar.HotbarSlots[i]) then
                persistentHotbar.HotbarSlots[i]:InvalidateLayout(true)
            end
        end
    end
end

-- Listen for inventory updates
hook.Add("RustInventory_ItemsUpdated", "RustInventory_RefreshHotbar", RefreshHotbar)
