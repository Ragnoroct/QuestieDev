---@class QuestieTracker
local QuestieTracker = QuestieLoader:CreateModule("QuestieTracker");
-------------------------
--Import modules.
-------------------------
---@type QuestieQuest
local QuestieQuest = QuestieLoader:ImportModule("QuestieQuest");
---@type QuestieMap
local QuestieMap = QuestieLoader:ImportModule("QuestieMap");
---@type QuestieLib
local QuestieLib = QuestieLoader:ImportModule("QuestieLib");
---@type QuestiePlayer
local QuestiePlayer = QuestieLoader:ImportModule("QuestiePlayer");
---@type QuestieDB
local QuestieDB = QuestieLoader:ImportModule("QuestieDB");
---@type QuestieQuestTimers
local QuestieQuestTimers = QuestieLoader:ImportModule("QuestieQuestTimers")
---@type QuestieTrackerMenu
local QuestieTrackerMenu = QuestieLoader:ImportModule("QuestieTrackerMenu")
---@type QuestieTrackerMove
local QuestieTrackerMove = QuestieLoader:ImportModule("QuestieTrackerMove")
---@type QuestieTrackerUtils
local QuestieTrackerUtils = QuestieLoader:ImportModule("QuestieTrackerUtils")

local _QuestieTracker = {}
_QuestieTracker.LineFrames = {}

-- these should be configurable maybe
local trackerLineCount = 64 -- shouldnt need more than this
local trackerBackgroundPadding = 4

-- used for fading the background of the tracker
_QuestieTracker.FadeTickerValue = 0
_QuestieTracker.FadeTickerDirection = false -- true to fade in
_QuestieTracker.IsFirstRun = true -- bad code

local _BindTruthTable = {
    ['left'] = function(button)
        return "LeftButton" == button
    end,
    ['right'] = function(button)
        return "RightButton" == button
    end,
    ['shiftleft'] = function(button)
        return "LeftButton" == button and IsShiftKeyDown()
    end,
    ['shiftright'] = function(button)
        return "RightButton" == button and IsShiftKeyDown()
    end,
    ['ctrlleft'] = function(button)
        return "LeftButton" == button and IsControlKeyDown()
    end,
    ['ctrlright'] = function(button)
        return "RightButton" == button and IsControlKeyDown()
    end,
    ['altleft'] = function(button)
        return "LeftButton" == button and IsAltKeyDown()
    end,
    ['altright'] = function(button)
        return "RightButton" == button and IsAltKeyDown()
    end,
    ['disabled'] = function() return false; end,
}

local function _IsBindTrue(bind, button)
    return bind and button and _BindTruthTable[bind] and _BindTruthTable[bind](button)
end

function _QuestieTracker:StartFadeTicker()
    if not _QuestieTracker.FadeTicker then
        _QuestieTracker.FadeTicker = C_Timer.NewTicker(0.02, function()
            if _QuestieTracker.FadeTickerDirection then
                if _QuestieTracker.FadeTickerValue < 0.3 then
                    _QuestieTracker.FadeTickerValue = _QuestieTracker.FadeTickerValue + 0.06
                    _QuestieTracker.baseFrame.texture:SetVertexColor(1,1,1,_QuestieTracker.FadeTickerValue)
                else
                    _QuestieTracker.FadeTicker:Cancel()
                    _QuestieTracker.FadeTicker = nil
                end
            else
                if _QuestieTracker.FadeTickerValue > 0 then
                    _QuestieTracker.FadeTickerValue = _QuestieTracker.FadeTickerValue - 0.06
                    _QuestieTracker.baseFrame.texture:SetVertexColor(1,1,1,math.max(0,_QuestieTracker.FadeTickerValue))
                else
                    _QuestieTracker.FadeTicker:Cancel()
                    _QuestieTracker.FadeTicker = nil
                end
            end
        end)
    end
end

function QuestieTracker:UnFocus() -- reset HideIcons to match savedvariable state
    if not Questie.db.char.TrackerFocus then return; end
    for questId in pairs (QuestiePlayer.currentQuestlog) do
        local quest = QuestieDB:GetQuest(questId)
        if quest then
            quest.FadeIcons = nil
            if quest.Objectives then
                if Questie.db.char.TrackerHiddenQuests[quest.Id] then
                    quest.HideIcons = true
                    quest.FadeIcons = nil
                else
                    quest.HideIcons = nil
                    quest.FadeIcons = nil
                end
                for _,Objective in pairs(quest.Objectives) do
                    if Questie.db.char.TrackerHiddenObjectives[tostring(questId) .. " " .. tostring(Objective.Index)] then
                        Objective.HideIcons = true
                        Objective.FadeIcons = nil
                    else
                        Objective.HideIcons = nil
                        Objective.FadeIcons = nil
                    end
                end
                if quest.SpecialObjectives then
                    for _,Objective in pairs(quest.SpecialObjectives) do
                        if Questie.db.char.TrackerHiddenObjectives[tostring(questId) .. " " .. tostring(Objective.Index)] then
                            Objective.HideIcons = true
                            Objective.FadeIcons = nil
                        else
                            Objective.HideIcons = nil
                            Objective.FadeIcons = nil
                        end
                    end
                end
            end
        end
    end
    Questie.db.char.TrackerFocus = nil
end

function QuestieTracker:FocusObjective(TargetQuest, TargetObjective, isSpecial)
    if Questie.db.char.TrackerFocus and (type(Questie.db.char.TrackerFocus) ~= "string" or Questie.db.char.TrackerFocus ~= tostring(TargetQuest.Id) .. " " .. tostring(TargetObjective.Index)) then
        QuestieTracker:UnFocus()
    end
    Questie.db.char.TrackerFocus = tostring(TargetQuest.Id) .. " " .. tostring(TargetObjective.Index)
    for questId in pairs (QuestiePlayer.currentQuestlog) do
        local quest = QuestieDB:GetQuest(questId)
        if quest and quest.Objectives then
            if questId == TargetQuest.Id then
                quest.HideIcons = nil
                quest.FadeIcons = nil
                for _,Objective in pairs(quest.Objectives) do
                    if Objective.Index == TargetObjective.Index then
                        Objective.HideIcons = nil
                        Objective.FadeIcons = nil
                    else
                        Objective.FadeIcons = true
                    end
                end
                if quest.SpecialObjectives then
                    for _,Objective in pairs(quest.SpecialObjectives) do
                        if Objective.Index == TargetObjective.Index then
                            Objective.HideIcons = nil
                            Objective.FadeIcons = nil
                        else
                            Objective.FadeIcons = true
                        end
                    end
                end
            else
                quest.FadeIcons = true
            end
        end
    end
end

function QuestieTracker:FocusQuest(TargetQuest)
    if Questie.db.char.TrackerFocus and (type(Questie.db.char.TrackerFocus) ~= "number" or Questie.db.char.TrackerFocus ~= TargetQuest.Id) then
        QuestieTracker:UnFocus()
    end
    Questie.db.char.TrackerFocus = TargetQuest.Id
    for questId in pairs (QuestiePlayer.currentQuestlog) do
        local quest = QuestieDB:GetQuest(questId)
        if quest then
            if questId == TargetQuest.Id then
                quest.HideIcons = nil
                quest.FadeIcons = nil
            else
                -- if hideOnFocus
                --Quest.HideIcons = true
                quest.FadeIcons = true
            end
        end
    end
end

-- local function _FlashObjectiveByTexture(Objective) -- really terrible animation code, sorry guys
--     if Objective.AlreadySpawned then
--         local toFlash = {}
--         -- ugly code
--         for questId, framelist in pairs(QuestieMap.questIdFrames) do
--             for index, frameName in ipairs(framelist) do
--                 local icon = _G[frameName];
--                 if not icon.miniMapIcon then

--                     -- todo: move into frame.session
--                     if icon:IsShown() then
--                         icon._hidden_by_flash = true
--                         icon:Hide()
--                     end
--                 end
--             end
--         end


--         for _, spawn in pairs(Objective.AlreadySpawned) do
--             if spawn.mapRefs then
--                 for _, frame in pairs(spawn.mapRefs) do
--                     if frame.data.ObjectiveData then
--                         table.insert(toFlash, frame)
--                         if frame._hidden_by_flash then
--                             frame:Show()
--                         end

--                         -- todo: move into frame.session
--                         frame._hidden_by_flash = nil
--                         frame._size = frame:GetWidth()
--                         frame._sizemul = 2
--                         frame:SetWidth(frame._size * 2)
--                         frame:SetHeight(frame._size * 2)
--                     end
--                 end
--             end
--         end
--         local flashB = true
--         _QuestieTracker._ObjectiveFlashTicker = C_Timer.NewTicker(0.28, function()
--             if flashB then
--                 flashB = false
--                 for _, frame in pairs(toFlash) do
--                     frame.texture:SetVertexColor(0.3,0.3,0.3,1)
--                     frame.glowTexture:SetVertexColor(frame.data.ObjectiveData.Color[1]/3,frame.data.ObjectiveData.Color[2]/3,frame.data.ObjectiveData.Color[3]/3,1)
--                 end
--             else
--                 flashB = true
--                 for _, frame in pairs(toFlash) do
--                     frame.texture:SetVertexColor(1,1,1,1)
--                     frame.glowTexture:SetVertexColor(frame.data.ObjectiveData.Color[1],frame.data.ObjectiveData.Color[2],frame.data.ObjectiveData.Color[3],1)
--                 end
--             end
--         end, 6)
--         C_Timer.After(5*0.28, function()
--             C_Timer.NewTicker(0.1, function()
--                 for _, frame in pairs(toFlash) do
--                     frame._sizemul = frame._sizemul - 0.2
--                     frame:SetWidth(frame._size * frame._sizemul)
--                     frame:SetHeight(frame._size  * frame._sizemul)
--                 end
--             end, 5)
--         end)
--         --C_Timer.After(6*0.3+0.1, function()
--         --    for _, frame in pairs(toFlash) do
--         --        frame:SetWidth(frame._size)
--         --        frame:SetHeight(frame._size)
--         --      frame._size = nil; frame._sizemul = nil
--         --    end
--         --end)
--         C_Timer.After(6*0.28+0.7, function()
--             for questId, framelist in pairs(QuestieMap.questIdFrames) do
--                 for index, frameName in ipairs(framelist) do
--                     local icon = _G[frameName];
--                     if icon._hidden_by_flash then
--                         icon._hidden_by_flash = nil
--                         icon:Show()
--                     end
--                 end
--             end
--         end)
--     end
-- end

local function _OnClick(self, button)
    if _IsBindTrue(Questie.db.global.trackerbindSetTomTom, button) then
        local spawn, zone, name = QuestieMap:GetNearestQuestSpawn(self.Quest)

        if spawn then
            QuestieTrackerUtils:SetTomTomTarget(name, zone, spawn[1], spawn[2])
        end
    elseif _IsBindTrue(Questie.db.global.trackerbindOpenQuestLog, button) then
        QuestieTrackerUtils:ShowQuestLog(self.Quest)
    elseif button == "RightButton" then
        local menu = QuestieTrackerMenu:GetMenuForQuest(self.Quest)
        LQuestie_EasyMenu(menu, _QuestieTracker.menuFrame, "cursor", 0 , 0, "MENU")
    end
end

local function _OnEnter()
    _QuestieTracker.FadeTickerDirection = true
    _QuestieTracker:StartFadeTicker()
end

local function _OnLeave()
    _QuestieTracker.FadeTickerDirection = false
    _QuestieTracker:StartFadeTicker()
end

function QuestieTracker:ResetLinesForFontChange()
    for i=1,trackerLineCount do
        _QuestieTracker.LineFrames[i].mode = nil
    end
end

function QuestieTracker:QuestRemoved(id)
    if Questie.db.char.TrackerFocus then
        if (type(Questie.db.char.TrackerFocus) == "number" and Questie.db.char.TrackerFocus == id)
        or (type(Questie.db.char.TrackerFocus) == "string" and Questie.db.char.TrackerFocus:sub(1, #tostring(id)) == tostring(id)) then
            QuestieTracker:UnFocus()
            QuestieQuest:UpdateHiddenNotes()
        end
    end
end

function QuestieTracker:SetCounterEnabled(enabled)
    if enabled then
        _QuestieTracker.counterFrame:Show()
    else
        _QuestieTracker.counterFrame:Hide()
    end
    QuestieTrackerMove:RepositionFrames(trackerLineCount, _QuestieTracker.LineFrames)
end

function QuestieTracker:Initialize()
    if QuestieTracker.started or (not Questie.db.global.trackerEnabled) then return; end
    if not Questie.db.char.TrackerHiddenQuests then
        Questie.db.char.TrackerHiddenQuests = {}
    end
    if not Questie.db.char.TrackerHiddenObjectives then
        Questie.db.char.TrackerHiddenObjectives = {}
    end
    if not Questie.db.char.TrackedQuests then
        Questie.db.char.TrackedQuests = {}
    end
    if not Questie.db.char.AutoUntrackedQuests then
        Questie.db.char.AutoUntrackedQuests = {} -- the reason why we separate this from TrackedQuests is so that users can switch between auto/manual without losing their manual tracking selection
    end
    _QuestieTracker.baseFrame = QuestieTracker:CreateBaseFrame()
    _QuestieTracker.counterFrame = _QuestieTracker:CreateActiveQuestsFrame()
    if not Questie.db.global.trackerCounterEnabled then
        _QuestieTracker.counterFrame:Hide()
    end
    _QuestieTracker.menuFrame = LQuestie_Create_UIDropDownMenu("QuestieTrackerMenuFrame", UIParent)

    if Questie.db.global.hookTracking then
        QuestieTracker:HookBaseTracker()
    end

    -- this number is static, I doubt it will ever need more
    local lastFrame = nil
    for i=1, trackerLineCount do
        local frm = CreateFrame("Button", nil, _QuestieTracker.baseFrame)
        frm.label = frm:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        function frm:SetMode(mode)
            if mode ~= self.mode then
                self.mode = mode
                if mode == "header" then
                    self.label:SetFont(self.label:GetFont(), Questie.db.global.trackerFontSizeHeader)
                    self:SetHeight(Questie.db.global.trackerFontSizeHeader)
                else
                    self.label:SetFont(self.label:GetFont(), Questie.db.global.trackerFontSizeLine)
                    self:SetHeight(Questie.db.global.trackerFontSizeLine)
                end
            end
        end

        function frm:SetQuest(Quest)
            self.Quest = Quest
        end

        function frm:SetObjective(Objective)
            self.Objective = Objective
        end

        function frm:SetVerticalPadding(amount)
            if self.mode == "header" then
                self:SetHeight(Questie.db.global.trackerFontSizeHeader + amount)
            else
                self:SetHeight(Questie.db.global.trackerFontSizeLine + amount)
            end
        end

        frm.label:SetJustifyH("LEFT")
        frm.label:SetPoint("TOPLEFT", frm)
        frm.label:Hide()

        -- autoadjust parent size for clicks
        frm.label._SetText = frm.label.SetText
        frm.label.frame = frm
        frm.label.SetText = function(self, text)
            self:_SetText(text)
            self.frame:SetWidth(self:GetWidth())
            self.frame:SetHeight(self:GetHeight())
        end

        frm:EnableMouse(true)
        frm:RegisterForDrag("LeftButton", "RightButton")
        frm:RegisterForClicks("RightButtonUp", "LeftButtonUp")

        -- hack for click-through
        frm:SetScript("OnDragStart", QuestieTrackerMove.OnDragStart)
        frm:SetScript("OnClick", _OnClick)
        frm:SetScript("OnDragStop", QuestieTrackerMove.OnDragStop)
        frm:SetScript("OnEnter", _OnEnter)
        frm:SetScript("OnLeave", _OnLeave)


        if lastFrame then
            frm:SetPoint("TOPLEFT", lastFrame, "BOTTOMLEFT", 0,0)
        else
            if Questie.db.global.trackerCounterEnabled then
                frm:SetPoint("TOPLEFT", _QuestieTracker.baseFrame, "TOPLEFT", trackerBackgroundPadding, -(trackerBackgroundPadding + _QuestieTracker.counterFrame:GetHeight()))
            else
                frm:SetPoint("TOPLEFT", _QuestieTracker.baseFrame, "TOPLEFT", trackerBackgroundPadding, -trackerBackgroundPadding)
            end
        end
        frm:SetWidth(1)
        frm:SetMode("header")
        --frm:Show()
        _QuestieTracker.LineFrames[i] = frm
        lastFrame = frm
    end

    QuestieTracker.started = true
end

local index = 0
function _QuestieTracker:GetNextLine()
    index = index + 1
    return _QuestieTracker.LineFrames[index]
end

_QuestieTracker.HexTableHack = {
    '00','11','22','33','44','55','66','77','88','99','AA','BB','CC','DD','EE','FF'
}
function _QuestieTracker:PrintProgressColor(percent, text)
    local hexGreen, hexRed, hexBlue =
    _QuestieTracker.HexTableHack[5 + math.floor(percent * 10)], _QuestieTracker.HexTableHack[8 + math.floor((1-percent) * 6)], _QuestieTracker.HexTableHack[4 + math.floor(percent * 6)]
    return "|cFF"..hexRed..hexGreen..hexBlue..text.."|r"
end

-- 1.12 color logic
local function RGBToHex(r, g, b)
    if r > 255 then r = 255; end
    if g > 255 then g = 255; end
    if b > 255 then b = 255; end
    return string.format("|cFF%02x%02x%02x", r, g, b);
end
local function FloatRGBToHex(r, g, b)
    return RGBToHex(r*254, g*254, b*254);
end
function _QuestieTracker:GetRGBForObjective(Objective)
    if not Objective.Collected or type(Objective.Collected) ~= "number" then return 0.8,0.8,0.8; end
    local float = Objective.Collected / Objective.Needed

    if Questie.db.global.trackerColorObjectives == "whiteToGreen" then
        return FloatRGBToHex(0.8-float/2, 0.8+float/3, 0.8-float/2);
    else
        if float < .49 then return FloatRGBToHex(1, 0+float/.5, 0); end
        if float == .50 then return FloatRGBToHex(1, 1, 0); end
        if float > .50 then return FloatRGBToHex(1-float/2, 1, 0); end
    end
    --return fRGBToHex(0.8-float/2, 0.8+float/3, 0.8-float/2);

    --[[if QuestieConfig.boldColors == false then
        if not (type(objective) == "function") then
            local lastIndex = findLast(objective, ":");
            if not (lastIndex == nil) then
                local progress = string.sub(objective, lastIndex+2);
                local slash = findLast(progress, "/");
                local have = tonumber(string.sub(progress, 0, slash-1));
                local need = tonumber(string.sub(progress, slash+1));
                if not have or not need then return 0.8, 0.8, 0.8; end
                local float = have / need;
                return 0.8-float/2, 0.8+float/3, 0.8-float/2;
            end
        end
        return 0.3, 1, 0.3;
    else
        if not (type(objective) == "function") then
            local lastIndex = findLast(objective, ":");
            if not (lastIndex == nil) then
                local progress = string.sub(objective, lastIndex+2);
                local slash = findLast(progress, "/");
                local have = tonumber(string.sub(progress, 0, slash-1));
                local need = tonumber(string.sub(progress, slash+1));
                if not have or not need then return 1, 0, 0; end
                local float = have / need;
                if float < .49 then return 1, 0+float/.5, 0; end
                if float == .50 then return 1, 1, 0; end
                if float > .50 then return 1-float/2, 1, 0; end
            end
        end
        return 0, 1, 0;
    end]]--
end


function QuestieTracker:Update()
    Questie:Debug(DEBUG_DEVELOP, "QuestieTracker: Update")

    if (not QuestieTracker.started) then return; end

    if (not Questie.db.global.trackerEnabled) then
        -- tracker has started but not enabled
        _QuestieTracker.baseFrame:Hide()
        return
    end
    if Questie.db.char.trackerCounterEnabled then
        _QuestieTracker.counterFrame:Update()
    end

    index = 0 -- zero because it simplifies GetNextLine()
    -- populate tracker
    local trackerWidth = 0
    local line = nil

    local order = {}
    local questCompletePercent = {}
    for questId in pairs (QuestiePlayer.currentQuestlog) do
        local quest = QuestieDB:GetQuest(questId)
        if quest then
            if QuestieQuest:IsComplete(quest) or not quest.Objectives then
                questCompletePercent[quest.Id] = 1
            else
                local percent = 0
                local count = 0;
                for _,Objective in pairs(quest.Objectives) do
                    percent = percent + (Objective.Collected / Objective.Needed)
                    count = count + 1
                end
                percent = percent / count
                questCompletePercent[quest.Id] = percent
            end
            table.insert(order, questId)
        end
    end
    if Questie.db.global.trackerSortObjectives == "byComplete" then
        table.sort(order, function(a, b)
            local vA, vB = questCompletePercent[a], questCompletePercent[b]
            if vA == vB then
                local qA = QuestieDB:GetQuest(a)
                local qB = QuestieDB:GetQuest(b)
                return qA and qB and qA.level < qB.level
            end
            return vB < vA
        end)
    elseif Questie.db.global.trackerSortObjectives == "byLevel" then
        table.sort(order, function(a, b)
            local qA = QuestieDB:GetQuest(a)
            local qB = QuestieDB:GetQuest(b)
            return qA and qB and qA.level < qB.level
        end)
    elseif Questie.db.global.trackerSortObjectives == "byLevelReversed" then
        table.sort(order, function(a, b)
            local qA = QuestieDB:GetQuest(a)
            local qB = QuestieDB:GetQuest(b)
            return qA and qB and qA.level > qB.level
        end)
    end
    local hasQuest = false
    for _, questId in pairs (order) do
        -- if quest.userData.tracked
        local quest = QuestieDB:GetQuest(questId)
        -- make sure objective data is up to date
        if quest and quest.Objectives then
            for _,Objective in pairs(quest.Objectives) do
                if Objective.Update then Objective:Update() end
            end
        end


        local complete = QuestieQuest:IsComplete(quest)
        if ((not complete) or Questie.db.global.trackerShowCompleteQuests) and ((GetCVar("autoQuestWatch") == "1" and not Questie.db.char.AutoUntrackedQuests[questId]) or (GetCVar("autoQuestWatch") == "0" and Questie.db.char.TrackedQuests[questId]))  then -- maybe have an option to display quests in the list with (Complete!) in the title
            hasQuest = true
            line = _QuestieTracker:GetNextLine()
            line:SetMode("header")
            line:SetQuest(quest)
            line:SetObjective(nil)

            local questName = (quest.LocalizedName or quest.name)
            local coloredQuestName = QuestieLib:GetColoredQuestName(quest.Id, questName, quest.level, Questie.db.global.trackerShowQuestLevel, complete)
            line.label:SetText(coloredQuestName)

            line:Show()
            line.label:Show()
            trackerWidth = math.max(trackerWidth, line.label:GetWidth())

            -- Add quest timer
            line = _QuestieTracker:GetNextLine()
            local seconds = QuestieQuestTimers:GetQuestTimerByQuestId(questId, line)
            if seconds then
                line:SetMode("header")
                line:SetQuest(quest)
                line.label:SetPoint("TOPLEFT", line, 10, 0)
                line.label:SetText(seconds)
                line:Show()
                line.label:Show()
            else
                -- No timer for this quest so we can reuse the line
                index = index - 1
            end

            if quest.Objectives and not complete then
                for _,Objective in pairs(quest.Objectives) do
                    line = _QuestieTracker:GetNextLine()
                    line:SetMode("line")
                    line:SetQuest(quest)
                    line:SetObjective(Objective)
                    local lineEnding = "" -- initialize because its not set if Needed is 0
                    if Objective.Needed > 0 then
                        lineEnding = tostring(Objective.Collected) .. "/" .. tostring(Objective.Needed)
                    end
                    if (Questie.db.global.trackerColorObjectives and Questie.db.global.trackerColorObjectives ~= "white") and Objective.Collected and type(Objective.Collected) == "number" then
                        line.label:SetText("    " .. _QuestieTracker:GetRGBForObjective(Objective) .. Objective.Description .. ": " .. lineEnding)
                    else
                        line.label:SetText("    |cFFEEEEEE" .. Objective.Description .. ": " .. lineEnding)
                    end
                    line:Show()
                    line.label:Show()
                    trackerWidth = math.max(trackerWidth, line.label:GetWidth())
                end
            end
            line:SetVerticalPadding(Questie.db.global.trackerQuestPadding)
        end
    end

    -- hide remaining lines
    for i=index+1,trackerLineCount do
        _QuestieTracker.LineFrames[i]:Hide()
    end

    -- adjust base frame size for dragging
    if line then
        _QuestieTracker.baseFrame:SetWidth(trackerWidth + trackerBackgroundPadding*2)
        _QuestieTracker.baseFrame:SetHeight((_QuestieTracker.baseFrame:GetTop() - line:GetBottom()) + trackerBackgroundPadding*2 - Questie.db.global.trackerQuestPadding*2)
    end
    -- make sure tracker is inside the screen

    if _QuestieTracker.IsFirstRun then
        _QuestieTracker.IsFirstRun = nil
        for questId in pairs (QuestiePlayer.currentQuestlog) do
            local quest = QuestieDB:GetQuest(questId)
            if quest then
                if Questie.db.char.TrackerHiddenQuests[questId] then
                    quest.HideIcons = true
                end
                if Questie.db.char.TrackerFocus then
                    if Questie.db.char.TrackerFocus and type(Questie.db.char.TrackerFocus) == "number" and Questie.db.char.TrackerFocus == quest.Id then -- quest focus
                        QuestieTracker:FocusQuest(quest)
                    end
                end
                if quest.Objectives then
                    for _,Objective in pairs(quest.Objectives) do
                        if Questie.db.char.TrackerHiddenObjectives[tostring(questId) .. " " .. tostring(Objective.Index)] then
                            Objective.HideIcons = true
                        end
                        if  Questie.db.char.TrackerFocus and type(Questie.db.char.TrackerFocus) == "string" and Questie.db.char.TrackerFocus == tostring(quest.Id) .. " " .. tostring(Objective.Index) then
                            QuestieTracker:FocusObjective(quest, Objective)
                        end
                    end
                end
                if quest.SpecialObjectives then
                    for _,Objective in pairs(quest.SpecialObjectives) do
                        if Questie.db.char.TrackerHiddenObjectives[tostring(questId) .. " " .. tostring(Objective.Index)] then
                            Objective.HideIcons = true
                        end
                        if  Questie.db.char.TrackerFocus and type(Questie.db.char.TrackerFocus) == "string" and Questie.db.char.TrackerFocus == tostring(quest.Id) .. " " .. tostring(Objective.Index) then
                            QuestieTracker:FocusObjective(quest, Objective)
                        end
                    end
                end
            end
        end
        QuestieQuest:UpdateHiddenNotes()
    end
    if hasQuest then
        _QuestieTracker.baseFrame:Show()
    else
        _QuestieTracker.baseFrame:Hide()
    end
end

local function _RemoveQuestWatch(index, isQuestie)
    if QuestieTracker._disableHooks then return end
    if not isQuestie then
        local qid = select(8,GetQuestLogTitle(index))
        if qid then
            if "0" == GetCVar("autoQuestWatch") then
                Questie.db.char.TrackedQuests[qid] = nil
            else
                Questie.db.char.AutoUntrackedQuests[qid] = true
            end
            C_Timer.After(0.1, function()
                QuestieTracker:Update()
            end)
        end
    end
end
QuestieTracker._last_aqw_time = GetTime()
local function _AQW_Insert(index, expire)
    if QuestieTracker._disableHooks then return end
    local time = GetTime()
    if index and index == QuestieTracker._last_aqw and (time - QuestieTracker._last_aqw_time) < 0.1 then return end -- this fixes double calling due to AQW+AQW_Insert (QuestGuru fix)
    QuestieTracker._last_aqw_time = time
    QuestieTracker._last_aqw = index
    RemoveQuestWatch(index, true) -- prevent hitting 5 quest watch limit
    local qid = select(8,GetQuestLogTitle(index))
    if qid then
        if "0" == GetCVar("autoQuestWatch") then
            if Questie.db.char.TrackedQuests[qid] then
                Questie.db.char.TrackedQuests[qid] = nil
            else
                Questie.db.char.TrackedQuests[qid] = true
            end
        else
            if Questie.db.char.AutoUntrackedQuests[qid] then
                Questie.db.char.AutoUntrackedQuests[qid] = nil
            elseif IsShiftKeyDown() and (QuestLogFrame:IsShown() or (QuestLogExFrame and QuestLogExFrame:IsShown())) then--hack
                Questie.db.char.AutoUntrackedQuests[qid] = true
            end
        end
        C_Timer.After(0.1, function()
            QuestieTracker:Update()
        end)
    end
end

function QuestieTracker:Unhook()
    if not QuestieTracker._alreadyHooked then return; end
    QuestieTracker._disableHooks = true
    if QuestieTracker._IsQuestWatched then
        IsQuestWatched = QuestieTracker._IsQuestWatched
        GetNumQuestWatches = QuestieTracker._GetNumQuestWatches
    end
    _QuestieTracker._alreadyHooked = nil
    QuestWatchFrame:Show()
end

function QuestieTracker:HookBaseTracker()
    if _QuestieTracker._alreadyHooked then return; end
    QuestieTracker._disableHooks = nil

    if not QuestieTracker._alreadyHookedSecure then
        hooksecurefunc("AutoQuestWatch_Insert", _AQW_Insert)
        hooksecurefunc("AddQuestWatch", _AQW_Insert)
        hooksecurefunc("RemoveQuestWatch", _RemoveQuestWatch)

        -- completed/objectiveless tracking fix
        -- blizzard quest tracker
        local baseQLTB_OnClick = QuestLogTitleButton_OnClick
        QuestLogTitleButton_OnClick = function(self, button) -- I wanted to use hooksecurefunc but this needs to be a pre-hook to work properly unfortunately
            if (not self) or self.isHeader or not IsShiftKeyDown() then baseQLTB_OnClick(self, button) return end
            index = self:GetID() + FauxScrollFrame_GetOffset(QuestLogListScrollFrame);
            if GetNumQuestLeaderBoards(index) == 0 and not IsQuestWatched(index) then -- only call if we actually want to fix this quest (normal quests already call AQW_insert)
                _AQW_Insert(index, QUEST_WATCH_NO_EXPIRE)
                QuestWatch_Update()
                QuestLog_SetSelection(index)
                QuestLog_Update()
            else
                baseQLTB_OnClick(self, button)
            end
        end
        -- other addons


        -- totally prevent the blizzard tracker frame from showing (BAD CODE, shouldn't be needed but some have had trouble)
        QuestWatchFrame:HookScript("OnShow", function(self) if QuestieTracker._disableHooks then return end self:Hide() end)
        QuestieTracker._alreadyHookedSecure = true
    end
    if not QuestieTracker._IsQuestWatched then
        QuestieTracker._IsQuestWatched = IsQuestWatched
        QuestieTracker._GetNumQuestWatches = GetNumQuestWatches
    end
    -- this is probably bad
    IsQuestWatched = function(index)
        if "0" == GetCVar("autoQuestWatch") then
            return Questie.db.char.TrackedQuests[select(8,GetQuestLogTitle(index)) or -1]
        else
            local qid = select(8,GetQuestLogTitle(index))
            return qid and QuestiePlayer.currentQuestlog[qid] and not Questie.db.char.AutoUntrackedQuests[qid]
        end
    end
    GetNumQuestWatches = function()
        return 0
    end

    QuestWatchFrame:Hide()
    QuestieTracker._alreadyHooked = true
end

function QuestieTracker:ResetLocation()
    Questie.db.char.TrackerLocation = nil
    if _QuestieTracker.baseFrame then
        _QuestieTracker:SetSafePoint(_QuestieTracker.baseFrame)
        _QuestieTracker.baseFrame:Show()
    end
end

function _QuestieTracker:SetSafePoint(frm)
    frm:ClearAllPoints();
    frm:SetPoint("TOPLEFT", UIParent, "CENTER", 0,0)
end

function _QuestieTracker:CreateActiveQuestsFrame()
    local _, numQuests = GetNumQuestLogEntries()
    local frm = CreateFrame("Button", nil, _QuestieTracker.baseFrame)

    frm.label = frm:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frm.label:SetText(QuestieLocale:GetUIString("TRACKER_ACTIVE_QUESTS") .. tostring(numQuests) .. "/20")
    frm.label:SetFont(frm.label:GetFont(), Questie.db.global.trackerFontSizeHeader)
    frm.label:SetPoint("TOP", _QuestieTracker.baseFrame)

    frm:SetHeight(Questie.db.global.trackerFontSizeHeader)
    frm:SetWidth(1)

    -- hack for click-through
    frm:SetScript("OnDragStart", QuestieTrackerMove.OnDragStart)
    frm:SetScript("OnClick", _OnClick)
    frm:SetScript("OnDragStop", QuestieTrackerMove.OnDragStop)
    frm:SetScript("OnEnter", _OnEnter)
    frm:SetScript("OnLeave", _OnLeave)

    frm.Update = function(self)
        local _, activeQuests = GetNumQuestLogEntries()
        self.label:SetText(QuestieLocale:GetUIString("TRACKER_ACTIVE_QUESTS") .. tostring(activeQuests) .. "/20")
    end

    frm:Show()
    return frm
end

function QuestieTracker:CreateBaseFrame()
    local frm = CreateFrame("Frame", nil, UIParent)

    frm:SetWidth(100)
    frm:SetHeight(100)

    local t = frm:CreateTexture(nil,"BACKGROUND")
    t:SetTexture(ICON_TYPE_BLACK)
    t:SetVertexColor(1,1,1,0)
    t:SetAllPoints(frm)
    frm.texture = t

    if Questie.db.char.TrackerLocation and Questie.db.char.TrackerLocation[1] and Questie.db.char.TrackerLocation[1] ~= "TOPRIGHT" and Questie.db.char.TrackerLocation[1] ~= "TOPLEFT" then
        print(QuestieLocale:GetUIString('TRACKER_INVALID_LOCATION') .. " (2)")
        Questie.db.char.TrackerLocation = nil
    end

    if Questie.db.char.TrackerLocation then
        -- we need to pcall this because it can error if something like MoveAnything is used to move the tracker
        local result, error = pcall(frm.SetPoint, frm, unpack(Questie.db.char.TrackerLocation))
        if not result then
            Questie.db.char.TrackerLocation = nil
            print(QuestieLocale:GetUIString('TRACKER_INVALID_LOCATION'))
            if QuestWatchFrame then
                result, error = pcall(frm.SetPoint, frm, unpack({QuestWatchFrame:GetPoint()}))
                if not result then
                    Questie.db.char.TrackerLocation = nil
                    _QuestieTracker:SetSafePoint(frm)
                end
            else
                _QuestieTracker:SetSafePoint(frm)
            end
        end
    else
        if QuestWatchFrame then
            local result, error = pcall(frm.SetPoint, frm, unpack({QuestWatchFrame:GetPoint()}))
            if not result then
                Questie.db.char.TrackerLocation = nil
                print(QuestieLocale:GetUIString('TRACKER_INVALID_LOCATION'))
                _QuestieTracker:SetSafePoint(frm)
            end
        else
            _QuestieTracker:SetSafePoint(frm)
        end
    end

    frm:SetMovable(true)
    frm:EnableMouse(true)
    frm:RegisterForDrag("LeftButton", "RightButton")

    frm:SetScript("OnDragStart", QuestieTrackerMove.OnDragStart)
    frm:SetScript("OnDragStop", QuestieTrackerMove.OnDragStop)
    frm:SetScript("OnEnter", _OnEnter)
    frm:SetScript("OnLeave", _OnLeave)

    frm:Show()

    return frm
end

function QuestieTracker:GetBaseFrame()
    return _QuestieTracker.baseFrame
end

function QuestieTracker:SetBaseFrame(frm)
    _QuestieTracker.baseFrame = frm
end

function QuestieTracker:GetCounterFrame()
    return _QuestieTracker.counterFrame
end

function QuestieTracker:GetBackgroundPadding()
    return trackerBackgroundPadding
end