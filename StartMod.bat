@echo OFF

SETLOCAL EnableExtensions

FOR /F "tokens=2,*" %%i IN ('reg query "HKLM\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul ^| Find /i "InstallPath" ')   DO set SteamDirectory=%%j

IF NOT DEFINED SteamDirectory (
 @echo trying 64 bit reg path

 FOR /F "tokens=2,*" %%i IN ('reg query "HKLM\SOFTWARE\Wow6432Node\Valve\Steam" /v "InstallPath" 2^>nul ^| Find /i "InstallPath"')   DO set SteamDirectory=%%j
)

@echo Steam directory is: %SteamDirectory%

IF NOT EXIST "%SteamDirectory%" (
  @echo Error the Steam directory directory doesn't seem to exist
  PAUSE
  EXIT
)

set InstallPath=%SteamDirectory%\steamapps\common\Natural Selection 2

@echo NS2 install path is: %InstallPath%
@echo Mod directory is: %~dp0

IF NOT EXIST "%InstallPath%" (
  @echo Error the Natural Selection 2  directory doesn't seem to exist
  PAUSE
  EXIT
) 

IF NOT EXIST "%~dp0\ModPath.lua" (
  @echo __ModPath = [[%~dp0]] > "%~dp0\ModPath.lua"
) 

start /d"%InstallPath%" .\ns2.exe -game "%~dp0"

EndLocal
