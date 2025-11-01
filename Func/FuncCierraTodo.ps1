# ================================
# Función para cerrar aplicaciones abiertas
# FuncCierraTodo.ps1
# Ubicación: Func\FuncCierraTodo.ps1
# ================================
# Cierra todas las aplicaciones en ventana antes del backup
# Excluye procesos críticos del sistema y aplicaciones protegidas

function Invoke-CierraTodo {
    # No necesita parámetros - usa Write-Message del script principal via dot sourcing
    
    Write-Message "🔒 Cerrando todas las aplicaciones en ventana..." "Yellow"
    
    # Lista para acumular los resultados
    $resultados = @()
    $resultados += ("-" * 78)
    $resultados += "Cerrado previo de programas ACTIVO"
    $resultados += ""
    
    # Obtiene todas las ventanas visibles con proceso asociado + procesos críticos del sistema
    $ventanas = Get-Process | Where-Object {
        $_.MainWindowHandle -ne 0 -and
        $_.MainWindowTitle -ne "" -and
        $_.ProcessName -notmatch '^(powershell|pwsh|powershell_ise|explorer|TextInputHost|winlogon|csrss|dwm|lsass|services|smss|wininit|svchost|taskhost|taskhostw|RuntimeBroker|SearchUI|StartMenuExperienceHost|ShellExperienceHost|ApplicationFrameHost|SystemSettings|WinStore.App|dllhost|sihost|ctfmon|MsMpEng|NisSrv|SecurityHealthService|audiodg|conhost)$' -and
        !$_.HasExited
    }
    
    if ($ventanas.Count -eq 0) {
        $resultados += "No se cerraron programas"
        $resultados += ("-" * 78)
        Write-Message "✅ No hay aplicaciones para cerrar" "Green"
        return ($resultados -join "`n")
    }
    
    $contadorErrores = 0
    $contadorCerrados = 0
    
    foreach ($proc in $ventanas) {
        # Guardar el nombre al inicio por si el objeto se invalida
        $nombreProceso = $proc.ProcessName
        
        try {
            Write-Message "   ❌ Cerrando: $nombreProceso" "Cyan"
            
            # Actualizar estado del proceso
            $proc.Refresh()
            
            # Verificar si el proceso sigue activo antes de intentar cerrarlo
            if ($proc.HasExited) {
                continue
            }
            
            # Intento de cierre suave con manejo de excepciones
            $cerradoSuave = $false
            try {
                $cerradoSuave = $proc.CloseMainWindow()
            } catch [System.InvalidOperationException] {
                # El proceso terminó durante CloseMainWindow
                continue
            }
            
            if ($cerradoSuave) {
                # Espera más inteligente con verificación periódica
                $intentos = 0
                $maxIntentos = 15  # 3 segundos total (15 x 200ms)
                
                while ($intentos -lt $maxIntentos) {
                    Start-Sleep -Milliseconds 200
                    $proc.Refresh()
                    if ($proc.HasExited) {
                        break
                    }
                    $intentos++
                }
            }
            
            # Actualizar estado nuevamente antes de verificar
            $proc.Refresh()
            
            # Si no se cerró después del tiempo de espera o CloseMainWindow falló
            if (!$proc.HasExited) {
                # Intento forzado si no respondió
                try {
                    $proc.Kill()
                    $proc.WaitForExit(1000)  # Esperar hasta 1 segundo
                    $resultados += "$($nombreProceso.ToUpper()) CERRADO FORZOSO"
                    Write-Message "   ⚠️ Forzado: $nombreProceso" "Red"
                    $contadorCerrados++
                } catch [System.InvalidOperationException] {
                    # El proceso ya terminó
                    $contadorCerrados++
                    continue
                }
            } else {
                $resultados += "$($nombreProceso.ToUpper()) CERRADO"
                $contadorCerrados++
            }
        } catch [System.InvalidOperationException] {
            # El proceso ya terminó durante la operación
            continue
        } catch [System.ComponentModel.Win32Exception] {
            # Error de acceso - proceso protegido o sin permisos
            $resultados += "$($nombreProceso.ToUpper()) ERROR (Sin permisos)"
            Write-Message "   ❌ Sin permisos para cerrar $nombreProceso" "Red"
            $contadorErrores++
        } catch {
            # Usar la variable guardada en lugar de acceder al objeto potencialmente inválido
            $resultados += "$($nombreProceso.ToUpper()) ERROR ($($_.Exception.Message))"
            Write-Message "   ❌ Error cerrando $nombreProceso`: $($_.Exception.Message)" "Red"
            $contadorErrores++
        }
    }
    
    # Mensaje final según resultados
    if ($contadorErrores -eq 0) {
        Write-Message "✅ Todas las aplicaciones se cerraron correctamente ($contadorCerrados cerradas)" "Green"
    } elseif ($contadorCerrados -gt 0) {
        Write-Message "⚠️ Aplicaciones cerradas: $contadorCerrados | Con errores: $contadorErrores" "Yellow"
    } else {
        Write-Message "❌ No se pudieron cerrar aplicaciones (errores: $contadorErrores)" "Red"
    }
    
    # Agregar línea de cierre
    $resultados += ("-" * 78)
    
    # Retornar los resultados como string con saltos de línea
    return ($resultados -join "`n")
}