@echo off
setlocal enabledelayedexpansion

::====================
set "socketport=2"
::====================

set "destPath=%USERPROFILE%\Desktop\AppTrace"

cd /d "%destPath%"

set "gearFilePath=%destPath%\Gear.txt"
set "countFilePath=%destPath%\Count.txt"
set "messageFilePath=%destPath%\AppList.txt"
set "resultFilePath=%destPath%\result.txt"
set "scriptPath=%destPath%\run-gear.cmd"
set "APPTracePath=%destPath%\AppTrace.exe"
set "runOnceKeyPath=HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"

for %%p in (
    standby-timeout-ac
    standby-timeout-dc
    hibernate-timeout-ac
    hibernate-timeout-dc
    monitor-timeout-ac
    monitor-timeout-dc
) do (
    powercfg /change "%%p" 0
)

if not exist "%gearFilePath%" (
    echo 2 > "%gearFilePath%"
)

if not exist "%countFilePath%" (
    echo 0 > "%countFilePath%"
    reg add "%runOnceKeyPath%" /v AutoRestartScript /t REG_SZ /d "cmd.exe /c \"%scriptPath%\"" /f
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
        timeout /t 20 /nobreak
        goto :continue
    )
)

:continue

if not defined message (
    echo Test finished, Exiting...
    set /p gear=<"%gearFilePath%"
    echo ============ Setting Gear to Gear !gear! =========== >> "%resultFilePath%"
    
    if !gear! GTR 7 (
        echo Test Finished.
        "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 1
        exit /b 0
    )

    cd %USERPROFILE%\Desktop\DTTControl
    "%USERPROFILE%\Desktop\DTTControl\DTTControl.exe" setgear !gear!
    set /a gear+=1
    echo !gear!>"%gearFilePath%"
    echo Resetting count files...
    del /F %countFilePath%
    reg add "%runOnceKeyPath%" /v AutoRestartScript /t REG_SZ /d "cmd.exe /c \"%scriptPath%\"" /f
    echo Reboot to continue...
    timeout /t 20 /nobreak
    shutdown /r /f /t 0
    exit /b 1
)

"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 0

timeout /t 10 /nobreak

for %%F in (!message!) do set "fileName=%%~nxF"

echo ================================================== >> "%resultFilePath%"
echo Executing: !message! >> "%resultFilePath%"
echo ================================================== >> "%resultFilePath%"

start /b "" cmd /c ""%APPTracePath%" !message! >> "%resultFilePath%" 2>>&1"
echo Wait for testing end...
timeout /t 100 /nobreak

taskkill /im "%fileName%" /im "EXCEL.EXE" /im "POWERPNT.EXE"

timeout /t 20 /nobreak

::============= DC Battery Check - Auto Charge =============
"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%

"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 1
::==========================================================

reg add "%runOnceKeyPath%" /v AutoRestartScript /t REG_SZ /d "cmd.exe /c \"%scriptPath%\"" /f
echo PC is about to REBOOT...
shutdown /r /f /t 0
