param(
    [Parameter(Mandatory=$true)][int]$ProcessId,
    [Parameter(Mandatory=$true)][string]$InstallDir,
    [Parameter(Mandatory=$true)][string]$Archive,
    [Parameter(Mandatory=$true)][string]$ExecutableName
)
$ErrorActionPreference = "Stop"
$work = Join-Path $env:TEMP ("GF-update-" + [guid]::NewGuid().ToString("N"))
$backup = Join-Path $work "backup"
$extract = Join-Path $work "package"
$logDir = Join-Path $env:LOCALAPPDATA "GALACTIC-FRONTIER"
$log = Join-Path $logDir "update.log"
New-Item -ItemType Directory -Force -Path $backup, $extract, $logDir | Out-Null
try {
    try { Wait-Process -Id $ProcessId -Timeout 90 -ErrorAction Stop } catch {
        if (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) { throw "Game process did not exit in time." }
    }
    Expand-Archive -LiteralPath $Archive -DestinationPath $extract -Force
    $newExe = Join-Path $extract $ExecutableName
    $newPck = Join-Path $extract "GALACTIC-FRONTIER.pck"
    if (!(Test-Path -LiteralPath $newExe -PathType Leaf) -or !(Test-Path -LiteralPath $newPck -PathType Leaf)) {
        throw "Package must contain the executable and GALACTIC-FRONTIER.pck at its root."
    }
    $targetExe = Join-Path $InstallDir $ExecutableName
    $targetPck = Join-Path $InstallDir "GALACTIC-FRONTIER.pck"
    if (!(Test-Path -LiteralPath $targetExe) -or !(Test-Path -LiteralPath $targetPck)) { throw "Installed game files are incomplete." }
    Copy-Item -LiteralPath $targetExe -Destination $backup
    Copy-Item -LiteralPath $targetPck -Destination $backup
    try {
        Copy-Item -LiteralPath $newExe -Destination $targetExe -Force
        Copy-Item -LiteralPath $newPck -Destination $targetPck -Force
    } catch {
        Copy-Item -LiteralPath (Join-Path $backup $ExecutableName) -Destination $targetExe -Force
        Copy-Item -LiteralPath (Join-Path $backup "GALACTIC-FRONTIER.pck") -Destination $targetPck -Force
        throw
    }
    Add-Content -LiteralPath $log -Value ("{0:u} Update installed." -f (Get-Date))
    Start-Process -FilePath $targetExe -WorkingDirectory $InstallDir
} catch {
    Add-Content -LiteralPath $log -Value ("{0:u} UPDATE FAILED: {1}" -f (Get-Date), $_.Exception.Message)
    if (Test-Path -LiteralPath (Join-Path $backup $ExecutableName)) {
        Copy-Item -LiteralPath (Join-Path $backup $ExecutableName) -Destination (Join-Path $InstallDir $ExecutableName) -Force
        Copy-Item -LiteralPath (Join-Path $backup "GALACTIC-FRONTIER.pck") -Destination (Join-Path $InstallDir "GALACTIC-FRONTIER.pck") -Force
    }
    Start-Process -FilePath (Join-Path $InstallDir $ExecutableName) -WorkingDirectory $InstallDir
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $Archive -Force -ErrorAction SilentlyContinue
}
