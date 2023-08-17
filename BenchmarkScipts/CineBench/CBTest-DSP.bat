@echo off
setlocal enabledelayedexpansion

if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

rem ========================================
rem You can change this configuration below:

set "multicore-looptimes=5"
set "singlecore-looptimes=5"
set "pauseduration=180"

rem ========================================


set CinebenchPath="%USERPROFILE%\Desktop\CinebenchR23\Cinebench.exe"
set "PTAT=C:\Program Files\Intel Corporation\Intel(R)PTAT\PTAT.exe"
set "logtool=%USERPROFILE%\Desktop\logtool"
set /p logname=Please enter a log name:

for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"

set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"

set "logpath=%USERPROFILE%\Desktop\log\Cinebench\ITS-%month%%day%%hour%%minute%"
mkdir "%logpath%"


rem ===== Make sure ITS service running=====
cd c:\windows\system32
sc stop LITSSVC
TIMEOUT /T 5
SC config LITSSVC start=disabled
TIMEOUT /T 5

SC config LenovoProcessManagement start=auto
TIMEOUT /T 5
sc start LenovoProcessManagement
TIMEOUT /T 5

cd "%logpath%"

rem ================= Enable Log =====================
echo Launching PTAT...
start /min "" "%PTAT%" "-m=CB-%logname%-PTAT.csv" "-noappend" "-l=r"
echo Launching ML_Scenario...
start /min cmd /c "%logtool%\ML_Scenario.exe -delay 1 -logname %logpath%\log\CB-%logname%-ML.csv -count 8000 -logonly"
echo All done, Please wait for a while...
timeout /t 20 > nul

rem ============= Muti-Core Cold Test =================
echo Running Cinebench tests... > %logname%.txt
echo Running three multicore tests...

for /L %%i IN (1,1,%multicore-looptimes%) do (
  echo Cinebench Multicore Run #%%i of %multicore-looptimes%... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t %pauseduration% /nobreak
)

rem =========== Single-Core Cold Test ==================

echo Running three single core tests...
for /L %%i IN (1,1,%singlecore-looptimes%) do (
  echo Cinebench Single Core Run #%%i of %singlecore-looptimes%... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t %pauseduration% /nobreak
)

rem ============= Muti-Core Warm Test ===================

rem echo Running 10 minute multicore test...
rem start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=600 >> %logname%.txt"
rem timeout /t 120 /nobreak

rem ============== Single-Core Warm Test =================

rem echo Running 10 minute single core test...
rem start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=600 >> %logname%.txt"

rem ======================================================

rem =============== Kill logging process =================
taskkill /F /IM "PTAT.exe" /IM "ML_Scenario.exe"
echo Successfully terminate PTAT and ML_Scenario^!
move /Y "%USERPROFILE%\Documents\iPTAT\log\CB-%logname%-ptat.csv" "%logpath%\log"

echo:
echo Cinebench results: > %logname%_Results.txt
echo ------------------ >> %logname%_Results.txt
findstr /b "CB" %logname%.txt >> %logname%_Results.txt
type %logname%_Results.txt
exit /B 0
