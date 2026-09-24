$ErrorActionPreference = "Stop"

function Commit-Step($message, $paths) {
    git add -- $paths
    if ((git diff --cached --quiet) -eq $false) {
        git commit -m $message
    }
}

Commit-Step "chore: initialize SecureSupply project" @(".gitignore","LICENSE","README.md")
Commit-Step "feat: add secure Python application" @("app")
Commit-Step "feat: add Kubernetes workload manifests" @("k8s")
Commit-Step "feat: add Kyverno image source policy" @("kyverno/templates/01-image-source.yaml")
Commit-Step "feat: add Kyverno pod security policy" @("kyverno/templates/02-pod-security.yaml")
Commit-Step "feat: add Kyverno host protection policy" @("kyverno/templates/03-host-controls.yaml")
Commit-Step "feat: add Kyverno resource governance" @("kyverno/templates/04-resources.yaml")
Commit-Step "feat: add Kyverno workload governance" @("kyverno/templates/05-governance.yaml")
Commit-Step "feat: add Kyverno network policy governance" @("kyverno/templates/06-networkpolicy.yaml")
Commit-Step "feat: add Kyverno namespace governance" @("kyverno/templates/07-namespace-governance.yaml")
Commit-Step "feat: add Cosign signature admission policy" @("kyverno/templates/08-cosign-signature.yaml")
Commit-Step "feat: add SBOM admission policy" @("kyverno/templates/09-sbom-attestation.yaml")
Commit-Step "feat: add provenance admission policy" @("kyverno/templates/10-provenance-attestation.yaml")
Commit-Step "test: add secure and insecure admission fixtures" @("tests")
Commit-Step "ci: add secure supply chain workflow" @(".github/workflows/secure-build.yml")
Commit-Step "feat: add environment rendering and validation" @("config/security.env.example","scripts")
Commit-Step "feat: add Argo CD GitOps application" @("gitops/application.yaml")
Commit-Step "docs: add policy matrix and deployment guide" @("docs")

Write-Host "Commit history created. Review with: git log --oneline --decorate -20"
