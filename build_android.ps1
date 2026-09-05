param(
    [string]$Action = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "         Hellfire - Android Build Pipeline             " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Detect Java
if (-not $env:JAVA_HOME) {
    if (Test-Path "C:\Program Files\Android\openjdk\jdk-21.0.8") {
        $env:JAVA_HOME = "C:\Program Files\Android\openjdk\jdk-21.0.8"
    } elseif (Test-Path "C:\Program Files\Android\Android Studio\jbr") {
        $env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
    }
}
if ($env:JAVA_HOME) {
    Write-Host "[OK] Using JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
    $env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
} else {
    Write-Host "[!] WARNING: JAVA_HOME not set. Using system java." -ForegroundColor Yellow
}

# 2. Detect Android SDK
if (-not $env:ANDROID_HOME) {
    if (Test-Path "C:\Program Files (x86)\Android\android-sdk") {
        $env:ANDROID_HOME = "C:\Program Files (x86)\Android\android-sdk"
    } elseif (Test-Path "$env:LOCALAPPDATA\Android\Sdk") {
        $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
    }
}
if ($env:ANDROID_HOME) {
    Write-Host "[OK] Using ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Green
    $env:PATH = "$env:ANDROID_HOME\platform-tools;$env:PATH"
} else {
    Write-Host "[ERROR] Android SDK not found! Please install Android Studio or set ANDROID_HOME." -ForegroundColor Red
    exit 1
}

# 3. Detect Android NDK
$ndkPath = $null
if (Test-Path "$env:ANDROID_HOME\ndk") {
    $ndkDirs = Get-ChildItem -Directory "$env:ANDROID_HOME\ndk" | Sort-Object Name -Descending
    if ($ndkDirs.Count -gt 0) {
        $ndkPath = $ndkDirs[0].FullName
    }
}
if (-not $ndkPath -and $env:ANDROID_NDK_HOME) {
    $ndkPath = $env:ANDROID_NDK_HOME
}

if (-not $ndkPath) {
    Write-Host ""
    Write-Host "[!] Android NDK was not detected in $env:ANDROID_HOME\ndk!" -ForegroundColor Yellow
    Write-Host "To install the NDK:" -ForegroundColor Yellow
    Write-Host "  1. In Android Studio: Tools -> SDK Manager -> SDK Tools tab."
    Write-Host "  2. Check 'NDK (Side by side)' and click OK."
    Write-Host "  Or run: & `"$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat`" --install `"ndk;26.1.10909125`""
    Write-Host ""
    exit 1
}

Write-Host "[OK] Using Android NDK: $ndkPath" -ForegroundColor Green
$env:ODIN_ANDROID_NDK = $ndkPath
$env:ANDROID_NDK_HOME = $ndkPath

# 4. Build / Check Raylib for Android ARM64
$raylibLib = "android\raylib-build\raylib\libraylib.a"
if (-not (Test-Path $raylibLib)) {
    Write-Host "[INFO] Compiling Raylib for Android ARM64..." -ForegroundColor Cyan
    if (-not (Test-Path "android\raylib-src")) {
        Write-Host "[INFO] Cloning Raylib repository..."
        git clone --depth 1 --branch 5.5 https://github.com/raysan5/raylib.git android\raylib-src
    }
    cmake -S android\raylib-src -B android\raylib-build `
        -DCMAKE_TOOLCHAIN_FILE="$ndkPath\build\cmake\android.toolchain.cmake" `
        -DANDROID_ABI=arm64-v8a `
        -DANDROID_PLATFORM=android-34 `
        -DPLATFORM=Android `
        -DBUILD_EXAMPLES=OFF `
        -DCMAKE_BUILD_TYPE=Release
    cmake --build android\raylib-build --target raylib
    if (-not (Test-Path $raylibLib)) {
        Write-Host "[ERROR] Failed to compile Raylib for Android!" -ForegroundColor Red
        exit 1
    }
}

# 5. Copy Raylib and stubs to NDK sysroot
$sysrootDir = "$ndkPath\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android"
if (-not (Test-Path "$sysrootDir\34")) { New-Item -ItemType Directory -Force -Path "$sysrootDir\34" | Out-Null }
Copy-Item -Force $raylibLib "$sysrootDir\libraylib.a"
Copy-Item -Force $raylibLib "$sysrootDir\34\libraylib.a"

$llvmAr = "$ndkPath\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-ar.exe"
if (Test-Path $llvmAr) {
    & $llvmAr cr "$sysrootDir\libX11.a" 2>$null
    & $llvmAr cr "$sysrootDir\34\libX11.a" 2>$null
    & $llvmAr cr "$sysrootDir\libpthread.a" 2>$null
    & $llvmAr cr "$sysrootDir\34\libpthread.a" 2>$null
}

# 6. Compile Odin Code to Shared Library
Write-Host "[INFO] Compiling Odin native library (libhellfire.so)..." -ForegroundColor Cyan
$jniDir = "android\app\src\main\jniLibs\arm64-v8a"
if (-not (Test-Path $jniDir)) { New-Item -ItemType Directory -Force -Path $jniDir | Out-Null }

odin build src -target:linux_arm64 -subtarget:android -build-mode:shared `
    -out:"$jniDir\libhellfire.so" -o:speed `
    -extra-linker-flags:"-lEGL -lGLESv2 -landroid -llog -lOpenSLES"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Odin compilation failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "[OK] libhellfire.so created successfully!" -ForegroundColor Green

# 7. Sync Assets
Write-Host "[INFO] Syncing game assets to Android project..." -ForegroundColor Cyan
$assetsTarget = "android\app\src\main\assets"
if (-not (Test-Path $assetsTarget)) { New-Item -ItemType Directory -Force -Path $assetsTarget | Out-Null }
Copy-Item -Recurse -Force assets/* $assetsTarget

if ($Action -eq "native-only") {
    Write-Host "[OK] Native library and assets ready for Android Studio!" -ForegroundColor Green
    exit 0
}

# 8. Package APK with Gradle
Write-Host "[INFO] Building APK via Gradle..." -ForegroundColor Cyan
Push-Location android
try {
    .\gradlew.bat assembleDebug --console=plain
} finally {
    Pop-Location
}

$apkPath = "android\app\build\outputs\apk\debug\app-debug.apk"
if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] APK build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "[SUCCESS] APK built successfully!" -ForegroundColor Green
Write-Host "Path: $apkPath" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# 9. Optional: Install & Run on Emulator or USB Device
if ($Action -eq "run") {
    Write-Host "[INFO] Deploying to active device / emulator..." -ForegroundColor Cyan
    adb install -r $apkPath
    adb shell am start -n com.recluse.hellfire/android.app.NativeActivity
}
