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
                     
-Simultaneas N       Número de backups simultáneos (1-32, por defecto: 3)
                     Mayor número = más rápido pero más uso de CPU/red
                     Ejemplo: .\ArturitoBACAP.ps1 -Simultaneas 8
                     
-Rapidito            Modo ultra-rápido con menos verificaciones de seguridad
                     Copia solo datos y timestamps (omite atributos/permisos)
                     Ejemplo: .\ArturitoBACAP.ps1 -Rapidito
                     
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
                   
- Destino.cfg      Carpeta destino del backup (UNA SOLA LÍNEA)
                   Las líneas que comienzan con # son ignoradas (comentarios)
                   Si no existe o es inválido: usa C:\BCKP por defecto
                   Soporta rutas locales (D:\Backups) y de red (\\NAS\Respaldos)
                   IMPORTANTE: Solo se permite una línea de destino válida
                   
- configSMTP.xml   Configuración SMTP completa encriptada (usar -AjustaEmail)
                   Incluye: servidor, puerto, SSL, credenciales, remitente, destinatario
                   Solo accesible por el usuario que lo configuró
"@ -ForegroundColor Green
Write-Host @"
`nLOGS GENERADOS:
===============
"@ -ForegroundColor Cyan
Write-Host @"
- BCKP_Resumen_YYYYMMDD_HHMMSS.log    Resumen ejecutivo consolidado
                                      Incluye: estadísticas, errores, conversiones UNC
                                      
- BCKP_Detalle_YYYYMMDD_HHMMSS.log    Logs detallados de todas las operaciones
                                      Consolidado de todos los logs individuales
                                      Incluye: robocopy, verificación, limpieza
"@ -ForegroundColor Green
Write-Host @"
`nFUNCIONALIDADES AUTOMÁTICAS:
============================
"@ -ForegroundColor Cyan
Write-Host @"
✅ Validación completa de rutas antes del backup (detecta errores tempranamente)
✅ Conversión automática de unidades lógicas a rutas UNC (C:\ → \\EQUIPO\C$\)
✅ Fallback automático a C:\BCKP si destino configurado es inválido
✅ Eliminación automática de carpetas obsoletas en destino
✅ Detección automática de threads óptimos según CPU disponible
✅ Compresión automática de logs grandes (>10MB) antes de enviar por email
✅ Consolidación automática de logs individuales en un único archivo detallado
✅ Rotación automática de backups históricos (con -Historico N)
✅ Permisos de seguridad automáticos en archivos de configuración
"@ -ForegroundColor Green
Write-Host @"
`nCONFIGURACIÓN DEL DESTINO (Destino.cfg):
========================================
"@ -ForegroundColor Cyan
Write-Host @"
El archivo Destino.cfg permite configurar la carpeta de destino del backup:

📁 FORMATO DEL ARCHIVO:
   # Comentarios comienzan con #
   # Solo se permite UNA línea de destino válida
   D:\MisBackups

📋 VALIDACIÓN AUTOMÁTICA:
   1️⃣  Si Destino.cfg no existe → se crea con ejemplos y usa C:\BCKP
   2️⃣  Si tiene una ruta válida → se valida y usa esa ruta
   3️⃣  Si la ruta es inválida → intenta con C:\BCKP automáticamente
   4️⃣  Si tiene múltiples líneas → usa C:\BCKP por defecto

⚠️  CASOS ESPECIALES:
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
`nPRIMER USO - GUÍA RÁPIDA:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
1️⃣  Configurar email (OBLIGATORIO si no usas -NoEmail):
   .\ArturitoBACAP.ps1 -AjustaEmail
   
2️⃣  (OPCIONAL) Editar Destino.cfg para cambiar destino del backup:
   # Por defecto usa C:\BCKP
   # Descomenta y modifica si necesitas otro destino
   D:\Respaldos
   
3️⃣  Editar Origen.cfg con las carpetas a respaldar:
   # Descomenta y modifica las líneas de ejemplo
   C:\Users\TuUsuario\Documents
   C:\Users\TuUsuario\Desktop
   
4️⃣  Ejecutar primer backup de prueba:
   .\ArturitoBACAP.ps1 -Debug -NoEmail
   
5️⃣  Si todo OK, configurar en Task Scheduler:
   .\ArturitoBACAP.ps1
   (sin parámetros = modo silencioso con email)
"@ -ForegroundColor Green
Write-Host @"
`nNOTAS IMPORTANTES:
==================
"@ -ForegroundColor Cyan
Write-Host @"
⚠️  Si intentas ejecutar sin -NoEmail y sin configuración de email,
   el script se detendrá y te pedirá ejecutar -AjustaEmail primero.
   
⚠️  -AjustaEmail tiene PRIORIDAD MÁXIMA sobre otros modificadores.
   Si lo usas, el resto de parámetros son ignorados.
   
⚠️  El modo silencioso (sin -Debug) es ideal para Task Scheduler.
   Solo genera logs, sin salidas en pantalla.
   
⚠️  Si Destino.cfg no existe o es inválido, el script usa C:\BCKP
   automáticamente como destino por defecto (con fallback inteligente).
   
⚠️  El destino configurado en Destino.cfg se valida completamente antes
   del backup. Si falla, el script intenta con C:\BCKP automáticamente.
"@ -ForegroundColor Red
Write-Host @"
`n=====================================================
=== Software By Arturito - Soporte Infoquil by WAJ ===
=== ÚSELO BAJO SU RESPONSABILIDAD                 ===
=====================================================
"@ -ForegroundColor White
}