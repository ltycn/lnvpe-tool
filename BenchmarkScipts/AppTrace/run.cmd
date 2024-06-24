@echo off
setlocal enabledelayedexpansion

::====================
set "socketport="
::====================

set "destPath=%USERPROFILE%\Desktop\AppTrace"

cd /d "%destPath%"

set "countFilePath=%destPath%\Count.txt"
set "messageFilePath=%destPath%\AppList.txt"
set "resultFilePath=%destPath%\result.txt"
set "scriptPath=%destPath%\run.cmd"
set "APPTracePath=%destPath%\AppTrace.exe"
set "runOnceKeyPath=HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"

if not exist "%countFilePath%" (
    echo 0 > "%countFilePath%"
    reg add "%runOnceKeyPath%" /v AutoRestartScript /t REG_SZ /d "cmd.exe /c \"%scriptPath%\"" /f
    if errorlevel 1 (
        echo Failed to set registry key for auto-restart script
        exit /b 1
    )
    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 0
    echo Ready for testing ! Please wait for reboot...
    timeout /t 5 /nobreak
    shutdown /r /f /t 0
    exit /b
)

set /p count=<"%countFilePath%"
set /a count+=1
echo !count!>"%countFilePath%"

for /f "tokens=1,* delims=:" %%a in ('findstr /n "^" "%messageFilePath%"') do (
    if "%%a"=="%count%" (
        set "message=%%b"
        echo The following APP's startup time will be tested.
        echo !message!
        timeout /t 10 /nobreak
        goto :continue
    )
)

:continue

if not defined message (
    echo Test finished, Existing...
    timeout /t 5 /nobreak
    exit /b 1
)

start /min "" "\\VM-SERVER\lnvpe-share\TOOL\ML_Scenario_20240624\ML_Scenario.exe" -delay 1 -logname %fileName%.csv -count 100000 -logonly
timeout /t 10 /nobreak

for %%F in (!message!) do set "fileName=%%~nxF"

echo ================================================== >> "%resultFilePath%"
echo Executing: !message! >> "%resultFilePath%"
echo ================================================== >> "%resultFilePath%"

start /b "" cmd /c ""%APPTracePath%" !message! >> "%resultFilePath%" 2>>&1"
echo Wait for testing end...
timeout /t 100 /nobreak

taskkill /im "%fileName%" /im "EXCEL.EXE" /im "POWERPNT.EXE" /im "ML_Scenario.exe"

timeout /t 10 /nobreak

::============= DC Battery Check - Auto Charge =============
"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%
::==========================================================

reg add "%runOnceKeyPath%" /v AutoRestartScript /t REG_SZ /d "cmd.exe /c \"%scriptPath%\"" /f
echo PC is about to REBOOT...
shutdown /r /f /t 0
