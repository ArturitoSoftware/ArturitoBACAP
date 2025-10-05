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
    
    param(
        [string]$credentialsFile = (Join-Path $PSScriptRoot "configSMTP.xml")
    )
    
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
        $configEmail | Export-Clixml -Path $credentialsFile
        
        # Asegurar permisos del archivo (solo usuario actual)
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl = Get-Acl $credentialsFile
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
        $regla = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            "FullControl",
            "Allow"
        )
        $acl.SetAccessRule($regla)
        Set-Acl -Path $credentialsFile -AclObject $acl
        
        Write-Host "`n✅ Configuración guardada exitosamente" -ForegroundColor Green
        Write-Host "   📁 Archivo: $credentialsFile" -ForegroundColor Gray
        Write-Host "   🔒 Permisos seguros aplicados" -ForegroundColor Gray
        Write-Host "   👤 Solo accesible por: $currentUser`n" -ForegroundColor Gray
        
        # Ofrecer enviar email de prueba
        $enviarPrueba = Read-Host "¿Enviar email de prueba? (S/N) [S]"
        if ([string]::IsNullOrWhiteSpace($enviarPrueba) -or $enviarPrueba -eq "S") {
            Write-Host "`n📤 Enviando email de prueba..." -ForegroundColor Yellow
            
            $resultado = Send-BackupEmail `
                -ConfigFile $credentialsFile `
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
    
    param(
        [string]$credentialsFile = (Join-Path $PSScriptRoot "configSMTP.xml")
    )
    
    if (!(Test-Path $credentialsFile)) {
        return @{
            Valido = $false
            Error = "No existe configuración de email"
            Sugerencia = "Ejecuta: .\ArturitoBACAP.ps1 -AjustaEmail"
        }
    }
    
    # Verificar permisos de seguridad
    $acl = Get-Acl $credentialsFile
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
        $config = Import-Clixml -Path $credentialsFile
        
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
    
    .PARAMETER ConfigFile
    Ruta al archivo de configuración encriptada
    
    .PARAMETER Subject
    Asunto del email
    
    .PARAMETER Body
    Cuerpo del email
    
    .PARAMETER Attachment
    Ruta al archivo adjunto (opcional)
    
    .PARAMETER EsPrueba
    Indica si es un email de prueba (no requiere adjunto)
    #>
    
    param(
        [string]$ConfigFile = (Join-Path $PSScriptRoot "configSMTP.xml"),
        [Parameter(Mandatory=$true)]
        [string]$Subject,
        [Parameter(Mandatory=$true)]
        [string]$Body,
        [string]$Attachment = $null,
        [switch]$EsPrueba = $false
    )
    
    # Validar configuración
    $validacion = Test-EmailConfig -credentialsFile $ConfigFile
    if (!$validacion.Valido) {
        Write-Host "❌ $($validacion.Error)" -ForegroundColor Red
        Write-Host "💡 $($validacion.Sugerencia)" -ForegroundColor Yellow
        return $false
    }
    
    $config = $validacion.Config
    
    # Comprimir adjunto si es muy grande (>10MB)
    if ($Attachment -and (Test-Path $Attachment)) {
        $tamano = (Get-Item $Attachment).Length
        if ($tamano -gt 10MB) {
            $archivoComprimido = "$Attachment.zip"
            try {
                Compress-Archive -Path $Attachment -DestinationPath $archivoComprimido -Force
                $Attachment = $archivoComprimido
                Write-Host "📦 Log comprimido para envío (tamaño original: $([math]::Round($tamano/1MB, 2)) MB)" -ForegroundColor Yellow
            } catch {
                Write-Host "⚠️  No se pudo comprimir el adjunto: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
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
        
        # Agregar adjunto si existe y no es prueba
        if ($Attachment -and (Test-Path $Attachment) -and !$EsPrueba) {
            $mailParams.Attachments = $Attachment
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
            return $false
        } elseif ($emailJob.State -eq 'Completed') {
            Receive-Job $emailJob | Out-Null
            Remove-Job $emailJob
            
            # Limpiar archivo comprimido temporal si se creó
            if ($Attachment -and $Attachment.EndsWith('.zip') -and !$EsPrueba) {
                Remove-Item $Attachment -Force -ErrorAction SilentlyContinue
            }
            
            return $true
        } else {
            $emailError = Receive-Job $emailJob
            Remove-Job $emailJob
            Write-Host "❌ Error al enviar email: $emailError" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "❌ Error al enviar email: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}