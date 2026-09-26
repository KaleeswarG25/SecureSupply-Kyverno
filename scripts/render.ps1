$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $Root "config\security.env"
$Generated = Join-Path $Root "generated"

if (-not (Test-Path $ConfigFile)) {
    throw "Missing config/security.env"
}

# Load configuration
Get-Content $ConfigFile | ForEach-Object {
    $line = $_.Trim()

    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)

        [Environment]::SetEnvironmentVariable(
            $parts[0].Trim(),
            $parts[1].Trim()
        )
    }
}

$required = @(
    "AWS_ACCOUNT_ID",
    "AWS_REGION",
    "ECR_REGISTRY",
    "ECR_REPOSITORY",
    "IMAGE_DIGEST",
    "COSIGN_OIDC_ISSUER",
    "COSIGN_IDENTITY_REGEXP",
    "GITHUB_REPOSITORY",
    "GITHUB_BRANCH",
    "ALLOWED_ECR_REGISTRY"
)

foreach ($name in $required) {
    $value = [Environment]::GetEnvironmentVariable($name)

    if ([string]::IsNullOrWhiteSpace($value) -or $value -match "CHANGE_ME") {
        throw "Missing or invalid configuration: $name"
    }
}

# Recreate generated directory
if (Test-Path $Generated) {
    Remove-Item $Generated -Recurse -Force
}

New-Item -ItemType Directory -Force $Generated | Out-Null

Write-Host "Rendering Kubernetes manifests..." -ForegroundColor Cyan

# ============================================================
# Kubernetes manifests
# ============================================================

$K8sFiles = Get-ChildItem -Path (Join-Path $Root "k8s") -File |
    Where-Object { $_.Extension -in ".yaml", ".yml" }

foreach ($file in $K8sFiles) {

    $content = Get-Content $file.FullName -Raw

    $content = $content `
        -replace '\$\{ECR_REGISTRY\}', $env:ECR_REGISTRY `
        -replace '\$\{ECR_REPOSITORY\}', $env:ECR_REPOSITORY `
        -replace '\$\{IMAGE_DIGEST\}', $env:IMAGE_DIGEST

    $output = Join-Path $Generated $file.Name

    Set-Content -Path $output -Value $content -Encoding UTF8

    Write-Host "  Rendered: $($file.Name)" -ForegroundColor Green
}

# ============================================================
# Kyverno policy templates
# ============================================================

# IMPORTANT:
# security.env contains regex backslashes such as:
#   https://github\.com/...\.yml
#
# YAML double-quoted strings require those backslashes to be
# escaped as:
#   https://github\\.com/...\\.yml

$CosignIdentityYaml = $env:COSIGN_IDENTITY_REGEXP -replace '\\', '\\'

$KyvernoFiles = Get-ChildItem -Path (Join-Path $Root "kyverno\templates") -File |
    Where-Object { $_.Extension -in ".yaml", ".yml" }

foreach ($file in $KyvernoFiles) {

    $content = Get-Content $file.FullName -Raw

    $content = $content `
        -replace '\$\{AWS_ACCOUNT_ID\}', $env:AWS_ACCOUNT_ID `
        -replace '\$\{AWS_REGION\}', $env:AWS_REGION `
        -replace '\$\{ECR_REGISTRY\}', $env:ECR_REGISTRY `
        -replace '\$\{ECR_REPOSITORY\}', $env:ECR_REPOSITORY `
        -replace '\$\{IMAGE_DIGEST\}', $env:IMAGE_DIGEST `
        -replace '\$\{COSIGN_OIDC_ISSUER\}', $env:COSIGN_OIDC_ISSUER `
        -replace '\$\{COSIGN_IDENTITY_REGEXP\}', $CosignIdentityYaml `
        -replace '\$\{GITHUB_REPOSITORY\}', $env:GITHUB_REPOSITORY `
        -replace '\$\{GITHUB_BRANCH\}', $env:GITHUB_BRANCH `
        -replace '\$\{ALLOWED_ECR_REGISTRY\}', $env:ALLOWED_ECR_REGISTRY

    $output = Join-Path $Generated $file.Name

    Set-Content -Path $output -Value $content -Encoding UTF8

    Write-Host "  Rendered: $($file.Name)" -ForegroundColor Green
}

# ============================================================
# Final output
# ============================================================

Write-Host ""
Write-Host "Rendering complete." -ForegroundColor Green
Write-Host ""
Write-Host "Generated files:" -ForegroundColor Cyan

Get-ChildItem -Path $Generated -File |
    Select-Object -ExpandProperty Name