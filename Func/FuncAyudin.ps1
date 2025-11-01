# ================================
# Función de Ayuda integrada de ArturitoBACAP
# FuncAyudin.ps1
# Ubicación: Func\FuncAyudin.ps1
# ================================

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
`nESTRUCTURA DEL PROYECTO:
=======================
"@ -ForegroundColor Cyan
Write-Host @"
ArturitoBACAP/
├── ArturitoBACAP.ps1           Script principal
│
├── Conf/                        Archivos de configuración
│   ├── configSMTP.xml          Config email (generado con -AjustaEmail)
│   ├── Origen.cfg              Carpetas origen (auto-generado)
│   ├── Destino.cfg             Carpeta destino (auto-generado)
│   ├── Omitir.cfg              Exclusiones (auto-generado)
│   └── MapeosUNC.json          Histórico conversiones UNC (auto)
│
├── Func/                        Funciones modulares
│   ├── FuncAyudin.ps1          Ayuda integrada
│   ├── FuncBorrarRapido.ps1    Limpieza de obsoletos
│   ├── FuncCierraTodo.ps1      Cierre de aplicaciones
│   ├── FuncEnviaEmail.ps1      Envío de notificaciones
│   ├── FuncGuardaHistorico.ps1 Rotación de históricos
│   ├── FuncLimpiaLogs.ps1      Limpieza de logs antiguos
│   ├── FuncManejaOmitir.ps1    Procesamiento exclusiones
│   ├── FuncManejaPerfiles.ps1  Procesamiento perfiles
│   ├── FuncValidacionUNC.ps1   Validación y conversión UNC
│   └── FuncVerificaBACKUP.ps1  Verificación de integridad
│
├── Temp/                        Archivos temporales (auto-limpiados)
└── Logs/                        Logs de backup (rotación auto)

💡 ARQUITECTURA MODULAR: Todas las funciones están organizadas en carpetas
   específicas para máximo orden y mantenibilidad. El proyecto es totalmente
   portable - puedes mover la carpeta completa a cualquier ubicación.
"@ -ForegroundColor Green
Write-Host @"
`nARCHIVOS DE CONFIGURACIÓN:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
📁 Conf/Origen.cfg
   Lista de carpetas a respaldar (una por línea)
   • Las líneas que comienzan con # son comentarios
   • Soporta rutas locales (C:\) y de red (\\servidor\carpeta)
   • Conversión automática a UNC cuando es necesario
   • Se crea automáticamente con ejemplos si no existe
   • SOPORTA PERFILES: Líneas con formato N:[ruta]
   
📁 Conf/Destino.cfg
   Carpeta destino del backup (UNA SOLA LÍNEA por perfil)
   • Las líneas con # son comentarios
   • Modo estándar: Si no existe o es inválido → usa C:\BCKP
   • Con perfiles: Requiere destino válido obligatorio (no usa C:\BCKP)
   • Soporta rutas locales y de red
   • Se crea automáticamente con ejemplos si no existe
   • SOPORTA PERFILES: Líneas con formato N:[ruta]
   
📁 Conf/Omitir.cfg
   Carpetas a excluir del backup (sistema híbrido)
   • Nombre simple: node_modules (omite en cualquier nivel)
   • Ruta relativa: Documentos\Temp (desde raíz de origen)
   • Ruta absoluta: C:\Datos\NoBackup (solo esa ruta exacta)
   • Se crea automáticamente con ejemplos si no existe
   • SOPORTA PERFILES: Líneas con formato N:[ruta]
   • Conversión UNC automática para unidades mapeadas
   
📁 Conf/configSMTP.xml
   Configuración SMTP completa encriptada (usar -AjustaEmail)
   • Servidor, puerto, SSL, credenciales, remitente, destinatario
   • Solo accesible por el usuario que lo configuró
   • Permisos restrictivos automáticos
   
📁 Conf/MapeosUNC.json
   Histórico de conversiones UNC (generado automáticamente)
   • Recuerda mapeos de unidades lógicas → rutas UNC
   • Formato JSON: {"Z:": "\\\\servidor\\datos"}
   • No requiere configuración manual
"@ -ForegroundColor Green
Write-Host @"
`nSISTEMA DE PERFILES:
====================
"@ -ForegroundColor Cyan
Write-Host @"
Los perfiles permiten mantener múltiples configuraciones de backup en los
mismos archivos Origen.cfg, Destino.cfg y Omitir.cfg.

📋 FORMATO DE PERFILES:

   1️⃣  Sin prefijo (modo estándar):
      C:\Documentos
      D:\Proyectos
      
   2️⃣  Con prefijo numérico (perfiles 1-99):
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
   
   -Perfil 1-99:
   • Usa SOLO líneas que comienzan con N:
   • Remueve el prefijo N: antes de usar la ruta
   • REQUIERE destino válido (no usa C:\BCKP por defecto)
   • Si no hay destino válido → ERROR y no avanza

⚠️  IMPORTANTE - PERFILES Y DESTINOS:

   • PERFIL 0: Permite usar C:\BCKP si no hay destino válido
   • PERFIL 1-99: REQUIERE destino válido obligatoriamente
   • Los perfiles NO pueden usar el destino por defecto
   • Garantiza que cada perfil tenga su destino específico

📝 EJEMPLO COMPLETO:

   Conf/Origen.cfg:
   # Modo estándar
   C:\Documentos
   
   # Perfil 1 - Personal
   1:C:\Users\Juan\Documents
   1:C:\Users\Juan\Pictures
   
   # Perfil 2 - Trabajo
   2:C:\Proyectos\ClienteA

   Conf/Destino.cfg:
   # Modo estándar
   C:\BCKP
   
   # Perfil 1
   1:D:\Backup_Personal
   
   # Perfil 2
   2:E:\Backup_Trabajo
   
   Conf/Omitir.cfg:
   # Modo estándar
   node_modules
   .git
   
   # Perfil 1
   1:Temp
   1:.vs
   
   # Perfil 2
   2:Build
   2:obj

   Uso:
   .\ArturitoBACAP.ps1              → Usa config estándar
   .\ArturitoBACAP.ps1 -Perfil 1    → Usa config perfil 1
   .\ArturitoBACAP.ps1 -Perfil 2    → Usa config perfil 2

✅ VALIDACIONES AUTOMÁTICAS:

   • Verifica líneas válidas para el perfil seleccionado
   • Valida destino con solo UNA línea por perfil
   • Con perfiles: valida destino obligatorio antes de avanzar
   • Mensajes claros si falta configuración
"@ -ForegroundColor Green
Write-Host @"
`nSISTEMA DE EXCLUSIONES (Omitir.cfg):
====================================
"@ -ForegroundColor Cyan
Write-Host @"
El archivo Conf/Omitir.cfg usa un SISTEMA HÍBRIDO de exclusión con tres
tipos diferentes según cómo especifiques la ruta.

📋 TIPOS DE EXCLUSIÓN:

   1️⃣  NOMBRE SIMPLE (omite en cualquier nivel):
      node_modules
      .git
      Temp
      
      Resultado:
      ✓ Omite: C:\Datos\node_modules
      ✓ Omite: C:\Docs\Proyectos\node_modules
      ✓ Omite: D:\Cualquier\Ruta\node_modules
   
   2️⃣  RUTA RELATIVA (desde raíz de cada origen):
      Documentos\Temp
      Proyectos\.git
      
      Resultado:
      ✓ Omite: [origen]\Documentos\Temp
      ✗ NO omite: [origen]\Otros\Temp
   
   3️⃣  RUTA ABSOLUTA (solo esa ruta específica):
      C:\Datos\NoBackupear
      D:\Proyectos\Build
      
      Resultado:
      ✓ Omite: SOLO C:\Datos\NoBackupear
      ✗ NO omite: D:\Datos\NoBackupear

🔄 CONVERSIÓN UNC AUTOMÁTICA:

   Si excluyes una unidad mapeada, se convierte automáticamente:
   
   Ejemplo:
   • Excluyes: Z:\Carpeta
   • Z: mapea a \\servidor\datos
   • Se excluye: \\servidor\datos\Carpeta

📝 EJEMPLO COMPLETO:

   Conf/Omitir.cfg:
   # Nombres simples (omiten en cualquier nivel)
   node_modules
   .git
   `$RECYCLE.BIN
   System Volume Information
   
   # Rutas relativas (desde raíz de origen)
   Documentos\Temp
   Proyectos\Build
   
   # Rutas absolutas (solo rutas específicas)
   C:\Datos\NoBackupear
   D:\Trabajo\Temporal
   
   # Perfil 1 - Exclusiones Personal
   1:Temp
   1:AppData\Local\Temp
   1:.vs
   
   # Perfil 2 - Exclusiones Trabajo
   2:node_modules
   2:.git
   2:C:\Proyectos\Build

💡 RECOMENDACIONES:

   • Nombres simples: Para carpetas comunes (node_modules, .git)
   • Rutas relativas: Para estructura específica de tus orígenes
   • Rutas absolutas: Para excluir carpetas muy específicas
   • Usa perfiles para diferentes conjuntos de exclusiones

⚠️  Las exclusiones se muestran en logs clasificadas por tipo
"@ -ForegroundColor Green
Write-Host @"
`nMODO NUNCABORRA (PROTECCIÓN):
=============================
"@ -ForegroundColor Cyan
Write-Host @"
El modificador -NuncaBorra activa modo de protección que impide la
eliminación de archivos y carpetas en el destino.

🛡️  COMPORTAMIENTO:

   SIN -NuncaBorra (estándar):
   • Usa /MIR en Robocopy (mirror = espejo exacto)
   • Elimina carpetas obsoletas en destino
   • Elimina archivos que ya no están en origen
   • Destino = copia exacta del origen
   
   CON -NuncaBorra:
   • Usa /E en lugar de /MIR (copia sin eliminar)
   • NO elimina carpetas obsoletas
   • NO elimina archivos que ya no están en origen
   • Destino acumula archivos (incremental)
   • Ideal para mantener historial completo

⚠️  CASOS DE USO:

   ✅ USAR -NuncaBorra cuando:
   • Quieres mantener archivos antiguos del origen
   • Necesitas historial completo de cambios
   • Backup incremental acumulativo
   • Protección contra borrados accidentales
   
   ❌ NO USAR -NuncaBorra cuando:
   • Quieres destino como espejo exacto
   • El espacio en disco es limitado
   • Necesitas limpiar archivos obsoletos auto

📊 IMPACTO EN LOGS:

   • Logs muestran: "Modo NuncaBorra: ACTIVO"
   • No se reportan carpetas/archivos eliminados
   • Verificación solo compara origen→destino
   • Emails: "Modo NuncaBorra: Sin eliminación"

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
📄 Logs/BCKP_Resumen_YYYYMMDD_HHMMSS.log
   Resumen ejecutivo consolidado
   • Perfil usado, estadísticas, errores
   • Conversiones UNC, modo NuncaBorra
   • Exclusiones aplicadas
   • 📧 ADJUNTO AL EMAIL: Siempre
                                      
📄 Logs/BCKP_Detalle_YYYYMMDD_HHMMSS.log
   Log detallado de todas las operaciones
   • Perfil, robocopy, verificación, limpieza
   • Consolidado de logs individuales
   • Detalles de exclusiones
   • 📧 ADJUNTO AL EMAIL: Siempre
                                      
💡 AMBOS LOGS SE ENVÍAN POR EMAIL: Máxima trazabilidad
   
💾 COMPRESIÓN AUTOMÁTICA: Logs >10MB se comprimen antes de enviar
   
🎯 INFORMACIÓN DE PERFILES: Los logs muestran el perfil usado:
   • "Perfil: 1" si se usó -Perfil 1
   • "Perfil: Estándar" en modo normal
   • Subject email: [P1] para indicar perfil
   
🗑️ ROTACIÓN AUTOMÁTICA: Logs >30 días se eliminan auto
"@ -ForegroundColor Green
Write-Host @"
`nFUNCIONALIDADES AUTOMÁTICAS:
============================
"@ -ForegroundColor Cyan
Write-Host @"
✅ Validación completa de rutas antes del backup
✅ Conversión automática unidades lógicas → UNC
✅ Fallback a C:\BCKP si destino inválido (solo modo estándar)
✅ Eliminación automática carpetas obsoletas (excepto -NuncaBorra)
✅ Detección automática threads óptimos según CPU
✅ Compresión automática logs grandes (>10MB)
✅ Consolidación automática logs individuales
✅ Rotación automática backups históricos
✅ Permisos seguridad automáticos en configs
✅ Creación automática archivos config con ejemplos
✅ Envío múltiples adjuntos email (resumen + detalle)
✅ Procesamiento automático perfiles con archivos temp
✅ Validación estricta destinos con perfiles
✅ Indicación clara perfil usado en logs/emails
✅ Procesamiento automático exclusiones con conversión UNC
✅ Limpieza automática archivos temporales al finalizar
✅ Histórico automático conversiones UNC en Conf/MapeosUNC.json
"@ -ForegroundColor Green
Write-Host @"
`nCONFIGURACIÓN DEL DESTINO:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
El archivo Conf/Destino.cfg configura la carpeta destino del backup.

📋 VALIDACIÓN AUTOMÁTICA (MODO ESTÁNDAR):
   1️⃣  Si no existe → crea con ejemplos y usa C:\BCKP
   2️⃣  Si tiene ruta válida → la valida y usa
   3️⃣  Si es inválida → intenta con C:\BCKP auto
   4️⃣  Si múltiples líneas → usa C:\BCKP

📋 VALIDACIÓN CON PERFILES (-Perfil 1-99):
   1️⃣  Si no existe → ERROR (no usa C:\BCKP)
   2️⃣  Si no hay línea perfil → ERROR (no usa C:\BCKP)
   3️⃣  Si ruta perfil inválida → ERROR (no usa C:\BCKP)
   4️⃣  Si múltiples líneas perfil → ERROR
   
   ⚠️  PERFILES REQUIEREN DESTINO VÁLIDO OBLIGATORIO

✅ RUTAS SOPORTADAS:
   C:\Backups                  ✓ Ruta local
   D:\Respaldos                ✓ Otro disco
   \\servidor\compartido       ✓ Red UNC
   Z:\                         ✓ Unidad mapeada (convierte a UNC)
"@ -ForegroundColor Green
Write-Host @"
`n⚠️  SCRIPTS NO FIRMADOS - DESBLOQUEO REQUERIDO:
==============================================
"@ -ForegroundColor Yellow
Write-Host @"
ArturitoBACAP NO está firmado digitalmente.
DEBES desbloquear TODOS los archivos antes de ejecutar.

🔓 COMANDO OBLIGATORIO (como Administrador):
   Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File

Este comando desbloquea todos los .ps1 recursivamente.

✅ VERIFICAR DESBLOQUEO:
   Get-ChildItem -Path . -Recurse -Filter *.ps1 | Get-Item -Stream Zone.Identifier -ErrorAction SilentlyContinue
   
   Sin resultados → correctamente desbloqueados ✓

⚠️  ALTERNATIVA (NO RECOMENDADA):
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
"@ -ForegroundColor Red
Write-Host @"
`nPRIMER USO - GUÍA RÁPIDA:
=========================
"@ -ForegroundColor Cyan
Write-Host @"
0️⃣  Desbloquear scripts (OBLIGATORIO - una vez):
   Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File
   
1️⃣  Configurar email (OBLIGATORIO si no usas -NoEmail):
   .\ArturitoBACAP.ps1 -AjustaEmail
   
2️⃣  (OPCIONAL) Editar Conf/Destino.cfg:
   # Por defecto: C:\BCKP (solo modo estándar)
   # Con perfiles: requiere destino válido
   # Se crea auto con ejemplos si no existe
   
3️⃣  Editar Conf/Origen.cfg con carpetas a respaldar:
   # Se crea auto con ejemplos si no existe
   
4️⃣  (OPCIONAL) Editar Conf/Omitir.cfg con exclusiones:
   # Se crea auto con ejemplos si no existe
   
5️⃣  Ejecutar primer backup de prueba:
   .\ArturitoBACAP.ps1 -Debug -NoEmail
   
6️⃣  Si OK, configurar en Task Scheduler:
   .\ArturitoBACAP.ps1
   
7️⃣  (OPCIONAL) Configurar perfiles:
   # Edita Conf/Origen.cfg, Destino.cfg, Omitir.cfg
   # Agrega líneas: N:[ruta]
   # Ejecuta: .\ArturitoBACAP.ps1 -Perfil N
"@ -ForegroundColor Green
Write-Host @"
`nNOTAS IMPORTANTES:
==================
"@ -ForegroundColor Cyan
Write-Host @"
⚠️  SCRIPTS NO FIRMADOS: Desbloquea recursivamente antes de ejecutar
   Comando: Get-ChildItem -Path . -Recurse -Filter *.ps1 | Unblock-File

⚠️  Sin email y sin config: script se detiene y pide -AjustaEmail
   
⚠️  -AjustaEmail tiene PRIORIDAD sobre otros modificadores
   
⚠️  Modo silencioso (sin -Debug): ideal para Task Scheduler
   
⚠️  Archivos en Conf/ se crean auto con ejemplos si no existen
   
⚠️  PERFILES Y DESTINOS: Perfiles (1-99) REQUIEREN destino válido
   No se permite C:\BCKP como fallback con perfiles
   
⚠️  -NuncaBorra protege destino contra borrados automáticos
   
⚠️  Emails incluyen AMBOS logs: resumen + detalle completo
   Logs >10MB se comprimen auto antes de enviar
   
⚠️  Emails muestran perfil: [P1] en subject, "Perfil: 1" en body
   
⚠️  Archivos temporales en Temp/ se limpian auto al finalizar
   
⚠️  Histórico conversiones UNC en Conf/MapeosUNC.json (auto)
   
⚠️  Exclusiones en Conf/Omitir.cfg soportan perfiles y conversión UNC
   
⚠️  ARQUITECTURA MODULAR: Funciones en Func/, configs en Conf/
   Proyecto totalmente portable - mueve la carpeta a donde quieras
"@ -ForegroundColor Red
Write-Host @"
`n=====================================================
=== Software By Arturito - Soporte Infoquil by WAJ ===
=== ÚSELO BAJO SU RESPONSABILIDAD                 ===
=====================================================
"@ -ForegroundColor White
}