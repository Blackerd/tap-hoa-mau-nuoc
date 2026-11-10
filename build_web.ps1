param(
    [string]$GodotExe = "C:\Users\Duong\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)

$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir = Join-Path $ProjectPath "build\web"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "Exporting Tap Hoa Mau Nuoc to Web (HTML5 / WebGL2 Single-Thread)..." -ForegroundColor Cyan
& $GodotExe --headless --path $ProjectPath --export-release "Web" "$OutDir\index.html"

if (Test-Path "$OutDir\index.html") {
    $JsPath = "$OutDir\index.js"
    if (Test-Path $JsPath) {
        Write-Host "Patching index.js with Mobile Portrait-to-Landscape Auto-Rotate 90deg & Touch Remap..." -ForegroundColor Cyan
        $js = [System.IO.File]::ReadAllText($JsPath)
        $oldSize = 'if(isFullscreen||wantsFullWindow){width=Math.floor(window.innerWidth*scale);height=Math.floor(window.innerHeight*scale)}'
        $newSize = 'if(isFullscreen||wantsFullWindow){const isP=window.innerHeight>window.innerWidth;width=Math.floor((isP?window.innerHeight:window.innerWidth)*scale);height=Math.floor((isP?window.innerWidth:window.innerHeight)*scale);canvas.style.position="fixed";canvas.style.top="0";canvas.style.left="0";canvas.style.transformOrigin="top left";canvas.style.transform=isP?"translate(100vw,0) rotate(90deg)":"none"}'
        $oldPos = 'computePosition:function(evt,rect){const canvas=GodotConfig.canvas;const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;const y=(evt.clientY-rect.y)*rh;return[x,y]}'
        $newPos = 'computePosition:function(evt,rect){const canvas=GodotConfig.canvas;if(window.innerHeight>window.innerWidth){const x=(evt.clientY-rect.top)*(canvas.width/rect.height);const y=(rect.right-evt.clientX)*(canvas.height/rect.width);return[x,y]}const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;const y=(evt.clientY-rect.y)*rh;return[x,y]}'
        $js = $js.Replace($oldSize, $newSize).Replace($oldPos, $newPos)
        [System.IO.File]::WriteAllText($JsPath, $js)
    }
    $ZipPath = Join-Path $ProjectPath "build\tap_hoa_mau_nuoc_web.zip"
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path "$OutDir\*" -DestinationPath $ZipPath -Force
    Write-Host "Web build & zip succeeded! Output: $ZipPath" -ForegroundColor Green
    Write-Host "To test locally: python -m http.server 8080 --directory `"$OutDir`"" -ForegroundColor Yellow
} else {
    Write-Host "Note: Make sure Godot 4.7.2 Export Templates are installed in Editor -> Manage Export Templates." -ForegroundColor Yellow
}

