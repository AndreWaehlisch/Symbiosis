--only startup if player is druid 
if Symbiosis.stop then
	return;
end;

--get some globals
local print = Symbiosis.print
local L = Symbiosis.L;

--define locals
local MacroName = "CastSymbiosis001";
local CreatedMacro = true;

local function MacroText(Target)
	if Target and not (UnitBuff("player",Symbiosis.SymbiosisSpell)) then
		return gsub(SymbConfig["MacroCode"],"SYMB",Target);
	elseif Target then
		--TODO: version till '/cast [@tar] Symbiosis' bug is fixed by blizzard
		local Target = gsub(Target,"%-","\\");
		return gsub(gsub(gsub(gsub(SymbConfig["MacroCode"],"%[@SYMB%]",""),"SYMB",Target),"\n/target "..Target,""),"\\","%-");
		
		--TODO: right version
		--return gsub(gsub(SymbConfig["MacroCode"],"%[@SYMB%]",""),"SYMB",Target);
	else
		return gsub(SymbConfig["MacroCode"],"%[@SYMB%]","");
	end;
end;

--update macro on new symbiosis target
function Symbiosis.EditTheMacro()
	--dont edit macro if: user had no space to create macro / macro is disabled
	if (not CreatedMacro) or SymbConfig["DisableMacro"] then
		return;
	end;

	if ( IsAddOnLoaded("Blizzard_MacroUI") ~= 1 ) then
		LoadAddOn("Blizzard_MacroUI");
	end;

	--update macro when user leaves edit
	local SymbiosisTarget;
	if not (Symbiosis.TargetString:GetText() == L["NoTarget"]) then
		SymbiosisTarget = Symbiosis.TargetString.Name;
	end;

	local name, _, body = GetMacroInfo(MacroName);
	
	if not ( MacroText(SymbiosisTarget) == body ) then
		local WasShown = false;--update wont work if macro window is open with symbiosis macro selected
		
		if MacroFrame:IsVisible() then
			HideUIPanel(MacroFrame);
			WasShown = true;
		end;
		
		if GetMacroInfo(MacroName) then
			EditMacro(GetMacroIndexByName(MacroName),nil,nil,MacroText(SymbiosisTarget));
		end;
		
		if WasShown then
			ShowUIPanel(MacroFrame);
		end;
	end;
end;

--create macro at startup				
function Symbiosis.CreateTheMacro()
	-- fix for ElvUI_Shadow&Light taint, which prevents users from changing talents after Blizzard_MacroUI is loaded
	if SymbConfig["DisableMacro"] and ( (select(6,GetAddOnInfo("ElvUI_SLE"))) ~= "MISSING" ) then
		return;
	end;
	
	if ( IsAddOnLoaded("Blizzard_MacroUI") ~= 1 ) then
		LoadAddOn("Blizzard_MacroUI");
	end;

	if SymbConfig["DisableMacro"] then
		if GetMacroInfo(MacroName) then
			DeleteMacro(MacroName);
		end;
		
		return;
	end;
	
	if GetMacroInfo(MacroName) then
		Symbiosis.EditTheMacro();
	else
		local NumCharMacros = ( select(2,GetNumMacros()) );
		
		if NumCharMacros >= MAX_CHARACTER_MACROS then
			CreatedMacro = false;
			print(L["NotEnoughMacroSpace"]);
		else
			CreateMacro(MacroName,Symbiosis.SymbiosisMacroIcon,MacroText(),true);
		end;
	end;
end;