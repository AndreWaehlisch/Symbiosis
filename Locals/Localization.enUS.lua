--found mistake or missing translation? go to http://wow.curseforge.com/addons/symbiosis/localization/ to fix it.

--define global table
Symbiosis = {};

Symbiosis.LocalsTable = {};

Symbiosis.LocalsTable["ENUS"] = {
	--in more than one
	["FrameLocked"] = "Frame is locked again.",
	["Unlock"] = "Unlock",
	["Lock"] = "Lock",

	["Stolen"] = "Stolen",
	["Dead"] = "Dead",
	["Size"] = "Size",
	["IsNowVisible"] = "Symbiosis button is now visible.",
	["IsNowHidden"] = "Symbiosis button is now hidden.",
	["AutomationOff"] = "Automation of show/hide stuff is now disabled. Go to the config (%s) to reenable it.",

	--SymbiosisBindingMacro.lua
	["NotEnoughMacroSpace"] = "You've not enough space to create a new character macro. Delete one and /reload your UI to try again.",

	--SymbiosisGlobales.lua
	["KeyBindingname"] = "Simulate Click on Symbiosis button",
	["AddonDidNotLoadup"] = "Addon did not load up because you are no druid.",
	--SpecNames
	["Blood"] = "Blood",
	["Frost"] = "Frost",
	["Unholy"] = "Unholy",
	["BeastMastery"] = "Beast Mastery",
	["Marksmanship"] = "Marksmanship",
	["Survival"] = "Survival",
	["Arcane"] = "Arcane",
	["Fire"] = "Fire",
	["Brewmaster"] = "Brewmaster",
	["Mistweaver"] = "Mistweaver",
	["Windwalker"] = "Windwalker",
	["Holy"] = "Holy",
	["Protection"] = "Protection",
	["Retribution"] = "Retribution",
	["Discipline"] = "Discipline",
	["Shadow"] = "Shadow",
	["Assassination"] = "Assassination",
	["Combat"] = "Combat",
	["Subtlety"] = "Subtlety",
	["Elemental"] = "Elemental",
	["Enhancement"] = "Enhancement",
	["Restoration"] = "Restoration",
	["Affliction"] = "Affliction",
	["Demonology"] = "Demonology",
	["Destruction"] = "Destruction",
	["Arms"] = "Arms",
	["Fury"] = "Fury",

	--SymbiosisSlashCommands.lua
	["TargetRemoved"] = "Target removed.",
	["NoTargetFound"] = "No target found.",
	["ToOpenOptUse"] = "To open the option menu use %s.",
	["UnknownCommand"] = "Unknown command",
	["MacroRestored"] = "Macro was restored to standard.",
	["CannotToggleInCombat"] = "Cannot toggle status of the Symbiosis button in combat.",

	--SymbiosisButton.lua
	["Minutes_Short"] = "Min",
	["Seconds_Short"] = "Sec",
	["BuffNotUp"] = "Buff not up",
	["TargetStolen"] = "Target stolen",
	["BuffIsUp"] = "Buff is up",
	["NoTarget"] = "No Target",
	["YouDontKnowSymbiosis"] = "You do not know the Symbiosis spell.",
	["RemovedBuff"] = "Removed Symbiosis buff because you shift-left-clicked the Symbiosis button.",
	["ClickedForFirstTime"] = "You just clicked the Symbiosis button for the first time. Right-click the button while in a party to select a target for Symbiosis.",
	["Disconnect_Short"]= "d/c",
	["Buffed"] = "Buffed",
	["FilterRemovedAll"] = "Your filters removed all targets.",
	["NotInParty"] = "Not in party",
	["NotInRaid"] = "not in raid",
	["TargetLeftParty"] = "Your Symbiosis target left the party",
	["Welcome"] = "Welcome",--TODO: implement format
	["FirstLoginMessage"] = "This is your first login with this addon. Drag the Symbiosis button (square thing in the middle of your screen) to where ever you like and hit the 'Lock' button above it.",
	["WelcomeBack"] = "Enabled. Welcome back %s.",
	["HeaderText"] = "Target list:",
	["RdyCheckWarn"] = "Symbiosis buff not up!",
	["HeaderSpellGet"] = "Spell you get from other players:",
	["HeaderSpellGrant"] = "Spell granted to other players:",
	["ErrorIconTooltip"] = "Fetching data...",
	["BuffOnlyUpOnYou"] = "buff only up on you",
	["RemoveOnClick"] = "remove on click",
	["Refresh"] = "Refresh",
	["NotInRangeIconTooltip"] = "Cannot retrieve talent data: Unit is too far away.",

	--SymbiosisGUI.lua
		--whisper
		["YouHaveSymbiosis"] = "You have %s now!",
		["YouGrantedMe"] = "You granted me %s.",--[MUST NOT BE LONGER THAN 255 CHARS]
		["YoullGet"] = "You will get %s.",--[MUST NOT BE LONGER THAN 255 CHARS]

		--main panel
		["Options"] = "options",
		["OutsideTooltip"] = "Everything non instanced is considered 'outside'.",--TODO: depricated?
		["DontShowTaggedAs"] = "Don't show units tagged as...",
		["Offline"] = "Offline",
		["UnitHasOther"] = "Unit has Symbiosis buff from other druid.",
		["InInsignificantGroup"] = "In insignificant Group",
		["InInsignificantGroupTooltip"] = "If this options is enabled only people in group 1 to X will be listed as possible Symbiosis targets, where X is based on currently selected raid size. So for 10 man raid only group 1 and 2 will be listed and for 25 man raid the first 5 groups. To scan all 8 groups disable this option.",
		["ChangeSizeButton"] = "Change size of Symbiosis button",
		["Done"] = "Done",
		["LockUnlockButton"] = "Locks/unlocks the Symbiosis Button.",
		["LockUnlockPopUp"] = "Locks/unlocks the Symbiosis popup.",
		["Unlocked"] = "Unlocked. To stop dragging hit the 'Lock' button or type the following:",
		["ResetPosition_Short"] = "Reset Pos.",
		["ResetPositionTooltip"] = "Reset position of Symbiosis button to screen center.",
		["PrintMessageWhenTarLeaves"] = "Print message when target leaves raid",
		["DontRemoveTarget"] = "Don't remove target if target leaves raid",
		["DontRemoveTargetTooltip"] = "You wont be able to cast Symbiosis on selected target unless target rejoins raid. This option may be usefull for arena/battleground groups.",
		["DisableShiftClick"] = "Disable shift-left-click on Symbiosis button",
		["DisableShiftClickTooltip"] = "A shift-left-click on the Symbiosis button removes the current Symbiosis buff.",
		["ChangeSize"] = "Change size",
		["TargetConfig"] = "Target Config",
		["ButtonConfig"] = "Button Config",
		["ShowGCD"] = "Show GCD",
		["ShowGCDTooltip"] = "If enable will show the global cooldown on Symbiosis button.",
		["ShowHeader"] = "Show header",
		["ShowHeaderTooltip"] = "When enabled a header will be shown above the popup list, explaining which spell the player gets and which spell is granted to other players.",
		["WarnOnRdyCheck"] = "Warn on Ready Check",
		["DontDisplayRealms"] = "Do not display realms on unit names",
		["WarnOnRdyCheckTooltip"] = "If enabled will show a text warning in the middle of the screen when Symbiosis buff is not up on ready check.",
		["DisableRangeIndication"] = "Disable range indication",
		["DisableRangeIndicationTooltip"] = "The Symbiosis button will turn red when the current 'target' is not in range. When Symbiosis buff is not up: 'Target' will be selected Symbiosis target (as shown on button). When buff is up: 'Target' will be your normal current target.",
		["DisableMainTooltip"] = "Disable main tooltip",
		["EnableWorkaround"] = "Enable workaround for lopsided state",
		["EnableWorkaroundTooltip"] = "'Lopsided state' is a bug, which must be fixed by Blizzard: Sometimes only you have Symbiosis buff up, but your target does not. When workaround is enabled you may (left)click to remove your current buff, while out of combat.",
		["ForceNormalColors"] = "Force Normal Colors",
		["ForceNormalColorsTooltip"] = "Innately the button has these different states: 'Normal' color: You can cast Symbiosis on target. 'Red': Target is in same zone as you, but out of range to receive Symbiosis. 'Gray': Target is in different zone as you. You may enable this option if you like the standard coloring better, which is just 'red' and 'normal color'.",
		["Test"] = "Test",
		["ChangeSizePopup"] = "Change size of popup",
		["ChangeSizePopupIcons"] = "Change size of popup icons",
		
		--Show/hide panel
		["ShowHideOptions"] = "show/hide options. Symbiosis button will be shown/hidden based on selected options here. If at least one state evaluates to 'Disabled' button will be hidden.",
		["ShowHide"] = "Show/Hide",
		["TriStateTooltip"] = "Changing this option will decide if the Symbiosis button will be automatically shown or hidden:",
		["Enabled"] = "Enabled",
		["Disabled"] = "Disabled",
		["IgnoredUnchecked"] = "Ignored (unchecked)",
		["WillShow"] = "Will show button in/as %s.",
		["WillHide"] = "Will hide button in/as %s.",
		["WillIgnore"] = "Will not change status of Symbiosis button in/as %s.",
		["IgnoreShowHide"] = "Disable show/hide",
		["IgnoreShowHideTooltip"] = "This will be enabled by calling '/symb show' and '/symb hide'. This option is not saved between sessions.",
		["5manInstance"] = "5man instance",
		["5manInstanceHc"]= "5man instance heroic",
		["10manInstance"] = "10man instance",
		["10manInstanceHc"]= "10man instance heroic",
		["25manInstance"] = "25man instance",
		["25manInstanceHc"] = "25man instance heroic",
		["40manInstance"] = "40man instance",
		["InRaid"] = "In raid",
		["InParty"] = "In party",
		["Solo"] = "Solo",
		["Raidfinder"] = "Raid finder",
		["ChallengeMode"] = "Challenge Modes",
		["5manGroup"] = "5man group",
		["10manGroup"] = "10man group",
		["25manGroup"] = "25man group",
		["40manGroup"] = "40man group",
		["Outside"] = "Outside",
		["Arena"] = "Arena",
		["Battleground"] = "Battleground",
		["Moonkin"] = "Moonkin",
		["Feral"] = "Feral",
		["Guardian"] = "Guardian",
		["Resto"] = "Resto",
		["Scenario"] = "Scenario",
		["ScenarioHc"] = "Scenario heroic",
		["Flexible"] = "Flexible",

		--whisper panel
		["Whisper"] = "Whisper",
		["WhisperOptions"] = "whisper options",
		["EnableTargetWhisper"] = "Enable target whisper",
		["LongWhisperHint"] = "When you cast Symbiosis your target may receive a whisper from you with this option. A Symbiosis-target must be selected beforehand for this to work. Delay between two whispers is 1 minute, to prevent spam.",
		["TestMessage"] = "Test Message:",
		["AddSpellsGranted"] = "Add spell granted to the target",
		["AddSpellsGet"] = "Add spell granted to you",
		["FullWhispOnlyOnFirst"] = "Full whisper message only on first whisper",
		["FullWhispOnlyOnFirstTooltip"] = "On consecutives whispers only a simplified message will be send.",
		["DisableWhispArena"] = "Disable whispers in arena",
		["SelectLanguage"] = "Select language:",
		["WhisperLanguage"] = "Whisper language",
		["Close"] = "Close",
		
		--spell info panel
		["SpellsGet"] = "Spells Get",
		["SpellsGrant"] = "Spells Grant",
		["ListOfSpellsGet"] = "Above is a list of all spells you can get when you cast Symbiosis on a specific class.",
		["ListOfSpellsGrant"] = "Above is a list of all spells other players can get when you cast Symbiosis on them.",
		["SpellYouGetDepends"] = "The spell you get does not depend on the spec your target has, only on your spec.",
		["SpellGrantDepends"] = "The spell they get only depends on their spec, not on yours.",
		["AllDPSGainSame"] = "All DPS specs of one class get the same spell.",
		["Ignore"] = "ignore",
		["OnTop"] = "on top",
		["ClassesMarkedAsTop"] = "Classes marked as 'on top' will be placed on top of the popup list, classes marked as 'ignore' will not be added to the list.",
		
		
		--macro panel
		["Macro"] = "Macro",
		["Reset"] = "Reset",
		["MacroOptions"] = "macro options (for advanced users)",
		["MacroOptions_Short"] = "Macro (adv.)",
		["ResetMacro"] = "Restore standard macro code.",
		["ConfirmResetMacro"] = "To reset macro code type the following:",
		["LongMacroHint1"] = "Symbiosis provides a key binding for you, you can assign it in the standard key bindings.",
		["LongMacroHint2"] = "Everytime you hit the assigned key the macro above will be fired.",
		["LongMacroHint3"] = "You can edit that macro only here.",
		["LongMacroHint4"] = "Use the following dummy for your Symbiosis target, everytime you select a new Symbiosis target the macro will be updated automatically:",
		["LongMacroHint5"] = "So the following example line will always cast Symbiosis on your selected target:",
		["LongMacroHint6"] = "You should always include the following script, which handles some whisper stuff and displays the cooldown of Symbiosis:",
		["LongMacroHint7"] = "Note: If you don't have selected a Symbiosis target or the Symbiosis buff is up, all instances of '[@SYMB]' will be removed from the macro. If you have selected a Symbiosis target the dummy 'SYMB' will be replaced by the target then.",
		["DisableMacro"] = "Disable macro",
		["DisableMacroHint"] = "If you assigned a hotkey for the Symbiosis button it will NOT work if you enable this option. Reload your UI for changes to take effect.",
		
		--PopUp panel
		["PopUp"] = "PopUp",
		["PopUpOptions"] = "PopUp options",
		["BackgroundName"] = "Background Name",
		["SelectBackground"] = "Select a Background",
		["Transparency"] = "Transparency",
		["LongPopUpHint1"] = "You can change the background art of the popup menu here. Just click on a tile to select it.",
		["LongPopUpHint2"]= "You can even add your own textures, look for the HowToAddOwnTextures.txt in the 'media' folder of the Symbiosis directory on how to do that.",
		["Background"] = "Background",
		["RemoveNoTargetTag"] = "Remove 'No Target' tag",
		["RemoveNoTargetTagTooltip"] = "Hides the 'No Target' tag above the Symbiosis button when no target is selected.",
		["HideMainBorder"] = "Hide Main Border",
		["BorderName"] = "Border Name",
		["SelectBorder"] = "Select a Border",
		["Preview"] = "Preview",
		["BorderSize"] = "Border Size",
};