local _, ns = ...

-- A small window with a pre-selected text box: press Ctrl+C to copy, the window closes itself.
local popup

local function createPopup()
    local f = CreateFrame("Frame", "ForeverBiSLinkPopup", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(440, 128)
    f:SetPoint("CENTER", 0, 180)
    f:SetFrameStrata("DIALOG")
    f:SetToplevel(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, "ForeverBiSLinkPopup")
    ns.RegisterGamepadFrame(f)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -5)
    f.title:SetText("Copy link")

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.label:SetPoint("TOPLEFT", 16, -34)
    f.label:SetPoint("RIGHT", -16, 0)
    f.label:SetJustifyH("LEFT")
    f.label:SetWordWrap(false)

    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetSize(400, 22)
    eb:SetPoint("TOPLEFT", 22, -56)
    eb:SetAutoFocus(true)
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function() f:Hide() end)
    eb:SetScript("OnEnterPressed", function() f:Hide() end)
    -- keep the text unchanged if the user types into it
    eb:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= f.url then
            self:SetText(f.url)
            self:HighlightText()
        end
    end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    eb:SetScript("OnKeyDown", function(self, key)
        if key == "C" and (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then
            C_Timer.After(0.05, function()
                f:Hide()
                ns.Print("Link copied: " .. (f.url or ""))
            end)
        end
    end)
    f.editBox = eb

    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.hint:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", -6, -8)
    f.hint:SetText("Press Ctrl+C to copy (Cmd+C on Mac), then paste it in your browser or Discord.")

    return f
end

function ns.ShowLinkPopup(title, url)
    popup = popup or createPopup()
    popup.url = url
    popup.label:SetText(title or "")
    popup.editBox:SetText(url)
    popup:Show()
    popup.editBox:SetFocus()
    popup.editBox:HighlightText()
end

function ns.ShowLinkPopupForItem(itemID)
    ns.WithItem(itemID, function(item)
        local name = item and item:GetItemName() or ("Item " .. itemID)
        local link = item and item:GetItemLink() or name
        ns.ShowLinkPopup(link, ns.GetItemURL(itemID, name))
    end)
end
