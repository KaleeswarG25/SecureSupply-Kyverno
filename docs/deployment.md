# Deployment sequence

1. Install Kyverno 1.19+ in the EKS cluster.
2. Configure the Kyverno admission controller IAM permissions needed to pull from private ECR.
3. Fill `config/security.env`.
4. Render policies.
5. Validate with `kubectl apply --dry-run=server -f generated/`.
6. Configure GitHub repository variables and the AWS OIDC role.
7. Run the secure-build workflow.
8. Confirm the image is signed and has SBOM/provenance attestations.
9. Point Argo CD at `gitops/application.yaml`.
10. Argo CD applies the rendered workload.
11. Kyverno verifies the image and Pod security controls at admission.

Do not switch every policy to Deny in a shared production cluster without first testing them against all platform/system workloads. Scope the policies to the namespaces/workloads your platform team owns if necessary.
