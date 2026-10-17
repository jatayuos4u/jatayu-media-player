#!/usr/bin/env python3
"""Prepare offline corresponding-source REVIEW bundle from already verified source files.
No binary rebuild, tag, upload or legal certification.
"""
from pathlib import Path
import hashlib
import json
import shutil
import tarfile

root=Path(__file__).resolve().parents[1]
source=root/"dist/v1-upstream-source-review"
release=root/"dist/release-candidate-1.0.0"
if not source.is_dir() or not release.is_dir():
    raise SystemExit("Missing upstream source review or staged release directory")
manifest=json.loads((root/"flatpak/libmpv.json").read_text())
required=[manifest]+manifest["modules"]
copies=[]
for component in required:
    name=component["name"]
    base=source/name
    for item in component["sources"]:
        kind=item["type"]
        if kind=="archive":
            filename=base/"0-upstream.tar.gz"
            if not filename.is_file() or hashlib.sha256(filename.read_bytes()).hexdigest()!=item["sha256"]:
                raise SystemExit(f"Missing/incorrect verified source archive for {name}")
            copies.append((filename,f"upstreams/{name}/{filename.name}"))
        elif kind=="git":
            filename=base/"pinned-upstream.tar.gz"
            if not filename.is_file():
                raise SystemExit(f"Missing pinned Git archive: {name}")
            copies.append((filename,f"upstreams/{name}/{filename.name}"))
            checkout=base/"git-source"
            if not checkout.is_dir():
                raise SystemExit(f"Missing checkout: {name}")
            import subprocess
            head=subprocess.check_output(["git","-C",str(checkout),"rev-parse","HEAD"],text=True).strip()
            if head!=item["commit"]:
                raise SystemExit(f"Git revision mismatch: {name}")
        elif kind=="patch":
            p=root/"flatpak"/item["path"]
            if not p.is_file(): raise SystemExit(f"Missing patch {p}")
            copies.append((p,f"project-patches/{p.name}"))
        elif kind=="shell":
            pass # preserved verbatim in original build manifest
        else:
            raise SystemExit(f"Unsupported manifest source kind: {kind}")
for path,target in [
    (root/"flatpak/libmpv.json","build-manifests/libmpv.json"),
    (root/"flatpak/io.github.jatayuos4u.JatayuMediaPlayer.json","build-manifests/application.json"),
    (root/"THIRD_PARTY_NOTICES.md","THIRD_PARTY_NOTICES.md"),
    (source/"SOURCE-INVENTORY.tsv","SOURCE-INVENTORY.tsv"),
    (release/"jatayu-media-player-1.0.0-source.tar.gz","jatayu-media-player-1.0.0-source.tar.gz"),
    (release/"SOURCE-COMMIT.txt","SOURCE-COMMIT.txt"),
]:
    if not path.is_file(): raise SystemExit(f"Missing: {path}")
    copies.append((path,target))
# Distinct full texts as provided in verified pinned sources (including demo license)
licenses=source/"license-review"
if not licenses.is_dir(): raise SystemExit("Missing extracted license review")
for p in sorted(licenses.rglob("*")):
    if p.is_file():
        copies.append((p,"license-texts/"+str(p.relative_to(licenses))))
archive=release/"jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz"
with tarfile.open(archive,"w:gz") as tf:
    for p,target in copies:
        tf.add(p,arcname="jatayu-media-player-1.0.0-sources/"+target,recursive=False)
digest=hashlib.sha256(archive.read_bytes()).hexdigest()
print("Prepared review archive:",archive)
print("SHA256:",digest)
print("Contains",len(copies),"source, manifest, patch and notice entries.")
print("NOT FULLY CLEARED: check all built components/embedded sources, notices, license compatibility, asset rights and source offer.")
print("No release was published.")
