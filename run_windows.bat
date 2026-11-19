@echo off
rem ============================================================================
rem � Yemilue Windows Launcher
rem Run on any Windows PC from flash drive
rem ============================================================================

setlocal
cd /d "%~dp0"

if exist "%~dp0yemilue.exe" (
    echo [yemilue] Launching native Windows binary...
    "%~dp0yemilue.exe" %*
    goto end
)

where cargo >nul 2>nul
if %errorlevel% equ 0 (
    echo [yemilue] Compiling offline from vendored sources...
    cargo run --release %*
    goto end
)

echo.
echo [ERROR] yemilue binary for Windows not found and Cargo is not installed.
echo To run on this Windows machine:
echo   1. Install Rust via https://rustup.rs (or copy portable cargo)
echo   2. Run 'cargo run --release' (all crates are already vendored offline)
echo.
pause

:end
endlocal
