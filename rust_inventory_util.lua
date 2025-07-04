-- Rust Inventory UI - Utility Functions
-- Helper functions for the inventory system

RustInventory = RustInventory or {}
RustInventory.Util = {}

-- Sound effects that could be used (optional)
RustInventory.Sounds = {
    open = "ui/buttonclick.wav",
    close = "ui/buttonclick.wav",
    hover = "ui/buttonrollover.wav",
    click = "ui/buttonclick.wav",
    error = "buttons/button10.wav"
}

-- Play a UI sound
function RustInventory.Util.PlaySound(soundName)
    local sound = RustInventory.Sounds[soundName]
    if sound then
        surface.PlaySound(sound)
    end
end

-- Get screen-relative position for centering
function RustInventory.Util.GetCenterPos(w, h)
    return (ScrW() - w) / 2, (ScrH() - h) / 2
end

-- Scale value based on screen resolution
function RustInventory.Util.Scale(value)
    local scale = math.min(ScrW() / 1920, ScrH() / 1080)
    return math.max(value * scale, value * 0.8) -- Minimum 80% scale
end

-- Check if point is within rectangle
function RustInventory.Util.IsPointInRect(x, y, rx, ry, rw, rh)
    return x >= rx and x <= rx + rw and y >= ry and y <= ry + rh
end

-- Linear interpolation
function RustInventory.Util.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Smooth lerp with easing
function RustInventory.Util.SmoothLerp(a, b, t)
    t = t * t * (3 - 2 * t) -- Smoothstep
    return RustInventory.Util.Lerp(a, b, t)
end

-- Format number with commas
function RustInventory.Util.FormatNumber(num)
    if not num then return "0" end
    local formatted = tostring(num)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Get item icon/texture (placeholder for future implementation)
function RustInventory.Util.GetItemIcon(itemType)
    -- This could be expanded to return actual item icons
    local icons = {
        weapon = "icon16/gun.png",
        tool = "icon16/wrench.png",
        clothing = "icon16/clothes.png",
        consumable = "icon16/food.png",
        resource = "icon16/brick.png",
        component = "icon16/cog.png",
        misc = "icon16/box.png"
    }
    return icons[itemType] or icons.misc
end

-- Get item color by rarity
function RustInventory.Util.GetRarityColor(rarity)
    local colors = {
        common = RustInventory.Colors.rarity_common,
        uncommon = RustInventory.Colors.rarity_uncommon,
        rare = RustInventory.Colors.rarity_rare,
        epic = RustInventory.Colors.rarity_epic,
        legendary = RustInventory.Colors.rarity_legendary
    }
    return colors[rarity] or colors.common
end

-- Draw a gradient
function RustInventory.Util.DrawGradient(x, y, w, h, colorTop, colorBottom)
    local gradientMat = Material("vgui/gradient-u")
    surface.SetMaterial(gradientMat)
    surface.SetDrawColor(colorTop)
    surface.DrawTexturedRect(x, y, w, h/2)
    surface.SetDrawColor(colorBottom)
    surface.DrawTexturedRect(x, y + h/2, w, h/2)
end

-- Draw a textured slot background
function RustInventory.Util.DrawSlotTexture(x, y, w, h, texture)
    if texture then
        surface.SetMaterial(Material(texture))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(x, y, w, h)
    end
end

-- Animation system for smooth transitions
RustInventory.Animations = {}
local activeAnimations = {}

function RustInventory.Animations.Create(object, property, targetValue, duration, easing)
    local startValue = object[property]
    local startTime = CurTime()
    
    local animData = {
        object = object,
        property = property,
        startValue = startValue,
        targetValue = targetValue,
        duration = duration,
        startTime = startTime,
        easing = easing or "linear"
    }
    
    table.insert(activeAnimations, animData)
    return animData
end

function RustInventory.Animations.Update()
    for i = #activeAnimations, 1, -1 do
        local anim = activeAnimations[i]
        local elapsed = CurTime() - anim.startTime
        local progress = math.min(elapsed / anim.duration, 1)
        
        -- Apply easing
        if anim.easing == "smooth" then
            progress = RustInventory.Util.SmoothLerp(0, 1, progress)
        end
        
        -- Update value
        anim.object[anim.property] = RustInventory.Util.Lerp(anim.startValue, anim.targetValue, progress)
        
        -- Remove completed animations
        if progress >= 1 then
            table.remove(activeAnimations, i)
        end
    end
end

-- Update animations every frame
hook.Add("Think", "RustInventory_UpdateAnimations", function()
    RustInventory.Animations.Update()
end)

-- Keybind system
RustInventory.Keybinds = {}

function RustInventory.Keybinds.IsPressed(key)
    return input.IsKeyDown(key)
end

function RustInventory.Keybinds.GetInventoryKey()
    return KEY_I
end

-- Debug functions
RustInventory.Debug = {}

function RustInventory.Debug.Print(...)
    if GetConVar("developer"):GetInt() > 0 then
        print("[RustInventory]", ...)
    end
end

function RustInventory.Debug.DrawBounds(x, y, w, h, color)
    if GetConVar("developer"):GetInt() > 0 then
        color = color or Color(255, 0, 0, 100)
        draw.RoundedBox(0, x, y, w, h, color)
    end
end
