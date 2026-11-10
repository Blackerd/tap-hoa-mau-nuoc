param(
    [string]$GodotExe = "C:\Users\Duong\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Re-importing modified assets..." -ForegroundColor Yellow
& $GodotExe --headless --path $ProjectPath --import
Write-Host "Running Automated E2E Screenshot Suite for Tap Hoa Mau Nuoc..." -ForegroundColor Cyan
& $GodotExe --path $ProjectPath "res://scenes/e2e_test_runner.tscn"
Write-Host "Screenshots saved to: $ProjectPath\test_screenshots" -ForegroundColor Green
