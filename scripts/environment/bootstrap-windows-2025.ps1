# Fail immediately on any error
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Helper: download a file with exponential backoff retry.
function Invoke-DownloadWithRetry {
    param(
        [string]$Url,
        [string]$Destination,
        [int]$MaxRetries = 5
    )

    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
            return
        } catch {
            if ($attempt -lt $MaxRetries) {
                $delay = 5 * [math]::Pow(2, $attempt)  # 10, 20, 40, 80 seconds
                Write-Host "Download of $Url failed (attempt $attempt of $MaxRetries): $($_.Exception.Message). Retrying in $delay seconds..."
                Start-Sleep -Seconds $delay
            } else {
                throw "Download of $Url failed after $MaxRetries attempts: $($_.Exception.Message)"
            }
        }
    }
}

# Install protoc directly from the upstream GitHub release. This matches the
# pinned version used on Linux/macOS in the Vector repo
# (scripts/environment/install-protoc.sh) and avoids the recurring Chocolatey
# CDN failures.
$ProtocVersion = "21.12"
$ProtocDir = Join-Path $env:RUNNER_TEMP "protoc"
$ProtocZip = Join-Path $env:RUNNER_TEMP "protoc.zip"
$ProtocUrl = "https://github.com/protocolbuffers/protobuf/releases/download/v${ProtocVersion}/protoc-${ProtocVersion}-win64.zip"

Write-Host "Downloading protoc v${ProtocVersion} from ${ProtocUrl}"
Invoke-DownloadWithRetry -Url $ProtocUrl -Destination $ProtocZip
Expand-Archive -Path $ProtocZip -DestinationPath $ProtocDir -Force
echo "$ProtocDir\bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append

# GNU make ships with the pre-installed MSYS2 toolchain at C:\msys64\usr\bin,
# but that directory is not on PATH by default. Add it so `make` resolves.
echo "C:\msys64\usr\bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
