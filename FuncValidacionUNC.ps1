# ================================
# Funciones de validación y conversión UNC
# FuncValidacionUNC.ps1
# ================================

# Archivo de histórico de mapeos
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$mapFilePath = Join-Path $scriptDir "MapeosUNC.json"

function Get-UNCFromHistory {
    param([string]$DriveLetter)

    if (Test-Path $mapFilePath) {
        $mapeos = Get-Content $mapFilePath | ConvertFrom-Json
        if ($mapeos.$DriveLetter) {
            return $mapeos.$DriveLetter
        }
    }
    return $null
}

function Save-UNCToHistory {
    param(
        [string]$DriveLetter,
        [string]$UNCPath
    )

    $mapeos = @{}
    if (Test-Path $mapFilePath) {
        $mapeos = Get-Content $mapFilePath | ConvertFrom-Json
    }

    $mapeos.$DriveLetter = $UNCPath
    $mapeos | ConvertTo-Json | Out-File $mapFilePath -Encoding UTF8
}

# Función para convertir unidades lógicas a rutas UNC
function Convert-ToUNC {
    param($Path)
    
    $pathTrimmed = $Path.Trim()
    
    # Si ya es una ruta UNC, devolverla tal como está
    if ($pathTrimmed.StartsWith("\\")) {
        return @{
            RutaOriginal = $Path
            RutaConvertida = $pathTrimmed
            EsConversion = $false
            EsRed = $true
            Metodo = "Ya era UNC"
        }
    }
    
    # Verificar si es una unidad con letra
    if ($pathTrimmed.Length -ge 2 -and $pathTrimmed.Substring(1,1) -eq ':') {
        $unidadLetra = $pathTrimmed.Substring(0,1).ToUpper()
        $restoDeLaRuta = if ($pathTrimmed.Length -gt 3) { $pathTrimmed.Substring(3) } else { "" }
        
        try {
            # Método 1: WMI para unidades mapeadas
            $unidadMapeada = Get-WmiObject -Class Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -eq "${unidadLetra}:" }
            
            if ($unidadMapeada -and $unidadMapeada.ProviderName) {
                $rutaUNC = $unidadMapeada.ProviderName
                if ($restoDeLaRuta) {
                    $rutaUNC = $rutaUNC.TrimEnd('\') + '\' + $restoDeLaRuta.TrimStart('\')
                }
                Save-UNCToHistory -DriveLetter "${unidadLetra}:" -UNCPath $unidadMapeada.ProviderName
                return @{
                    RutaOriginal = $Path
                    RutaConvertida = $rutaUNC
                    EsConversion = $true
                    EsRed = $true
                    Metodo = "WMI"
                }
            }
            
            # Método 2: net use
            $netUseResult = net use "${unidadLetra}:" 2>$null
            if ($netUseResult -and $LASTEXITCODE -eq 0) {
                $lineaRemoto = $netUseResult | Select-String "Remote name|Recurso remoto"
                if ($lineaRemoto) {
                    $rutaUNC = ($lineaRemoto.ToString() -split '\s+')[-1].Trim()
                    if ($rutaUNC -and $rutaUNC.StartsWith("\\")) {
                        if ($restoDeLaRuta) {
                            $rutaUNC = $rutaUNC.TrimEnd('\') + '\' + $restoDeLaRuta.TrimStart('\')
                        }
                        Save-UNCToHistory -DriveLetter "${unidadLetra}:" -UNCPath $rutaUNC
                        return @{
                            RutaOriginal = $Path
                            RutaConvertida = $rutaUNC
                            EsConversion = $true
                            EsRed = $true
                            Metodo = "net use"
                        }
                    }
                }
            }

            # Método 3: Histórico local
            $rutaUNC = Get-UNCFromHistory -DriveLetter "${unidadLetra}:"
            if ($rutaUNC) {
                if ($restoDeLaRuta) {
                    $rutaUNC = $rutaUNC.TrimEnd('\') + '\' + $restoDeLaRuta.TrimStart('\')
                }
                return @{
                    RutaOriginal = $Path
                    RutaConvertida = $rutaUNC
                    EsConversion = $true
                    EsRed = $true
                    Metodo = "Histórico"
                }
            }
            
            # Si no se pudo convertir, es probablemente una unidad local
            return @{
                RutaOriginal = $Path
                RutaConvertida = $pathTrimmed
                EsConversion = $false
                EsRed = $false
                Metodo = "Local"
            }
            
        } catch {
            return @{
                RutaOriginal = $Path
                RutaConvertida = $pathTrimmed
                EsConversion = $false
                EsRed = $false
                Metodo = "Error: $($_.Exception.Message)"
            }
        }
    }
    
    # Para rutas que no siguen el patrón estándar
    return @{
        RutaOriginal = $Path
        RutaConvertida = $pathTrimmed
        EsConversion = $false
        EsRed = $false
        Metodo = "Sin conversión"
    }
}

# Función para validar una ruta individual
function Test-PathAccess {
    param($Path)
    
    try {
        # Verificar existencia básica
        if (Test-Path $Path -ErrorAction Stop) {
            # Intentar acceso de lectura
            $items = Get-ChildItem $Path -ErrorAction Stop | Select-Object -First 1
            return @{
                Existe = $true
                Accesible = $true
                Error = $null
            }
        } else {
            return @{
                Existe = $false
                Accesible = $false
                Error = "Ruta no encontrada"
            }
        }
    } catch {
        # La ruta existe pero no es accesible
        if (Test-Path $Path -ErrorAction SilentlyContinue) {
            return @{
                Existe = $true
                Accesible = $false
                Error = $_.Exception.Message
            }
        } else {
            return @{
                Existe = $false
                Accesible = $false
                Error = $_.Exception.Message
            }
        }
    }
}

# Función para validar destino
function Test-DestinationPath {
    param($DestinationPath)
    
    try {
        # Verificar si es ruta UNC
        if ($DestinationPath.StartsWith("\\")) {
            $servidor = $DestinationPath.Split('\')[2]
            if (!(Test-Connection -ComputerName $servidor -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
                return @{
                    Valido = $false
                    Error = "Servidor no accesible: \\$servidor"
                    Creado = $false
                }
            }
        } else {
            # Verificar unidad local
            $unidad = $DestinationPath.Substring(0,3)
            if (!(Test-Path $unidad -ErrorAction SilentlyContinue)) {
                return @{
                    Valido = $false
                    Error = "Unidad no existe: $unidad"
                    Creado = $false
                }
            }
        }
        
        # Intentar crear el directorio si no existe
        $creado = $false
        if (!(Test-Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force -ErrorAction Stop | Out-Null
            $creado = $true
        }
        
        # Verificar permisos de escritura
        $archivoTest = Join-Path $DestinationPath "test_backup_$(Get-Date -Format 'yyyyMMddHHmmss').tmp"
        "test" | Out-File -FilePath $archivoTest -Force -ErrorAction Stop
        Remove-Item $archivoTest -Force -ErrorAction Stop
        
        return @{
            Valido = $true
            Error = $null
            Creado = $creado
        }
        
    } catch {
        return @{
            Valido = $false
            Error = $_.Exception.Message
            Creado = $false
        }
    }
}

# Función principal de validación completa
function Invoke-PathValidation {
    param($CarpetasOrigen, $Destino)
    
    Write-Message "`n🔍 INICIANDO VALIDACIÓN DE RUTAS" "Magenta"
    
    $resultado = @{
        CarpetasValidas = @()
        CarpetasInvalidas = @()
        ConversionesUNC = @()
        DestinoValido = $false
        DestinoOriginal = $Destino
        DestinoFinal = $Destino
        ErroresOrigen = @()
        ErrorDestino = $null
        DestinoCreado = $false
        DestinoConvertido = $false
    }
    
    # 1. PRIMERO: Intentar conversión UNC del destino
    Write-Message "🎯 Procesando destino: $Destino" "Yellow"
    $conversionDestino = Convert-ToUNC -Path $Destino
    
    if ($conversionDestino.EsConversion) {
        $resultado.DestinoFinal = $conversionDestino.RutaConvertida
        $resultado.DestinoConvertido = $true
        $resultado.ConversionesUNC += $conversionDestino
        Write-Message "   🌐 Destino convertido a UNC: $($conversionDestino.RutaConvertida)" "Green"
    } else {
        $resultado.DestinoFinal = $conversionDestino.RutaConvertida
        if ($conversionDestino.EsRed) {
            Write-Message "   🌐 Destino ya es ruta de red: $($conversionDestino.RutaConvertida)" "Gray"
        } else {
            Write-Message "   💾 Destino es ruta local: $($conversionDestino.RutaConvertida)" "Gray"
        }
    }
    
    # 2. SEGUNDO: Validar el destino (ya convertido si correspondía)
    Write-Message "🔍 Validando destino final: $($resultado.DestinoFinal)" "Yellow"
    $validacionDestino = Test-DestinationPath -DestinationPath $resultado.DestinoFinal
    
    if ($validacionDestino.Valido) {
        $resultado.DestinoValido = $true
        $resultado.DestinoCreado = $validacionDestino.Creado
        if ($validacionDestino.Creado) {
            Write-Message "✅ Destino creado y accesible: $($resultado.DestinoFinal)" "Green"
        } else {
            Write-Message "✅ Destino accesible: $($resultado.DestinoFinal)" "Green"
        }
    } else {
        $resultado.ErrorDestino = $validacionDestino.Error
        Write-Message "❌ Destino inválido: $($validacionDestino.Error)" "Red"
        return $resultado
    }
    
    # 3. TERCERO: Procesar carpetas de origen (conversión UNC + validación)
    Write-Message "`n📂 Procesando $($CarpetasOrigen.Count) carpetas de origen..." "Yellow"
    
    foreach ($carpetaOrigen in $CarpetasOrigen) {
        Write-Message "🔄 Procesando: $carpetaOrigen" "Cyan"
        
        # Intentar conversión UNC
        $conversionResult = Convert-ToUNC -Path $carpetaOrigen
        
        # Registrar conversión si ocurrió
        if ($conversionResult.EsConversion) {
            $resultado.ConversionesUNC += $conversionResult
            Write-Message "   🌐 Convertido a UNC: $($conversionResult.RutaConvertida)" "Green"
        } elseif ($conversionResult.EsRed) {
            Write-Message "   🌐 Ya es ruta de red: $($conversionResult.RutaConvertida)" "Gray"
        } else {
            Write-Message "   💾 Ruta local: $($conversionResult.RutaConvertida)" "Gray"
        }
        
        # Validar la ruta (original o convertida)
        $validacionRuta = Test-PathAccess -Path $conversionResult.RutaConvertida
        
        if ($validacionRuta.Existe -and $validacionRuta.Accesible) {
            $resultado.CarpetasValidas += $conversionResult.RutaConvertida
            Write-Message "   ✅ Válida y accesible" "Green"
        } else {
            $resultado.CarpetasInvalidas += $carpetaOrigen
            $errorMsg = "Carpeta inválida: $carpetaOrigen"
            if ($conversionResult.EsConversion) {
                $errorMsg += " (convertida a: $($conversionResult.RutaConvertida))"
            }
            $errorMsg += " - $($validacionRuta.Error)"
            $resultado.ErroresOrigen += $errorMsg
            Write-Message "   ❌ $errorMsg" "Red"
        }
    }
    
    # 4. Resumen de validación
    Write-Message "`n📊 RESUMEN DE VALIDACIÓN:" "Magenta"
    Write-Message "   ✅ Carpetas válidas: $($resultado.CarpetasValidas.Count)" "Green"
    Write-Message "   ❌ Carpetas inválidas: $($resultado.CarpetasInvalidas.Count)" "Red"
    Write-Message "   🔄 Conversiones UNC: $($resultado.ConversionesUNC.Count)" "Cyan"
    Write-Message "   🎯 Destino: $(if($resultado.DestinoValido){'✅ VÁLIDO'}else{'❌ INVÁLIDO'})" $(if($resultado.DestinoValido){'Green'}else{'Red'})
    if ($resultado.DestinoConvertido) {
        Write-Message "   🌐 Destino convertido: $($resultado.DestinoOriginal) → $($resultado.DestinoFinal)" "Cyan"
    }
    
    if ($resultado.ConversionesUNC.Count -gt 0) {
        Write-Message "   📋 Conversiones realizadas:" "Yellow"
        foreach ($conversion in $resultado.ConversionesUNC) {
            $tipo = if ($conversion.RutaOriginal -eq $resultado.DestinoOriginal) { "[DESTINO]" } else { "[ORIGEN]" }
            Write-Message "      • $tipo $($conversion.RutaOriginal) → $($conversion.RutaConvertida)" "Cyan"
        }
    }
    
    return $resultado
}
