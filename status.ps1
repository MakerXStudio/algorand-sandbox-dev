$isError = $false

Write-Host "=== Algod status"
./goal.ps1 node status
if ($LASTEXITCODE -ne 0) {
  $isError = $true
  Write-Error "Algod not running"
}
Write-Host
Write-Host "=== Indexer status"
try {
  $indexerStatus = Invoke-RestMethod -Method Get "http://localhost:8980/health?pretty"
  Write-Host (ConvertTo-Json $indexerStatus)

  if (-not $indexerStatus.'db-available') {
    throw "Indexer database not running"
  }
} catch {
  $isError = $true
  Write-Error "Indexer not running: $_"
}

if ($isError) {
  exit 1
}

exit 0
