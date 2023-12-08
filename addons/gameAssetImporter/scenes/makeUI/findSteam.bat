@echo off
setlocal enabledelayedexpansion

:: Possible locations for Steam in the Windows Registry
set "steamRegistryKeys=HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Valve\Steam HKEY_CURRENT_USER\Software\Valve\Steam"

:: Define the output file path
set "outputFile=steam_dir.txt"

:: Loop through each registry key location and check for the InstallPath value
for %%k in (%steamRegistryKeys%) do (
    set "steamDir="
    for /f "tokens=2,*" %%a in ('reg query "%%k" /v InstallPath 2^>nul') do (
        set "steamDir=%%b"
    )
    if defined steamDir (
        echo !steamDir! > "%outputFile%"
        goto :end
    )
)

:end
