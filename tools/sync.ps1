```powershell
$ErrorActionPreference = "Stop"

# ============================================================
# Create SVO - Minecraft Sync Tool
# ============================================================

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $ProjectRoot ".local-sync.json"

function Pause-Script {
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# ============================================================
# First run - create local config
# ============================================================

if (-not (Test-Path -LiteralPath $ConfigFile)) {

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       CREATE SVO - FIRST RUN" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Git project:"
    Write-Host $ProjectRoot
    Write-Host ""

    Write-Host "Enter the path to your Minecraft instance folder."
    Write-Host "Example:"
    Write-Host "C:\Users\User\AppData\Roaming\PrismLauncher\instances\MyPack\minecraft"
    Write-Host ""

    $InstancePath = Read-Host "Minecraft path"
    $InstancePath = $InstancePath.Trim('"').Trim()

    if (-not (Test-Path -LiteralPath $InstancePath -PathType Container)) {
        Write-Host ""
        Write-Host "ERROR: Directory does not exist:" -ForegroundColor Red
        Write-Host $InstancePath -ForegroundColor Red
        Pause-Script
        exit 1
    }

    $Config = @{
        instancePath = $InstancePath
        folders = @(
            "mods",
            "config",
            "kubejs",
            "scripts"
        )
    }

    $Config | ConvertTo-Json -Depth 5 |
        Set-Content -LiteralPath $ConfigFile -Encoding UTF8

    Write-Host ""
    Write-Host "Local configuration created:" -ForegroundColor Green
    Write-Host $ConfigFile
    Write-Host ""
}

# ============================================================
# Load configuration
# ============================================================

try {
    $Config = Get-Content -LiteralPath $ConfigFile -Raw |
        ConvertFrom-Json
}
catch {
    Write-Host ""
    Write-Host "ERROR: Could not read configuration file." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Pause-Script
    exit 1
}

$InstancePath = $Config.instancePath
$Folders = @($Config.folders)

if (-not (Test-Path -LiteralPath $InstancePath -PathType Container)) {
    Write-Host ""
    Write-Host "ERROR: Minecraft directory does not exist:" -ForegroundColor Red
    Write-Host $InstancePath -ForegroundColor Red
    Pause-Script
    exit 1
}

# ============================================================
# Copy function
# ============================================================

function Sync-Folder {
    param (
        [string]$Folder,
        [string]$SourceRoot,
        [string]$TargetRoot
    )

    $Source = Join-Path $SourceRoot $Folder
    $Target = Join-Path $TargetRoot $Folder

    Write-Host ""
    Write-Host "[$Folder]" -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        Write-Host "  Source folder does not exist. Skipping." -ForegroundColor DarkYellow
        return
    }

    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
    }

    & robocopy `
        $Source `
        $Target `
        /E `
        /R:0 `
        /W:0 `
        /COPY:DAT `
        /DCOPY:DAT `
        /XJ `
        /NP `
        /TEE

    $ExitCode = $LASTEXITCODE

    if ($ExitCode -ge 8) {
        Write-Host ""
        Write-Host "  COPY ERROR!" -ForegroundColor Red
        Write-Host "  Robocopy exit code: $ExitCode" -ForegroundColor Red
    }
    elseif ($ExitCode -ge 1) {
        Write-Host "  Changes copied." -ForegroundColor Green
    }
    else {
        Write-Host "  No changes." -ForegroundColor DarkGray
    }
}

# ============================================================
# Main menu
# ============================================================

while ($true) {

    Clear-Host

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       CREATE SVO - SYNC TOOL" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Git project:"
    Write-Host "  $ProjectRoot"
    Write-Host ""

    Write-Host "Minecraft instance:"
    Write-Host "  $InstancePath"
    Write-Host ""

    Write-Host "Folders:"
    foreach ($Folder in $Folders) {
        Write-Host "  - $Folder"
    }

    Write-Host ""
    Write-Host "----------------------------------------"
    Write-Host ""

    Write-Host "1. Minecraft -> Git"
    Write-Host "2. Git -> Minecraft"
    Write-Host "3. Change Minecraft path"
    Write-Host "4. Exit"
    Write-Host ""

    $Choice = Read-Host "Select"

    # ========================================================
    # Minecraft -> Git
    # ========================================================

    if ($Choice -eq "1") {

        Write-Host ""
        Write-Host "Minecraft -> Git" -ForegroundColor Cyan
        Write-Host ""

        foreach ($Folder in $Folders) {
            Sync-Folder `
                -Folder $Folder `
                -SourceRoot $InstancePath `
                -TargetRoot $ProjectRoot
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Sync finished." -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green

        Pause-Script
    }

    # ========================================================
    # Git -> Minecraft
    # ========================================================

    elseif ($Choice -eq "2") {

        Write-Host ""
        Write-Host "WARNING!" -ForegroundColor Yellow
        Write-Host "This will copy files from Git into Minecraft."
        Write-Host ""

        $Confirm = Read-Host "Continue? (y/n)"

        if ($Confirm -ne "y" -and $Confirm -ne "Y") {
            continue
        }

        Write-Host ""
        Write-Host "Git -> Minecraft" -ForegroundColor Cyan
        Write-Host ""

        foreach ($Folder in $Folders) {
            Sync-Folder `
                -Folder $Folder `
                -SourceRoot $ProjectRoot `
                -TargetRoot $InstancePath
        }

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Sync finished." -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green

        Pause-Script
    }

    # ========================================================
    # Change Minecraft path
    # ========================================================

    elseif ($Choice -eq "3") {

        Write-Host ""
        Write-Host "Current path:"
        Write-Host $InstancePath
        Write-Host ""

        $NewPath = Read-Host "New Minecraft path"
        $NewPath = $NewPath.Trim('"').Trim()

        if (-not (Test-Path -LiteralPath $NewPath -PathType Container)) {
            Write-Host ""
            Write-Host "ERROR: Directory does not exist." -ForegroundColor Red
            Pause-Script
            continue
        }

        $Config.instancePath = $NewPath

        $Config | ConvertTo-Json -Depth 5 |
            Set-Content -LiteralPath $ConfigFile -Encoding UTF8

        $InstancePath = $NewPath

        Write-Host ""
        Write-Host "Path updated." -ForegroundColor Green

        Start-Sleep -Seconds 1
    }

    # ========================================================
    # Exit
    # ========================================================

    elseif ($Choice -eq "4") {
        break
    }

    else {
        Write-Host ""
        Write-Host "Unknown option." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}
```
