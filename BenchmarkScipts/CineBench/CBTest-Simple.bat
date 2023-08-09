@echo off
set CinebenchPath="%USERPROFILE%\Desktop\CinebenchR23\Cinebench.exe"

if [%1]==[] goto printUsage 

set logname=%1
rem ========================================
rem You can change this configuration below:

set "multicore-looptimes=5"
set "singlecore-looptimes=5"
set "pauseduration=180"

rem if you set looptimes=5, then it will run totally 5*2=100 times (ITS-Balance ITS-EPM)
rem ========================================


echo Running Cinebench tests... > %logname%.txt

::=====Muti-Core Cold Test===========================================================

echo Running three multicore tests...

for /L %%i IN (1,1,%multicore-looptimes%) do (
  echo Cinebench Multicore Run #%%i of %multicore-looptimes%... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t %pauseduration% /nobreak
)

::====Single-Core Cold Test===========================================================

echo Running three single core tests...
for /L %%i IN (1,1,%singlecore-looptimes%) do (
  echo Cinebench Single Core Run #%%i of %singlecore-looptimes%... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t %pauseduration% /nobreak
)

::====Muti-Core Warm Test==============================================================

rem echo Running 10 minute multicore test...
rem start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=600 >> %logname%.txt"
rem timeout /t 120 /nobreak

::====Single-Core Warm Test============================================================

rem echo Running 10 minute single core test...
rem start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=600 >> %logname%.txt"

::=====================================================================================

echo:
echo Cinebench results: > %logname%_Results.txt
echo ------------------ >> %logname%_Results.txt
findstr /b "CB" %logname%.txt >> %logname%_Results.txt
type %logname%_Results.txt
exit /B 0

:: display command-line usage
:printUsage:
@echo Usage: %0 ^<log name^>
exit /B 1
