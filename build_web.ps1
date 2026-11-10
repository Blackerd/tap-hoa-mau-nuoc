param(
    [string]$GodotExe = "C:\Users\Duong\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir = Join-Path $ProjectPath "build\web"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Exporting Tap Hoa Mau Nuoc to Web (HTML5 / WebGL2 Single-Thread)..." -ForegroundColor Cyan
& $GodotExe --headless --path $ProjectPath --export-release "Web" "$OutDir\index.html"

if (Test-Path "$OutDir\index.html") {
    Write-Host "Web build succeeded! Output: $OutDir\index.html" -ForegroundColor Green
    Write-Host "To test locally: python -m http.server 8080 --directory `"$OutDir`"" -ForegroundColor Yellow
} else {
    Write-Host "Note: Make sure Godot 4.7.2 Export Templates are installed in Editor -> Manage Export Templates." -ForegroundColor Yellow
}

