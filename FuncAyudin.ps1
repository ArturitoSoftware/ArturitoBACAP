# Funcion de Ayuda integrada de Arturito BACAP
function Show-Help {
    Write-Host @"
=====================================================
=== 🚀 ArturitoBACAP - Backup Inteligente - 2025 ===
===                                              ====
================== AYUDA INTEGRADA ==================
===                                              ====
=====================================================
"@ -ForegroundColor White
    Write-Host @"
`nMODIFICADORES DISPONIBLES:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
-AjustaEmail         Configurar todos los parámetros SMTP para envío de emails
                     (servidor, puerto, credenciales, remitente, destinatario)
                     INCLUYE email de prueba automático al finalizar
                     Ejemplo: .\ArturitoBACAP.ps1 -AjustaEmail
                     
-NoEmail             Ejecutar backup sin enviar email de reporte
                     (útil para ejecuciones manuales o pruebas)
                     Ejemplo: .\ArturitoBACAP.ps1 -NoEmail
                     
-Perfil N            Usar perfil de configuración específico (0-99)
                     0 = modo estándar (sin perfil, comportamiento original)
                     1-99 = usa solo líneas que comienzan con N: en configs
                     IMPORTANTE: Perfiles requieren destino válido obligatorio
                     Ejemplo: .\ArturitoBACAP.ps1 -Perfil 1
                     
-Simultaneas N       Número de backups simultáneos (1-32, por defecto: 3)
                     Mayor número = más rápido pero más uso de CPU/red
                     Ejemplo: .\ArturitoBACAP.ps1 -Simultaneas 8
                     
-Rapidito            Modo ultra-rápido con menos verificaciones de seguridad
                     Copia solo datos y timestamps (omite atributos/permisos)
                     Ejemplo: .\ArturitoBACAP.ps1 -Rapidito
                     
-NuncaBorra          Modo protección: NO elimina archivos ni carpetas obsoletas
                     Equivale a /E en lugar de /MIR en Robocopy
                     Útil para backups incrementales sin borrado
                     Ejemplo: .\ArturitoBACAP.ps1 -NuncaBorra
                     
-Debug               Habilita mensajes en pantalla (modo interactivo)
                     Por defecto: modo silencioso para Task Scheduler
                     Ejemplo: .\ArturitoBACAP.ps1 -Debug
                     
-Verifica            Verificar integridad del backup al finalizar
                     Compara origen vs destino para detectar diferencias
                     Ejemplo: .\ArturitoBACAP.ps1 -Verifica
                     
-Apagar              Apagar el equipo automáticamente al terminar
                     En modo Debug: da 30 segundos para cancelar (CTRL+C)
                     En modo silencioso: apaga inmediatamente
                     Ejemplo: .\ArturitoBACAP.ps1 -Apagar
                     
-CierroTodo          Cerrar todos los programas antes de iniciar backup
                     (recomendado para backups de bases de datos activas)
                     Ejemplo: .\ArturitoBACAP.ps1 -CierroTodo
                     
-Historico N         Mantener N backups históricos rotando automáticamente
                     0 = no guardar históricos (solo backup actual)
                     Ejemplo: .\ArturitoBACAP.ps1 -Historico 5
                     
-Ayuda               Mostrar esta ayuda
                     Ejemplo: .\ArturitoBACAP.ps1 -Ayuda
"@ -ForegroundColor Green
Write-Host @"
`nCOMBINACIONES ÚTILES:
====================
"@ -ForegroundColor Cyan
Write-Host @"
# Backup rápido con verificación (recomendado para producción)
.\ArturitoBACAP.ps1 -Rapidito -Simultaneas 8 -Verifica

# Backup completo con apagado automático (ideal para Task Scheduler nocturno)
.\ArturitoBACAP.ps1 -Apagar -Historico 7

# Backup de prueba sin email ni apagado (para testing)
.\ArturitoBACAP.ps1 -NoEmail -Debug -Verifica

# Backup completo cerrando aplicaciones (para sistemas en uso)
.\ArturitoBACAP.ps1 -CierroTodo -Verifica -Simultaneas 5

# Backup máximo rendimiento (sin verificación ni email)
.\ArturitoBACAP.ps1 -Rapidito -Simultaneas 16 -NoEmail

# Backup incremental sin borrar archivos obsoletos (modo protección)
.\ArturitoBACAP.ps1 -NuncaBorra -Verifica

# Usar perfil 1 con verificación y sin borrado
.\ArturitoBACAP.ps1 -Perfil 1 -NuncaBorra -Verifica

# Usar perfil 2 en modo rápido con apagado
.\ArturitoBACAP.ps1 -Perfil 2 -Rapidito -Apagar
"@ -ForegroundColor Green
Write-Host @"
`nARCHIVOS DE CONFIGURACIÓN:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
- Origen.cfg       Lista de carpetas a respaldar (una por línea)
                   Las líneas que comienzan con # son ignoradas (comentarios)
                   Soporta rutas locales (C:\) y de red (\\servidor\carpeta)
                   Conversión automática a UNC cuando es necesario
                   Se crea automáticamente con ejemplos si no existe
                   SOPORTA PERFILES: Líneas con formato N:[ruta]
                   
- Destino.cfg      Carpeta destino del backup (UNA SOLA LÍNEA)
                   Las líneas que comienzan con # son ignoradas (comentarios)
                   Si no existe o es inválido: usa C:\BCKP por defecto
                   EXCEPTO con perfiles: requiere destino válido obligatorio
                   Soporta rutas locales (D:\Backups) y de red (\\NAS\Respaldos)
                   IMPORTANTE: Solo se permite una línea de destino válida
                   Se crea automáticamente con ejemplos si no existe
                   SOPORTA PERFILES: Líneas con formato N:[ruta]
                   
- configSMTP.xml   Configuración SMTP completa encriptada (usar -AjustaEmail)
                   Incluye: servidor, puerto, SSL, credenciales, remitente, destinatario
                   Solo accesible por el usuario que lo configuró
"@ -ForegroundColor Green
Write-Host @"
`nSISTEMA DE PERFILES:
====================
"@ -ForegroundColor Cyan
Write-Host @"
Los perfiles permiten mantener múltiples configuraciones de backup en los
mismos archivos Origen.cfg y Destino.cfg, seleccionando cuál usar con -Perfil N.

📋 FORMATO DE PERFILES:

   En Origen.cfg y Destino.cfg, las líneas pueden tener dos formatos:

   1️⃣  Sin prefijo (modo estándar):
      C:\Documentos
      D:\Proyectos
      
   2️⃣  Con prefijo numérico (para perfiles):
      1:C:\Users\Juan\Documents
      1:C:\Users\Juan\Pictures
      2:C:\Proyectos\ClienteA
      2:D:\Trabajo

🎯 COMPORTAMIENTO SEGÚN PERFIL:

   -Perfil 0 (o sin especificar):
   • Usa solo líneas SIN prefijo numérico
   • Ignora líneas con formato N: (no genera error)
   • Permite usar C:\BCKP como destino por defecto
   • Comportamiento original del script
   
   -Perfil 1:
   • Usa SOLO líneas que comienzan con 1:
   • Remueve el prefijo 1: antes de usar la ruta
   • REQUIERE destino válido (no usa C:\BCKP por defecto)
   • Si no hay destino válido → ERROR y no avanza
   
   -Perfil 2, 3, ... 99:
   • Mismo comportamiento que Perfil 1
   • Usa líneas con su número específico

⚠️  IMPORTANTE - PERFILES Y DESTINOS:

   • PERFIL 0: Permite usar C:\BCKP si no hay destino válido
   • PERFIL 1-99: REQUIERE destino válido obligatoriamente
   • Los perfiles NO pueden usar el destino por defecto
   • Esto garantiza que cada perfil tenga su destino específico

📝 EJEMPLO COMPLETO:

   Origen.cfg:
   # Modo estándar (sin perfil)
   C:\Documentos
   D:\Proyectos
   
   # Perfil 1 - Backup Personal
   1:C:\Users\Juan\Documents
   1:C:\Users\Juan\Pictures
   
   # Perfil 2 - Backup Trabajo
   2:C:\Proyectos\ClienteA
   2:D:\Trabajo

   Destino.cfg:
   # Modo estándar
   C:\BCKP
   
   # Perfil 1
   1:D:\Backup_Personal
   
   # Perfil 2
   2:E:\Backup_Trabajo

   Uso:
   .\ArturitoBACAP.ps1              → Usa C:\Documentos y D:\Proyectos → C:\BCKP
   .\ArturitoBACAP.ps1 -Perfil 1    → Usa Documents y Pictures → D:\Backup_Personal
   .\ArturitoBACAP.ps1 -Perfil 2    → Usa ClienteA y Trabajo → E:\Backup_Trabajo

✅ VALIDACIONES AUTOMÁTICAS:

   • Verifica que existan líneas válidas para el perfil seleccionado
   • Valida que el destino tenga solo UNA línea por perfil
   • Con perfiles: valida destino obligatorio antes de avanzar
   • Mensajes claros si falta configuración del perfil

🔧 CASOS DE USO:

   • Perfil 1: Backup personal diario
   • Perfil 2: Backup de trabajo semanal
   • Perfil 3: Backup completo mensual
   • Perfil 0: Backup general sin categorizar
"@ -ForegroundColor Green
Write-Host @"
`nMODO NUNCABORRA (PROTECCIÓN):
=============================
"@ -ForegroundColor Cyan
Write-Host @"
El modificador -NuncaBorra activa un modo de protección especial que impide
la eliminación de archivos y carpetas en el destino.

🛡️  COMPORTAMIENTO:

   SIN -NuncaBorra (comportamiento estándar):
   • Usa /MIR en Robocopy (mirror = espejo exacto)
   • Elimina carpetas obsoletas en destino
   • Elimina archivos que ya no están en origen
   • Destino es copia exacta del origen
   
   CON -NuncaBorra:
   • Usa /E en lugar de /MIR (copia sin eliminar)
   • NO elimina carpetas obsoletas en destino
   • NO elimina archivos que ya no están en origen
   • Destino acumula todos los archivos (incremental)
   • Ideal para mantener historial completo

⚠️  CASOS DE USO:

   ✅ USAR -NuncaBorra cuando:
   • Quieres mantener archivos antiguos eliminados del origen
   • Necesitas historial completo de cambios
   • Backup incremental acumulativo
   • Proteges contra borrados accidentales en origen
   
   ❌ NO USAR -NuncaBorra cuando:
   • Quieres destino como espejo exacto del origen
   • El espacio en disco es limitado
   • Necesitas limpiar archivos obsoletos automáticamente

📊 IMPACTO EN LOGS Y REPORTES:

   • Los logs muestran: "Modo NuncaBorra: ACTIVO"
   • No se reportan carpetas/archivos eliminados
   • La verificación solo compara origen→destino (no viceversa)
   • Los emails indican: "Modo NuncaBorra: Sin eliminación de obsoletos"

💡 EJEMPLO:

   Backup estándar (con borrado):
   .\ArturitoBACAP.ps1 -Verifica
   
   Backup protegido (sin borrado):
   .\ArturitoBACAP.ps1 -NuncaBorra -Verifica
"@ -ForegroundColor Green
Write-Host @"
`nLOGS GENERADOS:
===============
"@ -ForegroundColor Cyan
Write-Host @"
- BCKP_Resumen_YYYYMMDD_HHMMSS.log    Resumen ejecutivo consolidado
                                      Incluye: perfil usado, estadísticas, errores
                                      conversiones UNC, modo NuncaBorra
                                      📧 ADJUNTO AL EMAIL: Siempre se envía
                                      
- BCKP_Detalle_YYYYMMDD_HHMMSS.log    Logs detallados de todas las operaciones
                                      Consolidado de todos los logs individuales
                                      Incluye: perfil, robocopy, verificación, limpieza
                                      📧 ADJUNTO AL EMAIL: Siempre se envía
                                      
💡 AMBOS LOGS SE ENVÍAN POR EMAIL: El reporte incluye tanto el resumen ejecutivo
   como el log completo detallado para máxima trazabilidad.
   
💾 COMPRESIÓN AUTOMÁTICA: Logs mayores a 10MB se comprimen automáticamente
   antes de enviar por email (reduce ancho de banda y espacio).
   
🎯 INFORMACIÓN DE PERFILES: Los logs siempre muestran qué perfil se usó:
   • "Perfil: 1" si se usó -Perfil 1
   • "Perfil: Estándar (sin perfil)" si se usó modo normal
   • El subject del email incluye [P1] para indicar el perfil
"@ -ForegroundColor Green
Write-Host @"
`nFUNCIONALIDADES AUTOMÁTICAS:
============================
"@ -ForegroundColor Cyan
Write-Host @"
✅ Validación completa de rutas antes del backup (detecta errores tempranamente)
✅ Conversión automática de unidades lógicas a rutas UNC (C:\ → \\EQUIPO\C$\)
✅ Fallback automático a C:\BCKP si destino es inválido (solo en modo estándar)
✅ Eliminación automática de carpetas obsoletas en destino (excepto con -NuncaBorra)
✅ Detección automática de threads óptimos según CPU disponible
✅ Compresión automática de logs grandes (>10MB) antes de enviar por email
✅ Consolidación automática de logs individuales en un único archivo detallado
✅ Rotación automática de backups históricos (con -Historico N)
✅ Permisos de seguridad automáticos en archivos de configuración
✅ Creación automática de archivos de configuración con ejemplos (Origen.cfg, Destino.cfg)
✅ Envío automático de múltiples adjuntos por email (resumen + detalle completo)
✅ Procesamiento automático de perfiles con archivos temporales (se limpian al finalizar)
✅ Validación estricta de destinos con perfiles (requiere destino válido obligatorio)
"@ -ForegroundColor Green
Write-Host @"
`nCONFIGURACIÓN DEL DESTINO (Destino.cfg):
========================================
"@ -ForegroundColor Cyan
Write-Host @"
El archivo Destino.cfg permite configurar la carpeta de destino del backup:

📁 FORMATO DEL ARCHIVO (MODO ESTÁNDAR):
   # Comentarios comienzan con #
   # Solo se permite UNA línea de destino válida
   D:\MisBackups

📁 FORMATO CON PERFILES:
   # Modo estándar (sin perfil)
   C:\BCKP
   
   # Perfil 1
   1:D:\Backup_Personal
   
   # Perfil 2
   2:E:\Backup_Trabajo

📋 VALIDACIÓN AUTOMÁTICA (MODO ESTÁNDAR):
   1️⃣  Si Destino.cfg no existe → se crea con ejemplos y usa C:\BCKP
   2️⃣  Si tiene una ruta válida → se valida y usa esa ruta
   3️⃣  Si la ruta es inválida → intenta con C:\BCKP automáticamente
   4️⃣  Si tiene múltiples líneas → usa C:\BCKP por defecto

📋 VALIDACIÓN CON PERFILES (-Perfil 1-99):
   1️⃣  Si no existe Destino.cfg → ERROR (no usa C:\BCKP)
   2️⃣  Si no hay línea para el perfil → ERROR (no usa C:\BCKP)
   3️⃣  Si la ruta del perfil es inválida → ERROR (no usa C:\BCKP)
   4️⃣  Si hay múltiples líneas del perfil → ERROR
   
   ⚠️  IMPORTANTE: Los perfiles REQUIEREN destino válido obligatorio
   No se permite usar C:\BCKP como fallback con perfiles

⚠️  CASOS ESPECIALES (SOLO MODO ESTÁNDAR):
   • Archivo vacío o solo comentarios → usa C:\BCKP
   • Línea vacía después de quitar espacios → usa C:\BCKP
   • Más de una línea válida → usa C:\BCKP (solo se permite UNA ruta)

✅ RUTAS SOPORTADAS:
   C:\Backups                  ✓ Ruta local
   D:\Respaldos                ✓ Otro disco local
   \\servidor\compartido       ✓ Ruta de red UNC
   \\NAS\Backups\Empresa       ✓ Ruta de red con subcarpetas
   Z:\                         ✓ Unidad mapeada (se convierte a UNC)
   
❌ RUTAS NO SOPORTADAS:
   Disco:\Backup               ✗ Unidad inválida
   C:Backup                    ✗ Sin barra invertida
   ftp://servidor/backup       ✗ Protocolos no soportados
"@ -ForegroundColor Green
Write-Host @"
`n⚠️  SCRIPTS NO FIRMADOS - DESBLOQUEO REQUERIDO:
==============================================
"@ -ForegroundColor Yellow
Write-Host @"
ArturitoBACAP y sus funciones auxiliares NO están firmados digitalmente.
Antes de ejecutar por primera vez, debes desbloquear todos los archivos.

🔓 COMANDO OBLIGATORIO (ejecutar como Administrador):
   Get-ChildItem -Path . -Filter *.ps1 | Unblock-File

Este comando desbloquea todos los scripts .ps1 en la carpeta actual,
permitiendo su ejecución sin restricciones de seguridad.

✅ VERIFICAR DESBLOQUEO:
   Get-ChildItem -Path . -Filter *.ps1 | Get-Item -Stream Zone.Identifier -ErrorAction SilentlyContinue
   
   Si no devuelve resultados → scripts correctamente desbloqueados ✓

⚠️  ALTERNATIVA (NO RECOMENDADA para uso permanente):
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   
   Esta opción solo afecta la sesión actual de PowerShell.
"@ -ForegroundColor Red
Write-Host @"
`nPRIMER USO - GUÍA RÁPIDA:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
0️⃣  Desbloquear scripts (OBLIGATORIO - una sola vez):
   Get-ChildItem -Path . -Filter *.ps1 | Unblock-File
   
1️⃣  Configurar email (OBLIGATORIO si no usas -NoEmail):
   .\ArturitoBACAP.ps1 -AjustaEmail
   
2️⃣  (OPCIONAL) Editar Destino.cfg para cambiar destino del backup:
   # Por defecto usa C:\BCKP (solo en modo estándar)
   # Con perfiles requiere destino válido obligatorio
   # Si no existe, se crea automáticamente con ejemplos
   # Descomenta y modifica si necesitas otro destino
   D:\Respaldos
   
3️⃣  Editar Origen.cfg con las carpetas a respaldar:
   # Si no existe, se crea automáticamente con ejemplos
   # Descomenta y modifica las líneas de ejemplo
   C:\Users\TuUsuario\Documents
   C:\Users\TuUsuario\Desktop
   
4️⃣  Ejecutar primer backup de prueba:
   .\ArturitoBACAP.ps1 -Debug -NoEmail
   
5️⃣  Si todo OK, configurar en Task Scheduler:
   .\ArturitoBACAP.ps1
   (sin parámetros = modo silencioso con email)
   
6️⃣  (OPCIONAL) Configurar perfiles si necesitas múltiples configuraciones:
   # Edita Origen.cfg y Destino.cfg agregando líneas con formato:
   # 1:[ruta] para perfil 1, 2:[ruta] para perfil 2, etc.
   # Luego ejecuta: .\ArturitoBACAP.ps1 -Perfil 1
"@ -ForegroundColor Green
Write-Host @"
`nNOTAS IMPORTANTES:
==================
"@ -ForegroundColor Cyan
Write-Host @"
⚠️  SCRIPTS NO FIRMADOS: Debes desbloquear los archivos .ps1 antes de ejecutar.
   Comando: Get-ChildItem -Path . -Filter *.ps1 | Unblock-File

⚠️  Si intentas ejecutar sin -NoEmail y sin configuración de email,
   el script se detendrá y te pedirá ejecutar -AjustaEmail primero.
   
⚠️  -AjustaEmail tiene PRIORIDAD MÁXIMA sobre otros modificadores.
   Si lo usas, el resto de parámetros son ignorados.
   
⚠️  El modo silencioso (sin -Debug) es ideal para Task Scheduler.
   Solo genera logs, sin salidas en pantalla.
   
⚠️  Si Destino.cfg no existe, se crea automáticamente con ejemplos.
   En modo estándar usa C:\BCKP. Con perfiles requiere destino válido.
   
⚠️  Si Origen.cfg no existe, se crea automáticamente con ejemplos
   y el script se detiene para que edites las carpetas a respaldar.
   
⚠️  PERFILES Y DESTINOS: Los perfiles (1-99) REQUIEREN destino válido.
   No se permite usar C:\BCKP como fallback con perfiles.
   
⚠️  -NuncaBorra protege el destino contra borrados automáticos.
   Útil para backups incrementales acumulativos.
   
⚠️  Los emails incluyen AMBOS logs adjuntos: resumen ejecutivo + detalle completo
   (logs >10MB se comprimen automáticamente antes de enviar).
   
⚠️  Los emails muestran el perfil usado: [P1] en subject, "Perfil: 1" en body.
"@ -ForegroundColor Red
Write-Host @"
`n=====================================================
=== Software By Arturito - Soporte Infoquil by WAJ ===
=== ÚSELO BAJO SU RESPONSABILIDAD                 ===
=====================================================
"@ -ForegroundColor White
}