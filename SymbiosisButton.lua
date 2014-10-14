--only startup if player is druid
if Symbiosis.stop then
	return;
end;

local print = Symbiosis.print;
local L = Symbiosis.L;

--define locals
local _, SymbiosisButton, pop, targetstring, durationstring, BuffFrame, slider, CurSpec, LastSpec;
local Member, ButtonUnit, Target = {}, {}, {};

local Lasttimer = 0;
local Timerintervall = 5;--this is the intervall (in seconds) in which we check the buff on target
local BadTimeStart = 15;--when the duration string should be yellow (in minutes)

local LastWhisper, WhisperStartWatch = 0, 0;
local WhisperDelay = 60;--delay between two whispers (in seconds)
local WhisperTimeout = 3;--time when unregistering event to check for successfull buff cast (in seconds)
local LastWhisperTarget = "-";

local membercount, wantedmembercount, PlayerRaidID, SetAttrAfterCombatForLopsided = 0,0,0,0;
local UpdateAfterCombat, RemoveAfterCombat, UpdateMacroAndAttributeAfterCombat, ShowHideAfterCombat, UserHadBuff, TempHidden = false, false, false, false, false, false;
local groupsize = "solo";
local ClassColors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;

local QuestionMarkIcon, NotInSameZoneIcon = "Interface\\ICONS\\INV_Misc_QuestionMark", "Interface\\ICONS\\Ability_creature_cursed_04";

local LGIST = LibStub:GetLibrary("LibGroupInSpecT-1.0");

--button layout stuff
local maxmemberbuttons = Symbiosis.maxmemberbuttons;
local PopUpTagHeight, PopUpTagWidth = 10, 90;
local PopUpButtonHeight, PopUpButtonWidth = Symbiosis.PopUpButtonHeight, 200;
local PopUpIconHeight, PopUpIconWidth = Symbiosis.PopUpButtonHeight*0.8, Symbiosis.PopUpButtonHeight*0.8;

-- local optimizers
local UnitBuff = UnitBuff;
local UnitGUID = UnitGUID;
local UnitName = UnitName;
local UnitIsConnected = UnitIsConnected;
local UnitClass = UnitClass;
local UnitIsDeadOrGhost = UnitIsDeadOrGhost;
local GetNumGroupMembers = GetNumGroupMembers;
local GetRaidRosterInfo = GetRaidRosterInfo;
local GetSpellInfo = GetSpellInfo;
local GetSpellCooldown = GetSpellCooldown;
local IsInInstance = IsInInstance;
local IsInRaid = IsInRaid;
local IsInGroup = IsInGroup;
local InCombatLockdown = InCombatLockdown;
local GetInstanceInfo = GetInstanceInfo;
local IsSpellKnown = IsSpellKnown;
local IsShiftKeyDown = IsShiftKeyDown;
local GetTime = GetTime;
local strlower = strlower;
local floor = floor;
local unpack = unpack;
local pairs = pairs;
local ipairs = ipairs;
local select = select;
local tinsert = tinsert;
local abs = abs;
local IsSpellInRange = IsSpellInRange;
local exp = exp;
local GetSpellLink = GetSpellLink;
local format = format;
local strmatch = strmatch;
local gsub = gsub;
local wipe = wipe;
local tonumber = tonumber;
local GetSpecialization = function() return GetSpecialization() or 1 end;

--make some globals from the symbiosis table local
local SpellsGot = Symbiosis.SpellsGot;
local SpellsGranted = Symbiosis.SpellsGranted;
local SymbiosisIcon = Symbiosis.SymbiosisIcon;
local SymbiosisSpell = Symbiosis.SymbiosisSpell;
local SymbiosisSpellID = Symbiosis.SymbiosisSpellID;
local DruidSpecNames = Symbiosis.DruidSpecNames;

-----------------------------------------
--helper functions
-----------------------------------------

--check if we are in raid or party
local function CheckRaidOrParty()
	if IsInRaid() then
		groupsize = "raid";
	elseif IsInGroup() then
		groupsize = "party";
	else
		groupsize = "solo";
	end;
	membercount = GetNumGroupMembers();
end;

local function ShowHideButton(DoShow, PetBattle)
	--hide button if user does not know Symbiosis spell
	if ( not IsSpellKnown(SymbiosisSpellID) ) then
		SymbiosisButton:Hide();
		return;
	end;
	
	if ( Symbiosis.IgnoreShowHide:GetChecked() == 1 ) and ( not PetBattle ) then
		return;
	end;

	if InCombatLockdown() then
		ShowHideAfterCombat = true;
	elseif DoShow then
		SymbiosisButton:Show();
	else
		SymbiosisButton:Hide();
	end;
end;

local function GetSpellToCheckForCD()
	if Target["class"] then
		return SpellsGot[CurSpec][Target["class"]] or SymbiosisSpellID;
	else
		return SymbiosisSpellID;
	end;
end;

local function DoWeNeedCd(start,dur,enabled)
	if SymbConfig["ShowGCD"] or (dur > 1.5) then
		return start, dur, enabled;
	else
		return 0, 0, 0;
	end;
end;

local function GetCD()
	--if buff is up: use GetSpell
	if UnitBuff("player",SymbiosisSpell) then
		return DoWeNeedCd(GetSpellCooldown(GetSpellToCheckForCD()));
	else--if buff is not up: use SymbiosisSpell
		return DoWeNeedCd(GetSpellCooldown(SymbiosisSpellID));
	end;
end;

--returns member table wich is sorted by class
local function SortTablePerClass(mytable)
	local newtable = {};

	--sort with order of Symbiosis.ClassNames while considering user priorities (j=1 user prio, j=2 rest)
	for j = 1,2 do
		for i in ipairs(Symbiosis.ClassNames) do
			for k in pairs(mytable) do
				if ( Symbiosis.ClassNames[i] == mytable[k]["class"] ) then
					if (j == 1) and (SymbConfig["SpellInfoCfg"]["Prioritize"][DruidSpecNames[CurSpec]][mytable[k]["class"]]) then
						tinsert(newtable,mytable[k]);
					elseif (j == 2) and (not SymbConfig["SpellInfoCfg"]["Prioritize"][DruidSpecNames[CurSpec]][mytable[k]["class"]]) then
						tinsert(newtable,mytable[k]);
					end;
				end;
			end;
		end;
	end;
	
	if (#newtable > 0) then
		return newtable;
	else
		return mytable;
	end;
end;

--adjust size of hotkeystring according to size of symbiosis button
function Symbiosis.ResizeHotkeyString()
	if ( SymbButton["Size"] < 80 ) then
		Symbiosis.HotkeyString:Hide();
		return;
	end;

	if ( not GetBindingKey(Symbiosis.Key) ) then
		Symbiosis.HotkeyString:Hide();
		return;
	end;

	Symbiosis.HotkeyString:SetText(GetBindingKey(Symbiosis.Key));
	Symbiosis.HotkeyString:SetFont((Symbiosis.HotkeyString:GetFont()),6.126*exp(0.003*SymbButton["Size"]),"OUTLINE");
	Symbiosis.HotkeyString:SetWidth(strlenutf8(Symbiosis.HotkeyString:GetText())*12);
	Symbiosis.HotkeyString:SetHeight(Symbiosis.HotkeyString:GetStringHeight());

	local xoffset = -72.018*exp(-SymbButton["Size"]/42.774)+10;
	local yoffset = 2;

	if ( SymbButton["Size"] >= 200 ) then
		yoffset = 10;
	elseif ( SymbButton["Size"] > 90 ) then
		yoffset = 5;
	end;

	Symbiosis.HotkeyString:SetPoint("TOPRIGHT",-xoffset,-yoffset);
end;

local function GetPlayerZone()
	return (select(7,GetRaidRosterInfo(PlayerRaidID or 0))) or "";
end;

--recoloring of symbiosis button to show if target is in range
local function CheckRange(BuffIsUp, Reset)
	--out of range (0) OR in range (1) OR unit not valid (nil)
	local state = IsSpellInRange(SymbiosisSpell,((not BuffIsUp and Target["unit"]) or "target"));
	if (state == 0) and (not Reset) then
		SymbiosisButton.icon:SetVertexColor(1,0,0);--red
	elseif (state == nil) and (not BuffIsUp) and (not Reset) and (not UnitBuff("player",SymbiosisSpell)) then
		if SymbConfig["ForceNormalColors"] then
			SymbiosisButton.icon:SetVertexColor(1,1,1);--full color
		elseif ( (select(7,GetRaidRosterInfo(Target["raidID"] or 0))) == GetPlayerZone() ) then
			SymbiosisButton.icon:SetVertexColor(1,0,0);--red
		else
			SymbiosisButton.icon:SetVertexColor(.5,.5,.5);--gray
		end;
	else
		SymbiosisButton.icon:SetVertexColor(1,1,1);--full color
	end;
end;

local function SetupRangeCheckOnButton(BuffIsUp, Reset)
	if SymbConfig["DisableRangeIndicator"] then
		if SymbiosisButton.rangecheck:GetScript("OnUpdate") then
			SymbiosisButton.rangecheck:SetScript("OnUpdate",nil);
			SymbiosisButton.icon:SetVertexColor(1,1,1);
		end;
		
		return;
	end;

	if (not Reset) then
		local TimeSinceLast = 0;
		local UpdateIntervall = 0.3;
		SymbiosisButton.rangecheck:SetScript("OnUpdate",function(self,elapsed)
			TimeSinceLast = TimeSinceLast + elapsed;
			
			if TimeSinceLast > UpdateIntervall then
				CheckRange(BuffIsUp);
				TimeSinceLast = 0;
			end;
		end);
	else
		SymbiosisButton.rangecheck:SetScript("OnUpdate",nil);
		CheckRange(nil,true);
	end;
end;

-----------------------------------------
--timer (for buff watch) stuff
-----------------------------------------
--timer for buff duration
local CheckBuffSetTimerAndSetDuration;
local function SetTimer(StartTimer)
	if StartTimer then
		SymbiosisButton:SetScript("OnUpdate",function(self,elapsed)
			Lasttimer = Lasttimer + elapsed;
			if ( Lasttimer > Timerintervall ) then
				Lasttimer = 0;
				CheckBuffSetTimerAndSetDuration(false);
			end;
		end);
	else
		--remove OnUpdate handler
		SymbiosisButton:SetScript("OnUpdate",nil);
	end;
end;

--update duration of symbiosis buff to durationstring
local function UpdateDuration(Time)
	SetAttrAfterCombatForLopsided = 0;
	
	if (not (SymbiosisButton:GetAttribute("type1") == "macro")) and (not (durationstring:GetText() == L["BuffOnlyUpOnYou"] .. "\n(" .. L["RemoveOnClick"] .. ")")) then
		if InCombatLockdown() then
			SetAttrAfterCombatForLopsided = 2;
		else
			SymbiosisButton:SetAttribute("type1","macro");
		end;
	end;
	
	if ( Time > 0 ) then
		if ( (Time/60) < BadTimeStart ) then
			--(badtimestart=15)
			durationstring:SetTextColor(GameFontNormal:GetTextColor());--yellow
		else
			durationstring:SetTextColor(0.4,1,0);--green
		end;
		if ( (-floor(-Time/60)) > 1 ) then
			--display minutes (green or yellow when badtimestart(s))
			durationstring:SetText((-floor(-Time/60)) .. " " .. L["Minutes_Short"]);
		else
			--display seconds
			durationstring:SetTextColor(1,0,0);--red
			durationstring:SetText(floor(Time) .. " " .. L["Seconds_Short"]);
		end;
	elseif ( Time == -1 ) then
		--buff is not up on target
		if UnitBuff("player",SymbiosisSpell) then
			--but buff is up on us
			durationstring:SetTextColor(0.78,0.08,0.52);--medium violet red
			durationstring:SetText(L["BuffOnlyUpOnYou"]);
			
			if SymbConfig["EnableLopsidedWorkaround"] then
				if InCombatLockdown() then
					SetAttrAfterCombatForLopsided = 1;
				else
					if not (SymbiosisButton:GetAttribute("type1") == "cancelaura") then
						SymbiosisButton:SetAttribute("type1","cancelaura");
					end;
					
					durationstring:SetText(L["BuffOnlyUpOnYou"] .. "\n(" .. L["RemoveOnClick"] .. ")");
					
					SetTimer(true);
				end;
			end;
		else
			--neither target nor we have buff up
			durationstring:SetTextColor(1,0,0);--red
			durationstring:SetText(L["BuffNotUp"] .. "!");
		end;
	elseif ( Time == -2) then
		--target has buff of other druid
		durationstring:SetText(L["TargetStolen"] .. "!");
		durationstring:SetTextColor(0,0,1);--blue
	elseif ( Time == 0 ) then
		--taget is out of scan range
		durationstring:SetText(L["BuffIsUp"]);
		durationstring:SetTextColor(GameFontNormal:GetTextColor());
	else
		--this should never happen
		durationstring:SetText("");
	end;
end;

local function UpdateMacroAndAttribute(BuffIsUp)
	Symbiosis.EditTheMacro();
	if BuffIsUp then
		SymbiosisButton:SetAttribute("macrotext","/cast "..SymbiosisSpell);
	elseif Target["name"] then
		SymbiosisButton:SetAttribute("macrotext","/target " .. Target["name"] .. "\n/cast " .. SymbiosisSpell .. "\n/targetlasttarget");
	end;
end;

local function CheckMacroAndAttribute(OnTargetSet)
	--update macro and attribute of symbiosis button: when symbiosis is not up we want to have [@SymbiosisTarget] in macro and attribute, when it is up we dont want that
	local incombat = InCombatLockdown();
	if UnitBuff("player",SymbiosisSpell) then
		if ( (not UserHadBuff) or OnTargetSet ) and (not incombat) then
			UpdateMacroAndAttribute(true);
			UserHadBuff = true;
		elseif ( (not UserHadBuff) or OnTargetSet ) and incombat then
			UpdateMacroAndAttributeAfterCombat = true;
		end;
	else
		if ( UserHadBuff or OnTargetSet ) and (not incombat) then
			UserHadBuff = false;
			UpdateMacroAndAttribute(false);
		elseif ( UserHadBuff or OnTargetSet ) and incombat then
			UpdateMacroAndAttributeAfterCombat = true;
		end;
	end;
end;

--Check current buff on Target["unit"], set duration and start timer if necessary.
--ToggleTimerOn: 
--SetTimer() calls ToggleTimerOn==false
--SetSymbiosisButton() calls ToggleTimerOn==true
--BuffFrame_OnEvent() calls ToggleTimerOn==true
function CheckBuffSetTimerAndSetDuration(ToggleTimerOn)--this is local, decleration is above SetTimer()
	if Target["unit"] then
		local expiration,unitCaster = select(7,UnitBuff(Target["unit"],SymbiosisSpell));
		if expiration then
			if unitCaster == "player" then
				--target has our buff
				UpdateDuration(expiration - GetTime());
				SetupRangeCheckOnButton(true);
			elseif unitCaster then
				--target has buff of other druid
				UpdateDuration(-2);
				SetupRangeCheckOnButton(false);
			else
				--target is out of scan range
				UpdateDuration(0);
				SetupRangeCheckOnButton(false);
			end;

			--if we are not called by SetTimer then call SetTimer(true)
			if ToggleTimerOn then
				SetTimer(true);
			end;
		else
			--target does not have any symbiosis buff
			SetTimer(false);
			UpdateDuration(-1);
			SetupRangeCheckOnButton(false);
		end;
	else
		--remove timer if target is nil
		SetTimer(false);
		UpdateDuration(-1);	
		SetupRangeCheckOnButton(nil,true);
	end;

	CheckMacroAndAttribute(true);
end;

-----------------------------------------
--configure symbiosis main button
--and setup table for spec icons
-----------------------------------------

--color to display the name of a member, based on class
local function GetColor(class,GetHex)
	if GetHex then
		if ClassColors[class] then
			return ClassColors[class]["colorStr"];
		else
			return "ffffffff";
		end;
	end;
	
	if ClassColors[class] then
		return ClassColors[class]["r"], ClassColors[class]["g"], ClassColors[class]["b"];
	else
		return GameFontNormal:GetTextColor();
	end;
end;

local function CheckSpec(SpecIconTable,classOrSpecId)
	return (select(3,GetSpellInfo(SpecIconTable[classOrSpecId])));
end;

local function GetIconOfSpec(TargetClass,TargetSpec)
	if TargetSpec and SpellsGranted[TargetClass] then--check for SpellGranted table because of 'attempt to index local "SpecIconTable" (a nil value)' error
		return CheckSpec(SpellsGranted[TargetClass],TargetSpec), SpellsGranted[TargetClass][TargetSpec];
	elseif not TargetSpec then
		return CheckSpec(SpellsGot[GetSpecialization()],TargetClass), SpellsGot[GetSpecialization()][TargetClass];
	else
		return;
	end;
end;

--set the icon of the symbiosis main button based on spec of druid and class of target
local function SetSymbiosisButtonIcon()
	local icon, spellid;
	if Target["class"] then
		icon, spellid = GetIconOfSpec(Target["class"]);
	end;

	SymbiosisButton.icon.spellid = nil;

	if icon then
		SymbiosisButton.icon:SetTexture(icon);
		SymbiosisButton.icon:SetTexCoord(0,1,0,1);
		SymbiosisButton.icon.spellid = spellid;
	elseif Target["class"] then
		SymbiosisButton.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
		SymbiosisButton.icon:SetTexCoord(unpack(CLASS_ICON_TCOORDS[Target["class"]]));
	elseif Target["name"] then
		SymbiosisButton.icon:SetTexture(QuestionMarkIcon);
		SymbiosisButton.icon:SetTexCoord(0,1,0,1);
	else
		SymbiosisButton.icon:SetTexture(SymbiosisIcon);
		SymbiosisButton.icon:SetTexCoord(0,1,0,1);
	end;
end;

--set name above the symbiosis main button in color of class
local function SetSymbiosisButtonName()
	targetstring:SetText(Target["nameShort"] or Target["name"]);
	targetstring.Name = Target["name"];
	targetstring:Show();
	targetstring:SetTextColor(GetColor(Target["class"]));
end;

--add icon of spell/class to symbiosis button based on the Target[] table and set name
local function SetSymbiosisButton()
	SetSymbiosisButtonIcon();
	SetSymbiosisButtonName();
	CheckBuffSetTimerAndSetDuration(true);

	--redo animation on new target
	local start, dur, enabled = GetCD();
	if (enabled == 1) and (dur > 0) and (start > 0) then
		Symbiosis.CooldownFrame:SetCooldown(start,dur);
	end;

	--register event to check buff
	BuffFrame:RegisterEvent("UNIT_AURA");
end;

function Symbiosis.RemoveSymbiosisTarget()
	BuffFrame:UnregisterAllEvents();
	SetTimer(false);

	wipe(Target);

	SymbiosisButton.icon:SetTexture(SymbiosisIcon);
	SymbiosisButton.icon:SetTexCoord(0,1,0,1);
	SymbiosisButton.icon.spellid = nil;

	durationstring:SetText("");
	targetstring:SetText(L["NoTarget"]);
	targetstring.Name = L["NoTarget"];
	targetstring:SetTextColor(GameFontNormal:GetTextColor());

	if ( targetstring:GetText() == L["NoTarget"] ) then
		if SymbConfig["RemoveNoTargetTag"] then
			targetstring:Hide();
		else
			targetstring:Show();
		end;
	else
		targetstring:Show();
	end;

	if InCombatLockdown() then
		RemoveAfterCombat = true;
	else
		SymbiosisButton:SetAttribute("macrotext","");
		Symbiosis.CooldownFrame:SetCooldown(0,0);
		SetupRangeCheckOnButton(nil,true);
	end;
end;

-----------------------------------------
--setup stuff to display popup functions
-----------------------------------------
local ShowPopUp;

local function SetErrorIcon(frame,i,grant,isInRange,criticalError)
	--we have no class of target or couldnt retrieve icon for other reasons
	if (Member[i] and Member[i]["class"]) and (not grant) then
		frame:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES");
		frame:SetTexCoord(unpack(CLASS_ICON_TCOORDS[Member[i]["class"]]));
	elseif isInRange then
		frame:SetTexture(QuestionMarkIcon);
		frame:SetTexCoord(0,1,0,1);
	else
		frame:SetTexture(NotInSameZoneIcon);
		frame:SetTexCoord(0,1,0,1);
	end;

	--remove/overwrite possible old handlers
	if grant then--only grant icons will get error icon
		local grantIconParent = frame:GetParent();
		grantIconParent:SetScript("OnMouseDown",nil);
		
		grantIconParent:SetScript("OnEnter",function()
			GameTooltip:SetOwner(grantIconParent,"ANCHOR_CURSOR",2,2);
			if isInRange or criticalError then
				GameTooltip:SetText(L["ErrorIconTooltip"]);
			else
				GameTooltip:SetText((select(1,gsub(L["NotInRangeIconTooltip"],": ",":\n"))));
			end;
			GameTooltip:Show();
		end);
		
		grantIconParent:SetScript("OnLeave",function()
			GameTooltip:Hide();
		end);
	end;
end;

--icon to display near the member, based on druid spec and target class
local function SetIcon(frame,i,grantframe)
	local icon, spellId;

	if Member[i]["class"] then
		icon, spellId = GetIconOfSpec(Member[i]["class"]);
	end;

	local IconParent = frame:GetParent();
	IconParent:Show();
	
	if icon and spellId then
		--set icon
		frame:SetTexture(icon);
		frame:SetTexCoord(0,1,0,1);
		
		--set on enter event
		IconParent:SetScript("OnEnter",function()
			GameTooltip:SetOwner(IconParent,"ANCHOR_CURSOR",2,2);
			GameTooltip:SetHyperlink("spell:"..spellId);
			GameTooltip:Show();
		end);
		
		--set on leave event
		IconParent:SetScript("OnLeave",function()
			GameTooltip:Hide();
		end);
		
		--link spell to chat on shiftclick
		IconParent:SetScript("OnMouseDown",function()
			if IsShiftKeyDown() then
				ChatEdit_InsertLink(GetSpellLink(spellId));
			end;
		end);
	else
		SetErrorIcon(frame,i);
	end;

	if Member[i]["GUID"] and Member[i]["unit"] and grantframe then
		local granticon, grantspellId, targetSpec;
		
		if LGIST:GetCachedInfo(Member[i]["GUID"]) then
			targetSpec = LGIST:GetCachedInfo(Member[i]["GUID"]).spec_index;
		end;
		
		if (not targetSpec) and Member[i]["class"] then
			--if we cannot retrieve target spec yet but all specs of target class gain same spell just use that
			local checkId;
			local allSame = true;
			
			for _, Id in pairs(SpellsGranted[Member[i]["class"]]) do
				if not checkId then
					checkId = Id;
				elseif not (checkId == Id) then
					allSame = false;
				end
			end;
			
			if allSame then
				targetSpec = 1;
			end;
		end;
		
		if targetSpec then
			granticon, grantspellId = GetIconOfSpec(Member[i]["class"],targetSpec);
			
			if granticon and grantspellId then
				grantframe:SetTexture(granticon);
				grantframe:SetTexCoord(0,1,0,1);
				
				local grantIconParent = grantframe:GetParent();
				grantIconParent:Show();
				--set on enter event
				grantIconParent:SetScript("OnEnter",function()
					GameTooltip:SetOwner(grantIconParent,"ANCHOR_CURSOR",2,2);
					GameTooltip:SetHyperlink("spell:"..grantspellId);
					GameTooltip:Show();
				end);
				
				--set on leave event
				grantIconParent:SetScript("OnLeave",function()
					GameTooltip:Hide();
				end);
				
				--link spell to chat on shiftclick
				grantIconParent:SetScript("OnMouseDown",function()
					if IsShiftKeyDown() then
						ChatEdit_InsertLink(GetSpellLink(grantspellId));
					end;
				end);
			else
				SetErrorIcon(grantframe,i,true,(select(7,GetRaidRosterInfo(Member[i]["raidID"] or 0))) == GetPlayerZone());
			end;
		else
			SetErrorIcon(grantframe,i,true,(select(7,GetRaidRosterInfo(Member[i]["raidID"] or 0))) == GetPlayerZone());
		end;
	else
		SetErrorIcon(grantframe,i,true,nil,true);
	end;
end;

local WhisperFrame = CreateFrame("Frame");
local StartSpellCastFrame = CreateFrame("Frame");
Symbiosis.StartSpellCastFrame = StartSpellCastFrame;
StartSpellCastFrame:SetScript("OnEvent",function(self,event,unit,spell)
	if (unit == "player") and (spell == SymbiosisSpell) then
		WhisperStartWatch = GetTime();
		WhisperFrame:RegisterEvent("UNIT_AURA");
	end;
end);

--whisper stuff
local WhisperedPeopleList = {};
local DoWhisper = false;
local unitCaster, expirationTime;
WhisperFrame:SetScript("OnEvent",function(self,event,unit)
	if (GetTime() - WhisperStartWatch) > WhisperTimeout then
		WhisperFrame:UnregisterAllEvents();
		return;
	end;
	
	if Target["unit"] then
		if not (unit == Target["unit"]) then
			return;
		end;	
		expirationTime, unitCaster = select(7,UnitBuff(Target["unit"],SymbiosisSpell));
	else
		unitCaster = nil;
	end;

	if (unitCaster == "player") then
		DoWhisper = true;
		if LastWhisperTarget == Target["name"] then
			if (GetTime()-LastWhisper) < WhisperDelay then
				DoWhisper = false;
			end;
		end;
		
		--so we only get fresh buffs (full expTime is 3600):
		if (expirationTime - GetTime()) < 3598 then
			DoWhisper = false;
		end;
		
		if DoWhisper then
			WhisperFrame:UnregisterAllEvents();
			
			if ( (select(2,IsInInstance())) == "arena" ) and ( SymbConfig["DisableWhispArena"] ) then
				return;
			end;
			
			LastWhisperTarget = Target["name"];
			LastWhisper = GetTime();

			local targetSpec;
			
			if Target["GUID"] and LGIST:GetCachedInfo(Target["GUID"]) then
				targetSpec = LGIST:GetCachedInfo(Target["GUID"]).spec_index;
			end;
			
			--full msg on first whisper. simplify msg on consecutives whispers.
			local WhisperList = Symbiosis.GetWhisperMessage(GetSpecialization(),Target["class"],Target["unit"],((WhisperedPeopleList[Target["name"]]) and (SymbConfig["FullWhispOnlyOnFirst"])),targetSpec);
			
			for _, text in ipairs(WhisperList) do
				SendChatMessage(text,"WHISPER",nil,Target["name"]);
			end;
			
			WhisperedPeopleList[Target["name"]] = true;
		end;
	end;
end);

local checkBuffAfterLopsidedRemove = CreateFrame("Frame");
checkBuffAfterLopsidedRemove:SetScript("OnEvent",function()
	if ( not UnitBuff("player",SymbiosisSpell) ) and ( not UnitBuff(Target["unit"] or "player",SymbiosisSpell) ) then
		checkBuffAfterLopsidedRemove:UnregisterAllEvents();
		SymbiosisButton:SetAttribute("type1","macro");
	end;
end);

--the event fired when symbiosis button is clicked
local function OnClickEventMainButton(self,button)--self and button are nil when called from macro
	if not button then
		button = "LeftButton"
	end;

	if ( button == "RightButton" ) and ( not IsSpellKnown(SymbiosisSpellID) ) then
		print(L["YouDontKnowSymbiosis"]);
		SymbConfig["firstlogin"] = false;
		return;
	end;
	
	--the following is the standard button mapping
	if button == "RightButton" then
		if pop:IsVisible() then
			pop:Hide();
		else
			ShowPopUp();
		end;
	end;

	--notice for: remove symb buff on shift left click (the actual remove is at setattribute of secure button)
	local shiftRemoved = false;
	if (SymbConfig["DisableBuffRemove"] == false) and self and (button == "LeftButton") and IsShiftKeyDown() and UnitBuff("player",SymbiosisSpell) then
		if not ( (select(2,IsInInstance())) == "arena" ) then
			print(L["RemovedBuff"]);
			shiftRemoved = true;
		end;
	end;

	--set default attribute after removing buff from lopsided state
	if SymbConfig["EnableLopsidedWorkaround"] and self then
		local lopsidedRemoved = false;
		if (button == "LeftButton") and UnitBuff("player",SymbiosisSpell) and (not UnitBuff(Target["unit"] or "",SymbiosisSpell)) then
			lopsidedRemoved = true;
		end;
		
		if shiftRemoved or lopsidedRemoved then
			if InCombatLockdown() then
				SetAttrAfterCombatForLopsided = 2;
			else
				checkBuffAfterLopsidedRemove:RegisterEvent("UNIT_AURA");
			end;
		end;
	end;

	--Cooldown check function (non GCD)
	local start, dur, enabled = GetCD();
	if (enabled == 1) and (dur > 0) and (start > 0) then
		Symbiosis.CooldownFrame:SetCooldown(start,dur);
	end;

	--on first login print name of addon
	if SymbConfig["firstlogin"] and self then
		print(L["ClickedForFirstTime"] .. " " .. format(L["ToOpenOptUse"],Symbiosis.DoCommand("config")));
		SymbConfig["firstlogin"] = false;
	end;
end;
Symbiosis.Click = OnClickEventMainButton;

local function GetRaidId(MyName,Unit)
	if groupsize == "raid" then
		return strmatch(Unit or Target["unit"],"%d+");
	else
		for i = 1, membercount do
			if MyName == GetRaidRosterInfo(i) then
				return i;
			end;
		end;
		
		return;
	end;
end;

--function called when clicked on member in popup
local function ClickFunction(buttonID,isLogin)--on isLogin buttonID is the i in "groupsize..i"
	if pop:GetScript("OnDragStart") then
		return;
	end;
	
	if not isLogin then
		Target = ButtonUnit[buttonID];
	else
		local myname, myrealm = UnitName(groupsize..buttonID);
		local name;
		if myname and myrealm and (myrealm ~= "") then
			name = myname .. '-' .. myrealm;
		elseif ( not myname ) then
			name = "?";--to prevent empty returns when client is still loading
		else
			name = myname;
		end;
		Target["name"] = name;
		if SymbConfig["ShortenNames"] then
			Target["nameShort"] = myname;
		else
			Target["nameShort"] = nil;
		end;
		Target["unit"] = groupsize..buttonID;
		Target["subgroup"] = 1;
		Target["class"] = ( select(2,UnitClass(groupsize..buttonID)) ) or "DRUID";
		Target["online"] = 1;
		Target["isDead"] = false;
		Target["raidID"] = GetRaidId(name);
		Target["GUID"] = UnitGUID(groupsize..buttonID);
	end;

	SetSymbiosisButton();

	--set whisper command
	SymbiosisButton:SetScript("OnMouseDown",OnClickEventMainButton);
	
	pop:Hide();
end;

--set the onmousedown event of i-th button
local function SetClickEvent(buttonID, NoTarget)
	if not NoTarget then
		_G["SymbiosisButton_MemberButton_"..buttonID]:SetScript("OnMouseDown",function()
			ClickFunction(buttonID);
		end);
	else
		_G["SymbiosisButton_MemberButton_"..buttonID]:SetScript("OnMouseDown",function()
			if not pop:GetScript("OnDragStart") then
				pop:Hide();
			end;
		end);
	end;
end;

--clear button for when player is not in raid/party or no viable target is present
local function ClearButton(i,text)
	_G["SymbiosisButton_MemberButton_"..i].fontstring:SetText(text);
	_G["SymbiosisButton_MemberButton_"..i].fontstring:SetTextColor(GameFontNormal:GetTextColor());
	_G["SymbiosisButton_Icon_"..i]:SetScript("OnEnter",nil);
	_G["SymbiosisButton_GrantIcon_"..i]:SetScript("OnEnter",nil);
	_G["SymbiosisButton_Icon_"..i]:Hide();
	_G["SymbiosisButton_GrantIcon_"..i]:Hide();

	--clicking the button closes popup
	SetClickEvent(i,true);

	_G["SymbiosisButton_TagFrame_"..i]:SetText("");
	_G["SymbiosisButton_TagFrame_"..i]:SetTextColor(GameFontNormal:GetTextColor());
end;

local RetryNameAndIconFrame, RetryNameAndIconFrameTime= CreateFrame("Frame"), 0;

--set the name (in class color) and the icon (if target has our buff show little symbiosis icon) in the popup menu [where "i" is the unit number and "buttonID" ist the number of the button]
local function SetNameAndIcon(i,buttonID,debugit)--TODO: remove debug
	--emergency break: close popup and try again in a sec
	if not Member[i] then
		if Symbiosis.debugpop then
			print("Debug12:",i,buttonID,debugit,"_",GetRaidRosterInfo(i));
		end
		pop:Hide();
		RetryNameAndIconFrameTime = 0;
		RetryNameAndIconFrame:SetScript("OnUpdate",function(self,elapsed)
			RetryNameAndIconFrameTime = RetryNameAndIconFrameTime + elapsed;
			if RetryNameAndIconFrameTime > 0.3 then
				self:SetScript("OnUpdate",nil);
				ShowPopUp();
			end;
		end);
		return;
	end;
	
	local name, online, isDead, class, unit = Member[i]["name"], Member[i]["online"], Member[i]["isDead"], Member[i]["class"], Member[i]["unit"];
	local mybutton = _G["SymbiosisButton_MemberButton_"..buttonID];
	local mytag = _G["SymbiosisButton_TagFrame_"..buttonID];
	local tag = "";
	local icon = "";

	SetIcon(_G["SymbiosisButton_Icon_"..buttonID].icon,i,_G["SymbiosisButton_GrantIcon_"..buttonID].icon);

	--dead/offline tag
	if online then
		mybutton.fontstring:SetTextColor(GetColor(class));
		if isDead then
			tag = " (" .. strlower(L["Dead"]) .. ")";
		end;
		_G["SymbiosisButton_Icon_"..buttonID].icon:SetDesaturated(nil);
		_G["SymbiosisButton_GrantIcon_"..buttonID].icon:SetDesaturated(nil);
	else
		mybutton.fontstring:SetTextColor(0.5,0.5,0.5);
		tag = " (" .. L["Disconnect_Short"] .. ")";
		_G["SymbiosisButton_Icon_"..buttonID].icon:SetDesaturated(1);
		_G["SymbiosisButton_GrantIcon_"..buttonID].icon:SetDesaturated(1);
	end;

	--remove old scripts
	mytag:GetParent():SetScript("OnEnter",nil);
	mytag:GetParent():SetScript("OnLeave",nil);

	--make tag non click through
	mytag:GetParent():EnableMouse(false);

	--stolen/buffed tag
	local unitCaster = ( select(8,UnitBuff(unit,SymbiosisSpell)) );
	if unitCaster then
		if unitCaster == "player" then
			tag = " (" .. strlower(L["Buffed"]) .. ")";
			if SymbConfig["PopUp_IconSize"] <= 50 then
				icon = "|T"..SymbiosisIcon..":"..pop.buffedIconTagFunc.."|t ";
			else
				icon = "|T"..SymbiosisIcon..":20|t ";
			end;
		else
			mybutton.fontstring:SetTextColor(0.67,0.67,0.67);
			tag = " (" .. strlower(L["Stolen"]) .. ")";
			
			mytag:GetParent():SetScript("OnEnter",function()
				GameTooltip:ClearLines();
				GameTooltip:SetOwner(mytag:GetParent(),"ANCHOR_CURSOR",2,2);
				GameTooltip:AddLine(L["Stolen"] .. ": " .. UnitName(unitCaster),GetColor("DRUID"));
				GameTooltip:Show();
			end);
			
			mytag:GetParent():SetScript("OnLeave",function()
				GameTooltip:Hide();
			end);
			
			_G["SymbiosisButton_Icon_"..buttonID].icon:SetDesaturated(1);
			_G["SymbiosisButton_GrantIcon_"..buttonID].icon:SetDesaturated(1);
		end;
	end;

	--Set name and if target has our buff set little symbiosis icon:
	mybutton.fontstring:SetText(icon..(Member[i]["nameShort"] or name or "???"));

	--set tags:
	mytag:SetText(tag);
	mytag:SetTextColor(mybutton.fontstring:GetTextColor());
	local myTagContainer = mytag:GetParent();
	myTagContainer:ClearAllPoints();
	if icon == "" then
		myTagContainer:SetPoint("BOTTOMLEFT",mybutton,"BOTTOMLEFT",10,7);
		mytag:SetJustifyH("LEFT");
	else
		myTagContainer:SetPoint("TOP",mybutton.fontstring,"BOTTOM",5,2);
		mytag:SetJustifyH("CENTER");
	end;

	--fill up ButtonUnit table
	ButtonUnit[buttonID] = Member[i];
	
	return true;
end;

--shows number of buttons we need (how many member in party) and hides the rest
local function SetButtonNumber(count)
	--if we have no target to show we enlarge the fontstring width, because no icon is displayed next to it anyway, undo this here. if however the user has smaller icons we provide more space for the names:
	local fontstringWidth = 80;
	if SymbConfig["PopUp_IconSize"] <= 50 then
		fontstringWidth = 140;
	elseif SymbConfig["PopUp_IconSize"] <= 75 then
		fontstringWidth = 110;
	end;
	
	if count < maxmemberbuttons then
		_G["SymbiosisButton_MemberButton_"..count+1]:Hide();
	else
		count = maxmemberbuttons;
	end;
	
	pop.count = count;
	pop:SetHeight((SymbConfig["PopUp_Size"]/100)*PopUpButtonHeight*count);

	for i=1,count do
		_G["SymbiosisButton_MemberButton_"..i]:Show();
		_G["SymbiosisButton_MemberButton_"..i].fontstring:SetWidth(fontstringWidth);
	end;
end;

--setup number of party members
--returns: false (not in party or raid) or true (is in party/raid and members were recorded)
local function SetupMemberList()
	--delete old stuff
	wipe(Member);

	if Symbiosis.debugMemberlist then
		groupsize = "raid";
		wantedmembercount = 12;
		membercount = wantedmembercount
		for i = 1, wantedmembercount do
			Member[i] = {};
			Member[i]["class"] = Symbiosis.ClassNames[fastrandom(1,10)];
			Member[i]["GUID"] = UnitGUID("player");
			Member[i]["unit"] = "player";
			Member[i]["name"] = "Test"..i;
			--Member[i]["nameShort"] = "T"..i;
			Member[i]["online"] = fastrandom(0,1)==0 and true or false;
			Member[i]["isDead"] = false;
			Member[i]["raidID"] = i;
		end;
		return true, false;
	end;
	
	--check if we are in raid or party
	CheckRaidOrParty();

	if groupsize == "solo" then
		--we are not in raid and not in party
		return false;
	else
		--setup table
		local UnwantedUnitCount = 0;
		wantedmembercount = 0;
		local AllFiltered = true;
		local AllDruid = true;
		
		if groupsize ~= "raid" then
			membercount = membercount - 1;--units in party only go up to "party4"
		end;
		
		for i=1,membercount do
			local name,subgroup,class,online,isDead;
			if groupsize == "raid" then
				name,_,subgroup,_,_,class,_,online,isDead = GetRaidRosterInfo(i);
				if not name then
					name = "?";--to prevent empty returns when client is still loading
					
					if UnitClass(groupsize..i) then
						class = UnitClass(groupsize..i);
					else
						class = "DRUID";
					end;
					
					if not subgroup then
						subgroup = 1;
					end;
					
					online = true;
					isDead = false;
				end;
			else
				local myname,myrealm = UnitName(groupsize..i);

				if myname and myrealm and (myrealm ~= "") then
					name = myname..'-'..myrealm;
				elseif ( not myname ) then
					name = "?";--to prevent empty returns when client is still loading
				else
					name = myname;
				end;
				subgroup = 1;
				class = ( select(2,UnitClass(groupsize..i)) );
				isDead = UnitIsDeadOrGhost(groupsize..i);
				online = UnitIsConnected(groupsize..i);
			end;
			
			--ignore nonwanted classes
			local AddUnit = (not SymbConfig["SpellInfoCfg"]["Ignore"][DruidSpecNames[CurSpec]][class]);

			--Check if unit is dead and we should hide dead
			AddUnit = AddUnit and (not (SymbConfig["DontShowUnitDead"] and isDead));
			
			--Check if unit is offline and we should hide offline
			AddUnit = AddUnit and (not (SymbConfig["DontShowUnitOffline"] and (not online)));
						
			--Check if unit is stolen
			if AddUnit and SymbConfig["DontShowUnitStolen"] then
				local BuffIsUp,_,_,_,_,_,_,unitCaster = UnitBuff(groupsize..i,SymbiosisSpell);
				if (BuffIsUp) and (unitCaster ~= "player") then
					AddUnit = false;
				end;
			end;

			--Check if unit is in insignificant group
			if AddUnit and SymbConfig["DontShowUnitInsignificant"] then
				--if in 5man party: ignore everything above grp1
				if (groupsize == "party") and (subgroup > 1) then
					AddUnit = false;
				end;
				
				local _, _, size = GetInstanceInfo();
				-- Returns:
				-- 0 - None
				-- 1 - 5 Player
				-- 2 - 5 Player (Heroic)
				-- 3 - 10 Player
				-- 4 - 25 Player
				-- 5 - 10 Player (Heroic)
				-- 6 - 25 Player (Heroic)
				-- 7 - Raid Finder
				-- 8 - Challenge Mode
				-- 9 - 40 Player
				-- 10 - nil!
				-- 11 - Heroic Scenario
				-- 12 - Scenario
				-- 13 - nil!
				-- 14 - Flexible
				
				--if in 10man raid: ignore everything above grp2
				if (groupsize == "raid") and ((size == 3) or (size == 5)) and (subgroup>2) then
					AddUnit = false;
				end;
				
				--if in 25man raid: ignore everything above grp5
				if (groupsize == "raid") and ((size == 4) or (size == 6) or (size == 8)) and (subgroup>5) then
					AddUnit = false;
				end;
			end;
			
			--If we wont add unit because of filters notice the user (if enabled)
			if AddUnit and (class ~= "DRUID") then
				AllFiltered = false;
			end;
			
			--If all raid members are druid dont notice the user
			if class ~= "DRUID" then
				AllDruid = false;
			end;

			--Check if unit is druid
			AddUnit = AddUnit and (class ~= "DRUID");
			if AddUnit then
				local GUID = UnitGUID(groupsize..i);
				Member[i-UnwantedUnitCount] = {};
				Member[i-UnwantedUnitCount]["class"] = class;
				Member[i-UnwantedUnitCount]["GUID"] = GUID;
				Member[i-UnwantedUnitCount]["unit"] = groupsize..i;
				Member[i-UnwantedUnitCount]["name"] = name;
				if SymbConfig["ShortenNames"] then
					Member[i-UnwantedUnitCount]["nameShort"] = UnitName(groupsize..i);
				end;
				Member[i-UnwantedUnitCount]["online"] = online;
				Member[i-UnwantedUnitCount]["isDead"] = isDead;
				Member[i-UnwantedUnitCount]["raidID"] = GetRaidId(name,groupsize..i);
				wantedmembercount = wantedmembercount + 1;
			else 
				UnwantedUnitCount = UnwantedUnitCount + 1;
			end;
		end;
		
		Member = SortTablePerClass(Member);
		
		if AllDruid then
			AllFiltered = false;
		end;
		
		return true, AllFiltered;
	end;
end;

local function SetPopUpPosition()
	if not SymbConfig["Refresh_GetPoint_pos1"] then
		Symbiosis.Refreshbutton:ClearAllPoints();
		Symbiosis.Refreshbutton:SetPoint("TOPLEFT",pop,"BOTTOMRIGHT",15,55);
	end;
	
	if SymbConfig["Pop_GetPoint_pos1"] then
		return;
	end;
	
	--determine in which quadrant we are and set position of the PopUp accordingly
	pop:ClearAllPoints();

	if ( SymbiosisButton:GetLeft() > UIParent:GetWidth()/2 ) then
		if ( SymbiosisButton:GetBottom() > UIParent:GetHeight()/2 ) then
			pop:SetPoint("TOPRIGHT",SymbiosisButton,"BOTTOMLEFT",-8,-8);--pop ist links unten
		else
			pop:SetPoint("BOTTOMRIGHT",SymbiosisButton,"TOPLEFT",-8,8);--pop ist links oben
		end;
	else
		if ( SymbiosisButton:GetBottom() > UIParent:GetHeight()/2 ) then
			pop:SetPoint("TOPLEFT",SymbiosisButton,"BOTTOMRIGHT",8,-8);--pop ist rechts unten
		else
			pop:SetPoint("BOTTOMLEFT",SymbiosisButton,"TOPRIGHT",8,8);--pop ist rechts oben
		end;
	end;

	--if we are out of bounds: bounce popup up or down
	local bottom, top = pop:GetBottom(), pop:GetTop();
	if ( bottom < 30 ) then--popup is too low
		local point, relativeTo, relativePoint, xOfs, yOfs = pop:GetPoint(1);
		pop:ClearAllPoints();
		pop:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs + abs(bottom) + 30);
	elseif ( top + 20 > UIParent:GetHeight() ) then--popup is too high
		local point, relativeTo, relativePoint, xOfs, yOfs = pop:GetPoint(1);
		local yMove = 20;
		if SymbiosisButton.PopUpHeader:IsVisible() then
			yMove = 20 + SymbiosisButton.PopUpHeader:GetHeight();
		end;
		pop:ClearAllPoints();
		pop:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - (top - UIParent:GetHeight()) - yMove);
	end;
end;

--show PopUp menu when main button was right clicked. this is local, declaration is at the beginning of "setup stuff to display popup functions"
local LastPos = 1;

function Symbiosis:SpecUpdateOnUnit()--params: event,guid,unit,info
	local buttonNum = 1;
	local count;

	if wantedmembercount > maxmemberbuttons then
		count = maxmemberbuttons;
	else
		count = wantedmembercount;
	end;	

	local getIcon;
	for i = LastPos, LastPos+count-1 do
		getIcon = strlower(_G["SymbiosisButton_GrantIcon_"..buttonNum].icon:GetTexture() or "");
		if (getIcon == strlower(QuestionMarkIcon)) or (getIcon == strlower(NotInSameZoneIcon)) then
			SetNameAndIcon(i,buttonNum,1);
		end;
		buttonNum = buttonNum + 1;
	end;
end;

--------------

function ShowPopUp()
	--don't open popup in arena while in combat
	if InCombatLockdown() and ( (select(2,IsInInstance())) == "arena" ) then
		return;
	end;
	
	local SetupSuccess, AllFiltered = SetupMemberList();
	
	pop:Show();

	--show header only when we have people in the list
	SymbiosisButton.PopUpHeader:Hide();
	
	if SetupSuccess then
		if (wantedmembercount > 0) then
			if SymbConfig["ShowHeader"] then
				SymbiosisButton.PopUpHeader:Show();
			end;
			
			--adjust height according to member count and fill PopUp with members
			local count,DoSlider;
			if wantedmembercount > maxmemberbuttons then
				count = maxmemberbuttons;
				DoSlider = true;
			else
				count = wantedmembercount;
				DoSlider = false;
			end;
			SetButtonNumber(count);

			--setup first set of buttons (and try to snap to last position)
			if ( LastPos > wantedmembercount-maxmemberbuttons+1 ) then
				if LastPos > 1 then
					LastPos = wantedmembercount-maxmemberbuttons+1;
				else
					LastPos = 1;
				end;
			end;
			
			if ( wantedmembercount-maxmemberbuttons+1 < 1 ) then
				LastPos = 1;
			end;
			
			local buttonNum = 1;
			for i = LastPos, LastPos+count-1 do
				SetNameAndIcon(i,buttonNum,2);
				SetClickEvent(buttonNum);
				buttonNum = buttonNum + 1;
			end;

			--add update watcher if necessary
			local addUpdateWatcher = false;
			for i = 1, count do
				local getIcon = strlower(_G["SymbiosisButton_GrantIcon_"..i].icon:GetTexture() or "");
				if (getIcon == strlower(QuestionMarkIcon)) or (getIcon == strlower(NotInSameZoneIcon)) then
					addUpdateWatcher = true;
				end;
			end;
			
			if addUpdateWatcher then
				LGIST.RegisterCallback(Symbiosis,"GroupInSpecT_Update","SpecUpdateOnUnit");
			end;
			
			--setup slider if needed
			if DoSlider then
				slider:SetMinMaxValues(1,wantedmembercount-maxmemberbuttons+1);
				slider:SetValue(LastPos);
				slider:Show();
				slider:SetScript("OnValueChanged",function()
					local buttonnumber = 1;
					for i=slider:GetValue(),slider:GetValue()+maxmemberbuttons-1 do
						SetNameAndIcon(i,buttonnumber,3);
						SetClickEvent(buttonnumber);
						buttonnumber = buttonnumber + 1;
					end;
					LastPos = slider:GetValue();
					GameTooltip:Hide();
				end);
			else
				slider:Hide();
			end;
		else
			--there is no vailable target
			slider:Hide();
			SetButtonNumber(1);
			SymbiosisButton_MemberButton_1.fontstring:SetWidth(180);--if we have no target to show we enlarge the fontstring width, because no icon is displayed next to it anyway. this is undone at SetButtonNumber()
			_G["SymbiosisButton_TagFrame_1"]:SetText("");
			ClearButton(1,L["NoTarget"]);
			if AllFiltered then
				print(L["FilterRemovedAll"]);
			end;
		end;
	else
		--remove everything from list and tell the user that he is not in a party/raid
		slider:Hide();
		SetButtonNumber(1);
		SymbiosisButton_MemberButton_1.fontstring:SetWidth(180);--see note above
		_G["SymbiosisButton_TagFrame_1"]:SetText("");
		ClearButton(1,L["NotInParty"]);
	end;
	
	SetPopUpPosition();
	
	GameTooltip:Hide();
end;
Symbiosis.ShowPopUp = ShowPopUp;

-----------------------------------------
--create functions
-----------------------------------------

local function CreatePopUpHeader()
	SymbiosisButton.PopUpHeader = CreateFrame("FRAME",nil,SymbiosisButton_MemberButton_1);
	local container = SymbiosisButton.PopUpHeader;
	container:SetWidth(PopUpButtonWidth);
	container:SetHeight(PopUpButtonHeight*0.4);
	container:SetPoint("BOTTOMLEFT",SymbiosisButton_MemberButton_1,"TOPLEFT");
	container:SetBackdrop({	edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
							edgeSize = (container:GetHeight()/2)	});
	container:SetBackdropBorderColor(1,1,1,0.6);

	--headertext
	local headertext = Symbiosis.CreateLabel(container,L["HeaderText"],PopUpButtonWidth-(container:GetHeight()*0.6*2),0,0);
	headertext:ClearAllPoints();
	headertext:SetPoint("LEFT",container,"LEFT",7,0);

	--grant icon
	local grant = CreateFrame("FRAME",nil,container);
	grant:SetHeight(container:GetHeight()*0.85);
	grant:SetWidth(grant:GetHeight());
	
	container.grant = grant:CreateTexture(nil,"ARTWORK");
	container.grant:SetAllPoints(grant);
	container.grant:SetTexture("Interface\\ICONS\\Spell_nature_faeriefire");
	
	grant:SetScript("OnEnter",function()
		GameTooltip:SetOwner(grant,"ANCHOR_CURSOR",2,2);
		GameTooltip:SetText(L["HeaderSpellGrant"]);
		GameTooltip:Show();
	end);

	grant:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);

	--get icon
	local get = CreateFrame("FRAME",nil,container);
	get:SetHeight(container:GetHeight()*0.85);
	get:SetWidth(get:GetHeight());
	
	container.get = get:CreateTexture(nil,"ARTWORK");
	container.get:SetAllPoints(get);
	container.get:SetTexture(SymbiosisIcon);
	
	get:SetScript("OnEnter",function()
		GameTooltip:SetOwner(get,"ANCHOR_CURSOR",2,2);
		GameTooltip:SetText(L["HeaderSpellGet"]);
		GameTooltip:Show();
	end);

	get:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);

	--hide header if disabled
	if not SymbConfig["ShowHeader"] then
		container:Hide();
	end;
	
	--SETUP LOCATION OF HEADER ICONS
	local testLocation = false;
	
	--reanchor icon and granticon in header, depending on icon/granticon position in popup
	SymbiosisButton_Icon_1:SetScript("OnSizeChanged",function()
		grant:ClearAllPoints();		
		grant:SetPoint("CENTER",SymbiosisButton_GrantIcon_1,"CENTER",0,(PopUpButtonHeight*0.4)/2 + (PopUpButtonHeight*SymbConfig["PopUp_Size"]/100)/2);
		
		get:ClearAllPoints();
		get:SetPoint("CENTER",SymbiosisButton_Icon_1,"CENTER",0,(PopUpButtonHeight*0.4)/2 + (PopUpButtonHeight*SymbConfig["PopUp_Size"]/100)/2);
		
		--if icons in popup are too small just use a default position (needs to be done in OnUpdate handler)
		testLocation = true;
		
		--if icons are very very small just hide header icons
		if SymbConfig["PopUp_IconSize"] <= 20 then
			grant:Hide();
			get:Hide();
		else
			grant:Show();
			get:Show();
		end;
	end);
	
	--if icons in popup are too small just use a default position
	get:SetScript("OnUpdate",function()
		if testLocation then
			testLocation = false;
			local abstand = grant:GetLeft() - ( get:GetLeft() + get:GetWidth() );
			
			if abstand < 0 then
				get:ClearAllPoints();
				get:SetPoint("RIGHT",grant,"LEFT",-1,0);
			end;
		end;
	end);
	
	SymbiosisButton_Icon_1:GetScript("OnSizeChanged")();
end;

--create slider for popup
local function CreateGroupSlider()
	slider = Symbiosis.CreateSlider(0,0,"",1,15,1,0,pop,false);
	slider:SetWidth(PopUpButtonWidth);
	slider:ClearAllPoints();
	slider:SetPoint("TOPLEFT",pop,"BOTTOMLEFT",0,-5);
	slider.low:SetText("");
	slider.high:SetText("");
	slider:SetValueStep(1);
	
	local function MouseWheelFunc(self,direction)
		if slider:IsVisible() then
			--direction: 1 for up, -1 for down
			slider:SetValue(slider:GetValue()-direction);
		end;
	end;

	slider:SetScript("OnMouseWheel",function(self,direction)
		MouseWheelFunc(self,direction);
	end);

	for i=1,maxmemberbuttons do
		local mybutton = _G["SymbiosisButton_MemberButton_"..i];
		mybutton:EnableMouseWheel(1);
		mybutton:SetScript("OnMouseWheel",function(self,direction)
			MouseWheelFunc(self,direction);
		end);
	end;

	slider:Hide();
end;

--create our buttons in the PopUp menu
local function CreateMemberButtons()	
	local lastbutton = pop;
	for i = 1, maxmemberbuttons do
		--create the actual button
		local buttonframe = CreateFrame("Frame","SymbiosisButton_MemberButton_"..i,lastbutton);
		buttonframe:SetWidth(lastbutton:GetWidth());
		buttonframe:SetHeight(PopUpButtonHeight);
		buttonframe:SetPoint("TOPLEFT",lastbutton,(i==1) and "TOPLEFT" or "BOTTOMLEFT",0,0);
		buttonframe:SetFrameStrata("MEDIUM");--this must be "medium" and pop must be "high"
		buttonframe:Show();

		buttonframe:SetScript("OnShow",function()
			buttonframe:SetBackdrop(Symbiosis.BackdropTable);
			buttonframe:SetBackdropColor(1,1,1,SymbButton["Transparency"]);
		end);
		
		--close popup when clicking on "Not in party" field
		if i == 1 then
			buttonframe:SetScript("OnMouseDown",function()
				pop:Hide();
			end);
		end;
		
		--create the title of each button (which will be the names of the member)
		buttonframe.fontstring = Symbiosis.CreateLabel(buttonframe,i,buttonframe:GetWidth()-50-50-10);--50 for icons each (grant and each) and 10 for left margin
		buttonframe.fontstring:SetHeight(20);
		buttonframe.fontstring:ClearAllPoints();
		buttonframe.fontstring:SetPoint("LEFT",buttonframe,"LEFT",10,0);
		
		--create tag container
		local tagcontainer = CreateFrame("Frame",nil,buttonframe);
		tagcontainer:SetWidth(PopUpTagWidth);
		tagcontainer:SetHeight(PopUpTagHeight);
		tagcontainer:SetPoint("TOP",buttonframe.fontstring,"BOTTOM",5,2);
		tagcontainer:EnableMouse(false);
		
		--create tag, e.g. for dc/offline/stolen
		local tagframe = tagcontainer:CreateFontString("SymbiosisButton_TagFrame_"..i,"ARTWORK","GameFontNormal");
		tagframe:SetAllPoints(tagcontainer);

		--hide tags (dead/offline) when popup too small
		if SymbConfig["PopUp_Size"] < 90 then
				_G["SymbiosisButton_TagFrame_"..i]:Hide();
		end;
		
		--create grant icon
		local granticonframe = CreateFrame("Frame","SymbiosisButton_GrantIcon_"..i,buttonframe);
		granticonframe:SetWidth(PopUpIconWidth);
		granticonframe:SetHeight(PopUpIconHeight);
		granticonframe:SetPoint("RIGHT",buttonframe,"RIGHT",-2,0);
		granticonframe.icon = granticonframe:CreateTexture();
		granticonframe.icon:SetAllPoints(granticonframe);
		
		--create the icon next to the name		
		local iconframe = CreateFrame("Frame","SymbiosisButton_Icon_"..i,buttonframe);
		iconframe:SetWidth(PopUpIconWidth);
		iconframe:SetHeight(PopUpIconHeight);
		iconframe:SetPoint("RIGHT",granticonframe,"LEFT",-5,0);
		iconframe.icon = iconframe:CreateTexture();
		iconframe.icon:SetAllPoints(iconframe);
		
		lastbutton = buttonframe;
	end;
	
	--function to resize the buffed icon tag when PopUp_Size is below 50% (above 50% size should be always 20). returns rounded values.
	pop.buffedIconTagFunc = function()
		return tonumber(format("%.0f",(3.64802*exp(0.0383748*SymbConfig["PopUp_Size"]-0.239762))));
	end;
	
	Symbiosis.SetBorder(SymbButton["BorderFile"],SymbButton["BorderSize"],true);
end;

local function CreateStopDragButtons()
	------------------------
	--create dragstop frame: green "click me to disable dragging of button" button above symbiosis button
	------------------------
	
	local stopdrag = CreateFrame("Frame",nil,SymbiosisButton);
	SymbiosisButton.StopDragButton = stopdrag;
	
	stopdrag.tex = stopdrag:CreateTexture();
	stopdrag:SetWidth(100);
	stopdrag:SetHeight(30);
	stopdrag:SetPoint("BOTTOM",SymbiosisButton,"TOP",0,20);
	stopdrag:SetScript("OnMouseDown",function()
		stopdrag:Hide();
		SymbiosisButton:SetScript("OnDragStart",nil);
		SymbConfig["DragEnabled"] = false;
		print(L["FrameLocked"]);
		Symbiosis.DragButton:SetText(L["Unlock"]);
	end);
	stopdrag:Hide();

	stopdrag.tex:SetTexture(0,.95,0,.7);
	stopdrag.tex:SetAllPoints(stopdrag);

	local font = stopdrag:CreateFontString(nil,"ARTWORK","GameFontNormal");
	font:SetWidth(100);
	font:SetHeight(30);
	font:SetText(L["Lock"]);
	font:SetAllPoints(stopdrag);
	font:SetJustifyH("CENTER");

	local esc = CreateFrame("BUTTON",nil,stopdrag,"UIPanelButtonTemplate");
	esc:SetWidth(12);
	esc:SetHeight(12);
	esc:SetText("x");
	esc:SetPoint("TOPRIGHT",-1,-1);
	esc:SetScript("OnClick",function()
		stopdrag:Hide();
	end);
	
	------------------------
	--2create dragstop frame: green "click me to disable dragging of button" button above symbiosis button
	------------------------
	local stopdrag2 = CreateFrame("Frame",nil,pop);
	SymbiosisButton.StopDragButton2 = stopdrag2;
	
	stopdrag2.tex = stopdrag2:CreateTexture();
	stopdrag2:SetWidth(100);
	stopdrag2:SetHeight(30);
	stopdrag2:SetPoint("TOPRIGHT",pop,"BOTTOMLEFT",-10,-10);
	stopdrag2:SetScript("OnMouseDown",function()
		Symbiosis.StopDragFunc2();
	end);
	stopdrag2:Hide();

	stopdrag2.tex:SetTexture(0,.95,0,.7);
	stopdrag2.tex:SetAllPoints(stopdrag2);

	local font2 = stopdrag2:CreateFontString(nil,"ARTWORK","GameFontNormal");
	font2:SetWidth(100);
	font2:SetHeight(30);
	font2:SetText(L["Lock"]);
	font2:SetAllPoints(stopdrag2);
	font2:SetJustifyH("CENTER");
end;

--refresh button to get fresh data
local function CreateRefreshButton()
	Symbiosis.Refreshbutton = CreateFrame("Frame",nil,pop);
	local Refreshbutton = Symbiosis.Refreshbutton;
	Refreshbutton:SetSize(SymbConfig["Refreshbutton_Size"],SymbConfig["Refreshbutton_Size"]);
	Refreshbutton:SetResizable(true);
	Refreshbutton:SetMaxResize(100,100);
	Refreshbutton:SetMinResize(20,20);
	Refreshbutton.icon = Refreshbutton:CreateTexture();
	Refreshbutton.icon:SetAllPoints(Refreshbutton);
	Refreshbutton.icon:SetTexture("Interface\\Icons\\Spell_Frost_Stun");
	
	--size grabber
	local sizer = CreateFrame("Frame",nil,Refreshbutton);
	sizer:SetPoint("BOTTOMRIGHT");
	sizer:SetSize(20,20);
	sizer:EnableMouse(true);
	sizer.tex = sizer:CreateTexture(nil,"ARTWORK");
	sizer.tex:SetAllPoints(sizer);
	sizer.tex:SetTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Up");
	Refreshbutton.sizer = sizer;
	
	local isSizing = false;
	
	sizer:SetScript("OnMouseDown",function()
		--alt click restores default size
		if IsAltKeyDown() then
			SymbConfig["Refreshbutton_Size"] = 40;
			Refreshbutton:SetSize(40,40);
			return;
		end;
		
		isSizing = true;
		Refreshbutton:StartSizing("BOTTOMRIGHT");
		sizer.tex:SetTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Down");
	end);
	
	sizer:SetScript("OnMouseUp",function()
		isSizing = false;
		Refreshbutton:EnableMouse(true);
		Refreshbutton:StopMovingOrSizing();
		sizer.tex:SetTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Up");
	end);
	
	Refreshbutton:SetScript("OnSizeChanged",function(self,width,height)
		if width > height then
			self:SetSize(width,width);
		else
			self:SetSize(height,height);
		end;
		
		SymbConfig["Refreshbutton_Size"] = max(width,height);
	end);
	
	if SymbConfig["Refresh_GetPoint_pos1"] and SymbConfig["Refresh_GetPoint_pos2"] and SymbConfig["Refresh_GetPoint_x"] and SymbConfig["Refresh_GetPoint_y"] then
		Refreshbutton:SetPoint(
			SymbConfig["Refresh_GetPoint_pos1"],
			UIParent,
			SymbConfig["Refresh_GetPoint_pos2"],
			SymbConfig["Refresh_GetPoint_x"],
			SymbConfig["Refresh_GetPoint_y"]
		);
	else
		SymbConfig["Refresh_GetPoint_pos1"] = nil;
	end;
	
	Refreshbutton:SetMovable(true);
	Refreshbutton:RegisterForDrag("LeftButton");
	Refreshbutton:SetScript("OnDragStop",function()
		Refreshbutton:StopMovingOrSizing();
		local pos1,_,pos2,x,y = Refreshbutton:GetPoint(1);
		SymbConfig["Refresh_GetPoint_pos1"] = pos1;
		SymbConfig["Refresh_GetPoint_pos2"] = pos2;
		SymbConfig["Refresh_GetPoint_x"] = x;
		SymbConfig["Refresh_GetPoint_y"] = y;
	end);
	
	local LastCheck = 0;
	Refreshbutton:SetScript("OnMouseDown",function()
		if Refreshbutton:GetScript("OnDragStart") or isSizing then
			return;
		end;
		
		pop:SetScript("OnUpdate",function(self,elapsed)
			LastCheck = LastCheck + elapsed;
			if LastCheck > 1 then
				LastCheck = 0;
				Refreshbutton:Show();
				pop:SetScript("OnUpdate",nil);
			end;
		end);
		Refreshbutton:Hide();
		pop:Hide();
		ShowPopUp();
	end);
	
	Refreshbutton:SetScript("OnEnter",function()
		GameTooltip:SetOwner(Refreshbutton,"ANCHOR_BOTTOMRIGHT",5,5);
		GameTooltip:SetText(L["Refresh"]);
		GameTooltip:Show();
	end);
	
	Refreshbutton:SetScript("OnLeave",function()
		GameTooltip:Hide();
	end);
	
	sizer:Hide();
end;

--create PopUp menu
local function CreatePopUpMenu()
	pop = CreateFrame("Frame","SymbiosisButton_PopUpFrame",SymbiosisButton);

	--number of visible member buttons
	pop.count = 1;
	
	--hide frame on esc pressed
	tinsert(UISpecialFrames,pop:GetName());

	pop:SetWidth(PopUpButtonWidth);

	--set saved old position (if it is saved)
	if SymbConfig["Pop_GetPoint_pos1"] and SymbConfig["Pop_GetPoint_pos2"] and SymbConfig["Pop_GetPoint_x"] and SymbConfig["Pop_GetPoint_y"] then
		pop:SetPoint(
		SymbConfig["Pop_GetPoint_pos1"],
		UIParent,
		SymbConfig["Pop_GetPoint_pos2"],
		SymbConfig["Pop_GetPoint_x"],
		SymbConfig["Pop_GetPoint_y"]
		);
	else
		SymbConfig["Pop_GetPoint_pos1"] = nil;
	end;
	
	--frame layout
	if SymbConfig["HideMainBorder"] then
		pop:SetBackdrop(nil);
	else
		pop:SetBackdrop({	edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
							edgeSize = 2});
	end;

	--this must be "high" and buttons must be "medium"
	pop:SetFrameStrata("HIGH");

	--setup stuff for dragging
	pop:SetMovable(true);
	pop:RegisterForDrag("LeftButton");
	pop:SetScript("OnDragStop",function()
		pop:StopMovingOrSizing();
		local pos1,_,pos2,x,y = pop:GetPoint(1);
		SymbConfig["Pop_GetPoint_pos1"] = pos1;
		SymbConfig["Pop_GetPoint_pos2"] = pos2;
		SymbConfig["Pop_GetPoint_x"] = x;
		SymbConfig["Pop_GetPoint_y"] = y;
	end);

	pop:Hide();
	
	--remove old watcher when we close popup
	pop:SetScript("OnHide",function()
		LGIST.UnregisterCallback(Symbiosis,"GroupInSpecT_Update","SpecUpdateOnUnit");
	end);
	
	--refresh button to get fresh data
	CreateRefreshButton();
end;

--create text above main button
local function CreateTargetString()
	targetstring = Symbiosis.CreateLabel(SymbiosisButton,L["NoTarget"],250,0,35);	
	targetstring:SetJustifyH("CENTER");
	targetstring:ClearAllPoints();
	targetstring:SetPoint("BOTTOM",SymbiosisButton,"TOP",0,4);
	targetstring:SetHeight(10);
	Symbiosis.TargetString = targetstring;

	targetstring.Refresh = function()
		if not (targetstring:GetText() == L["NoTarget"]) then
			if SymbConfig["ShortenNames"] then
				targetstring:SetText(Target["nameShort"] or UnitName(Target["unit"]));
			else
				targetstring:SetText(Target["name"]);
			end;
		end;
	end;
	
	if SymbConfig["RemoveNoTargetTag"] and ( targetstring:GetText() == L["NoTarget"] ) then
		targetstring:Hide();
	else
		targetstring:Show();
	end;

	durationstring = Symbiosis.CreateLabel(SymbiosisButton,"",200,0,0);
	durationstring:SetJustifyH("CENTER");
	durationstring:ClearAllPoints();
	durationstring:SetPoint("TOP",SymbiosisButton,"BOTTOM",0,10);
end;

--create main button
local function CreateMainButton()	
	--create button&hotkeystring, set texture and show the button
	SymbiosisButton = CreateFrame("Button","SymbiosisButton",UIParent,"SecureActionButtonTemplate");
	SymbiosisButton:SetWidth((SymbButton["Size"]/100)*Symbiosis.ButtonSize);
	SymbiosisButton:SetHeight(SymbiosisButton:GetWidth());

	Symbiosis.HotkeyString = SymbiosisButton:CreateFontString(nil,"ARTWORK","GameFontNormal");
	local HotkeyString = Symbiosis.HotkeyString;
	HotkeyString:SetJustifyH("RIGHT");
	HotkeyString:Hide();
	Symbiosis.ResizeHotkeyString();

	--slider
	Symbiosis.SizerSlider:SetValue(SymbButton["Size"]);

	--for range check
	SymbiosisButton.rangecheck = CreateFrame("Frame",nil,SymbiosisButton);

	SymbiosisButton.icon = SymbiosisButton:CreateTexture();
	SymbiosisButton.icon:SetTexture(SymbiosisIcon);
	SymbiosisButton.icon:SetAllPoints(SymbiosisButton);
	SymbiosisButton:SetPoint(
		SymbButton["GetPoint_pos1"],
		UIParent,
		SymbButton["GetPoint_pos2"],
		SymbButton["GetPoint_x"],
		SymbButton["GetPoint_y"]
	);
	ShowHideButton(true);

	local function GetPos()
		if ( SymbiosisButton:GetLeft() > UIParent:GetWidth()/2 ) then
			if ( SymbiosisButton:GetBottom() > UIParent:GetHeight()/2 ) then
				return "ANCHOR_BOTTOMLEFT";
			else
				return "ANCHOR_TOPRIGHT";
			end;
		else
			if ( SymbiosisButton:GetBottom() > UIParent:GetHeight()/2 ) then
				return "ANCHOR_BOTTOMRIGHT";
			else
				return "ANCHOR_TOPLEFT";
			end;
		end;
	end;

	SymbiosisButton:SetScript("OnEnter",function()
		if not SymbConfig["DisableMainTooltip"] then
			if pop:IsVisible() then
				return;
			end;
			
			local spellid = SymbiosisButton.icon.spellid;
			
			if not spellid then
				return;
			end;
			
			GameTooltip:SetOwner(SymbiosisButton,GetPos(),2,2);
			GameTooltip:SetHyperlink("spell:"..spellid);
			GameTooltip:Show();
		else
			GameTooltip:Hide();
		end;
		
		--show little tag for hotkey when mousing over button
		if GetBindingKey(Symbiosis.Key) then
			if SymbButton["Size"] < 80 then
				Symbiosis.HotkeyString:Hide();
				return;
			end;
			HotkeyString:SetText(GetBindingKey(Symbiosis.Key));
			HotkeyString:Show();
		end;
	end);

	SymbiosisButton:SetScript("OnLeave",function()
		GameTooltip:Hide();
		HotkeyString:Hide();
	end);

	--cast buff on unmodified leftclick
	SymbiosisButton:SetAttribute("type1","macro");

	--remove buff on shift leftclick
	if ( SymbConfig["DisableBuffRemove"] == false ) then
		SymbiosisButton:SetAttribute("shift-type1","cancelaura");
	end;
	SymbiosisButton:SetAttribute("unit","player");
	SymbiosisButton:SetAttribute("spell",SymbiosisSpell);

	--PopUp window on rightclick
	SymbiosisButton:SetScript("OnMouseDown",OnClickEventMainButton);

	--setup stuff to drag button
	SymbiosisButton:EnableMouse(true);
	SymbiosisButton:SetMovable(true);
	SymbiosisButton:RegisterForDrag("LeftButton");
	SymbiosisButton:SetScript("OnDragStop",function()
		SymbiosisButton:StopMovingOrSizing();
		local pos1,_,pos2,x,y = SymbiosisButton:GetPoint(1);
		SymbButton["GetPoint_pos1"] = pos1;
		SymbButton["GetPoint_pos2"] = pos2;
		SymbButton["GetPoint_x"] = x;
		SymbButton["GetPoint_y"] = y;
	end);

	--create cooldown frame
	Symbiosis.CooldownFrame = CreateFrame("Cooldown",nil,SymbiosisButton);
	Symbiosis.CooldownFrame:SetAllPoints(SymbiosisButton);
	
	--hide button if user does not know Symbiosis spell
	if ( not IsSpellKnown(SymbiosisSpellID) ) then
		SymbiosisButton:Hide();
		return;
	end;
end;

--create own tooltip frame to check for buff hints
local function CreateTooltip()
	CreateFrame("GameTooltip","Symbiosis_Tooltip",nil,"GameTooltipTemplate"):SetOwner(WorldFrame,"ANCHOR_NONE");
end;

-----------------------------------------
--events
-----------------------------------------

--register event to check when buffs change
BuffFrame = CreateFrame("Frame");--this is local
BuffFrame:SetScript("OnEvent",function(self,event,unit)
	local name, realm = UnitName(unit);
	if not realm then
		realm = "";
	end;
	if name then
		if (name == Target["name"]) or ((name.."-"..realm) == Target["name"]) then
			CheckBuffSetTimerAndSetDuration(true);
		end;
	end;
end);

do
	local DoShow, DoHide;

	local function CheckDoShowHide(Type)
		if ( SymbConfig["TriState_" .. Type] == 0 ) then
			DoHide = true;
		elseif ( SymbConfig["TriState_" .. Type] == 1 ) then
			DoShow = true;
		end;
	end;

	--run CheckDoShowHide on all TriState-Types
	function Symbiosis.CheckToShowHideButtonFunc()
		--on login and "firstlogin" always show button
		if SymbConfig["firstlogin"] then
			return;
		end;
		
		--dont show if in petBattle
		if TempHidden then
			return;
		end;

		DoShow, DoHide = false, false;
		
		local isininstance, instancetype = IsInInstance();
		-- Returns:
		-- "none" when outside an instance
		-- "pvp" when in a battleground
		-- "arena" when in an arena
		-- "party" when in a 5-man instance
		-- "raid" when in a raid instance 
		
		--disable buff removing in arena
		if ( not InCombatLockdown() ) then
			if ( instancetype == "arena" ) then
				SymbiosisButton:SetAttribute("shift-type1","");
			elseif ( SymbConfig["DisableBuffRemove"] == false ) then
				SymbiosisButton:SetAttribute("shift-type1","cancelaura");
			end;
		end;
		
		--INSTANCE TYPES
		if isininstance then
			local _, _, size = GetInstanceInfo();
			-- Returns:
			-- 0 - None
			-- 1 - 5 Player
			-- 2 - 5 Player (Heroic)
			-- 3 - 10 Player
			-- 4 - 25 Player
			-- 5 - 10 Player (Heroic)
			-- 6 - 25 Player (Heroic)
			-- 7 - Raid Finder
			-- 8 - Challenge Mode
			-- 9 - 40 Player
			-- 10 - nil!
			-- 11 - Heroic Scenario
			-- 12 - Scenario
			-- 13 - nil!
			-- 14 - Flexible
			
			if ( size > 0 ) and ( not (instancetype == "arena") ) then--TODO: remove 2nd part of IF when: 3rd return of GetInstanceInfo() in TolVir Arena is 0 (was 1)
				CheckDoShowHide(Symbiosis.TypesForTriStateButtons[1][size] or "Outside");
			elseif ( instancetype == "arena" ) then
				CheckDoShowHide("Arena");
			elseif ( instancetype == "pvp" ) then
				CheckDoShowHide("Battleground");
			end;
		else
			CheckDoShowHide("Outside");
		end;
		
		--SPEC TYPES
		if CurSpec then
			CheckDoShowHide(Symbiosis.TypesForTriStateButtons[2][CurSpec]);
		end;
		
		--PARTYSTATUS TYPES
		if ( groupsize == "solo" ) then
			CheckDoShowHide("Solo");
		elseif ( groupsize == "party" ) then
			CheckDoShowHide("InParty");
		else
			CheckDoShowHide("InRaid");
		end;
		
		if ( groupsize ~= "solo" ) then
			if ( membercount <= 5 ) then
				CheckDoShowHide("5manGroup");
			elseif ( membercount <= 10 ) then
				CheckDoShowHide("10manGroup");
			elseif ( membercount <= 25 ) then
				CheckDoShowHide("25manGroup");
			else
				CheckDoShowHide("40manGroup");
			end;
		end;
		
		--Do Show/Hide Button
		if DoHide then
			ShowHideButton(false);
		elseif DoShow then
			ShowHideButton(true);
		end;
	end;
end;
local CheckToShowHideButtonFunc = Symbiosis.CheckToShowHideButtonFunc;

Symbiosis.CheckToShowHideFrame = CreateFrame("Frame")
Symbiosis.CheckToShowHideFrame:SetScript("OnEvent",CheckToShowHideButtonFunc);

local ZoneCheckFrame = CreateFrame("Frame");
ZoneCheckFrame:SetScript("OnEvent",CheckToShowHideButtonFunc);

local SpecChangeFrame = CreateFrame("Frame");
SpecChangeFrame:SetScript("OnEvent",function()
	CurSpec = GetSpecialization();
	if SymbiosisButton then--this gets fired before "PLAYERLOGIN" and throws an error because SymbiosisButton is not created yet
		--refresh symbiosis button icon when players changes specs
		if not ( LastSpec == CurSpec ) then
			SetSymbiosisButtonIcon();
			LastSpec = CurSpec;

			--reset possible cooldown when we change spec
			local start, dur, enabled = GetCD();
			if (enabled == 1) and (dur > 0) and (start > 0) then
				Symbiosis.CooldownFrame:SetCooldown(start,dur);
			end;
		end;

		CheckToShowHideButtonFunc();
	end;
end);

--check if Target["unit"] is still the same
local RaidChangedFrame = CreateFrame("Frame");
RaidChangedFrame:SetScript("OnEvent",function()	
	--force refresh when groupsize changes
	local Refresh = false;
	if ( (GetNumGroupMembers() ~= membercount) or (groupsize == "solo") ) and ( pop:IsVisible() ) then
		pop:Hide();
		Refresh = true;
	end;

	CheckRaidOrParty();
	
	CheckToShowHideButtonFunc();

	--get current player raidID
	if not (UnitName("player") == GetRaidRosterInfo(PlayerRaidID)) then
		for i = 1, membercount do
			if UnitName("player") == GetRaidRosterInfo(i) then
				PlayerRaidID = i;
				break;
			end;
		end;
	end;
	
	if Refresh then
		ShowPopUp();
	end;
	
	--check if Target[unit] is still correct
	if Target["unit"] and Target["GUID"] then
		local found = false;
		if (not ( Target["GUID"] == UnitGUID(Target["unit"]) )) or (not (GetRaidRosterInfo(Target["raidID"] or 0) == Target["name"])) then
			for i=1,membercount do
				if (UnitGUID(groupsize..i) == Target["GUID"]) then					
					Target["unit"] = groupsize..i;
					Target["GUID"] = UnitGUID(groupsize..i);
					Target["raidID"] = GetRaidId(Target["name"]);
					found = true;
					break;
				end;
			end;
			if found then
				if InCombatLockdown() then
					UpdateAfterCombat = true;
				else
					SetSymbiosisButton();
				end;
			elseif ( not SymbConfig["TargetConfigDontRemove"] ) then
				local name, class = Target["nameShort"] or Target["name"], Target["class"];
				Symbiosis.RemoveSymbiosisTarget();
				if ( SymbConfig["TargetConfigNotice"] ) then
					if name then
						print(L["TargetLeftParty"] .. " (|c" .. GetColor(class,true) .. name .. "|r).");
					else
						print(L["TargetLeftParty"] .. ".");
					end;
				end;
			else
				targetstring:SetText((Target["nameShort"] or Target["name"]) .. " (" .. L["NotInRaid"] .. ")");
				targetstring.Name = Target["name"];
				targetstring:Show();
				targetstring:SetTextColor(1,0,0);
			end;
		elseif InCombatLockdown() then
			UpdateAfterCombat = true;
		else
			SetSymbiosisButton();
		end;
	end;
end);

--register event so we notice when combat starts
local CheckSymbCDFrame = CreateFrame("Frame");
local CombatFrame = CreateFrame("Frame");
CombatFrame:SetScript("OnEvent",function(self,event,...)
	if event == "PLAYER_REGEN_ENABLED" then
		--do stuff when we leave combat
		if not UnitBuff("player",SymbiosisSpell) then
			local start, dur, enabled = GetSpellCooldown(SymbiosisSpellID);
			if dur > 0 then
				local CheckTime, EndTime = 0, 0;
				CheckSymbCDFrame:SetScript("OnUpdate",function(self,elapsed)
					CheckTime = CheckTime + elapsed;
					EndTime = EndTime + elapsed;
					if CheckTime > 0.5 then
						CheckTime = 0;
						start, dur, enabled = GetSpellCooldown(SymbiosisSpellID);
						if (start > 0) and (dur > 2) and (enabled == 1) then
							CheckSymbCDFrame:SetScript("OnUpdate",nil);
							Symbiosis.CooldownFrame:SetCooldown(start,dur);
						end;
					end;
					
					if EndTime > 20 then
						CheckSymbCDFrame:SetScript("OnUpdate",nil);
					end;
				end);
			end;
		end;
		
		if UpdateAfterCombat then
			UpdateAfterCombat = false;
			SetSymbiosisButton();
		end;
		
		if RemoveAfterCombat then
			RemoveAfterCombat = false;
			SymbiosisButton:SetAttribute("macrotext","");
			Symbiosis.CooldownFrame:SetCooldown(0,0);
			SetupRangeCheckOnButton(nil,true);
		end;
		
		if UpdateMacroAndAttributeAfterCombat then
			UpdateMacroAndAttributeAfterCombat = false;
			CheckMacroAndAttribute();
		end;
		
		if ShowHideAfterCombat then
			ShowHideAfterCombat = false;
			CheckToShowHideButtonFunc();
		end;
		
		if SetAttrAfterCombatForLopsided == 1 then
			SetAttrAfterCombatForLopsided = 0;
			SymbiosisButton:SetAttribute("type1","cancelaura");
			durationstring:SetText(L["BuffOnlyUpOnYou"] .. "\n(" .. L["RemoveOnClick"] .. ")");
		elseif SetAttrAfterCombatForLopsided == 2 then
			SetAttrAfterCombatForLopsided = 0;
			SymbiosisButton:SetAttribute("type1","macro");
			UpdateMacroAndAttribute(false);
		end;
	else
		--do stuff when we enter combat
		if pop:IsVisible() then
			pop:Hide();
		end;
		
		--when workaround is active and we enter combat: temp. disable it so we can use Symbiosis during the fight
		if strmatch(durationstring:GetText() or "",L["RemoveOnClick"]) then
			SetAttrAfterCombatForLopsided = 1;
			durationstring:SetText(L["BuffOnlyUpOnYou"]);
			SymbiosisButton:SetAttribute("type1","macro");
			UpdateMacroAndAttribute(false);
		end;
	end;
end);

--remind user to use Symbiosis when buff not up on ready check
local BuffReminderFrame = CreateFrame("Frame");
Symbiosis.BuffReminderFrame = BuffReminderFrame;
BuffReminderFrame:SetScript("OnEvent",function()
	if UnitBuff("player",SymbiosisSpell) or ( not SymbiosisButton:IsVisible() ) then
		return;
	end;

	local icon = " |T" .. SymbiosisIcon .. ":20|t ";
	local text = icon .. L["RdyCheckWarn"] .. icon;

	RaidNotice_AddMessage(RaidWarningFrame,text,ChatTypeInfo["RAID_WARNING"]);
end);

--code executed at login
local LoginFrame = CreateFrame("Frame")
LoginFrame:RegisterEvent("PLAYER_LOGIN")
LoginFrame:SetScript("OnEvent",function()
	--setup/create stuff
	Symbiosis.CreateGUI();
	Symbiosis.SetupSavedVars();
	CreateMainButton();
	CreateTargetString();
	Symbiosis.CreateTheMacro();
	CreatePopUpMenu();
	CreateStopDragButtons();
	CreateMemberButtons();
	CreatePopUpHeader();
	CreateGroupSlider();
	CreateTooltip();

	--popup sliders (they need to be called after MemberButtons creation)
	Symbiosis.popupIconSizerSlider:SetValue(SymbConfig["PopUp_IconSize"]);
	Symbiosis.popupSizerSlider:SetValue(SymbConfig["PopUp_Size"]);
	
	--register events to some local frames (some of which must not fire before our stuff above is created)
	RaidChangedFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
	CombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	CombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	ZoneCheckFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA");
	SpecChangeFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");

	--MASQUE support
	--create new masque group and add our SymbiosisButton to it
	if LibStub("Masque",true) then
		Symbiosis.MSQGroup = LibStub("Masque"):Group("Symbiosis");
		Symbiosis.MSQGroup:AddButton(SymbiosisButton,{ ["Icon"] = SymbiosisButton.icon, });
	end;

	--enable whisper stuff
	if SymbConfig["WhisperEnable"] then
		StartSpellCastFrame:RegisterEvent("UNIT_SPELLCAST_START");
	end;
	
	--enable readycheck-event when option is enabled
	if SymbConfig["WarnOnReadyCheck"] then
		BuffReminderFrame:RegisterEvent("READY_CHECK");
	end;

	--show/hide on login
	CheckRaidOrParty();
	CheckToShowHideButtonFunc();

	--store current specialization on login
	CurSpec = GetSpecialization();
	LastSpec = CurSpec;

	--stuff when first login
	if SymbConfig["firstlogin"] then
		SymbConfig["DragEnabled"] = true;
		ShowHideButton(true);
		SymbiosisButton:SetScript("OnDragStart",function()
			if SymbiosisButton:IsMovable() then
				SymbiosisButton:StartMoving();
			end;
		end);
		Symbiosis.DragButton:SetText(L["Lock"]);
		SymbiosisButton.StopDragButton:Show();
		print(L["Welcome"] .. " |cffFF0000" .. UnitName("player") .. "|r. " .. L["FirstLoginMessage"]);
	else
		--enable dragging when option is enabled and not first login
		if SymbConfig["DragEnabled"] then
			SymbiosisButton:SetScript("OnDragStart",function()
				if SymbiosisButton:IsMovable() then
					SymbiosisButton:StartMoving();
				end;
			end);
			Symbiosis.DragButton:SetText(L["Lock"]);
		end;
		
		print(format(L["WelcomeBack"]," |cffFF0000" .. UnitName("player") .. "|r"));
	end;
	
	--Set CD animation on Symbiosis button
	do
		local LastCheck = 0;
		local CDFrame = CreateFrame("Frame");
		CDFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
		CDFrame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET");
		CDFrame:SetScript("OnEvent",function()
			if SymbConfig["ShowGCD"] or (GetTime()-LastCheck > 1) then
				LastCheck = GetTime();
				local start, dur, enabled = GetCD();
				if (enabled == 1) and (dur > 0) and (start > 0) then
					Symbiosis.CooldownFrame:SetCooldown(start,dur);
				end;
			end;
		end);
	end;

	--if there is an active target set already: reload it
	do
		local CheckBuffOnLoadup = CreateFrame("Frame");
		local LastCheck, EndTime = 0,0;
		CheckBuffOnLoadup:SetScript("OnUpdate",function(self,elapsed)
			EndTime = EndTime + elapsed;
			LastCheck = LastCheck + elapsed;
			
			if LastCheck > 5 then
				LastCheck = 0;
				if membercount > 0 then
					for i=1,membercount do
						if not ( UnitName(groupsize..i) == UnitName("player") ) then
							if ( (select(8,UnitBuff(groupsize..i,SymbiosisSpell))) == "player" ) then
								CheckBuffOnLoadup:SetScript("OnUpdate",nil);
								ClickFunction(i,true);
							end;
						end;
					end;
				end;
			end;
			
			if EndTime > 30 then
				CheckBuffOnLoadup:SetScript("OnUpdate",nil);
			end;
		end);
	end;
end);

local TempHideFrame = CreateFrame("Frame");
TempHideFrame:RegisterEvent("PET_BATTLE_OPENING_START");
TempHideFrame:RegisterEvent("PET_BATTLE_CLOSE");
TempHideFrame:SetScript("OnEvent",function(self,event)
	if (event == "PET_BATTLE_OPENING_START") then
		if SymbiosisButton:IsVisible() then
			TempHidden = true;
			ShowHideButton(false,true);
		end;
	elseif (event == "PET_BATTLE_CLOSE") then
		if TempHidden then
			TempHidden = false;
			ShowHideButton(true,true);
		end;
	end;
end);