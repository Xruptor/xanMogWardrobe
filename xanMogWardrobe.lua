local ADDON_NAME, addon = ...
if not _G[ADDON_NAME] then
	_G[ADDON_NAME] = CreateFrame("Frame", ADDON_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
end
addon = _G[ADDON_NAME]

local debugf = tekDebug and tekDebug:GetFrame(ADDON_NAME)
local function Debug(...)
    if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end

--We need to use a customFrame since AceEvent is loaded and it takes over the RegisterEvent frames
local eventFrame = CreateFrame("Frame", ADDON_NAME.."EventFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		if event == "ADDON_LOADED" then
			local arg1 = ...
			if arg1 and arg1 == ADDON_NAME then
				eventFrame:UnregisterEvent("ADDON_LOADED")
				eventFrame:RegisterEvent("PLAYER_LOGIN")
			end
			return
		end
		if IsLoggedIn() then
			addon:EnableAddon(event, ...)
			eventFrame:UnregisterEvent("PLAYER_LOGIN")
			eventFrame = nil
		end
		return
	end
end)

local AceGUI = LibStub("AceGUI-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)
LibStub("AceEvent-3.0"):Embed(addon)

local IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

--see slot diagram here https://wow.gamepedia.com/InventorySlotId
--https://wow.gamepedia.com/InventorySlotName

local transMogSlots = { 
	[0] = {canTransMog = false, globalString = "Ammo", invSlotName = "AMMOSLOT", slotID = INVSLOT_AMMO},
	[1] = {canTransMog = true, globalString = "Head", invSlotName = "HEADSLOT", slotID = INVSLOT_HEAD, buttonPos = 1},
	[2] = {canTransMog = false, globalString = "Neck", invSlotName = "NECKSLOT", slotID = INVSLOT_NECK},
	[3] = {canTransMog = true, globalString = "Shoulders", invSlotName = "SHOULDERSLOT", slotID = INVSLOT_SHOULDER, buttonPos = 2},
	[4] = {canTransMog = true, globalString = "Shirt", invSlotName = "SHIRTSLOT", slotID = INVSLOT_BODY, buttonPos = 5},
	[5] = {canTransMog = true, globalString = "Chest", invSlotName = "CHESTSLOT", slotID = INVSLOT_CHEST, buttonPos = 4},
	[6] = {canTransMog = true, globalString = "Waist", invSlotName = "WAISTSLOT", slotID = INVSLOT_WAIST, buttonPos = 9},
	[7] = {canTransMog = true, globalString = "Legs", invSlotName = "LEGSSLOT", slotID = INVSLOT_LEGS, buttonPos = 10},
	[8] = {canTransMog = true, globalString = "Feet", invSlotName = "FEETSLOT", slotID = INVSLOT_FEET, buttonPos = 11},
	[9] = {canTransMog = true, globalString = "Wrist", invSlotName = "WRISTSLOT", slotID = INVSLOT_WRIST, buttonPos = 7},
	[10] = {canTransMog = true, globalString = "Hands", invSlotName = "HANDSSLOT", slotID = INVSLOT_HAND, buttonPos = 8},
	[11] = {canTransMog = false, globalString = "Finger", invSlotName = "FINGER0SLOT", slotID = INVSLOT_FINGER1},
	[12] = {canTransMog = false, globalString = "Finger", invSlotName = "FINGER1SLOT", slotID = INVSLOT_FINGER2},
	[13] = {canTransMog = false, globalString = "Trinket", invSlotName = "TRINKET0SLOT", slotID = INVSLOT_TRINKET1},
	[14] = {canTransMog = false, globalString = "Trinket", invSlotName = "TRINKET1SLOT", slotID = INVSLOT_TRINKET2},
	[15] = {canTransMog = true, globalString = "Back", invSlotName = "BACKSLOT", slotID = INVSLOT_BACK, buttonPos = 3},
	[16] = {canTransMog = true, globalString = "Main Hand", invSlotName = "MAINHANDSLOT", slotID = INVSLOT_MAINHAND, buttonPos = 12},
	[17] = {canTransMog = true, globalString = "Off Hand", invSlotName = "SECONDARYHANDSLOT", slotID = INVSLOT_OFFHAND, buttonPos = 13},
	[18] = {canTransMog = false, globalString = "Ranged", invSlotName = "RANGEDSLOT", slotID = INVSLOT_RANGED},
	[19] = {canTransMog = true, globalString = "Tabard", invSlotName = "TABARDSLOT", slotID = INVSLOT_TABARD, buttonPos = 6},
}

local MAINHANDSLOT_ENCHANT = 98
local SECONDARYHANDSLOT_ENCHANT = 99

--https://wow.gamepedia.com/RaceId

local RaceIDs = {
    Human = 1,
    Orc = 2,
    Dwarf = 3,
    NightElf = 4,
    Scourge = 5,
    Tauren = 6,
    Gnome = 7,
    Troll = 8,
    Goblin = 9,
    BloodElf = 10,
    Draenei = 11,
    Worgen = 22,
    Pandaren = 24,
	LightforgedDraenei = 30,
	HighmountainTauren = 28,
	Nightborne = 27,
	VoidElf = 29,
	MagharOrc = 36,
	DarkIronDwarf = 34,
	KulTiran = 32,
	ZandalariTroll = 31,
	Mechagnome = 37,
	Vulpera = 35,
}

local raceGender = {
    [0] = MALE,
    [1] = FEMALE,
}

--update this from here Blizzard_Wardrobe.lua
local SET_MODEL_PAN_AND_ZOOM_LIMITS = {
	["Draenei2"] = { maxZoom = 2.2105259895325, panMaxLeft = -0.56983226537705, panMaxRight = 0.82581323385239, panMaxTop = -0.17342753708363, panMaxBottom = -2.6428601741791 },
	["Draenei3"] = { maxZoom = 3.0592098236084, panMaxLeft = -0.33429977297783, panMaxRight = 0.29183092713356, panMaxTop = -0.079871296882629, panMaxBottom = -2.4141833782196 },
	["Worgen2"] = { maxZoom = 1.9605259895325, panMaxLeft = -0.64045578241348, panMaxRight = 0.59410041570663, panMaxTop = -0.11050206422806, panMaxBottom = -2.2492413520813 },
	["Worgen3"] = { maxZoom = 2.9013152122498, panMaxLeft = -0.2526838183403, panMaxRight = 0.38198262453079, panMaxTop = -0.10407017171383, panMaxBottom = -2.4137926101685 },
	["Worgen3Alt"] = { maxZoom = 3.3618412017822, panMaxLeft = -0.19753229618072, panMaxRight = 0.26802557706833, panMaxTop = -0.073476828634739, panMaxBottom = -1.9255120754242 },
	["Worgen2Alt"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.33268970251083, panMaxRight = 0.36896070837975, panMaxTop = -0.14780110120773, panMaxBottom = -2.1662468910217 },
	["Scourge2"] = { maxZoom = 3.1710526943207, panMaxLeft = -0.3243542611599, panMaxRight = 0.5625838637352, panMaxTop = -0.054175414144993, panMaxBottom = -1.7261047363281 },
	["Scourge3"] = { maxZoom = 2.7105259895325, panMaxLeft = -0.35650563240051, panMaxRight = 0.41562974452972, panMaxTop = -0.07072202116251, panMaxBottom = -1.877711892128 },
	["Orc2"] = { maxZoom = 2.5526309013367, panMaxLeft = -0.64236557483673, panMaxRight = 0.77098786830902, panMaxTop = -0.075792260468006, panMaxBottom = -2.0818419456482 },
	["Orc3"] = { maxZoom = 3.2960524559021, panMaxLeft = -0.22763830423355, panMaxRight = 0.32022559642792, panMaxTop = -0.038521766662598, panMaxBottom = -2.0473554134369 },
	["Gnome3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.29900181293488, panMaxRight = 0.35779395699501, panMaxTop = -0.076380833983421, panMaxBottom = -0.99909907579422 },
	["Gnome2"] = { maxZoom = 2.8552639484406, panMaxLeft = -0.2777853012085, panMaxRight = 0.29651582241058, panMaxTop = -0.095201380550861, panMaxBottom = -1.0263166427612 },
	["Dwarf2"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.50352156162262, panMaxRight = 0.4159924685955, panMaxTop = -0.07211934030056, panMaxBottom = -1.4946432113648 },
	["Dwarf3"] = { maxZoom = 2.8947370052338, panMaxLeft = -0.37057432532311, panMaxRight = 0.43383255600929, panMaxTop = -0.084960877895355, panMaxBottom = -1.7173190116882 },
	["BloodElf3"] = { maxZoom = 3.1644730567932, panMaxLeft = -0.2654082775116, panMaxRight = 0.28886350989342, panMaxTop = -0.049619361758232, panMaxBottom = -1.9943760633469 },
	["BloodElf2"] = { maxZoom = 3.1710524559021, panMaxLeft = -0.25901651382446, panMaxRight = 0.45525884628296, panMaxTop = -0.085230752825737, panMaxBottom = -2.0548067092895 },
	["Troll2"] = { maxZoom = 2.2697355747223, panMaxLeft = -0.58214980363846, panMaxRight = 0.5104039311409, panMaxTop = -0.05494449660182, panMaxBottom = -2.3443803787231 },
	["Troll3"] = { maxZoom = 3.1249995231628, panMaxLeft = -0.35141581296921, panMaxRight = 0.50875341892242, panMaxTop = -0.063820324838161, panMaxBottom = -2.4224486351013 },
	["Tauren2"] = { maxZoom = 2.1118416786194, panMaxLeft = -0.82946360111237, panMaxRight = 0.83975899219513, panMaxTop = -0.061676319688559, panMaxBottom = -2.035267829895 },
	["Tauren3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.37433895468712, panMaxRight = 0.40420442819595, panMaxTop = -0.1868137717247, panMaxBottom = -2.2116675376892 },
	["NightElf3"] = { maxZoom = 2.9539475440979, panMaxLeft = -0.27334463596344, panMaxRight = 0.27148312330246, panMaxTop = -0.094710879027844, panMaxBottom = -2.3087983131409 },
	["NightElf2"] = { maxZoom = 2.9144732952118, panMaxLeft = -0.45042458176613, panMaxRight = 0.47114592790604, panMaxTop = -0.10513981431723, panMaxBottom = -2.4612309932709 },
	["Human3"] = { maxZoom = 3.3618412017822, panMaxLeft = -0.19753229618072, panMaxRight = 0.26802557706833, panMaxTop = -0.073476828634739, panMaxBottom = -1.9255120754242 },
	["Human2"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.33268970251083, panMaxRight = 0.36896070837975, panMaxTop = -0.14780110120773, panMaxBottom = -2.1662468910217 },
	["Pandaren3"] = { maxZoom = 2.5921046733856, panMaxLeft = -0.45187762379646, panMaxRight = 0.54132586717606, panMaxTop = -0.11439494043589, panMaxBottom = -2.2257535457611 },
	["Pandaren2"] = { maxZoom = 2.9342107772827, panMaxLeft = -0.36421552300453, panMaxRight = 0.50203305482864, panMaxTop = -0.11241528391838, panMaxBottom = -2.3707413673401 },
	["Goblin2"] = { maxZoom = 2.4605259895325, panMaxLeft = -0.31328883767128, panMaxRight = 0.39014467597008, panMaxTop = -0.089733943343162, panMaxBottom = -1.3402827978134 },
	["Goblin3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.26144406199455, panMaxRight = 0.30945864319801, panMaxTop = -0.07625275105238, panMaxBottom = -1.2928194999695 },
	["LightforgedDraenei2"] = { maxZoom = 2.2105259895325, panMaxLeft = -0.56983226537705, panMaxRight = 0.82581323385239, panMaxTop = -0.17342753708363, panMaxBottom = -2.6428601741791 },
	["LightforgedDraenei3"] = { maxZoom = 3.0592098236084, panMaxLeft = -0.33429977297783, panMaxRight = 0.29183092713356, panMaxTop = -0.079871296882629, panMaxBottom = -2.4141833782196 },
	["HighmountainTauren2"] = { maxZoom = 2.1118416786194, panMaxLeft = -0.82946360111237, panMaxRight = 0.83975899219513, panMaxTop = -0.061676319688559, panMaxBottom = -2.035267829895 },
	["HighmountainTauren3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.37433895468712, panMaxRight = 0.40420442819595, panMaxTop = -0.1868137717247, panMaxBottom = -2.2116675376892 },
	["Nightborne3"] = { maxZoom = 2.9539475440979, panMaxLeft = -0.27334463596344, panMaxRight = 0.27148312330246, panMaxTop = -0.094710879027844, panMaxBottom = -2.3087983131409 },
	["Nightborne2"] = { maxZoom = 2.9144732952118, panMaxLeft = -0.45042458176613, panMaxRight = 0.47114592790604, panMaxTop = -0.10513981431723, panMaxBottom = -2.4612309932709 },
	["VoidElf3"] = { maxZoom = 3.1644730567932, panMaxLeft = -0.2654082775116, panMaxRight = 0.28886350989342, panMaxTop = -0.049619361758232, panMaxBottom = -1.9943760633469 },
	["VoidElf2"] = { maxZoom = 3.1710524559021, panMaxLeft = -0.25901651382446, panMaxRight = 0.45525884628296, panMaxTop = -0.085230752825737, panMaxBottom = -2.0548067092895 },
	["MagharOrc2"] = { maxZoom = 2.5526309013367, panMaxLeft = -0.64236557483673, panMaxRight = 0.77098786830902, panMaxTop = -0.075792260468006, panMaxBottom = -2.0818419456482 },
	["MagharOrc3"] = { maxZoom = 3.2960524559021, panMaxLeft = -0.22763830423355, panMaxRight = 0.32022559642792, panMaxTop = -0.038521766662598, panMaxBottom = -2.0473554134369 },
	["DarkIronDwarf2"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.50352156162262, panMaxRight = 0.4159924685955, panMaxTop = -0.07211934030056, panMaxBottom = -1.4946432113648 },
	["DarkIronDwarf3"] = { maxZoom = 2.8947370052338, panMaxLeft = -0.37057432532311, panMaxRight = 0.43383255600929, panMaxTop = -0.084960877895355, panMaxBottom = -1.7173190116882 },
	["KulTiran2"] = { maxZoom =  1.71052598953247, panMaxLeft = -0.667941331863403, panMaxRight = 0.589463412761688, panMaxTop = -0.373320609331131, panMaxBottom = -2.7329957485199 },
	["KulTiran3"] = { maxZoom =  2.22368383407593, panMaxLeft = -0.43183308839798, panMaxRight = 0.445900857448578, panMaxTop = -0.303212702274323, panMaxBottom = -2.49550628662109 },
	["ZandalariTroll2"] = { maxZoom =  2.1710512638092, panMaxLeft = -0.487841755151749, panMaxRight = 0.561356604099274, panMaxTop = -0.385127544403076, panMaxBottom = -2.78562784194946 },
	["ZandalariTroll3"] = { maxZoom =  3.32894563674927, panMaxLeft = -0.376705944538116, panMaxRight = 0.488780438899994, panMaxTop = -0.20890490710735, panMaxBottom = -2.67064166069031 },
	["Mechagnome3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.29900181293488, panMaxRight = 0.35779395699501, panMaxTop = -0.076380833983421, panMaxBottom = -0.99909907579422 },
	["Mechagnome2"] = { maxZoom = 2.8552639484406, panMaxLeft = -0.2777853012085, panMaxRight = 0.29651582241058, panMaxTop = -0.095201380550861, panMaxBottom = -1.0263166427612 },
	["Vulpera2"] = { maxZoom = 2.4605259895325, panMaxLeft = -0.31328883767128, panMaxRight = 0.39014467597008, panMaxTop = -0.089733943343162, panMaxBottom = -1.3402827978134 },
	["Vulpera3"] = { maxZoom = 2.9605259895325, panMaxLeft = -0.26144406199455, panMaxRight = 0.30945864319801, panMaxTop = -0.07625275105238, panMaxBottom = -1.2928194999695 },
}

local function showAlert(...)
	local tmp = {}
	local index = 0
	
	index = index + 1
	tmp[index] = "|cFF99CC33"..ADDON_NAME.."|r:"
	
	for i=1, select("#", ...) do
		index = index + 1
		tmp[index] = tostring(select(i, ...))
	end
	
	DEFAULT_CHAT_FRAME:AddMessage( table.concat(tmp, " " , 1 , index) )
end

local function getItemMatrix(itemID)
	if not itemID then return nil end
	local name, itemLink, quality, itemLevel, reqLevel, class, subClass, maxStack, equipSlot, icon, sellPrice, classID, subClassID, bindType, expansion, itemSetID, isReagent = GetItemInfo(itemID)
	if name then
		return {
			name = name,
			itemLink = itemLink,
			quality = quality,
			itemLevel = itemLevel,
			reqLevel = reqLevel,
			class = class,
			subClass = subClass,
			maxStack = maxStack,
			equipSlot = equipSlot,
			icon = icon,
			sellPrice = sellPrice,
			classID = classID,
			subClassID = subClassID,
			bindType = bindType,
			expansion = expansion,
			itemSetID = itemSetID,
			isReagent = isReagent,
		}
	end
	return nil
end

local function itemSlotIcon(slotID, texture, itemLink, illusionID)
	if not slotID or not addon.WardrobeFrame.itemSlots or not addon.WardrobeFrame.itemSlots[slotID] then return end
	
	local itemSlots = addon.WardrobeFrame.itemSlots
	
	--check for illusions
	if illusionID or slotID == MAINHANDSLOT_ENCHANT or slotID == SECONDARYHANDSLOT_ENCHANT then
		local tmpSlot
		if slotID == INVSLOT_MAINHAND then
			tmpSlot = MAINHANDSLOT_ENCHANT
		elseif slotID == INVSLOT_OFFHAND then
			tmpSlot = SECONDARYHANDSLOT_ENCHANT
		else
			tmpSlot = slotID
		end
		if not tmpSlot then return end
		
		--set the default no enchant cancel image
		itemSlots[tmpSlot].icon:SetTexture("Interface\\Transmogrify\\Textures.png")
		itemSlots[tmpSlot].icon:SetTexCoord(0.28906250, 0.55468750, 0.51171875, 0.57812500);
		itemSlots[tmpSlot].slotName = WEAPON_ENCHANTMENT
		itemSlots[tmpSlot].itemLink = nil --do not do a link, instead show illusion name
		
		if illusionID then
			local visualID, name, transmogIllusionLink = C_TransmogCollection.GetIllusionSourceInfo(illusionID)
			if name and transmogIllusionLink then
				itemSlots[tmpSlot].icon:SetTexture(134941) --put the enchant scroll picture
				itemSlots[tmpSlot].icon:SetTexCoord(0,1,0,1) --you have to use this to reset the texture coords
				itemSlots[tmpSlot].slotName = string.format(TRANSMOGRIFIED_ENCHANT, name)
			end
		else
			--we don't have an illusion which means we probably used the dummy slots MAINHANDSLOT_ENCHANT and SECONDARYHANDSLOT_ENCHANT
			return
		end
	end
	--if the texture fails, then load our current character texture
	local slotTexture = select(2, GetInventorySlotInfo( transMogSlots[slotID].invSlotName ))
	itemSlots[slotID].icon:SetTexture(texture or slotTexture)
	itemSlots[slotID].itemLink = itemLink
	itemSlots[slotID].slotName = _G[transMogSlots[slotID].invSlotName] --grab it as a globalString
end

local function GetShortItemID(link)
	if link then
		if type(link) == "number" then link = tostring(link) end
		return link:match("item:(%d+):") or link:match("^(%d+):") or link	
	end
end

local function GetIllusionID(link)
	--transmogillusion and transmogappearance do not have a trailing colon after the itemID
	return link:match("transmogillusion:(%d+)") or nil
end

local function GetTransMogID(link)
	--transmogillusion and transmogappearance do not have a trailing colon after the itemID
	return link:match("transmogappearance:(%d+)") or nil
end

local function saveOutfit(saveName)
	if not XML_DB then showAlert(string.format(L.ErrorSave, 1)) end
	if not saveName then showAlert(string.format(L.ErrorSave, 1)) end
	
	local storeOutfit = {}
	
	local itemPool = addon.WardrobeFrame.itemPool
	
	for i=1, #itemPool do
		local itemID = GetShortItemID(itemPool[i].itemLink)
		local slotID = itemPool[i].slotID
		local transMogID = itemPool[i].transMogID
		local illusionID = itemPool[i].illusionID
	
		if itemID and slotID and transMogID then
			if illusionID then
				table.insert(storeOutfit, tostring(itemID)..";"..tostring(slotID)..";"..tostring(transMogID)..";"..tostring(illusionID))
			else
				table.insert(storeOutfit, tostring(itemID)..";"..tostring(slotID)..";"..tostring(transMogID))
			end
		else
			showAlert(string.format(L.ErrorSave, 2))
			break
		end
	end
	
	table.insert(XML_DB, {name=saveName, outfit=storeOutfit, class=addon.InspectedClass})
	showAlert("[|cff33ff99"..saveName.."|r]", L.YesSave)
end

StaticPopupDialogs["XANMOGWARDROBE_SAVEOUTFIT"] = {
	text = L.SaveOutfit ,
	button1 = "Save",
	button2 = "Cancel",
	hasEditBox = true,
	timeout = 0,
	hideOnEscape = 1,
	OnAccept = function (self, data, data2)
		local text = self.editBox:GetText()
		if text == "" or string.len(text) < 1 then
			showAlert(L.NoSave.."\n"..L.InvalidName)
		else
			saveOutfit(text)
		end
	end,
	whileDead = 1,
	maxLetters = 255,
}

function addon:SetupMogFrame()

	local addonFrame = AceGUI:Create("Window")
	addon.WardrobeFrame = addonFrame

	addonFrame:SetTitle(ADDON_NAME)
	addonFrame:SetWidth(450)
	addonFrame:SetHeight(570)
	
	addonFrame:EnableResize(false)
	addonFrame.frame:EnableMouseWheel(true)
	addonFrame.frame:SetClampedToScreen(true)
	addonFrame.frame:SetFrameStrata("DIALOG")
	
	addonFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	local function onEnter(self)
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
		if self.itemLink then
			if type(self.itemLink) == "number" then
				GameTooltip:SetItemByID(self.itemLink)
			else
				GameTooltip:SetHyperlink(self.itemLink)
			end
		else
			GameTooltip:SetText(self.slotName)
		end
	end
		
	addonFrame.itemSlots = {}
	
	--lets grab only the slots we can transmog and order them
	local buttonSlots = {}
	for i, mogSlot in ipairs(transMogSlots) do
		if mogSlot.canTransMog then
			table.insert(buttonSlots, mogSlot)
		end
	end
	table.sort(buttonSlots, function(a,b) return (a.buttonPos < b.buttonPos) end) --order by buttonPos

	for i, btnData in ipairs(buttonSlots) do
		local slot = CreateFrame("ItemButton", nil, addonFrame.frame)
		slot.info = btnData
		if i == 1 then
			slot:SetPoint("TOPLEFT", addonFrame.frame, "TOPLEFT", 20, -85)
		elseif i == 8 then
			slot:SetPoint("TOPRIGHT", addonFrame.frame, "TOPRIGHT", -20, -85)
		elseif i >= 12 then
			if i == 12 then
				slot:SetPoint("CENTER", addonFrame.frame, "CENTER", -15, -232)
			else
				slot:SetPoint("RIGHT", addonFrame.itemSlots[ buttonSlots[i-1].slotID ], "RIGHT", 45, 0)
			end
		else
			slot:SetPoint("TOP", addonFrame.itemSlots[ buttonSlots[i-1].slotID ], "BOTTOM", 0, -8)
		end
		slot:RegisterForClicks("AnyUp")
		slot:SetScript("OnEnter", onEnter)
		slot:SetScript("OnLeave", GameTooltip_Hide)
		slot.OnEnter = onEnter
		addonFrame.itemSlots[btnData.slotID] = slot
		itemSlotIcon(btnData.slotID)
	end
	
	for i = MAINHANDSLOT_ENCHANT, SECONDARYHANDSLOT_ENCHANT do
		local slot = CreateFrame("ItemButton", "test"..MAINHANDSLOT_ENCHANT, addonFrame.frame)
		slot:SetHeight(20)
		slot:SetWidth(20)
		--slot:SetNormalTexture(nil) --get rid of that tooltip border
		if i == MAINHANDSLOT_ENCHANT then
			slot:SetPoint("CENTER", addonFrame.itemSlots[16], "CENTER", 0, -33) --mainhand
		else
			slot:SetPoint("CENTER", addonFrame.itemSlots[17], "CENTER", 0, -33) --mainhand
		end
		slot:RegisterForClicks("AnyUp")
		slot:SetScript("OnEnter", onEnter)
		slot:SetScript("OnLeave", GameTooltip_Hide)
		slot.OnEnter = onEnter
		addonFrame.itemSlots[i] = slot
		itemSlotIcon(i)
	end

	local model = CreateFrame("DressUpModel", nil, addonFrame.frame)
	model:SetPoint("CENTER")
	model:SetSize(300,400)
	model:SetUnit("player")
	model:Undress() --this is VERY important.  That way you don't have to load the armor twice for it to show
	--model:SetModelScale(1)
	model:SetPosition(0,0,0)
	model.defaultPosX, model.defaultPosY, model.defaultPosZ, model.yaw = 0, 0, 0, 0
	--model:SetLight(true, false, -1, 0, 0, .7, .7, .7, .7, .6, 1, 1, 1)
	addonFrame.model = model

	--set the pan and zoom limits
	--https://github.com/Gethe/wow-ui-source/blob/f836c162afa2ccb5e42ef4a6c386a438608f4dd3/AddOns/Blizzard_Collections/Blizzard_Wardrobe.lua
	local _, race = UnitRace("player")
	local sex = UnitSex("player")
	model.panAndZoomModelType = race..sex
	
	model:SetScript("OnUpdate",function(self, elapsed) 
		if ( self.rotating ) then
			local x = GetCursorPosition()
			local diff = (x - self.rotateStartCursorX) * MODELFRAME_DRAG_ROTATION_CONSTANT
			self.rotateStartCursorX = GetCursorPosition()
			self.yaw = self.yaw + diff
			if ( self.yaw < 0 ) then
				self.yaw = self.yaw + (2 * PI)
			end
			if ( self.yaw > (2 * PI) ) then
				self.yaw = self.yaw - (2 * PI)
			end
			self:SetRotation(self.yaw, false)
		elseif ( self.panning ) then
			local cursorX, cursorY = GetCursorPosition()
			local modelX = self:GetPosition()
			local panSpeedModifier = 100 * sqrt(1 + modelX - self.defaultPosX)
			local modelY = self.panStartModelY + (cursorX - self.panStartCursorX) / panSpeedModifier
			local modelZ = self.panStartModelZ + (cursorY - self.panStartCursorY) / panSpeedModifier
			local limits = SET_MODEL_PAN_AND_ZOOM_LIMITS[self.panAndZoomModelType]
			if not limits then limits = SET_MODEL_PAN_AND_ZOOM_LIMITS["Human2"] end  --failsafe if addon gets outdated and new races are put in
			
			modelY = Clamp(modelY, limits.panMaxLeft, limits.panMaxRight)
			modelZ = Clamp(modelZ, limits.panMaxBottom, limits.panMaxTop)
			self:SetPosition(modelX, modelY, modelZ)
		end
	end)
	model:SetScript("OnMouseDown",function(self, button) 
		if ( button == "LeftButton" ) then
			self.rotating = true
			self.rotateStartCursorX = GetCursorPosition()
		elseif ( button == "RightButton" ) then
			self.panning = true
			self.panStartCursorX, self.panStartCursorY = GetCursorPosition()
			local modelX, modelY, modelZ = self:GetPosition()
			self.panStartModelY = modelY
			self.panStartModelZ = modelZ
		end
	end)
	model:SetScript("OnMouseUp",function(self, button) 
		if ( button == "LeftButton" ) then
			self.rotating = false
		elseif ( button == "RightButton" ) then
			self.panning = false
		end
	end)
	model:SetScript("OnMouseWheel",function(self, delta) 
		local posX, posY, posZ = self:GetPosition()
		posX = posX + delta * 0.5
		local limits = SET_MODEL_PAN_AND_ZOOM_LIMITS[self.panAndZoomModelType]
		if not limits then limits = SET_MODEL_PAN_AND_ZOOM_LIMITS["Human2"] end  --failsafe if addon gets outdated and new races are put in
		posX = Clamp(posX, self.defaultPosX, limits.maxZoom)
		self:SetPosition(posX, posY, posZ)
	end)
	
	local modelbg = addonFrame.frame:CreateTexture(nil,"BACKGROUND");
	modelbg:SetAllPoints(model);
	modelbg:SetColorTexture(0.3, 0.3, 0.3, 0.2)

    local saveButton = CreateFrame("Button", nil, addonFrame.frame, "UIPanelButtonTemplate")
	saveButton.Text:SetFontObject("GameFontNormal")
	saveButton:SetWidth(80)
	saveButton:SetHeight(30)
    saveButton:SetText(L.Save)
    saveButton:SetPoint("BOTTOMLEFT", 10, 13)
    saveButton:SetScript("OnClick", function()
		StaticPopup_Show("XANMOGWARDROBE_SAVEOUTFIT")
    end)
	addonFrame.saveButton = saveButton
	
    local loadButton = CreateFrame("Button", nil, addonFrame.frame, "UIPanelButtonTemplate")
	loadButton.Text:SetFontObject("GameFontNormal")
	loadButton:SetWidth(80)
	loadButton:SetHeight(30)
    loadButton:SetText(L.Load)
    loadButton:SetPoint("BOTTOMRIGHT", -10, 13)
    loadButton:SetScript("OnClick", function()
		addon.LoaderFrame:Show()
    end)
	addonFrame.loadButton = loadButton
	
	local raceDDList = AceGUI:Create("Dropdown")
	addonFrame.raceDDList = raceDDList
	raceDDList:SetWidth(300)
	raceDDList:ClearAllPoints()
	raceDDList.frame:SetParent(addonFrame.frame)
	raceDDList:SetPoint("CENTER", addonFrame.frame, "TOP", 0, -50)
	
	local tmp = {}
	for k, v in pairs(RaceIDs) do
		tmp[k..";"..v..";0;2" ] = k.." - Male"  --UnitSex is 2 for male but 0 for player model SetCustomRace
		tmp[k..";"..v..";1;3"] = k.." - Female" --UnitSex is 3 for female but 1 for player model SetCustomRace
	end
	table.sort(tmp, function(a,b) return (a < b) end)
	raceDDList:SetList(tmp)
	
	raceDDList:SetCallback(
		"OnValueChanged",
		function (self, event, value, checked)
			addonFrame.selectedRace = value
			addon:UpdateModelRace()
		end)

	addonFrame.frame:HookScript("OnHide",function() 
		if InspectFrame and InspectFrame:IsShown() then
			--if you don't close it this way it still thinks it's open because it's a primary UI Frame from UIPanelWindows
			HideUIPanel(InspectFrame)
			addonFrame.selectedRace = nil --default to our characters race
		end
	end)
	
	addonFrame:Hide()
	
end


local function AddEntry(entry, isHeader)
	if not addon.LoaderFrame or not addon.LoaderFrame.scrollframe then return end
	
	local scrollFrame = addon.LoaderFrame.scrollframe
	
	local highlightColor = {1, 0, 0}
	local label = AceGUI:Create("XanMogWardrobeLabel")

	label.userdata.color = {1, 1, 1}

	label:SetHeaderHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	label:ToggleHeaderHighlight(false)

	if isHeader then
		label:SetText(entry.header)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("CENTER")
		label.userdata.isHeader = true
		label.userdata.text = entry.header
		--label.userdata.icon = entry.icon
		label.userdata.outfit = entry.outfit
		
		label:ToggleHeaderHighlight(true)
	else
		label:SetText(entry.name)
		label:SetFont(STANDARD_TEXT_FONT, 14, THICKOUTLINE)
		label:SetFullWidth(true)
		label.userdata.color = {64/255, 224/255, 208/255} --hex: 40e0d0
		label:SetColor(unpack(label.userdata.color))
		label:ApplyJustifyH("LEFT")
		--label:SetImage(entry.icon)
		--label:SetImageSize(18, 18)
		label.userdata.isHeader = false
		label.userdata.text = entry.name
		--label.userdata.icon = entry.icon
		label.userdata.outfit = entry.outfit
	end

	label:SetCallback(
		"OnEnter",
		function (widget, sometable)
			if not label.userdata.isHeader then
				label:SetColor(unpack(highlightColor))
			end
		end)
	label:SetCallback(
		"OnLeave",
		function (widget, sometable)
			label:SetColor(unpack(label.userdata.color))
		end)
	label:SetCallback(
		"OnClick",
		function (widget, sometable)
			addon:UpdateModel(label.userdata.outfit, true)
		end)

	scrollFrame:AddChild(label)
end

local function DisplayList()
	if not addon.LoaderFrame or not addon.LoaderFrame.scrollframe then return end
	
	local scrollFrame = addon.LoaderFrame.scrollframe
	
	scrollFrame:ReleaseChildren() --clear out the scrollframe
	
	local usrData = {}
	local tempList = {}

	for unitObj, objData in pairs(XML_DB) do
		if objData.class and objData.name and not tempList[objData.class..objData.name] then
			table.insert(usrData, { header=objData.class, name=objData.name, outfit=objData.outfit} )
			tempList[objData.class..objData.name] = true
		end
	end
	
	if table.getn(usrData) > 0 then
	
		--sort the list by header, name
		table.sort(usrData, function(a, b)
			if a.header  == b.header then
				return a.name < b.name;
			end
			return a.header < b.header;
		end)
	
		local lastHeader = ""
		for i=1, #usrData do
			if lastHeader ~= usrData[i].header then
				AddEntry(usrData[i], true) --add header
				AddEntry(usrData[i], false) --add entry
				lastHeader = usrData[i].header
			else
				AddEntry(usrData[i], false) --add entry
			end
		end
		scrollFrame.frame:Show()
	else
		scrollFrame.frame:Hide()
	end
	
end

function addon:UpdateModelRace()
	if not addon.WardrobeFrame.selectedRace then return end

	local modelName, modelNumID, modelSex, unitZoomSex = strsplit(';', self.WardrobeFrame.selectedRace)
	
	if modelName and modelNumID and modelSex and unitZoomSex then
		--change the model
		--addon.WardrobeFrame.model:SetUnit("none")
		--addon.WardrobeFrame.model:ClearModel()
		--addon.WardrobeFrame.model:SetDisplayInfo(968705)
		self.WardrobeFrame.model:SetCustomRace(tonumber(modelNumID), tonumber(modelSex))
		--addon.WardrobeFrame.model:Undress()
		--addon.WardrobeFrame.model:SetModel(917116)
		--addon.WardrobeFrame.model:RefreshUnit()
		--myModel:GetModelFileID();
		--addon.WardrobeFrame.model:Undress()
		--addon.WardrobeFrame.model:TryOn(19019)
		--addon.WardrobeFrame.model:RefreshCamera()
		--addon.WardrobeFrame.model:ClearModel()
		--addon.WardrobeFrame.model:SetUnit("player")
		--addon.WardrobeFrame.model:RefreshUnit()
	end
	
	if self.WardrobeFrame.itemPool then
		--display after 1 second, for some reason we have to force the TryOn twice.  I can't figure out why.  I think it has to do with ItemCache
		C_Timer.After(0.2, function() self:UpdateModel(self.WardrobeFrame.itemPool) end)
	end
	
	-- model:GetModelFileID() 

	-- ModelFileIDs = {
		-- female = {
			-- human = 1000764,
			-- orc = 949470,
			-- dwarf = 950080,
			-- nightelf = 921844,
			-- undead = 997378,
			-- tauren = 986648,
			-- gnome = 940356,
			-- troll = 1018060,
			-- goblin = 119369,
			-- bloodelf = 110258,
			-- draenei = 1022598,
		-- },
		
		-- male = {
			-- human = 1011653,
			-- orc = 917116,
			-- dwarf = 878772,
			-- nightelf = 974343,
			-- undead = 959310,
			-- tauren = 968705,
			-- gnome = 900914,
			-- troll = 1022938,
			-- goblin = 119376,
			-- bloodelf = 1100087,
			-- draenei = 1005887,
		-- }
	-- }

end

function addon:SetupLoaderFrame()

	local loaderFrame = AceGUI:Create("Window")

	addon.LoaderFrame = loaderFrame
	loaderFrame.frame:SetParent(addon.WardrobeFrame.frame)
	loaderFrame.frame:ClearAllPoints() --very important, otherwise mouse issues happen
	loaderFrame.frame:SetPoint("LEFT", addon.WardrobeFrame.frame, "RIGHT")
	
	loaderFrame.title:SetScript("OnMouseDown", nil)
	loaderFrame.title:SetScript("OnMouseUp", nil)
		
	loaderFrame:SetTitle(L.LoadSet)
	loaderFrame:SetHeight(500)
	loaderFrame:SetWidth(380)
	loaderFrame:EnableResize(false)
	loaderFrame.frame:EnableMouseWheel(true)
	loaderFrame.frame:SetClampedToScreen(true)
	loaderFrame.frame:SetFrameStrata("DIALOG")
	
	local scrollframe = AceGUI:Create("ScrollFrame");
	scrollframe:SetFullWidth(true)
	scrollframe:SetLayout("Flow")

	addon.LoaderFrame.scrollframe = scrollframe
	loaderFrame:AddChild(scrollframe)

	hooksecurefunc(loaderFrame, "Show" ,function()
		DisplayList()
	end)
	
	loaderFrame:Hide()
	
end

function addon:UpdateModel(itemPool, isLoaded, numTries)
	if not itemPool then return end
	
	addon.WardrobeFrame.model:Undress() --make sure they are undressed
	
	--loaded manually from display list
	if isLoaded then
		local tmpPool = {}
		local refresh = false
		
		for i=1, #itemPool do
			local itemID, slotID, transMogID, illusionID = strsplit(';', itemPool[i])
			--Debug(1, itemID, slotID, transMogID, illusionID)
			if itemID then
				local itemMatrix = getItemMatrix(itemID) or getItemMatrix(GetShortItemID(itemID))
				if itemMatrix then
					--Debug(2, itemMatrix.itemLink, slotID, transMogID, itemMatrix.icon, illusionID)
					table.insert(tmpPool, {itemLink=itemMatrix.itemLink, slotID=tonumber(slotID) or slotID, transMogID=tonumber(transMogID) or transMogID, icon=itemMatrix.icon, illusionID=tonumber(illusionID) or illusionID})
				else
					refresh = true
				end
			end
		end
		
		--some items weren't yet queried from server
		if refresh then
			if not numTries or numTries < 3 then
				C_Timer.After(0.2, function() addon:UpdateModel(itemPool, true, (numTries or 0) + 1) end)
			elseif numTries and numTries > 3 then
				showAlert(L.NoLoad)
			end
			return
		end
		
		--transfer it over
		itemPool = tmpPool
		
		--store it for use in other areas
		self.WardrobeFrame.itemPool = itemPool
	end
	
	--first lets clear them
	for i, mogSlot in ipairs(transMogSlots) do
		if mogSlot.canTransMog then
			itemSlotIcon(mogSlot.slotID)
		end
	end
	itemSlotIcon(MAINHANDSLOT_ENCHANT)
	itemSlotIcon(SECONDARYHANDSLOT_ENCHANT)

	--load the items
	for i=1, #itemPool do
		itemSlotIcon(itemPool[i].slotID, itemPool[i].icon, itemPool[i].itemLink, itemPool[i].illusionID)
		--the transMogID loads additional apperances like illusions for the artifacts, whereas giving just the regular itemlink doesn't
		--additional the secondary parameter allows you to load directly into a slot like, "MAINHANDSLOT" or "SECONDARYHANDSLOT"
		if itemPool[i].slotID and tonumber(itemPool[i].slotID) then
			if itemPool[i].transMogID then
				addon.WardrobeFrame.model:TryOn(itemPool[i].transMogID, transMogSlots[itemPool[i].slotID].invSlotName, itemPool[i].illusionID)
			elseif itemPool[i].itemLink then
				addon.WardrobeFrame.model:TryOn(itemPool[i].itemLink, transMogSlots[itemPool[i].slotID].invSlotName, itemPool[i].illusionID)
			end
		end
		--Debug("TryOn", UnitName("target"), itemPool[i].transMogID, transMogSlots[itemPool[i].slotID].invSlotName, itemPool[i].slotID, itemPool[i].itemLink, itemPool[i].icon)
	end
	
end

local function doBackupItemGrab(itemPool, slotID, transMogID, illusionID)
	if transMogID and transMogID ~= NO_TRANSMOG_SOURCE_ID then
		local link = GetInventoryItemLink("target", slotID)
		if link then
			local itemMatrix = getItemMatrix(link) or getItemMatrix(GetShortItemID(link))
			if itemMatrix then
				table.insert(itemPool, {itemLink=itemMatrix.itemLink, slotID=slotID, transMogID=transMogID, icon=itemMatrix.icon, illusionID=illusionID})
			end
		end
	end
end

--https://github.com/Gethe/wow-ui-source/blob/356d028f9d245f6e75dc8a806deb3c38aa0aa77f/FrameXML/DressUpFrames.lua
function addon:LoadInspectedCharacter()
	local itemPool = {}
	
	--C_TransmogCollection.GetItemInfo
	
	
	--DressUpItemTransmogInfoList(C_TransmogCollection.GetInspectItemTransmogInfoList());
	
	-- for slotID, itemTransmogInfo in ipairs(itemTransmogInfoList) do
		-- local ignoreChildItems = slotID ~= INVSLOT_MAINHAND;
		-- playerActor:SetItemTransmogInfo(itemTransmogInfo, slotID, ignoreChildItems);
	-- end
	
	local inspectSlots, mainHandEnchant, offHandEnchant = C_TransmogCollection.GetInspectSources()
	if not inspectSlots then return end

	local mainHandSlotID = GetInventorySlotInfo("MAINHANDSLOT")
	local secondaryHandSlotID = GetInventorySlotInfo("SECONDARYHANDSLOT")
	
	for i, sourceIndex in pairs(inspectSlots) do
		if sourceIndex ~= NO_TRANSMOG_SOURCE_ID and i ~= mainHandSlotID and i ~= secondaryHandSlotID then
			local categoryID, visualID, canEnchant, icon, _, itemLink, transmogLink = C_TransmogCollection.GetAppearanceSourceInfo(sourceIndex)
			if itemLink then
				--Debug(categoryID, visualID, icon, sourceIndex, GetShortItemID(sourceIndex), itemLink, GetShortItemID(itemLink))
				--categoryID is also slotID
				table.insert(itemPool, {itemLink=itemLink, slotID=i, transMogID=sourceIndex, icon=icon})
			else
				doBackupItemGrab(itemPool, i, sourceIndex)
			end
		end
	end

	--local link = GetInventoryItemLink("target", slotId)
	
    --TRANSMOGRIFIED = "Transmogrified to:\n%s";
    --TRANSMOGRIFIED_ENCHANT = "Illusion: %s";
    --TRANSMOGRIFIED_HEADER = "Transmogrified to:";

	--https://wow.gamepedia.com/WeaponEnchantID
	--we don't want to store a ILLUSION enchant if it's zero
	if mainHandEnchant == 0 then mainHandEnchant = nil end
	if offHandEnchant == 0 then offHandEnchant = nil end
	
	if mainHandSlotID and inspectSlots[mainHandSlotID] then
		local _, _, _, mainHandIcon, _, mainHandLink = C_TransmogCollection.GetAppearanceSourceInfo(inspectSlots[mainHandSlotID])
		if mainHandLink then
			table.insert(itemPool, {itemLink=mainHandLink, slotID=mainHandSlotID, transMogID=inspectSlots[mainHandSlotID], icon=mainHandIcon, illusionID=mainHandEnchant})
		else
			doBackupItemGrab(itemPool, mainHandSlotID, inspectSlots[mainHandSlotID], mainHandEnchant)
		end
	end
	
	if secondaryHandSlotID and inspectSlots[secondaryHandSlotID] then
		local _, _, _, secondaryHandIcon, _, secondaryHandLink = C_TransmogCollection.GetAppearanceSourceInfo(inspectSlots[secondaryHandSlotID])
		if secondaryHandLink then
			table.insert(itemPool, {itemLink=secondaryHandLink, slotID=secondaryHandSlotID, transMogID=inspectSlots[secondaryHandSlotID], icon=secondaryHandIcon, illusionID=offHandEnchant})
		else
			doBackupItemGrab(itemPool, secondaryHandSlotID, inspectSlots[secondaryHandSlotID], offHandEnchant)
		end
	end

	--store it for use in other areas
	addon.WardrobeFrame.itemPool = itemPool
	
	--display after 1 second, for some reason we have to force the TryOn twice.  I can't figure out why.  I think it has to do with ItemCache
	C_Timer.After(0.2, function() addon:UpdateModel(itemPool) end)
	
	addon.WardrobeFrame:Show()
end

function addon:AddInspectButton()
	if addon.inspectButton then return end
	if not InspectFrame then return end
	addon.inspectButton = true
	
	local button = CreateFrame("Button", ADDON_NAME.."_InspectButton", InspectFrame, "UIPanelButtonTemplate")
	button:SetText("Load Player")
	button:SetHeight(30)
	button:SetWidth(button:GetTextWidth() + 30)
	button:SetPoint("TOPRIGHT", 110, 0)
	button:SetScript("OnClick", function()
		addon:LoadInspectedCharacter()
		addon.InspectedClass = select(2, UnitClass("target")) or "Unknown"
	end)
end

function addon:INSPECT_READY()
	if not addon.inspectButton then
		if IsAddOnLoaded("Blizzard_InspectUI") or InspectFrame then
			addon:AddInspectButton()
			addon:UnregisterEvent("INSPECT_READY")
		end
	end
end

function addon:EnableAddon()
	XML_DB = XML_DB or {}
	
	if not addon.inspectButton then
		if IsAddOnLoaded("Blizzard_InspectUI") or InspectFrame then
			addon:AddInspectButton()
			return
		end
		addon:RegisterEvent("INSPECT_READY")
	end
	
	addon:SetupMogFrame()
	addon:SetupLoaderFrame()
	
	SLASH_XANMOGWARDROBE1 = "/xmw";
	SlashCmdList["XANMOGWARDROBE"] = function()
		addon.WardrobeFrame:Show()
	end
	
	local ver = C_AddOns.GetAddOnMetadata(ADDON_NAME,"Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFF20ff20%s|r] loaded:   /xmw", ADDON_NAME, ver or "1.0"))
end
