# Ensure the script runs as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -FilePath "powershell" -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-File", $PSCommandPath -Verb RunAs
    exit
}

# ############################# Configuration #############################
$socketport = ""
$multicore_looptimes = 50
$pauseduration = 1800

$CinebenchPath = "$env:USERPROFILE\Desktop\CinebenchR23\Cinebench.exe"
$logrootpath = "$env:USERPROFILE\Desktop\log"
$AutoCharge = "\\FILE-SERVER\lnvpe-share\TOOL\AutoCharge.exe"
$ML_Scenario = "\\FILE-SERVER\lnvpe-share\TOOL\ML_Scenario_20240904\ML_Scenario.exe"
# #########################################################################

# Initialize log path and other settings
function Initialize-Environment {
    $datetime = Get-Date -Format "yyMMdd-HHmmss"
    $global:logpath = Join-Path -Path $logrootpath -ChildPath "CB\$datetime"
    New-Item -ItemType Directory -Path "$logpath\ML" | Out-Null

    # Prevent PC from entering sleep mode
    $powerSettings = @(
        "standby-timeout-ac",
        "standby-timeout-dc",
        "hibernate-timeout-ac",
        "hibernate-timeout-dc",
        "monitor-timeout-ac",
        "monitor-timeout-dc"
    )
    foreach ($setting in $powerSettings) {
        powercfg /change $setting 0
    }
}

# Activate a window by partial title match
function Activate-Window {
    param (
        [string]$processName
    )

    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Win32 {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
        }
"@

    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }

    if ($process) {
        $handle = $process.MainWindowHandle
        [Win32]::SetForegroundWindow($handle) | Out-Null
        Write-Host "Window for process '$processName' has been activated."
    } else {
        Write-Host "No active window found for process '$processName'."
    }
}

# Run a single test
function Run-Bench {
    param (
        [string]$testname,
        [string]$CBConfig,
        [string]$outputFile
    )
    Write-Host "=========== Start Testing... [$testname] ===========" | Out-File -FilePath $outputFile -Append

    Start-Process -FilePath $ML_Scenario `
                  -ArgumentList "-delay 1 -logname ML-CB.csv -count 100000 -logonly" `
                  -WindowStyle Minimized `
                  -WorkingDirectory $logpath

    Start-Sleep -Seconds 10

    $tempFile = New-TemporaryFile

    $process = Start-Process -FilePath $CinebenchPath `
                             -ArgumentList $CBConfig `
                             -RedirectStandardOutput $tempFile `
                             -NoNewWindow `
                             -PassThru
    Start-Sleep -Seconds 5
    Activate-Window -processName "cinebench"

    $process.WaitForExit()

    $lines = Get-Content $tempFile
    $filteredLines = $lines | Where-Object { $_ -match "CB" }

    if ($filteredLines) {
        $filteredLines | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No lines containing 'CB' found."
    }

    # 将所有内容写入输出文件
    $lines | Out-File -FilePath $outputFile -Append
    Remove-Item $tempFile

    Write-Host "=========== End Testing... [$testname] ===========" | Out-File -FilePath $outputFile -Append

    & $AutoCharge $socketport

    Start-Sleep -Seconds $pauseduration

    Stop-Process -Name "ML_Scenario" -Force
}



# Main test logic
function Run-Test {
    $outputFile = Join-Path -Path $logpath -ChildPath "CinebenchTestLog.txt"
    New-Item -ItemType File -Path $outputFile -Force | Out-Null
    Write-Host "Log file location: $outputFile"

    & $AutoCharge $socketport
    & $AutoCharge $socketport 0

    for ($i = 1; $i -le $multicore_looptimes; $i++) {
        Run-Bench -testname "DC-CBTest-$i" -CBConfig "g_CinebenchCpuXTest=true g_CinebenchCpu1Test=false g_CinebenchMinimumTestDuration=1" -outputFile $outputFile
    }

    & $AutoCharge $socketport 1
    Move-Item -Path "ML*.csv" -Destination "$logpath\ML" -Force

    # Process the log file after testing
    Process-CinebenchLog
}

# Process the Cinebench log file and save filtered results
function Process-CinebenchLog {
    $logFilePath = Join-Path -Path $logpath -ChildPath "CinebenchTestLog.txt"
    $resultFilePath = Join-Path -Path $logpath -ChildPath "CinebenchTestResult.txt"

    if (Test-Path $logFilePath) {
        Get-Content $logFilePath | Where-Object { $_ -match "^CB" } | Out-File -FilePath $resultFilePath -Force
        Write-Host "Filtered results saved to: $resultFilePath"
    } else {
        Write-Host "Log file not found: $logFilePath"
    }
}

# Main script execution
Initialize-Environment
Set-Location -Path $logpath
Run-Test
