rmdir /s /q "D:\World of Warcraft\_retail_\Interface\AddOns\ReVault"
@REM del /q "D:\World of Warcraft\_retail_\WTF\Account\60034891#4\SavedVariables\ReVault.lua"
@REM del /q "D:\World of Warcraft\_retail_\WTF\Account\60034891#4\SavedVariables\ReVault.lua.bak"
mkdir "D:\World of Warcraft\_retail_\Interface\AddOns\ReVault"
xcopy /e /i /exclude:.publishignore . "D:\World of Warcraft\_retail_\Interface\AddOns\ReVault"
PAUSE