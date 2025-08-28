-- MapsterFindThing addon for WoW 3.3.5a
-- Repositions the FindThingFrame on the world map

local addonName, addon = ...
local frame = CreateFrame("Frame")

-- Default saved variables
local defaults = {
    xOffset = -220.5,  -- Default X offset from TopRight
    yOffset = -1   -- Default Y offset from TopRight
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
    
    -- Set new position anchored to WorldMapFrame's TopRight
    FindThingFrame:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", 
                           MapsterFindThingDB.xOffset, 
                           MapsterFindThingDB.yOffset)
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
    
    if command == "x" and value then
        MapsterFindThingDB.xOffset = value
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r X offset set to " .. value)
        
    elseif command == "y" and value then
        MapsterFindThingDB.yOffset = value
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Y offset set to " .. value)
        
    elseif command == "reset" then
        MapsterFindThingDB.xOffset = defaults.xOffset
        MapsterFindThingDB.yOffset = defaults.yOffset
        RepositionFindThingFrame()
        print("|cFF00FF00MapsterFindThing:|r Position reset to defaults")
        
    elseif command == "show" or command == "status" then
        print("|cFF00FF00MapsterFindThing:|r Current position:")
        print("  X offset: " .. MapsterFindThingDB.xOffset)
        print("  Y offset: " .. MapsterFindThingDB.yOffset)
        
    else
        -- Help text
        print("|cFF00FF00MapsterFindThing|r commands:")
        print("  |cFFFFFF00/findthing x <number>|r - Set X offset (negative = left)")
        print("  |cFFFFFF00/findthing y <number>|r - Set Y offset (negative = up)")
        print("  |cFFFFFF00/findthing reset|r - Reset to default position")
        print("  |cFFFFFF00/findthing show|r - Show current position")
        print("  |cFFFFFF00/ft|r - Short version of /findthing")
        print("  Current: X=" .. MapsterFindThingDB.xOffset .. ", Y=" .. MapsterFindThingDB.yOffset)
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