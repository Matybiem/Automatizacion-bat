param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('CreateUser', 'ApplyProfile')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'

function Read-YesNo {
    param([string]$Prompt)

    while ($true) {
        $answer = (Read-Host $Prompt).Trim()
        if ($answer -match '^(?i:S|N)$') {
            return $answer.ToUpperInvariant()
        }

        Write-Host 'Respuesta no valida. Escriba S o N.' -ForegroundColor Yellow
    }
}

function Test-AccountName {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name) -or $Name.Length -gt 20) {
        return $false
    }

    if ($Name -ne $Name.Trim() -or $Name -match '^\.+$|\.$') {
        return $false
    }

    $invalidCharacters = [char[]]@('"', '/', '\', '[', ']', ':', ';', '|', '=', ',', '+', '*', '?', '<', '>')
    return $Name.IndexOfAny($invalidCharacters) -lt 0
}

function ConvertTo-PlainText {
    param([System.Security.SecureString]$Value)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function New-StandardUser {
    $userName = 'Santo Tomas'
    if ((Read-YesNo 'Mantener el nombre de usuario Santo Tomas? [S,N]') -eq 'N') {
        do {
            $userName = Read-Host 'Escriba el nombre de usuario'
            if (-not (Test-AccountName $userName)) {
                Write-Host 'Nombre no valido. Use hasta 20 caracteres y evite los caracteres especiales no permitidos por Windows.' -ForegroundColor Yellow
                continue
            }

            if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
                Write-Host "La cuenta '$userName' ya existe." -ForegroundColor Yellow
                $userName = ''
                continue
            }

            break
        } while ($true)
    }
    elseif (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
        Write-Host "La cuenta '$userName' ya existe." -ForegroundColor Red
        return 1
    }

    if (-not (Test-AccountName $userName)) {
        Write-Host 'El nombre de usuario no cumple las reglas de Windows.' -ForegroundColor Red
        return 1
    }

    $password = $null
    if ((Read-YesNo 'El usuario estandar tendra contrasena? [S,N]') -eq 'S') {
        while ($true) {
            $firstPassword = Read-Host 'Escriba la contrasena' -AsSecureString
            $secondPassword = Read-Host 'Confirme la contrasena' -AsSecureString
            $firstText = ConvertTo-PlainText $firstPassword
            $secondText = ConvertTo-PlainText $secondPassword
            $matches = [string]::Equals($firstText, $secondText, [StringComparison]::Ordinal)
            $firstText = $null
            $secondText = $null

            if ($matches) {
                $password = $firstPassword
                break
            }

            Write-Host 'Las contrasenas no coinciden. Intentelo nuevamente.' -ForegroundColor Yellow
        }
    }

    try {
        if ($null -eq $password) {
            New-LocalUser -Name $userName -FullName $userName -NoPassword | Out-Null
        }
        else {
            New-LocalUser -Name $userName -FullName $userName -Password $password | Out-Null
        }

        $usersGroup = Get-LocalGroup -SID 'S-1-5-32-545'
        $userSid = (Get-LocalUser -Name $userName).SID.Value
        $userGroupSids = @(Get-LocalGroupMember -Group $usersGroup | ForEach-Object { $_.SID.Value })
        if ($userSid -notin $userGroupSids) {
            Add-LocalGroupMember -Group $usersGroup -Member $userName | Out-Null
        }
        Write-Host "Perfil estandar '$userName' creado correctamente." -ForegroundColor Green
        Write-Host "Ahora inicia en el perfil $userName y ejecuta el BAT." -ForegroundColor Cyan
        return 0
    }
    catch {
        Write-Host "No se pudo crear el perfil: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    }
}

function Set-TaskbarOption {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    New-Item -Path $Path -Force | Out-Null
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

function Set-ProfilePersonalization {
    $advancedPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $searchPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'

    Set-TaskbarOption -Path $searchPath -Name 'SearchboxTaskbarMode' -Value 1
    Set-TaskbarOption -Path $advancedPath -Name 'ShowTaskViewButton' -Value 0
    Set-TaskbarOption -Path $advancedPath -Name 'TaskbarDa' -Value 0
    Set-TaskbarOption -Path $advancedPath -Name 'TaskbarResume' -Value 0

    $sourceFolder = Join-Path $PSScriptRoot 'Fondo'
    if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
        throw "No se encontro la carpeta Fondo: $sourceFolder"
    }

    $imageExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.tif', '.tiff')
    $sourceImages = @(Get-ChildItem -LiteralPath $sourceFolder -File -Recurse | Where-Object { $imageExtensions -contains $_.Extension.ToLowerInvariant() })
    if ($sourceImages.Count -ne 1) {
        throw "Se esperaba exactamente una imagen compatible dentro de '$sourceFolder'; se encontraron $($sourceImages.Count)."
    }

    $pictureFolder = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
    if ([string]::IsNullOrWhiteSpace($pictureFolder)) {
        throw 'Windows no pudo determinar la carpeta Imagenes del usuario.'
    }

    $destinationFolder = Join-Path $pictureFolder 'Fondo'
    New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceFolder '*') -Destination $destinationFolder -Recurse -Force

    $relativeImagePath = $sourceImages[0].FullName.Substring($sourceFolder.Length).TrimStart('\')
    $wallpaperPath = Join-Path $destinationFolder $relativeImagePath
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallPaper' -Value $wallpaperPath

    if (-not ('Wallpaper.NativeMethods' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace Wallpaper {
    public static class NativeMethods {
        [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern bool SystemParametersInfo(uint action, uint parameter, string value, uint flags);
    }
}
'@
    }

    $updated = [Wallpaper.NativeMethods]::SystemParametersInfo(20, 0, $wallpaperPath, 3)
    if (-not $updated) {
        throw "Windows no pudo aplicar el fondo de pantalla (error $([Runtime.InteropServices.Marshal]::GetLastWin32Error()))."
    }

    Write-Host 'Barra de tareas configurada.' -ForegroundColor Green
    Write-Host "Fondo aplicado: $wallpaperPath" -ForegroundColor Green
    Write-Host 'Los cambios de la barra pueden requerir cerrar sesion o reiniciar el Explorador de Windows.' -ForegroundColor Yellow
}

try {
    switch ($Mode) {
        'CreateUser' {
            exit (New-StandardUser)
        }
        'ApplyProfile' {
            Set-ProfilePersonalization
            exit 0
        }
    }
}
catch {
    Write-Host "Error al configurar el perfil: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}