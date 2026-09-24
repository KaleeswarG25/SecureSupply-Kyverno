from pathlib import Path
import os, re

ROOT = Path(__file__).resolve().parents[1]
ENV_FILE = ROOT / "config" / "security.env"
TEMPLATE_DIR = ROOT / "kyverno" / "templates"
OUT = ROOT / "generated"

def load_env(path):
    values = {}
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        values[k.strip()] = v.strip()
    return values

if not ENV_FILE.exists():
    raise SystemExit("Missing config/security.env. Copy config/security.env.example and fill it first.")

values = load_env(ENV_FILE)
required = [
    "ALLOWED_ECR_REGISTRY", "COSIGN_OIDC_ISSUER", "COSIGN_IDENTITY_REGEXP",
    "ECR_REGISTRY", "ECR_REPOSITORY", "IMAGE_DIGEST"
]
missing = [k for k in required if not values.get(k) or "CHANGE_ME" in values.get(k, "")]
if missing:
    raise SystemExit("Fill these values in config/security.env: " + ", ".join(missing))

OUT.mkdir(exist_ok=True)
for src in sorted(TEMPLATE_DIR.glob("*.yaml")):
    text = src.read_text()
    for key, value in values.items():
        text = text.replace("${" + key + "}", value)
    (OUT / src.name).write_text(text)

# Render the deployment manifest separately.
src = ROOT / "k8s" / "deployment.yaml"
text = src.read_text()
for key, value in values.items():
    text = text.replace("${" + key + "}", value)
(OUT / "deployment.yaml").write_text(text)

print(f"Rendered {len(list(TEMPLATE_DIR.glob('*.yaml')))} Kyverno policies plus deployment into {OUT}")
