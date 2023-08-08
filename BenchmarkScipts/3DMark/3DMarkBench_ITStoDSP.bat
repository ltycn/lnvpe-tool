@echo off
setlocal enabledelayedexpansion

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "_3DMarkPath=C:\Program Files\UL\3DMark"
set "logrootpath=%USERPROFILE%\Desktop\log"
set "logtool=%USERPROFILE%\Desktop\logtool"

rem ========================================
rem You can change this configuration below:

set "looptimes=5"
set "pauseduration=180"

rem if you set looptimes=5, then it will run totally 5*4=20 times (ITS-Balance ITS-EPM & DSP-Intelligent DSP-EPM)
rem ========================================

@echo off
color 0f

echo [41;37m***** This is an automated 3DMark testing script *****[0m
echo [46;30mFunctions:[0m
echo [32m1. Evaluates 3DMark performance in both Intelligent and EPM modes of ITS.[0m
echo [32m2. Captures performance parameters using PTAT and ML_Scenario[0m
echo [32m3. Test execution process:[0m
echo [32m   - Switches Dispatcher mode to Intelligent[0m
echo [32m   - Enables Logs (PTAT, ML_Scenario)[0m
echo [32m   - Starts testing (default: three cycles with a 3-minute interval)[0m
echo [32m   - Switches Dispatcher mode to EPM[0m
echo [32m   - Enables Logs (PTAT, ML_Scenario)[0m
echo [32m   - Starts testing (default: three cycles with a 3-minute interval)[0m
echo [32m   - Organizes and completes the logging[0m
echo [43;30mTo ensure the script runs correctly, please meet these requirements:[0m
echo [32m1. 3DMark and PTAT are installed in their default paths.[0m
echo [32m2. The desktop contains a "logtool" folder, which includes the following files:[0m
echo [32m   - ML_Scenario.exe[0m
echo [32m   - LenovoIPF.dll[0m
echo [32m   - LenovoCamera.dll[0m
echo [32m   - ServiceControl.exe[0m
echo [32m   - xmltocsv.exe[0m
echo [41;37m********************************************************************[0m
echo [46;30m   - If any of the above files are missing, enter "d" to download them automatically (internet connection required)[0m
echo [46;30m   - If the requirements are met, enter "y" to initiate the testing process[0m
echo [46;30m   - enter "u" to update this script[0m
echo [41;37m********************************************************************[0m
echo [32mFor further information, visit: https://github.com/ltycn/lnvpe-tool/BenchmarkScripts[0m


set /p "confirmation=Enter your Choice: "

if "%confirmation%"=="y" (
    goto :runbench
)else if "%confirmation%"=="u" (
    goto :update
)else if "%confirmation%"=="d" (
    goto :download
) else (
    exit
)

pause
exit

:update
echo Updating...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/BenchmarkScipts/3DMark/3DMarkBench_ITStoDSP.bat', '%USERPROFILE%\Desktop\3DMarkBench_ITStoDSP.bat')"
echo Update completed, File saved to %USERPROFILE%\Desktop\3DMarkBench_ITStoDSP.bat
pause
exit /b 0

:download
REM Create logtool directory on the desktop if it doesn't exist
if not exist "%logtool%" mkdir "%logtool%" 2>nul

REM Download four files and save them in the logtool directory
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/ServiceControl.exe', '%USERPROFILE%\Desktop\logtool\ServiceControl.exe')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/ML_Scenario.exe', '%USERPROFILE%\Desktop\logtool\ML_Scenario.exe')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/LenovoIPF.dll', '%USERPROFILE%\Desktop\logtool\LenovoIPF.dll')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/LenovoCamera.dll', '%USERPROFILE%\Desktop\logtool\LenovoCamera.dll')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/xmltocsv.exe', '%USERPROFILE%\Desktop\logtool\xmltocsv.exe')"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://dl.lnvpe.com/logtool/DSPi.exe', '%USERPROFILE%\Desktop\logtool\DSPi.exe')"
echo Download complete, press enter to test...
pause

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


cd c:\windows\system32
TIMEOUT /T 10
sc stop LenovoProcessManagement
TIMEOUT /T 10
SC config LenovoProcessManagement start=disabled
TIMEOUT /T 10

SC config LITSSVC start=auto
TIMEOUT /T 10
sc start LITSSVC
TIMEOUT /T 10


set "ITSlogpath=%logrootpath%\3DMark-%month%%day%%hour%%minute%-ITS"
set "DSPlogpath=%logrootpath%\3DMark-%month%%day%%hour%%minute%-DSP"
mkdir "%ITSlogpath%"
mkdir "%ITSlogpath%\3dm-result"
cd %ITSlogpath%


rem ======================================================================
rem start ITS test. BSM=146 EPM=148 Auto=135 

for %%a in (135 148) do (

    %logtool%\Servicecontrol.exe control LITSSVC %%a

    if %%a==135 (
        set "logname=Balance"
        echo Successfully set ITS to [ Balance Mode ]
    ) else if %%a==148 (
        set "logname=EPM"
        echo Successfully set ITS to [ EPM Mode ]
    )
    echo Launching PTAT...
    start /min "" "%PTAT%" "-m=ITS-!logname!-PTAT.csv" "-noappend" "-l=r"
    echo Launching ML_Scenario...
    start /min cmd /c "%logtool%\ML_Scenario.exe -delay 1 -logname ITS-!logname!-ML.csv -count 4000 -logonly"
    echo All done, Please wait for a while...

    timeout /t 20 > nul

    for /L %%i IN (1, 1, %looptimes%) do (
        echo Let's go^!
        echo =====[ Current Mode: !logname! ]==== Start Testing... =========[ %%i of %looptimes% ]=========
        "%_3DMarkPath%\3DMarkCmd.exe" "--definition=timespy.3dmdef" "--out=%ITSlogpath%\3dm-result\ITS-!logname!-%%i.3dmark-result" "--export=%ITSlogpath%\3dm-result\ITS-!logname!-%%i.xml"
        echo =============================== End Testing... ===============================
        echo Take a break...for %pauseduration% seconds...
        timeout /t %pauseduration% > nul
    )

    timeout /t 20 > nul

    taskkill /F /IM "PTAT.exe" /IM "ML_Scenario.exe"
    echo Successfully terminate PTAT and ML_Scenario!

    move /Y "%USERPROFILE%\Documents\iPTAT\log\its-!logname!-ptat.csv" "%ITSlogpath%"
)

rem ======================================================================
rem Change ITS active staus to disable, start up Lenovo Process Management

%logtool%Servicecontrol.exe control LITSSVC 135
cd c:\windows\system32
TIMEOUT /T 10
sc stop LITSSVC
TIMEOUT /T 10
SC config LITSSVC start=disabled
TIMEOUT /T 10

SC config LenovoProcessManagement start=auto
TIMEOUT /T 10
sc start LenovoProcessManagement
TIMEOUT /T 10

rem ======================================================================

mkdir "%DSPlogpath%"
mkdir "%DSPlogpath%\3dm-result"
cd %DSPlogpath%

rem ======================================================================
rem start Dispatcer test. BSM=164/0xA4, Inteligent=163/0xA3, EPM=165/0xa5

for %%a in (163 165) do (

    %logtool%\Servicecontrol.exe control LenovoProcessManagement %%a

    if %%a==163 (
        set "logname=INT"
        echo Successfully set Dispatcher to [ Intelligent Mode ]
    ) else if %%a==165 (
        set "logname=EPM"
        echo Successfully set Dispatcher to [ EPM Mode ]
    )
    echo Launching PTAT...
    start /min "" "%PTAT%" "-m=DSP-!logname!-PTAT.csv" "-noappend" "-l=r"
    echo Launching ML_Scenario...
    start /min cmd /c "%logtool%\ML_Scenario.exe -delay 1 -logname DSP-!logname!-ML.csv -count 4000 -logonly"
    echo All done, Please wait for a while...

    timeout /t 20 > nul

    for /L %%i IN (1, 1, %looptimes%) do (
        echo Let's go^!
        echo =====[ Current Mode: !logname! ]==== Start Testing... =========[ %%i of %looptimes% ]=========
        "%_3DMarkPath%\3DMarkCmd.exe" "--definition=timespy.3dmdef" "--out=%DSPlogpath%\3dm-result\DSP-!logname!-%%i.3dmark-result" "--export=%DSPlogpath%\3dm-result\DSP-!logname!-%%i.xml"
        echo =============================== End Testing... ===============================
        echo Take a break...for %pauseduration% seconds...
        timeout /t %pauseduration% > nul
    )

    timeout /t 20 > nul

    taskkill /F /IM "PTAT.exe" /IM "ML_Scenario.exe"
    echo Successfully terminate PTAT and ML_Scenario!

    move /Y "%USERPROFILE%\Documents\iPTAT\log\dsp-!logname!-ptat.csv" "%DSPlogpath%"
)

pause

endlocal