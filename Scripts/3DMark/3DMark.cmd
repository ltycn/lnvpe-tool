@echo off
setlocal enabledelayedexpansion

rem Check if running as administrator
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ############################# Configuration #############################
set "socketport=2"
set "looptimes=3"
set "pauseduration=180"

set "_3DMarkPath=C:\Program Files\UL\3DMark"
set "_3DMarkdefinitionfile=timespy.3dmdef"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "AutoCharge=\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe"
set "ML_Scenario=\\VM-SERVER\lnvpe-share\TOOL\ML_Scenario\ML_Scenario.exe"
rem #########################################################################

for /f "tokens=*" %%a in ('powershell -command "Get-Date -Format yyMMdd-HHmmss"') do set "datetime=%%a"

set "logpath=%logrootpath%\3DMark\%datetime%"
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

rem #################################################################
rem ###   Testing Logic Aera   ######################################
rem #################################################################

:runTest

    "%AutoCharge%" %socketport%

    "%AutoCharge%" %socketport% 0

    for /L %%i IN (1, 1, %looptimes%) do (
        rem Launch PTAT and run tests
        call :runBench "DC-3DMark-%%i" "%logpath%"
        )

    "%AutoCharge%" %socketport% 1

    for /L %%j IN (1, 1, %looptimes%) do (
        rem Launch PTAT and run tests
        call :runBench "AC-3DMark-%%j" "%logpath%"
        )

    rem Move logs to logpath
    rem move /Y "%USERPROFILE%\Documents\iPTAT\log\*" "%logpath%\PTAT"
    move /Y "ML*.csv" "%logpath%\ML"

    rem ========== Auto Charge when battery low ==========
    rem "%AutoCharge%" %socketport%

    rem ========== Control Power Socket ON/OFF ==========
    rem "%AutoCharge%" %socketport% 1
    rem "%AutoCharge%" %socketport% 0

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


rem #################################################################
rem ###   Testing Process Area   ####################################
rem #################################################################

rem Function to launch PTAT and run tests
:runBench
    set "testname=%~1"
    set "logpath=%~2"

    rem start /min "" "%PTAT%" "-m=ptat-%testname%.csv" "-noappend" "-l=c"
    start /min "" "%ML_Scenario%" -delay 1 -logname ML-%testname%.csv -count 100000 -logonly

    echo Start logging, Please wait for a while...
    timeout /t 20 > nul

    echo ============ Start Testing... =========[ %testname% of !looptimes! ]=================
    "%_3DMarkPath%\3DMarkCmd.exe" "--definition=%_3DMarkdefinitionfile%" "--out=%logpath%\%testname%.3dmark-result" "--export=%logpath%\%testname%.xml"
    echo =============================== End Testing... ===============================
    timeout /t 20 > nul

    taskkill /F /IM "PTATService.exe" /IM "ML_Scenario.exe"
    echo Successfully terminate PTAT & ML_Scenario ^!
    timeout /t 5 > nul

    rem "%AutoCharge%" %socketport%

    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
goto :eof
