local LSM = LibStub("LibSharedMedia-3.0"); 
local path = [[Interface\Addons\Symbiosis\Media\statusbar\]];

------------
--STATUSBAR-
------------

--media files taken from Elkano's SharedMedia
local FileNames = { "Aluminium", "BantoBar", "Bars", "Bumps", "Button", "Charcoal", "Cilo", "Cloud", "Dabs", "DarkBottom", "Diagonal", "Flat", "Glamour", "Glamour2", "Glamour3", "Glamour4", "Glamour5", "Glamour6", "Glamour7", "Glass", "Glaze", "Gloss", "Graphite", "Hatched", "Healbot", "LiteStep", "LiteStepLite", "Lyfe", "Melli", "MelliDark", "MelliDarkRough", "Minimalist", "Otravi", "Round", "Ruben", "Skewed", "Smooth", "Smudge", "Steel", "Striped", "Tube", "Water", "Wisps", "Xeon" };

for _, Name in pairs(FileNames) do
	LSM:Register("statusbar", Name, path .. Name);
end;

LSM:Register("statusbar","SymbiosisStandard","Interface/Tooltips/UI-Tooltip-Background");

---------
--BORDER-
---------

LSM:Register("border","SymbiosisStandard","Interface/ArenaEnemyFrame/UI-Arena-Border");