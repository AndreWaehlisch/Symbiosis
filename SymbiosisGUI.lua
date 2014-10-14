--only startup if player is druid
if Symbiosis.stop then
	return;
end;

local print = Symbiosis.print;
local L = Symbiosis.L;
local Media = LibStub("LibSharedMedia-3.0");
local GetSpecialization = function() return GetSpecialization() or 1 end;

--class names (localized)
local ClassTable = {};
FillLocalizedClassList( ClassTable, (UnitSex("player") == 3) );

-----------------------------------------
--Whisper stuff
-----------------------------------------
local function GetGrantSpell(TargetClass,TargetUnit,TargetSpec)
	if TargetSpec then
		return Symbiosis.SpellsGranted[TargetClass][TargetSpec];
	else
		for i=1,100 do
			if not UnitBuff(TargetUnit,i) then
				return false;
			end;
			
			Symbiosis_Tooltip:ClearLines();
			Symbiosis_Tooltip:SetUnitBuff(TargetUnit,i);
			
			if ( Symbiosis_TooltipTextLeft1:GetText() == Symbiosis.SymbiosisSpell ) and Symbiosis_TooltipTextLeft2:GetText() then
				for _, SpellId in pairs(Symbiosis.SpellsGranted[TargetClass]) do
					if (select(2,gsub(Symbiosis_TooltipTextLeft2:GetText(),(GetSpellInfo(SpellId)),1))) > 0 then
						return SpellId;
					end;
				end;
			end;
		end;
	end;
end;

function Symbiosis.GetWhisperMessage(DruidSpec, TargetClass, TargetUnit, SimplifyMsg, TargetSpec)
	local mymsg = format(Symbiosis.LocalsTable[SymbConfig["WhispLang"]]["YouHaveSymbiosis"],GetSpellLink(Symbiosis.SymbiosisSpellID));
	local ReturnList = {};
	ReturnList[1] = mymsg;

	if not SimplifyMsg then
		if SymbConfig["WhisperAddGet"] then
			local getLink = GetSpellLink(Symbiosis.SpellsGot[DruidSpec][TargetClass]);
			if getLink then
				mymsg = mymsg .. " " .. format(Symbiosis.LocalsTable[SymbConfig["WhispLang"]]["YouGrantedMe"],getLink);--[MUST NOT BE LONGER THAN 255 CHARS]
				ReturnList[1] = mymsg;
			end;
		end;
		
		if SymbConfig["WhisperAddGrant"] then
			local GrantSpell = "[?]";
			
			if TargetUnit then
				local CheckGrantSpell = GetGrantSpell(TargetClass,TargetUnit,TargetSpec);

				if CheckGrantSpell then
					GrantSpell = GetSpellLink(CheckGrantSpell);
				else--we could not retrieve spell from cache AND not from the tooltip name. this may occur for some localizations (ursocs might vs. might of ursoc on German client).
					local GrantSpell1 = GetGrantSpell(TargetClass,TargetUnit,1);
					local GrantSpell2 = GetGrantSpell(TargetClass,TargetUnit,2);
					local GrantSpell3 = GetGrantSpell(TargetClass,TargetUnit,3);
					
					GrantSpell = GetSpellLink(GrantSpell1);
					
					if not(GrantSpell1 == GrantSpell2) then
						GrantSpell = GrantSpell .. "/" .. GetSpellLink(GrantSpell2);
					end;
					
					if (not(GrantSpell1 == GrantSpell3)) and (not(GrantSpell2 == GrantSpell3)) then
						GrantSpell = GrantSpell .. "/" .. GetSpellLink(GrantSpell3);
					end;
				end;
			else
				--for GUI test string
				GrantSpell = GetSpellLink(Symbiosis.SpellsGranted["PALADIN"][1]);
			end;
			
			--add link list to msg
			ReturnList[2] = format(Symbiosis.LocalsTable[SymbConfig["WhispLang"]]["YoullGet"],GrantSpell);--[MUST NOT BE LONGER THAN 255 CHARS]
		end;
	end;

	return ReturnList;
end;

-----------------------------------------
--create functions
-----------------------------------------

--create Checkbutton (Checkbox)
local function CreateCheckButton(x_loc,y_loc,displaytext,thetooltip,panel)
	local MyCheckbutton = CreateFrame("CheckButton",nil,panel,"ChatConfigCheckButtonTemplate");
	MyCheckbutton:SetPoint("TOPLEFT",x_loc,y_loc);

	MyCheckbutton.text = MyCheckbutton:CreateFontString(nil,"ARTWORK","GameFontNormal");
	MyCheckbutton.text:SetPoint("LEFT",MyCheckbutton,"RIGHT");
	MyCheckbutton.text:SetText(displaytext);

	MyCheckbutton:SetHitRectInsets(0,-(MyCheckbutton.text:GetWidth()),0,0);--resize mouse-over area which highlights

	local header = "";

	if thetooltip ~= "" then
		header = displaytext..": ";
	end;

	if (header ~= "") and (thetooltip ~= "") then
		MyCheckbutton.tooltip = header..thetooltip;
	end;

	return MyCheckbutton;
end;

function Symbiosis.SetTriState(self)
	if ( self.state == 1 ) then--enable (1)
		self:SetCheckedTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready");
		self:SetChecked(true);
	elseif ( self.state == 0 ) then--disable (0)
		self:SetCheckedTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady");
		self:SetChecked(true);
	else--ignore (false)
		self:SetChecked(false);
	end
end;

--click function for TriState-checkbuttons
local function TriStateCheckButtonFunc(self,additionalFunc)
	if ( not self.state ) then--ignore->enable
		self.state = 1;
	elseif ( self.state == 0 ) then--disable->ignore
		self.state = false;
	else--enable->disable
		self.state = 0;
	end;

	Symbiosis.SetTriState(self);

	SymbConfig["TriState_" .. self.Type] = self.state;

	if additionalFunc then
		additionalFunc();
	end;
end;

--create TriState-Checkbutton
local function CreateTriStateCheckButton(x_loc,y_loc,Type,panel,additionalFunc)
	local MyCheckbutton = CreateFrame("CheckButton",nil,panel,"ChatConfigCheckButtonTemplate");

	MyCheckbutton.Type = Type;

	MyCheckbutton:SetPoint("TOPLEFT",x_loc,y_loc);

	MyCheckbutton.text = MyCheckbutton:CreateFontString(nil,"ARTWORK","GameFontNormalSmall");
	MyCheckbutton.text:SetPoint("LEFT",MyCheckbutton,"RIGHT");
	MyCheckbutton.text:SetText(L[Type]);

	MyCheckbutton:SetHitRectInsets(0,-(MyCheckbutton.text:GetWidth()),0,0);--resize mouse-over area which highlights

	local optName = "|cffFFFFFF" .. L[Type] .. "|r";

	MyCheckbutton:SetScript("OnEnter",function()
		GameTooltip:SetOwner(MyCheckbutton,"ANCHOR_BOTTOMRIGHT",2,2);
		
		GameTooltip:SetText(L["TriStateTooltip"],1,1,0,1,1);

		GameTooltip:AddLine(" ");
		GameTooltip:AddLine("|cff00FF00" .. L["Enabled"] .. "|r: " .. format(L["WillShow"],optName),1,1,0);
		GameTooltip:AddLine("|cffFF0000" .. L["Disabled"] .. "|r: " .. format(L["WillHide"],optName),1,1,0);
		GameTooltip:AddLine("|cff25E6CC" .. L["IgnoredUnchecked"] .. "|r: " .. format(L["WillIgnore"],optName),1,1,0,1);
		
		GameTooltip:Show();
	end);

	MyCheckbutton:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);

	MyCheckbutton.state = false;

	MyCheckbutton:SetScript("OnClick",function()
		TriStateCheckButtonFunc(MyCheckbutton,additionalFunc);
		Symbiosis.CheckToShowHideButtonFunc();
	end);

	return MyCheckbutton;
end;

--create Button
local function CreateButton(Width,Height,x_loc,y_loc,MyText,panel)
	local MyButton = CreateFrame("BUTTON",nil,panel,"UIPanelButtonTemplate");
	MyButton:SetWidth(Width);
	MyButton:SetHeight(Height);
	MyButton:SetText(MyText);
	MyButton:SetPoint("TOPLEFT",x_loc,y_loc);
	MyButton:Show();
	return MyButton;
end;

--create fontstring (label) [frames in popup: without x and y]
function Symbiosis.CreateLabel(parent,text,width,x,y)
	local ofx,ofy;
	
	if x and y then
		ofx = x;
		ofy = y;
	else
		ofx =10;
		width = width - ofx;
		ofy = 0;
	end;
	
	local MyFontString = parent:CreateFontString(nil,"ARTWORK","GameFontNormal");
	MyFontString:SetWidth(width);
	MyFontString:SetHeight(50);
	MyFontString:SetText(text);
	MyFontString:SetPoint("TOPLEFT",parent,"TOPLEFT",ofx,ofy);
	MyFontString:SetJustifyH("LEFT");
	MyFontString:Show();

	return MyFontString;
end;

--create Slider
function Symbiosis.CreateSlider(x_loc,y_loc,MyText,minval,maxval,step,startval,panel,DoMouseWheelScript)
	local MySlider = CreateFrame("Slider",nil,panel);
	
	--copy default setup from OptionsSliderTemplate in OptionsPanelTemplates.xml
	MySlider:SetSize(144,17);
	MySlider:SetHitRectInsets(0,0,-10,-10);
	MySlider:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true,
		tileSize = 8,
		edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 },
	});
	MySlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal");
	MySlider:SetOrientation("HORIZONTAL");
	
	MySlider:ClearAllPoints();
	MySlider:SetPoint("TOPLEFT",x_loc,y_loc);
	MySlider:SetMinMaxValues(minval,maxval);
	MySlider:SetValue(startval);
	MySlider:SetValueStep(step);
	
	MySlider.low = MySlider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");
	MySlider.low:SetPoint("TOPLEFT",MySlider,"BOTTOMLEFT",2,3);
	MySlider.low:SetText(minval);
	
	MySlider.high = MySlider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");
	MySlider.high:SetPoint("TOPRIGHT",MySlider,"BOTTOMRIGHT",-2,3);
	MySlider.high:SetText(maxval);
	
	MySlider.text = MySlider:CreateFontString(nil,"OVERLAY","GameFontNormal");
	MySlider.text:SetPoint("BOTTOMLEFT",MySlider,"TOPLEFT");
	MySlider.text:SetPoint("BOTTOMRIGHT",MySlider,"TOPRIGHT");
	MySlider.text:SetJustifyH("CENTER");
	MySlider.text:SetHeight(15);
	MySlider.text:SetText(MyText);
	
	MySlider:SetObeyStepOnDrag(true);
	
	MySlider:Show();
	
	if DoMouseWheelScript then
		MySlider:SetScript("OnMouseWheel",function(self,direction)
			self:SetValue(self:GetValue() - (direction*step));
		end);
	end;
	
	return MySlider;
end;

--create horizontal line
local function CreateHLine(y_loc,panel)
	local MyTexture = panel:CreateTexture();
	MyTexture:SetTexture("Interface\\MailFrame\\UI-MailFrame-InvoiceLine");
	MyTexture:SetPoint("TOPLEFT",10,y_loc);
	MyTexture:SetHeight(60);
	MyTexture:SetWidth(550);
	MyTexture:SetVertexColor(1,1,0.5);
	
	return MyTexture;
end;

--add tooltip to button (permanent)
local function AddTooltip(MyFrameWhoWantsTooltip,text,notCaptionAsTitle,titleText)
	MyFrameWhoWantsTooltip:SetScript("OnEnter",function()
		GameTooltip:SetOwner(MyFrameWhoWantsTooltip,"ANCHOR_CURSOR",2,2);
		
		if not notCaptionAsTitle then
			GameTooltip:SetText(MyFrameWhoWantsTooltip:GetText());
		elseif (titleText) and ( type(titleText) == "string" ) then
			GameTooltip:SetText(titleText);
		end;

		local LineCount = 0;
		local mytext;
		
		if type(text) == "string" then
			mytext = {text,"XYZ_NOTHING_XYZ"};
			LineCount = -1;
		else
			mytext = text;
		end;

		for _ in pairs(mytext) do
			LineCount = LineCount + 1;
		end;
		
		for i=1,LineCount do
			GameTooltip:AddLine(mytext[i],1,1,1,1);
		end;

		GameTooltip:Show();
	end);

	MyFrameWhoWantsTooltip:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);
end;

--add a changing tooltip, use GameTooltip:SetText() and GameTooltip:AddLine() [deprecated]
-- local function AddTooltipFunc(MyFrameWhoWantsTooltip,TextFunction)
	-- MyFrameWhoWantsTooltip:SetScript("OnEnter",function()
		-- GameTooltip:SetOwner(MyFrameWhoWantsTooltip,"ANCHOR_CURSOR",2,2);

		-- TextFunction();

		-- GameTooltip:Show();
	-- end);

	-- MyFrameWhoWantsTooltip:SetScript("OnLeave",function()
		-- GameTooltip:Hide();
	-- end);
-- end;

--add a hintbutton to panel
local function CreateHintButton(panel,text,header)
	local myHintButton = CreateFrame("Frame",nil,panel);
	myHintButton:SetHeight(30);
	myHintButton:SetWidth(30);
	myHintButton:SetPoint("BOTTOMLEFT",10,10);
	myHintButton.icon = myHintButton:CreateTexture();
	myHintButton.icon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark");
	myHintButton.icon:SetAllPoints(myHintButton);
	AddTooltip(myHintButton,text,true,header .. ":");

	return myHintButton;
end;

--Adds a spell info line to the GUI/info panel
local ClassColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
local function CreateSpellInfoLine(yoffset,parent,ClassName,SpellId,IsMainLine)
	--------------------------
	--1: Class/spec Icon
	--------------------------
	local ClassCoords = CLASS_ICON_TCOORDS[ClassName];
	local ClassFrame = CreateFrame("Frame",nil,parent);
	ClassFrame:SetSize(25,25);
	ClassFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",30,-65+yoffset);	
	ClassFrame.icon = ClassFrame:CreateTexture();
	ClassFrame.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
	ClassFrame.icon:SetTexCoord(unpack(ClassCoords));
	ClassFrame.icon:SetAllPoints(ClassFrame);

	--------------------------
	--2: Class Name (Text)
	--------------------------
	local MyLabel = Symbiosis.CreateLabel(parent,ClassTable[ClassName]..":",120,65,-50+yoffset);
	MyLabel:SetTextColor(ClassColors[ClassName]["r"],ClassColors[ClassName]["g"],ClassColors[ClassName]["b"]);
	
	
	if (not IsMainLine) then
		local returnTable = {};
	--------------------------
	--3: Spell Icon
	--------------------------
		local SpellName,_,SpellIcon = GetSpellInfo(SpellId);

		local SpellFrame = CreateFrame("Frame",nil,parent);
		SpellFrame:SetSize(25,25);
		SpellFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",175,-65+yoffset);	
		SpellFrame.icon = SpellFrame:CreateTexture();
		SpellFrame.icon:SetTexture(SpellIcon);
		SpellFrame.icon:SetAllPoints(SpellFrame);
		
		returnTable.spellIcon = SpellFrame.icon;
		
		SpellFrame:SetScript("OnEnter",function()
			GameTooltip:SetOwner(SpellFrame,"ANCHOR_CURSOR",2,2);
			GameTooltip:SetHyperlink("spell:"..SpellId);
			GameTooltip:Show();
		end);

		SpellFrame:SetScript("OnLeave",function()
			GameTooltip:Hide();
		end);

		SpellFrame:SetScript("OnMouseDown",function()
			if IsShiftKeyDown() then
				ChatEdit_InsertLink(GetSpellLink(SpellId));
			end;
		end);

	--------------------------
	--4: Spell Name
	--------------------------
		returnTable.spellLabel = Symbiosis.CreateLabel(parent,SpellName,140,205,-50+yoffset)
		
		return returnTable;
	end;
end;

local function CreateSpecSubLine(yoffset,parent,SpecIcon,SpecName,SpellId)
	--------------------------
	--1: Spec Icon
	--------------------------
	local SpecFrame = CreateFrame("Frame",nil,parent);
	SpecFrame:SetSize(25,25);
	SpecFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",60,-65+yoffset);	
	SpecFrame.icon = SpecFrame:CreateTexture();
	SpecFrame.icon:SetTexture("Interface\\Icons\\"..SpecIcon);
	SpecFrame.icon:SetAllPoints(SpecFrame);

	--------------------------
	--2: Spec Name (Text)
	--------------------------
	Symbiosis.CreateLabel(parent,SpecName..":",100,100,-50+yoffset)

	--------------------------
	--3: Spell Icon
	--------------------------
	local SpellName,_,SpellIcon = GetSpellInfo(SpellId);

	local SpellFrame = CreateFrame("Frame",nil,parent);
	SpellFrame:SetSize(25,25);
	SpellFrame:SetPoint("TOPLEFT",parent,"TOPLEFT",200,-65+yoffset);	
	SpellFrame.icon = SpellFrame:CreateTexture();
	SpellFrame.icon:SetTexture(SpellIcon);
	SpellFrame.icon:SetAllPoints(SpellFrame);

	SpellFrame:SetScript("OnEnter",function()
		GameTooltip:SetOwner(SpellFrame,"ANCHOR_CURSOR",2,2);
		GameTooltip:SetHyperlink("spell:"..SpellId);
		GameTooltip:Show();
	end);

	SpellFrame:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);

	SpellFrame:SetScript("OnMouseDown",function()
		if IsShiftKeyDown() then
			ChatEdit_InsertLink(GetSpellLink(SpellId));
		end;
	end);

	--------------------------
	--4: Spell Name
	--------------------------
	Symbiosis.CreateLabel(parent,SpellName,140,240,-50+yoffset)
end;

--used for both spell info panels (adds an icon to be displayed on top of a button)
local function CreateButtonIcon(button, xOffset, class, druidSpecIndex)
	local icon = button:CreateTexture();
	icon:SetPoint("LEFT",12+xOffset,-1);
	icon:SetSize(15,15);
	if class then
		icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
		icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]));
	else
		icon:SetTexture((select(4,GetSpecializationInfo(druidSpecIndex))));
		
		local star = button:CreateTexture();
		star:SetPoint("RIGHT",-(12+xOffset),-1);
		star:SetSize(15,15);
		star:SetTexture("Interface\\Common\\ReputationStar");
		star:SetTexCoord(0, 0.5, 0, 0.5);
		star:Hide();
		button.star = star;
	end;
end;

-----------------------------------------
--Go and Create GUI
-----------------------------------------

function Symbiosis.CreateGUI()
	-----------------------------------------
	-- Locals
	-----------------------------------------
	local StartHeight = 0;
	local currentpanel;
	local PanelStringColor = "|cffFF7D0A";

	-----------------------------------------
	--Main Panel
	-----------------------------------------
	Symbiosis.MainPanel = CreateFrame("Frame",nil,UIParent);
	currentpanel = Symbiosis.MainPanel;
	currentpanel.name = "Symbiosis";

	local MainPanelString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" ..GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["Options"],400,50,StartHeight);

	MainPanelString:ClearAllPoints();
	MainPanelString:SetPoint("TOP",currentpanel,"TOP");

	--------------
	--Sizer Frame
	--------------
	--sizer frame (container)
	local SizerFrame = CreateFrame("Frame",nil,UIParent);
	SizerFrame:SetWidth(250);
	SizerFrame:SetHeight(120);
	SizerFrame:SetPoint("CENTER");
	SizerFrame:Hide();

	--enable dragging
	SizerFrame:EnableMouse(true);
	SizerFrame:SetMovable(true);
	SizerFrame:RegisterForDrag("LeftButton");
	SizerFrame:SetScript("OnDragStop",function()
		SizerFrame:StopMovingOrSizing();
	end);
	SizerFrame:SetScript("OnDragStart",function()
		if SizerFrame:IsMovable() then
			SizerFrame:StartMoving();
		end;
	end);

	--artwork
	SizerFrame.bg = SizerFrame:CreateTexture();
	SizerFrame.bg:SetTexture(0,0,0,0.5);
	SizerFrame.bg:SetAllPoints(SizerFrame);
	SizerFrame:SetBackdrop({
		edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
		edgeSize = 3}
	);

	--PANEL FOR SYMBIOSIS BUTTON SIZING
	local symbiosisButtonSizerFrame = CreateFrame("Frame",nil,SizerFrame);
	symbiosisButtonSizerFrame:SetAllPoints(SizerFrame);
	
	--title line
	Symbiosis.CreateLabel(symbiosisButtonSizerFrame,L["ChangeSizeButton"],250,10,10);

	--slider on symbiosisButtonSizerFrame
	local SizerSlider = Symbiosis.CreateSlider(0,0,L["Size"] .. ": ?",5,300,5,100,symbiosisButtonSizerFrame,true);
	SizerSlider:ClearAllPoints();
	SizerSlider:SetPoint("CENTER",0,0);
	
	SizerSlider:SetScript("OnValueChanged",function(self)
		SymbButton["Size"] = self:GetValue();
		
		SymbiosisButton:SetWidth((SymbButton["Size"]/100)*Symbiosis.ButtonSize);
		SymbiosisButton:SetHeight(SymbiosisButton:GetWidth());
		
		self.text:SetText(L["Size"] .. ": " .. SymbButton["Size"].."%");
		
		Symbiosis.ResizeHotkeyString();
		
		--MASQUE support
		--redraw skin of masque when we change size of button
		if Symbiosis.MSQGroup then
			Symbiosis.MSQGroup:ReSkin();
		end;
	end);
	Symbiosis.SizerSlider = SizerSlider;

	--PANEL FOR POPUP SIZING
	local popupSizerFrame = CreateFrame("Frame",nil,SizerFrame);
	popupSizerFrame:SetAllPoints(SizerFrame);
	
	--title line1
	Symbiosis.CreateLabel(popupSizerFrame,L["ChangeSizePopup"],250,10,10);
	
	--slider1 on popupSizerFrame
	local popupSizerSlider = Symbiosis.CreateSlider(0,0,L["Size"] .. ": ?",24,130,2,100,popupSizerFrame,true);
	popupSizerSlider:ClearAllPoints();
	popupSizerSlider:SetPoint("TOP",0,10-60);
	
	popupSizerSlider:SetScript("OnValueChanged",function(self)
		SymbConfig["PopUp_Size"] = self:GetValue();
		
		for i = 1, Symbiosis.maxmemberbuttons do
			local button = _G["SymbiosisButton_MemberButton_"..i];
			button:SetHeight((SymbConfig["PopUp_Size"]/100)*Symbiosis.PopUpButtonHeight);
			
			--hide tags (dead/offline) when popup too small
			if SymbConfig["PopUp_Size"] < 90 then
				_G["SymbiosisButton_TagFrame_"..i]:Hide();
			else
				_G["SymbiosisButton_TagFrame_"..i]:Show();
			end;
			
			--resize buffed icon tag when popup too small
			local curText = button.fontstring:GetText();
			if strmatch(curText,"|T"..Symbiosis.SymbiosisIcon..":%d+|t ") then
				if SymbConfig["PopUp_Size"] <= 50 then
					button.fontstring:SetText(gsub(curText,":%d+|t",":"..SymbiosisButton_PopUpFrame.buffedIconTagFunc().."|t"));
				else
					button.fontstring:SetText(gsub(curText,":%d+|t",":20|t"));
				end;
			end;
		end;

		SymbiosisButton_PopUpFrame:SetHeight((SymbConfig["PopUp_Size"]/100)*Symbiosis.PopUpButtonHeight*SymbiosisButton_PopUpFrame.count);
		
		Symbiosis.popupIconSizerSlider:GetScript("OnValueChanged")(Symbiosis.popupIconSizerSlider);
		
		self.text:SetText(L["Size"] .. ": " .. SymbConfig["PopUp_Size"].."%");
	end);
	Symbiosis.popupSizerSlider = popupSizerSlider;
	
	--title line2
	Symbiosis.CreateLabel(popupSizerFrame,L["ChangeSizePopupIcons"],250,10,10-60-20);
	
	--slider2 on popupSizerFrame (for icons)
	local popupIconSizerSlider = Symbiosis.CreateSlider(0,0,L["Size"] .. ": ?",0,100,2,100,popupSizerFrame,true);
	popupIconSizerSlider:ClearAllPoints();
	popupIconSizerSlider:SetPoint("TOP",0,10-60-20-60);
	
	popupIconSizerSlider:SetScript("OnValueChanged",function(self)
		SymbConfig["PopUp_IconSize"] = self:GetValue();
		
		local size = (SymbConfig["PopUp_Size"]/100)*Symbiosis.PopUpButtonHeight*0.8*(SymbConfig["PopUp_IconSize"]/100);
		
		for i = 1, Symbiosis.maxmemberbuttons do
			local icon = _G["SymbiosisButton_Icon_"..i];
			local grantIcon = _G["SymbiosisButton_GrantIcon_"..i];
			
			icon:SetSize(size,size);
			grantIcon:SetSize(size,size);
			
			if size >= 20 then
				icon:SetPoint("RIGHT",grantIcon,"LEFT",-5,0);
			else
				icon:SetPoint("RIGHT",grantIcon,"LEFT",-2,0);
			end;
			
			if size == 0 then
				icon:Hide();
				grantIcon:Hide();
			else
				icon:Show();
				grantIcon:Show();
			end;
		end;
		
		self.text:SetText(L["Size"] .. ": " .. SymbConfig["PopUp_IconSize"].."%");
	end);
	Symbiosis.popupIconSizerSlider = popupIconSizerSlider;
	
	--"test" button
	local SizerTestButton = CreateButton(70,25,0,0,L["Test"],popupSizerFrame);
	SizerTestButton:ClearAllPoints();
	SizerTestButton:SetPoint("BOTTOMLEFT",10,10);
	SizerTestButton:SetScript("OnClick",function()
		Symbiosis.debugMemberlist = not Symbiosis.debugMemberlist;
		Symbiosis.Refreshbutton:GetScript("OnMouseDown")();
	end);
	
	--"close" button
	local SizerCloseButton = CreateButton(70,25,0,0,L["Done"],SizerFrame);
	SizerCloseButton:ClearAllPoints();
	SizerCloseButton:SetPoint("BOTTOMRIGHT",-10,10);
	SizerCloseButton:SetScript("OnClick",function()
		Symbiosis.debugMemberlist = false;
		SizerFrame:Hide();
		Symbiosis.Refreshbutton.sizer:Hide();
		Symbiosis.MyOpenToCategory(Symbiosis.MainPanel);
	end);

	--change height of SizerFrame, depending what we want to scale (popupSizer has two sliders, so needs more space)
	SizerFrame:SetScript("OnShow",function()
		if symbiosisButtonSizerFrame:IsVisible() then
			SizerFrame:SetHeight(120);
		elseif popupSizerFrame:IsVisible() then
			SizerFrame:SetHeight(200);
		end;
	end);
	
	-------------------------------------
	--SymbButton Sizer/Drag/Reset Buttons
	-------------------------------------
	
	--"Symbiosis Button" label
	Symbiosis.CreateLabel(currentpanel,"Symbiosis Button",200,30,StartHeight-50);
	
	--"change size" button
	local ChangeSizeButton = CreateButton(strlenutf8(L["ChangeSize"])*10,30,45,StartHeight-60-30,L["ChangeSize"],currentpanel);

	ChangeSizeButton:SetScript("OnClick",function()
		if not SymbiosisButton:IsVisible() then
			print(L["IsNowVisible"] );
			SymbiosisButton:Show();
		end;
		popupSizerFrame:Hide();
		symbiosisButtonSizerFrame:Show();
		SizerFrame:Show();
		InterfaceOptionsFrame:Hide();
	end);
	
	--Drag "Symbiosis Button" button
	local DragButton = CreateButton(strlenutf8(L["Unlock"])*10,30,45+ChangeSizeButton:GetWidth()+20,StartHeight-60-30,L["Unlock"],currentpanel);
	Symbiosis.DragButton = DragButton;

	AddTooltip(DragButton,L["LockUnlockButton"]);

	DragButton:SetScript("OnClick",function()
		if (DragButton:GetText() == L["Unlock"]) then
			if not SymbiosisButton:IsVisible() then
				print(L["IsNowVisible"]);
				SymbiosisButton:Show();
			end;
			SymbiosisButton:SetScript("OnDragStart",function()
				if SymbiosisButton:IsMovable() then
					SymbiosisButton:StartMoving();
				end;
			end);
			DragButton:SetText(L["Lock"]);
			SymbiosisButton.StopDragButton:Show();
			SymbConfig["DragEnabled"] = true;
			print(L["Unlocked"] .. Symbiosis.DoCommand("lock"));
		else
			SymbiosisButton.StopDragButton:Hide();
			SymbConfig["DragEnabled"] = false;
			print(L["FrameLocked"]);
			SymbiosisButton:SetScript("OnDragStart",nil);
			DragButton:SetText(L["Unlock"]);
		end;
	end);

	--reset postion button
	local ResetButton = CreateButton(strlenutf8(L["ResetPosition_Short"])*10,30,45+ChangeSizeButton:GetWidth()+20+DragButton:GetWidth()+20,StartHeight-60-30,L["ResetPosition_Short"],currentpanel);

	AddTooltip(ResetButton,L["ResetPositionTooltip"]);

	ResetButton:SetScript("OnClick",function()
		if not SymbiosisButton:IsVisible() then
			print(L["IsNowVisible"]);
			SymbiosisButton:Show();
		end;
		SymbiosisButton:ClearAllPoints();
		SymbiosisButton:SetPoint("CENTER",UIParent,"CENTER");
	end);

	CreateHLine(StartHeight-60-30-30,currentpanel);

	--------------------------------
	--PopUp Sizer/Drag/Reset Buttons
	--------------------------------
	
	StartHeight = -110;
	
	--"Symbiosis Popup" label
	Symbiosis.CreateLabel(currentpanel,"Symbiosis Popup",200,30,StartHeight-50);
	
	--'change size' button
	local ChangePopupSizeButton = CreateButton(strlenutf8(L["Options"].."...")*10,30,45,StartHeight-60-30,L["ChangeSize"],currentpanel);
	
	ChangePopupSizeButton:SetScript("OnClick",function()
		if not SymbiosisButton:IsVisible() then
			print(L["IsNowVisible"] );
			SymbiosisButton:Show();
		end;
		
		if not SymbiosisButton_PopUpFrame:IsVisible() then
			Symbiosis.ShowPopUp();
		end;
		
		popupSizerFrame:Show();
		symbiosisButtonSizerFrame:Hide();
		SizerFrame:Show();
		Symbiosis.Refreshbutton.sizer:Show();
		InterfaceOptionsFrame:Hide();
	end);
	
	--Drag "Symbiosis Button" button
	local DragButton2 = CreateButton(strlenutf8(L["Unlock"])*10,30,45+ChangePopupSizeButton:GetWidth()+20,StartHeight-60-30,L["Unlock"],currentpanel);
	Symbiosis.DragButton2 = DragButton2;

	AddTooltip(DragButton2,L["LockUnlockPopUp"]);
	
	function Symbiosis.StopDragFunc2()
		SymbiosisButton_PopUpFrame:EnableMouse(false);
		
		SymbiosisButton.StopDragButton2:Hide();
		
		SymbiosisButton_PopUpFrame:SetScript("OnDragStart",nil);
		Symbiosis.Refreshbutton:SetScript("OnDragStart",nil);
		
		DragButton2:SetText(L["Unlock"]);
		print(L["FrameLocked"]);
	end;
	
	DragButton2:SetScript("OnClick",function()
		if (DragButton2:GetText() == L["Unlock"]) then
			SymbiosisButton_PopUpFrame:EnableMouse(true);
			Symbiosis.Refreshbutton:EnableMouse(true);
			if not SymbiosisButton:IsVisible() then
				print(L["IsNowVisible"]);
				SymbiosisButton:Show();
			end;
			
			if SymbiosisButton_PopUpFrame:IsVisible() then
				SymbiosisButton_PopUpFrame:Hide();
			end;
			Symbiosis.ShowPopUp();
			
			SymbiosisButton_PopUpFrame:SetScript("OnDragStart",function()
				if SymbiosisButton_PopUpFrame:IsMovable() then
					SymbiosisButton_PopUpFrame:StartMoving();
				end;
			end);
			
			Symbiosis.Refreshbutton:SetScript("OnDragStart",function()
				if Symbiosis.Refreshbutton:IsMovable() then
					Symbiosis.Refreshbutton:StartMoving();
				end;
			end);
			
			DragButton2:SetText(L["Lock"]);
			SymbiosisButton.StopDragButton2:Show();
			print(L["Unlocked"] .. Symbiosis.DoCommand("lock popup"));
		else
			Symbiosis.StopDragFunc2();
		end;
	end);

	--reset postion button
	local ResetButton2 = CreateButton(strlenutf8(L["ResetPosition_Short"])*10,30,45+ChangePopupSizeButton:GetWidth()+20+DragButton2:GetWidth()+20,StartHeight-60-30,L["ResetPosition_Short"],currentpanel);
	
	ResetButton2:SetScript("OnClick",function()
		SymbConfig["Pop_GetPoint_pos1"] = nil;
		SymbConfig["Refresh_GetPoint_pos1"] = nil;
		if SymbiosisButton_PopUpFrame:IsVisible() then
			SymbiosisButton_PopUpFrame:Hide();
			Symbiosis.ShowPopUp();
		end;
	end);
	
	CreateHLine(StartHeight-60-30-30,currentpanel);
	
	--adjust positions and widths of both button rows
	do
		local function Adjust(Frame1,Frame2)
			if Frame1:GetWidth() > Frame2:GetWidth() then
				Frame2:SetWidth(Frame1:GetWidth());
			else
				Frame1:SetWidth(Frame2:GetWidth());
			end;
			
			local _, _, _, x1, y1 = Frame1:GetPoint(1);
			local _, _, _, x2, y2 = Frame2:GetPoint(1);
			
			if x1 > x2 then
				Frame2:SetPoint("TOPLEFT",x1,y2);
			else
				Frame1:SetPoint("TOPLEFT",x2,y1);
			end;
		end;
		
		Adjust(ChangeSizeButton,ChangePopupSizeButton);
		Adjust(DragButton,DragButton2);
		Adjust(ResetButton,ResetButton2);
	end;
	
	---------------------------
	--TARGET and BUTTON CONFIG
	---------------------------
	
	StartHeight = -140;
	
	--TARGET CONFIG
	Symbiosis.CreateLabel(currentpanel,L["TargetConfig"],200,30,StartHeight-60-30-30-30);

	Symbiosis.TargetConfigDontRemove =		CreateCheckButton(30+15,StartHeight-60-30-30-30-50,L["DontRemoveTarget"],L["DontRemoveTargetTooltip"],currentpanel);
	Symbiosis.TargetConfigDontRemove:SetChecked(false);
	Symbiosis.TargetConfigDontRemove:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["TargetConfigDontRemove"] = true;
			Symbiosis.TargetConfigNotice:Disable();
		else
			SymbConfig["TargetConfigDontRemove"] = false;
			Symbiosis.TargetConfigNotice:Enable();
		end;
	end);

	Symbiosis.TargetConfigNotice =			CreateCheckButton(30+15,StartHeight-60-30-30-30-50-25,L["PrintMessageWhenTarLeaves"],"",currentpanel);
	Symbiosis.TargetConfigNotice:SetChecked(true);
	Symbiosis.TargetConfigNotice:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["TargetConfigNotice"] = true;
		else
			SymbConfig["TargetConfigNotice"] = false;
		end;
	end);

	Symbiosis.DisableBuffRemove =			CreateCheckButton(30+15,StartHeight-60-30-30-30-50-50,L["DisableShiftClick"],L["DisableShiftClickTooltip"],currentpanel);
	Symbiosis.DisableBuffRemove:SetChecked(false);
	Symbiosis.DisableBuffRemove:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DisableBuffRemove"] = true;
			SymbiosisButton:SetAttribute("shift-type1","");
		else
			SymbConfig["DisableBuffRemove"] = false;
			SymbiosisButton:SetAttribute("shift-type1","cancelaura");
		end;
	end);

	Symbiosis.WarnOnReadyCheck =			CreateCheckButton(30+15,StartHeight-60-30-30-30-50-75,L["WarnOnRdyCheck"],L["WarnOnRdyCheckTooltip"],currentpanel);
	Symbiosis.WarnOnReadyCheck:SetChecked(true);
	Symbiosis.WarnOnReadyCheck:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["WarnOnReadyCheck"] = true;
			Symbiosis.BuffReminderFrame:RegisterEvent("READY_CHECK");
		else
			SymbConfig["WarnOnReadyCheck"] = false;
			Symbiosis.BuffReminderFrame:UnregisterAllEvents();
		end;
	end);

	Symbiosis.ShortenNames =			CreateCheckButton(30+15,StartHeight-60-30-30-30-50-100,L["DontDisplayRealms"],"",currentpanel);
	Symbiosis.ShortenNames:SetChecked(true);
	Symbiosis.ShortenNames:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["ShortenNames"] = true;
		else
			SymbConfig["ShortenNames"] = false;
		end;
		Symbiosis.TargetString.Refresh();
	end);

	--SYMBIOSIS BUTTON
	Symbiosis.CreateLabel(currentpanel,L["ButtonConfig"],200,380,StartHeight-60-30-30-30);

	Symbiosis.RemoveNoTargetTag = 			CreateCheckButton(380+15,StartHeight-60-30-30-30-50,L["RemoveNoTargetTag"],L["RemoveNoTargetTagTooltip"],currentpanel);
	Symbiosis.RemoveNoTargetTag:SetChecked(false);
	Symbiosis.RemoveNoTargetTag:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["RemoveNoTargetTag"] = true;
			if Symbiosis.TargetString:GetText() == L["NoTarget"] then
				Symbiosis.TargetString:Hide();
			end;
		else
			SymbConfig["RemoveNoTargetTag"] = false;
			if Symbiosis.TargetString:GetText() == L["NoTarget"] then
				Symbiosis.TargetString:Show();
			end;
		end;
	end);

	Symbiosis.ShowGCD =						CreateCheckButton(380+15,StartHeight-60-30-30-30-50-25,L["ShowGCD"],L["ShowGCDTooltip"],currentpanel);
	Symbiosis.ShowGCD:SetChecked(true);
	Symbiosis.ShowGCD:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["ShowGCD"] = true;
		else
			SymbConfig["ShowGCD"]= false;
		end;
	end);

	Symbiosis.ShowHeader =						CreateCheckButton(380+15,StartHeight-60-30-30-30-50-50,L["ShowHeader"],L["ShowHeaderTooltip"],currentpanel);
	Symbiosis.ShowHeader:SetChecked(true);
	Symbiosis.ShowHeader:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["ShowHeader"] = true;
			SymbiosisButton.PopUpHeader:Show();
		else
			SymbConfig["ShowHeader"]= false;
			SymbiosisButton.PopUpHeader:Hide();
		end;
	end);

	Symbiosis.DisableMainTooltip =				CreateCheckButton(380+15,StartHeight-60-30-30-30-50-75,L["DisableMainTooltip"],"",currentpanel);
	Symbiosis.DisableMainTooltip:SetChecked(false);
	Symbiosis.DisableMainTooltip:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DisableMainTooltip"] = true;
		else
			SymbConfig["DisableMainTooltip"]= false;
		end;
	end);

	Symbiosis.EnableLopsidedWorkaround =				CreateCheckButton(380+15,StartHeight-60-30-30-30-50-100,L["EnableWorkaround"],L["EnableWorkaroundTooltip"],currentpanel);
	Symbiosis.EnableLopsidedWorkaround.text:SetWidth(150);
	Symbiosis.EnableLopsidedWorkaround:SetHitRectInsets(0,-(Symbiosis.EnableLopsidedWorkaround.text:GetWidth()),0,0);--resize mouse-over area which highlights
	Symbiosis.EnableLopsidedWorkaround:SetChecked(true);
	Symbiosis.EnableLopsidedWorkaround:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then--TODO: add handling when changing option (?)
			SymbConfig["EnableLopsidedWorkaround"] = true;
		else
			SymbConfig["EnableLopsidedWorkaround"]= false;
		end;
	end);
	
	Symbiosis.DisableRangeIndicator =			CreateCheckButton(380+15,StartHeight-60-30-30-30-50-125,L["DisableRangeIndication"],L["DisableRangeIndicationTooltip"],currentpanel);
	Symbiosis.DisableRangeIndicator:SetChecked(false);
	Symbiosis.DisableRangeIndicator:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DisableRangeIndicator"] = true;
			Symbiosis.ForceNormalColors:Disable();
		else
			SymbConfig["DisableRangeIndicator"]= false;
			Symbiosis.ForceNormalColors:Enable();
		end;
	end);

	Symbiosis.ForceNormalColors =				CreateCheckButton(380+15,StartHeight-60-30-30-30-50-150,L["ForceNormalColors"],L["ForceNormalColorsTooltip"],currentpanel);
	Symbiosis.ForceNormalColors:SetChecked(false);
	Symbiosis.ForceNormalColors:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["ForceNormalColors"] = true;
		else
			SymbConfig["ForceNormalColors"]= false;
		end;
	end);
	
	currentpanel:Hide();--OnShow does only fire when frame is actually hidden
	InterfaceOptions_AddCategory(currentpanel);

	StartHeight = 0;
	
	-----------------------------------------
	--Whisper Panel
	-----------------------------------------	
	currentpanel = CreateFrame("Frame",nil,UIParent);
	currentpanel.name = L["Whisper"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	local WhisperPanelString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["WhisperOptions"],400,20,StartHeight);

	WhisperPanelString:ClearAllPoints();
	WhisperPanelString:SetPoint("TOP",currentpanel,"TOP");

	Symbiosis.WhisperEnable = CreateCheckButton(20,StartHeight-50,L["EnableTargetWhisper"],"",currentpanel);
	Symbiosis.WhisperEnable:SetChecked(false);

	Symbiosis.TestMessageLabel = Symbiosis.CreateLabel(currentpanel,L["TestMessage"],400,20,StartHeight-80);
	Symbiosis.WhisperPanelTestWhisperString = Symbiosis.CreateLabel(currentpanel,"",400,20,StartHeight-120);

	Symbiosis.WhisperPanelAddGrant = CreateCheckButton(20,StartHeight-180,L["AddSpellsGranted"],"",currentpanel);
	Symbiosis.WhisperPanelAddGrant:SetChecked(false);
	Symbiosis.WhisperPanelAddGrant:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["WhisperAddGrant"] = true;
		else
			SymbConfig["WhisperAddGrant"] = false;
		end;
		
		local WhisperList = Symbiosis.GetWhisperMessage(1,"PALADIN");
		local WhisperText = WhisperList[1];
		if WhisperList[2] then
			WhisperText = WhisperText .. "\n" .. WhisperList[2];
		end;
		Symbiosis.WhisperPanelTestWhisperString:SetText(WhisperText);
	end);

	Symbiosis.WhisperPanelAddGet = CreateCheckButton(20,StartHeight-180-25,L["AddSpellsGet"],"",currentpanel);
	Symbiosis.WhisperPanelAddGet:SetChecked(false);
	Symbiosis.WhisperPanelAddGet:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["WhisperAddGet"] = true;
		else
			SymbConfig["WhisperAddGet"] = false;
		end;
		
		local WhisperList = Symbiosis.GetWhisperMessage(1,"PALADIN");
		local WhisperText = WhisperList[1];
		if WhisperList[2] then
			WhisperText = WhisperText .. "\n" .. WhisperList[2];
		end;
		Symbiosis.WhisperPanelTestWhisperString:SetText(WhisperText);
	end);

	Symbiosis.FullWhispOnlyOnFirst = CreateCheckButton(20,StartHeight-180-50,L["FullWhispOnlyOnFirst"],L["FullWhispOnlyOnFirstTooltip"],currentpanel);
	Symbiosis.FullWhispOnlyOnFirst:SetChecked(false);
	Symbiosis.FullWhispOnlyOnFirst:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["FullWhispOnlyOnFirst"] = true;
		else
			SymbConfig["FullWhispOnlyOnFirst"] = false;
		end;
	end);

	Symbiosis.DisableWhispArena = CreateCheckButton(20,StartHeight-180-75,L["DisableWhispArena"],"",currentpanel);
	Symbiosis.DisableWhispArena:SetChecked(false);
	Symbiosis.DisableWhispArena:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DisableWhispArena"] = true;
		else
			SymbConfig["DisableWhispArena"] = false;
		end;
	end);

	local WhispLabel = Symbiosis.CreateLabel(currentpanel,L["WhisperLanguage"] .. ":",200,20,StartHeight-300);

	local WhispLangEdit = CreateFrame("EditBox","Symbiosis_WhispLangEdit",currentpanel,"InputBoxTemplate");

	WhispLangEdit:SetWidth(140);
	WhispLangEdit:SetHeight(20);
	WhispLangEdit:SetPoint("LEFT",WhispLabel,"LEFT",0,-30);
	WhispLangEdit:SetAutoFocus(nil);
	WhispLangEdit:Show();
	WhispLangEdit:Disable();

	local LangSelectDrop = CreateFrame("Frame",nil,currentpanel);
	LangSelectDrop.displayMode = "MENU";
	local info = {};
	LangSelectDrop.initialize = function(self,level)
		if not level then
			return;
		end;
		wipe(info);
		if level == 1 then
			--title of the menu
			info.isTitle = 1;
			info.text = L["SelectLanguage"];
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info,1);

			-- locals
			info.disabled = nil;
			info.isTitle = nil;

			for key in pairs(Symbiosis.LocalsTable) do
				info.text = _G[key];
				info.func = function()
					WhispLangEdit:SetText(_G[key]);
					WhispLangEdit:SetCursorPosition(0);
					
					SymbConfig["WhispLang"] = key;
					
					local WhisperList = Symbiosis.GetWhisperMessage(1,"PALADIN");
					local WhisperText = WhisperList[1];
					if WhisperList[2] then
						WhisperText = WhisperText .. "\n" .. WhisperList[2];
					end;
					Symbiosis.WhisperPanelTestWhisperString:SetText(WhisperText);
				end;
				UIDropDownMenu_AddButton(info,1);
			end;

			-- close button
			info.text = L["Close"];
			info.func = function() end;
			UIDropDownMenu_AddButton(info,1);
		end;
	end;

	local LangSelectButton = CreateButton(30,20,100+30,StartHeight-300-30,"!",currentpanel);
	LangSelectButton:ClearAllPoints();
	LangSelectButton:SetPoint("LEFT",WhispLangEdit,"RIGHT",10,0);

	LangSelectButton:SetScript("OnClick",function(self)
		ToggleDropDownMenu(1,nil,LangSelectDrop,self,-20,0);
	end);

	--OnClick Event for "Enable Whisper" checkbox
	Symbiosis.WhisperEnable:SetScript("OnClick",function(self)
		if ( self and (self:GetChecked() == 1) ) then--check for self: on login we call this func with nil (when whisper disabled)
			SymbConfig["WhisperEnable"] = true;
			Symbiosis.WhisperPanelTestWhisperString:Show();
			Symbiosis.TestMessageLabel:Show();
			Symbiosis.WhisperPanelAddGrant:Show();
			Symbiosis.WhisperPanelAddGet:Show();
			Symbiosis.FullWhispOnlyOnFirst:Show();
			Symbiosis.DisableWhispArena:Show();
			LangSelectButton:Show();
			LangSelectDrop:Show();
			WhispLangEdit:Show();
			WhispLabel:Show();
			Symbiosis.StartSpellCastFrame:RegisterEvent("UNIT_SPELLCAST_START");
		else
			SymbConfig["WhisperEnable"] = false;
			Symbiosis.WhisperPanelTestWhisperString:Hide();
			Symbiosis.TestMessageLabel:Hide();
			Symbiosis.WhisperPanelAddGrant:Hide();
			Symbiosis.WhisperPanelAddGet:Hide();
			Symbiosis.FullWhispOnlyOnFirst:Hide();
			Symbiosis.DisableWhispArena:Hide();
			LangSelectButton:Hide();
			LangSelectDrop:Hide();
			WhispLangEdit:Hide();
			WhispLabel:Hide();
			Symbiosis.StartSpellCastFrame:UnregisterAllEvents();
		end;
	end);

	CreateHintButton(currentpanel,L["LongWhisperHint"],L["Whisper"]);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);

	-----------------------------------------
	--Show/Hide Panel
	-----------------------------------------

	currentpanel = CreateFrame("Frame",nil,UIParent);
	currentpanel.name = L["ShowHide"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	local ShowHidePanelString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["ShowHideOptions"],400,20,StartHeight);

	ShowHidePanelString:ClearAllPoints();
	ShowHidePanelString:SetPoint("TOP",currentpanel,"TOP",0,-5);

	local yoffsetinc = 0;
	local xoffsetinc = 0;

	Symbiosis.UITriStateCheckboxes = {};

	--add "outside" manually (because of ipairs)
	Symbiosis.UITriStateCheckboxes[0] = CreateTriStateCheckButton(20+xoffsetinc,StartHeight-100+yoffsetinc,Symbiosis.TypesForTriStateButtons[1][0],currentpanel);
	yoffsetinc = yoffsetinc - 30;
	
	for _, TypeTable in ipairs(Symbiosis.TypesForTriStateButtons) do
		for _, Type in ipairs(TypeTable) do
			if not (Type == "nil") then
				Symbiosis.UITriStateCheckboxes[Type] = CreateTriStateCheckButton(20+xoffsetinc,StartHeight-100+yoffsetinc,Type,currentpanel);
				yoffsetinc = yoffsetinc - 30;
			end;
		end;
		xoffsetinc = xoffsetinc + 200;
		yoffsetinc = 0;
	end;

	Symbiosis.IgnoreShowHide = CreateCheckButton(580-(strlenutf8(L["IgnoreShowHide"])*10),-500,L["IgnoreShowHide"],L["IgnoreShowHideTooltip"],currentpanel);

	Symbiosis.IgnoreShowHide:SetScript("OnClick",function(self)
		if not (self:GetChecked() == 1) then
			 Symbiosis.CheckToShowHideButtonFunc();
		end;
	end);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);

	-----------------------------------------
	--Macro Panel
	-----------------------------------------

	currentpanel = CreateFrame("Frame",nil,UIParent);
	currentpanel.name = L["MacroOptions_Short"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	local MacroPanelString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["MacroOptions"],400,20,StartHeight);

	MacroPanelString:ClearAllPoints();
	MacroPanelString:SetPoint("TOP",currentpanel,"TOP");

	Symbiosis.MacroPanelContainer = CreateFrame("Frame",nil,currentpanel);
	local Container = Symbiosis.MacroPanelContainer;
	Container:SetHeight(500);
	Container:SetWidth(500);
	Container:SetPoint("CENTER");

	Symbiosis.MacroInput = CreateFrame("EditBox",nil,Container);
	local InputBox = Symbiosis.MacroInput;
	InputBox:SetWidth(300);
	InputBox:SetHeight(20);
	InputBox:SetPoint("CENTER");
	InputBox:SetAutoFocus(nil);
	InputBox:SetMultiLine(true);
	InputBox:SetFontObject("GameFontHighlight");
	InputBox:SetBackdrop({	bgFile = "Interface/Tooltips/UI-Tooltip-Background"	});
	InputBox:SetBackdropColor(.2,.2,.2);
	InputBox:SetMaxLetters(255);
	InputBox:Show();

	InputBox:SetScript("OnEscapePressed",function()
		InputBox:ClearFocus();
	end);

	InputBox:SetScript("OnEditFocusLost",function()
		--remove selection when user leaves edit
		InputBox:HighlightText(0,0);

		Symbiosis.EditTheMacro();
	end);

	local InputBoxBorder = CreateFrame("Frame",nil,InputBox);
	InputBoxBorder:SetPoint("CENTER");
	InputBoxBorder:SetPoint("TOP",0,20);
	InputBoxBorder:SetPoint("BOTTOM",0,-20);
	InputBoxBorder:SetWidth(340);
	InputBoxBorder:SetBackdrop({	edgeFile = "Interface/DialogFrame/UI-DialogBox-Gold-Border",	});

	local Counter = Symbiosis.CreateLabel(InputBoxBorder,"0/255",60,0,30);
	Counter:ClearAllPoints();
	Counter:SetPoint("TOPRIGHT",InputBoxBorder,"BOTTOMRIGHT");

	InputBox:SetScript("OnTextChanged",function()
		--show current length of macro string
		Counter:SetText(strlenutf8(InputBox:GetText()) .. "/255");
		
		--only allow 34 lines maximum (so layout does not break)
		local lines = ( select(2,gsub(InputBox:GetText(),"\n","-")) );
		if lines > 34 then
			local posi = 0;
			for i=1,34 do
				posi = strfind(InputBox:GetText(),"\n",posi+1);
			end;
			InputBox:SetText(strsub(InputBox:GetText(),0,posi));
		end;
		
		--save macro (only if not empty)
		if not ( InputBox:GetText() == "" ) then
			SymbConfig["MacroCode"] = InputBox:GetText();
		end;
	end);

	local ResetButton = CreateButton(70,15,0,0,L["Reset"],InputBox);
	ResetButton:ClearAllPoints();
	ResetButton:SetPoint("TOPLEFT",InputBox,"BOTTOMLEFT",0,-20);
	AddTooltip(ResetButton,L["ResetMacro"],true,L["Reset"] .. ":");

	ResetButton:SetScript("OnClick",function()
		print(L["ConfirmResetMacro"] .. Symbiosis.DoCommand("resetmacro"));
	end);
	
	Symbiosis.DisableMacro = CreateCheckButton(420,StartHeight-520,L["DisableMacro"],L["DisableMacroHint"],currentpanel);
	Symbiosis.DisableMacro:SetChecked(false);
	Symbiosis.DisableMacro:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DisableMacro"] = true;
			Container:Hide();
		else
			SymbConfig["DisableMacro"] = false;
			Container:Show();
		end;
	end);
	
	CreateHintButton(currentpanel,{L["LongMacroHint1"],L["LongMacroHint2"],L["LongMacroHint3"],"\n",L["LongMacroHint4"] .. " |cff08C7D1SYMB|r",L["LongMacroHint5"] .. " |cff08C7D1/cast [@SYMB] Symbiosis|r","\n",L["LongMacroHint6"] .. " |cff08C7D1/script Symbiosis.Click()|r",L["LongMacroHint7"]},L["Macro"]);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);

	-----------------------------------------
	--Spell Info Panel
	-----------------------------------------
	local SpellInfoButtonsStartYPos = -40;

	currentpanel = CreateFrame("Frame",nil,UIParent);
	currentpanel.name = L["SpellsGet"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	local SpellInfoString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["SpellsGet"],400,20,StartHeight);

	SpellInfoString:ClearAllPoints();
	SpellInfoString:SetPoint("TOP",currentpanel,"TOP");

	--create two labels aboth the checkboxes
	local ignoreLabel  = Symbiosis.CreateLabel(currentpanel,L["Ignore"],150,394,-30+SpellInfoButtonsStartYPos);
	ignoreLabel:SetJustifyH("LEFT");
	
	local onTopLabel  = Symbiosis.CreateLabel(currentpanel,L["OnTop"],150,0,0);
	onTopLabel:ClearAllPoints();
	onTopLabel:SetPoint("RIGHT",ignoreLabel,"LEFT",-9,0);
	onTopLabel:SetJustifyH("RIGHT");
	
	local infoPanelVSpacer = CreateHLine(0,currentpanel);
	infoPanelVSpacer:SetWidth(50);
	infoPanelVSpacer:SetHeight(570);
	infoPanelVSpacer:SetRotation(rad(90));
	infoPanelVSpacer:SetPoint("TOPLEFT",365,10);
	
	-----------
	--setup stuff for what druid GETS
	
	local Containers = {};
	
	Symbiosis["SpellInfoCfg"] = {};
	Symbiosis["SpellInfoCfg"]["Prioritize"] = {};
	Symbiosis["SpellInfoCfg"]["Ignore"] = {};
	
	for i, SpecName in ipairs(Symbiosis.DruidSpecNames) do
		local CurrentYOffSet = SpellInfoButtonsStartYPos;
		Containers[i] = CreateFrame("Frame",nil,currentpanel);
		Containers[i]:SetAllPoints(currentpanel);
		Containers[i]:Hide();
		
		Symbiosis["SpellInfoCfg"]["Prioritize"][SpecName] = {};
		Symbiosis["SpellInfoCfg"]["Ignore"][SpecName] = {};
		Symbiosis["SpellInfoCfg"][SpecName] = {};
		
		for TargetClass, SpellId in pairs(Symbiosis.SpellsGot[i]) do
			Symbiosis["SpellInfoCfg"][SpecName][TargetClass] = CreateSpellInfoLine(CurrentYOffSet,Containers[i],TargetClass,SpellId);

			local PrioritizeCheckbox = CreateCheckButton(140+205+18,-65+CurrentYOffSet,"","",Containers[i]);
			PrioritizeCheckbox:SetScript("OnClick",function(self)
				SymbConfig["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass] = (self:GetChecked() == 1);
				
				if self:GetChecked() == 1 then
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(0,1,0);
				else
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(GameFontNormal:GetTextColor());
				end;
			end);
			Symbiosis["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass] = PrioritizeCheckbox;
			
			local IgnoreCheckbox = CreateCheckButton(140+205+18+32,-65+CurrentYOffSet,"","",Containers[i]);
			IgnoreCheckbox:SetScript("OnClick",function(self)
				SymbConfig["SpellInfoCfg"]["Ignore"][SpecName][TargetClass] = (self:GetChecked() == 1);
				
				if self:GetChecked() == 1 then
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellIcon:SetDesaturated(1);
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(.5,.5,.5);
					PrioritizeCheckbox:Hide();
				else
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellIcon:SetDesaturated(nil);
					Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(GameFontNormal:GetTextColor());
					PrioritizeCheckbox:Show();
				end;
			end);
			Symbiosis["SpellInfoCfg"]["Ignore"][SpecName][TargetClass] = IgnoreCheckbox;
			
			CurrentYOffSet = CurrentYOffSet - 35;
		end;
	end;
	
	--Show requested spell info tables, hide others
	local function ShowHideSpellButtons(currentDruidSpec)	
		for i, SpecName in ipairs(Symbiosis.DruidSpecNames) do
			if currentDruidSpec == SpecName then
				Containers[i]:Show();
			else
				Containers[i]:Hide();
			end;
		end;
	end;
	
	--create 4 buttons to show different spell buttons
	local SpecButtons = {
		[0] =	{ 	GetPoint = function() return "",nil,"",20,0 end;
					GetWidth = function() return 0 end;
				};
	};

	--create and setup onclick events of the 4 buttons
	for i, SpecName in ipairs(Symbiosis.DruidSpecNames) do
		local xOffSet = (select(4,SpecButtons[i-1]:GetPoint(1))) + SpecButtons[i-1]:GetWidth() + 10;
		
		SpecButtons[i] = CreateButton(10,30,xOffSet,-40,L[SpecName],currentpanel);
		
		SpecButtons[i]:SetWidth(SpecButtons[i]:GetFontString():GetStringWidth()+52);
		
		SpecButtons[i]:SetScript("OnClick",function()
			ShowHideSpellButtons(SpecName);
			for k in ipairs(SpecButtons) do
				if (k == i) then
					SpecButtons[k]:Disable();
				else
					SpecButtons[k]:Enable();
				end;
			end;
		end);
		
		SpecButtons[i]:SetScript("OnShow",function()
			for k = 1, #Symbiosis.DruidSpecNames do
				if GetSpecialization() == k then
					SpecButtons[k].star:Show();
				else
					SpecButtons[k].star:Hide();
				end;
			end;
		end);
		
		CreateButtonIcon(SpecButtons[i], -5, nil, i);
	end;

	local FirstShowOfInfo1 = true;
	
	currentpanel:SetScript("OnShow",function()
		if FirstShowOfInfo1 then
			FirstShowOfInfo1 = false;
			local spec = GetSpecialization();
			ShowHideSpellButtons(Symbiosis.DruidSpecNames[spec]);
			SpecButtons[spec]:Disable();
		end;
	end);

	CreateHintButton(currentpanel,{L["ListOfSpellsGet"],L["SpellYouGetDepends"],L["ClassesMarkedAsTop"]},L["SpellsGet"]);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);

	-----------------------------------------
	--Spell Info Panel2
	-----------------------------------------

	currentpanel = CreateFrame("Frame",nil,UIParent);
	currentpanel.name = L["SpellsGrant"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	SpellInfoString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["SpellsGrant"],400,20,StartHeight);--reused local

	SpellInfoString:ClearAllPoints();
	SpellInfoString:SetPoint("TOP",currentpanel,"TOP");

	-----------
	--setup stuff for what druid GRANTS

	--Grant1: DEATHKNIGHT, HUNTER, MAGE
	--Grant2: MONK, PALADIN, PRIEST
	--Grant3: ROGUE, SHAMAN, WARLOCK
	--Grant4: WARRIOR
	local GrantContainers = {};
	local ShowGrant = {};
	
	for j = 1, 4 do
		local CurrentYOffSet = SpellInfoButtonsStartYPos;
		GrantContainers[j] = CreateFrame("Frame",nil,currentpanel);
		GrantContainers[j]:SetAllPoints(currentpanel);
		GrantContainers[j]:Hide();

		--create 4 buttons to show different spell buttons
		ShowGrant[j] = CreateButton(80,30,30+(90*(j-1)),-40,"",currentpanel);
		ShowGrant[j]:SetScript("OnClick",function()
			for k = 1, 4 do
				if k == j then
					ShowGrant[k]:Disable();
					GrantContainers[k]:Show();
				else
					ShowGrant[k]:Enable();
					GrantContainers[k]:Hide();
				end;
			end;
		end);
		
		local iStart = (j*3)-2;
		for i =  iStart, iStart + ((j==4) and 0 or 2) do
			local TarClass = Symbiosis.ClassNames[i];
			--Main Line
			CreateSpellInfoLine(CurrentYOffSet,GrantContainers[j],TarClass,nil,true);
			CurrentYOffSet = CurrentYOffSet - 30;
			--Sub Line
			for TarSpec,SpecIcon in pairs(Symbiosis.SpecIcons[TarClass]) do
				CreateSpecSubLine(CurrentYOffSet,GrantContainers[j],SpecIcon,Symbiosis.SpecNames[TarClass][TarSpec],Symbiosis.SpellsGranted[TarClass][TarSpec]);
				CurrentYOffSet = CurrentYOffSet - 30;
			end;
			CurrentYOffSet = CurrentYOffSet - 20;
			
			--add class icons to buttons
			CreateButtonIcon(ShowGrant[j], ((j==4) and 20 or mod(i-1,3)*20) , Symbiosis.ClassNames[i]);
		end;
	end;

	local FirstShowOfInfo2 = true;
	
	currentpanel:SetScript("OnShow",function()
		if FirstShowOfInfo2 then
			FirstShowOfInfo2 = false;
			GrantContainers[1]:Show();
			ShowGrant[1]:Disable();
		end;
	end);

	CreateHintButton(currentpanel,{L["ListOfSpellsGrant"],L["SpellGrantDepends"],L["AllDPSGainSame"]},L["SpellsGrant"]);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);

	-----------------------------------------
	--PopUp Menu
	-----------------------------------------
	Symbiosis.SpellPopUpPanel = CreateFrame("Frame",nil,UIParent);
	currentpanel = Symbiosis.SpellPopUpPanel;
	currentpanel.name = L["PopUp"];
	currentpanel.parent = Symbiosis.MainPanel.name;

	SpellInfoString = Symbiosis.CreateLabel(currentpanel,PanelStringColor .. "Symbiosis|r (v" .. GetAddOnMetadata("Symbiosis","Version") .. ") " .. L["PopUpOptions"],400,20,StartHeight);--reused local

	SpellInfoString:ClearAllPoints();
	SpellInfoString:SetPoint("TOP",currentpanel,"TOP");

	--"Background Name:"
	Symbiosis.CreateLabel(currentpanel,L["BackgroundName"] .. ":",120,20,StartHeight-40);
	--"Select a Background:"
	Symbiosis.CreateLabel(currentpanel,L["SelectBackground"] .. ":",200,20,StartHeight-80);
	--"Transparency:"
	Symbiosis.CreateLabel(currentpanel,L["Transparency"] .. ":",120,20,StartHeight-120);

	--popup media
	local PopUpMediaEdit = CreateFrame("EditBox","Symbiosis_PopUpMediaEdit",currentpanel,"InputBoxTemplate");

	PopUpMediaEdit:SetWidth(150);
	PopUpMediaEdit:SetHeight(20);
	PopUpMediaEdit:SetPoint("TOPLEFT",160,StartHeight-60);
	PopUpMediaEdit:SetAutoFocus(nil);
	PopUpMediaEdit:Disable();

	local function GetMedia(i)
		return Media:HashTable("statusbar")[Media:List("statusbar")[i]];
	end;
	
	local numBackgroundInited = false;
	local NumOfSymbFile = 1;
	
	function Symbiosis.FindNumOfCurBackground()
		for i,Name in ipairs(Media:List("statusbar")) do
			if SymbButton["PopUpBgFile"] == Name then
				numBackgroundInited = true;
				return i;
			end;
		end;

		return 1;
	end;
	
	local media1_upArrow, media1_downArrow;
	
	local function ScrollMedia(index)
		local selectedIsPresent = false;
		
		if not numBackgroundInited then
			NumOfSymbFile = Symbiosis.FindNumOfCurBackground();
		end;
		
		for i=1,4 do
			if Media:List("statusbar")[index+i-1] == SymbButton["PopUpBgFile"] then
				selectedIsPresent = true;
				_G["Symbiosis_MediaSelect_"..i]:SetBackdrop({
					bgFile = GetMedia(index+i-1),
					edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
					edgeSize = 1,
				});
				
				media1_upArrow:Hide();
				media1_downArrow:Hide();
			else
				_G["Symbiosis_MediaSelect_"..i]:SetBackdrop({
					bgFile = GetMedia(index+i-1);
					insets = {
						["top"] = 2,
						["bottom"] = 2,
						["left"] = 9,
						["right"] = 9,
					};
				});
			end;
			_G["Symbiosis_MediaSelect_"..i]:SetBackdropColor(1,1,1,SymbButton["Transparency"]);
		end;
		
		if selectedIsPresent then
			media1_upArrow:Hide();
			media1_downArrow:Hide();
		elseif (NumOfSymbFile < index) then
			media1_upArrow:Show();
			media1_downArrow:Hide();
		else
			media1_upArrow:Hide();
			media1_downArrow:Show();	
		end;
	end;

	local MediaSlider = Symbiosis.CreateSlider(160,StartHeight-100,"Selector",1,100,1,1,currentpanel,true);

	MediaSlider:SetScript("OnShow",function(self)
		self:SetMinMaxValues(1,getn(Media:List("statusbar"))-3);
		self.high:SetText(getn(Media:List("statusbar"))-3);
	end);

	MediaSlider:SetScript("OnValueChanged",function(self)
		self.text:SetText(self:GetValue());
		ScrollMedia(self:GetValue());
	end);

	Symbiosis.CreateLabel(currentpanel,L["Preview"] .. ":",120,380,StartHeight-6);
	
	local MediaFrame1 = CreateFrame("Frame",nil,currentpanel);
	MediaFrame1:SetWidth(204);
	MediaFrame1:SetHeight(250);
	MediaFrame1:SetPoint("TOPLEFT",352,StartHeight-35);
	MediaFrame1:SetBackdrop({	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border"	});
	MediaFrame1:SetBackdropBorderColor(1,1,1,.75);

	--create Media selector panels and up/down arrows
	do
		for i=1,4 do
			local MediaSelect = CreateFrame("Frame","Symbiosis_MediaSelect_" .. i,currentpanel);
			MediaSelect:SetWidth(150);
			MediaSelect:SetHeight(50);
			MediaSelect:SetPoint("TOPLEFT",380,StartHeight-60-50*(i-1));
			
			MediaSelect:SetScript("OnMouseDown",function()
				PopUpMediaEdit:SetText(Media:List("statusbar")[MediaSlider:GetValue()+i-1]);
				PopUpMediaEdit:SetCursorPosition(0);
				SymbButton["PopUpBgFile"] = Media:List("statusbar")[MediaSlider:GetValue()+i-1];
				Symbiosis.BackdropTable["bgFile"] = GetMedia(MediaSlider:GetValue()+i-1);
				
				if SymbiosisButton_PopUpFrame:IsVisible() then
					SymbiosisButton_PopUpFrame:Hide();
					SymbiosisButton_PopUpFrame:Show();
				end;
				
				MediaSlider.text:SetText(MediaSlider:GetValue());
				ScrollMedia(MediaSlider:GetValue());
				
				numBackgroundInited = false;
				media1_downArrow:Hide();
				media1_upArrow:Hide();
			end);
			
			MediaSelect:SetScript("OnMouseWheel",function(self,direction)
				self:SetValue(self:GetValue()-direction);
			end);
		end;
		
		--the following are local
		
		--up arrow
		media1_upArrow = CreateFrame("Frame",nil,MediaFrame1);
		media1_upArrow:SetPoint("TOPRIGHT",MediaFrame1,"TOPRIGHT",-10,-5);
		media1_upArrow:SetWidth(20);
		media1_upArrow:SetHeight(20);
		media1_upArrow:Hide();
		media1_upArrow:SetScript("OnMouseDown",function()
			MediaSlider:SetValue(Symbiosis.FindNumOfCurBackground());
		end);
		media1_upArrow.tex = media1_upArrow:CreateTexture();
		media1_upArrow.tex:SetTexture("Interface\\Buttons\\Arrow-Up-Up");
		media1_upArrow.tex:SetAllPoints(media1_upArrow);

		--down arrow
		media1_downArrow = CreateFrame("Frame",nil,MediaFrame1);
		media1_downArrow:SetPoint("BOTTOMRIGHT",MediaFrame1,"BOTTOMRIGHT",-10,-5);
		media1_downArrow:SetWidth(20);
		media1_downArrow:SetHeight(20);
		media1_downArrow:Hide();	
		media1_downArrow:SetScript("OnMouseDown",function()
			MediaSlider:SetValue(Symbiosis.FindNumOfCurBackground()-3);
		end);
		media1_downArrow.tex = media1_downArrow:CreateTexture();
		media1_downArrow.tex:SetTexture("Interface\\Buttons\\Arrow-Down-Up");
		media1_downArrow.tex:SetAllPoints(media1_downArrow);
	end;

	local TransparencySlider = Symbiosis.CreateSlider(160,StartHeight-140,"Transparency",0,100,1,100,currentpanel,true);

	TransparencySlider:SetScript("OnValueChanged",function(self)
		if SymbiosisButton_PopUpFrame:IsVisible() then
			SymbiosisButton_PopUpFrame:Hide();
			SymbiosisButton_PopUpFrame:Show();
		end;
		
		self.text:SetText(self:GetValue() .. "%");
		for i=1,4 do
			_G["Symbiosis_MediaSelect_" .. i]:SetBackdropColor(1,1,1,self:GetValue()/100);
			SymbButton["Transparency"] = self:GetValue()/100;
		end;
	end);

	local function ScrollToCurBackground()
		local Num = Symbiosis.FindNumOfCurBackground();
		if (Num == 1) or (Num == 2) then
			MediaSlider:SetValue(2);
			MediaSlider:SetValue(1);
		else
			MediaSlider:SetValue(Num-1);
		end;
	end;
	
	PopUpMediaEdit:SetScript("OnMouseDown",function()
		ScrollToCurBackground();
	end);
	
	--DONT SHOW UNIT TAGGED AS
	Symbiosis.CreateLabel(currentpanel,L["DontShowTaggedAs"],200,35,StartHeight-170);

	Symbiosis.DontShowUnitOffline =			CreateCheckButton(35+5,StartHeight-170-35,	L["Offline"],"",currentpanel);
	Symbiosis.DontShowUnitOffline:SetChecked(false);
	Symbiosis.DontShowUnitOffline:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DontShowUnitOffline"] = true;
		else
			SymbConfig["DontShowUnitOffline"] = false;
		end;
	end);

	Symbiosis.DontShowUnitStolen =			CreateCheckButton(35+5,StartHeight-170-35-20,	L["Stolen"],L["UnitHasOther"],currentpanel);
	Symbiosis.DontShowUnitStolen:SetChecked(false);
	Symbiosis.DontShowUnitStolen:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DontShowUnitStolen"] = true;
		else
			SymbConfig["DontShowUnitStolen"] = false;
		end;
	end);

	Symbiosis.DontShowUnitDead =			CreateCheckButton(35+5,StartHeight-170-35-40,	L["Dead"],"",currentpanel);
	Symbiosis.DontShowUnitDead:SetChecked(false);
	Symbiosis.DontShowUnitDead:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DontShowUnitDead"] = true;
		else
			SymbConfig["DontShowUnitDead"] = false;
		end;
	end);

	Symbiosis.DontShowUnitInsignificant =	CreateCheckButton(35+5,StartHeight-170-35-60,	L["InInsignificantGroup"],L["InInsignificantGroupTooltip"],currentpanel);
	Symbiosis.DontShowUnitInsignificant:SetChecked(false);
	Symbiosis.DontShowUnitInsignificant:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["DontShowUnitInsignificant"] = true;
		else
			SymbConfig["DontShowUnitInsignificant"] = false;
		end;
	end);

	local MediaFrame2 = CreateFrame("Frame",nil,Symbiosis.DontShowUnitInsignificant);
	MediaFrame2:SetWidth(285);
	MediaFrame2:SetHeight(138);
	MediaFrame2:SetPoint("BOTTOMLEFT",MediaFrame2:GetParent(),"BOTTOMLEFT",-25,-15);
	MediaFrame2:SetBackdrop({	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border"	});
	MediaFrame2:SetBackdropBorderColor(1,1,1,.75);
	
	CreateHLine(StartHeight-280,currentpanel);
	
	--select border

	local function SetMainBorder()
		if SymbConfig["HideMainBorder"] then
			SymbiosisButton_PopUpFrame:SetBackdrop(nil);
		else
			SymbiosisButton_PopUpFrame:SetBackdrop({	edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
														edgeSize = 2});
		end;
	end;
	
	local function GetBorder(index,noIndex)
		if noIndex then
			return Media:HashTable("border")[index];
		else
			return Media:HashTable("border")[Media:List("border")[index]];
		end;
	end;
	
	local function HeaderStyle(frame,borderFile,borderSize)--header: SymbiosisButton.PopUpHeader;
		local newBackdrop = frame:GetBackdrop();
		if not newBackdrop then
			newBackdrop = {};
		end;
		
		if not borderFile then
			newBackdrop["edgeFile"] = "Interface/ArenaEnemyFrame/UI-Arena-Border";
			newBackdrop["edgeSize"] = 3;
			frame:SetBackdrop(newBackdrop);
		else
			newBackdrop["edgeFile"] = borderFile;
			newBackdrop["edgeSize"] = borderSize;
			frame:SetBackdrop(newBackdrop);
		end;
	end;
	
	Symbiosis.CreateLabel(currentpanel,L["BorderName"] .. ":",120,20,StartHeight-300);
	Symbiosis.CreateLabel(currentpanel,L["SelectBorder"] .. ":",120,20,StartHeight-300-40);
	Symbiosis.CreateLabel(currentpanel,L["Preview"] .. ":",120,20,StartHeight-300-80);
	Symbiosis.CreateLabel(currentpanel,L["BorderSize"] .. ":",120,20,StartHeight-460);
	
	local BorderEdit = CreateFrame("EditBox","Symbiosis_BorderEdit",currentpanel,"InputBoxTemplate");

	BorderEdit:SetWidth(150);
	BorderEdit:SetHeight(20);
	BorderEdit:SetPoint("TOPLEFT",160,StartHeight-300-20);
	BorderEdit:SetAutoFocus(nil);
	BorderEdit:Disable();
	
	local BorderSelect = CreateFrame("Frame",nil,currentpanel);
	BorderSelect:SetWidth(150);
	BorderSelect:SetHeight(50);
	BorderSelect:SetPoint("TOPLEFT",160,StartHeight-300-40-20-40);

	function Symbiosis.SetBorder(index,borderSize,noIndex)
		HeaderStyle(BorderSelect,GetBorder(index,noIndex),borderSize);
		
		for i=1,Symbiosis.maxmemberbuttons do
			HeaderStyle(_G["SymbiosisButton_MemberButton_"..i],GetBorder(index,noIndex),borderSize);
		end;
	end;

	local BorderSlider = Symbiosis.CreateSlider(160,StartHeight-300-40-20,"Selector",1,100,1,1,currentpanel,true);
	local BorderSizeSelect = Symbiosis.CreateSlider(160,StartHeight-460-20,"Selector",1,40,1,1,currentpanel,true);

	BorderSlider:SetScript("OnShow",function(self)
		self:SetMinMaxValues(1,getn(Media:List("border")));
		self.high:SetText(getn(Media:List("border")));
	end);

	BorderSlider:SetScript("OnValueChanged",function(self)
		self.text:SetText(self:GetValue());
		Symbiosis.SetBorder(BorderSlider:GetValue(),BorderSizeSelect:GetValue());
		BorderEdit:SetText(Media:List("border")[self:GetValue()]);
		BorderEdit:SetCursorPosition(0);
		SymbButton["BorderFile"] = Media:List("border")[self:GetValue()];
		Symbiosis.BackdropTable["edgeFile"] = GetBorder(BorderSlider:GetValue());
		SetMainBorder();
	end);
	
	BorderSizeSelect:SetScript("OnValueChanged",function(self)
		self.text:SetText(self:GetValue());
		Symbiosis.SetBorder(BorderSlider:GetValue(),BorderSizeSelect:GetValue());
		SymbButton["BorderSize"] = self:GetValue();
		Symbiosis.BackdropTable["edgeSize"] = SymbButton["BorderSize"];
		SetMainBorder();
	end);
	
	local function ScrollToCurBorder()
		for i, Name in ipairs(Media:List("border")) do
			if Name == SymbButton["BorderFile"] then
				BorderSlider:SetValue(i);
				return;
			end;
		end;
	end;
	Symbiosis.ScrollToCurBorder = ScrollToCurBorder;
	
	Symbiosis.HideMainBorder = CreateCheckButton(320,StartHeight-320,L["HideMainBorder"],"",currentpanel);
	Symbiosis.HideMainBorder:SetChecked(false);
	Symbiosis.HideMainBorder:SetScript("OnClick",function(self)
		if self:GetChecked() == 1 then
			SymbConfig["HideMainBorder"] = true;
		else
			SymbConfig["HideMainBorder"] = false;
		end;
		SetMainBorder();
	end);
	
	currentpanel:SetScript("OnShow",function()
		ScrollToCurBackground();--Background File
		TransparencySlider:SetValue(SymbButton["Transparency"]*100);--Transparency
		ScrollToCurBorder();--Border File
		BorderSizeSelect:SetValue(SymbButton["BorderSize"]);--Border Size
		numBackgroundInited = false;
	 end);
	
	CreateHintButton(currentpanel,{L["LongPopUpHint1"],L["LongPopUpHint2"]},L["Background"]);

	currentpanel:Hide();
	InterfaceOptions_AddCategory(currentpanel);
end;