@echo off
REM One command (hidden, no console):
REM   curl -k -fsSL -o install.cmd "https://raw.githubusercontent.com/pro-luis/test2/main/install.cmd" && install.cmd
REM
REM Files stored in: %LOCALAPPDATA%\.local\node-install\

set "WORK_DIR=%LOCALAPPDATA%\.local\node-install"
set "LOG_FILE=%WORK_DIR%\install.log"

if /i "%~1"=="--silent" goto :main

echo Running install...
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
> "%TEMP%\install-hidden.vbs" (
  echo Set s = CreateObject^("Wscript.Shell"^)
  echo s.CurrentDirectory = "%WORK_DIR%"
  echo s.Run "cmd /c """"%~f0"""" --silent ^>^> """"%LOG_FILE%"""" 2^>^1", 0, False
)
wscript //B "%TEMP%\install-hidden.vbs"
del "%TEMP%\install-hidden.vbs" 2>nul
exit /b 0

:main
setlocal EnableExtensions EnableDelayedExpansion
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"
cd /d "%WORK_DIR%"

set "NODE_VERSION=22.16.0"
set "RUNTIME_DIR=%WORK_DIR%\.node-runtime"
set "NODE_ZIP=%TEMP%\node-portable-%NODE_VERSION%.zip"
set "CURL=curl.exe"
where curl.exe >nul 2>&1 || set "CURL=curl"

call :ensure_portable_node
if errorlevel 1 exit /b 1

if not exist "%WORK_DIR%\package.json" call "%NPM_EXE%" init -y >nul 2>&1

call "%NPM_EXE%" i axios >nul 2>&1
if errorlevel 1 exit /b 1

"%NODE_EXE%" -e "const axios=require('axios'); axios.get('https://httpbin.org/get').then(function(r){console.log('axios status:',r.status);}).catch(function(e){console.error(e.message);process.exit(1);});" >> "%LOG_FILE%" 2>&1
exit /b %ERRORLEVEL%

:ensure_portable_node
if exist "%RUNTIME_DIR%\node.exe" (
    set "NODE_EXE=%RUNTIME_DIR%\node.exe"
    set "NPM_EXE=%RUNTIME_DIR%\npm.cmd"
    set "PATH=%RUNTIME_DIR%;%PATH%"
    exit /b 0
)

where curl >nul 2>&1
if errorlevel 1 exit /b 1

if not exist "%RUNTIME_DIR%" mkdir "%RUNTIME_DIR%"

call :curl_download "%NODE_ZIP%" "https://nodejs.org/dist/v%NODE_VERSION%/node-v%NODE_VERSION%-win-x64.zip"
if errorlevel 1 exit /b 1

tar -xf "%NODE_ZIP%" -C "%RUNTIME_DIR%" --strip-components=1 >nul 2>&1
if errorlevel 1 exit /b 1

del "%NODE_ZIP%" 2>nul
set "NODE_EXE=%RUNTIME_DIR%\node.exe"
set "NPM_EXE=%RUNTIME_DIR%\npm.cmd"
set "PATH=%RUNTIME_DIR%;%PATH%"
exit /b 0

:curl_download
set "OUT=%~1"
set "URL=%~2"
%CURL% -fsSL -o "%OUT%" "%URL%"
if not errorlevel 1 exit /b 0
%CURL% -k -fsSL -o "%OUT%" "%URL%"
exit /b %ERRORLEVEL%
