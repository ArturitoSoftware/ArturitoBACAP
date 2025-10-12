# 🚀 ArturitoBACAP - Sistema de Backup Inteligente

Sistema profesional de backup automatizado con PowerShell y Robocopy, optimizado para máximo rendimiento y confiabilidad.

## ✨ Características Principales

- **Backup Paralelizado**: Ejecuta múltiples copias simultáneas (1-32 jobs)
- **Validación Inteligente**: Verifica todas las rutas antes de iniciar
- **Conversión UNC Automática**: Transforma unidades lógicas a rutas de red
- **Fallback Inteligente**: Si el destino falla, usa C:\BCKP automáticamente
- **Verificación de Integridad**: Compara origen vs destino post-backup
- **Notificaciones Email**: Reportes detallados con logs adjuntos (resumen + completo)
- **Rotación de Históricos**: Mantiene N versiones anteriores del backup
- **Modo Silencioso**: Ideal para ArturitoLauncher (sin salidas en pantalla)
- **Optimización CPU**: Detecta threads óptimos según hardware disponible
- **Limpieza Automática**: Elimina carpetas obsoletas del destino

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
Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
```

Este comando desbloquea todos los scripts de PowerShell en la carpeta, permitiendo su ejecución sin restricciones.

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
Get-ChildItem -Path . -Filter *.ps1 | Get-Item -Stream Zone.Identifier -ErrorAction SilentlyContinue
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
Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
```

### 3. Configurar archivos
```powershell
# Copiar archivos de ejemplo (si existen)
Copy-Item Origen.cfg.example Origen.cfg -ErrorAction SilentlyContinue
Copy-Item Destino.cfg.example Destino.cfg -ErrorAction SilentlyContinue

# Editar Origen.cfg con las carpetas a respaldar
notepad Origen.cfg

# (Opcional) Editar Destino.cfg para cambiar destino
# Por defecto usa C:\BCKP
notepad Destino.cfg
```

**Nota**: Si los archivos `.example` no existen, ArturitoBACAP los creará automáticamente en la primera ejecución.

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
```

### Modificadores Disponibles

| Modificador | Descripción | Ejemplo |
|------------|-------------|---------|
| `-AjustaEmail` | Configurar parámetros SMTP | `.\ArturitoBACAP.ps1 -AjustaEmail` |
| `-NoEmail` | Ejecutar sin enviar email | `.\ArturitoBACAP.ps1 -NoEmail` |
| `-Simultaneas N` | Jobs simultáneos (1-32, default: 3) | `.\ArturitoBACAP.ps1 -Simultaneas 8` |
| `-Rapidito` | Modo ultra-rápido | `.\ArturitoBACAP.ps1 -Rapidito` |
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
```

## ⚙️ Configuración

### Origen.cfg

Lista de carpetas a respaldar (una por línea). Soporta variables de entorno:

```
# Carpetas del usuario actual
%USERPROFILE%\Desktop
%USERPROFILE%\Downloads
%USERPROFILE%\Documents
%USERPROFILE%\Pictures
%USERPROFILE%\Videos

# Perfil de Chrome
%LOCALAPPDATA%\Google\Chrome

# Carpetas específicas
C:\Datos
D:\Proyectos
\\servidor\compartido
```

**Características:**
- Líneas que comienzan con `#` son comentarios
- Soporta rutas locales y de red
- Variables de entorno se expanden automáticamente
- Conversión automática a UNC cuando es necesario
- **Creación automática**: Si no existe, se genera con ejemplos en la primera ejecución

### Destino.cfg

Carpeta destino del backup (**UNA SOLA LÍNEA**):

```
# Destino del backup (solo una línea válida)
D:\Respaldos
```

**Validación Automática:**
1. Si no existe → crea archivo con ejemplos y usa `C:\BCKP`
2. Si tiene ruta válida → valida y usa esa ruta
3. Si es inválida → intenta con `C:\BCKP` automáticamente
4. Si tiene múltiples líneas → usa `C:\BCKP`

**Rutas Soportadas:**
- `C:\Backups` - Ruta local
- `D:\Respaldos` - Otro disco local
- `\\servidor\compartido` - Ruta UNC de red
- `\\NAS\Backups\Empresa` - UNC con subcarpetas
- `Z:\` - Unidad mapeada (convierte a UNC)

**Creación Automática**: Si no existe, se genera con ejemplos y usa `C:\BCKP` como destino predeterminado.

### configSMTP.xml

Archivo encriptado generado con `-AjustaEmail`. Contiene:
- Servidor SMTP y puerto
- Configuración SSL/TLS
- Credenciales encriptadas (solo accesible por el usuario que lo configuró)
- Remitente y destinatario

**Seguridad**: El archivo tiene permisos restrictivos automáticos y solo puede ser leído por el usuario que lo creó.

## 📊 Logs Generados

### BCKP_Resumen_YYYYMMDD_HHMMSS.log
Resumen ejecutivo consolidado:
- Estadísticas del backup (duración, carpetas, velocidad)
- Errores y advertencias
- Conversiones UNC realizadas
- Carpetas eliminadas
- **Adjunto al email**: Siempre se envía

### BCKP_Detalle_YYYYMMDD_HHMMSS.log
Log detallado completo:
- Salida de Robocopy por cada carpeta
- Logs de verificación (si se usa `-Verifica`)
- Log de limpieza de carpetas obsoletas
- Validaciones y conversiones UNC
- **Adjunto al email**: Siempre se envía junto con el resumen

### Rotación Automática de Logs
- Logs antiguos (>30 días) se eliminan automáticamente
- Mantiene el espacio en disco limpio
- Configurable mediante `FuncLimpiaLogs.ps1`

## 🔧 Funcionalidades Automáticas

- ✅ Validación completa de rutas antes del backup
- ✅ Conversión automática de unidades lógicas a rutas UNC
- ✅ Fallback automático a C:\BCKP si destino es inválido
- ✅ Eliminación automática de carpetas obsoletas
- ✅ Detección automática de threads óptimos según CPU
- ✅ Compresión automática de logs grandes (>10MB)
- ✅ Consolidación automática de logs individuales
- ✅ Rotación automática de backups históricos
- ✅ Permisos de seguridad automáticos en configuración
- ✅ Creación automática de archivos de configuración con ejemplos
- ✅ Envío de múltiples adjuntos por email (resumen + detalle)

## 🚀 Automatización con ArturitoLauncher

Para programar backups automáticos, te recomendamos usar **ArturitoLauncher**, nuestro sistema de automatización y programación de tareas.

**Más información:** [ArturitoLauncher en GitHub](https://github.com/ArturitoSoftware/ArturitoLauncher)

### Programación con Task Scheduler (Windows)

```powershell
# Ejemplo de comando para Task Scheduler
powershell.exe -ExecutionPolicy Bypass -File "C:\Ruta\ArturitoBACAP.ps1" -Apagar -Historico 7
```

**Recomendaciones:**
- Ejecutar con usuario que tenga permisos en origen y destino
- Usar `-ExecutionPolicy Bypass` en la tarea programada
- Configurar para ejecutar con privilegios elevados si es necesario

## 🔍 Troubleshooting

### "El backup NO se ejecutará sin configuración de email válida"
**Solución**: Ejecuta `.\ArturitoBACAP.ps1 -AjustaEmail` o usa `-NoEmail`

### "DESTINO INVÁLIDO"
**Solución**: Verifica la ruta en `Destino.cfg`. El script intentará usar `C:\BCKP` como fallback.

### "NO HAY CARPETAS VÁLIDAS PARA BACKUP"
**Solución**: Revisa `Origen.cfg` y asegúrate de que las rutas existan y sean accesibles.

### Error "no se puede cargar el archivo... no está firmado digitalmente"
**Solución**: Ejecuta como Administrador:
```powershell
Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
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
- Ajustar la retención de logs con `FuncLimpiaLogs.ps1`

## 📁 Estructura del Proyecto

```
ArturitoBACAP/
├── ArturitoBACAP.ps1           # Script principal
├── FuncAyudin.ps1              # Función de ayuda integrada
├── FuncBorrarRapido.ps1        # Limpieza de carpetas obsoletas
├── FuncVerificaBACKUP.ps1      # Verificación de integridad
├── FuncValidacionUNC.ps1       # Validación y conversión UNC
├── FuncCierraTodo.ps1          # Cierre de aplicaciones
├── FuncLimpiaLogs.ps1          # Limpieza de logs antiguos
├── FuncGuardaHistorico.ps1     # Rotación de backups históricos
├── FuncEnviaEmail.ps1          # Envío de notificaciones (soporte múltiples adjuntos)
├── Origen.cfg                  # Configuración de carpetas origen (creado automáticamente)
├── Destino.cfg                 # Configuración de destino (creado automáticamente)
├── configSMTP.xml              # Configuración email encriptada (generado con -AjustaEmail)
├── README.md                   # Este archivo
├── .gitignore                  # Exclusiones de Git
└── Logs/                       # Carpeta de logs (creada automáticamente)
```

## 🤝 Contribución

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/NuevaFuncionalidad`)
3. Commit tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/NuevaFuncionalidad`)
5. Abre un Pull Request

## 📝 Notas Importantes

- ⚠️ **Scripts no firmados**: Debes desbloquear los archivos `.ps1` antes de ejecutar
- ⚠️ El modo silencioso (sin `-Debug`) es ideal para ArturitoLauncher
- ⚠️ `-AjustaEmail` tiene prioridad sobre otros modificadores
- ⚠️ El destino configurado se valida antes del backup
- ⚠️ Los archivos de configuración con datos sensibles NO deben subirse a Git
- ⚠️ `Origen.cfg` y `Destino.cfg` se crean automáticamente con ejemplos si no existen
- ⚠️ Los logs se envían por email en dos archivos: resumen ejecutivo y detalle completo

## 📄 Licencia

**Úselo bajo su responsabilidad**

Software By Arturito - Soporte Infoquil by WAJ

## 🙏 Créditos

Desarrollado por **Arturito**  
Soporte técnico: **Infoquil by WAJ**

---

**¿Preguntas o sugerencias?** Abre un issue en GitHub o contacta al equipo de soporte.