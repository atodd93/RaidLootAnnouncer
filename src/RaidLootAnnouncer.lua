--[[
********************************************************************************
RaidLootAnnouncer
v1.0.0
21 March 2025
(Originally written for Live Servers v11.1.0.59679)

Author: Heuto @ Moon Guard Alliance
********************************************************************************

Description:
	RaidLootAnnouncer will allow you to automatically announce to your raid
    pre-established looted items imported via Cecil Discord Bot.

Features:
	- Import loot announcements submitted via CSV formatting

Download:
	The latest version of RaidLootAnnouncer is always available on
	- Curseforge

Localization:
	You can contribute by updating/adding localizations using the system on
	- On a future Git Repo

Contact:
	If you find any bugs or have any suggestions, you can contact us on:

	Discord: heuto
]]

local addonName, addonTable = 'RaidLootAnnouncer', 'RaidLootAnnouncerDB'

RaidLootAnnouncer = {}
local RLA = RaidLootAnnouncer

RLA.encounters = {}

-- Saved Variables Initialization
function RLA:Initialize()
    if not RaidLootAnnouncerDB then
        RaidLootAnnouncerDB = {  }
    end

    RaidLootAnnouncerDB.tiers = RaidLootAnnouncerDB.tiers or {}
    RaidLootAnnouncerDB.encounters = RaidLootAnnouncerDB.encounters or {}
    RaidLootAnnouncerDB.lootReserves = RaidLootAnnouncerDB.lootReserves or {}
    RaidLootAnnouncerDB.profile = RaidLootAnnouncerDB.profile or {}

    RLA.defaultData = {
        -- This structure is used due to it being a key-value pair before which is more difficult to deal with in Lua
        tiers = {
            { text = "Palace Neru'bar", value = "11.0", data = {} },
            { text = "Liberation of Undermine", value = "11.1", data = {} },
            { text = "Heuto's House", value = "11.2", data = {} }
        },
        encounters = {
            { difficulty = "Normal", boss = "Rasha'nan", tier = "11.0" },
            { difficulty = "Normal", boss = "Vexie and the Geargrinders", tier = "11.1" },
            { difficulty = "Normal", boss = "The One-Armed Bandit", tier = "11.1" },
            { difficulty = "Heroic", boss = "The One-Armed Bandit", tier = "11.1" },
            { difficulty = "Mythic", boss = "The One-Armed Bandit", tier = "11.1" },
            { difficulty = "Normal", boss = "Slippin' Jimmy", tier = "11.2" },
            { difficulty = "Heroic", boss = "Slippin' Jimmy", tier = "11.2" },
            { difficulty = "Mythic", boss = "Slippin' Jimmy", tier = "11.2" }
        },
        lootReserves = {
            {difficulty = "Normal", boss = "Slippin' Jimmy", character="Heuto", reserve="\124cffa335ee\124Hitem:230197::::::::80:::::\124h[Geargrinder's Spare Keys]\124h\124r"},
            {difficulty = "Heroic", boss = "Slippin' Jimmy", character="Heuto", reserve="\124cffa335ee\124Hitem:230197::::::::80:::::\124h[Geargrinder's Spare Keys]\124h\124r"},
            {difficulty = "Mythic", boss = "Slippin' Jimmy", character="Heuto", reserve="\124cffa335ee\124Hitem:230197::::::::80:::::\124h[Geargrinder's Spare Keys]\124h\124r"}
        },
        profile = {
            currentTier = "11.1"
        }
    }   

    self.encounters = RaidLootAnnouncerDB.encounters 
    self.tiers = RaidLootAnnouncerDB.tiers
    self.lootReserves = RaidLootAnnouncerDB.lootReserves
    self.profile = RaidLootAnnouncerDB.profile

end

-- Basic Frame for UI
function RLA:CreateMainFrame()
    local frame = CreateFrame("Frame", "RLAMainFrame", UIParent, "BasicFrameTemplateWithInset")
    RLA.mainFrame = frame;
    frame:SetSize(600, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
    frame.title:SetText("RaidLootAnnouncer")

    -- Tabs
    frame.tabButtons = {}

    local function CreateTab(id, text)
        local tab = CreateFrame("Button", "$parentTab"..id, frame, "PanelTabButtonTemplate")
        tab:SetID(id)
        tab:SetText(text)
        PanelTemplates_TabResize(tab, 0)
        table.insert(frame.tabButtons, tab)
        return tab
    end

    -- Tab 1: Announcements
    local tab1 = CreateTab(1, "Announcements")
    tab1:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 5, 7)

    -- Tab 2: Import
    local tab2 = CreateTab(2, "Import")
    tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)

    -- Panels
    frame.panels = {}

    RLA:BuildAnnouncements(frame)

    

    -- Panel 2: Import Panel
    local panel2 = CreateFrame("Frame", nil, frame)
    panel2:SetAllPoints(frame)
    frame.panels[2] = panel2

    -- Scroll Frame + Edit Box
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel2, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel2, "TOPLEFT", 15, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel2, "BOTTOMRIGHT", -45, 50)

    panel2.editBox = CreateFrame("EditBox", nil, scrollFrame, "InputBoxTemplate")
    panel2.editBox:SetMultiLine(true)
    panel2.editBox:SetWidth(360)
    panel2.editBox:SetAutoFocus(false)
    scrollFrame:SetScrollChild(panel2.editBox)

    --Profile Management
    panel2.tierProfileLabel = panel2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel2.tierProfileLabel:SetPoint("TOPLEFT", panel2, "TOPLEFT", 20, -60)
    panel2.tierProfileLabel:SetText("Select Tier Profile:")

    panel2.tierProfileDropdown = CreateFrame("Frame", "RLATierProfileDropdown", panel2, "UIDropDownMenuTemplate")
    panel2.tierProfileDropdown:SetPoint("TOPLEFT", panel2.tierProfileLabel, "BOTTOMLEFT", -15, -10)

    local tierProfiles = {}
    for profileName, data in pairs(RaidLootAnnouncerDB.tiers) do
        table.insert(tierProfiles, {text = data.text, value = data.value})
    end
    table.insert(tierProfiles, { text = "Create New Profile", value = "SECRETBUG"})

    UIDropDownMenu_Initialize(panel2.tierProfileDropdown, function(self, level, menuList)
        for i, option in ipairs(tierProfiles) do
           local info = UIDropDownMenu_CreateInfo()
           info.text = option.text
           info.value = option.value
           info.func = TierProfileOnClick
           UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetWidth(panel2.tierProfileDropdown, 100)
    UIDropDownMenu_SetSelectedValue(panel2.tierProfileDropdown, RaidLootAnnouncerDB.profile.currentTier)

    -- Delete Profile Button
    panel2.deleteProfileButton = CreateFrame("Button", nil, panel2, "GameMenuButtonTemplate")
    panel2.deleteProfileButton:SetPoint("LEFT", panel2.tierProfileDropdown, "RIGHT", 10, 0)
    panel2.deleteProfileButton:SetSize(80, 22)
    panel2.deleteProfileButton:SetText("Delete Profile")

    panel2.deleteProfileButton:SetScript("OnClick", function()
        local selectedProfile = UIDropDownMenu_GetSelectedValue(panel2.tierProfileDropdown)
        
        if selectedProfile == "SECRETBUG" then
            print("Cannot delete the 'New Tier Profile' option.")
            return
        end

        StaticPopupDialogs["RLA_CONFIRM_DELETE"] = {
            text = "Are you sure you want to delete profile: %s?",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                local tempTiers = {}
                local tempEncounters = {}
                for i, tier in pairs(RaidLootAnnouncerDB.tiers) do
                    if(tier.value ~= selectedProfile) then
                        table.insert(tempTiers, tier)
                    end
                end
                for i, encounter in pairs(RaidLootAnnouncerDB.encounters) do
                    if(encounter.tier ~= selectedProfile) then
                        table.insert(tempEncounters, encounter)
                    end
                end
                RaidLootAnnouncerDB.tiers = tempTiers
                RaidLootAnnouncerDB.encounters = tempEncounters
                print("Deleted profile: ", selectedProfile)

                RLA:RefreshTierProfileDropdown()
                RLA:PopulatePanelOneTiers()
                local selectedTier = UIDropDownMenu_GetSelectedValue(RLA.mainFrame.panels[1].dropdown)
                local selectedDifficulty = UIDropDownMenu_GetSelectedValue(RLA.mainFrame.panels[1].difficultyDropdown)
                RLA:DrawEncountersTable(selectedDifficulty or "Normal", selectedTier or "Liberation of Undermine")
                local tierProfiles = {}
                for profileName, data in pairs(RaidLootAnnouncerDB.tiers) do
                    table.insert(tierProfiles, {text = data.text, value = data.value})
                end
                table.insert(tierProfiles, { text = "Create New Profile", value = "SECRETBUG"})

                UIDropDownMenu_Initialize(panel2.tierProfileDropdown, function(self, level, menuList)
                    for i, option in ipairs(tierProfiles) do
                       local info = UIDropDownMenu_CreateInfo()
                       info.text = option.text
                       info.value = option.value
                       info.func = TierProfileOnClick
                       UIDropDownMenu_AddButton(info)
                    end
                end)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }

        StaticPopup_Show("RLA_CONFIRM_DELETE", selectedProfile)
    end)

    -- Tier Profile Name Label
    panel2.profileLabel = panel2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel2.profileLabel:SetPoint("BOTTOMLEFT", panel2, "BOTTOMLEFT", 20, 40)
    panel2.profileLabel:SetText("Tier Profile Name:")

    -- Tier Profile Name Input Box
    panel2.profileInput = CreateFrame("EditBox", nil, panel2, "InputBoxTemplate")
    panel2.profileInput:SetPoint("LEFT", panel2.profileLabel, "RIGHT", 10, 0)
    panel2.profileInput:SetSize(200, 20)
    panel2.profileInput:SetAutoFocus(false)
    panel2.profileInput:SetText("")

    panel2.profileLabel:Hide()
    panel2.profileInput:Hide()

    -- Parse Button
    panel2.parseButton = CreateFrame("Button", nil, panel2, "GameMenuButtonTemplate")
    panel2.parseButton:SetPoint("BOTTOM", panel2, "BOTTOM", 0, 10)
    panel2.parseButton:SetSize(140, 25)
    panel2.parseButton:SetText("Parse CSV")

    panel2.parseButton:SetScript("OnClick", function()
        local text = panel2.editBox:GetText()
        RLA:ParseCSV(text)
    end)

    -- Create the main frame
    local textWindow = CreateFrame("Frame", "MyTextWindow", UIParent, "BackdropTemplate")
    textWindow:SetFrameStrata("DIALOG")  -- Ensures it's rendered on top
    textWindow:SetFrameLevel(100)        -- Makes sure it's above other UI elements

    textWindow:SetSize(400, 300) -- Width, Height
    textWindow:SetPoint("CENTER") -- Centered on screen
    textWindow:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    textWindow:SetBackdropColor(0, 0, 0, 1)  -- Black, fully opaque
    textWindow:SetBackdropBorderColor(1, 1, 1, 1) -- White border, fully visible
    textWindow:EnableMouse(true)
    textWindow:SetMovable(true)
    textWindow:RegisterForDrag("LeftButton")
    textWindow:SetScript("OnDragStart", textWindow.StartMoving)
    textWindow:SetScript("OnDragStop", textWindow.StopMovingOrSizing)

    -- Title Text
    local title = textWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", textWindow, "TOP", 0, -10)
    title:SetText("Text Log Window")

    -- Create a ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, textWindow, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(360, 220)
    scrollFrame:SetPoint("TOP", textWindow, "TOP", 0, -40)

    -- Create an EditBox inside the ScrollFrame
    local outputText = CreateFrame("EditBox", nil, scrollFrame)
    outputText:SetSize(360, 220)
    outputText:SetMultiLine(true)
    outputText:SetFontObject(GameFontHighlight)
    outputText:SetAutoFocus(false)
    outputText:SetScript("OnEscapePressed", outputText.ClearFocus)

    -- Attach EditBox to ScrollFrame
    scrollFrame:SetScrollChild(outputText)

    -- Close Button at the Bottom
    local closeButton = CreateFrame("Button", nil, textWindow, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 30)
    closeButton:SetPoint("BOTTOM", textWindow, "BOTTOM", 0, 10)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() textWindow:Hide() end)    
    
    RLA.outputFrame = textWindow
    RLA.outputField = outputText

    textWindow:Hide()

    -- Assign tab click behavior
    for i, btn in ipairs(frame.tabButtons) do
        btn:SetScript("OnClick", function()
            RLA:ShowTab(i)
        end)
    end

    -- Default to Announcements Tab
    RLA:ShowTab(1)

    RLA:DrawEncountersTable(RaidLootAnnouncerDB.profile.currentDifficulty, RaidLootAnnouncerDB.profile.currentTier)


    RLA.mainFrame = frame
end

function TierProfileOnClick(self)
    local panel2 = RLA.mainFrame.panels[2]
    UIDropDownMenu_SetSelectedValue(panel2.tierProfileDropdown, self.value)
    RaidLootAnnouncerDB.profile.currentTier = self.value

    if self.value == "SECRETBUG" then
        panel2.profileLabel:Show()
        panel2.profileInput:Show()
        panel2.deleteProfileButton:Hide()
    else
        panel2.profileLabel:Hide()
        panel2.profileInput:Hide()
        panel2.deleteProfileButton:Show()
    end
end

function RLA:RefreshTierProfileDropdown()
    local panel2 = RLA.mainFrame.panels[2]
    local dropdownTiers = {}

    -- make into local memory list as directly manipulating db list will save to config duplicate new profile
    for profileName, data in pairs(RaidLootAnnouncerDB.tiers) do
        table.insert(dropdownTiers, { text = data.text, value = data.value })
    end

    table.insert(dropdownTiers, { text = "New Tier Profile", value = "SECRETBUG"})

    UIDropDownMenu_Initialize(panel2.tierProfileDropdown, function(self, level, menuList)
        for i, option in ipairs(dropdownTiers) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = TierProfileOnClick
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set default back to "New Tier Profile"
    UIDropDownMenu_SetSelectedValue(panel2.tierProfileDropdown, "SECRETBUG")
end


-- Tab Switching Logic
function RLA:ShowTab(id)
    local frame = RLA.mainFrame
    for i, btn in ipairs(frame.tabButtons) do
        if i == id then
            PanelTemplates_SelectTab(btn)
            frame.panels[i]:Show()
        else
            PanelTemplates_DeselectTab(btn)
            frame.panels[i]:Hide()
        end
    end
end


-- CSV Parser
function RLA:ParseCSV(input)
    local panel2 = RLA.mainFrame.panels[2]
    local selectedProfile = UIDropDownMenu_GetSelectedValue(panel2.tierProfileDropdown)
    local selectedTier = UIDropDownMenu_GetSelectedValue(RLA.mainFrame.panels[1].dropdown)
    local tierName = ""
    local isExistingEncounter = false
    local newEncounterSet = false
    local isInTiers = false

    -- New Tier being added
    if selectedProfile == "SECRETBUG" then
        tierName = panel2.profileInput:GetText()
        newEncounterSet = true
    end
    RaidLootAnnouncerDB.lootReserves = {}
    for line in input:gmatch("[^\r\n]+") do
        -- It will not be necessary to be adding the columns as data...
        
        local fields = {}
        for field in line:gmatch("([^,]+)") do
            table.insert(fields, field:match("^%s*(.-)%s*$")) -- trim whitespace
        end
        if fields[1] ~= 'difficulty' then    
            if #fields[4] <= 2 then
                -- Encounter: difficulty, boss name, tier
                isExistingEncounter = false
                for _, encounter in pairs(RaidLootAnnouncerDB.encounters) do
                    if fields[2] == encounter.boss and fields[3] == encounter.tier and fields[1] == encounter.difficulty then
                        isExistingEncounter = true
                    end
                end

                if isExistingEncounter ~= true then
                    table.insert(RaidLootAnnouncerDB.encounters, { difficulty = fields[1], boss = fields[2], tier = fields[3], order = fields[4] })    
                end

                if newEncounterSet == true and isInTiers == false then
                    table.insert(RaidLootAnnouncerDB.tiers, { text = tierName, value = fields[3], data = {} })
                    isInTiers = true
                end

            else
                -- Loot drop: difficulty, boss name, character name, loot drop
                table.insert(RaidLootAnnouncerDB.lootReserves, { character = fields[1], difficulty = fields[2], boss = fields[3],  reserve = fields[4] })
            end
        end
    end
    RLA.mainFrame.panels[2].editBox:SetText("")
    panel2.profileLabel:Hide()
    panel2.profileInput:Hide()

    local tierProfiles = {}
    for profileName, data in pairs(RaidLootAnnouncerDB.tiers) do
        table.insert(tierProfiles, {text = data.text, value = data.value})
    end
    table.insert(tierProfiles, { text = "Create New Profile", value = "SECRETBUG"})

    UIDropDownMenu_Initialize(panel2.tierProfileDropdown, function(self, level, menuList)
        for i, option in ipairs(tierProfiles) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = TierProfileOnClick
            UIDropDownMenu_AddButton(info)
        end
    end)

    
    local selectedDifficulty = UIDropDownMenu_GetSelectedValue(RLA.mainFrame.panels[1].difficultyDropdown)
    RLA:DrawEncountersTable(selectedDifficulty, selectedTier)
    RLA:ShowTab(1)
    print("Import complete!")
end

-- Slash Command to Open Frame
SLASH_RAIDLOOTANNOUNCER1 = "/rla"
SlashCmdList["RAIDLOOTANNOUNCER"] = function()
    if not RLA.mainFrame then
        RLA:CreateMainFrame()
    end
    if RLA.mainFrame:IsShown() then
        RLA.mainFrame:Hide()
    else
        RLA.mainFrame:Show()
    end
end

-- Event Registration
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if arg1 == addonName then
        RLA:Initialize()
        print("|cFF00FF00RaidLootAnnouncer Loaded. Type /rla to open.|r")
    end
end)

function RLA:PopulatePanelOneTiers()
    local panel1 = RLA.mainFrame.panels[1]
    local tierList = RaidLootAnnouncerDB.tiers

    local function OnClick(self)
        UIDropDownMenu_SetSelectedValue(panel1.dropdown, self.value)

        RaidLootAnnouncerDB.profile.currentTier = self.value
        RLA:DrawEncountersTable(UIDropDownMenu_GetSelectedValue(panel1.difficultyDropdown), self.value)
    end

    UIDropDownMenu_Initialize(panel1.dropdown, function(self, level, menuList)
        for i, option in ipairs(tierList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = OnClick
            UIDropDownMenu_AddButton(info)
        end
    end)
end


function RLA:BuildAnnouncements(frame)
    local panel1 = CreateFrame("Frame", nil, frame)
    panel1:SetAllPoints(frame)
    panel1:Hide()
    frame.panels[1] = panel1

    panel1.dropdownLabel = panel1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel1.dropdownLabel:SetPoint("TOPLEFT", panel1, "TOPLEFT", 20, -60)
    panel1.dropdownLabel:SetText("Select Tier:")

    panel1.dropdown = CreateFrame("Frame", "RLATierDropdown", panel1, "UIDropDownMenuTemplate")
    panel1.dropdown:SetPoint("TOPLEFT", panel1.dropdownLabel, "BOTTOMLEFT", -15, -10)

    

    UIDropDownMenu_SetWidth(panel1.dropdown, 120)
    UIDropDownMenu_SetSelectedValue(panel1.dropdown, RaidLootAnnouncerDB and RaidLootAnnouncerDB.currentTier or "11.1")
    UIDropDownMenu_JustifyText(panel1.dropdown, "LEFT")

    -- Difficulty Dropdown Label
    panel1.difficultyLabel = panel1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel1.difficultyLabel:SetPoint("LEFT", panel1.dropdownLabel, "RIGHT", 140, 0)
    panel1.difficultyLabel:SetText("Select Difficulty:")

    -- Difficulty Dropdown Frame
    panel1.difficultyDropdown = CreateFrame("Frame", "RLADifficultyDropdown", panel1, "UIDropDownMenuTemplate")
    panel1.difficultyDropdown:SetPoint("TOPLEFT", panel1.difficultyLabel, "BOTTOMLEFT", -15, -10)

    -- Difficulty Options
    local difficulties = {
        { text = "Normal", value = "Normal" },
        { text = "Heroic", value = "Heroic" },
        { text = "Mythic", value = "Mythic" }
    }

    RLA:PopulatePanelOneTiers()
    local tierList = RaidLootAnnouncerDB.tiers
    UIDropDownMenu_SetSelectedValue(panel1.dropdown, RaidLootAnnouncerDB.profile.currentTier)

    -- Function to set selected difficulty
    local function DifficultyOnClick(self)
        UIDropDownMenu_SetSelectedValue(panel1.difficultyDropdown, self.value)
        RaidLootAnnouncerDB.profile.currentDifficulty = self.value
        
        RLA:DrawEncountersTable(self.value, UIDropDownMenu_GetSelectedValue(panel1.dropdown))
    end

    -- Initialize difficulty dropdown
    UIDropDownMenu_Initialize(panel1.difficultyDropdown, function(self, level, menuList)
        for i, option in ipairs(difficulties) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = DifficultyOnClick
            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Set initial value (load from DB or default to Normal)
    UIDropDownMenu_SetWidth(panel1.difficultyDropdown, 120)
    UIDropDownMenu_SetSelectedValue(panel1.difficultyDropdown, RaidLootAnnouncerDB and RaidLootAnnouncerDB.profile.currentDifficulty)
    UIDropDownMenu_JustifyText(panel1.difficultyDropdown, "LEFT")


    local panel1DefaultText = "Please import your encounters and loot assignments using the Imports tab."
    -- in the event we do have encounters cached, we will change our instructions
    if(#tierList) then 
        panel1DefaultText = "Please import your loot assignments using the Imports tab."
    end    
    panel1.text = panel1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel1.text:SetPoint("CENTER")
    panel1.text:SetText(panel1DefaultText)

    -- Scroll Frame for Encounters Table
    panel1.scrollFrame = CreateFrame("ScrollFrame", nil, panel1, "UIPanelScrollFrameTemplate")
    panel1.scrollFrame:SetPoint("TOPLEFT", panel1, "TOPLEFT", 20, -100)
    panel1.scrollFrame:SetSize(550, 330)

    -- Content Frame inside scroll frame
    panel1.content = CreateFrame("Frame", nil, panel1.scrollFrame)
    panel1.content:SetSize(400, 180)  -- Adjust height dynamically later if needed
    panel1.scrollFrame:SetScrollChild(panel1.content)

    

    -- Function to draw encounters table
    function RLA:DrawEncountersTable(selectedDifficulty, selectedTier)
        -- Clear previous content
        RLA:ClearEncounterTable()
        
        panel1.rowFrames = panel1.rowFrames or {}

        -- Header row
        local header = panel1.content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        header:SetPoint("TOPLEFT", panel1.content, "TOPLEFT", 10, -10)
        header:SetText("Difficulty      Boss Name                                       Action")
        
        -- Spacer
        local yOffset = -30

        local filteredEncounters = {}

        for i, encounter in ipairs(RaidLootAnnouncerDB.encounters) do
            if encounter.difficulty == selectedDifficulty and encounter.tier == selectedTier then
                table.insert(filteredEncounters, encounter)
            end
        end

        table.sort(filteredEncounters, function(a,b)
            return a.order < b.order
        end)

        -- Loop through encounters table
        for i, entry in ipairs(filteredEncounters) do
            local row = panel1.content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row:SetPoint("TOPLEFT", panel1.content, "TOPLEFT", 10, yOffset)
            row:SetText(string.format("%-12s   %s", entry.difficulty, entry.boss))

            -- Action Button
            local button = CreateFrame("Button", nil, panel1.content, "GameMenuButtonTemplate")
            button:SetPoint("TOPLEFT", row, "TOPLEFT", 250, 0)
            button:SetSize(180, 18)
            button:SetText(entry.boss)
            button:SetNormalFontObject("GameFontNormalSmall")

            -- Click Behavior
            button:SetScript("OnClick", function(self)
                local message = ""
                for i, lootReserve in ipairs(RaidLootAnnouncerDB.lootReserves) do
                    
                    if lootReserve.boss == self:GetText() and UIDropDownMenu_GetSelectedValue(panel1.difficultyDropdown) == lootReserve.difficulty then
                        message = message .. string.format("%s -- %s", lootReserve.character, lootReserve.reserve) .. "\n"
                    end
                end
                if message == "" then
                    message = "No Reserves for this boss"
                end
                RLA.outputFrame:Show()
                RLA.outputField:SetText(message)
            end)

            yOffset = yOffset - 18
        end
        panel1.text:SetText("")
    end

    function RLA:ClearEncounterTable()
        if not panel1.rowFrames then return end
    
        -- Clear all children (buttons, frames)
        for i, child in ipairs({ panel1.content:GetChildren() }) do
            child:SetParent(nil)
            child:Hide()
        end

        -- Clear all FontStrings (text regions)
        for i, region in ipairs({ panel1.content:GetRegions() }) do
            if region and region:GetObjectType() == "FontString" then
                region:SetText("") -- Clear the text
            end
        end
    end

    local ClearAllButton = CreateFrame("Button", "ClearAllReservesButton", panel1, "UIPanelButtonTemplate")
    ClearAllButton:SetSize(150, 30) -- Set button size
    ClearAllButton:SetPoint("BOTTOM", panel1, "BOTTOM", 0, 10) -- Position at the bottom
    ClearAllButton:SetText("Clear All Reserves")

    -- Function to clear all reserves
    local function ClearAllReserves()   
        RaidLootAnnouncerDB.lootReserves = {}

        print("All reserves have been cleared!")
    end

    -- Set up the button click event
    ClearAllButton:SetScript("OnClick", ClearAllReserves)
    
end