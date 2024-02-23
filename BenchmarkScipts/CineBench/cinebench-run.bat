@echo off
setlocal EnableDelayedExpansion

:: Check for administrator privileges
if not "%1"=="am_admin" (
    powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
    exit /b
)

set "CinebenchPath=%USERPROFILE%\Desktop\CinebenchR23\Cinebench.exe"
set "logtool=%USERPROFILE%\Desktop\logtool"
set /p logname=Please enter a log name:

:: Confirm user specified run count. Print usage and exit if not.
if "%1"=="" goto printUsage

set "runcount=5"
set "pauseduration=180"

cd %USERPROFILE%\Desktop

:: Start ML_Scenario.exe with administrator privileges
start /min "" "%logtool%\ML_Scenario.exe" -delay 1 -logname %logname%-ML.csv -count 8000 -logonly

echo Running Cinebench %runcount% time(s)...
echo:

for /L %%i IN (1,1,%runcount%) do (
  echo Cinebench Run #%%i of %runcount%...
  echo Cinebench Run #%%i of %runcount%... >> cinebench_output.txt

  start /b /wait "CinebenchBatch Window" cmd.exe /C "!CinebenchPath! g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1 >> cinebench_output.txt"

  timeout /t %pauseduration% /nobreak
)

:: Kill ML_Scenario.exe
taskkill /f /im ML_Scenario.exe

echo:
echo Cinebench results: > cinebench_results.txt
echo ------------------ >> cinebench_results.txt
findstr /b "CB" cinebench_output.txt >> cinebench_results.txt
type cinebench_results.txt
exit /B 0
