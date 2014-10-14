--only startup if player is druid
if Symbiosis.stop then
	return;
end;

function Symbiosis.SetupSavedVars()
	--returns true if var is NOT desired type
	local function CheckVar(var,desiredtype)
		if ( type(var) == desiredtype ) then
			return false;
		elseif ( ((var == 0) or (var == 1) or (var == false)) and (desiredtype == "tristate") ) then
			return false;
		else
			return true;
		end;
	end;

	--for Config table
	local function CheckVarAndSetCheckBox(ConfigEntry,myType,CheckBox)
		if CheckVar(SymbConfig[ConfigEntry],myType) then
			if ( myType == "tristate" ) then
				SymbConfig[ConfigEntry] = false;
			else
				if CheckBox:GetChecked() == 1 then
					SymbConfig[ConfigEntry] = true;
				else
					SymbConfig[ConfigEntry] = false;
				end;
			end;
		else
			if ( myType == "tristate" ) then
				CheckBox.state = SymbConfig[ConfigEntry];
				Symbiosis.SetTriState(CheckBox);
			else
				CheckBox:SetChecked(SymbConfig[ConfigEntry]);
			end;
		end;
	end;

	-----------------------------------------
	--Config
	-----------------------------------------
	if CheckVar(SymbConfig,"table") then
		SymbConfig = {};
	end;

	--first login
	if CheckVar(SymbConfig["firstlogin"],"boolean") then
		SymbConfig["firstlogin"] = true;
	end;

	--drag
	if CheckVar(SymbConfig["DragEnabled"],"boolean") then
		SymbConfig["DragEnabled"] = false;
	end;

	--Main Panel
		--position of popup
		if	(
			( CheckVar(SymbConfig["Pop_GetPoint_pos1"],"string") )
		or	( CheckVar(SymbConfig["Pop_GetPoint_pos2"],"string") )
		or	( CheckVar(SymbConfig["Pop_GetPoint_x"],"number") )
		or	( CheckVar(SymbConfig["Pop_GetPoint_y"],"number") ) 
			) then
			--no/false position stored. we use standard location which is called when pos1 is nil
			SymbConfig["Pop_GetPoint_pos1"] = nil;
		end;
		
		--position of refresh button on popup
		if (
			( CheckVar(SymbConfig["Refresh_GetPoint_pos1"],"string") )
		or ( CheckVar(SymbConfig["Refresh_GetPoint_pos2"],"string") )
		or ( CheckVar(SymbConfig["Refresh_GetPoint_x"],"number") )
		or ( CheckVar(SymbConfig["Refresh_GetPoint_y"],"number") ) 
		) then
			--no/false position stored. we use standard location which is called when pos1 is nil
			SymbConfig["Refresh_GetPoint_pos1"] = nil;
		end;
		
		--left side
		CheckVarAndSetCheckBox("TargetConfigDontRemove","boolean",Symbiosis.TargetConfigDontRemove);
		CheckVarAndSetCheckBox("TargetConfigNotice","boolean",Symbiosis.TargetConfigNotice);
		CheckVarAndSetCheckBox("DisableBuffRemove","boolean",Symbiosis.DisableBuffRemove);
		CheckVarAndSetCheckBox("WarnOnReadyCheck","boolean",Symbiosis.WarnOnReadyCheck);
		CheckVarAndSetCheckBox("ShortenNames","boolean",Symbiosis.ShortenNames);
		
		if SymbConfig["TargetConfigDontRemove"] then
			Symbiosis.TargetConfigNotice:Disable();
		end;
		
		--right side
		CheckVarAndSetCheckBox("RemoveNoTargetTag","boolean",Symbiosis.RemoveNoTargetTag);
		CheckVarAndSetCheckBox("ShowGCD","boolean",Symbiosis.ShowGCD);
		CheckVarAndSetCheckBox("ShowHeader","boolean",Symbiosis.ShowHeader);
		CheckVarAndSetCheckBox("DisableRangeIndicator","boolean",Symbiosis.DisableRangeIndicator);
		CheckVarAndSetCheckBox("DisableMainTooltip","boolean",Symbiosis.DisableMainTooltip);
		CheckVarAndSetCheckBox("EnableLopsidedWorkaround","boolean",Symbiosis.EnableLopsidedWorkaround);
		CheckVarAndSetCheckBox("ForceNormalColors","boolean",Symbiosis.ForceNormalColors);
		
		if SymbConfig["DisableRangeIndicator"] then
			Symbiosis.ForceNormalColors:Disable();
		end;
	--Whisper Panel
	CheckVarAndSetCheckBox("WhisperEnable","boolean",Symbiosis.WhisperEnable);

	if not SymbConfig["WhisperEnable"] then
		Symbiosis.WhisperEnable:GetScript("OnClick")();
	end;

	CheckVarAndSetCheckBox("WhisperAddGrant","boolean",Symbiosis.WhisperPanelAddGrant);
	CheckVarAndSetCheckBox("WhisperAddGet","boolean",Symbiosis.WhisperPanelAddGet);
	CheckVarAndSetCheckBox("FullWhispOnlyOnFirst","boolean",Symbiosis.FullWhispOnlyOnFirst);
	CheckVarAndSetCheckBox("DisableWhispArena","boolean",Symbiosis.DisableWhispArena);

	if ( not SymbConfig["WhispLang"] ) or ( not Symbiosis.LocalsTable[SymbConfig["WhispLang"]] ) then
		if Symbiosis.LocalsTable[strupper(GetLocale())] then
			SymbConfig["WhispLang"] = strupper(GetLocale());
		else
			SymbConfig["WhispLang"] = "ENUS";
		end;
	end;
	Symbiosis_WhispLangEdit:SetText(_G[SymbConfig["WhispLang"]]);
	Symbiosis_WhispLangEdit:SetCursorPosition(0);

	local WhisperList = Symbiosis.GetWhisperMessage(1,"PALADIN");
	local WhisperText = WhisperList[1];
	if WhisperList[2] then
		WhisperText = WhisperText .. "\n" .. WhisperList[2];
	end;
	Symbiosis.WhisperPanelTestWhisperString:SetText(WhisperText);

	--Show/Hide Panel
	local EnabledOnDefault = { "Moonkin", "Feral", "Guardian", "Restoration", }
	for _, State in pairs(EnabledOnDefault) do
		if CheckVar(SymbConfig["TriState_" .. State],"tristate") then
			SymbConfig["TriState_" .. State] = 1;
		end;
	end;

	for Type, Checkbox in pairs(Symbiosis.UITriStateCheckboxes) do
		CheckVarAndSetCheckBox("TriState_" .. Type,"tristate",Checkbox);
	end;

	--Macro Panel
	if CheckVar(SymbConfig["MacroCode"],"string") then
		SymbConfig["MacroCode"] = Symbiosis.StandardMacro;
	end;

	Symbiosis.MacroInput:SetText(SymbConfig["MacroCode"]);
	
	CheckVarAndSetCheckBox("DisableMacro","boolean",Symbiosis.DisableMacro);
	
	if SymbConfig["DisableMacro"] then
		Symbiosis.MacroPanelContainer:Hide();
	end;

	--SpellInfo1 panel
	if CheckVar(SymbConfig["SpellInfoCfg"],"table") or CheckVar(SymbConfig["SpellInfoCfg"]["Prioritize"],"table") or CheckVar(SymbConfig["SpellInfoCfg"]["Ignore"],"table") then
		SymbConfig["SpellInfoCfg"] = {};
		SymbConfig["SpellInfoCfg"]["Prioritize"] = {};
		SymbConfig["SpellInfoCfg"]["Ignore"] = {};
		
		for i, SpecName in ipairs(Symbiosis.DruidSpecNames) do
			SymbConfig["SpellInfoCfg"]["Prioritize"][SpecName] = {};
			SymbConfig["SpellInfoCfg"]["Ignore"][SpecName] = {};
		end;
	end;
	
	for i, SpecName in ipairs(Symbiosis.DruidSpecNames) do
		for TargetClass, SpellId in pairs(Symbiosis.SpellsGot[i]) do
			Symbiosis["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass]:SetChecked(SymbConfig["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass]);
			
			if SymbConfig["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass] then
				Symbiosis["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass]:SetChecked(true);
				Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(0,1,0);
			end;
			
			if SymbConfig["SpellInfoCfg"]["Ignore"][SpecName][TargetClass] then
				Symbiosis["SpellInfoCfg"]["Ignore"][SpecName][TargetClass]:SetChecked(true);
				Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellIcon:SetDesaturated(1);
				Symbiosis["SpellInfoCfg"][SpecName][TargetClass].spellLabel:SetTextColor(.5,.5,.5);
				Symbiosis["SpellInfoCfg"]["Prioritize"][SpecName][TargetClass]:Hide();
			end;
		end;
	end;
	
	--PopUp Panel
	CheckVarAndSetCheckBox("DontShowUnitOffline","boolean",Symbiosis.DontShowUnitOffline);
	CheckVarAndSetCheckBox("DontShowUnitStolen","boolean",Symbiosis.DontShowUnitStolen);
	CheckVarAndSetCheckBox("DontShowUnitDead","boolean",Symbiosis.DontShowUnitDead);
	CheckVarAndSetCheckBox("DontShowUnitInsignificant","boolean",Symbiosis.DontShowUnitInsignificant);

	-----------------------------------------
	--Button
	-----------------------------------------
	if CheckVar(SymbButton,"table") then
		SymbButton = {};
	end;

	if	(
		( CheckVar(SymbButton["GetPoint_pos1"],"string") )
	or	( CheckVar(SymbButton["GetPoint_pos2"],"string") )
	or	( CheckVar(SymbButton["GetPoint_x"],"number") )
	or	( CheckVar(SymbButton["GetPoint_y"],"number") ) 
		) then
		--no/false/standard position stored. create default
		SymbButton["GetPoint_pos1"] = "CENTER";
		SymbButton["GetPoint_pos2"] = "CENTER";
		SymbButton["GetPoint_x"] = 0;
		SymbButton["GetPoint_y"] = 0;
	end;

	local function my_tonumber(input)
		return tonumber(input) or 0;
	end;
	
	if CheckVar(SymbButton["Size"],"number") then
		SymbButton["Size"] = 100;
	else
		if ( SymbButton["Size"] > my_tonumber(Symbiosis.SizerSlider.high:GetText()) ) or ( SymbButton["Size"] < my_tonumber(Symbiosis.SizerSlider.low:GetText()) ) then
			SymbButton["Size"] = 100;
		end;
	end;--the actual sizing of the button is done at CreateMainButton() in SymbiosisButton.lua
	
	if CheckVar(SymbConfig["PopUp_Size"],"number") then
		SymbConfig["PopUp_Size"] = 100;
	else
		if ( SymbConfig["PopUp_Size"] > my_tonumber(Symbiosis.popupSizerSlider.high:GetText()) ) or ( SymbConfig["PopUp_Size"] < my_tonumber(Symbiosis.popupSizerSlider.low:GetText()) ) then
			SymbConfig["PopUp_Size"] = 100;
		end;
	end;--the actual sizing of the popup is done at the PLAYER_LOGIN event in SymbiosisButton.lua
	
	if CheckVar(SymbConfig["PopUp_IconSize"],"number") then
		SymbConfig["PopUp_IconSize"] = 100;
	else
		if ( SymbConfig["PopUp_IconSize"] > my_tonumber(Symbiosis.popupIconSizerSlider.high:GetText()) ) or ( SymbConfig["PopUp_IconSize"] < my_tonumber(Symbiosis.popupIconSizerSlider.low:GetText()) ) then
			SymbConfig["PopUp_IconSize"] = 100;
		end;
	end;--the actual sizing of the popup icons is done at the PLAYER_LOGIN event in SymbiosisButton.lua
	
	if CheckVar(SymbConfig["Refreshbutton_Size"],"number") then
		SymbConfig["Refreshbutton_Size"] = 40;
	elseif ( SymbConfig["Refreshbutton_Size"] < 20 ) or ( SymbConfig["Refreshbutton_Size"] > 100 ) then
		SymbConfig["Refreshbutton_Size"] = 40;
	end;--the actual sizing of the popup icons is done at CreateRefreshButton() in SymbiosisButton.lua
	
	local Media = LibStub("LibSharedMedia-3.0");

	if CheckVar(SymbButton["PopUpBgFile"],"string") then
		SymbButton["PopUpBgFile"] = "SymbiosisStandard";
	end;
	
	--reset if saved file is a path (since v0.27 the name of the media is used)
	if ( select(2,gsub(SymbButton["PopUpBgFile"],"\\",1)) ) > 1 then
		SymbButton["PopUpBgFile"] = "SymbiosisStandard";
	end;
	
	if Media:IsValid("statusbar",SymbButton["PopUpBgFile"]) then
		Symbiosis.BackdropTable["bgFile"] = Media:HashTable("statusbar")[SymbButton["PopUpBgFile"]];
	else
		Symbiosis.BackdropTable["bgFile"] = SymbButton["PopUpBgFile"];
	end;
	Symbiosis_PopUpMediaEdit:SetText(Media:List("statusbar")[Symbiosis.FindNumOfCurBackground()]);
	Symbiosis_PopUpMediaEdit:SetCursorPosition(0);

	if CheckVar(SymbButton["Transparency"],"number") then
		SymbButton["Transparency"] = 0.95;
	else
		if (SymbButton["Transparency"] < 0) or (SymbButton["Transparency"] > 1) then
			SymbButton["Transparency"] = 0.95;
		end;
	end;

	if CheckVar(SymbButton["BorderSize"],"number") then
		SymbButton["BorderSize"] = 2;
	else
		if (SymbButton["BorderSize"] < 0) or (SymbButton["BorderSize"] > 40) then
			SymbButton["BorderSize"] = 2;
		end;
	end;
	
	if CheckVar(SymbButton["BorderFile"],"string") then
		SymbButton["BorderFile"] = "SymbiosisStandard";
	end;
	
	if Media:IsValid("border",SymbButton["BorderFile"]) then
		Symbiosis.BackdropTable["edgeFile"] = Media:HashTable("border")[SymbButton["BorderFile"]];
	else
		Symbiosis.BackdropTable["edgeFile"] = SymbButton["BorderFile"];
	end;
	
	-----------------
	-----------------
	--When saved Media file names are not yet loaded: Recheck when a new file is added to SharedMedia
	local function MediaLoaded(onLoadUp)
		if onLoadUp then
			--check if files were present on loadup
			return not ( (Symbiosis.BackdropTable["bgFile"] == SymbButton["PopUpBgFile"]) or (Symbiosis.BackdropTable["edgeFile"] == SymbButton["BorderFile"]) );
		else
			--check if files are currently present
			return ( Media:IsValid("statusbar",SymbButton["PopUpBgFile"]) and Media:IsValid("border",SymbButton["BorderFile"]) );
		end;
	end;
	
	local MediaFilesAlreadyLoaded = MediaLoaded(true);

	if not MediaFilesAlreadyLoaded then	
		function Symbiosis.LibSharedMedia_Registered()
			if (not MediaFilesAlreadyLoaded) then
				if MediaLoaded() then
					Symbiosis.ScrollToCurBorder();
					Symbiosis.BackdropTable["bgFile"] = Media:HashTable("statusbar")[SymbButton["PopUpBgFile"]];
					MediaFilesAlreadyLoaded = true;
				end;
			end;
		end;
		
		Media.RegisterCallback(Symbiosis,"LibSharedMedia_Registered");
	end;
	-----------------
	-----------------
	
	CheckVarAndSetCheckBox("HideMainBorder","boolean",Symbiosis.HideMainBorder);
end;