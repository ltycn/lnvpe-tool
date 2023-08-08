Set PATH="%PATH%;C:\PCMark10ResultsAC"
c:
md C:\PCMark10ResultsAC

cd c:\windows\system32
REM=============Initial, kill log, disable dispatcher,enable its============
taskkill /f /im "ML_Scenario.exe"
SC config LITSSVC start=auto
SC config LenovoProcessManagement start=disabled
sc stop LenovoProcessManagement
sc start LITSSVC
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -restoredefaultschemes

powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
Powercfg -setAcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0
Powercfg -setDcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 0
Powercfg -setAcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
Powercfg -setDcvalueindex SCHEME_CURRENT SUB_SLEEP STANDBYIDLE 0
Powercfg -setAcvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGH 0
Powercfg -setDcvalueindex SCHEME_CURRENT SUB_VIDEO ADAPTBRIGH 0
Powercfg -setAcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEONORMALLEVEL 40
Powercfg -setDcvalueindex SCHEME_CURRENT SUB_VIDEO VIDEONORMALLEVEL 40

powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e

REM===================ITS Auto===============================================
REM EPM 148 Auto 135 BSM  146
sc start LITSSVC

cd C:\PCMark10ResultsAC
Servicecontrol.exe control LITSSVC 135
set ITSAutoLOOP=ITSAutoC1 ITSAutoC2 ITSAutoC3

echo:
for %%a in (%ITSAutoLOOP%) do (


cd C:\PCMark10ResultsAC
TIMEOUT /T 10
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)
REM===================ITS EPM===============================================
REM EPM 148 Auto 135 BSM  146

cd C:\PCMark10ResultsAC
Servicecontrol.exe control LITSSVC 148
set ITSEPMLOOP=ITSEPMC1 ITSEPMC2 ITSEPMC3

echo:
for %%a in (%ITSEPMLOOP%) do (

TIMEOUT /T 10
cd C:\PCMark10ResultsAC
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)
REM===================ITS BSM ===============================================
REM EPM 148 Auto 135 BSM  146


cd C:\PCMark10ResultsAC
Servicecontrol.exe control LITSSVC 146
set ITSBSMLOOP=ITSBSMC1 ITSBSMC2 ITSBSMC3

echo:
for %%a in (%ITSBSMLOOP%) do (

TIMEOUT /T 10
cd C:\PCMark10ResultsAC
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)

REM===================Disable ITS Enable Disapatcher=========================

cd C:\PCMark10ResultsAC

Servicecontrol.exe control LITSSVC 135
cd c:\windows\system32
sc stop LITSSVC
SC config LITSSVC start=disabled

SC config LenovoProcessManagement start=auto
sc start LenovoProcessManagement
TIMEOUT /T 10

REM===================Dispatcher 3.0 Auto======================================
rem 0xA3 Inteligent 163, 0xA4 bsm 164, 0xa5 epm 165

cd C:\PCMark10ResultsAC

Servicecontrol.exe control LenovoProcessManagement 163
set DSP3AutoLoop=Disp3AutoC1 Disp3AutoC2 Disp3AutoC3
echo:
for %%a in (%DSP3AutoLoop%) do (

cd C:\PCMark10ResultsAC
TIMEOUT /T 10
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)

REM===================Dispatcher 3.0 BSM======================================
rem 0xA3 Inteligent 163, 0xA4 bsm 164, 0xa5 epm 165

cd C:\PCMark10ResultsAC

Servicecontrol.exe control LenovoProcessManagement 164
set DSP3BSMLoop=Disp3BSMC1 Disp3BSMC2 Disp3BSMC3
echo:
for %%a in (%DSP3BSMLoop%) do (

cd C:\PCMark10ResultsAC
TIMEOUT /T 10
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)

REM===================Dispatcher 3.0 EPM======================================
rem 0xA3 Inteligent 163, 0xA4 bsm 164, 0xa5 epm 165

cd C:\PCMark10ResultsAC

Servicecontrol.exe control LenovoProcessManagement 165
set DSP3EPMLoop=Disp3EPMC1 Disp3EPMC2 Disp3EPMC3
echo:
for %%a in (%DSP3EPMLoop%) do (

cd C:\PCMark10ResultsAC
TIMEOUT /T 10
start /min cmd /c "ML_Scenario.exe -delay 1 -logname C:\PCMark10ResultsAC\%%a.csv -count 1800 -logonly"
cd "C:\Program Files\UL\PCMark 10"
PCMark10Cmd.exe --definition=pcm10_benchmark.pcmdef --out=C:\PCMark10ResultsAC\%%a.pcmark10-result
PCMark10Cmd.exe --in="C:\PCMark10ResultsAC\%%a.pcmark10-result" --export-xml  "C:\PCMark10ResultsAC\%%a.xml" --export-pdf "C:\PCMark10ResultsAC\%%a.pdf"
cd c:\windows\system32
TIMEOUT /T 10
taskkill /f /im "ML_Scenario.exe"

)

powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
powercfg -restoredefaultschemes
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
copy C:\ProgramData\Lenovo\LenovoDispatcher\Logs\LNVDispatcherLog.log C:\PCMark10ResultsAC\LNVDispatcherLog.log /y