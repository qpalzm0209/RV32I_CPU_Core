$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$vivado = 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat'
$tclScript = Join-Path $PSScriptRoot 'check_synth.tcl'

if (-not (Test-Path -LiteralPath $vivado)) {
    throw "Vivado not found: $vivado"
}

$reportDir = Join-Path $projectRoot '.synth'
if (Test-Path -LiteralPath $reportDir) {
    $resolvedReport = (Resolve-Path -LiteralPath $reportDir).Path
    $resolvedRoot = (Resolve-Path -LiteralPath $projectRoot).Path
    if (-not $resolvedReport.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean synthesis directory outside project: $resolvedReport"
    }
    Remove-Item -LiteralPath $resolvedReport -Recurse -Force
}

Push-Location $projectRoot
try {
    $output = & $vivado -mode batch -source $tclScript -nojournal -nolog 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }
    $text = $output -join "`n"
    if (($exitCode -ne 0) -or ($text -match '(?m)^ERROR:') -or
        ($text -notmatch 'PASS: production top RTL elaboration') -or
        ($text -notmatch 'PASS: core routed timing check')) {
        throw 'Vivado synthesis or implementation failed'
    }
}
finally {
    Pop-Location
}

Get-Content -LiteralPath (Join-Path $reportDir 'summary.txt')
