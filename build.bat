@echo off
if not exist bin mkdir bin
if exist assets xcopy /E /I /Y /Q assets bin\assets >nul

echo Building Hellfire (Odin)...
odin build src -out:bin\hellfire.exe -debug

if %ERRORLEVEL% equ 0 (
    echo Build successful!
    if "%1"=="run" (
        bin\hellfire.exe
    )
) else (
    echo Build failed with error code %ERRORLEVEL%
)
