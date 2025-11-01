# ================================
# Funciones para manejo de carpetas a omitir
# FuncManejaOmitir.ps1
# Ubicación: Func\FuncManejaOmitir.ps1
# ================================
# Procesa archivo Omitir.cfg con soporte para perfiles
# Usa variables del script principal via dot-sourcing

function Get-TipoRutaOmitir {
    <#
    .SYNOPSIS
    Determina el tipo de ruta (absoluta, relativa o nombre simple)
    #>
    param([string]$Ruta)
    
    $rutaTrim = $Ruta.Trim()
    
    # Detectar ruta absoluta (C:\, D:\, \\servidor\, etc.)
    if ($rutaTrim -match '^[A-Za-z]:\\' -or $rutaTrim.StartsWith("\\")) {
        return @{
            Tipo = "Absoluta"
            Descripcion = "Ruta absoluta específica"
        }
    }
    
    # Detectar ruta relativa (contiene \ o /)
    if ($rutaTrim.Contains('\') -or $rutaTrim.Contains('/')) {
        return @{
            Tipo = "Relativa"
            Descripcion = "Ruta relativa desde origen"
        }
    }
    
    # Nombre simple (sin separadores de ruta)
    return @{
        Tipo = "NombreSimple"
        Descripcion = "Nombre simple, omite en cualquier nivel"
    }
}

function Get-CarpetasOmitir {
    <#
    .SYNOPSIS
    Lee y procesa el archivo Omitir.cfg según el perfil activo
    
    .PARAMETER ArchivoOmitir
    Ruta completa al archivo Omitir.cfg
    
    .PARAMETER Perfil
    Número de perfil activo (0 = sin perfil)
    #>
    param(
        [string]$ArchivoOmitir,
        [int]$Perfil
    )
    
    # Usa Write-Message del script principal via dot-sourcing
    
    $resultado = @{
        Success = $true
        CarpetasOmitir = @()
        LineasProcesadas = 0
        Errores = @()
        ArchivoExiste = $false
        Clasificacion = @{
            NombresRelativos = @()
            RutasAbsolutas = @()
            RutasRelativas = @()
        }
    }
    
    # Verificar si existe el archivo
    if (!(Test-Path $ArchivoOmitir)) {
        Write-Message "📂 Archivo Omitir.cfg no encontrado - No se omitirán carpetas" "Gray"
        return $resultado
    }
    
    $resultado.ArchivoExiste = $true
    
    try {
        $lineasOriginales = Get-Content $ArchivoOmitir -Encoding UTF8 -ErrorAction Stop
        
        # Filtrar comentarios y líneas vacías
        $lineasValidas = $lineasOriginales | Where-Object { 
            $_.Trim() -ne "" -and !$_.StartsWith("#") 
        }
        
        if ($lineasValidas.Count -eq 0) {
            Write-Message "📂 Archivo Omitir.cfg está vacío - No se omitirán carpetas" "Gray"
            return $resultado
        }
        
        # Procesar según perfil
        if ($Perfil -gt 0) {
            # Modo perfil: buscar líneas que coincidan con el perfil
            $prefijoRequerido = "${Perfil}:"
            $lineasPerfil = $lineasValidas | Where-Object { 
                $_.Trim().StartsWith($prefijoRequerido) 
            }
            
            if ($lineasPerfil.Count -eq 0) {
                Write-Message "📂 Perfil $Perfil no tiene carpetas a omitir configuradas" "Gray"
                return $resultado
            }
            
            # Extraer las rutas (quitar el prefijo del perfil)
            $carpetasOmitir = $lineasPerfil | ForEach-Object {
                $_.Trim().Substring($prefijoRequerido.Length).Trim()
            }
            
            Write-Message "✅ Perfil ${Perfil}: $($carpetasOmitir.Count) carpetas a omitir" "Cyan"
            
        } else {
            # Modo estándar: usar líneas sin prefijo de perfil
            $lineasSinPerfil = $lineasValidas | Where-Object { 
                $linea = $_.Trim()
                # Verificar que no tenga formato de perfil (número seguido de dos puntos)
                $linea -notmatch '^\d+:'
            }
            
            if ($lineasSinPerfil.Count -eq 0) {
                Write-Message "📂 No hay carpetas a omitir para modo estándar" "Gray"
                return $resultado
            }
            
            $carpetasOmitir = $lineasSinPerfil | ForEach-Object { $_.Trim() }
            Write-Message "✅ Modo estándar: $($carpetasOmitir.Count) carpetas a omitir" "Cyan"
        }
        
        # Validar que las rutas no estén vacías
        $carpetasOmitirValidas = $carpetasOmitir | Where-Object { 
            ![string]::IsNullOrWhiteSpace($_) 
        }
        
        if ($carpetasOmitirValidas.Count -eq 0) {
            $resultado.Errores += "Todas las líneas de omisión están vacías"
            $resultado.Success = $false
            return $resultado
        }
        
        # Clasificar las rutas según su tipo
        Write-Message "`n🔍 Clasificando exclusiones..." "Cyan"
        
        foreach ($ruta in $carpetasOmitirValidas) {
            $tipo = Get-TipoRutaOmitir -Ruta $ruta
            
            switch ($tipo.Tipo) {
                "Absoluta" {
                    $resultado.Clasificacion.RutasAbsolutas += $ruta
                    Write-Message "   📍 Ruta absoluta: $ruta" "Yellow"
                }
                "Relativa" {
                    $resultado.Clasificacion.RutasRelativas += $ruta
                    Write-Message "   📁 Ruta relativa: $ruta" "Cyan"
                }
                "NombreSimple" {
                    $resultado.Clasificacion.NombresRelativos += $ruta
                    Write-Message "   🏷️  Nombre simple: $ruta (omite en cualquier nivel)" "Gray"
                }
            }
        }
        
        $resultado.CarpetasOmitir = $carpetasOmitirValidas
        $resultado.LineasProcesadas = $carpetasOmitirValidas.Count
        
        # Resumen de clasificación
        if ($carpetasOmitirValidas.Count -gt 0) {
            Write-Message "`n📋 Resumen de exclusiones:" "Magenta"
            Write-Message "   🏷️  Nombres simples: $($resultado.Clasificacion.NombresRelativos.Count) (omiten en cualquier nivel)" "Gray"
            Write-Message "   📁 Rutas relativas: $($resultado.Clasificacion.RutasRelativas.Count) (desde raíz de origen)" "Cyan"
            Write-Message "   📍 Rutas absolutas: $($resultado.Clasificacion.RutasAbsolutas.Count) (específicas)" "Yellow"
        }
        
    } catch {
        $resultado.Success = $false
        $resultado.Errores += "Error al leer Omitir.cfg: $($_.Exception.Message)"
    }
    
    return $resultado
}

function New-OmitirConfigFile {
    <#
    .SYNOPSIS
    Crea un archivo Omitir.cfg con ejemplos si no existe
    
    .PARAMETER ArchivoOmitir
    Ruta completa donde crear el archivo
    #>
    param([string]$ArchivoOmitir)
    
    # Usa Write-Message del script principal via dot-sourcing
    
    $ejemploOmitir = @"
# ========================================
# Configuración de carpetas a OMITIR durante el backup
# ========================================
# Líneas que comienzan con # son comentarios y se ignoran
#
# TIPOS DE EXCLUSIÓN (Modo Híbrido):
#
# 1. NOMBRE SIMPLE: Omite en cualquier nivel de las carpetas origen
#    Ejemplo: node_modules
#    Resultado: Omite C:\Datos\node_modules, C:\Docs\Proyectos\node_modules, etc.
#
# 2. RUTA RELATIVA: Omite desde la raíz de cada carpeta origen
#    Ejemplo: Documentos\Temp
#    Resultado: Omite [origen]\Documentos\Temp pero NO [origen]\Otros\Temp
#
# 3. RUTA ABSOLUTA: Omite solo esa ruta específica
#    Ejemplo: C:\Datos\NoBackupear
#    Resultado: Omite SOLO C:\Datos\NoBackupear
#
# ========================================
# MODO PERFILES:
# ========================================
# Formato: NUMERO_PERFIL:ruta
# Ejemplo: 1:node_modules
#          2:C:\Datos\Especifico
#
# ========================================
# CARPETAS UNIVERSALES DE WINDOWS
# ========================================
# Papelera de reciclaje (en cualquier unidad)
#`$RECYCLE.BIN

# Información del sistema (en cualquier unidad)
#System Volume Information

# Carpetas temporales comunes
#Temp
#AppData\Local\Temp

# Cache de Windows
#AppData\Local\Microsoft\Windows\INetCache

# ========================================
# CARPETAS COMUNES DE DESARROLLO
# ========================================
#node_modules
#.git
#.vs
#bin
#obj
#packages
#dist
#build

# ========================================
# EJEMPLOS CON PERFILES
# ========================================
#1:`$RECYCLE.BIN
#1:Temp
#1:node_modules
#2:C:\Proyectos\NoBackupear
#2:.git
"@
    
    try {
        Set-Content -Path $ArchivoOmitir -Value $ejemploOmitir -Encoding UTF8
        Write-Message "📄 Se ha creado el archivo Omitir.cfg con ejemplos" "Green"
        return $true
    } catch {
        Write-Message "❌ Error al crear Omitir.cfg: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Format-RobocopyExclusions {
    <#
    .SYNOPSIS
    Convierte las carpetas a omitir en parámetros /XD de Robocopy con conversión UNC
    
    .PARAMETER CarpetasOmitir
    Array de carpetas a excluir
    
    .OUTPUTS
    Array de parámetros para Robocopy (/XD "carpeta1" /XD "carpeta2" ...)
    #>
    param([array]$CarpetasOmitir)
    
    # Usa Write-Message y Convert-ToUNC del script principal via dot-sourcing
    
    if ($CarpetasOmitir.Count -eq 0) {
        return @()
    }
    
    $exclusiones = @()
    
    foreach ($carpeta in $CarpetasOmitir) {
        # Intentar convertir a UNC si es una ruta con letra de unidad
        $rutaFinal = $carpeta
        
        if ($carpeta -match '^[A-Za-z]:') {
            # Es una ruta con letra de unidad, intentar conversión UNC
            $conversionUNC = Convert-ToUNC -Path $carpeta
            
            if ($conversionUNC.EsConversion) {
                $rutaFinal = $conversionUNC.RutaConvertida
                Write-Message "   🔄 Exclusión convertida: $carpeta → $rutaFinal" "Cyan"
            } else {
                # Si no se pudo convertir, usar la ruta original
                $rutaFinal = $conversionUNC.RutaConvertida
            }
        }
        
        $exclusiones += "/XD"
        $exclusiones += "`"$rutaFinal`""
    }
    
    # Debug: mostrar parámetros generados
    Write-Message "`n🔧 Parámetros de exclusión para Robocopy:" "Magenta"
    Write-Message "   $($exclusiones -join ' ')" "Yellow"
    
    return $exclusiones
}