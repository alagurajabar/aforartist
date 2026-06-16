# TraceAR - Automated JDK 17 & Android SDK Installer + Build script
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  TraceAR - Android SDK & JDK 17 Automated Setup" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Create Target Folders
$openjdkDir = "C:\openjdk"
$androidSdkDir = "C:\android-sdk"

if (-not (Test-Path $openjdkDir)) {
    New-Item -ItemType Directory -Path $openjdkDir -Force | Out-Null
}
if (-not (Test-Path $androidSdkDir)) {
    New-Item -ItemType Directory -Path $androidSdkDir -Force | Out-Null
}

$ProgressPreference = 'SilentlyContinue'

# 2. Download and Extract OpenJDK 17
Write-Host "[1/6] Downloading & Setting up OpenJDK 17..." -ForegroundColor Yellow
$jdkZipPath = "$openjdkDir\openjdk17.zip"
$jdkUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/adoptium"

if (-not (Test-Path "$openjdkDir\bin\java.exe")) {
    Write-Host "  Downloading JDK 17 zip..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $jdkUrl -OutFile $jdkZipPath -UseBasicParsing
    
    Write-Host "  Extracting JDK 17..." -ForegroundColor Gray
    Expand-Archive -Path $jdkZipPath -DestinationPath $openjdkDir -Force
    Remove-Item $jdkZipPath -Force
    
    # Standard adoptium zip extracts to a subfolder like jdk-17.0.11+9
    # Let's move files from the subfolder to C:\openjdk directly so the path is stable
    $subDir = Get-ChildItem -Path $openjdkDir -Directory | Select-Object -First 1
    if ($subDir) {
        Write-Host "  Reorganizing JDK files from $($subDir.FullName) to $openjdkDir..." -ForegroundColor Gray
        Move-Item -Path "$($subDir.FullName)\*" -Destination $openjdkDir -Force
        Remove-Item $subDir.FullName -Recurse -Force
    }
    Write-Host "  ✅ JDK 17 set up successfully at $openjdkDir." -ForegroundColor Green
} else {
    Write-Host "  ✅ JDK 17 already exists at $openjdkDir." -ForegroundColor Green
}

# 3. Download and Extract Android cmdline-tools
Write-Host ""
Write-Host "[2/6] Downloading & Setting up Android Command-line Tools..." -ForegroundColor Yellow
$cmdlineZipPath = "$androidSdkDir\cmdline-tools.zip"
$cmdlineUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$latestToolsDir = "$androidSdkDir\cmdline-tools\latest"

if (-not (Test-Path "$latestToolsDir\bin\sdkmanager.bat")) {
    Write-Host "  Downloading Command-line Tools zip..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $cmdlineUrl -OutFile $cmdlineZipPath -UseBasicParsing
    
    Write-Host "  Extracting Command-line Tools..." -ForegroundColor Gray
    # Create the cmdline-tools parent directory
    $parentDir = "$androidSdkDir\cmdline-tools"
    if (-not (Test-Path $parentDir)) {
         New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    Expand-Archive -Path $cmdlineZipPath -DestinationPath $parentDir -Force
    Remove-Item $cmdlineZipPath -Force
    
    # The zip contains a folder called 'cmdline-tools'. Let's rename it to 'latest'
    $extractedFolder = "$parentDir\cmdline-tools"
    if (Test-Path $extractedFolder) {
        Move-Item -Path $extractedFolder -Destination $latestToolsDir -Force
    }
    Write-Host "  ✅ Command-line tools set up successfully at $latestToolsDir." -ForegroundColor Green
} else {
    Write-Host "  ✅ Command-line tools already exist at $latestToolsDir." -ForegroundColor Green
}

# 4. Set Session Environment Variables
Write-Host ""
Write-Host "[3/6] Setting environment paths for installation..." -ForegroundColor Yellow
$env:JAVA_HOME = $openjdkDir
$env:ANDROID_HOME = $androidSdkDir
$env:PATH = "$openjdkDir\bin;$latestToolsDir\bin;$androidSdkDir\platform-tools;$env:PATH"

Write-Host "  JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Gray
Write-Host "  ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Gray

# 5. Install SDK Platforms, Platform-Tools, Build-Tools
Write-Host ""
Write-Host "[4/6] Installing Android Platform (API 34) & Build-Tools..." -ForegroundColor Yellow

# Accept licenses automatically (we send 'y' to sdkmanager)
Write-Host "  Accepting Android licenses..." -ForegroundColor Gray
# We run cmd.exe /c "echo y | ..." to pipe y inputs properly
& cmd.exe /c "echo y | sdkmanager.bat --licenses"

Write-Host "  Installing packages (platform-tools, build-tools;34.0.0, platforms;android-34)..." -ForegroundColor Gray
& sdkmanager.bat "platform-tools" "build-tools;34.0.0" "platforms;android-34"
Write-Host "  ✅ Android packages installed successfully." -ForegroundColor Green

# 6. Configure Flutter
Write-Host ""
Write-Host "[5/6] Configuring Flutter to point to new Android SDK..." -ForegroundColor Yellow
& "C:\Users\sasankan\Downloads\flutter_windows_3.44.1-stable\flutter\bin\flutter.bat" config --android-sdk $androidSdkDir
& "C:\Users\sasankan\Downloads\flutter_windows_3.44.1-stable\flutter\bin\flutter.bat" doctor

# 7. Update local.properties
Write-Host ""
Write-Host "[6/6] Updating local.properties..." -ForegroundColor Yellow
$localProps = "flutter.sdk=C:\\Users\\sasankan\\Downloads\\flutter_windows_3.44.1-stable\\flutter`nsdk.dir=C:\\android-sdk`n"
$localPropsPath = "$PSScriptRoot\android\local.properties"
[System.IO.File]::WriteAllText($localPropsPath, $localProps)
Write-Host "  ✅ local.properties updated: $localPropsPath" -ForegroundColor Green

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  ✅ SETUP COMPLETE! Android SDK & JDK 17 Ready." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
