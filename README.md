# SecureSupply-Kyverno

## Kubernetes Software Supply-Chain Security Platform

SecureSupply-Kyverno is a DevSecOps platform that secures the container software supply chain from source code to Kubernetes admission.

The project combines **GitHub Actions, GitLeaks, Trivy, Docker, Amazon ECR, Cosign, CycloneDX SBOM, SLSA provenance, Argo CD, Amazon EKS and Kyverno** to build, scan, attest, deploy and continuously enforce security requirements at the Kubernetes admission layer.

---

## Architecture

```text
                         Developer
                             |
                             v
                         GitHub
                             |
                             v
                    +----------------+
                    |   GitLeaks     |
                    | Secret Scan    |
                    +----------------+
                             |
                             v
                    +----------------+
                    | Docker Build   |
                    +----------------+
                             |
                             v
                    +----------------+
                    |     Trivy      |
                    | Image Security |
                    +----------------+
                             |
                             v
                    +----------------+
                    | CycloneDX SBOM |
                    +----------------+
                             |
                             v
                    +----------------+
                    |   Amazon ECR   |
                    +----------------+
                       /           \
                      /             \
                     v               v
             Cosign Signature    SBOM Attestation
                                      |
                                      v
                              SLSA Provenance
                                      |
                                      v
                                Argo CD / GitOps
                                      |
                                      v
                              Amazon EKS Cluster
                                      |
                                      v
                              +---------------+
                              |    Kyverno    |
                              | Admission     |
                              | Enforcement   |
                              +---------------+
                                      |
                       +--------------+--------------+
                       |                             |
                       v                             v
                  ALLOW WORKLOAD                DENY WORKLOAD
Security Pipeline
GitHub
   |
   +--> GitLeaks
   |
   +--> Python syntax validation
   |
   +--> Kubernetes YAML validation
   |
   +--> Docker build
   |
   +--> Trivy vulnerability scan
   |
   +--> CycloneDX SBOM
   |
   +--> Amazon ECR
          |
          +--> Cosign keyless image signing
          |
          +--> SBOM attestation
          |
          +--> SLSA provenance
          |
          v
       Argo CD
          |
          v
       Amazon EKS
          |
          v
       Kyverno
          |
          +--> Verify image source
          +--> Verify immutable digest
          +--> Verify Cosign signature
          +--> Verify SBOM
          +--> Verify provenance
          +--> Enforce Kubernetes security
Security Controls

Kyverno policies enforce the following controls.

Container Supply Chain
Approved Amazon ECR registry
Immutable image digests
Cosign keyless image signatures
GitHub Actions signing identity validation
CycloneDX SBOM attestation verification
SLSA provenance attestation verification
Pod Security
runAsNonRoot=true
Explicit non-root container user
seccompProfile.type=RuntimeDefault
allowPrivilegeEscalation=false
privileged=false
Drop all Linux capabilities
Prevent capability additions
Read-only root filesystem
No host namespaces
No hostPath volumes
Workload Governance
Explicit ServiceAccount
automountServiceAccountToken=false
Required application labels
Liveness probes
Readiness probes
CPU requests and limits
Memory requests and limits
Network Security
NetworkPolicy required for workloads
Namespace-level governance
Restricted Kubernetes namespace labels
Policy Set

The project contains ten Kyverno enforcement policies:

#	Policy	Purpose
01	Image Source	Restricts images to the approved ECR registry
02	Pod Security	Enforces secure container execution
03	Host Controls	Prevents unsafe host access
04	Resources	Requires CPU and memory requests/limits
05	Workload Governance	Enforces ServiceAccounts, probes and labels
06	NetworkPolicy	Requires network isolation
07	Namespace Governance	Enforces namespace security requirements
08	Cosign Signature	Verifies trusted image signatures
09	SBOM Attestation	Verifies CycloneDX SBOM attestations
10	Provenance Attestation	Verifies SLSA provenance

All policies are designed for enforcement, not audit-only operation.

Repository Structure
SecureSupply-Kyverno/
|
├── .github/
│   └── workflows/
│       └── secure-build.yml
|
├── app/
│   ├── Dockerfile
│   └── application source
|
├── config/
│   └── security.env.example
|
├── docs/
│   ├── architecture.md
│   └── security-model.md
|
├── gitops/
│   └── application.yaml
|
├── k8s/
│   └── Kubernetes workload templates
|
├── kyverno/
│   └── templates/
│       ├── 01-image-source.yaml
│       ├── 02-pod-security.yaml
│       ├── 03-host-controls.yaml
│       ├── 04-resources.yaml
│       ├── 05-governance.yaml
│       ├── 06-networkpolicy.yaml
│       ├── 07-namespace-governance.yaml
│       ├── 08-cosign-signature.yaml
│       ├── 09-sbom-attestation.yaml
│       └── 10-provenance-attestation.yaml
|
├── scripts/
│   └── render.ps1
|
├── security/
│   └── iam/
│       ├── kyverno-ecr-policy.json
│       └── kyverno-trust-policy.json
|
├── tests/
│   ├── good/
│   │   └── secure-pod.yaml
│   └── bad/
│       └── negative-test.yaml
|
├── LICENSE
└── README.md
Configuration

Environment-specific values are intentionally separated from the policy templates.

Create the local configuration:

Copy-Item config/security.env.example config/security.env
notepad config/security.env

Configure values such as:

AWS_ACCOUNT_ID=
AWS_REGION=
ECR_REGISTRY=
ECR_REPOSITORY=
IMAGE_DIGEST=
COSIGN_OIDC_ISSUER=
COSIGN_IDENTITY_REGEXP=
GITHUB_REPOSITORY=
GITHUB_BRANCH=
ALLOWED_ECR_REGISTRY=

Never commit:

config/security.env

Only the example configuration belongs in Git.

Render Kubernetes Manifests

The project uses PowerShell templating to inject environment-specific values into Kubernetes and Kyverno manifests.

Run:

.\scripts\render.ps1

Generated manifests are written to:

generated/

The generated/ directory is intentionally ignored by Git because it contains environment-specific values.

Validate Kubernetes Manifests

Before deployment:

kubectl apply --dry-run=server -f generated/

For a local Kubernetes environment such as Docker Desktop:

kubectl apply -f generated/

For Amazon EKS:

kubectl apply -f generated/

Always verify the target cluster and namespace before applying manifests.

AWS Integration

The platform uses:

AWS
Amazon ECR for container images
Amazon EKS for Kubernetes
IAM for AWS permissions
EKS OIDC / IRSA for Kyverno registry access
GitHub Actions OIDC for CI/CD AWS authentication
Argo CD for GitOps deployment

The repository does not require long-lived AWS access keys to be stored in GitHub.

For GitHub Actions, configure the required repository variables and authentication mechanism according to your AWS OIDC setup.

IAM Design

Kyverno requires read-only access to ECR so that admission policies can verify image signatures and attestations.

The repository provides reusable IAM policy templates under:

security/iam/

These templates intentionally use placeholders rather than environment-specific AWS account and OIDC values.

The Kyverno trust relationship should be restricted to:

system:serviceaccount:kyverno:kyverno-admission-controller
Testing

The repository contains both secure and intentionally insecure workloads.

Valid workload
tests/good/secure-pod.yaml

The secure workload is designed to satisfy the Kyverno policies.

Negative security tests
tests/bad/

Examples cover security violations such as:

Privileged containers
Root execution
Mutable image tags
External registries
HostPath
Host namespaces
Privilege escalation
Missing resource requests/limits
Missing workload governance controls

A violating workload should be rejected by the Kyverno admission layer.

Example:

kubectl apply -f tests/bad/negative-test.yaml

Expected behavior:

admission webhook denied the request

This demonstrates that the policies are actively enforcing security requirements.

CI/CD Security

The GitHub Actions workflow performs:

Repository checkout
GitLeaks secret scanning
Python syntax validation
Kubernetes YAML validation
Docker image build
Trivy vulnerability scanning
CycloneDX SBOM generation
ECR image push
Cosign keyless image signing
SBOM attestation
SLSA provenance generation

The resulting image is referenced by an immutable digest rather than a mutable tag.

Supply-Chain Security Model

The project establishes multiple independent verification layers:

Source
  |
  +--> Secret detection
  |
  v
Build
  |
  +--> Vulnerability scanning
  +--> SBOM
  |
  v
Registry
  |
  +--> Immutable digest
  +--> Signature
  +--> SBOM attestation
  +--> Provenance
  |
  v
Kubernetes
  |
  +--> Kyverno admission
        |
        +--> Registry verification
        +--> Signature verification
        +--> SBOM verification
        +--> Provenance verification
        +--> Runtime security policies

A container therefore has to satisfy both the software supply-chain requirements and the Kubernetes workload security requirements before admission.

Technologies
Cloud
AWS
Amazon ECR
Amazon EKS
AWS IAM
EKS OIDC / IRSA
DevSecOps
GitHub Actions
GitLeaks
Trivy
Docker
Cosign
CycloneDX
SLSA
SBOM
Kubernetes
Kubernetes
Kyverno
Argo CD
NetworkPolicy
ServiceAccounts
Admission Control
Automation
PowerShell
YAML
Git
Project Validation

The implementation has been validated on Amazon EKS with:

Kyverno admission enforcement enabled
ECR-backed immutable container image
Cosign keyless signature verification
CycloneDX SBOM attestation verification
SLSA provenance verification
Secure workload deployment
Negative admission testing

An intentionally privileged workload was rejected by Kyverno because it violated multiple enforced security policies.

This confirms that the project is operating as an enforcement-based admission security platform, rather than only generating policy definitions.

Security Notes

This repository is intended as a production-style learning and portfolio project.

Before production use, review:

ECR repository permissions
AWS IAM least privilege
EKS network architecture
NetworkPolicy behavior with the selected CNI
DNS and required egress
Argo CD RBAC
Kyverno resource sizing
Image vulnerability policy
Signing identity configuration
SBOM/provenance trust configuration
Cluster observability and audit logging

Never commit:

AWS access keys
AWS secret keys
Kubernetes credentials
Private signing keys
Environment-specific secrets
config/security.env
Author

Kaleeswar G

Computer Science & Engineering

DevOps / Cloud / DevSecOps

GitHub:

https://github.com/KaleeswarG25