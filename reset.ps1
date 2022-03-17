<#
    .SYNOPSIS
        Algorand Sandbox reset.
    .DESCRIPTION
        This tears down and reinstalls the dev environment.
    .EXAMPLE
        ./reset.ps1
        This resets and recreates everything, but prompts you for confirmation first
        ./reset.ps1 -Confirm
        This resets and recreates everything without prompting
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'high')]
Param()

#Requires -Version 7.0.0
Set-StrictMode -Version "Latest"
$ErrorActionPreference = "Stop"

function Test-ThrowIfNotSuccessful() {
  if ($LASTEXITCODE -ne 0) {
    throw "Error executing last command"
  }
}

function Write-Header([string] $title) {
  Write-Host
  Write-Host "#########################"
  Write-Host "### $title"
  Write-Host "#########################"
  Write-Host
}

function Remove-Folder([string] $foldername) {
  if (Test-Path $foldername) { Remove-Item -LiteralPath $foldername -Force -Recurse }
}

if ($PSCmdlet.ShouldProcess("Reset Algorand dev environment")) {

  Write-Header "Stopping containers"
  docker-compose stop
  Test-ThrowIfNotSuccessful
  Write-Header "Deleting containers"
  docker-compose down
  Test-ThrowIfNotSuccessful
  docker-compose rm -f
  Test-ThrowIfNotSuccessful
  Write-Header "Restarting containers"
  docker-compose up -d
  Test-ThrowIfNotSuccessful  
}
