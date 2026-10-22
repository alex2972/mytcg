$ErrorActionPreference = 'Stop'
$builderScript = Join-Path $PSScriptRoot 'server.py'
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCommand) {
    & $pythonCommand.Source $builderScript
} else {
    $bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (-not (Test-Path -LiteralPath $bundledPython)) {
        throw 'Python was not found. Install Python and Pillow, then run this launcher again.'
    }
    & $bundledPython $builderScript
}
