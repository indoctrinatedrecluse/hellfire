@echo off
if not exist bin mkdir bin

echo Building Hellfire (Odin)...
odin build src -out:bin\hellfire.exe -debug

if %ERRORLEVEL% equ 0 (
    echo Build successful! Running bin\hellfire.exe...
    if "%1"=="run" (
        bin\hellfire.exe
    )
) else (
    echo Build failed with error code %ERRORLEVEL%
)

