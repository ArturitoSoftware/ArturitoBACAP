# 🚀 ArturitoBACAP - Sistema de Backup Inteligente

Sistema profesional de backup automatizado con PowerShell y Robocopy, optimizado para máximo rendimiento y confiabilidad.

## ✨ Características Principales

- **Backup Paralelizado**: Ejecuta múltiples copias simultáneas (1-32 jobs)
- **Sistema de Perfiles**: Múltiples configuraciones en los mismos archivos (0-99 perfiles)
- **Sistema de Exclusiones**: Omite carpetas específicas con archivo Omitir.cfg (modo híbrido)
- **Modo Protección**: Backup incremental sin borrar archivos obsoletos (NuncaBorra)
- **Validación Inteligente**: Verifica todas las rutas antes de iniciar
- **Conversión UNC Automática**: Transforma unidades lógicas a rutas de red
- **Fallback Inteligente**: Si el destino falla, usa C:\BCKP automáticamente (solo modo estándar)
- **Verificación de Integridad**: Compara origen vs destino post-backup
- **Notificaciones Email**: Reportes detallados con logs adjuntos (resumen + completo)
- **Rotación de Históricos**: Mantiene N versiones anteriores del backup
- **Modo Silencioso**: Ideal para Task Scheduler (sin salidas en pantalla)
- **Optimización CPU**: Detecta threads óptimos según hardware disponible
- **Limpieza Automática**: Elimina carpetas obsoletas del destino (excepto modo NuncaBorra)
- **Arquitectura Modular**: Funciones organizadas por carpetas para máximo orden

## 📂 Estructura del Proyecto

```
ArturitoBACAP/
├── ArturitoBACAP.ps1           # Script principal
│
├── Conf/                        # Archivos de configuración
│   ├── configSMTP.xml          # Config email encriptada (generado con -AjustaEmail)
│   ├── Origen.cfg              # Carpetas origen (creado automáticamente)
│   ├── Destino.cfg             # Carpeta destino (creado automáticamente)
│   ├── Omitir.cfg              # Exclusiones de backup (creado automáticamente)
│   └── MapeosUNC.json          # Histórico de conversiones UNC (generado automáticamente)
│
├── Func/                        # Funciones modulares
│   ├── FuncAyudin.ps1          # Función de ayuda integrada
│   ├── FuncBorrarRapido.ps1    # Limpieza de carpetas obsoletas
│   ├── FuncCierraTodo.ps1      # Cierre de aplicaciones
│   ├── FuncEnviaEmail.ps1      # Envío de notificaciones
│   ├── FuncGuardaHistorico.ps1 # Rotación de backups históricos
│   ├── FuncLimpiaLogs.ps1      # Limpieza de logs antiguos
│   ├── FuncManejaOmitir.ps1    # Procesamiento de exclusiones
│   ├── FuncManejaPerfiles.ps1  # Procesamiento de perfiles
│   ├── FuncValidacionUNC.ps1   # Validación y conversión UNC
│   └── FuncVerificaBACKUP.ps1  # Verificación de integridad
│
├── Temp/                        # Archivos temporales (limpiados automáticamente)
│   └── .gitkeep
│
├── Logs/                        # Logs de backup (rotación automática)
│   └── .gitkeep
│
├── README.md                    # Este archivo
└── .gitignore                   # Exclusiones de Git
```

## 📋 Requisitos

- Windows 10/11 o Windows Server 2016+
- PowerShell 5.1 o superior
- Permisos de administrador (para algunas funcionalidades)
- Robocopy (incluido en Windows)

## ⚠️ IMPORTANTE: Ejecución de Scripts No Firmados

Este script y sus funciones auxiliares **NO están firmados digitalmente**. Antes de ejecutar ArturitoBACAP por primera vez, debes desbloquear todos los archivos del proyecto.

### 🔓 Desbloquear Scripts (OBLIGATORIO)

Abre PowerShell como **Administrador** en la carpeta del proyecto y ejecuta:

```powershell
# Desbloquear todos los archivos .ps1 de la carpeta actual
Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File
```

Este comando desbloquea todos los scripts de PowerShell en la carpeta y subcarpetas, permitiendo su ejecución sin restricciones.

### Alternativa: Cambiar Política de Ejecución (NO RECOMENDADO para uso permanente)

Si prefieres cambiar la política de ejecución temporalmente:

```powershell
# ⚠️ Solo para pruebas - NO recomendado en producción
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

**Nota**: Esta alternativa solo afecta la sesión actual de PowerShell y es menos segura.

### Verificar Desbloqueo

Para confirmar que los scripts están desbloqueados:

```powershell
Get-ChildItem -Path . -Recurse -Filter *.ps1 | Get-Item -Stream Zone.Identifier -ErrorAction SilentlyContinue
```

Si no devuelve ningún resultado, los archivos están correctamente desbloqueados.

---

## 🚀 Instalación

### 1. Clonar el repositorio
```powershell
git clone https://github.com/ArturitoSoftware/ArturitoBACAP.git
cd ArturitoBACAP
```

### 2. Desbloquear scripts (OBLIGATORIO)
```powershell
# Como Administrador
Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File
```

### 3. Configurar archivos
```powershell
# Los archivos se crean automáticamente con ejemplos en la primera ejecución
# Editar Conf/Origen.cfg con las carpetas a respaldar
notepad Conf\Origen.cfg

# (Opcional) Editar Conf/Destino.cfg para cambiar destino
# Por defecto usa C:\BCKP en modo estándar
# Con perfiles requiere destino válido obligatorio
notepad Conf\Destino.cfg

# (Opcional) Editar Conf/Omitir.cfg para excluir carpetas
notepad Conf\Omitir.cfg
```

### 4. Configurar email (obligatorio si no usarás -NoEmail)
```powershell
.\ArturitoBACAP.ps1 -AjustaEmail
```

### 5. Ejecutar primer backup de prueba
```powershell
.\ArturitoBACAP.ps1 -Debug -NoEmail
```

## 📖 Uso

### Comandos Básicos

```powershell
# Mostrar ayuda completa
.\ArturitoBACAP.ps1 -Ayuda

# Backup básico (modo silencioso con email)
.\ArturitoBACAP.ps1

# Backup interactivo sin email
.\ArturitoBACAP.ps1 -Debug -NoEmail

# Backup con verificación
.\ArturitoBACAP.ps1 -Verifica

# Backup rápido con 8 jobs simultáneos
.\ArturitoBACAP.ps1 -Rapidito -Simultaneas 8

# Backup con protección (sin borrar obsoletos)
.\ArturitoBACAP.ps1 -NuncaBorra

# Usar perfil 1
.\ArturitoBACAP.ps1 -Perfil 1

# Usar perfil 2 con verificación
.\ArturitoBACAP.ps1 -Perfil 2 -Verifica
```

### Modificadores Disponibles

| Modificador | Descripción | Ejemplo |
|------------|-------------|---------|
| `-AjustaEmail` | Configurar parámetros SMTP | `.\ArturitoBACAP.ps1 -AjustaEmail` |
| `-NoEmail` | Ejecutar sin enviar email | `.\ArturitoBACAP.ps1 -NoEmail` |
| `-Perfil N` | Usar perfil específico (0-99) | `.\ArturitoBACAP.ps1 -Perfil 1` |
| `-Simultaneas N` | Jobs simultáneos (1-32, default: 3) | `.\ArturitoBACAP.ps1 -Simultaneas 8` |
| `-Rapidito` | Modo ultra-rápido | `.\ArturitoBACAP.ps1 -Rapidito` |
| `-NuncaBorra` | No eliminar archivos obsoletos | `.\ArturitoBACAP.ps1 -NuncaBorra` |
| `-Debug` | Mensajes en pantalla | `.\ArturitoBACAP.ps1 -Debug` |
| `-Verifica` | Verificar integridad | `.\ArturitoBACAP.ps1 -Verifica` |
| `-Apagar` | Apagar equipo al terminar | `.\ArturitoBACAP.ps1 -Apagar` |
| `-CierroTodo` | Cerrar programas antes | `.\ArturitoBACAP.ps1 -CierroTodo` |
| `-Historico N` | Mantener N backups históricos | `.\ArturitoBACAP.ps1 -Historico 5` |
| `-Ayuda` | Mostrar ayuda | `.\ArturitoBACAP.ps1 -Ayuda` |

### Combinaciones Recomendadas

```powershell
# Producción: Rápido con verificación
.\ArturitoBACAP.ps1 -Rapidito -Simultaneas 8 -Verifica

# Task Scheduler nocturno: Con apagado e históricos
.\ArturitoBACAP.ps1 -Apagar -Historico 7

# Testing: Interactivo sin email
.\ArturitoBACAP.ps1 -NoEmail -Debug -Verifica

# Sistemas en uso: Cerrando aplicaciones
.\ArturitoBACAP.ps1 -CierroTodo -Verifica -Simultaneas 5

# Máximo rendimiento: Sin verificación
.\ArturitoBACAP.ps1 -Rapidito -Simultaneas 16 -NoEmail

# Backup incremental protegido (sin borrar)
.\ArturitoBACAP.ps1 -NuncaBorra -Verifica

# Usar perfil 1 con protección
.\ArturitoBACAP.ps1 -Perfil 1 -NuncaBorra -Verifica

# Usar perfil 2 en modo rápido con apagado
.\ArturitoBACAP.ps1 -Perfil 2 -Rapidito -Apagar
```

## ⚙️ Configuración

### Sistema de Perfiles

Los **perfiles** permiten mantener múltiples configuraciones de backup en los mismos archivos `Origen.cfg`, `Destino.cfg` y `Omitir.cfg`, seleccionando cuál usar con `-Perfil N`.

#### Formato de Perfiles

Las líneas en los archivos de configuración pueden tener dos formatos:

**1. Sin prefijo (modo estándar, Perfil 0):**
```
C:\Documentos
D:\Proyectos
```

**2. Con prefijo numérico (para perfiles 1-99):**
```
1:C:\Users\Juan\Documents
1:C:\Users\Juan\Pictures
2:C:\Proyectos\ClienteA
2:D:\Trabajo
```

#### Comportamiento según Perfil

**`-Perfil 0` (o sin especificar):**
- Usa solo líneas **SIN** prefijo numérico
- Ignora líneas con formato `N:` (no genera error)
- Permite usar `C:\BCKP` como destino por defecto
- Comportamiento original del script

**`-Perfil 1` (o cualquier 1-99):**
- Usa **SOLO** líneas que comienzan con `1:`
- Remueve el prefijo `1:` antes de usar la ruta
- **REQUIERE destino válido** (no usa `C:\BCKP` por defecto)
- Si no hay destino válido → ERROR y no avanza

#### Ejemplo Completo de Perfiles

**Conf/Origen.cfg:**
```
# Modo estándar (sin perfil)
C:\Documentos
D:\Proyectos

# Perfil 1 - Backup Personal
1:C:\Users\Juan\Documents
1:C:\Users\Juan\Pictures
1:C:\Users\Juan\Desktop

# Perfil 2 - Backup Trabajo
2:C:\Proyectos\ClienteA
2:C:\Proyectos\ClienteB
2:D:\Documentacion_Empresa

# Perfil 3 - Backup Completo
3:C:\Users\Juan\Documents
3:C:\Proyectos
3:D:\Backup_Servidor
```

**Conf/Destino.cfg:**
```
# Modo estándar
C:\BCKP

# Perfil 1
1:D:\Backup_Personal

# Perfil 2
2:E:\Backup_Trabajo

# Perfil 3
3:\\NAS\Backup_Completo
```

**Uso:**
```powershell
# Modo estándar: C:\Documentos y D:\Proyectos → C:\BCKP
.\ArturitoBACAP.ps1

# Perfil 1: Documents, Pictures, Desktop → D:\Backup_Personal
.\ArturitoBACAP.ps1 -Perfil 1

# Perfil 2: ClienteA, ClienteB, Documentacion → E:\Backup_Trabajo
.\ArturitoBACAP.ps1 -Perfil 2

# Perfil 3: Documents, Proyectos, Servidor → \\NAS\Backup_Completo
.\ArturitoBACAP.ps1 -Perfil 3
```

### Sistema de Exclusiones (Omitir.cfg)

El archivo `Conf/Omitir.cfg` permite excluir carpetas específicas del backup usando un **sistema híbrido** de exclusión.

#### Tipos de Exclusión

**1. Nombre Simple** (omite en cualquier nivel):
```
node_modules
.git
Temp
```
Resultado: Omite `C:\Datos\node_modules`, `C:\Docs\Proyectos\node_modules`, etc.

**2. Ruta Relativa** (desde raíz de origen):
```
Documentos\Temp
Proyectos\.git
```
Resultado: Omite `[origen]\Documentos\Temp` pero NO `[origen]\Otros\Temp`

**3. Ruta Absoluta** (solo ruta específica):
```
C:\Datos\NoBackupear
D:\Proyectos\Build
```
Resultado: Omite SOLO esas rutas exactas

#### Ejemplo Completo de Omitir.cfg

```
# Modo estándar (sin perfil)
node_modules
.git
$RECYCLE.BIN
System Volume Information

# Perfil 1 - Exclusiones Personal
1:Temp
1:AppData\Local\Temp
1:.vs

# Perfil 2 - Exclusiones Trabajo
2:node_modules
2:.git
2:C:\Proyectos\ClienteA\Build
```

#### Conversión UNC Automática

Las exclusiones con unidades lógicas se convierten automáticamente a UNC:
```
# Si excluyes: Z:\Temp
# Y Z: mapea a \\servidor\datos
# Se excluye: \\servidor\datos\Temp
```

### Conf/Origen.cfg

Lista de carpetas a respaldar (una por línea). Soporta variables de entorno y perfiles:

```
# Carpetas del usuario actual (modo estándar)
%USERPROFILE%\Desktop
%USERPROFILE%\Downloads
%USERPROFILE%\Documents

# Perfil de Chrome
%LOCALAPPDATA%\Google\Chrome

# Carpetas específicas
C:\Datos
D:\Proyectos
\\servidor\compartido

# Perfil 1 - Personal
1:%USERPROFILE%\Documents
1:%USERPROFILE%\Pictures
1:%USERPROFILE%\Videos

# Perfil 2 - Trabajo
2:C:\Proyectos\ClienteA
2:D:\Trabajo\Documentos
```

**Características:**
- Líneas que comienzan con `#` son comentarios
- Soporta rutas locales y de red
- Variables de entorno se expanden automáticamente
- Conversión automática a UNC cuando es necesario
- **Soporta perfiles**: Líneas con formato `N:[ruta]`
- **Creación automática**: Si no existe, se genera con ejemplos

### Conf/Destino.cfg

Carpeta destino del backup (**UNA SOLA LÍNEA por perfil**):

```
# Destino del backup modo estándar
D:\Respaldos

# Perfil 1 - Personal
1:E:\Backup_Personal

# Perfil 2 - Trabajo
2:\\NAS\Backup_Trabajo
```

**Validación Automática (Modo Estándar):**
1. Si no existe → crea archivo con ejemplos y usa `C:\BCKP`
2. Si tiene ruta válida → valida y usa esa ruta
3. Si es inválida → intenta con `C:\BCKP` automáticamente
4. Si tiene múltiples líneas → usa `C:\BCKP`

**Validación con Perfiles (-Perfil 1-99):**
1. Si no existe Destino.cfg → **ERROR** (no usa `C:\BCKP`)
2. Si no hay línea para el perfil → **ERROR** (no usa `C:\BCKP`)
3. Si la ruta del perfil es inválida → **ERROR** (no usa `C:\BCKP`)
4. Si hay múltiples líneas del perfil → **ERROR**

### Modo NuncaBorra (Protección)

El modificador `-NuncaBorra` activa un modo de protección que impide la eliminación de archivos y carpetas en el destino.

#### Comportamiento

**SIN `-NuncaBorra` (comportamiento estándar):**
- Usa `/MIR` en Robocopy (mirror = espejo exacto)
- Elimina carpetas obsoletas en destino
- Elimina archivos que ya no están en origen
- Destino es copia exacta del origen

**CON `-NuncaBorra`:**
- Usa `/E` en lugar de `/MIR` (copia sin eliminar)
- **NO** elimina carpetas obsoletas en destino
- **NO** elimina archivos que ya no están en origen
- Destino acumula todos los archivos (incremental)
- Ideal para mantener historial completo

#### Casos de Uso

✅ **USAR `-NuncaBorra` cuando:**
- Quieres mantener archivos antiguos eliminados del origen
- Necesitas historial completo de cambios
- Backup incremental acumulativo
- Proteges contra borrados accidentales en origen

❌ **NO USAR `-NuncaBorra` cuando:**
- Quieres destino como espejo exacto del origen
- El espacio en disco es limitado
- Necesitas limpiar archivos obsoletos automáticamente

### Conf/configSMTP.xml

Archivo encriptado generado con `-AjustaEmail`. Contiene:
- Servidor SMTP y puerto
- Configuración SSL/TLS
- Credenciales encriptadas (solo accesible por el usuario que lo configuró)
- Remitente y destinatario

**Seguridad**: El archivo tiene permisos restrictivos automáticos y solo puede ser leído por el usuario que lo creó.

### Conf/MapeosUNC.json

Histórico automático de conversiones de unidades lógicas a rutas UNC:
- Se genera automáticamente al detectar unidades mapeadas
- Permite recordar conversiones para futuras ejecuciones
- Formato JSON simple: `{"Z:": "\\\\servidor\\datos"}`
- No requiere configuración manual

## 📊 Logs Generados

### BCKP_Resumen_YYYYMMDD_HHMMSS.log
Resumen ejecutivo consolidado:
- **Perfil usado**: Muestra qué perfil se utilizó (0 = Estándar, 1-99 = número específico)
- Estadísticas del backup (duración, carpetas, velocidad)
- Errores y advertencias
- Conversiones UNC realizadas
- Carpetas eliminadas (o indicación de modo NuncaBorra)
- Exclusiones aplicadas (Omitir.cfg)
- **Adjunto al email**: Siempre se envía

### BCKP_Detalle_YYYYMMDD_HHMMSS.log
Log detallado completo:
- **Perfil usado**: Al inicio del log
- Salida de Robocopy por cada carpeta
- Logs de verificación (si se usa `-Verifica`)
- Log de limpieza de carpetas obsoletas (excepto con `-NuncaBorra`)
- Validaciones y conversiones UNC
- Detalles de exclusiones aplicadas
- **Adjunto al email**: Siempre se envía junto con el resumen

### Email con Información de Perfil

Los emails incluyen información del perfil usado:
- **Subject**: `Backup EXITOSO [P1] ⚡ 00:15:30 - 19/10 14:30` (si se usó Perfil 1)
- **Body**: `🎯 Perfil: 1` o `🎯 Perfil: Estándar` (si se usó Perfil 0)

### Rotación Automática de Logs
- Logs antiguos (>30 días) se eliminan automáticamente
- Mantiene el espacio en disco limpio
- Configurable mediante `Func/FuncLimpiaLogs.ps1`

## 🔧 Funcionalidades Automáticas

- ✅ Validación completa de rutas antes del backup
- ✅ Conversión automática de unidades lógicas a rutas UNC
- ✅ Fallback automático a C:\BCKP si destino es inválido (solo modo estándar)
- ✅ Eliminación automática de carpetas obsoletas (excepto con `-NuncaBorra`)
- ✅ Detección automática de threads óptimos según CPU
- ✅ Compresión automática de logs grandes (>10MB)
- ✅ Consolidación automática de logs individuales
- ✅ Rotación automática de backups históricos
- ✅ Permisos de seguridad automáticos en configuración
- ✅ Creación automática de archivos de configuración con ejemplos
- ✅ Envío de múltiples adjuntos por email (resumen + detalle)
- ✅ Procesamiento automático de perfiles con archivos temporales
- ✅ Validación estricta de destinos con perfiles (requiere destino válido)
- ✅ Indicación clara de perfil usado en logs y emails
- ✅ Procesamiento automático de exclusiones con conversión UNC
- ✅ Limpieza automática de archivos temporales al finalizar

## 🚀 Automatización con Task Scheduler

### Programación con Task Scheduler (Windows)

```powershell
# Ejemplo de comando para Task Scheduler (modo estándar)
powershell.exe -ExecutionPolicy Bypass -File "C:\Ruta\ArturitoBACAP.ps1" -Apagar -Historico 7

# Ejemplo con perfil 1
powershell.exe -ExecutionPolicy Bypass -File "C:\Ruta\ArturitoBACAP.ps1" -Perfil 1 -Verifica

# Ejemplo con perfil 2 y modo protección
powershell.exe -ExecutionPolicy Bypass -File "C:\Ruta\ArturitoBACAP.ps1" -Perfil 2 -NuncaBorra -Apagar
```

**Recomendaciones:**
- Ejecutar con usuario que tenga permisos en origen y destino
- Usar `-ExecutionPolicy Bypass` en la tarea programada
- Configurar para ejecutar con privilegios elevados si es necesario
- Usar perfiles diferentes para tareas programadas en distintos horarios

## 🔍 Troubleshooting

### "El backup NO se ejecutará sin configuración de email válida"
**Solución**: Ejecuta `.\ArturitoBACAP.ps1 -AjustaEmail` o usa `-NoEmail`

### "ERROR: Perfil X requiere un destino válido en Destino.cfg"
**Solución**: 
1. Edita `Conf/Destino.cfg` y agrega una línea con formato `X:[ruta_destino]`
2. Ejemplo: `1:D:\Backup_Personal` para Perfil 1
3. Los perfiles NO pueden usar `C:\BCKP` como fallback

### "No se encontraron rutas válidas para el perfil X"
**Solución**:
1. Edita `Conf/Origen.cfg` y agrega líneas con formato `X:[ruta_origen]`
2. Ejemplo: `1:C:\Documents` para Perfil 1
3. Asegúrate de que las rutas existan

### "DESTINO INVÁLIDO"
**Solución**: 
- En modo estándar: Verifica la ruta en `Conf/Destino.cfg`. El script intentará usar `C:\BCKP` como fallback.
- Con perfiles: Debes proporcionar un destino válido obligatorio. No hay fallback a `C:\BCKP`.

### "NO HAY CARPETAS VÁLIDAS PARA BACKUP"
**Solución**: Revisa `Conf/Origen.cfg` y asegúrate de que las rutas existan y sean accesibles.

### Error "no se puede cargar el archivo... no está firmado digitalmente"
**Solución**: Ejecuta como Administrador:
```powershell
Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File
```

### Error de permisos
**Solución**: Ejecuta PowerShell como administrador o ajusta permisos de las carpetas.

### Backup muy lento
**Solución**: Aumenta `-Simultaneas` (ej: `-Simultaneas 8`) y considera usar `-Rapidito`.

### Email no se envía
**Solución**: 
1. Verifica configuración SMTP con `-AjustaEmail`
2. Revisa que el servidor SMTP permita la conexión
3. Confirma que las credenciales sean correctas
4. Verifica que el puerto y SSL/TLS estén configurados correctamente

### Los adjuntos del email son muy grandes
**Solución**: ArturitoBACAP comprime automáticamente adjuntos >10MB. Si aún son grandes, considera:
- Reducir el nivel de detalle en logs
- Ajustar la retención de logs con `Func/FuncLimpiaLogs.ps1`

### El destino se llena de archivos viejos
**Solución**: 
- Si usas `-NuncaBorra`, este es el comportamiento esperado (modo incremental)
- Para limpiar automáticamente, ejecuta sin `-NuncaBorra`
- Considera usar perfiles: uno con `-NuncaBorra` para histórico, otro sin él para limpieza

### Las exclusiones no funcionan
**Solución**:
1. Verifica el formato en `Conf/Omitir.cfg`
2. Nombres simples: sin barras (ej: `node_modules`)
3. Rutas relativas: desde raíz de origen (ej: `Documentos\Temp`)
4. Rutas absolutas: ruta completa (ej: `C:\Datos\NoBackupear`)
5. Usa `-Debug` para ver las exclusiones aplicadas

## 📝 Notas Importantes

- ⚠️ **Scripts no firmados**: Debes desbloquear los archivos `.ps1` recursivamente antes de ejecutar
- ⚠️ El modo silencioso (sin `-Debug`) es ideal para Task Scheduler
- ⚠️ `-AjustaEmail` tiene prioridad sobre otros modificadores
- ⚠️ El destino configurado se valida antes del backup
- ⚠️ Los archivos de configuración con datos sensibles NO deben subirse a Git
- ⚠️ Los archivos en `Conf/` se crean automáticamente con ejemplos si no existen
- ⚠️ Los logs se envían por email en dos archivos: resumen ejecutivo y detalle completo
- ⚠️ **PERFILES Y DESTINOS**: Los perfiles (1-99) REQUIEREN destino válido. No se permite usar `C:\BCKP` como fallback
- ⚠️ **MODO NUNCABORRA**: Protege el destino contra borrados. Útil para backups incrementales acumulativos
- ⚠️ Los emails muestran el perfil usado: `[P1]` en subject, `Perfil: 1` en body
- ⚠️ Los archivos temporales (carpeta `Temp/`) se limpian automáticamente al finalizar
- ⚠️ El histórico de conversiones UNC se guarda en `Conf/MapeosUNC.json`
- ⚠️ Las exclusiones en `Conf/Omitir.cfg` soportan perfiles y conversión UNC automática

## 📄 Licencia

**Úselo bajo su responsabilidad**

Software By Arturito - Soporte Infoquil by WAJ

## 🙏 Créditos

Desarrollado por **Arturito**  
Soporte técnico: **Infoquil by WAJ**

---

**¿Preguntas o sugerencias?** Abre un issue en GitHub o contacta al equipo de soporte.