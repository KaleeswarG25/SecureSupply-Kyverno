# Kyverno policy matrix

| Control | Policy |
|---|---|
| ECR registry | 01-image-source |
| Digest only | 01-image-source |
| Cosign signature | 08-cosign-signature |
| SBOM attestation | 09-sbom-attestation |
| SLSA provenance | 10-provenance-attestation |
| Non-root | 02-pod-security |
| Seccomp | 02-pod-security |
| No privilege escalation | 02-pod-security |
| No privileged | 02-pod-security |
| Drop ALL | 02-pod-security |
| No added capabilities | 03-host-controls |
| Read-only root FS | 02-pod-security |
| No hostNetwork | 03-host-controls |
| No hostPID | 03-host-controls |
| No hostIPC | 03-host-controls |
| No hostPath | 03-host-controls |
| CPU/memory resources | 04-resources |
| Explicit ServiceAccount | 05-governance |
| Disable token automount | 05-governance |
| Required labels | 05-governance |
| Probes | 05-governance |
| NetworkPolicy structure | 06-networkpolicy |
| Namespace security label | 07-namespace-governance |
