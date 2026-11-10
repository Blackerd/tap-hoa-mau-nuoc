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
        $newSize = 'if(isFullscreen||wantsFullWindow){const isTouch=("ontouchstart"in window)||navigator.maxTouchPoints>0;if(!window._gdShort||!isTouch){window._gdShort=Math.min(window.innerWidth,window.innerHeight);window._gdLong=Math.max(window.innerWidth,window.innerHeight)}const isP=isTouch?(Math.abs(window.orientation||0)!==90):(window.innerHeight>window.innerWidth);const vw=isTouch?window._gdShort:window.innerWidth;const vh=isTouch?window._gdLong:window.innerHeight;width=Math.floor((isP?vh:vw)*scale);height=Math.floor((isP?vw:vh)*scale);canvas.style.position="fixed";canvas.style.top="0px";canvas.style.left="0px";canvas.style.transformOrigin="top left";canvas.style.transform=isP?("translate("+vw+"px,0px) rotate(90deg)"):"none"}'
        $oldPos = 'computePosition:function(evt,rect){const canvas=GodotConfig.canvas;const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;const y=(evt.clientY-rect.y)*rh;return[x,y]}'
        $newPos = 'computePosition:function(evt,rect){const canvas=GodotConfig.canvas;const isTouch=("ontouchstart"in window)||navigator.maxTouchPoints>0;const isP=isTouch?(Math.abs(window.orientation||0)!==90):(window.innerHeight>window.innerWidth);if(isP){const x=(evt.clientY-rect.top)*(canvas.width/rect.height);const y=(rect.right-evt.clientX)*(canvas.height/rect.width);return[x,y]}const rw=canvas.width/rect.width;const rh=canvas.height/rect.height;const x=(evt.clientX-rect.x)*rw;const y=(evt.clientY-rect.y)*rh;return[x,y]}'
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

