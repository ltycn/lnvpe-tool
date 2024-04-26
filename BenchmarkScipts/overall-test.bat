@echo off
setlocal enabledelayedexpansion

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ==================================================
rem You can change this configuration below:

set "socketport=2"

set "looptimes=3"
set "pauseduration=180"
set "pcmarkdefinitionfile=pcm10_benchmark.pcmdef"
set "_3dmarkdefinitionfile=timespy.3dmdef"

rem ==================================================

set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "PCMarkPath=C:\Program Files\UL\PCMark 10"
set "_3DMarkPath=C:\Program Files\UL\3DMark"
set "CinebenchPath=%USERPROFILE%\Desktop\Cinebench2024"
set "logrootpath=%USERPROFILE%\Desktop\log"

@echo off

rem Prevent PC goes into sleep
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0


if not exist "%logrootpath%" (
    mkdir "%logrootpath%"
)


for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"

set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"

set "logpath=%logrootpath%\overalltest-log\%month%%day%%hour%%minute%"
mkdir "%logpath%"
cd %logpath%

"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 0

rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////

echo Launching PTAT...
start /min "" "%PTAT%" "-m=PCMark-PTAT.csv" "-noappend" "-l=c"
echo Start logging, Please wait for a while...

timeout /t 20 > nul

for /L %%i IN (1, 1, %looptimes%) do (
    echo Let's go^!
    echo ============ Start Testing... =========[ %%i of %looptimes% ]=================
    "%PCMarkPath%\PCMark10Cmd.exe" "--definition=%pcmarkdefinitionfile%" "--out=%logpath%\pcm-%%i.pcmark10-result" "--export=%logpath%\pcm-%%i.xml"
    echo =============================== End Testing... ===============================
    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%
    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
)
timeout /t 20 > nul
taskkill /F /IM "PTATService.exe"
echo Successfully terminate PTAT ^!
move /Y "%USERPROFILE%\Documents\iPTAT\log\PCMark-PTAT.csv" "%logpath%"

rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////

echo Launching PTAT...
start /min "" "%PTAT%" "-m=3DMark-PTAT.csv" "-noappend" "-l=c"
echo Start logging, Please wait for a while...

timeout /t 20 > nul

for /L %%i IN (1, 1, %looptimes%) do (
    echo Let's go^!
    echo ============ Start Testing... =========[ %%i of %looptimes% ]=================
    "%_3DMarkPath%\3DMarkCmd.exe" "--definition=%_3dmarkdefinitionfile%" "--out=%logpath%\3dm-%%i.3dmark-result" "--export=%logpath%\3dm-%%i.xml"
    echo =============================== End Testing... ===============================
    "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%
    echo Take a break...for %pauseduration% seconds...
    timeout /t %pauseduration% > nul
)
timeout /t 20 > nul
taskkill /F /IM "PTATService.exe"
echo Successfully terminate PTAT ^!
move /Y "%USERPROFILE%\Documents\iPTAT\log\3DMark-PTAT.csv" "%logpath%"

rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////
rem ////////////////////////////////////////////////////////////////////////////////

echo Launching PTAT...
start /min "" "%PTAT%" "-m=Cinebench-PTAT.csv" "-noappend" "-l=c"
echo Start logging, Please wait for a while...

timeout /t 20 > nul

cd %logpath%

for /L %%i IN (1,1,%looptimes%) do (
  echo Cinebench Run #%%i of %looptimes%...
  echo Cinebench Run #%%i of %looptimes%... >> cinebench_output.txt

  start /b /wait "CinebenchBatch Window" cmd.exe /C "!CinebenchPath!\cinebench.exe g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1 >> cinebench_output.txt"
  "\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport%
  timeout /t %pauseduration% /nobreak
)
timeout /t 20 > nul
taskkill /F /IM "PTATService.exe"
echo Successfully terminate PTAT ^!
move /Y "%USERPROFILE%\Documents\iPTAT\log\Cinebench-PTAT.csv" "%logpath%"


"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 1

pause

endlocal