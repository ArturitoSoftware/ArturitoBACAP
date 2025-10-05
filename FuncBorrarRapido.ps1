function Borrar-Rapido {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")]
        [string[]]$Path,

        [switch]$Recurse,
        [switch]$Force,
        [string[]]$Include,
        [string[]]$Exclude,
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {
        # Carpeta vacía para Robocopy
        $tmpEmpty = Join-Path $env:TEMP "CarpetaVacia"
        if (-not (Test-Path $tmpEmpty)) { New-Item -Path $tmpEmpty -ItemType Directory | Out-Null }

        # Determinar cantidad máxima de Jobs paralelos según CPU
        $maxJobs = [math]::Max(1, [int]([Environment]::ProcessorCount * 0.7))
        $jobQueue = @()
    }

    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) { continue }

            # Expandir rutas según Include/Exclude
            $items = Get-ChildItem -LiteralPath $p -Force -Recurse:$Recurse -Include $Include -Exclude $Exclude -ErrorAction SilentlyContinue

            if (-not $items) { continue }

            foreach ($item in $items) {
                if (-not (Test-Path $item.FullName)) { continue }

                # Respeta -WhatIf y -Confirm
                if ($PSCmdlet.ShouldProcess($item.FullName, "Eliminar")) {
                    if ($item.PSIsContainer) {
                        # Carpeta → borrar en Job paralelo
                        $job = Start-Job -ScriptBlock {
                            param($folder, $tmp)
                            # Quitar ReadOnly de todo el contenido
                            Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Attributes = 'Normal' }
                            # Robocopy espejo para eliminar rápido
                            robocopy $tmp $folder /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
                            # Eliminar la carpeta en sí
                            Remove-Item $folder -Force -Recurse -ErrorAction SilentlyContinue
                        } -ArgumentList $item.FullName, $tmpEmpty
                        $jobQueue += $job

                        # Control de Jobs paralelos
                        while ($jobQueue.Count -ge $maxJobs) {
                            $finished = $jobQueue | Where-Object { $_.State -ne 'Running' }
                            if ($finished) {
                                $jobQueue = $jobQueue | Where-Object { $_.State -eq 'Running' }
                            }
                            Start-Sleep -Milliseconds 50
                        }
                    } else {
                        # Archivo → eliminar directo
                        Remove-Item $item.FullName -Force:$Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
    }

    end {
        # Esperar que todos los Jobs terminen
        if ($jobQueue) {
            $jobQueue | Wait-Job | Out-Null
            $jobQueue | Remove-Job -Force
        }
    }
}
