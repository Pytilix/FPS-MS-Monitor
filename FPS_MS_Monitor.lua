--[[
    ============================================================================
    FPS & MS Monitor
    Copyright (c) 2021-2026 Pytilix
    All rights reserved.

    This Add-on and its source code are proprietary. 
    Unauthorized copying, modification, or distribution of this file, 
    via any medium, is strictly prohibited.
    
    The source code is provided for personal use and educational purposes 
    only, as per Blizzard's UI Add-On Development Policy.
    ============================================================================
--]]

local AddonName = "FPS_MS_Monitor"
local FMS = CreateFrame("Frame", "FPSMSMonitorFrame", UIParent, "BackdropTemplate")
local GFM = CreateFrame("Frame", "FPSMSGraphFrame", UIParent, "BackdropTemplate")
local BWM = CreateFrame("Frame", "FPSMSBandwidthFrame", UIParent, "BackdropTemplate")
local MSM = CreateFrame("Frame", "FPSMSLatencyFrame", UIParent, "BackdropTemplate")
local categoryID 

-- Liste der Fonts basierend auf deinem Ordner
local fontList = {
    {name = "Standard", path = STANDARD_TEXT_FONT},
    {name = "Adventure", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\Adventure.ttf"},
    {name = "Bazooka", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\Bazooka.ttf"},
    {name = "BlackChancery", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\BlackChancery.ttf"},
    {name = "Celestia", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\CelestiaMediumRedux1.55.ttf"},
    {name = "DejaVu Sans", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\DejaVuLGCSans.ttf"},
    {name = "DejaVu Serif", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\DejaVuLGCSerif.ttf"},
    {name = "DorisPP", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\DorisPP.ttf"},
    {name = "Enigma", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\EnigmaU_2.ttf"},
    {name = "Fitzgerald", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\Fitzgerald.ttf"},
    {name = "Gentium", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\GentiumPlus-Regular.ttf"},
    {name = "Hack", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\Hack-Regular.ttf"},
    {name = "HookedUp", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\HookedUp.ttf"},
    {name = "SFAtarian", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\SFAtarianSystem.ttf"},
    {name = "SFCovington", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\SFCovington.ttf"},
    {name = "SFMovie", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\SFMoviePoster-Bold.ttf"},
    {name = "SFWonder", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\SFWonderComic.ttf"},
    {name = "Yellow", path = "Interface\\AddOns\\"..AddonName.."\\fonts\\yellow.ttf"},
}

-- 1. DATABASE & DEFAULTS
local function InitDB()
    if not FPSMSMonitorDB then FPSMSMonitorDB = {} end
    local def = {
        locked = false, graphLocked = false, bwLocked = false, msLocked = false,
        fontSize = 12, fontOutline = "OUTLINE", fontIndex = 1,
        showBackground = true, bgAlpha = 0.7, bgColor = {r = 0, g = 0, b = 0},
        customWidth = 110, customHeight = 35, pos = {p = "TOPLEFT", x = 20, y = -20},
        showBorder = false, borderColor = {r = 1, g = 1, b = 1, a = 1}, edgeSize = 1,
        showGraph = false, graphBG = true, showGraphBorder = false,
        graphBGColor = {r = 0, g = 0, b = 0, a = 0.7}, graphBorderColor = {r = 1, g = 1, b = 1, a = 1},
        graphWidth = 150, graphHeight = 50, graphPos = {p = "TOPLEFT", x = 20, y = -60},
        showBWGraph = false, bwBG = true, showBWBorder = false,
        bwBGColor = {r = 0, g = 0, b = 0, a = 0.7}, bwBorderColor = {r = 1, g = 1, b = 1, a = 1},
        bwWidth = 150, bwHeight = 50, bwPos = {p = "TOPLEFT", x = 20, y = -120},
        showMSGraph = false, msBG = true, showMSBorder = false,
        msBGColor = {r = 0, g = 0, b = 0, a = 0.7}, msBorderColor = {r = 1, g = 1, b = 1, a = 1},
        msWidth = 150, msHeight = 50, msPos = {p = "TOPLEFT", x = 20, y = -180},
        graphEdgeSize = 1,
        showFPS = true, showMS = true, showMSHome = false, showMSWorld = false, showTraffic = false, showTime = false,
        colorFPS = {r = 1, g = 1, b = 1}, colorMS = {r = 1, g = 1, b = 1}, colorHome = {r = 1, g = 1, b = 1},
        colorWorld = {r = 1, g = 1, b = 1}, colorTraffic = {r = 1, g = 1, b = 1}, colorTime = {r = 1, g = 1, b = 1},
        useMouseover = false, idleAlpha = 0, fadeSpeed = 0.3,
    }
    for k, v in pairs(def) do if FPSMSMonitorDB[k] == nil then FPSMSMonitorDB[k] = v end end
end

-- 2. TOOLTIP & FADE
local function ShowTrafficTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    local inRate, outRate, hL, wL = GetNetStats()
    GameTooltip:AddLine("FPS & MS Monitor", 1, 0.82, 0)
    GameTooltip:AddLine("|cff00ff00Type /fms for Settings|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Latency (Home/World):", hL.."/"..wL.." ms", 0.7,0.7,0.7, 1,1,1)
    GameTooltip:AddDoubleLine("Traffic (In/Out):", string.format("%.1f/%.1f KB/s", inRate, outRate), 0.7,0.7,0.7, 1,1,1)
    UpdateAddOnMemoryUsage()
    local totalMem = 0
    for i = 1, C_AddOns.GetNumAddOns() do totalMem = totalMem + GetAddOnMemoryUsage(i) end
    GameTooltip:AddDoubleLine("Total Addon Memory:", string.format("%.2f MB", totalMem / 1024), 1, 0.8, 0, 1, 1, 1)
    GameTooltip:Show()
end

local function FadeFrame(f, targetAlpha)
    if not FPSMSMonitorDB.useMouseover then f:SetAlpha(1.0) return end
    UIFrameFadeIn(f, FPSMSMonitorDB.fadeSpeed, f:GetAlpha(), targetAlpha)
end

-- 3. GRAPH LOGIC
local fpsHistory, bwHistory, msHistory = {}, {}, {}
local fpsBars, bwBars, msBars = {}, {}, {}

local function CreateGraphTitle(f, text)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.title:SetPoint("TOPLEFT", 5, -2); f.title:SetText(text)
end
CreateGraphTitle(GFM, "FPS:"); CreateGraphTitle(BWM, "Traffic:"); CreateGraphTitle(MSM, "MS:")

local function UpdateGraphs()
    local db = FPSMSMonitorDB
    if db.showGraph then
        GFM:Show(); table.insert(fpsHistory, GetFramerate()); if #fpsHistory > 40 then table.remove(fpsHistory, 1) end
        local w, h = (db.graphWidth - 10) / 40, db.graphHeight - 15
        for i = 1, 40 do
            if not fpsBars[i] then fpsBars[i] = GFM:CreateTexture(nil, "OVERLAY"); fpsBars[i]:SetTexture("Interface/ChatFrame/ChatFrameBackground") end
            local val = fpsHistory[i] or 0
            fpsBars[i]:SetSize(math.max(1, w - 1), h * math.min(val / 144, 1) + 1)
            fpsBars[i]:SetPoint("BOTTOMLEFT", GFM, "BOTTOMLEFT", 5 + (i-1)*w, 5)
            if val > 60 then fpsBars[i]:SetVertexColor(0, 1, 0, 0.7) elseif val > 30 then fpsBars[i]:SetVertexColor(1, 1, 0, 0.7) else fpsBars[i]:SetVertexColor(1, 0, 0, 0.7) end
        end
    else GFM:Hide() end
    if db.showBWGraph then
        BWM:Show(); local inR, outR = GetNetStats(); table.insert(bwHistory, inR + outR); if #bwHistory > 40 then table.remove(bwHistory, 1) end
        local w, h = (db.bwWidth - 10) / 40, db.bwHeight - 15
        for i = 1, 40 do
            if not bwBars[i] then bwBars[i] = BWM:CreateTexture(nil, "OVERLAY"); bwBars[i]:SetTexture("Interface/ChatFrame/ChatFrameBackground") end
            local val = bwHistory[i] or 0
            bwBars[i]:SetSize(math.max(1, w - 1), h * math.min(val / 100, 1) + 1)
            bwBars[i]:SetPoint("BOTTOMLEFT", BWM, "BOTTOMLEFT", 5 + (i-1)*w, 5)
            bwBars[i]:SetVertexColor(0.2, 0.6, 1, 0.8)
        end
    else BWM:Hide() end
    if db.showMSGraph then
        MSM:Show(); local _, _, hMS, wMS = GetNetStats(); table.insert(msHistory, math.max(hMS, wMS)); if #msHistory > 40 then table.remove(msHistory, 1) end
        local w, h = (db.msWidth - 10) / 40, db.msHeight - 15
        for i = 1, 40 do
            if not msBars[i] then msBars[i] = MSM:CreateTexture(nil, "OVERLAY"); msBars[i]:SetTexture("Interface/ChatFrame/ChatFrameBackground") end
            local val = msHistory[i] or 0
            msBars[i]:SetSize(math.max(1, w - 1), h * math.min(val / 200, 1) + 1)
            msBars[i]:SetPoint("BOTTOMLEFT", MSM, "BOTTOMLEFT", 5 + (i-1)*w, 5)
            if val < 50 then msBars[i]:SetVertexColor(0, 1, 0, 0.7) elseif val < 150 then msBars[i]:SetVertexColor(1, 1, 0, 0.7) else msBars[i]:SetVertexColor(1, 0, 0, 0.7) end
        end
    else MSM:Hide() end
end

-- 4. UPDATE LOOK
local function UpdateLook()
    local db = FPSMSMonitorDB
    if not db then return end
    local frames = {
        {f = FMS, w = db.customWidth, h = db.customHeight, p = db.pos, showBG = db.showBackground, showBD = db.showBorder, bgC = db.bgColor, bdC = db.borderColor, eS = db.edgeSize},
        {f = GFM, w = db.graphWidth, h = db.graphHeight, p = db.graphPos, showBG = db.graphBG, showBD = db.showGraphBorder, bgC = db.graphBGColor, bdC = db.graphBorderColor, eS = db.graphEdgeSize},
        {f = BWM, w = db.bwWidth, h = db.bwHeight, p = db.bwPos, showBG = db.bwBG, showBD = db.showBWBorder, bgC = db.bwBGColor, bdC = db.bwBorderColor, eS = db.graphEdgeSize},
        {f = MSM, w = db.msWidth, h = db.msHeight, p = db.msPos, showBG = db.msBG, showBD = db.showMSBorder, bgC = db.msBGColor, bdC = db.msBorderColor, eS = db.graphEdgeSize}
    }
    for _, cfg in ipairs(frames) do
        cfg.f:SetSize(cfg.w, cfg.h); cfg.f:ClearAllPoints(); cfg.f:SetPoint(cfg.p.p, UIParent, cfg.p.p, cfg.p.x, cfg.p.y)
        cfg.f:SetBackdrop({bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = cfg.showBD and "Interface/ChatFrame/ChatFrameBackground" or nil, edgeSize = cfg.eS or 1})
        cfg.f:SetBackdropColor(cfg.bgC.r, cfg.bgC.g, cfg.bgC.b, cfg.showBG and (cfg.bgC.a or db.bgAlpha) or 0)
        cfg.f:SetBackdropBorderColor(cfg.bdC.r, cfg.bdC.g, cfg.bdC.b, cfg.showBD and (cfg.bdC.a or 1) or 0)
        cfg.f:SetAlpha(db.useMouseover and db.idleAlpha or 1.0)
    end
    local currentFont = fontList[db.fontIndex] and fontList[db.fontIndex].path or STANDARD_TEXT_FONT
    FMS.text:SetFont(currentFont, db.fontSize, db.fontOutline)
end

FMS.text = FMS:CreateFontString(nil, "OVERLAY"); FMS.text:SetPoint("CENTER", 0, 0)
FMS:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer > 0.1 then
        local db = FPSMSMonitorDB; local inR, outR, hMS, wMS = GetNetStats(); local txt = ""
        if db.showFPS then txt = txt .. string.format("|cff%02x%02x%02x%.0f FPS|r ", db.colorFPS.r*255, db.colorFPS.g*255, db.colorFPS.b*255, GetFramerate()) end
        if db.showMS then txt = txt .. string.format("|cff%02x%02x%02x%d MS|r", db.colorMS.r*255, db.colorMS.g*255, db.colorMS.b*255, wMS > 0 and wMS or hMS) end
        if db.showMSHome then txt = txt .. string.format("\n|cff%02x%02x%02xHome: %d MS|r", db.colorHome.r*255, db.colorHome.g*255, db.colorHome.b*255, hMS) end
        if db.showMSWorld then txt = txt .. string.format("\n|cff%02x%02x%02xWorld: %d MS|r", db.colorWorld.r*255, db.colorWorld.g*255, db.colorWorld.b*255, wMS) end
        if db.showTraffic then txt = txt .. string.format("\n|cff%02x%02x%02xIn: %.1f Out: %.1f|r", db.colorTraffic.r*255, db.colorTraffic.g*255, db.colorTraffic.b*255, inR, outR) end
        if db.showTime then txt = txt .. string.format("\n|cff%02x%02x%02x%s|r", db.colorTime.r*255, db.colorTime.g*255, db.colorTime.b*255, date("%H:%M:%S")) end
        FMS.text:SetText(txt); UpdateGraphs(); self.timer = 0
    end
end)

-- 5. OPTIONS MENU
local function CreateInterfaceOptions()
    local panel = CreateFrame("Frame", "FMSOptionsPanel", UIParent); panel.name = "FPS & MS Monitor"
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10); scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
    local content = CreateFrame("Frame", nil, scrollFrame); content:SetSize(580, 950); scrollFrame:SetScrollChild(content)

    local function CreateHeader(text, y)
        local h = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        h:SetPoint("TOPLEFT", 16, y); h:SetText(text); h:SetTextColor(1, 0.8, 0)
        local line = content:CreateTexture(nil, "ARTWORK"); line:SetSize(550, 1); line:SetPoint("TOPLEFT", 16, y-18)
        line:SetColorTexture(1, 1, 1, 0.2); return y - 40
    end

    local function CreateToggle(label, dbKey, x, y, colorKey)
        local cb = CreateFrame("CheckButton", "FMS_CB_"..dbKey, content, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y); _G[cb:GetName().."Text"]:SetText(label)
        cb:SetChecked(FPSMSMonitorDB[dbKey]); cb:SetScript("OnClick", function(s) FPSMSMonitorDB[dbKey] = s:GetChecked(); UpdateLook() end)
        if colorKey then
            local btn = CreateFrame("Button", nil, content, "BackdropTemplate")
            btn:SetSize(16, 16); btn:SetPoint("LEFT", cb, "LEFT", 115, 0) 
            btn:SetBackdrop({bgFile = "Interface/ChatFrame/ChatFrameBackground", edgeFile = "Interface/Buttons/WHITE8X8", edgeSize = 1})
            btn:SetBackdropColor(FPSMSMonitorDB[colorKey].r, FPSMSMonitorDB[colorKey].g, FPSMSMonitorDB[colorKey].b, 1)
            btn:SetScript("OnClick", function()
                ColorPickerFrame:SetupColorPickerAndShow({
                    r = FPSMSMonitorDB[colorKey].r, g = FPSMSMonitorDB[colorKey].g, b = FPSMSMonitorDB[colorKey].b, 
                    hasOpacity = colorKey:find("BG") or colorKey:find("Border"), opacity = (FPSMSMonitorDB[colorKey].a or 1),
                    swatchFunc = function() 
                        FPSMSMonitorDB[colorKey].r, FPSMSMonitorDB[colorKey].g, FPSMSMonitorDB[colorKey].b = ColorPickerFrame:GetColorRGB()
                        if ColorPickerFrame.hasOpacity then FPSMSMonitorDB[colorKey].a = ColorPickerFrame:GetColorAlpha() end
                        btn:SetBackdropColor(FPSMSMonitorDB[colorKey].r, FPSMSMonitorDB[colorKey].g, FPSMSMonitorDB[colorKey].b, 1); UpdateLook()
                    end
                })
            end)
        end
    end

    local function CreateSlider(label, dbKey, minV, maxV, step, x, y)
        local s = CreateFrame("Slider", "FMS_S_"..dbKey, content, "OptionsSliderTemplate")
        s:SetPoint("TOPLEFT", x, y); s:SetMinMaxValues(minV, maxV); s:SetValueStep(step); s:SetValue(FPSMSMonitorDB[dbKey]); s:SetWidth(160)
        _G[s:GetName().."Text"]:SetText(label .. ": " .. FPSMSMonitorDB[dbKey])
        s:SetScript("OnValueChanged", function(self, v)
            v = step < 0.1 and math.floor(v*100)/100 or math.floor(v)
            FPSMSMonitorDB[dbKey] = v; _G[self:GetName().."Text"]:SetText(label .. ": " .. v); UpdateLook()
        end)
    end

    local currY = -20
    local col1, col2, col3, col4 = 16, 160, 304, 448
    local sl1, sl2, sl3 = 16, 200, 385

    -- === DISPLAY & WINDOW OPTIONS ===
    currY = CreateHeader("Display & Window Options", currY)
    
    -- Reihe 1-3
    CreateToggle("Show FPS", "showFPS", col1, currY, "colorFPS"); CreateToggle("Show MS", "showMS", col2, currY, "colorMS"); 
    CreateToggle("Home MS", "showMSHome", col3, currY, "colorHome"); CreateToggle("World MS", "showMSWorld", col4, currY, "colorWorld"); currY = currY - 30
    CreateToggle("Show BW", "showTraffic", col1, currY, "colorTraffic"); CreateToggle("Show Time", "showTime", col2, currY, "colorTime"); 
    CreateToggle("Mouseover", "useMouseover", col3, currY); CreateToggle("Lock Window", "locked", col4, currY); currY = currY - 30
    CreateToggle("Main BG", "showBackground", col1, currY, "bgColor"); CreateToggle("Main Border", "showBorder", col2, currY, "borderColor"); currY = currY - 50

    -- Reihe 4-6 (Slider)
    CreateSlider("Font Size", "fontSize", 8, 30, 1, sl1, currY); CreateSlider("BG Alpha", "bgAlpha", 0, 1, 0.05, sl2, currY); CreateSlider("Border Size", "edgeSize", 1, 10, 1, sl3, currY); currY = currY - 50
    CreateSlider("Main Width", "customWidth", 40, 400, 5, sl1, currY); CreateSlider("Main Height", "customHeight", 10, 200, 5, sl2, currY); CreateSlider("Fade Speed", "fadeSpeed", 0.1, 2, 0.1, sl3, currY); currY = currY - 50
    CreateSlider("Idle Alpha", "idleAlpha", 0, 1, 0.05, sl1, currY)

    -- === REIHE 7: FONT SELECTOR BOX ===
    local fontLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontLabel:SetPoint("TOPLEFT", sl1, currY - 45); fontLabel:SetText("Choose Font:")

    local fontBox = CreateFrame("Frame", "FMSFontSelector", content, "BackdropTemplate")
    fontBox:SetSize(180, 26); fontBox:SetPoint("TOPLEFT", sl1, currY - 65)
    fontBox:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    fontBox:SetBackdropColor(0, 0, 0, 0.5); fontBox:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    local fontText = fontBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontText:SetPoint("CENTER", 0, 0); fontText:SetText(fontList[FPSMSMonitorDB.fontIndex].name)

    local prevBtn = CreateFrame("Button", nil, fontBox)
    prevBtn:SetSize(20, 20); prevBtn:SetPoint("LEFT", -22, 0)
    prevBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prevBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prevBtn:SetScript("OnClick", function()
        FPSMSMonitorDB.fontIndex = FPSMSMonitorDB.fontIndex - 1
        if FPSMSMonitorDB.fontIndex < 1 then FPSMSMonitorDB.fontIndex = #fontList end
        fontText:SetText(fontList[FPSMSMonitorDB.fontIndex].name); UpdateLook()
    end)

    local nextBtn = CreateFrame("Button", nil, fontBox)
    nextBtn:SetSize(20, 20); nextBtn:SetPoint("RIGHT", 22, 0)
    nextBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nextBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nextBtn:SetScript("OnClick", function()
        FPSMSMonitorDB.fontIndex = FPSMSMonitorDB.fontIndex + 1
        if FPSMSMonitorDB.fontIndex > #fontList then FPSMSMonitorDB.fontIndex = 1 end
        fontText:SetText(fontList[FPSMSMonitorDB.fontIndex].name); UpdateLook()
    end)

    currY = currY - 140

    -- === GRAPHS SETTINGS ===
    currY = CreateHeader("Graphs Settings", currY)
    CreateToggle("FPS Graph", "showGraph", col1, currY); CreateToggle("FPS BG", "graphBG", col2, currY, "graphBGColor"); CreateToggle("FPS Border", "showGraphBorder", col3, currY, "graphBorderColor"); CreateToggle("FPS Graph Lock", "graphLocked", col4, currY); currY = currY - 30
    CreateToggle("BW Graph", "showBWGraph", col1, currY); CreateToggle("BW BG", "bwBG", col2, currY, "bwBGColor"); CreateToggle("BW Border", "showBWBorder", col3, currY, "bwBorderColor"); CreateToggle("BW Graph Lock", "bwLocked", col4, currY); currY = currY - 30
    CreateToggle("MS Graph", "showMSGraph", col1, currY); CreateToggle("MS BG", "msBG", col2, currY, "msBGColor"); CreateToggle("MS Border", "showMSBorder", col3, currY, "msBorderColor"); CreateToggle("MS Graph Lock", "msLocked", col4, currY); currY = currY - 60

    CreateSlider("Global Border", "graphEdgeSize", 1, 10, 1, sl1, currY); CreateSlider("FPS Width", "graphWidth", 40, 500, 5, sl2, currY); CreateSlider("FPS Height", "graphHeight", 10, 300, 5, sl3, currY); currY = currY - 50
    CreateSlider("BW Width", "bwWidth", 40, 500, 5, sl1, currY); CreateSlider("BW Height", "bwHeight", 10, 300, 5, sl2, currY); CreateSlider("MS Width", "msWidth", 40, 500, 5, sl3, currY); currY = currY - 50
    CreateSlider("MS Height", "msHeight", 10, 300, 5, sl1, currY); currY = currY - 70

    local reload = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reload:SetSize(100, 25); reload:SetPoint("BOTTOMLEFT", 16, 10); reload:SetText("Reload UI"); reload:SetScript("OnClick", ReloadUI)
    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(100, 25); reset:SetPoint("LEFT", reload, "RIGHT", 10, 0); reset:SetText("Reset"); reset:SetScript("OnClick", function() FPSMSMonitorDB = nil; ReloadUI() end)
    
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name); Settings.RegisterAddOnCategory(category); categoryID = category:GetID() 
end

-- 6. INTERACTION
local function SetupFrameInteraction(f, dbLockedKey)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(s) if not FPSMSMonitorDB[dbLockedKey] then s:StartMoving() end end)
    f:SetScript("OnDragStop", function(s) 
        s:StopMovingOrSizing(); local p, _, _, x, y = s:GetPoint()
        local key = (f == FMS and "pos" or (f == GFM and "graphPos" or (f == BWM and "bwPos" or "msPos")))
        FPSMSMonitorDB[key] = {p = p, x = x, y = y}
    end)
    f:SetScript("OnEnter", function(s) FadeFrame(s, 1.0); if f == FMS then ShowTrafficTooltip(s) end end)
    f:SetScript("OnLeave", function(s) FadeFrame(s, FPSMSMonitorDB.idleAlpha); GameTooltip:Hide() end)
end

SetupFrameInteraction(FMS, "locked"); SetupFrameInteraction(GFM, "graphLocked"); SetupFrameInteraction(BWM, "bwLocked"); SetupFrameInteraction(MSM, "msLocked")

SLASH_FMS1 = "/fms"; SlashCmdList["FMS"] = function() Settings.OpenToCategory(categoryID or "FPS & MS Monitor") end

FMS:RegisterEvent("ADDON_LOADED")
FMS:SetScript("OnEvent", function(self, event, arg1) 
    if arg1 == AddonName then InitDB(); UpdateLook(); CreateInterfaceOptions(); print("|cff00ff00FPS & MS Monitor loaded. /fms for settings.|r") end 
end)