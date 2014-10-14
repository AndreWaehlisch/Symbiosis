--define local table
Symbiosis.L = Symbiosis.LocalsTable[strupper(GetLocale())] or Symbiosis.LocalsTable["ENUS"];
local L = Symbiosis.L;

--define print function
function Symbiosis.print(printmsg,...)
	if (type(printmsg) == "string") and (select("#",...) == 0) then
		print("|cff45FF54Symbiosis|r: " .. printmsg);
	else
		print(printmsg,...);
	end;
end;
local print = Symbiosis.print;

--define other slash command when we dont start up
local function SetupAddonDidNotStartUpSlash()
	SLASH_SYMBIOSIS1, SLASH_SYMBIOSIS2, SLASH_SYMBIOSIS3 = "/symbiosis", "/sym", "/symb";
	SlashCmdList["SYMBIOSIS"] = function()
		print(L["AddonDidNotLoadup"]);
	end;
end;

--only startup if player is druid
if ( (select(2,UnitClass("player"))) ~= "DRUID" ) then
	Symbiosis.stop = true;
	print(L["AddonDidNotLoadup"]);
	SetupAddonDidNotStartUpSlash();
	return;
else
	Symbiosis.stop = false;
end;

------------------------
----GLOBALS-------------
------------------------

--define globals
Symbiosis.SymbiosisIcon = "Interface\\Icons\\spell_druid_symbiosis";
Symbiosis.SymbiosisMacroIcon = "INV_MISC_QUESTIONMARK";
Symbiosis.SymbiosisSpellID = 110309;
Symbiosis.SymbiosisSpell = GetSpellInfo(Symbiosis.SymbiosisSpellID);
Symbiosis.ButtonSize = 50;--standard width and height of symbiosis button
Symbiosis.PopUpButtonHeight = 50;--standard height of popup member button
Symbiosis.maxmemberbuttons = 10;--number of member buttons
Symbiosis.StandardMacro = format("%s\n%s\n%s","#showtooltip " .. Symbiosis.SymbiosisSpell,"/cast [@SYMB] " .. Symbiosis.SymbiosisSpell,"/script Symbiosis.Click()");
Symbiosis.BackdropTable = {--standard layout of member buttons
							bgFile = "Interface/Tooltips/UI-Tooltip-Background",
							edgeFile = "Interface/ArenaEnemyFrame/UI-Arena-Border",
							edgeSize = 1,
};

--define global color for commands in "print" function
function Symbiosis.DoCommand(msg)
	return " '|cff08C7D1/symb " .. msg .."|r'"
end;

--define globals for key binding
Symbiosis.Key = "MACRO CastSymbiosis001";
_G["BINDING_NAME_" .. Symbiosis.Key] = L["KeyBindingname"];
_G["BINDING_HEADER_" .. "SymbiosisKeyHeader"] = "Symbiosis";

--Types for TriState Buttons (location types numbered arcording to GetInstanceDifficulty returns) (all entries must be available in L table)
Symbiosis.TypesForTriStateButtons = {
	[1] = {-- Locations
		 [0] = "Outside",
		 [1] = "5manInstance",
		 [2] = "5manInstanceHc",
		 [3] = "10manInstance",
		 [4] = "25manInstance",
		 [5] = "10manInstanceHc",
		 [6] = "25manInstanceHc",
		 [7] = "Raidfinder",
		 [8] = "ChallengeMode",
		 [9] = "40manInstance",
		[10] = "nil",
		[11] = "ScenarioHc",
		[12] = "Scenario",
		[13] = "nil",
		[14] = "Flexible",
		[15] = "Arena",
		[16] = "Battleground",
	},
	[2] = {-- Specs
		[1] = "Moonkin",
		[2] = "Feral",
		[3] = "Guardian",
		[4] = "Restoration",
	},
	[3] = {-- GroupStates
		[1] = "Solo",
		[2] = "InRaid",
		[3] = "InParty",
		[4] = "5manGroup",
		[5] = "10manGroup",
		[6] = "25manGroup",
		[7] = "40manGroup",
	},
};

------------------------
----DRUID GETS----------
------------------------
Symbiosis.SpellsGot = {
	--moonkin
	[1] = {
		["DEATHKNIGHT"] = "110570",--anti-magic shell
		["HUNTER"] = "110588",--misdirection
		["MAGE"] = "110621",--mirror image
		["MONK"] = "126458",--grapple weapon
		["PALADIN"] = "110698",--hammer of justice
		["PRIEST"] = "110707",--mass dispel
		["ROGUE"] = "110788",--cloak of shadows
		["SHAMAN"] = "110802",--purge
		["WARLOCK"] = "122291",--unending resolve
		["WARRIOR"] = "122292",--intervene
	},
	
	--feral
	[2] = {
		["DEATHKNIGHT"] = "122283",--death coil
		["HUNTER"] = "110597",--play dead
		["MAGE"] = "110693",--frost nova
		["MONK"] = "126449",--clash
		["PALADIN"] = "110700",--divine shield
		["PRIEST"] = "110715",--dispersion
		["ROGUE"] = "110730",--redirect
		["SHAMAN"] = "110807",--feral spirit
		["WARLOCK"] = "110810",--soul swap
		["WARRIOR"] = "112997",--shattering blow
	},
	
	--guardian
	[3] = {
		["DEATHKNIGHT"] = "122285",--bone shield
		["HUNTER"] = "110600",--ice trap
		["MAGE"] = "110694",--frost armor
		["MONK"] = "126453",--elusive brew
		["PALADIN"] = "110701",--consecration
		["PRIEST"] = "110717",--fear ward
		["ROGUE"] = "122289",--feint
		["SHAMAN"] = "110803",--lightning shield
		["WARLOCK"] = "122290",--life tap
		["WARRIOR"] = "113002",--spell reflection
	},
	
	--resto
	[4] = {
		["DEATHKNIGHT"] = "110575",--icebound fortitude
		["HUNTER"] = "110617",--deterrence
		["MAGE"] = "110696",--ice block
		["MONK"] = "126456",--fortifying brew
		["PALADIN"] = "122288",--cleanse
		["PRIEST"] = "110718",--leap of faith
		["ROGUE"] = "110791",--evasion
		["SHAMAN"] = "110806",--spiritwalker's grace
		["WARLOCK"] = "112970",--demonic circle: teleport
		["WARRIOR"] = "113004",--intimidating roar
	},
};

------------------------
----TARGET GETS---------
------------------------
Symbiosis.SpellsGranted = {
	["DEATHKNIGHT"] = {
		[1] = "113072",--blood: might of ursoc
		[2] = "113516",--frost: wild mushroom: plague
		[3] = "113516",--unholy: wild mushroom: plague
	},

	["HUNTER"] = {
		[1] = "113073",--all specs: dash
		[2] = "113073",
		[3] = "113073",
	},
	
	["MAGE"] = {
		[1] = "113074",--all specs: healing touch
		[2] = "113074",
		[3] = "113074",
	},
	
	["MONK"] = {
		[1] = "113306",--brewmaster: survival instincts
		[2] = "113275",--mistweaver: entangling roots
		[3] = "127361",--windwalker: bear hug
	},

	["PALADIN"] = {
		[1] = "113269",--holy: rebirth
		[2] = "113075",--prot: barkskin
		[3] = "122287",--retri: wrath
	},
	
	["PRIEST"] = {
		[1] = "113506",--diszi: cyclone
		[2] = "113506",--holy: cyclone
		[3] = "113277",--shadow: tranquility
	},
	
	["ROGUE"] = {
		[1] = "113613",--all specs: growl
		[2] = "113613",
		[3] = "113613",
	},
	
	["SHAMAN"] = {
		[1] = "113287",--ele: solar beam
		[2] = "113287",--enhance: solar beam
		[3] = "113289",--resto: prowl
	},
	
	["WARLOCK"] = {
		[1] = "113295",--all specs: rejuvenation
		[2] = "113295",
		[3] = "113295",
	},
	
	["WARRIOR"] = {
		[1] = "122294",--fury+arms: stampeding shout
		[2] = "122294",
		[3] = "122286",--prot: savage defense
	},
};

--Spec Icon Table for info panel (add "Interface\\Icons\\" to get full path)
Symbiosis.SpecIcons = {
	["DEATHKNIGHT"] = {
		[1] = "Spell_Deathknight_BloodPresence",
		[2] = "Spell_Deathknight_FrostPresence",
		[3] = "Spell_Deathknight_UnholyPresence",
	},

	["HUNTER"] = {
		[1] = "ability_hunter_bestialdiscipline",
		[2] = "Ability_Hunter_FocusedAim",
		[3] = "ability_hunter_camouflage",
	},
	
	["MAGE"] = {
		[1] = "Spell_Holy_MagicalSentry",
		[2] = "Spell_Fire_FireBolt02",
		[3] = "Spell_Frost_FrostBolt02",
	},
	
	["MONK"] = {
		[1] = "spell_monk_brewmaster_spec",
		[2] = "spell_monk_mistweaver_spec",
		[3] = "spell_monk_windwalker_spec",
	},

	["PALADIN"] = {
		[1] = "Spell_Holy_HolyBolt",
		[2] = "Ability_Paladin_ShieldoftheTemplar",
		[3] = "Spell_Holy_AuraOfLight",
	},
	
	["PRIEST"] = {
		[1] = "Spell_Holy_PowerWordShield",
		[2] = "Spell_Holy_GuardianSpirit",
		[3] = "Spell_Shadow_ShadowWordPain",
	},
	
	["ROGUE"] = {
		[1] = "Ability_Rogue_Eviscerate",
		[2] = "Ability_Backstab",
		[3] = "Ability_Stealth",
	},
	
	["SHAMAN"] = {
		[1] = "Spell_Nature_Lightning",
		[2] = "Spell_Nature_LightningShield",
		[3] = "Spell_Nature_MagicImmunity",
	},
	
	["WARLOCK"] = {
		[1] = "Spell_Shadow_DeathCoil",
		[2] = "Spell_Shadow_Metamorphosis",
		[3] = "Spell_Shadow_RainOfFire",
	},
	
	["WARRIOR"] = {
		[1] = "Ability_Warrior_SavageBlow",
		[2] = "Ability_Warrior_InnerRage",
		[3] = "Ability_Warrior_DefensiveStance",
	},
};

--Spec Names (localized) for info panel
Symbiosis.SpecNames = {
	["DEATHKNIGHT"] = {
		[1] = L["Blood"],
		[2] = L["Frost"],
		[3] = L["Unholy"],
	},
	
	["HUNTER"] = {
		[1] = L["BeastMastery"],
		[2] = L["Marksmanship"],
		[3] = L["Survival"],
	},
	
	["MAGE"] = {
		[1] = L["Arcane"],
		[2] = L["Fire"],
		[3] = L["Frost"],
	},
	
	["MONK"] = {
		[1] = L["Brewmaster"],
		[2] = L["Mistweaver"],
		[3] = L["Windwalker"],
	},

	["PALADIN"] = {
		[1] = L["Holy"],
		[2] = L["Protection"],
		[3] = L["Retribution"],
	},
	
	["PRIEST"] = {
		[1] = L["Discipline"],
		[2] = L["Holy"],
		[3] = L["Shadow"],
	},
	
	["ROGUE"] = {
		[1] = L["Assassination"],
		[2] = L["Combat"],
		[3] = L["Subtlety"],
	},
	
	["SHAMAN"] = {
		[1] = L["Elemental"],
		[2] = L["Enhancement"],
		[3] = L["Restoration"],
	},
	
	["WARLOCK"] = {
		[1] = L["Affliction"],
		[2] = L["Demonology"],
		[3] = L["Destruction"],
	},
	
	["WARRIOR"] = {
		[1] = L["Arms"],
		[2] = L["Fury"],
		[3] = L["Protection"],
	},
};

--non-localized collection of class names, in alphab. order (druid not present). don't leave any index empty: ipairs
Symbiosis.ClassNames = {
	[1] = "DEATHKNIGHT",
	[2] = "HUNTER",
	[3] = "MAGE",
	[4] = "MONK",
	[5] = "PALADIN",
	[6] = "PRIEST",
	[7] = "ROGUE",
	[8] = "SHAMAN",
	[9] = "WARLOCK",
	[10] = "WARRIOR",
};

--names of all druid specs as used in the spell info panel (used with ipairs)
Symbiosis.DruidSpecNames = {
	[1] = "Moonkin",
	[2] = "Feral",
	[3] = "Guardian",
	[4] = "Resto",
};

--band aid fix for blizzards InterfaceOptionsFrame_OpenToCategory bugs (intern use only - calls from other addons are not fixed)
--bug1: calling InterfaceOptionsFrame_OpenToCategory for the first time after reload will throw you to the category list, not the addon list
--bug2: if the panel you want to open is not visible with the current scroll value the InterfaceOptionsFrame_OpenToCategory call does nothing
local function PanelNameIsVisible(Frame)
	for i = 1, 31 do
		if _G["InterfaceOptionsFrameAddOnsButton"..i] then
			if _G["InterfaceOptionsFrameAddOnsButton"..i]:GetText() == Frame.name then
				InterfaceOptionsFrame_OpenToCategory(Frame);
				return true;
			end;
		end;
	end;
	
	return false;
end;

function Symbiosis.MyOpenToCategory(Frame)
	InterfaceOptionsFrame_OpenToCategory(Frame);
	InterfaceOptionsFrame_OpenToCategory(Frame);
	
	if not Frame:IsVisible() then
		InterfaceOptionsFrame_OpenToCategory(Frame);
	end;

	if not PanelNameIsVisible(Frame) then
		local i = 0;--hard bail out
		local scrollbar = InterfaceOptionsFrameAddOnsListScrollBar;
		local value = 0;
		
		repeat
			i = i + 1;

			FauxScrollFrame_OnVerticalScroll(scrollbar:GetParent(), value, InterfaceOptionsFrameAddOns.buttonHeight, OptionsListScroll_Update);
			value = scrollbar:GetValue()+scrollbar:GetValueStep();
		until (PanelNameIsVisible(Frame)) or (i > 100);
	end;
end;