-- Rust Inventory UI - Persistent Hotbar
-- This script handles the always-visible hotbar at the bottom of the screen

local HOTBAR_PANEL = {}

function HOTBAR_PANEL:Init()
    if not RustInventory then
        timer.Simple(0.1, function()
            if IsValid(self) then self:Init() end
        end)
        return
    end

    local screenW, screenH = ScrW(), ScrH()
    local hotbarSlots = RustInventory.Constants.HOTBAR_SLOTS
    local slotSize = RustInventory.Constants.SLOT_SIZE
    local slotSpacing = RustInventory.Constants.SLOT_SPACING
    local hotbarWidth = (slotSize + slotSpacing) * hotbarSlots - slotSpacing + 20

    local hotbarX = (screenW - hotbarWidth) / 2
    local hotbarY = screenH - 90

    self:SetPos(hotbarX, hotbarY)
    self:SetSize(hotbarWidth, slotSize + 20)
    self:SetPaintBackground(false)
    self:SetMouseInputEnabled(true)

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
            local hasItem, item, isActiveSlot = false, nil, false
            if RustInventory.Items then
                hasItem = RustInventory.Items.HasHotbarItem(i)
                item = RustInventory.Items.GetHotbarItem(i)
                isActiveSlot = (RustInventory.Items.GetActiveHotbarSlot() == i)
            end

            RustInventory.Draw.Slot(0, 0, w, h, s.IsHovered, isActiveSlot, hasItem)
            draw.SimpleText(tostring(i), "RustInventory_Small", 3, 3, RustInventory.Colors.text_secondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            if hasItem and item then
                if item.model and util.IsValidModel(item.model) then
                    if not IsValid(s.ModelPanel) then
                        s.ModelPanel = vgui.Create("DModelPanel", s)
                        s.ModelPanel:SetModel(item.model)
                        s.ModelPanel:SetSize(w, h)
                        s.ModelPanel:SetPos(0, 0)
                        s.ModelPanel:SetFOV(45)
                        s.ModelPanel:SetCamPos(Vector(20, 20, 20))
                        s.ModelPanel:SetLookAt(Vector(0, 0, 0))
                        s.ModelPanel:SetZPos(-1)
                        s.ModelPanel:SetMouseInputEnabled(false)
                        s.ModelPanel.LayoutEntity = function(pnl, ent)
                            ent:SetAngles(Angle(0, RealTime() * 50 % 360, 0))
                        end
                    end
                else
                    if IsValid(s.ModelPanel) then
                        s.ModelPanel:Remove()
                        s.ModelPanel = nil
                    end

                    local iconMaterial = item.icon and Material(item.icon)
                    if iconMaterial and not iconMaterial:IsError() then
                        local iconSize = w * 0.6
                        local iconX = (w - iconSize) / 2
                        local iconY = (h - iconSize) / 2
                        surface.SetDrawColor(255, 255, 255, 255)
                        surface.SetMaterial(iconMaterial)
                        surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
                    else
                        draw.SimpleText(item.name or item.class, "RustInventory_Small", w / 2, h / 2, RustInventory.Colors.text_primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end

                if item.ammo and item.ammo > 0 and item.maxAmmo > 0 then
                    draw.SimpleText(tostring(item.ammo), "RustInventory_Small", w - 3, h - 3, RustInventory.Colors.text_accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                end
            elseif IsValid(s.ModelPanel) then
                s.ModelPanel:Remove()
                s.ModelPanel = nil
            end

            draw.SimpleText(tostring(i), "RustInventory_Small", w - 5, 5, RustInventory.Colors.text_accent, TEXT_ALIGN_RIGHT)
        end

        slotPanel.OnCursorEntered = function(s)
            s.IsHovered = true
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
                if not IsValid(inventoryPanel) then return end

                if RustInventory.ItemMovement and RustInventory.ItemMovement.HasPickedUpItem() then
                    RustInventory.ItemMovement.DropItem(i, "hotbar")
                elseif RustInventory.Items and RustInventory.Items.HasHotbarItem(i) then
                    local item = RustInventory.Items.GetHotbarItem(i)
                    if item then
                        RustInventory.ItemMovement.PickupItem(item, i, "hotbar")
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
