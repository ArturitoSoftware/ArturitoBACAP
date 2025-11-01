# ================================
# FuncEnviaEmail.ps1
# Función para configurar y enviar emails de backup
# ================================

function Set-EmailConfig {
    <#
    .SYNOPSIS
    Configura los parámetros SMTP de forma segura
    
    .DESCRIPTION
    Solicita al usuario todos los parámetros necesarios para el envío de emails
    y los guarda de forma encriptada en un archivo XML
    #>
    
    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "=== 🚀 ArturitoBACAP - 🔐 CONFIGURACIÓN DE EMAIL ===" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    
    Write-Host "`n📧 Ingresa los datos de tu servidor SMTP:" -ForegroundColor Yellow
    Write-Host "   (Todos los datos se guardarán encriptados)`n" -ForegroundColor Gray
    
    # Solicitar datos SMTP
    $smtpServer = Read-Host "Servidor SMTP (ej: smtp.gmail.com)"
    if ([string]::IsNullOrWhiteSpace($smtpServer)) {
        Write-Host "❌ El servidor SMTP es obligatorio" -ForegroundColor Red
        return $false
    }
    
    $puerto = Read-Host "Puerto (ej: 587 para TLS, 465 para SSL)"
    if ([string]::IsNullOrWhiteSpace($puerto)) {
        $puerto = "587"
        Write-Host "   ℹ️  Usando puerto por defecto: 587" -ForegroundColor Gray
    }
    
    $usaSsl = Read-Host "¿Usar SSL/TLS? (S/N) [S]"
    if ([string]::IsNullOrWhiteSpace($usaSsl)) { $usaSsl = "S" }
    $usaSslBool = $usaSsl -eq "S"
    
    $emailDesde = Read-Host "Email remitente (FROM)"
    if ([string]::IsNullOrWhiteSpace($emailDesde)) {
        Write-Host "❌ El email remitente es obligatorio" -ForegroundColor Red
        return $false
    }
    
    $emailPara = Read-Host "Email destinatario (TO)"
    if ([string]::IsNullOrWhiteSpace($emailPara)) {
        Write-Host "❌ El email destinatario es obligatorio" -ForegroundColor Red
        return $false
    }
    
    $usuario = Read-Host "Usuario SMTP (normalmente el mismo que FROM)"
    if ([string]::IsNullOrWhiteSpace($usuario)) {
        $usuario = $emailDesde
        Write-Host "   ℹ️  Usando email remitente como usuario" -ForegroundColor Gray
    }
    
    $securePass = Read-Host "Contraseña SMTP" -AsSecureString
    
    # Crear objeto con configuración
    $configEmail = @{
        SmtpServer = $smtpServer
        Port = [int]$puerto
        UseSsl = $usaSslBool
        From = $emailDesde
        To = $emailPara
        Usuario = $usuario
        Password = $securePass
    }
    
    try {
        # Guardar configuración encriptada
        $configEmail | Export-Clixml -Path $configEmailFile
        
        # Asegurar permisos del archivo (solo usuario actual)
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $permisosAplicados = $false
        
        try {
            $acl = Get-Acl $configEmailFile
            $acl.SetAccessRuleProtection($true, $false)
            $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
            $regla = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $currentUser,
                "FullControl",
                "Allow"
            )
            $acl.SetAccessRule($regla)
            Set-Acl -Path $configEmailFile -AclObject $acl -ErrorAction Stop
            $permisosAplicados = $true
        } catch {
            # Si falla por permisos, intentar método alternativo más simple
            try {
                icacls $configEmailFile /inheritance:r /grant:r "$($currentUser):F" | Out-Null
                $permisosAplicados = $true
            } catch {
                # Si tampoco funciona, continuar sin permisos restringidos
                Write-Host "   ⚠️  No se pudieron aplicar permisos restringidos (requiere permisos elevados)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`n✅ Configuración guardada exitosamente" -ForegroundColor Green
        Write-Host "   📁 Archivo: $configEmailFile" -ForegroundColor Gray
        if ($permisosAplicados) {
            Write-Host "   🔒 Permisos seguros aplicados" -ForegroundColor Gray
            Write-Host "   👤 Solo accesible por: $currentUser`n" -ForegroundColor Gray
        } else {
            Write-Host "   ⚠️  Archivo guardado con permisos estándar" -ForegroundColor Yellow
            Write-Host "   💡 Para mayor seguridad, ejecuta como administrador`n" -ForegroundColor Gray
        }
        
        # Ofrecer enviar email de prueba
        $enviarPrueba = Read-Host "¿Enviar email de prueba? (S/N) [S]"
        if ([string]::IsNullOrWhiteSpace($enviarPrueba) -or $enviarPrueba -eq "S") {
            Write-Host "`n📤 Enviando email de prueba..." -ForegroundColor Yellow
            
            $resultado = Send-BackupEmail `
                -Subject "✅ Prueba de configuración - ArturitoBacap" `
                -Body "Este es un email de prueba.`n`nSi lo recibiste, la configuración es correcta.`n`n🚀 ArturitoBacap está listo para enviar reportes de backup." `
                -EsPrueba
            
            if ($resultado) {
                Write-Host "✅ Email de prueba enviado correctamente" -ForegroundColor Green
                Write-Host "   Verifica tu bandeja de entrada en: $emailPara`n" -ForegroundColor Gray
            } else {
                Write-Host "❌ Error al enviar email de prueba" -ForegroundColor Red
                Write-Host "   Verifica la configuración y vuelve a intentar con:" -ForegroundColor Yellow
                Write-Host "   .\ArturitoBACAP.ps1 -AjustaEmail`n" -ForegroundColor Yellow
            }
        }
        
        return $true
        
    } catch {
        Write-Host "`n❌ Error guardando configuración: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-EmailConfig {
    <#
    .SYNOPSIS
    Verifica si existe configuración de email válida
    
    .DESCRIPTION
    Comprueba la existencia del archivo de configuración y sus permisos
    #>
    
    if (!(Test-Path $configEmailFile)) {
        return @{
            Valido = $false
            Error = "No existe configuración de email"
            Sugerencia = "Ejecuta: .\ArturitoBACAP.ps1 -AjustaEmail"
        }
    }
    
    # Verificar permisos de seguridad
    $acl = Get-Acl $configEmailFile
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    
    $reglasOtrosUsuarios = $acl.Access | Where-Object { 
        $_.IdentityReference -ne $currentUser -and 
        $_.IdentityReference -notlike "*SYSTEM*" -and
        $_.IdentityReference -notlike "*Administrador*"
    }
    
    if ($reglasOtrosUsuarios) {
        return @{
            Valido = $false
            Error = "El archivo de configuración tiene permisos inseguros"
            Sugerencia = "Ejecuta: .\ArturitoBACAP.ps1 -AjustaEmail para reconfigurar"
        }
    }
    
    # Intentar cargar configuración
    try {
        $config = Import-Clixml -Path $configEmailFile
        
        # Validar que tenga los campos necesarios
        $camposRequeridos = @('SmtpServer', 'Port', 'From', 'To', 'Usuario', 'Password')
        $camposFaltantes = $camposRequeridos | Where-Object { -not $config.ContainsKey($_) }
        
        if ($camposFaltantes) {
            return @{
                Valido = $false
                Error = "Configuración incompleta (faltan: $($camposFaltantes -join ', '))"
                Sugerencia = "Ejecuta: .\ArturitoBACAP.ps1 -AjustaEmail para reconfigurar"
            }
        }
        
        return @{
            Valido = $true
            Config = $config
        }
        
    } catch {
        return @{
            Valido = $false
            Error = "Error al leer configuración: $($_.Exception.Message)"
            Sugerencia = "Ejecuta: .\ArturitoBACAP.ps1 -AjustaEmail para reconfigurar"
        }
    }
}

function Send-BackupEmail {
    <#
    .SYNOPSIS
    Envía email con reporte de backup
    
    .DESCRIPTION
    Carga la configuración encriptada y envía el email con el reporte adjunto
    
    .PARAMETER Subject
    Asunto del email
    
    .PARAMETER Body
    Cuerpo del email
    
    .PARAMETER Attachment
    Ruta(s) al(los) archivo(s) adjunto(s) - puede ser string o array
    
    .PARAMETER EsPrueba
    Indica si es un email de prueba (no requiere adjunto)
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        [Parameter(Mandatory=$true)]
        [string]$Body,
        $Attachment = $null,  # Acepta string o array
        [switch]$EsPrueba = $false
    )
    
    # Validar configuración
    $validacion = Test-EmailConfig
    if (!$validacion.Valido) {
        Write-Host "❌ $($validacion.Error)" -ForegroundColor Red
        Write-Host "💡 $($validacion.Sugerencia)" -ForegroundColor Yellow
        return $false
    }
    
    $config = $validacion.Config
    
    # Normalizar adjuntos a array
    $adjuntosFinales = @()
    if ($Attachment) {
        if ($Attachment -is [array]) {
            $adjuntosFinales = $Attachment | Where-Object { Test-Path $_ }
        } elseif ($Attachment -is [string] -and (Test-Path $Attachment)) {
            $adjuntosFinales = @($Attachment)
        }
    }
    
    # Comprimir adjuntos si son muy grandes (>10MB cada uno)
    $adjuntosComprimidos = @()
    $totalSize = 0
    
    foreach ($adjunto in $adjuntosFinales) {
        $tamano = (Get-Item $adjunto).Length
        $totalSize += $tamano
        
        if ($tamano -gt 10MB) {
            $archivoComprimido = "$adjunto.zip"
            try {
                Compress-Archive -Path $adjunto -DestinationPath $archivoComprimido -Force
                $adjuntosComprimidos += $archivoComprimido
                $tamanoComprimido = (Get-Item $archivoComprimido).Length
                Write-Host "📦 $(Split-Path $adjunto -Leaf) comprimido: $([math]::Round($tamano/1MB, 2)) MB → $([math]::Round($tamanoComprimido/1MB, 2)) MB" -ForegroundColor Yellow
            } catch {
                Write-Host "⚠️  No se pudo comprimir $(Split-Path $adjunto -Leaf): $($_.Exception.Message)" -ForegroundColor Yellow
                $adjuntosComprimidos += $adjunto
            }
        } else {
            $adjuntosComprimidos += $adjunto
        }
    }
    
    if ($adjuntosComprimidos.Count -gt 0) {
        Write-Host "📎 Adjuntando $($adjuntosComprimidos.Count) archivo(s) (Total: $([math]::Round($totalSize/1MB, 2)) MB)" -ForegroundColor Cyan
    }
    
    try {
        # Crear credenciales
        $credenciales = New-Object System.Management.Automation.PSCredential (
            $config.Usuario, 
            $config.Password
        )
        
        # Preparar parámetros de envío (sin Encoding que causa problemas de serialización)
        $mailParams = @{
            From = $config.From
            To = $config.To
            Subject = $Subject
            Body = $Body
            SmtpServer = $config.SmtpServer
            Port = $config.Port
            UseSsl = $config.UseSsl
        }
        
        # Agregar adjuntos si existen y no es prueba
        if ($adjuntosComprimidos.Count -gt 0 -and !$EsPrueba) {
            $mailParams.Attachments = $adjuntosComprimidos
        }
        
        # Enviar email con timeout - crear Encoding dentro del job
        $emailJob = Start-Job -ScriptBlock { 
            param($Params, $Usuario, $Password)
            
            # Crear credenciales dentro del job
            $cred = New-Object System.Management.Automation.PSCredential($Usuario, $Password)
            
            # Agregar encoding UTF8 dentro del job (evita problemas de serialización)
            $Params.Encoding = [System.Text.Encoding]::UTF8
            $Params.Credential = $cred
            
            Send-MailMessage @Params
        } -ArgumentList $mailParams, $config.Usuario, $config.Password
        
        $emailCompleto = Wait-Job $emailJob -Timeout 60
        
        if ($emailJob.State -eq 'Running') {
            Stop-Job $emailJob
            Remove-Job $emailJob
            Write-Host "⏱️  Timeout al enviar email (60 segundos)" -ForegroundColor Yellow
            
            # Limpiar archivos comprimidos temporales
            foreach ($adjunto in $adjuntosComprimidos) {
                if ($adjunto.EndsWith('.zip') -and !$EsPrueba) {
                    Remove-Item $adjunto -Force -ErrorAction SilentlyContinue
                }
            }
            
            return $false
        } elseif ($emailJob.State -eq 'Completed') {
            Receive-Job $emailJob | Out-Null
            Remove-Job $emailJob
            
            # Limpiar archivos comprimidos temporales si se crearon
            foreach ($adjunto in $adjuntosComprimidos) {
                if ($adjunto.EndsWith('.zip') -and !$EsPrueba) {
                    Remove-Item $adjunto -Force -ErrorAction SilentlyContinue
                }
            }
            
            return $true
        } else {
            $emailError = Receive-Job $emailJob
            Remove-Job $emailJob
            Write-Host "❌ Error al enviar email: $emailError" -ForegroundColor Red
            
            # Limpiar archivos comprimidos temporales
            foreach ($adjunto in $adjuntosComprimidos) {
                if ($adjunto.EndsWith('.zip') -and !$EsPrueba) {
                    Remove-Item $adjunto -Force -ErrorAction SilentlyContinue
                }
            }
            
            return $false
        }
        
    } catch {
        Write-Host "❌ Error al enviar email: $($_.Exception.Message)" -ForegroundColor Red
        
        # Limpiar archivos comprimidos temporales en caso de error
        foreach ($adjunto in $adjuntosComprimidos) {
            if ($adjunto.EndsWith('.zip') -and !$EsPrueba) {
                Remove-Item $adjunto -Force -ErrorAction SilentlyContinue
            }
        }
        
        return $false
    }
}