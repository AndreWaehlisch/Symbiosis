local FileNames = { "MyAwesomeArt1", "MyAwesomeArt2" };

local LSM = LibStub("LibSharedMedia-3.0"); 
local path = [[Interface\Addons\MyMediaAddon\]];

for _, Name in pairs(FileNames) do
	LSM:Register("statusbar", Name, path .. Name);
end;