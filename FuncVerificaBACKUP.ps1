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
    # Si NuncaBorra está activo, usa /E en lugar de /MIR para no detectar extras como error
    $opcionesVerificacion = @(
        $(if ($NuncaBorra) { "/E" } else { "/MIR" }),  # /E no considera extras como error
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
            
            # Interpretación de códigos según modo
            if ($NuncaBorra) {
                # En modo NuncaBorra, código 2 (extras) NO es error
                if ($exitCode -eq 0 -or $exitCode -eq 2) {
                    Write-Message "      ✅ Verificación exitosa" "Green"
                } elseif ($exitCode -eq 1 -or $exitCode -eq 3) {
                    Write-Message "      ⚠️ Se encontraron diferencias (archivos faltantes o diferentes)" "Yellow"
                    $erroresVerificacion += $nombreCarpeta
                } else {
                    Write-Message "      ❌ Error en verificación (código $exitCode)" "Red"
                    $erroresVerificacion += $nombreCarpeta
                }
            } else {
                # En modo normal, cualquier diferencia es advertencia
                if ($exitCode -eq 0) {
                    Write-Message "      ✅ Verificación exitosa" "Green"
                } elseif ($exitCode -ge 1 -and $exitCode -le 3) {
                    Write-Message "      ⚠️ Se encontraron diferencias" "Yellow"
                    $erroresVerificacion += $nombreCarpeta
                } else {
                    Write-Message "      ❌ Error en verificación (código $exitCode)" "Red"
                    $erroresVerificacion += $nombreCarpeta
                }
            }
        } catch {
            Write-Message "      ❌ Error al verificar - $($_.Exception.Message)" "Red"
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