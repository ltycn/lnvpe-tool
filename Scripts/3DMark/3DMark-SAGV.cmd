@echo off
setlocal enabledelayedexpansion

rem Check if running as administrator
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ############################# Configuration #############################
set "looptimes=3"
set "pauseduration=180"

set "_3DMarkPath=C:\Program Files\UL\3DMark"
rem List of definition files
set "_3DMarkdefinitionfiles=timespy wildlife firestrike firestrike_extreme"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "ML_Scenario=\\VM-SERVER\lnvpe-share\TOOL\ML_Scenario\ML_Scenario.exe"
rem #########################################################################

for /f "tokens=*" %%a in ('powershell -command "Get-Date -Format yyMMdd-HHmmss"') do set "datetime=%%a"

set "logpath=%logrootpath%\3DMark\%datetime%"
mkdir "%logpath%\ML"
cd %logpath%

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
rem ###   Testing Logic Area   ######################################
rem #################################################################

:runTests
    call :toggleLenovoService 0x111
    sc control LenovoProcessManagement 165
    call :runTest EPM-SAGVEnable
    sc control LenovoProcessManagement 172
    call :runTest GEEK-SAGVEnable

    call :toggleLenovoService 0x000
    sc control LenovoProcessManagement 165
    call :runTest EPM-SAGVDisable
    sc control LenovoProcessManagement 172
    call :runTest GEEK-SAGVDisable

    move /Y "ML*.csv" "%logpath%\ML"
exit /b

rem #################################################################
rem ###   Common Functions   ########################################
rem #################################################################

:toggleLenovoService
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LenovoProcessManagement\Performance\PowerSlider" /v Policy_DYTCTest /t REG_DWORD /d %1 /f
    net stop LenovoProcessManagement
    net start LenovoProcessManagement
    timeout /t 10 > nul
goto :eof

:runTest
    rem Loop through each _3DMarkdefinitionfile
    for %%d in (%_3DMarkdefinitionfiles%) do (
        for /L %%i in (1, 1, %looptimes%) do (
            call :runBench "%1-%%d-%%i" "%logpath%" "%%d"
        )
    )
goto :eof

rem #################################################################
rem ###   Testing Process Area   ####################################
rem #################################################################

:runBench
    set "testname=%~1"
    set "logpath=%~2"
    set "definitionfile=%~3"

    start /min "" "%ML_Scenario%" -delay 1 -logname ML-%testname%.csv -count 100000 -logonly
    echo Start logging, Please wait for a while...
    timeout /t 20 > nul

    echo ============ Start Testing... =========[ %testname% of !looptimes! using %definitionfile% ]=================
    "%_3DMarkPath%\3DMarkCmd.exe" "--definition=%definitionfile%.3dmdef" "--out=%logpath%\%testname%.3dmark-result" "--export=%logpath%\%testname%.xml"
    echo ============================================ End Testing... ================================================
    timeout /t 20 > nul

    taskkill /F /IM "ML_Scenario.exe"
    echo Successfully terminate ML_Scenario ^!
    timeout /t 5 > nul

    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
goto :eof
