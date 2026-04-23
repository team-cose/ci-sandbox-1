# Fail immediately on any error
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Install protoc via the shared cross-platform script. It pins the same version
# used on Linux/macOS and downloads directly from the upstream GitHub release,
# so we avoid the recurring Chocolatey CDN failures.
$ProtocInstallDir = Join-Path $env:RUNNER_TEMP "protoc-bin"
bash scripts/environment/install-protoc.sh "$ProtocInstallDir"
if ($LASTEXITCODE -ne 0) {
    throw "install-protoc.sh failed with exit code $LASTEXITCODE"
}
echo "$ProtocInstallDir" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
