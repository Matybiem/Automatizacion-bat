# Instalador automatico de software

Script de preparacion de equipos Windows. La instalacion de aplicaciones y la configuracion personal del usuario se ejecutan en etapas separadas.

## Requisitos

- Windows con PowerShell y `cmd.exe`.
- Los archivos de instalacion deben estar en `aplicaciones/`, junto al BAT. Esa carpeta esta excluida de Git porque contiene instaladores pesados; hay que copiarla localmente a cada equipo.
- La carpeta `Fondo/` debe permanecer junto al BAT. Incluye la imagen que se copiara al perfil del usuario y se aplicara como fondo.
- Para crear una cuenta o instalar aplicaciones se necesitan permisos de administrador. El usuario estandar puede ejecutar el BAT sin elevarlo; solo se solicita elevacion si acepta instalar aplicaciones faltantes.

## Archivos de instalacion esperados

El BAT busca estos nombres y rutas dentro de `aplicaciones/`:

| Aplicacion | Ruta esperada |
| --- | --- |
| Adobe Reader | `AcroRdrDC2300820533_es_ES.exe` |
| Google Chrome | `ChromeSetup.exe` |
| Microsoft Teams | `MSTeamsSetup.exe` |
| Microsoft 365 | `OfficeSetup365.exe` |
| VLC | `vlc-3.0.12-win64.exe` |
| WinRAR | `winrar-x64-600es.exe` |
| Configuration Manager | `CM/Client/CCMSetup.exe` |
| Certificado | `certificado.cer` |

## Uso

1. En la preparacion inicial, inicia `Auto_Install_Apps.bat` desde una cuenta administradora. Si hace falta, Windows solicitara elevacion. Elige instalar todo o seleccionar aplicaciones.
2. Al terminar, el BAT permite crear una cuenta local estandar. El nombre predeterminado es `Santo Tomas`; se puede elegir otro. La contrasena es opcional y, si se usa, se solicita dos veces para confirmar.
3. Cierra la sesion admin e inicia sesion en la cuenta estandar creada.
4. Ejecuta nuevamente `Auto_Install_Apps.bat` desde esa cuenta. El script comprueba las aplicaciones y, si faltan, permite iniciar su instalacion con permisos de administrador.
5. Confirma la configuracion personal. El script configura la barra de tareas, copia `Fondo/` a Imagenes y aplica su imagen como fondo de pantalla.

El cambio de nombre del equipo y su incorporacion al dominio son pasos manuales y no los realiza este script.

## Personalizacion de la barra

El perfil estandar configura la busqueda para mostrar solo el icono y desactiva Vista de tareas y Widgets. La opcion «Reanudar» se intenta desactivar mediante el valor de registro `TaskbarResume`; su compatibilidad depende de la version de Windows. El script reinicia el Explorador para actualizar la barra. Windows puede restringir la personalizacion mientras no este activado; el script informa por separado si no consigue aplicar el fondo.

## Git

La carpeta `aplicaciones/` esta ignorada por `.gitignore` y no se sube a GitHub. `Fondo/` si forma parte del proyecto porque el BAT la necesita para aplicar el fondo.