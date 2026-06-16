# TraceAR - Automated Flutter Setup & Android Build Script
# Run this script from PowerShell as Administrator for best results

param(
    [string]$FlutterPath = "C:\flutter",
    [switch]$SkipFlutterInstall = $false
)

$ErrorActionPreference = "Continue"
$ProjectPath = $PSScriptRoot

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  TraceAR - Android Build Setup Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# STEP 1: Install Flutter SDK (or skip)
Write-Host "[1/6] Installing Flutter SDK..." -ForegroundColor Yellow
if (-not $SkipFlutterInstall) {
    $flutterExe = "$FlutterPath\bin\flutter.bat"
    if (Test-Path $flutterExe) {
        Write-Host "  [OK] Flutter already found at $FlutterPath" -ForegroundColor Green
    } else {
        $flutterZip = "$env:TEMP\flutter_stable.zip"
        $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip"
        try {
            Import-Module BitsTransfer -ErrorAction SilentlyContinue
            Start-BitsTransfer -Source $flutterUrl -Destination $flutterZip -Description "Downloading Flutter SDK"
        } catch {
            Write-Host "  BitsTransfer failed, falling back to WebClient..." -ForegroundColor Gray
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($flutterUrl, $flutterZip)
        }

        Write-Host "  [INFO] Extracting Flutter SDK to $FlutterPath..." -ForegroundColor Yellow
        if (Test-Path $FlutterPath) { Remove-Item $FlutterPath -Recurse -Force }
        Expand-Archive -Path $flutterZip -DestinationPath (Split-Path $FlutterPath -Parent) -Force
        $extractedFolder = Join-Path (Split-Path $FlutterPath -Parent) "flutter"
        if ($extractedFolder -ne $FlutterPath -and (Test-Path $extractedFolder)) {
            Rename-Item $extractedFolder $FlutterPath -Force
        }
        Remove-Item $flutterZip -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Flutter SDK extracted successfully." -ForegroundColor Green
    }

    $env:PATH = "$FlutterPath\bin;$env:PATH"
    Write-Host "  [OK] Flutter added to session PATH." -ForegroundColor Green
} else {
    Write-Host "[1/6] Skipping Flutter install (using existing)." -ForegroundColor Gray
    $env:PATH = "$FlutterPath\bin;$env:PATH"
}

# STEP 2: Locate Android SDK
Write-Host ""
Write-Host "[2/6] Locating Android SDK..." -ForegroundColor Yellow

$androidSdkPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:USERPROFILE\AppData\Local\Android\Sdk",
    "C:\Android\Sdk",
    "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
)

$androidSdk = $null
foreach ($path in $androidSdkPaths) {
    if (Test-Path "$path\platform-tools") {
        $androidSdk = $path
        break
    }
}

if ($androidSdk) {
    Write-Host "  [OK] Android SDK found: $androidSdk" -ForegroundColor Green
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
    $env:PATH = "$androidSdk\platform-tools;$androidSdk\tools\bin;$env:PATH"
} else {
    Write-Host "  [WARNING] Android SDK not found. Install Android Studio or set ANDROID_HOME." -ForegroundColor Yellow
}

# STEP 3: Write local.properties
Write-Host ""
Write-Host "[3/6] Writing android/local.properties..." -ForegroundColor Yellow

$localProps = "flutter.sdk=$($FlutterPath -replace '\\','\\')`r`n"
if ($androidSdk) {
    $localProps += "sdk.dir=$($androidSdk -replace '\\','\\')`r`n"
} else {
    $localProps += "# sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk`r`n"
}
$localProps += "flutter.compileSdkVersion=34`r`n"
$localProps += "flutter.minSdkVersion=21`r`n"
$localProps += "flutter.targetSdkVersion=34`r`n"
$localPropsPath = Join-Path $ProjectPath "android\local.properties"
[System.IO.File]::WriteAllText($localPropsPath, $localProps)
Write-Host "  [OK] local.properties written." -ForegroundColor Green

# STEP 4: Create asset directories
Write-Host ""
Write-Host "[4/6] Creating asset directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path (Join-Path $ProjectPath "assets\images") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $ProjectPath "assets\icons") | Out-Null
Write-Host "  [OK] assets directories created." -ForegroundColor Green

# STEP 5: Flutter pub get
Write-Host ""
Write-Host "[5/6] Running flutter pub get..." -ForegroundColor Yellow
Set-Location $ProjectPath
& "$FlutterPath\bin\flutter.bat" pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Dependencies resolved." -ForegroundColor Green
} else {
    Write-Host "  [WARNING] pub get failed." -ForegroundColor Yellow
}

# STEP 6: Build APK
Write-Host ""
Write-Host "[6/6] Building Android APK (debug)..." -ForegroundColor Yellow
& "$FlutterPath\bin\flutter.bat" build apk --debug --verbose
if ($LASTEXITCODE -eq 0) {
    $apkPath = Join-Path $ProjectPath "build\app\outputs\flutter-apk\app-debug.apk"
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  APK Location:" -ForegroundColor Cyan
    Write-Host "  $apkPath" -ForegroundColor White
    Write-Host ""
    Write-Host "  To install on device: adb install $apkPath" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    Write-Host "==================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Common fixes:" -ForegroundColor Yellow
    Write-Host "  1. Install Android Studio" -ForegroundColor White
    Write-Host "  2. Accept Android SDK licenses: flutter doctor --android-licenses" -ForegroundColor White
}
Write-Host ""
Write-Host "Flutter Doctor output:" -ForegroundColor Cyan
& "$FlutterPath\bin\flutter.bat" doctor
