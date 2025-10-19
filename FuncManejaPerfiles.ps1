# FuncManejaPerfiles.ps1
# Función para procesar archivos de configuración con soporte de perfiles
# Genera archivos temporales filtrados según el perfil seleccionado
# Uso: Se carga mediante dot-sourcing en ArturitoBACAP.ps1

function Invoke-ProcesoPerfiles {
    param(
        [string]$ArchivoOrigen,
        [string]$ArchivoDestino,
        [int]$Perfil = 0,
        [string]$ScriptDir
    )
    
    $tmpDir = Join-Path $ScriptDir "Temp"
    if (!(Test-Path $tmpDir)) {
        New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $origenTmp = Join-Path $tmpDir "Origen_tmp_$timestamp.cfg"
    $destinoTmp = Join-Path $tmpDir "Destino_tmp_$timestamp.cfg"
    
    function ProcessFile {
        param($FilePath, $TmpPath, $AllowMultiple = $true)
        
        if (!(Test-Path $FilePath)) {
            return @{
                Success = $false
                Error = "Archivo no encontrado: $FilePath"
                TmpPath = $null
            }
        }
        
        $lineas = Get-Content $FilePath -Encoding UTF8
        $lineasProcesadas = @()
        
        foreach ($linea in $lineas) {
            $lineaTrim = $linea.Trim()
            
            # Saltar líneas vacías y comentarios puros
            if ([string]::IsNullOrWhiteSpace($lineaTrim) -or $lineaTrim.StartsWith("#")) {
                continue
            }
            
            # Detectar si la línea tiene formato de perfil (número seguido de dos puntos)
            if ($lineaTrim -match '^(\d+):(.+)$') {
                $numeroPerfil = [int]$matches[1]
                $rutaSinPrefijo = $matches[2].Trim()
                
                # Si estamos usando perfil y coincide el número
                if ($Perfil -gt 0 -and $numeroPerfil -eq $Perfil) {
                    $lineasProcesadas += $rutaSinPrefijo
                }
                # Si no estamos usando perfil, ignorar esta línea (no es error)
                continue
            }
            
            # Línea sin prefijo de perfil
            if ($Perfil -eq 0) {
                # Solo incluir si no estamos en modo perfil
                $lineasProcesadas += $lineaTrim
            }
        }
        
        # Validación adicional para archivo de destino (solo una línea)
        if (!$AllowMultiple -and $lineasProcesadas.Count -gt 1) {
            return @{
                Success = $false
                Error = "El archivo de destino contiene más de una ruta válida para el perfil seleccionado"
                TmpPath = $null
            }
        }
        
        # Escribir archivo temporal
        if ($lineasProcesadas.Count -gt 0) {
            Set-Content -Path $TmpPath -Value $lineasProcesadas -Encoding UTF8
            return @{
                Success = $true
                LineasProcesadas = $lineasProcesadas.Count
                TmpPath = $TmpPath
            }
        } else {
            return @{
                Success = $false
                Error = "No se encontraron rutas válidas$(if($Perfil -gt 0){" para el perfil $Perfil"})"
                TmpPath = $null
            }
        }
    }
    
    # Procesar archivo de origen (permite múltiples líneas)
    $resultadoOrigen = ProcessFile -FilePath $ArchivoOrigen -TmpPath $origenTmp -AllowMultiple $true
    
    # Procesar archivo de destino (solo una línea)
    $resultadoDestino = ProcessFile -FilePath $ArchivoDestino -TmpPath $destinoTmp -AllowMultiple $false
    
    # Verificar errores
    $errores = @()
    if (!$resultadoOrigen.Success) {
        $errores += "Origen: $($resultadoOrigen.Error)"
    }
    if (!$resultadoDestino.Success) {
        $errores += "Destino: $($resultadoDestino.Error)"
    }
    
    if ($errores.Count -gt 0) {
        # Limpiar archivos temporales en caso de error
        if (Test-Path $origenTmp) { Remove-Item $origenTmp -Force -ErrorAction SilentlyContinue }
        if (Test-Path $destinoTmp) { Remove-Item $destinoTmp -Force -ErrorAction SilentlyContinue }
        
        return @{
            Success = $false
            Errores = $errores
            OrigenTmp = $null
            DestinoTmp = $null
        }
    }
    
    return @{
        Success = $true
        OrigenTmp = $resultadoOrigen.TmpPath
        DestinoTmp = $resultadoDestino.TmpPath
        LineasOrigen = $resultadoOrigen.LineasProcesadas
        LineasDestino = $resultadoDestino.LineasProcesadas
        Perfil = $Perfil
    }
}

function Remove-ArchivosTemporales {
    param([string]$ScriptDir)
    
    $tmpDir = Join-Path $ScriptDir "Temp"
    if (Test-Path $tmpDir) {
        Get-ChildItem -Path $tmpDir -Filter "*.cfg" | Where-Object {
            $_.Name -match '^(Origen|Destino)_tmp_\d{8}_\d{6}\.cfg$'
        } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}