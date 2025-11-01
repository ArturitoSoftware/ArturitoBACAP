# ================================
# Función de gestión de histórico de backups
# FuncGuardaHistorico.ps1
# Ubicación: Func\FuncGuardaHistorico.ps1
# ================================

function GuardaHistorico {
    # No necesita parámetros - usa las variables del script principal via dot sourcing
    # Variables que usa: $DestinoFinal, $Historico, $Destino
    
    try {
        # Guardar directorio base antes de que $DestinoFinal se modifique
        $DirectorioBase = $DestinoFinal
        
        Write-Message "`nGESTIÓN DE HISTORICO DE BACKUPS" "Magenta"
        Write-Message "Directorio base: $DestinoFinal" "Cyan"
        
        # Patrón para validar nombres de carpetas de backup histórico
        $patronBackup = "^BCKPHist\d{8}_\d{6}$"
        
        # 1) Verificar y eliminar carpetas que no cumplan con el patrón de nombre
        Write-Message "Verificando carpetas existentes en: $DestinoFinal" "Yellow"
        
        $todasLasCarpetas = Get-ChildItem -Path $DestinoFinal -Directory -ErrorAction SilentlyContinue
        $carpetasInvalidas = $todasLasCarpetas | Where-Object { $_.Name -notmatch $patronBackup }
        
        if ($carpetasInvalidas) {
            Write-Message "Eliminando carpetas con nombres inválidos..." "Red"
            foreach ($carpeta in $carpetasInvalidas) {
                Write-Message "Eliminando carpeta inválida: $($carpeta.Name)" "Red"
                Remove-Item -Path $carpeta.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Obtener carpetas válidas de backup
        $carpetasBackup = Get-ChildItem -Path $DestinoFinal -Directory | Where-Object { $_.Name -match $patronBackup }
        $cantidadActual = $carpetasBackup.Count
        
        Write-Message "Carpetas de backup encontradas: $cantidadActual" "Cyan"
        Write-Message "Cantidad de históricos solicitados: $Historico" "Cyan"
        
        # Generar nombre de nueva carpeta con fecha y hora actual
        $fechaHoraActual = Get-Date -Format "yyyyMMdd_HHmmss"
        $nombreNuevaCarpeta = "BCKPHist$fechaHoraActual"
        $rutaNuevaCarpeta = Join-Path -Path $DestinoFinal -ChildPath $nombreNuevaCarpeta
        
        if ($cantidadActual -lt $Historico) {
            # 3) Hay menos carpetas que las solicitadas - crear nueva sin borrar ninguna
            Write-Message "Creando nueva carpeta de backup: $nombreNuevaCarpeta" "Green"
            New-Item -Path $rutaNuevaCarpeta -ItemType Directory -Force | Out-Null
            Write-Message "Carpeta creada exitosamente: $rutaNuevaCarpeta" "Green"
            
            # Actualizar $DestinoFinal para que apunte a la carpeta de backup específica
            $script:DestinoFinal = $rutaNuevaCarpeta
            
        } elseif ($cantidadActual -eq $Historico) {
            # 4) Cantidad igual a la solicitada - renombrar la más antigua
            $carpetasOrdenadas = $carpetasBackup | Sort-Object Name
            $carpetaMasAntigua = $carpetasOrdenadas[0]
            
            Write-Message "Renombrando carpeta más antigua: $($carpetaMasAntigua.Name) -> $nombreNuevaCarpeta" "Yellow"
            Rename-Item -Path $carpetaMasAntigua.FullName -NewName $nombreNuevaCarpeta -Force
            Write-Message "Carpeta renombrada exitosamente" "Green"
            
            # Actualizar $DestinoFinal para que apunte a la carpeta de backup específica
            $script:DestinoFinal = Join-Path -Path $DestinoFinal -ChildPath $nombreNuevaCarpeta
            
        } else {
            # 2) Hay más carpetas que las solicitadas - eliminar las más antiguas y renombrar la más vieja
            $carpetasOrdenadas = $carpetasBackup | Sort-Object Name
            $cantidadAEliminar = $cantidadActual - $Historico
            
            Write-Message "Eliminando $cantidadAEliminar carpetas más antiguas..." "Red"
            
            # Eliminar las más antiguas (pero dejar una para renombrar)
            for ($i = 0; $i -lt $cantidadAEliminar; $i++) {
                if ($i -lt $carpetasOrdenadas.Count) {
                    $carpetaAEliminar = $carpetasOrdenadas[$i]
                    Write-Message "Eliminando carpeta antigua: $($carpetaAEliminar.Name)" "Red"
                    Remove-Item -Path $carpetaAEliminar.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            
            # Renombrar la más vieja restante
            $carpetasRestantes = Get-ChildItem -Path $DestinoFinal -Directory | Where-Object { $_.Name -match $patronBackup } | Sort-Object Name
            if ($carpetasRestantes.Count -gt 0) {
                $carpetaMasVieja = $carpetasRestantes[0]
                Write-Message "Renombrando carpeta más vieja restante: $($carpetaMasVieja.Name) -> $nombreNuevaCarpeta" "Yellow"
                Rename-Item -Path $carpetaMasVieja.FullName -NewName $nombreNuevaCarpeta -Force
                Write-Message "Carpeta renombrada exitosamente" "Green"
                
                # Actualizar $DestinoFinal para que apunte a la carpeta de backup específica
                $script:DestinoFinal = Join-Path -Path $DestinoFinal -ChildPath $nombreNuevaCarpeta
            }
        }
        
        # Verificación final
        $carpetasFinales = Get-ChildItem -Path $DirectorioBase -Directory | Where-Object { $_.Name -match $patronBackup }
        Write-Message "Proceso completado. Destino era: $Destino Ahora apunta a: $DestinoFinal" "Green"
        Write-Message "Total de carpetas de backup mantenidas: $($carpetasFinales.Count)" "Green"
        
    } catch {
        Write-Error "Error en GuardaHistorico: $($_.Exception.Message)"
        throw
    }
}