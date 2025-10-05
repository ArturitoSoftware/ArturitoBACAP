function Invoke-LimpiaLogs {
    
    try {
        # Obtener todos los archivos BCKP_*.log ordenados por fecha de creación (más antiguos primero)
        $archivosLog = Get-ChildItem -Path $logDir -Filter "BCKP_*.log" | 
                       Sort-Object CreationTime
        
        # Si hay 6 o menos archivos, no borrar nada
        if ($archivosLog.Count -le 6) {
            Write-Message "📄 Logs encontrados: $($archivosLog.Count) - No se requiere limpieza" "Green"
            return
        }
        
        # Calcular cuántos archivos hay que borrar (todos menos los 6 más recientes)
        $cantidadABorrar = $archivosLog.Count - 6
        $archivosABorrar = $archivosLog | Select-Object -First $cantidadABorrar
        
        Write-Message "`n🧹 Limpiando logs antiguos: borrando $cantidadABorrar de $($archivosLog.Count) archivos" "Yellow"
        
        # Borrar los archivos más antiguos
        foreach ($archivo in $archivosABorrar) {
            try {
                Remove-Item -Path $archivo.FullName -Force
                Write-Message "   ❌ Borrado: $($archivo.Name)" "Cyan"
            } catch {
                Write-Message "   ⚠️ Error borrando $($archivo.Name): $($_.Exception.Message)" "Red"
            }
        }
        
        Write-Message "✅ Limpieza de logs completada - Conservados los 6 archivos más recientes" "Green"
        
    } catch {
        Write-Message "❌ Error en limpieza de logs: $($_.Exception.Message)" "Red"
    }
}