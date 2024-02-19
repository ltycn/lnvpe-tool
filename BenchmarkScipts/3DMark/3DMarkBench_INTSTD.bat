@echo off
setlocal enabledelayedexpansion

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

set "_3DMarkPath=C:\Program Files\UL\3DMark"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "logtool=%USERPROFILE%\Desktop\logtool"

rem ========================================
rem You can change this configuration below:

set "looptimes=3"
set "pauseduration=180"

set "definitions=(cpuprofile directxraytracingft firestrike FireStrikeExtreme NvidiaDlss PciExpress TimeSpy TimeSpyExtreme WildLife WildLifeExtreme)"

rem if you set looptimes=5, then it will run totally 5*2=10 times (IDSP-Intelligent DSP-EPM)
rem ========================================

@echo off


set /p "confirmation=Enter your Choice:(y) "

if "%confirmation%"=="y" (
    goto :runbench
) else (
    goto :runbench
)

pause
exit


:runbench
if not exist "%logrootpath%" (
    mkdir "%logrootpath%"
)
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"

set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"

set "logpath=%logrootpath%\%month%%day%%hour%%minute%"
mkdir "%logpath%"
mkdir "%logpath%\3dm-result"
cd %logpath%



:: Function to stop and disable a service
:StopAndDisableService
    sc stop %1
    timeout /nobreak /t 5 > nul
    sc config %1 start= disabled
    timeout /nobreak /t 5 > nul
    sc query %1
    echo Successfully stopped and disabled the service.
    exit /b

:: Main loop
for %%a in (163 188) do (
    if %%a=="163" (
        set "logname=INT"
        %logtool%\Servicecontrol.exe control LenovoProcessManagement %%a
        echo Successfully set Dispatcher to [ Intelligent Mode ]
    ) else if %%a==188 (
        for /f "tokens=3" %%b in ('sc query LenovoProcessManagement ^| findstr /C:"STATE"') do (
            set "serviceState=%%b"
        )
        echo The service state is: !serviceState!

        if "!serviceState!"=="RUNNING" (
            echo Service is running. Stopping and disabling...
            call :StopAndDisableService LenovoProcessManagement
        ) else if "!serviceState!"=="STOPPED" (
            echo Service is already stopped. Disabling...
            call :StopAndDisableService LenovoProcessManagement
        ) else (
            echo Unknown service state: !serviceState!
            echo Please check the service manually.
        )

        set "logname=STD"
        echo Successfully set Dispatcher to [ STD Mode ]
    )

    timeout /t 20 > nul

    for %%i in %definitions% do (
    for /L %%j IN (1, 1, %looptimes%) do (
        echo Let's go^! 
        echo =====[ Current Mode: !logname! ]==== Start Testing... =========[ %%j of %looptimes% ]=========
        
        echo Launching ML_Scenario...
        start /min cmd /c "!logtool!\ML_Scenario.exe -delay 1 -logname DSP-!logname!-ML.csv -count 50000 -logonly"
        timeout /t 10 > nul

        "%_3DMarkPath%\3DMarkCmd.exe" "--definition=%%i.3dmdef" "--out=%logpath%\3dm-result\%%i-!logname!-%%j.3dmark-result" "--export=%logpath%\3dm-result\DSP-!logname!-%%j.xml"

        echo =============================== End Testing... ===============================
        timeout /t 10 > nul
        
        echo Stop ML_Scenario...
        taskkill /F /IM "ML_Scenario.exe"

        echo Take a break...for %pauseduration% seconds...
        timeout /t %pauseduration% > nul
    )

)

pause

endlocal