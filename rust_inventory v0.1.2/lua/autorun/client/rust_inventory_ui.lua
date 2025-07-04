-- Rust Inventory UI - Main Client Script
-- This script handles the main inventory UI display and input handling

local PANEL = {}

function PANEL:Init()
    -- Wait for RustInventory to be initialized
    if not RustInventory then
        timer.Simple(0.1, function()
            if IsValid(self) then
                self:Init()
            end
        end)
        return
    end
    
    self:SetTitle("")
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()
    self:SetDraggable(false)
    self:SetSizable(false)
    self:ShowCloseButton(false)
    
    -- Hide the persistent hotbar when inventory is open
    hook.Run("RustInventory_HideHotbar")
    
    -- Create main container - fullscreen like Rust
    self.MainContainer = vgui.Create("DPanel", self)
    self.MainContainer:SetSize(self:GetWide(), self:GetTall())
    self.MainContainer:SetPos(0, 0)
    self.MainContainer.Paint = function(s, w, h)
        -- No background - let the main panel's blur handle it
    end
    
    -- Create player model panel
    self:CreatePlayerModelPanel()
    
    -- Create equipment slots
    self:CreateEquipmentSlots()
    
    -- Create main inventory grid
    self:CreateInventoryGrid()
    
    -- Create hotbar
    self:CreateHotbar()
end

function PANEL:CreatePlayerModelPanel()
    local screenW, screenH = self:GetWide(), self:GetTall()
    
    -- Make player model even larger
    local playerW, playerH = 500, 800
    
    -- Calculate position to align bottom with inventory
    -- Inventory is at screenH - 90 - inventoryHeight - 10, so we need to calculate that
    local slotSize = RustInventory.Constants.SLOT_SIZE
    local slotSpacing = RustInventory.Constants.SLOT_SPACING
    local rows = RustInventory.Constants.INVENTORY_ROWS
    local inventoryHeight = (slotSize + slotSpacing) * rows - slotSpacing + 20
    local inventoryBottomY = screenH - 90 - 10 -- Bottom of inventory panel (adjusted for new hotbar position)
    local playerY = inventoryBottomY - playerH -- Position so bottom aligns with inventory
    
    -- Player model without background panel - direct to main container
    self.PlayerModel = vgui.Create("DModelPanel", self.MainContainer)
    self.PlayerModel:SetPos(50, playerY)
    self.PlayerModel:SetSize(playerW, playerH)
    self.PlayerModel:SetModel(LocalPlayer():GetModel())
    self.PlayerModel:SetFOV(40)
    self.PlayerModel:SetCamPos(Vector(80, 0, 35))
    self.PlayerModel:SetLookAt(Vector(0, 0, 35))
    
    -- Add mouse control for player model
    function self.PlayerModel:DragMousePress()
        self.PressX, self.PressY = gui.MousePos()
        self.Pressed = true
    end
    
    function self.PlayerModel:DragMouseRelease()
        self.Pressed = false
    end
    
    function self.PlayerModel:LayoutEntity(ent)
        if self.Pressed then
            local mx, my = gui.MousePos()
            self.Angles = self.Angles or Angle(0, 0, 0)
            self.Angles.y = self.Angles.y + (mx - (self.PressX or mx)) * 0.5
            self.PressX, self.PressY = mx, my
        end
        
        if self.Angles then
            ent:SetAngles(self.Angles)
        end
    end
    
    -- Player name label positioned below the model
    self.PlayerNameLabel = vgui.Create("DLabel", self.MainContainer)
    self.PlayerNameLabel:SetPos(50, playerY + playerH + 10)
    self.PlayerNameLabel:SetSize(playerW, 20)
    self.PlayerNameLabel:SetText(LocalPlayer():Nick())
    self.PlayerNameLabel:SetFont("RustInventory_Main")
    self.PlayerNameLabel:SetTextColor(RustInventory.Colors.text_primary)
    self.PlayerNameLabel:SetContentAlignment(5)
end

function PANEL:CreateEquipmentSlots()
    local screenW, screenH = self:GetWide(), self:GetTall()
    local equipmentX = 580 -- Moved even further right to accommodate larger player model
    local equipmentY = 50
    
    -- Equipment slots without background panel
    self.EquipmentSlots = {}
    
    for i, slot in ipairs(RustInventory.EquipmentSlots) do
        local slotPanel = vgui.Create("DPanel", self.MainContainer)
        slotPanel:SetPos(equipmentX + slot.x, equipmentY + slot.y) -- Direct positioning on main container
        slotPanel:SetSize(RustInventory.Constants.SLOT_SIZE, RustInventory.Constants.SLOT_SIZE)
        slotPanel.SlotType = slot.name
        slotPanel.IsHovered = false
        slotPanel.Paint = function(s, w, h)
            RustInventory.Draw.Slot(0, 0, w, h, s.IsHovered, false, false)
            
            -- Draw slot type indicator
            draw.SimpleText(slot.name:upper():sub(1, 3), "RustInventory_Small", w/2, h/2, RustInventory.Colors.text_tertiary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        slotPanel.OnCursorEntered = function(s)
            s.IsHovered = true
        end
        
        slotPanel.OnCursorExited = function(s)
            s.IsHovered = false
        end
        
        self.EquipmentSlots[i] = slotPanel
    end
end

function PANEL:CreateInventoryGrid()
    local screenW, screenH = self:GetWide(), self:GetTall()
    local slotSize = RustInventory.Constants.SLOT_SIZE
    local slotSpacing = RustInventory.Constants.SLOT_SPACING
    local rows = RustInventory.Constants.INVENTORY_ROWS
    local cols = RustInventory.Constants.INVENTORY_COLS
    
    -- Calculate inventory panel dimensions
    local inventoryWidth = (slotSize + slotSpacing) * cols - slotSpacing + 20
    local inventoryHeight = (slotSize + slotSpacing) * rows - slotSpacing + 20
    
    -- Position above hotbar, centered horizontally
    local inventoryX = (screenW - inventoryWidth) / 2 -- Center horizontally
    local inventoryY = screenH - 90 - inventoryHeight - 10 -- Stack directly above hotbar (90px from bottom) with small gap
    
    -- Create inventory slots without background panel
    self.InventorySlots = {}
    
    for row = 1, rows do
        self.InventorySlots[row] = {}
        for col = 1, cols do
            local slotPanel = vgui.Create("DPanel", self.MainContainer)
            local x = inventoryX + 10 + (col - 1) * (slotSize + slotSpacing)
            local y = inventoryY + 10 + (row - 1) * (slotSize + slotSpacing)
            
            slotPanel:SetPos(x, y)
            slotPanel:SetSize(slotSize, slotSize)
            slotPanel.SlotRow = row
            slotPanel.SlotCol = col
            slotPanel.IsHovered = false
            slotPanel.Paint = function(s, w, h)
                -- Calculate linear slot index for inventory
                local slotIndex = (row - 1) * cols + col
                
                -- Check if we have an item for this slot
                local hasItem = false
                local item = nil
                
                if RustInventory.Items then
                    hasItem = RustInventory.Items.HasInventoryItem(slotIndex)
                    item = RustInventory.Items.GetInventoryItem(slotIndex)
                end
                
                RustInventory.Draw.Slot(0, 0, w, h, s.IsHovered, false, hasItem)
                
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
            end
            
            slotPanel.OnCursorEntered = function(s)
                s.IsHovered = true
                
                -- Store item for potential tooltip
                if RustInventory.Items then
                    local slotIndex = (row - 1) * cols + col
                    s.HoveredItem = RustInventory.Items.GetInventoryItem(slotIndex)
                end
            end
            
            slotPanel.OnCursorExited = function(s)
                s.IsHovered = false
                s.HoveredItem = nil
            end
            
            slotPanel.OnMousePressed = function(s, keyCode)
                if keyCode == MOUSE_LEFT then
                    -- Calculate linear slot index for inventory
                    local slotIndex = (row - 1) * cols + col
                    
                    -- Check if we have a picked up item to drop
                    if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
                        -- Drop the picked up item here
                        RustInventory.ItemMovement.DropItem(slotIndex, "inventory")
                    else
                        -- Pick up the item in this slot
                        if RustInventory.Items and RustInventory.Items.HasInventoryItem(slotIndex) then
                            local item = RustInventory.Items.GetInventoryItem(slotIndex)
                            if item then
                                RustInventory.ItemMovement.PickupItem(item, slotIndex, "inventory")
                            end
                        end
                    end
                end
            end
            
            self.InventorySlots[row][col] = slotPanel
        end
    end
end

function PANEL:CreateHotbar()
    local screenW, screenH = self:GetWide(), self:GetTall()
    local hotbarSlots = RustInventory.Constants.HOTBAR_SLOTS
    local slotSize = RustInventory.Constants.SLOT_SIZE
    local slotSpacing = RustInventory.Constants.SLOT_SPACING
    local hotbarWidth = (slotSize + slotSpacing) * hotbarSlots - slotSpacing + 20
    
    local hotbarX = (screenW - hotbarWidth) / 2 -- Center horizontally
    local hotbarY = screenH - 90 -- Match persistent hotbar position (90 pixels from bottom)
    
    -- Create hotbar slots without background panel
    self.HotbarSlots = {}
    
    for i = 1, hotbarSlots do
        local slotPanel = vgui.Create("DPanel", self.MainContainer)
        local x = hotbarX + 10 + (i - 1) * (slotSize + slotSpacing)
        local y = hotbarY + 10
        
        slotPanel:SetPos(x, y)
        slotPanel:SetSize(slotSize, slotSize)
        slotPanel.SlotIndex = i
        slotPanel.IsHovered = false
        slotPanel.Paint = function(s, w, h)
            -- Check if we have an item for this slot
            local hasItem = false
            local item = nil
            
            if RustInventory.Items then
                hasItem = RustInventory.Items.HasHotbarItem(i)
                item = RustInventory.Items.GetHotbarItem(i)
            end
            
            RustInventory.Draw.Slot(0, 0, w, h, s.IsHovered, false, hasItem)
            
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

function PANEL:Paint(w, h)
    -- Draw blurred background
    local mat = Material("pp/blurscreen")
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    
    -- Apply stronger blur effect
    mat:SetFloat("$blur", 4)
    mat:Recompute()
    render.UpdateScreenEffectTexture()
    surface.DrawTexturedRect(0, 0, w, h)
    
    -- Draw much darker overlay for better contrast (closer to Rust's style)
    draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 240))
    
end

-- PaintOver is called after all child panels are painted, ensuring the picked-up item is on top
function PANEL:PaintOver(w, h)
    local mx, my = gui.MousePos()

    -- Draw picked up item following mouse cursor (on top of everything)
    if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
        local pickedUpItem = RustInventory.ItemMovement.GetPickedUpItem()
        if pickedUpItem then
            local slotSize = RustInventory.Constants.SLOT_SIZE
            local itemX = mx - slotSize / 2
            local itemY = my - slotSize / 2

            -- Draw slot background
            RustInventory.Draw.Slot(itemX, itemY, slotSize, slotSize, false, true, true)

            -- Draw item icon or text
            local hasValidIcon = false
            local iconMaterial = nil

            if pickedUpItem.icon then
                iconMaterial = Material(pickedUpItem.icon)
                hasValidIcon = iconMaterial and not iconMaterial:IsError()
            end

            if hasValidIcon then
                local iconSize = slotSize * 0.6
                local iconX = itemX + (slotSize - iconSize) / 2
                local iconY = itemY + (slotSize - iconSize) / 2

                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(iconMaterial)
                surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
            else
                local itemName = pickedUpItem.name or pickedUpItem.class
                draw.SimpleText(itemName, "RustInventory_Small", itemX + slotSize / 2, itemY + slotSize / 2, RustInventory.Colors.text_primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Tooltips are now drawn above all UI
    if self.HotbarSlots then
        for _, slot in pairs(self.HotbarSlots) do
            if IsValid(slot) and slot.IsHovered and slot.HoveredItem then
                RustInventory.Tooltip.Show(slot.HoveredItem, mx, my)
            end
        end
    end

    if self.InventorySlots then
        for row = 1, RustInventory.Constants.INVENTORY_ROWS do
            for col = 1, RustInventory.Constants.INVENTORY_COLS do
                local slot = self.InventorySlots[row][col]
                if IsValid(slot) and slot.IsHovered and slot.HoveredItem then
                    RustInventory.Tooltip.Show(slot.HoveredItem, mx, my)
                end
            end
        end
    end
end

function PANEL:OnRemove()
    -- Cancel any picked up items when inventory is closed
    if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
        RustInventory.ItemMovement.CancelPickup()
    end
    
    -- Show the persistent hotbar when inventory is closed
    hook.Run("RustInventory_ShowHotbar")
end

function PANEL:RefreshInventory()
    -- Force repaint of all inventory slots
    if self.InventorySlots then
        for row = 1, RustInventory.Constants.INVENTORY_ROWS do
            for col = 1, RustInventory.Constants.INVENTORY_COLS do
                if IsValid(self.InventorySlots[row][col]) then
                    self.InventorySlots[row][col]:InvalidateLayout(true)
                end
            end
        end
    end
    
    -- Force repaint of hotbar slots
    if self.HotbarSlots then
        for i = 1, RustInventory.Constants.HOTBAR_SLOTS do
            if IsValid(self.HotbarSlots[i]) then
                self.HotbarSlots[i]:InvalidateLayout(true)
            end
        end
    end
end

function PANEL:OnKeyCodePressed(keyCode)
    if keyCode == KEY_ESCAPE then
        -- Cancel pickup if we have an item picked up
        if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
            RustInventory.ItemMovement.CancelPickup()
            return true -- Consume the key event
        else
            -- Close inventory normally
            self:Close()
            return true
        end
    end
end

function PANEL:OnMousePressed(keyCode)
    if keyCode == MOUSE_RIGHT then
        -- Cancel pickup on right click
        if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
            RustInventory.ItemMovement.CancelPickup()
        end
    end
end

vgui.Register("RustInventoryUI", PANEL, "DFrame")

-- Global variable to store the inventory panel
local inventoryPanel = nil

-- Function to toggle inventory
local function ToggleInventory()
    if IsValid(inventoryPanel) then
        inventoryPanel:Close()
        inventoryPanel = nil
    else
        inventoryPanel = vgui.Create("RustInventoryUI")
    end
end

-- Bind the inventory key using Think hook for key detection
local lastIPressed = false
hook.Add("Think", "RustInventoryKeyCheck", function()
    local isIPressed = input.IsKeyDown(KEY_I)
    
    -- Check if I key was just pressed (not held)
    if isIPressed and not lastIPressed then
        local keyboardFocus = vgui.GetKeyboardFocus()
        
        -- Allow I key if no focus, or if focus is the inventory panel itself
        if not keyboardFocus or (IsValid(inventoryPanel) and keyboardFocus == inventoryPanel) then
            ToggleInventory()
        end
    end
    
    lastIPressed = isIPressed
end)

-- Console command for testing
concommand.Add("rust_inventory", function()
    ToggleInventory()
end)

-- Function to refresh inventory UI when items change
local function RefreshInventoryUI()
    if IsValid(inventoryPanel) then
        inventoryPanel:RefreshInventory()
    end
end

-- Listen for inventory updates
hook.Add("RustInventory_ItemsUpdated", "RustInventory_RefreshUI", RefreshInventoryUI)


-- LISTEN FOR ESC FOR CLOSE (WAS MISSING)
hook.Add("Think", "RustInventory_EscapeClose", function()
    if IsValid(inventoryPanel) and RustInventory.Config.CloseOnEscape and input.IsKeyDown(KEY_ESCAPE) then
        -- Prevent rapid reopening/closing
        if not inventoryPanel.LastEscPress or CurTime() - inventoryPanel.LastEscPress > 0.3 then
            inventoryPanel.LastEscPress = CurTime()
            
            if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
                RustInventory.ItemMovement.CancelPickup()
            else
                inventoryPanel:Close()
                inventoryPanel = nil
            end
        end
    end
end)

