:: CinebenchBatch.cd - Batch file for running Cinebench multiple times
:: and printing the results from all runs when complete
::
@echo off

:: set this variable to the location of your Cinebench executable
set CinebenchPath="%USERPROFILE%\Desktop\CinebenchR23\Cinebench.exe"

:: confirm user specified log name. print usage and exit if not
if [%1]==[] goto printUsage 

::
:: start Cinebench execution loop. we generate two files:
::   <UserDefinedLogName>.txt  - our messages + STDOUT from Cinebench 
::   <UserDefinedLogName>_Results.txt - Extracted single/multi-core results
::  

set logname=%1
echo Running Cinebench tests... > %logname%.txt
echo:

::=====Muti-Core Cold Test===========================================================

echo Running three multicore tests...

for /L %%i IN (1,1,3) do (
  echo Cinebench Multicore Run #%%i of 3... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t 120 /nobreak
)

::====Single-Core Cold Test===========================================================

echo Running three single core tests...
for /L %%i IN (1,1,3) do (
  echo Cinebench Single Core Run #%%i of 3... >> %logname%.txt
  start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=1 >> %logname%.txt"
  timeout /t 120 /nobreak
)

::====Muti-Core Warm Test==============================================================

echo Running 10 minute multicore test...
start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=600 >> %logname%.txt"
timeout /t 120 /nobreak

::====Single-Core Warm Test============================================================

echo Running 10 minute single core test...
start /b /wait "CinebenchBatch Window" cmd.exe /C "%CinebenchPath% g_CinebenchCpuXTest=false g_CinebenchCpu1Test=true g_CinebenchMinimumTestDuration=600 >> %logname%.txt"

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
