@echo off
setlocal EnableDelayedExpansion

rem 设置要遍历的目录
set "dir=C:\Users\liu\Desktop\PPT&EXCEL"
set "socketport="

rem 创建日志文件
> log.txt (
    echo Start log: %date% %time%
    echo =========== Start DC Test ===========
)

"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 0
timeout /t 10 > nul

start /b "officecounter Window" cmd.exe /C "\\VM-SERVER\lnvpe-share\TEST\officecounter.exe" >> log.txt 2>&1

for %%f in ("%dir%\*") do (
    rem 对每个文件循环5次
    for /l %%n in (1,1,5) do (
        rem 打开文件
        start "" "%%f"
        
        rem 延迟10秒
        timeout /t 30 > nul
        
        taskkill /f /im EXCEL.EXE /im POWERPNT.EXE > nul 2>&1
        timeout /t 5 > nul
    )
)

taskkill /f /im officecounter.exe

"\\VM-SERVER\lnvpe-share\TOOL\AutoCharge.exe" %socketport% 1
timeout /t 10 > nul

echo =========== Start AC Test =========== >> log.txt

start /b "officecounter Window" cmd.exe /C "\\VM-SERVER\lnvpe-share\TEST\officecounter.exe" >> log.txt 2>&1

for %%j in ("%dir%\*") do (
    rem 对每个文件循环5次
    for /l %%n in (1,1,5) do (
        rem 打开文件
        "%%j"
        
        rem 延迟10秒
        timeout /t 30 > nul
        
        taskkill /f /im EXCEL.EXE /im POWERPNT.EXE > nul 2>&1
        timeout /t 5 > nul
    )
)
taskkill /f /im officecounter.exe

>> log.txt (
    echo ====================================
    echo End log: %date% %time%
)

pause