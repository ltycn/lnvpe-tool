@echo off
setlocal enabledelayedexpansion

rem Check if running as administrator
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ############################# Configuration #############################
set "socketport="
set "multicore-looptimes=5"
set "singlecore-looptimes=5"
set "pauseduration=180"


set CinebenchPath="%USERPROFILE%\Desktop\CinebenchR23\Cinebench.exe"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "AutoCharge=\\FILE-SERVER\lnvpe-share\TOOL\AutoCharge.exe"
set "ML_Scenario=\\FILE-SERVER\lnvpe-share\TOOL\ML_Scenario_20240904\ML_Scenario.exe"
rem #########################################################################


for /f "tokens=*" %%a in ('powershell -command "Get-Date -Format yyMMdd-HHmmss"') do set "datetime=%%a"

set "logpath=%logrootpath%\CB\%datetime%"
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

    start /min "" "%ML_Scenario%" -delay 1 -logname ML-CB.csv -count 100000 -logonly

    timeout /t 10 > nul

    for /L %%i IN (1, 1, %multicore-looptimes%) do (
        rem Launch PTAT and run tests
        call :runBench "DC-CBTest-%%i" "%logpath%" "g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1"
        )

    "%AutoCharge%" %socketport% 1

    REM for /L %%j IN (1, 1, %singlecore-looptimes%) do (
    REM     rem Launch PTAT and run tests
    REM     call :runBench "DC-CBTest-%%j" "%logpath%" "g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1"
    REM     )

    taskkill /F /IM "ML_Scenario.exe"

    move /Y "ML*.csv" "%logpath%\ML"



exit /b

rem Function to launch PTAT and run tests
:runBench
    set "testname=%~1"
    set "logpath=%~2"
    set "CBConfig=%~3"

    echo Start logging, Please wait for a while...
    timeout /t 20 > nul

    echo ============ Start Testing... =========[ %testname% of !looptimes! ]=================
    start /wait "" "%CinebenchPath%" %CBConfig% >> %testname%.txt
    echo =============================== End Testing... ===============================
    timeout /t 20 > nul

    "%AutoCharge%" %socketport%

    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
goto :eof
