--only startup if player is druid 
if Symbiosis.stop then
	return
end;

local print = Symbiosis.print
local L = Symbiosis.L;

-----------------------------------------
--Slash Commands
-----------------------------------------
SLASH_SYMBIOSIS1, SLASH_SYMBIOSIS2, SLASH_SYMBIOSIS3 = "/symbiosis", "/sym", "/symb";
local function SymbiosisSlashCmd(msg,self)
	if not msg then
		return;
	end;
	
	local lowmsg = strlower(msg);
	local command, commandrest = lowmsg:match("^(%S*)%s*(.-)$");
	-- local arg1, arg1rest = commandrest:match("^(%S*)%s*(.-)$");
	-- local arg2, arg2rest = arg1rest:match("^(%S*)%s*(.-)$");

	if (command == "opt") or (command == "options") or (command == "option") or (command == "config") or (command == "configure") or (command == "cfg") or (command == "configuration") or (command == "configurations") or (command == "menu") or (command == "") then
		Symbiosis.MyOpenToCategory(Symbiosis.MainPanel);
	elseif (command == "hide") or (command == "disable") or (command == "off") then
		if InCombatLockdown() then
			print(L["CannotToggleInCombat"]);
		else
			print(L["IsNowHidden"] .. " " .. format(L["AutomationOff"],Symbiosis.DoCommand("config")));
			Symbiosis.IgnoreShowHide:SetChecked(1);
			SymbiosisButton:Hide();
		end;
	elseif (command == "show") or (command == "enable") or (command == "on") then
		if InCombatLockdown() then
			print(L["CannotToggleInCombat"]);
		else
			print(L["IsNowVisible"] .. " " .. format(L["AutomationOff"],Symbiosis.DoCommand("config")));
			Symbiosis.IgnoreShowHide:SetChecked(1);
			SymbiosisButton:Show();
		end;
	elseif (command == "toggle") then
		if InCombatLockdown() then
			print(L["CannotToggleInCombat"]);
		else
			if SymbiosisButton:IsVisible() then
				print(L["IsNowHidden"] .. " " .. format(L["AutomationOff"],Symbiosis.DoCommand("config")));
				SymbiosisButton:Hide();
			else
				print(L["IsNowVisible"] .. " " .. format(L["AutomationOff"],Symbiosis.DoCommand("config")));
				SymbiosisButton:Show();
			end;
			Symbiosis.IgnoreShowHide:SetChecked(1);
		end;
	elseif (command == "remove") then
		if (SymbiosisButton.icon:GetTexture() ~= Symbiosis.SymbiosisIcon) then
			Symbiosis.RemoveSymbiosisTarget();
			print(L["TargetRemoved"]);
		else
			print(L["NoTargetFound"]);
		end;
	elseif (command == "lock") or (command == "dragstop") or ((command == "stopdrag") and (commandrest == "")) or ((command == "drag") and (commandrest == "stop")) or ((command == "stop") and (commandrest == "drag")) then
		SymbiosisButton.StopDragButton:Hide();
		SymbiosisButton:SetScript("OnDragStart",nil);
		SymbConfig["DragEnabled"] = false;
		print(L["FrameLocked"]);
		Symbiosis.DragButton:SetText(L["Unlock"]);
	elseif (command == "stopdragpopup") or ((command == "stopdrag") and (commandrest == "popup")) or ((command == "lock") and (commandrest == "popup")) then
		Symbiosis.StopDragFunc2();
	elseif (command == "resetmacro") or (command == "macroreset") or (command == "macro" and commandrest == "reset") or (command == "reset" and commandrest == "macro") then
		SymbConfig["MacroCode"] = Symbiosis.StandardMacro;
		Symbiosis.MacroInput:SetText(SymbConfig["MacroCode"]);
		print(L["MacroRestored"]);
		Symbiosis.EditTheMacro();
	elseif (command == "reset") then
		--emergency brake for weird drag bug where we cant stop dragging
		SymbiosisButton:StopMovingOrSizing();
		
		--reset position of symbiosis button
		SymbiosisButton:ClearAllPoints();
		SymbiosisButton:SetPoint("CENTER",UIParent,"CENTER");
	elseif (command == "help") or (command == "?") then
		print(format(L["ToOpenOptUse"],Symbiosis.DoCommand("config")));
	elseif (command == "debug") and (commandrest == "pop") then--TODO: remove
		if Symbiosis.debugpop then
			Symbiosis.debugpop = false;
		else
			Symbiosis.debugpop = true;
		end;
		print("Debugpop is now"," _ ",Symbiosis.debugpop);
	else
		print(L["UnknownCommand"] .. ": '|cff5555FF" .. lowmsg .. "|r'. " .. format(L["ToOpenOptUse"],Symbiosis.DoCommand("config")));
	end;
end;
SlashCmdList["SYMBIOSIS"] = SymbiosisSlashCmd;