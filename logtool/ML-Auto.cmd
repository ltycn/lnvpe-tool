@echo off
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' goto gotAdmin
else powershell -Command "Start-Process '%0' -Verb RunAs"
exit /B

:gotAdmin
cd /d %userprofile%\Desktop\logtool

set /p userInput="log name: "

ML_Scenario.exe -delay 1 -logname "%userInput%".csv -count 50000 -logonly
