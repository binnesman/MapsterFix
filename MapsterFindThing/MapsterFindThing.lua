-- MapsterFindThing addon for WoW 3.3.5a
-- Repositions the FindThingFrame on the world map

local addonName, addon = ...
local frame = CreateFrame("Frame")

-- Default saved variables
local defaults = {
    xOffset = 0,     -- Default X offset (0 for automatic positioning)
    yOffset = 0,     -- Default Y offset (0 for automatic positioning)
    useAutoPosition = true  -- Use automatic positioning by default
}

-- Initialize saved variables
local function InitializeSavedVariables()
    if not MapsterFindThingDB then
        MapsterFindThingDB = {}
    end
    
    -- Set defaults for missing values
    for k, v in pairs(defaults) do
        if MapsterFindThingDB[k] == nil then
            MapsterFindThingDB[k] = v
        end
    end
end

-- Function to reposition the FindThingFrame
local function RepositionFindThingFrame()
    if not FindThingFrame or not WorldMapFrame then
        return
    end
    
    -- Clear all current points
    FindThingFrame:ClearAllPoints()
    
    if MapsterFindThingDB.useAutoPosition then
        -- Use automatic positioning (frame appears to the right of the map)
        FindThingFrame:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 0, 0)
    else
        -- Use manual positioning with saved offsets
        FindThingFrame:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 
                               MapsterFindThingDB.xOffset, 
                               MapsterFindThingDB.yOffset)
    end
end

-- Hook to reposition when world map is shown
local function OnWorldMapShow()
    -- Small delay to ensure frames are properly loaded
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer >= 0.1 then
            RepositionFindThingFrame()
            self:SetScript("OnUpdate", nil)
            self.timer = 0
        end
    end)
end

-- Event handling
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("WORLD_MAP_UPDATE")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitializeSavedVariables()
        
        -- Hook the WorldMapFrame OnShow
        if WorldMapFrame then
            WorldMapFrame:HookScript("OnShow", OnWorldMapShow)
        end
        
        print("|cFF00FF00MapsterFindThing|r loaded. Type |cFFFFFF00/findthing|r for help.")
        
    elseif event == "PLAYER_LOGIN" then
        -- Additional attempt to hook if WorldMapFrame wasn't ready
        if WorldMapFrame and not WorldMapFrame:GetScript("OnShow") then
            WorldMapFrame:HookScript("OnShow", OnWorldMapShow)
        end
        
    elseif event == "WORLD_MAP_UPDATE" then
        -- Reposition whenever the world map updates
        RepositionFindThingFrame()
    end
end)

-- Slash command handling
SLASH_MAPSTERFINDTHING1 = "/findthing"
SLASH_MAPSTERFINDTHING2 = "/ft"  -- Short version

SlashCmdList["MAPSTERFINDTHING"] = function(msg)
    local command, value = strsplit(" ", msg)
    command = command and command:lower() or ""
    value = tonumber(value)
    
    if command == "auto" then
        MapsterFindThingDB.useAutoPosition = true
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Switched to automatic positioning")
        
    elseif command == "manual" then
        MapsterFindThingDB.useAutoPosition = false
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Switched to manual positioning")
        
    elseif command == "x" and value then
        MapsterFindThingDB.useAutoPosition = false
        MapsterFindThingDB.xOffset = value
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r X offset set to " .. value .. " (manual mode)")
        
    elseif command == "y" and value then
        MapsterFindThingDB.useAutoPosition = false
        MapsterFindThingDB.yOffset = value
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Y offset set to " .. value .. " (manual mode)")
        
    elseif command == "reset" then
        MapsterFindThingDB.xOffset = defaults.xOffset
        MapsterFindThingDB.yOffset = defaults.yOffset
        MapsterFindThingDB.useAutoPosition = defaults.useAutoPosition
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Position reset to defaults (auto mode)")
        
    elseif command == "show" or command == "status" then
        print("|cFF00FF00MapsterFindThing:|r Current settings:")
        if MapsterFindThingDB.useAutoPosition then
            print("  Mode: |cFF00FF00Automatic|r (frame to the right of map)")
        else
            print("  Mode: |cFFFFFF00Manual|r")
            print("  X offset: " .. MapsterFindThingDB.xOffset)
            print("  Y offset: " .. MapsterFindThingDB.yOffset)
        end
        
    else
        -- Help text
        print("|cFF00FF00MapsterFindThing|r commands:")
        print("  |cFFFFFF00/findthing auto|r - Use automatic positioning")
        print("  |cFFFFFF00/findthing manual|r - Use manual positioning")
        print("  |cFFFFFF00/findthing x <number>|r - Set X offset (switches to manual)")
        print("  |cFFFFFF00/findthing y <number>|r - Set Y offset (switches to manual)")
        print("  |cFFFFFF00/findthing reset|r - Reset to defaults (auto mode)")
        print("  |cFFFFFF00/findthing show|r - Show current settings")
        print("  |cFFFFFF00/ft|r - Short version of /findthing")
        if MapsterFindThingDB.useAutoPosition then
            print("  Current: |cFF00FF00Automatic positioning|r")
        else
            print("  Current: Manual (X=" .. MapsterFindThingDB.xOffset .. ", Y=" .. MapsterFindThingDB.yOffset .. ")")
        end
    end
end

-- Additional hook for Mapster compatibility
local mapsterCheckTimer = 0
frame:SetScript("OnUpdate", function(self, elapsed)
    mapsterCheckTimer = mapsterCheckTimer + elapsed
    if mapsterCheckTimer >= 1 then  -- Check every second for first 10 seconds
        mapsterCheckTimer = 0
        
        -- Check if Mapster has loaded and created frames
        if WorldMapFrame and FindThingFrame then
            RepositionFindThingFrame()
            
            -- Stop checking after 10 attempts
            self.attemptCount = (self.attemptCount or 0) + 1
            if self.attemptCount >= 10 then
                self:SetScript("OnUpdate", nil)
            end
        end
    end
end)