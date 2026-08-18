$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$vivadoBin = 'C:\Xilinx\Vivado\2020.2\bin'
$xvlog = Join-Path $vivadoBin 'xvlog.bat'
$xelab = Join-Path $vivadoBin 'xelab.bat'
$xsim = Join-Path $vivadoBin 'xsim.bat'

foreach ($tool in @($xvlog, $xelab, $xsim)) {
    if (-not (Test-Path -LiteralPath $tool)) {
        throw "Vivado simulator tool not found: $tool"
    }
}

$tests = @(
    'tb_multicycle_timing',
    'tb_rv32i_isa',
    'tb_control_flow_edges',
    'tb_illegal_instruction'
)
$sources = @(
    (Join-Path $projectRoot 'rv32i_cpu.sv'),
    (Join-Path $projectRoot 'rv32i_datapath.sv'),
    (Join-Path $projectRoot 'data_mem.sv')
)

foreach ($test in $tests) {
    $buildDir = Join-Path $projectRoot ".sim\$test"
    if (Test-Path -LiteralPath $buildDir) {
        $resolvedBuild = (Resolve-Path -LiteralPath $buildDir).Path
        $resolvedRoot = (Resolve-Path -LiteralPath $projectRoot).Path
        if (-not $resolvedBuild.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean simulation directory outside project: $resolvedBuild"
        }
        Remove-Item -LiteralPath $resolvedBuild -Recurse -Force
    }
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

    Push-Location $buildDir
    try {
        & $xvlog -sv -i $projectRoot @sources (Join-Path $projectRoot "tests\$test.sv")
        if ($LASTEXITCODE -ne 0) { throw "xvlog failed for $test" }

        & $xelab $test -s "${test}_snapshot"
        if ($LASTEXITCODE -ne 0) { throw "xelab failed for $test" }

        $simOutput = & $xsim "${test}_snapshot" -runall 2>&1
        $simExit = $LASTEXITCODE
        $simOutput | ForEach-Object { Write-Host $_ }
        $simText = $simOutput -join "`n"
        if (($simExit -ne 0) -or ($simText -match '(?m)^Fatal:') -or
            ($simText -notmatch "PASS:.*$test") ) {
            throw "simulation assertions failed for $test"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host 'PASS: all simulations'
