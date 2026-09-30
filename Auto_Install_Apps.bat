@echo off
setlocal

cd /d "%~dp0"

:: ==================================================
:: CONFIGURACION
:: ==================================================

set "SCRIPT=%~f0"
set "CONFIGURAR_PERFIL=%~dp0ConfigurarPerfil.ps1"
set "APPDIR=%~dp0aplicaciones"

set "ADOBE=%APPDIR%\AcroRdrDC2300820533_es_ES.exe"
set "CHROME=%APPDIR%\ChromeSetup.exe"
set "TEAMS=%APPDIR%\MSTeamsSetup.exe"
set "OFFICE=%APPDIR%\OfficeSetup365.exe"
set "VLC=%APPDIR%\vlc-3.0.12-win64.exe"
set "WINRAR=%APPDIR%\winrar-x64-600es.exe"
set "CM=%APPDIR%\CM\Client\CCMSetup.exe"
set "CERT=%APPDIR%\certificado.cer"

if /I "%~1"=="/install-worker" goto InstalacionElevada
call :CuentaAdministradora
if errorlevel 1 goto FlujoEstandar
call :SesionElevada
if errorlevel 1 goto ElevarAdministrador
goto FlujoAdministrador

:ElevarAdministrador
echo [INFO] Solicitando permisos de administrador...
call :ElevarProceso /admin
exit /b

:FlujoAdministrador
call :MenuInstalacion
call :CrearPerfilEstandar
echo.
pause
exit /b

:InstalacionElevada
call :SesionElevada
if errorlevel 1 goto ElevarInstalacion
call :MenuInstalacion
exit /b

:ElevarInstalacion
echo [INFO] Solicitando permisos para instalar aplicaciones...
call :ElevarProceso /install-worker
exit /b

:FlujoEstandar
cls
echo.
echo ==================================================
echo        CONFIGURACION DEL PERFIL ESTANDAR
echo ==================================================
echo.
echo Estado actual de las aplicaciones:
echo.
set "FALTAN_APLICACIONES=0"
call :EstadoAdobe
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoChrome
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoTeams
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoOffice
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoVLC
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoWinRAR
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoCM
if errorlevel 1 set "FALTAN_APLICACIONES=1"
call :EstadoCertificado
if errorlevel 1 set "FALTAN_APLICACIONES=1"

if "%FALTAN_APLICACIONES%"=="1" (
    echo.
    choice /C SN /N /M "Faltan aplicaciones. Desea proceder con la instalacion? [S,N]?"
    if errorlevel 2 goto ConfigurarPerfil
    call :ElevarProceso /install-worker
)

:ConfigurarPerfil
echo.
echo Cambios de Windows que se aplicaran:
echo   - Barra de busqueda: solo icono.
echo   - Vista de tareas: desactivada.
echo   - Widgets: desactivados.
echo   - Reanudar: desactivado.
echo   - Copiar Fondo a Imagenes y aplicar su imagen como fondo de pantalla.
echo.
choice /C SN /N /M "Desea continuar con las modificaciones? [S,N]?"
if errorlevel 2 goto ProcesoFinalizado
powershell -NoProfile -ExecutionPolicy Bypass -File "%CONFIGURAR_PERFIL%" -Mode ApplyProfile
if errorlevel 1 echo [ERROR] No se pudieron aplicar todas las personalizaciones.

:ProcesoFinalizado
echo.
echo PROCESO FINALIZADO. Presione una tecla para continuar.
pause >nul
exit /b

:CuentaAdministradora
powershell -NoProfile -Command "$adminSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544'); $identity = [Security.Principal.WindowsIdentity]::GetCurrent(); if ($identity.Groups -contains $adminSid) { exit 0 }; exit 1" >nul 2>&1
exit /b %errorlevel%

:SesionElevada
powershell -NoProfile -Command "$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()); if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 }; exit 1" >nul 2>&1
exit /b %errorlevel%

:ElevarProceso
set "BAT_PATH=%SCRIPT%"
set "BAT_ARGUMENT=%~1"
powershell -NoProfile -Command "try { $process = Start-Process -FilePath $env:BAT_PATH -ArgumentList $env:BAT_ARGUMENT -Verb RunAs -Wait -PassThru; exit $process.ExitCode } catch { exit 1 }"
exit /b %errorlevel%

:CrearPerfilEstandar
powershell -NoProfile -ExecutionPolicy Bypass -File "%CONFIGURAR_PERFIL%" -Mode CreateUser
exit /b %errorlevel%

:: ==================================================
:: RESUMEN
:: ==================================================

:MenuInstalacion
cls

echo.
echo ==================================================
echo        INSTALADOR AUTOMATICO DE SOFTWARE
echo ==================================================
echo.
echo Estado actual:
echo.

call :EstadoAdobe
call :EstadoChrome
call :EstadoTeams
call :EstadoOffice
call :EstadoVLC
call :EstadoWinRAR
call :EstadoCM
call :EstadoCertificado

echo.
choice /C SN /N /M "Desea instalar todo? [S,N]?"
if errorlevel 2 goto SeleccionIndividual
set "INSTALAR_ADOBE=S"
set "INSTALAR_CHROME=S"
set "INSTALAR_TEAMS=S"
set "INSTALAR_OFFICE=S"
set "INSTALAR_VLC=S"
set "INSTALAR_WINRAR=S"
set "INSTALAR_CM=S"
set "INSTALAR_CERTIFICADO=S"
goto IniciarInstalacion

:SeleccionIndividual
echo.
echo Elige los programas a instalar:
echo.
call :PreguntarInstalacion "Adobe Reader" EstadoAdobe INSTALAR_ADOBE
call :PreguntarInstalacion "Google Chrome" EstadoChrome INSTALAR_CHROME
call :PreguntarInstalacion "Microsoft Teams" EstadoTeams INSTALAR_TEAMS
call :PreguntarInstalacion "Microsoft 365" EstadoOffice INSTALAR_OFFICE
call :PreguntarInstalacion "VLC Media Player" EstadoVLC INSTALAR_VLC
call :PreguntarInstalacion "WinRAR" EstadoWinRAR INSTALAR_WINRAR
call :PreguntarInstalacion "Configuration Manager" EstadoCM INSTALAR_CM
call :PreguntarInstalacion "Certificado de red" EstadoCertificado INSTALAR_CERTIFICADO

:IniciarInstalacion
echo INICIANDO INSTALACION
echo ==================================================
echo.

if /I "%INSTALAR_ADOBE%"=="S" call :InstalarAdobe
if /I "%INSTALAR_CHROME%"=="S" call :InstalarChrome
if /I "%INSTALAR_TEAMS%"=="S" call :InstalarTeams
if /I "%INSTALAR_OFFICE%"=="S" call :InstalarOffice
if /I "%INSTALAR_VLC%"=="S" call :InstalarVLC
if /I "%INSTALAR_WINRAR%"=="S" call :InstalarWinRAR
if /I "%INSTALAR_CM%"=="S" call :InstalarCM
if /I "%INSTALAR_CERTIFICADO%"=="S" call :InstalarCertificado

echo.
echo ==================================================
echo INSTALACION FINALIZADA
echo ==================================================
echo.
echo Estado actualizado:
echo.
call :EstadoAdobe
call :EstadoChrome
call :EstadoTeams
call :EstadoOffice
call :EstadoVLC
call :EstadoWinRAR
call :EstadoCM
call :EstadoCertificado
echo.
exit /b

:: ==================================================
:: ESTADOS
:: ==================================================

:EstadoAdobe
call :AdobeInstalado
if %errorlevel%==0 (
    powershell -Command "Write-Host 'Adobe Reader             [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Adobe Reader             [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:AdobeInstalado
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /i "Adobe" >nul 2>&1
if %errorlevel%==0 exit /b 0
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | findstr /i "Adobe" >nul 2>&1
exit /b %errorlevel%

:EstadoChrome
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1
if %errorlevel%==0 (
    powershell -Command "Write-Host 'Google Chrome            [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Google Chrome            [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:EstadoTeams
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "Teams" >nul
if %errorlevel%==0 (
    powershell -Command "Write-Host 'Microsoft Teams          [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Microsoft Teams          [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:EstadoOffice
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "Microsoft 365" >nul
if %errorlevel%==0 (
    powershell -Command "Write-Host 'Microsoft 365            [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Microsoft 365            [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:EstadoVLC
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "VLC" >nul
if %errorlevel%==0 (
    powershell -Command "Write-Host 'VLC Media Player         [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'VLC Media Player         [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:EstadoWinRAR
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "WinRAR" >nul
if %errorlevel%==0 (
    powershell -Command "Write-Host 'WinRAR                   [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'WinRAR                   [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:EstadoCM

if not exist "%CM%" exit /b 0

sc query CcmExec >nul 2>&1

if %errorlevel%==0 (
    powershell -Command "Write-Host 'Configuration Manager    [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Configuration Manager    [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:: ==================================================
:: INSTALACIONES
:: ==================================================

:InstalarAdobe

if not exist "%ADOBE%" (
    powershell -Command "Write-Host '[ERROR] Adobe Reader no encontrado' -ForegroundColor Red"
    goto :eof
)

call :AdobeInstalado
if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] Adobe Reader' -ForegroundColor Yellow"

"%ADOBE%" /sAll /rs /msi EULA_ACCEPT=YES

goto :eof

:InstalarChrome

if not exist "%CHROME%" goto :eof

reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe" >nul 2>&1

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] Google Chrome' -ForegroundColor Yellow"

"%CHROME%"

goto :eof

:InstalarTeams

if not exist "%TEAMS%" goto :eof

reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "Teams" >nul

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] Microsoft Teams' -ForegroundColor Yellow"

"%TEAMS%"

goto :eof

:InstalarOffice

if not exist "%OFFICE%" goto :eof

reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "Microsoft 365" >nul

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] Microsoft 365' -ForegroundColor Yellow"

"%OFFICE%"

goto :eof

:InstalarVLC

if not exist "%VLC%" goto :eof

reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "VLC" >nul

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] VLC Media Player' -ForegroundColor Yellow"

"%VLC%" /S

goto :eof

:InstalarWinRAR

if not exist "%WINRAR%" goto :eof

reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall /s | findstr /i "WinRAR" >nul

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] WinRAR' -ForegroundColor Yellow"

"%WINRAR%" /S

goto :eof

:InstalarCM

if not exist "%CM%" (
    goto :eof
)

sc query CcmExec >nul 2>&1

if %errorlevel%==0 (
    goto :eof
)

powershell -Command "Write-Host '[INSTALANDO] Configuration Manager' -ForegroundColor Yellow"

"%CM%" /mp:SCCM02-ADM.stomas.cst SMSSITECODE=ST2 SMSMP=SCCM02-ADM.stomas.cst DNSSUFFIX=stomas.cst

goto :eof

:EstadoCertificado
if not exist "%CERT%" (
    powershell -Command "Write-Host 'Certificado de red       [NO ENCONTRADO]' -ForegroundColor Red"
    exit /b 0
)

call :CertificadoInstalado
if %errorlevel%==0 (
    powershell -Command "Write-Host 'Certificado de red       [YA INSTALADO]' -ForegroundColor Green"
    exit /b 0
) else (
    powershell -Command "Write-Host 'Certificado de red       [SE INSTALARA]' -ForegroundColor Yellow"
    exit /b 1
)

:CertificadoInstalado
powershell -NoProfile -Command "$cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($env:CERT); if (Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }) { exit 0 }; exit 1" >nul 2>&1
exit /b %errorlevel%

:PreguntarInstalacion
set "%~3=N"
call :%~2 >nul
if not errorlevel 1 exit /b 0
choice /C SN /N /M "%~1 [S,N]?"
if errorlevel 2 exit /b 0
set "%~3=S"
exit /b 0

:InstalarCertificado
if not exist "%CERT%" (
    powershell -Command "Write-Host '[ERROR] Certificado de red no encontrado' -ForegroundColor Red"
    goto :eof
)

call :CertificadoInstalado
if %errorlevel%==0 goto :eof

powershell -Command "Write-Host '[INSTALANDO] Certificado de red' -ForegroundColor Yellow"
certutil -addstore -f Root "%CERT%" >nul 2>&1
if errorlevel 1 (
    powershell -Command "Write-Host '[ERROR] No se pudo instalar el certificado de red' -ForegroundColor Red"
)

goto :eof