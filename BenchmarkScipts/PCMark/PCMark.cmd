@echo off
setlocal enabledelayedexpansion

rem Check if running as administrator
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ############################# Configuration #############################
set "socketport="
set "looptimes=3"
set "pauseduration=180"

set "PCMarkPath=C:\Program Files\UL\PCMark 10"
set "pcmarkdefinitionfile=pcm10_benchmark.pcmdef"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "AutoCharge=\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe"
set "ML_Scenario=\\VM-SERVER\lnvpe-share\TOOL\ML_Scenario\ML_Scenario.exe"
rem #########################################################################


for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"

set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"
mkdir "%logpath%" && mkdir "%logpath%\ML" && mkdir "%logpath%\PTAT" && cd "%logpath%"

rem Prevent PC from going into sleep
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

rem Function to run test

:runTest

    "%AutoCharge%" %socketport%

    "%AutoCharge%" %socketport% 0

    for /L %%i IN (1, 1, %looptimes%) do (
        rem Launch PTAT and run tests
        call :runBench "DC-PCMark-%%i" "%logpath%"
        )

    "%AutoCharge%" %socketport% 1

    for /L %%j IN (1, 1, %looptimes%) do (
        rem Launch PTAT and run tests
        call :runBench "AC-PCMark-%%j" "%logpath%"
        )

    rem Move logs to logpath
    move /Y "%USERPROFILE%\Documents\iPTAT\log\*" "%logpath%\PTAT"
    move /Y "ML*.csv" "%logpath%\ML"

    rem ================ Fixed STD Mode =================
    rem net stop "LenovoProcessManagement"
    rem sc config "LenovoProcessManagement" start= disabled

    rem =============== Intelligent Mode ================
    rem sc control LenovoProcessManagement 163

    rem ============== Battery Saving Mode ==============
    rem sc control LenovoProcessManagement 164

    rem =========== Extreame Performance Mode ===========
    rem sc control LenovoProcessManagement 165

    rem ========== Restore Balance Power Plan ===========
    rem powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    rem powercfg -restoredefaultschemes
    rem powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 

exit /b

rem Function to launch PTAT and run tests
:runBench
    set "testname=%~1"
    set "logpath=%~2"

    start /min "" "%PTAT%" "-m=ptat-%testname%.csv" "-noappend" "-l=c"
    start /min "" "%ML_Scenario%" -delay 1 -logname ML-%testname%.csv -count 100000 -logonly

    echo Start logging, Please wait for a while...
    timeout /t 20 > nul

    echo ============ Start Testing... =========[ %testname% of !looptimes! ]=================
    "%PCMarkPath%\PCMark10Cmd.exe" "--definition=%pcmarkdefinitionfile%" "--out=%logpath%\pcm-%testname%.pcmark10-result" "--export=%logpath%\pcm-%testname%.xml"
    echo =============================== End Testing... ===============================
    timeout /t 20 > nul

    taskkill /F /IM "PTATService.exe" /IM "ML_Scenario.exe"
    echo Successfully terminate PTAT & ML_Scenario ^!
    timeout /t 5 > nul

    "%AutoCharge%" %socketport%

    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
goto :eof
