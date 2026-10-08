# Run the FinSure Risk Scoring API locally in Docker.
#
# Self-contained: every step is an explicit command echoed before it runs.
# Build context is app/ (matches app/Dockerfile). Container port is 8080;
# host port defaults to 18080. Synthetic payload only - never real PII.
#
#   pwsh ./scripts/Run-Local-Docker.ps1
#   pwsh ./scripts/Run-Local-Docker.ps1 -Port 18080 -SkipCleanup
param(
    [string]$ApiKey = 'local-dummy-key',
    [string]$ImageTag = 'finsure-risk-scoring:local',
    [string]$ContainerName = 'finsure-local',
    [int]$Port = 18080,
    [int]$ReadyWaitSeconds = 90,
    [switch]$SkipCleanup
)

$ErrorActionPreference = 'Stop'
$AppDir = Join-Path $PSScriptRoot '../app'
$BaseUrl = "http://127.0.0.1:$Port"
$Payload = '{"firstName":"Jane","lastName":"Doe","idNumber":"9001011234088"}'

Push-Location $AppDir
try {
    Write-Host "STEP 1: build image (explicit command below)"
    Write-Host "  docker build -f Dockerfile -t $ImageTag ."
    docker build -f Dockerfile -t $ImageTag .

    Write-Host 'STEP 2: run container (explicit command below)'
    Write-Host "  docker run -d --name $ContainerName -p ${Port}:8080 -e RiskShield__ApiKey=$ApiKey $ImageTag"
    docker run -d --name $ContainerName -p "${Port}:8080" -e "RiskShield__ApiKey=$ApiKey" $ImageTag | Out-Null

    Write-Host 'STEP 3: confirm non-root user (expect: app)'
    docker exec $ContainerName whoami

    Write-Host 'STEP 4: wait for /health/live (bounded poll, explicit GETs)'
    $deadline = (Get-Date).AddSeconds($ReadyWaitSeconds)
    $healthy = $false
    while ((Get-Date) -lt $deadline) {
        try {
            $live = Invoke-WebRequest "$BaseUrl/health/live" -TimeoutSec 5 -SkipHttpErrorCheck
            if ($live.StatusCode -eq 200) { $healthy = $true; break }
        } catch { }
        Start-Sleep -Seconds 3
    }
    if (-not $healthy) { throw "API did not report Healthy within $ReadyWaitSeconds seconds." }

    Write-Host 'STEP 5: health checks (expect 200 Healthy)'
    Invoke-RestMethod "$BaseUrl/health/live"
    Invoke-RestMethod "$BaseUrl/health/ready"

    Write-Host 'STEP 6: validate check (expect 502: api.riskshield.com unreachable, wiring correct)'
    Invoke-WebRequest "$BaseUrl/validate" -Method Post `
        -Body $Payload -ContentType 'application/json' -SkipHttpErrorCheck

    Write-Host 'STEP 7: PII log check (expect 0 matches: idNumber value never logged)'
    $piiHits = docker logs $ContainerName 2>&1 | Select-String '9001011234088'
    if ($piiHits) { throw "PII LEAK: idNumber value found in container logs." }
    Write-Host '  0 matches - log redaction holds.'
} finally {
    Pop-Location
    if ($SkipCleanup) {
        Write-Host "STEP 8: skipped cleanup (-SkipCleanup). Remove manually:"
        Write-Host "  docker rm -f $ContainerName"
    } else {
        Write-Host 'STEP 8: cleanup (explicit command below)'
        Write-Host "  docker rm -f $ContainerName"
        docker rm -f $ContainerName | Out-Null
        Write-Host 'Done.'
    }
}
