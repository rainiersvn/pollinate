# Run the FinSure Risk Scoring API locally with `dotnet run`.
#
# Self-contained: every step is an explicit command echoed before it runs.
# Synthetic payload only (Test User / 9001011234088) - never real PII.
#
#   pwsh ./scripts/Run-Local-Dotnet.ps1
#   pwsh ./scripts/Run-Local-Dotnet.ps1 -ApiKey 'local-dummy-key' -Port 18080
param(
    [string]$ApiKey = 'local-dummy-key',
    [int]$Port = 18080,
    [int]$ReadyWaitSeconds = 60
)

$ErrorActionPreference = 'Stop'
$AppDir = Join-Path $PSScriptRoot '../app'
$BaseUrl = "http://127.0.0.1:$Port"
$Payload = '{"firstName":"Jane","lastName":"Doe","idNumber":"9001011234088"}'

Write-Host 'STEP 1: set vendor key placeholder'
$env:RiskShield__ApiKey = $ApiKey

Write-Host 'STEP 2: start API (background job, explicit command below)'
Write-Host "  dotnet run --project src/FinSure.RiskScoring.Api --urls $BaseUrl"
$job = Start-Job -WorkingDirectory $AppDir -ScriptBlock {
    param($Project, $Urls, $Key)
    $env:RiskShield__ApiKey = $Key
    dotnet run --project $Project --urls $Urls
} -ArgumentList 'src/FinSure.RiskScoring.Api', $BaseUrl, $ApiKey

try {
    Write-Host 'STEP 3: wait for /health/live (bounded poll, explicit GETs)'
    $deadline = (Get-Date).AddSeconds($ReadyWaitSeconds)
    $healthy = $false
    while ((Get-Date) -lt $deadline) {
        try {
            $live = Invoke-WebRequest "$BaseUrl/health/live" -TimeoutSec 5 -SkipHttpErrorCheck
            if ($live.StatusCode -eq 200) { $healthy = $true; break }
        } catch { }
        Start-Sleep -Seconds 2
    }
    if (-not $healthy) { throw "API did not report Healthy within $ReadyWaitSeconds seconds." }

    Write-Host 'STEP 4: health checks (expect 200 Healthy)'
    Invoke-RestMethod "$BaseUrl/health/live"
    Invoke-RestMethod "$BaseUrl/health/ready"

    Write-Host 'STEP 5: validate check (expect 502: api.riskshield.com unreachable, wiring correct)'
    Invoke-WebRequest "$BaseUrl/validate" -Method Post `
        -Body $Payload -ContentType 'application/json' -SkipHttpErrorCheck
} finally {
    Write-Host 'STEP 6: stop API and clear placeholder key from this session'
    Stop-Job $job | Out-Null
    Remove-Job $job -Force | Out-Null
    Remove-Item Env:RiskShield__ApiKey -ErrorAction SilentlyContinue
    Write-Host 'Done.'
}
