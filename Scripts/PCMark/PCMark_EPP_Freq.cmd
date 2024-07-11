@echo off
setlocal enabledelayedexpansion

rem Check if running as administrator
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem Configuration
set "socketport="
rem set "looptimes=3"
set "pauseduration=180"
set "pcmarkdefinitionfile=pcm10_benchmark.pcmdef"
set "_3dmarkdefinitionfile=timespy.3dmdef"
set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "PCMarkPath=C:\Program Files\UL\PCMark 10"
set "_3DMarkPath=C:\Program Files\UL\3DMark"
set "CinebenchPath=%USERPROFILE%\Desktop\Cinebench2024"
set "logrootpath=%USERPROFILE%\Desktop\log"


for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"

set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"
set "logpath=%logrootpath%\overalltest-log\%month%%day%%hour%%minute%"
mkdir "%logpath%"
cd "%logpath%"

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

rem Create log directory if not exists
if not exist "%logrootpath%" mkdir "%logrootpath%"

rem Function to run test
:runTest
    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 0

    rem Loop for EPP values
    for /L %%i IN (10, 10, 100) do (
        set "EPP=%%i"
        Powercfg -setdcvalueindex scheme_current sub_processor PERFEPP1 !EPP!
        Powercfg -setdcvalueindex scheme_current sub_processor PERFEPP !EPP!
        Powercfg -setacvalueindex scheme_current sub_processor PERFEPP1 !EPP!
        Powercfg -setacvalueindex scheme_current sub_processor PERFEPP !EPP!
        Powercfg -setactive scheme_current

        rem Loop for processor frequency
        for %%f in (1400 1450 1500 1550 1600 1650 1700 1800 1900 2000 2100 2300 2500 3000 4000 5000) do (
        Powercfg -setdcvalueindex scheme_current sub_processor PROCFREQMAX %%f
        Powercfg -setdcvalueindex scheme_current sub_processor PROCFREQMAX1 %%f
        Powercfg -setacvalueindex scheme_current sub_processor PROCFREQMAX %%f
        Powercfg -setacvalueindex scheme_current sub_processor PROCFREQMAX1 %%f
        Powercfg -setactive scheme_current

        rem Launch PTAT and run tests
        call :runBench "EPP!EPP!-FREQ%%f" "%logpath%"
        )

    )

    rem Move logs to logpath
    move /Y "%USERPROFILE%\Documents\iPTAT\log\*" "%logpath%"

    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 1

exit /b

rem Function to launch PTAT and run tests
:runBench
    set "testname=%~1"
    set "logpath=%~2"
    start /min "" "%PTAT%" "-m=ptat-%testname%.csv" "-noappend" "-l=c"
    start /min "" "\\VM-SERVER\lnvpe-share\TOOL\ML_Scenario\ML_Scenario.exe" -delay 1 -logname ML-%testname%.csv -count 100000 -logonly
    echo Start logging, Please wait for a while...
    timeout /t 20 > nul
    echo Let's go^!
    echo ============ Start Testing... =========[ %testname% of !looptimes! ]=================
    "%PCMarkPath%\PCMark10Cmd.exe" "--definition=%pcmarkdefinitionfile%" "--out=%logpath%\pcm-%testname%.pcmark10-result" "--export=%logpath%\pcm-%testname%.xml"
    echo =============================== End Testing... ===============================
    timeout /t 20 > nul
    taskkill /F /IM "PTATService.exe" /IM "ML_Scenario.exe"
    echo Successfully terminate PTAT & ML_Scenario ^!
    timeout /t 5 > nul
    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%
    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
goto :eof
