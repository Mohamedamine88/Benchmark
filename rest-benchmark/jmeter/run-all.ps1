param(
    [string]$JMeterExecutable = "jmeter",
    [string]$ResultsDirectory = "../results",
    [string[]]$Variants = @("variant-a", "variant-c", "variant-d"),
    [string[]]$Scenarios = @("heavy-body", "join-filter", "mixed", "read-heavy")
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scenarioDirectory = Join-Path $scriptRoot "scenarios"

$scenarioFiles = @{
    "heavy-body" = "heavy-body.jmx"
    "join-filter" = "join-filter.jmx"
    "mixed"      = "mixed.jmx"
    "read-heavy" = "read-heavy.jmx"
}

$variantPorts = @{
    "variant-a" = 8081
    "variant-c" = 8082
    "variant-d" = 8083
}

function Resolve-ScenarioFile($name) {
    if (-not $scenarioFiles.ContainsKey($name)) {
        throw "Unknown scenario '$name'. Available: $($scenarioFiles.Keys -join ', ')"
    }

    $fullPath = Join-Path $scenarioDirectory $scenarioFiles[$name]
    if (-not (Test-Path $fullPath)) {
        throw "Scenario file '$fullPath' is missing."
    }

    return $fullPath
}

function Resolve-VariantPort($variant) {
    if (-not $variantPorts.ContainsKey($variant)) {
        throw "Unknown variant '$variant'. Available: $($variantPorts.Keys -join ', ')"
    }

    return $variantPorts[$variant]
}

Write-Host "Using JMeter executable: $JMeterExecutable"

$resolvedResultsDir = Resolve-Path -Path (Join-Path $scriptRoot $ResultsDirectory) -ErrorAction SilentlyContinue
if (-not $resolvedResultsDir) {
    $resolvedResultsDir = Join-Path $scriptRoot $ResultsDirectory
    Write-Host "Results directory '$resolvedResultsDir' does not exist. Creating it..."
    New-Item -ItemType Directory -Path $resolvedResultsDir | Out-Null
} else {
    $resolvedResultsDir = $resolvedResultsDir.ProviderPath
}

foreach ($variant in $Variants) {
    $port = Resolve-VariantPort $variant
    foreach ($scenario in $Scenarios) {
        $scenarioPath = Resolve-ScenarioFile $scenario
        $resultFile = Join-Path $resolvedResultsDir "$variant-$scenario.jtl"

        Write-Host ""
        Write-Host "=== Running $scenario for $variant (port $port) ===" -ForegroundColor Cyan
        Write-Host "Scenario file: $scenarioPath"
        Write-Host "Result file  : $resultFile"

        & $JMeterExecutable `
            -n `
            -t $scenarioPath `
            -l $resultFile `
            -JvariantHost=localhost `
            -JvariantPort=$port

        if ($LASTEXITCODE -ne 0) {
            throw "JMeter run failed for variant '$variant' scenario '$scenario' with exit code $LASTEXITCODE."
        }
    }
}

Write-Host ""
Write-Host "All requested JMeter scenarios finished successfully." -ForegroundColor Green

