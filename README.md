# SecureSupply-Kyverno

Kubernetes software supply-chain security project using GitHub Actions, GitLeaks, Trivy, Syft, Cosign, Amazon ECR, Argo CD, EKS and Kyverno.

## Security chain

GitHub -> GitLeaks -> build -> Trivy -> Syft SBOM -> ECR -> Cosign signature/attestations -> Argo CD -> EKS -> Kyverno admission.

Kyverno enforces:

- approved Amazon ECR registry
- immutable image digests
- Cosign keyless signatures from the configured GitHub Actions workflow
- signed SBOM attestation
- signed SLSA provenance attestation
- non-root at pod and container level
- RuntimeDefault seccomp
- allowPrivilegeEscalation=false
- privileged=false
- drop ALL capabilities
- no added capabilities
- read-only root filesystem
- no hostNetwork/hostPID/hostIPC
- no hostPath
- CPU and memory requests/limits
- explicit ServiceAccount
- automountServiceAccountToken=false
- required application labels
- NetworkPolicy governance
- liveness/readiness probes
- restricted namespace labels

## Configuration

Never hard-code account IDs, ECR URLs, image digests or signing identities.

```powershell
Copy-Item config/security.env.example config/security.env
notepad config/security.env
```

Then validate the rendered manifests against the target cluster:

```powershell
kubectl apply --dry-run=server -f generated/
```

The generated directory is intentionally ignored by Git because it contains environment-specific values. Commit the templates and the example configuration, not real secrets.

## AWS/GitHub values

Set GitHub repository variable values:

- AWS_REGION
- ECR_REGISTRY
- ECR_REPOSITORY

Set GitHub secret:

- AWS_ROLE_TO_ASSUME

Use GitHub OIDC for AWS authentication; do not create long-lived AWS access keys in GitHub.

## Important

The repository contains the complete policy model, but ECR identity, AWS account details, image digest and GitHub OIDC identity are environment-specific. Fill `config/security.env` before rendering.

The NetworkPolicy shown is a baseline example. Adjust DNS and application egress for your actual cluster networking/CNI before production rollout.

## Attack tests

The `tests/bad/` directory intentionally contains insecure examples for admission testing:

- privileged
- root
- latest tag
- external registry
- hostPath
- hostNetwork
- privilege escalation
- missing resources

A valid workload is in `tests/good/secure-pod.yaml`.

