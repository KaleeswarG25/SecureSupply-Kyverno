from pathlib import Path

p = Path("config/security.env")
if not p.exists():
    raise SystemExit("config/security.env is missing. Copy config/security.env.example first.")

bad=[]
for i,line in enumerate(p.read_text().splitlines(),1):
    if "CHANGE_ME" in line:
        bad.append(i)
if bad:
    raise SystemExit(f"CHANGE_ME remains in config/security.env at lines: {bad}")
print("Security configuration is populated.")
