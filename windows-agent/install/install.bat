@echo off
echo ========================================
echo LLMBridge Windows Agent Installer
echo ========================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Set installation directory
set INSTALL_DIR=C:\LLMBridge
set SERVICE_NAME=LLMBridgeAgent

echo Installation directory: %INSTALL_DIR%
echo.

REM Create installation directory
if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
)

REM Copy files
echo Copying files...
copy /Y windows-agent.exe "%INSTALL_DIR%\"
if exist llmbridge-agent.yaml (
    copy /Y llmbridge-agent.yaml "%INSTALL_DIR%\"
) else if exist config.yaml (
    copy /Y config.yaml "%INSTALL_DIR%\llmbridge-agent.yaml"
) else (
    echo ERROR: Config file not found!
    pause
    exit /b 1
)

REM Check if NSSM exists
where nssm >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo WARNING: NSSM not found in PATH
    echo Please download NSSM from: https://nssm.cc/download
    echo And install the service manually using:
    echo   nssm install %SERVICE_NAME% "%INSTALL_DIR%\windows-agent.exe"
    echo   nssm set %SERVICE_NAME% Start SERVICE_AUTO_START
    echo   nssm start %SERVICE_NAME%
    pause
    exit /b 1
)

REM Stop existing service if running
sc query %SERVICE_NAME% >nul 2>&1
if %errorLevel% equ 0 (
    echo Stopping existing service...
    nssm stop %SERVICE_NAME%
    timeout /t 2 /nobreak >nul
    echo Removing existing service...
    nssm remove %SERVICE_NAME% confirm
)

REM Install service
echo Installing Windows service...
nssm install %SERVICE_NAME% "%INSTALL_DIR%\windows-agent.exe"
nssm set %SERVICE_NAME% AppDirectory "%INSTALL_DIR%"
nssm set %SERVICE_NAME% Start SERVICE_AUTO_START
nssm set %SERVICE_NAME% DisplayName "LLMBridge Agent"
nssm set %SERVICE_NAME% Description "Remote control agent for LLMBridge-PC system"

REM Configure firewall
echo Configuring Windows Firewall...
netsh advfirewall firewall delete rule name="LLMBridge Agent" >nul 2>&1
netsh advfirewall firewall add rule name="LLMBridge Agent" dir=in action=allow protocol=TCP localport=8888

REM Start service
echo Starting service...
nssm start %SERVICE_NAME%

echo.
echo ========================================
echo Installation complete!
echo ========================================
echo.
echo Service Name: %SERVICE_NAME%
echo Installation Directory: %INSTALL_DIR%
echo Port: 8888
echo.
echo IMPORTANT: Edit %INSTALL_DIR%\llmbridge-agent.yaml to change the auth token!
echo.
echo Service commands:
echo   Start:   nssm start %SERVICE_NAME%
echo   Stop:    nssm stop %SERVICE_NAME%
echo   Restart: nssm restart %SERVICE_NAME%
echo   Status:  sc query %SERVICE_NAME%
echo.
pause
