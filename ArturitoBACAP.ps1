<#
    Script de Backup con Robocopy
    - Paralelización de carpetas usando Jobs
    - Configuración optimizada de Robocopy para máximo rendimiento
    - Manejo seguro de credenciales SMTP
    - Opción de apagado automático
    - Modo silencioso para Task Scheduler
    - Envía el log por email al finalizar
    - Verificación opcional de integridad
    - Validación completa de rutas y conversión automática UNC
    - Sistema de email modular mediante dot-sourcing
    - Lectura de destino desde archivo Destino.cfg
    - Modo NuncaBorra para proteger archivos en destino
    - Sistema de perfiles para múltiples configuraciones
#>

param(
    [switch]$NoEmail = $false,
    [switch]$AjustaEmail = $false,
    [int]$Simultaneas = 3,
    [switch]$Rapidito = $false,
    [switch]$Debug = $false,
    [switch]$Apagar = $false,
    [switch]$Verifica = $false,
    [switch]$Ayuda = $false,
    [switch]$CierroTodo = $false,
    [int]$Historico = 0,
    [switch]$NuncaBorra = $false,
    [int]$Perfil = 0
)

# ================================
# 1. Configuración inicial
# ================================

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptDir "Logs"
$configEmailFile = Join-Path $scriptDir "configSMTP.xml"

function Write-Message {
    param($Message, $Color = "White")
    if ($Debug) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# -------------
    . (Join-Path $scriptDir "FuncAyudin.ps1")
    . (Join-Path $scriptDir "FuncBorrarRapido.ps1")
    . (Join-Path $scriptDir "FuncVerificaBACKUP.ps1")
    . (Join-Path $scriptDir "FuncValidacionUNC.ps1")
    . (Join-Path $scriptDir "FuncCierraTodo.ps1")
    . (Join-Path $scriptDir "FuncLimpiaLogs.ps1")
    . (Join-Path $scriptDir "FuncGuardaHistorico.ps1")
    . (Join-Path $scriptDir "FuncEnviaEmail.ps1")
    . (Join-Path $scriptDir "FuncManejaPerfiles.ps1")
# -------------

$validParams = @('NoEmail', 'AjustaEmail', 'Simultaneas', 'Rapidito', 'Debug', 'Verifica', 'Apagar', 'Ayuda', 'CierroTodo', 'Historico', 'NuncaBorra', 'Perfil')

$allArgs = $args + $MyInvocation.BoundParameters.Keys

foreach ($arg in $MyInvocation.Line.Split(' ')) {
    if ($arg.StartsWith('-')) {
        $paramName = $arg.TrimStart('-')
        if ($paramName.Contains(':')) {
            $paramName = $paramName.Split(':')[0]
        }
        if ($paramName -ne '' -and $paramName -notin $validParams) {
            Write-Host "❌ MODIFICADOR INVÁLIDO: -$paramName" -ForegroundColor Red
            Write-Host "💡 Para ver los modificadores válidos, ejecuta: .\ArturitoBACAP.ps1 -Ayuda" -ForegroundColor Yellow
            exit 1
        }
    }
}

foreach ($param in $PSBoundParameters.Keys) {
    if ($param -notin $validParams) {
        Write-Host "❌ MODIFICADOR INVÁLIDO: -$param" -ForegroundColor Red
        Write-Host "💡 Para ver los modificadores válidos, ejecuta: .\ArturitoBACAP.ps1 -Ayuda" -ForegroundColor Yellow
        exit 1
    }
}

if ($Ayuda) {
    Show-Help
    exit 0
}

if ($AjustaEmail) {
    $resultado = Set-EmailConfig -credentialsFile $configEmailFile
    exit $(if ($resultado) { 0 } else { 1 })
}

if ($Simultaneas -lt 1 -or $Simultaneas -gt 32) {
    Write-Host "❌ -Simultaneas debe estar entre 1 y 32" -ForegroundColor Red
    Write-Host "💡 Valor actual: $Simultaneas" -ForegroundColor Yellow
    exit 1
}

if ($Perfil -lt 0 -or $Perfil -gt 99) {
    Write-Host "❌ -Perfil debe estar entre 0 y 99" -ForegroundColor Red
    Write-Host "💡 0 = sin perfil (comportamiento estándar)" -ForegroundColor Yellow
    Write-Host "💡 1-99 = usar perfil específico" -ForegroundColor Yellow
    exit 1
}

# ================================
# 3. Banner y validaciones
# ================================

$carpetasFile = Join-Path $scriptDir "Origen.cfg"
$destinoFile = Join-Path $scriptDir "Destino.cfg"

Write-Host @"

=====================================================
=== 🚀 ArturitoBACAP - Backup Inteligente - 2025 ===
=====================================================

"@ -ForegroundColor White

if (!$NoEmail) {
    $validacionEmail = Test-EmailConfig -credentialsFile $configEmailFile
    if (!$validacionEmail.Valido) {
        Write-Host "❌ $($validacionEmail.Error)" -ForegroundColor Red
        Write-Host "💡 $($validacionEmail.Sugerencia)" -ForegroundColor Yellow
        Write-Host "`nEl backup NO se ejecutará sin configuración de email válida." -ForegroundColor Yellow
        Write-Host "Usa -NoEmail si deseas ejecutar el backup sin enviar reportes.`n" -ForegroundColor Cyan
        exit 1
    }
    Write-Message "✅ Configuración de email válida" "Green"
}

if (!$Debug) {
Write-Host @"
Corriendo, aguarde por favor...
"@ -ForegroundColor Cyan
}

Write-Message "MODO DEBUG ACTIVO" "Magenta"

if ($CierroTodo) {
    $resultadoCierrePrevio = Invoke-CierraTodo
}

# ================================
# 2.5. PROCESAMIENTO DE PERFILES
# ================================
Write-Message "`n🔧 Procesando configuración de archivos..." "Cyan"

$resultadoPerfiles = Invoke-ProcesoPerfiles -ArchivoOrigen $carpetasFile -ArchivoDestino $destinoFile -Perfil $Perfil -ScriptDir $scriptDir

if (!$resultadoPerfiles.Success) {
    Write-Host "`n❌ ERROR AL PROCESAR ARCHIVOS DE CONFIGURACIÓN:" -ForegroundColor Red
    $resultadoPerfiles.Errores | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
    
    if ($Perfil -gt 0) {
        Write-Host "`n💡 Asegúrate de que existan líneas con formato: ${Perfil}:[ruta]" -ForegroundColor Yellow
        Write-Host "   Ejemplo: ${Perfil}:C:\MiCarpeta" -ForegroundColor Cyan
    }
    exit 1
}

if ($Perfil -gt 0) {
    Write-Message "✅ Perfil $Perfil activado - $($resultadoPerfiles.LineasOrigen) carpetas origen, $($resultadoPerfiles.LineasDestino) destino" "Green"
} else {
    Write-Message "✅ Modo estándar (sin perfil) - $($resultadoPerfiles.LineasOrigen) carpetas origen, $($resultadoPerfiles.LineasDestino) destino" "Green"
}

# Usar archivos temporales procesados
$carpetasFile = $resultadoPerfiles.OrigenTmp
$destinoFile = $resultadoPerfiles.DestinoTmp

# ================================
# Cargar destino desde archivo o usar default
# ================================
$destinoDefault = "C:\BCKP"
$destinoConfigValido = $false

if (Test-Path $destinoFile) {
    Write-Message "`n📂 Archivo Destino.cfg encontrado, validando..." "Cyan"
    
    $lineasDestino = @(Get-Content $destinoFile | Where-Object { $_.Trim() -ne "" -and !$_.StartsWith("#") })
    
    if ($lineasDestino.Count -eq 0) {
        if ($Perfil -gt 0) {
            Write-Host "`n❌ ERROR: Perfil $Perfil requiere un destino válido en Destino.cfg" -ForegroundColor Red
            Write-Host "💡 No se puede usar destino por defecto con perfiles" -ForegroundColor Yellow
            Write-Host "💡 Agrega una línea: ${Perfil}:[ruta_destino]" -ForegroundColor Cyan
            exit 1
        }
        Write-Message "⚠️  Destino.cfg está vacío o solo tiene comentarios" "Yellow"
        Write-Message "   Usando destino por defecto: $destinoDefault" "Yellow"
    } elseif ($lineasDestino.Count -gt 1) {
        if ($Perfil -gt 0) {
            Write-Host "`n❌ ERROR: Perfil $Perfil tiene más de una línea de destino válida" -ForegroundColor Red
            Write-Host "💡 Solo se permite una ruta de destino por perfil" -ForegroundColor Yellow
            exit 1
        }
        Write-Message "⚠️  Destino.cfg contiene más de una línea válida" "Yellow"
        Write-Message "   Solo se permite una ruta de destino" "Yellow"
        Write-Message "   Usando destino por defecto: $destinoDefault" "Yellow"
    } else {
        # Convertir explícitamente a string para evitar errores
        $destinoConfig = [string]$lineasDestino[0]
        $destinoConfig = $destinoConfig.Trim()
        Write-Message "📍 Destino configurado: $destinoConfig" "Cyan"
        
        if ([string]::IsNullOrWhiteSpace($destinoConfig)) {
            if ($Perfil -gt 0) {
                Write-Host "`n❌ ERROR: Perfil $Perfil requiere un destino válido en Destino.cfg" -ForegroundColor Red
                Write-Host "💡 La ruta de destino está vacía" -ForegroundColor Yellow
                exit 1
            }
            Write-Message "⚠️  La ruta en Destino.cfg está vacía" "Yellow"
            Write-Message "   Usando destino por defecto: $destinoDefault" "Yellow"
        } else {
            $destinoConfigValido = $true
            $destino = $destinoConfig
            Write-Message "✅ Destino desde Destino.cfg será validado" "Green"
        }
    }
} else {
    if ($Perfil -gt 0) {
        Write-Host "`n❌ ERROR: Perfil $Perfil requiere archivo Destino.cfg con destino válido" -ForegroundColor Red
        Write-Host "💡 No se puede usar destino por defecto con perfiles" -ForegroundColor Yellow
        Write-Host "💡 Crea Destino.cfg y agrega: ${Perfil}:[ruta_destino]" -ForegroundColor Cyan
        exit 1
    }
    Write-Message "`n📂 Archivo Destino.cfg no encontrado" "Yellow"
    Write-Message "   Usando destino por defecto: $destinoDefault" "Cyan"
    
    $ejemploDestino = @"
# Configuración de carpeta de destino para backup
# Líneas que comienzan con # son comentarios y se ignoran
# IMPORTANTE: Solo se permite UNA línea de destino válida
# Ejemplo:
#C:\MisBackups
#D:\Respaldos
#\\servidor\compartido\backups
"@
    
    Set-Content -Path $destinoFile -Value $ejemploDestino -Encoding UTF8
    Write-Message "📄 Se ha creado el archivo Destino.cfg con ejemplos" "Yellow"
}

if (!$destinoConfigValido) {
    if ($Perfil -gt 0) {
        Write-Host "`n❌ ERROR: No se puede continuar sin destino válido para Perfil $Perfil" -ForegroundColor Red
        exit 1
    }
    $destino = $destinoDefault
}

if (Test-Path $carpetasFile) {
    $carpetasOrigen = Get-Content $carpetasFile | Where-Object { $_.Trim() -ne "" -and !$_.StartsWith("#") }
    Write-Message "`n📂 Carpetas cargadas desde: Origen.cfg ($($carpetasOrigen.Count) carpetas)" "Green"
} else {
    $errorMsg = "❌ No se ha encontrado el archivo: Origen.cfg"
    Write-Message $errorMsg "Red"
    
    $ejemploContent = @"
# Configuración de carpetas de origen para backup
# Líneas que comienzan con # son comentarios y se ignoran
# Ejemplo de carpetas:
#C:\Users\UsuarioEjemplo\Documents\
#C:\Users\UsuarioEjemplo\Desktop\MisCarpetas
#Z:\Carpeta de Red
"@
    
    Set-Content -Path $carpetasFile -Value $ejemploContent -Encoding UTF8
    Write-Message "📄 Se ha creado el archivo Origen.cfg con ejemplos" "Yellow"
    Write-Message "   Edita el archivo descomentando y modificando las carpetas que deseas respaldar" "Yellow"
    Write-Message "   y ejecuta el script nuevamente" "Yellow"
    
    if (!$Debug) {
        if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path (Join-Path $logDir "Error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log") -Value "ERROR: $errorMsg"
    }
    exit 1
}

$exclusiones = @()

# ================================
# 4. Configuración de paths de log
# ================================

if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    Write-Message "📁 Creado directorio: $logDir" "Green"
}

# ================================
# 6. VALIDACIÓN COMPLETA DE RUTAS
# ================================

$validacionCompleta = Invoke-PathValidation -CarpetasOrigen $carpetasOrigen -Destino $destino

if (!$validacionCompleta.DestinoValido) {
    if ($Perfil -gt 0) {
        # Con perfil NO se permite fallback a destino por defecto
        $errorMsg = "❌ DESTINO INVÁLIDO PARA PERFIL ${Perfil}: $($validacionCompleta.ErrorDestino)"
        Write-Message $errorMsg "Red"
        Write-Host "💡 Los perfiles requieren destinos válidos específicos" -ForegroundColor Yellow
        Write-Host "💡 No se puede usar destino por defecto (C:\BCKP) con perfiles" -ForegroundColor Yellow
        if (!$Debug) {
            Add-Content -Path (Join-Path $logDir "Error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log") -Value "ERROR: $errorMsg"
        }
        exit 1
    }
    
    # Sin perfil, intentar con destino por defecto
    if ($destinoConfigValido -and $destino -ne $destinoDefault) {
        Write-Message "`n⚠️  Destino configurado '$destino' no es válido: $($validacionCompleta.ErrorDestino)" "Yellow"
        Write-Message "🔄 Intentando con destino por defecto: $destinoDefault" "Cyan"
        
        $destino = $destinoDefault
        $validacionCompleta = Invoke-PathValidation -CarpetasOrigen $carpetasOrigen -Destino $destino
        
        if (!$validacionCompleta.DestinoValido) {
            $errorMsg = "❌ DESTINO POR DEFECTO TAMBIÉN INVÁLIDO: $($validacionCompleta.ErrorDestino)"
            Write-Message $errorMsg "Red"
            if (!$Debug) {
                Add-Content -Path (Join-Path $logDir "Error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log") -Value "ERROR: $errorMsg"
            }
            exit 1
        } else {
            Write-Message "✅ Usando destino por defecto exitosamente" "Green"
        }
    } else {
        $errorMsg = "❌ DESTINO INVÁLIDO: $($validacionCompleta.ErrorDestino)"
        Write-Message $errorMsg "Red"
        if (!$Debug) {
            Add-Content -Path (Join-Path $logDir "Error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log") -Value "ERROR: $errorMsg"
        }
        exit 1
    }
}

if ($validacionCompleta.CarpetasValidas.Count -eq 0) {
    $errorMsg = "❌ NO HAY CARPETAS VÁLIDAS PARA BACKUP"
    Write-Message $errorMsg "Red"
    Write-Message "Errores encontrados:" "Yellow"
    $validacionCompleta.ErroresOrigen | ForEach-Object { Write-Message "   • $_" "Red" }
    
    if (!$Debug) {
        $errorCompleto = "$errorMsg`n$($validacionCompleta.ErroresOrigen -join "`n")"
        Add-Content -Path (Join-Path $logDir "Error_$(Get-Date -Format 'yyyyMMdd_HHmmss').log") -Value "ERROR: $errorCompleto"
    }
    exit 1
}

$carpetasValidas = $validacionCompleta.CarpetasValidas
$DestinoFinal = $validacionCompleta.DestinoFinal

Write-Message "`n✅ VALIDACIÓN COMPLETA - Continuando con backup de $($carpetasValidas.Count) carpetas válidas" "Green"
if ($validacionCompleta.DestinoConvertido) {
    Write-Message "   🌐 Usando destino convertido: $DestinoFinal" "Cyan"
}

if ($Historico -gt 0) {
    Write-Message "Gestionando histórico de backups..." "Yellow"
    GuardaHistorico
}

# ================================
# 8. Configuración optimizada de Robocopy
# ================================
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$numCores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
$threadsOptimos = [Math]::Min(16, [Math]::Max(1, $numCores - 2))

Write-Message "🖥️  CPU: $numCores cores lógicos detectados" "Cyan"
Write-Message "⚡ ArturitoBacap usará $threadsOptimos threads" "Green"

$opcionesBase = @(
    $(if ($NuncaBorra) { "/E" } else { "/MIR" }),
    "/MT:$threadsOptimos",
    "/R:3",
    "/W:2",
    "/NFL", "/NDL",
    "/NP",
    "/J",
    "/IT"
)

if ($Rapidito) {
    $opcionesBase += @(
        "/DCOPY:T",
        "/COPY:DT",
        "/COMPRESS"
    )
} else {
    $opcionesBase += @("/COPY:DAT")
}

if ($exclusiones.Count -gt 0) {
    $excluir = ($exclusiones | ForEach-Object { "/XF `"$_`"" }) -join " "
    $opcionesBase += $excluir.Split(' ')
}

# ================================
# 10. Función de backup paralelizado
# ================================
function Start-ParallelBackup {
    $jobs = @()
    $inicioTotal = Get-Date
    
    Write-Message "🚀 Iniciando backup paralelizado con $Simultaneas jobs simultáneos..." "Cyan"
    
    foreach ($origen in $carpetasValidas) {
        $nombreCarpeta = Split-Path $origen -Leaf
        $destinoJob = Join-Path $DestinoFinal $nombreCarpeta
        $logIndividual = Join-Path $logDir "Backup_$($nombreCarpeta)_$timestamp.log"
        
        while ((Get-Job -State Running).Count -ge $Simultaneas) {
            Start-Sleep -Milliseconds 100
        }
        
        Write-Message "📦 Iniciando: $nombreCarpeta" "Green"
        
        $job = Start-Job -ArgumentList $origen, $destinoJob, $opcionesBase, $logIndividual -ScriptBlock {
            param($Origen, $DestinoJob, $Opciones, $LogPath)
            
            $opcionesStr = ($Opciones + @("/LOG:`"$LogPath`"")) -join " "
            $comando = "robocopy `"$Origen`" `"$DestinoJob`" $opcionesStr"
            
            try {
                $resultado = cmd /c $comando
                return @{
                    ExitCode = $LASTEXITCODE
                    Output = $resultado
                    Origen = $Origen
                    Error = $null
                }
            } catch {
                return @{
                    ExitCode = -1
                    Output = $null
                    Origen = $Origen
                    Error = $_.Exception.Message
                }
            }
        }
        
        $jobs += @{
            Job = $job
            Carpeta = $nombreCarpeta
            Origen = $origen
            LogPath = $logIndividual
            Procesado = $false
        }
    }
    
    $completados = 0
    $total = $jobs.Count
    $errores = @()
    
    while ($completados -lt $total) {
        foreach ($jobInfo in $jobs) {
            if ($jobInfo.Job.State -eq 'Completed' -and !$jobInfo.Procesado) {
                $jobInfo.Procesado = $true
                $completados++
                $resultado = Receive-Job $jobInfo.Job
                Remove-Job $jobInfo.Job
                
                $status = switch ($resultado.ExitCode) {
                    0 { @{Txt="Sin cambios"; Color="Gray"} }
                    1 { @{Txt="OK - Copiado"; Color="Green"} }
                    2 { @{Txt="OK - Extras"; Color="Yellow"} }
                    3 { @{Txt="OK - Copiado+Extras"; Color="Green"} }
                    {$_ -ge 8} { @{Txt="ERROR"; Color="Red"}; $errores += $jobInfo.Carpeta }
                    default { @{Txt="Código $($resultado.ExitCode)"; Color="Yellow"} }
                }
                
                Write-Message "✓ [$completados/$total] $($jobInfo.Carpeta): $($status.Txt)" $status.Color
                
                if ($resultado.Error) {
                    Write-Message "   Error: $($resultado.Error)" "Red"
                    $errores += $jobInfo.Carpeta
                }
            }
        }
        Start-Sleep -Milliseconds 200
    }
    
    $finTotal = Get-Date
    $duracionTotal = $finTotal - $inicioTotal
    
    return @{
        Inicio = $inicioTotal
        Fin = $finTotal
        Duracion = $duracionTotal
        Errores = $errores
        Jobs = $jobs
    }
}

# ================================
# 11. Limpiar carpetas obsoletas
# ================================
function Remove-ObsoleteFolders {
    Write-Message "🧹 Verificando carpetas a borrar en destino..." "Yellow"
    
    $carpetasEsperadas = $carpetasValidas | ForEach-Object { Split-Path $_ -Leaf }
    
    $carpetasDestino = @()
    if (Test-Path $DestinoFinal) {
        $carpetasDestino = Get-ChildItem -Path $DestinoFinal -Directory | Select-Object -ExpandProperty Name
    }
    
    $carpetasObsoletas = $carpetasDestino | Where-Object { $_ -notin $carpetasEsperadas }
    
    $logLimpieza = Join-Path $logDir "Limpieza_$timestamp.log"
    $carpetasEliminadas = @()
    
    if ($carpetasObsoletas.Count -gt 0) {
        Write-Message "⚠️  Carpetas a borrar en destino: $($carpetasObsoletas -join ', ')" "Yellow"
        
        foreach ($carpetaObsoleta in $carpetasObsoletas) {
            $rutaCompleta = Join-Path $DestinoFinal $carpetaObsoleta
            try {
                Write-Message "🗑️  Eliminando: $carpetaObsoleta" "Red"
                Remove-Item -Path $rutaCompleta -Recurse -Force
                $carpetasEliminadas += $carpetaObsoleta
                Add-Content -Path $logLimpieza -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): ELIMINADA - $carpetaObsoleta"
            } catch {
                Write-Message "❌ Error eliminando $carpetaObsoleta`: $($_.Exception.Message)" "Red"
                Add-Content -Path $logLimpieza -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): ERROR eliminando $carpetaObsoleta - $($_.Exception.Message)"
            }
        }
    } else {
        Write-Message "✅ No hay carpetas para borrar en destino" "Green"
        Add-Content -Path $logLimpieza -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): No hay carpetas a borrar"
    }
    
    return @{
        CarpetasObsoletas = $carpetasObsoletas
        CarpetasEliminadas = $carpetasEliminadas
        LogPath = $logLimpieza
    }
}

# ================================
# 12. Ejecutar backup
# ================================
Write-Message "`n⚡ MODO $(if($Rapidito){'ULTRA-RÁPIDO'}else{'OPTIMIZADO'}) ACTIVO" "Magenta"

if ($NuncaBorra) {
    Write-Message "🛡️  MODO NUNCA-BORRA ACTIVO: No se eliminarán carpetas ni archivos obsoletos" "Yellow"
}

if ($Perfil -gt 0) {
    Write-Message "🎯 PERFIL $Perfil ACTIVO" "Cyan"
}

Write-Message "🖥️  CPU: $numCores cores lógicos detectados" "Cyan"
Write-Message "⚡ ArturitoBacap usará $threadsOptimos threads" "Green"

$resultadoLimpieza = if ($NuncaBorra) {
    Write-Message "🛡️  Omitiendo limpieza de carpetas obsoletas (Modo NuncaBorra)" "Yellow"
    @{
        CarpetasObsoletas = @()
        CarpetasEliminadas = @()
        LogPath = $null
    }
} else {
    Remove-ObsoleteFolders
}
$resultadoBackup = Start-ParallelBackup

# ================================
# 13. Verificación opcional
# ================================
$resultadoVerificacion = $null
if ($Verifica) {
    Write-Message "`n🔍 VERIFICACIÓN DE INTEGRIDAD DEL BACKUP ACTIVA" "Magenta"
    if ($NuncaBorra) {
        Write-Message "🛡️  Verificación en modo NuncaBorra (solo verifica que origen esté en destino)" "Yellow"
    }
    $resultadoVerificacion = Test-BackupIntegrity -CarpetasValidas $carpetasValidas -Destino $DestinoFinal -LogDir $logDir -Timestamp $timestamp
    
    if ($resultadoVerificacion.EsExitosa) {
        Write-Message "`r`n  ✅ VERIFICACIÓN EXITOSA en $($resultadoVerificacion.Duracion.ToString('hh\:mm\:ss\.fff'))" "Green"
    } else {
        Write-Message "`r`n  ⚠️ VERIFICACIÓN CON ERRORES en $($resultadoVerificacion.Duracion.ToString('hh\:mm\:ss\.fff'))" "Red"
        Write-Message "    Errores en: $($resultadoVerificacion.Errores -join ', ')" "Red"
    }
}
# ================================
# 14. Consolidar logs
# ================================
$logResumen = Join-Path $logDir "BCKP_Resumen_$timestamp.log"
$logDetalle = Join-Path $logDir "BCKP_Detalle_$timestamp.log"

$resumenCompleto = @"
============================================
============== ARTURITOBACAP ===============
=== BACKUP RESUMEN - $($resultadoBackup.Inicio.ToString("dd/MM/yyyy HH:mm:ss")) ===
============================================

Perfil: $(if($Perfil -gt 0){"$Perfil"}else{"Estándar (sin perfil)"})
Modo: $(if($Rapidito){'Ultra-rápido'}else{'Optimizado'})
$(if($NuncaBorra){'🛡️  Modo NuncaBorra: ACTIVO (sin borrado de obsoletos)'})
Jobs simultáneos: $Simultaneas
CPU: $numCores cores lógicos detectados
ArturitoBacap usará: $threadsOptimos threads
Duración total backup: $($resultadoBackup.Duracion.ToString('hh\:mm\:ss'))
$(if($Verifica){"Duración verificación: $($resultadoVerificacion.Duracion.ToString('hh\:mm\:ss'))"})

=== CARPETAS DE ORIGEN ===
$($carpetasOrigen | ForEach-Object {"   $_"} | Out-String)

=== CARPETA DESTINO ===
   $DestinoFinal

=== VALIDACIÓN DE RUTAS ===
Carpetas procesadas: $($carpetasValidas.Count)
Carpetas inválidas: $($validacionCompleta.CarpetasInvalidas.Count)
Conversiones UNC: $($validacionCompleta.ConversionesUNC.Count)
Destino creado: $(if($validacionCompleta.DestinoCreado){'SÍ'}else{'NO'})

=== RESULTADOS BACKUP ===
Carpetas eliminadas: $(if($NuncaBorra){'N/A (Modo NuncaBorra)'}else{$resultadoLimpieza.CarpetasEliminadas.Count})
Errores backup: $($resultadoBackup.Errores.Count)
$(if($Verifica){"Errores verificación: $($resultadoVerificacion.Errores.Count)"})
$(if($Verifica){"Verificación: $(if($resultadoVerificacion.EsExitosa){'EXITOSA'}else{'CON ERRORES'})"})
Apagar equipo: $(if($Apagar){'SÍ'}else{'NO'})

$(if($validacionCompleta.ConversionesUNC.Count -gt 0){"🔄 CONVERSIONES UNC REALIZADAS:"})
$(if($validacionCompleta.ConversionesUNC.Count -gt 0){$($validacionCompleta.ConversionesUNC | ForEach-Object {"   $($_.RutaOriginal) → $($_.RutaConvertida) ($($_.Metodo))"}) -join "`n"})

$(if($validacionCompleta.CarpetasInvalidas.Count -gt 0){"❌ CARPETAS INVÁLIDAS:"})
$(if($validacionCompleta.CarpetasInvalidas.Count -gt 0){$($validacionCompleta.ErroresOrigen | ForEach-Object {"   $_"}) -join "`n"})

$(if($resultadoLimpieza.CarpetasEliminadas.Count -gt 0){"🗑️ CARPETAS ELIMINADAS: $($resultadoLimpieza.CarpetasEliminadas -join ', ')"})
$(if($NuncaBorra){"🛡️  MODO NUNCABORRA: No se eliminaron carpetas ni archivos obsoletos"})

=== FIN BACKUP: $($resultadoBackup.Fin.ToString("dd/MM/yyyy HH:mm:ss")) ===

=== Software By Arturito USELO BAJO SU RESPONSABILIDAD
=== Soporte Infoquil by WAJ
"@

Set-Content -Path $logResumen -Value $resumenCompleto

$detalleCompleto = @"
==================================================
================= ARTURITOBACAP ==================
=== LOG DETALLADO - BACKUP $($resultadoBackup.Inicio.ToString("dd/MM/yyyy HH:mm:ss")) ===
==================================================

Timestamp: $timestamp
Perfil: $(if($Perfil -gt 0){"$Perfil"}else{"Estándar (sin perfil)"})
Modo: $(if($Rapidito){'Ultra-rápido'}else{'Optimizado'})
$(if($NuncaBorra){'🛡️  Modo NuncaBorra: ACTIVO'})
Jobs simultáneos: $Simultaneas
CPU: $numCores cores lógicos detectados
ArturitoBacap usará: $threadsOptimos threads

=== CARPETAS DE ORIGEN ===
$($carpetasOrigen | ForEach-Object {"   $_"} | Out-String)

=== CARPETA DESTINO ===
   $DestinoFinal

=== VALIDACIÓN DE RUTAS ===
Carpetas originales procesadas: $($carpetasOrigen.Count)
Carpetas válidas finales: $($validacionCompleta.CarpetasValidas.Count)
Conversiones UNC realizadas: $($validacionCompleta.ConversionesUNC.Count)

$(if($validacionCompleta.ConversionesUNC.Count -gt 0){"CONVERSIONES UNC DETALLADAS:"})
$(if($validacionCompleta.ConversionesUNC.Count -gt 0){$($validacionCompleta.ConversionesUNC | ForEach-Object {"  Origen: $($_.RutaOriginal)`n  UNC: $($_.RutaConvertida)`n  Método: $($_.Metodo)`n  Tipo: $(if($_.EsRed){'Red'}else{'Local'})`n"}) -join "`n"})

$(if($validacionCompleta.ErroresOrigen.Count -gt 0){"ERRORES DE VALIDACIÓN:"})
$(if($validacionCompleta.ErroresOrigen.Count -gt 0){$($validacionCompleta.ErroresOrigen | ForEach-Object {"  $_"}) -join "`n"})

"@

if (!$NuncaBorra -and (Test-Path $resultadoLimpieza.LogPath)) {
    $detalleCompleto += "`n=== LOG DE BORRADO DE CARPETAS EN DESTINO ===`n"
    $detalleCompleto += Get-Content $resultadoLimpieza.LogPath -Raw
    $detalleCompleto += "`n"
} elseif ($NuncaBorra) {
    $detalleCompleto += "`n=== MODO NUNCABORRA ===`n"
    $detalleCompleto += "No se realizó limpieza de carpetas obsoletas (modo protección activado)`n"
}

foreach ($jobInfo in $resultadoBackup.Jobs) {
    if (Test-Path $jobInfo.LogPath) {
        $detalleCompleto += "`n=== LOG BACKUP: $($jobInfo.Carpeta) ===`n"
        $logContent = Get-Content $jobInfo.LogPath -Raw
        $logContent = $logContent -replace "-------------------------------------------------------------------------------\s+ROBOCOPY\s+::\s+Herramienta para copia eficaz de archivos\s+-------------------------------------------------------------------------------", "================================================================================================"
        $logContent = $logContent -replace "Director.", " Carpetas"
        $logContent = $logContent -replace "Extras", "No en Origen (borradas en destino)"
        $detalleCompleto += $logContent
        $detalleCompleto += "`n"
        
        Remove-Item $jobInfo.LogPath -Force -ErrorAction SilentlyContinue
    }
}

if ($Verifica) {
    foreach ($origen in $carpetasValidas) {
        $nombreCarpeta = Split-Path $origen -Leaf
        $logVerificacion = Join-Path $logDir "Verificacion_$($nombreCarpeta)_$timestamp.log"
        if (Test-Path $logVerificacion) {
            $detalleCompleto += "`n=== LOG VERIFICACIÓN: $nombreCarpeta ===`n"
            $logContent = Get-Content $logVerificacion -Raw
            $logContent = $logContent -replace "-------------------------------------------------------------------------------\s+ROBOCOPY\s+::\s+Herramienta para copia eficaz de archivos\s+-------------------------------------------------------------------------------", "================================================================================================"
            $logContent = $logContent -replace "Director.", " Carpetas"
            $logContent = $logContent -replace "Extras", "No en Origen"
            $detalleCompleto += $logContent
            $detalleCompleto += "`n"
            
            Remove-Item $logVerificacion -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($CierroTodo) {
    $detalleCompleto += $resultadoCierrePrevio + "`n"
}

$detalleCompleto += "`n=== FIN LOG DETALLADO: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss") ===

=== Software By Arturito USELO BAJO SU RESPONSABILIDAD
=== Soporte Infoquil by WAJ"
Set-Content -Path $logDetalle -Value $detalleCompleto

if (!$NuncaBorra -and (Test-Path $resultadoLimpieza.LogPath)) {
    Remove-Item $resultadoLimpieza.LogPath -Force -ErrorAction SilentlyContinue
}

# ================================
# 15. Reporte final optimizado
# ================================
$tieneErrores = $resultadoBackup.Errores.Count -gt 0 -or ($Verifica -and !$resultadoVerificacion.EsExitosa)
$statusIcon = if ($tieneErrores) { "⚠️" } else { "🚀" }
$statusColor = if ($tieneErrores) { "Red" } else { "Green" }

$duracionTotal = if ($Verifica) { 
    $resultadoBackup.Duracion.Add($resultadoVerificacion.Duracion)
} else { 
    $resultadoBackup.Duracion 
}

if ($Debug) {
    Write-Host ""
    Write-Host $statusIcon -ForegroundColor $statusColor -NoNewline
    Write-Host " PROCESO COMPLETADO en $($duracionTotal.ToString('hh\:mm\:ss'))" -ForegroundColor Magenta
}

Write-Message "  📊 Velocidad promedio backup: $(($carpetasValidas.Count / $resultadoBackup.Duracion.TotalMinutes).ToString('F1')) carpetas/min" "Cyan"

if ($Perfil -gt 0) {
    Write-Message "  🎯 Perfil usado: $Perfil" "Cyan"
}

if ($validacionCompleta.ConversionesUNC.Count -gt 0) {
    Write-Message "  🔄 Conversiones UNC realizadas: $($validacionCompleta.ConversionesUNC.Count)" "Cyan"
}

if (!$NuncaBorra -and $resultadoLimpieza.CarpetasEliminadas.Count -gt 0) {
    Write-Message "  🗑️  Carpetas eliminadas: $($resultadoLimpieza.CarpetasEliminadas -join ', ')" "Yellow"
} elseif ($NuncaBorra) {
    Write-Message "  🛡️  Modo NuncaBorra: Sin eliminación de obsoletos" "Cyan"
}

if ($resultadoBackup.Errores.Count -gt 0) {
    Write-Message "  ⚠️  Errores backup: $($resultadoBackup.Errores -join ', ')" "Red"
}

if ($Verifica -and !$resultadoVerificacion.EsExitosa) {
    Write-Message "  ⚠️  Errores verificación: $($resultadoVerificacion.Errores -join ', ')" "Red"
}

# ================================
# 16. Email optimizado
# ================================
if (!$NoEmail) {
    Write-Message "`n📧 Enviando reporte..." "Magenta"
    
    $statusText = if ($tieneErrores) { "CON ERRORES" } else { "EXITOSO" }
    $perfilText = if ($Perfil -gt 0) { " [P$Perfil]" } else { "" }
    $subject = "Backup $statusText$perfilText ⚡ $($duracionTotal.ToString('hh\:mm\:ss')) - $(Get-Date -Format 'dd/MM HH:mm')"
    
    $bodyOptimizado = @"
🚀 BACKUP $statusText

🎯 Perfil: $(if($Perfil -gt 0){"$Perfil"}else{"Estándar"})
⏱️  Duración total: $($duracionTotal.ToString('hh\:mm\:ss'))
    📦 Backup: $($resultadoBackup.Duracion.ToString('hh\:mm\:ss'))
$(if($Verifica){"    🔍 Verificación: $($resultadoVerificacion.Duracion.ToString('hh\:mm\:ss'))"})
📂 Carpetas válidas: $($carpetasValidas.Count)
🔄 Conversiones UNC: $($validacionCompleta.ConversionesUNC.Count)
🗑️ Eliminadas: $(if($NuncaBorra){'N/A (Modo NuncaBorra)'}else{$resultadoLimpieza.CarpetasEliminadas.Count})
🔥 Modo: $(if($Rapidito){'Ultra-rápido'}else{'Optimizado'}) ($Simultaneas jobs)
$(if($NuncaBorra){'🛡️  Modo NuncaBorra: ACTIVO'})
🖥️  CPU: $threadsOptimos threads de $numCores cores
📊 Velocidad backup: $(($carpetasValidas.Count / $resultadoBackup.Duracion.TotalMinutes).ToString('F1')) carpetas/min
$(if($Verifica){"🔍 Verificación: $(if($resultadoVerificacion.EsExitosa){'✅ EXITOSA'}else{'⚠️ CON ERRORES'})"})
$(if($Apagar){'🔌 Equipo se apagará automáticamente'}else{'💻 Equipo permanece encendido'})

$(if ($validacionCompleta.ConversionesUNC.Count -gt 0) { "🔄 CONVERSIONES UNC: $($validacionCompleta.ConversionesUNC.Count) realizadas" })
$(if ($validacionCompleta.CarpetasInvalidas.Count -gt 0) { "❌ CARPETAS INVÁLIDAS: $($validacionCompleta.CarpetasInvalidas.Count)" })
$(if (!$NuncaBorra -and $resultadoLimpieza.CarpetasEliminadas.Count -gt 0) { "🗑️ ELIMINADAS: $($resultadoLimpieza.CarpetasEliminadas -join ', ')" })
$(if ($NuncaBorra) { "🛡️  MODO NUNCABORRA: Sin eliminación de obsoletos" })
$(if ($resultadoBackup.Errores.Count -gt 0) { "⚠️ ERRORES BACKUP: $($resultadoBackup.Errores -join ', ')" })
$(if ($Verifica -and !$resultadoVerificacion.EsExitosa) { "⚠️ ERRORES VERIFICACIÓN: $($resultadoVerificacion.Errores -join ', ')" })
$(if (!$tieneErrores -and $resultadoLimpieza.CarpetasEliminadas.Count -eq 0 -and $validacionCompleta.CarpetasInvalidas.Count -eq 0) { "✅ TODO EXITOSO" } elseif (!$tieneErrores) { "✅ BACKUP EXITOSO" })

Log completo adjunto.
"@

    $emailEnviado = Send-BackupEmail `
        -ConfigFile $configEmailFile `
        -Subject $subject `
        -Body $bodyOptimizado `
        -Attachment @($logResumen, $logDetalle)
    
    if ($emailEnviado) {
        Write-Message "✅ Email enviado exitosamente" "Green"
    } else {
        Write-Message "❌ Error al enviar email (ver detalles arriba)" "Red"
        Add-Content -Path $logResumen -Value "`n=== ERROR AL ENVIAR EMAIL ==="
    }
    
} else {
    Write-Message "`n🧪 MODO SIN EMAIL" "Magenta"
    Write-Message "`n📄 Log resumen: $logResumen" "Magenta"
    Write-Message "📄 Log detalle: $logDetalle" "Magenta"
}

Invoke-LimpiaLogs -logDir $logDir

# Limpiar archivos temporales de perfiles
Remove-ArchivosTemporales -ScriptDir $scriptDir

# ================================
# 17. APAGAR EQUIPO
# ================================
if ($Apagar) {
    Write-Message "`n🔌 Preparando apagado del equipo..." "Yellow"
    Add-Content -Path $logResumen -Value "`n=== APAGADO PROGRAMADO ==="
    
    if (!$Debug) {
        Write-Message "🔌 Apagando equipo..." "Red"
        Add-Content -Path $logResumen -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): Apagado automático iniciado"
        shutdown /s /t 10 /c "Backup completado. Apagando equipo..."
    } else {
        Write-Host "`n⚠️  EL EQUIPO SE APAGARÁ EN 30 SEGUNDOS" -ForegroundColor Red -BackgroundColor Yellow
        Write-Host "Presiona CTRL+C para cancelar el apagado" -ForegroundColor Yellow
        
        shutdown /s /t 30 /c "Backup completado. Apagando en 30 segundos..."
        
        try {
            for ($i = 25; $i -gt 0; $i--) {
                Write-Host "⏱️  Apagando en $i segundos... (CTRL+C para cancelar)" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
            Write-Host "🔌 Apagando equipo..." -ForegroundColor Red
            Add-Content -Path $logResumen -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): Apagado automático confirmado"
        } catch {
            shutdown /a
            Write-Host "`n❌ Apagado cancelado por el usuario" -ForegroundColor Green
            Add-Content -Path $logResumen -Value "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'): Apagado cancelado por usuario"
        }
    }
} else {
    if ($Debug) {
        Write-Host "`nPresiona Enter para continuar..."
        $null = Read-Host
    }
}