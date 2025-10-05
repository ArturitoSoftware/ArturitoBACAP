# ================================
# Función de verificación por resincronización
# ================================

function Test-BackupIntegrity {
    param(
        $CarpetasValidas,
        $Destino,
        $LogDir,
        $Timestamp
    )
    
    Write-Message "  🔍 Comenzando la verificación..." "Cyan"
    $inicioVerificacion = Get-Date
    $erroresVerificacion = @()
    
    # Opciones para verificación rápida (solo comparar, no copiar)
    $opcionesVerificacion = @(
        "/MIR",              # Espejo para comparar estructura
        "/L",                # Solo listar diferencias, no copiar
        "/MT:8",             # Menos hilos para verificación
        "/R:1", "/W:1",      # Reintentos mínimos
        "/NFL", "/NDL", "/NP", # Sin outputs detallados
        "/COPY:DT"           # Solo comparar data y timestamps
    )
    
    foreach ($origen in $CarpetasValidas) {
        $nombreCarpeta = Split-Path $origen -Leaf
        $destinoFinal = Join-Path $Destino $nombreCarpeta
        $logVerificacion = Join-Path $LogDir "Verificacion_$($nombreCarpeta)_$Timestamp.log"
        
        Write-Message "    🔎 Verificando: $nombreCarpeta" "Yellow"
        
        # Ejecutar robocopy en modo verificación
        $opcionesStr = ($opcionesVerificacion + @("/LOG:`"$logVerificacion`"")) -join " "
        $comando = "robocopy `"$origen`" `"$destinoFinal`" $opcionesStr"
        
        try {
            $resultado = cmd /c $comando
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-Message "      ✅ Verificación exitosa" "Green" # ERA: "      ✅ ${nombreCarpeta}: Verificación exitosa" "Green"
            } elseif ($exitCode -ge 1 -and $exitCode -le 3) {
                Write-Message "      Se encontraron diferencias" "Yellow" # ERA: "      ⚠️ ${nombreCarpeta}: Se encontraron diferencias" "Yellow"
                $erroresVerificacion += $nombreCarpeta
            } else {
                Write-Message "      ❌ Error en verificación (código $exitCode)" "Red" # ERA: "      ❌ ${nombreCarpeta}: Error en verificación (código $exitCode)" "Red"
                $erroresVerificacion += $nombreCarpeta
            }
        } catch {
            Write-Message "❌ ${nombreCarpeta}: Error al verificar - $($_.Exception.Message)" "Red"
            $erroresVerificacion += $nombreCarpeta
        }
    }
    
    $finVerificacion = Get-Date
    $duracionVerificacion = $finVerificacion - $inicioVerificacion
    
    return @{
        Inicio = $inicioVerificacion
        Fin = $finVerificacion
        Duracion = $duracionVerificacion
        Errores = $erroresVerificacion
        EsExitosa = ($erroresVerificacion.Count -eq 0)
    }
}
