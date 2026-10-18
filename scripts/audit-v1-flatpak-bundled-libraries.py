#!/usr/bin/env python3
"""Read-only inspection of deployed Flatpak shared libraries against pinned source review.
The output is evidence for human review, not legal certification.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import tarfile

root=Path(__file__).resolve().parents[1]
deployment=root/"flatpak-build/files"
manifest=json.loads((root/"flatpak/libmpv.json").read_text())
stage=root/"dist/release-candidate-1.0.0-theme-fixed"
archive=stage/"jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz"
if not deployment.is_dir() or not archive.is_file():
    sys.exit("MISSING: flatpak-build/files or corrected corresponding-source archive")
modules={m["name"] for m in [manifest]+manifest.get("modules",[])}
prefixes={"libmpv":"libmpv.so","luajit":"libluajit-","libass":"libass.so","uchardet":"libuchardet.so","libplacebo":"libplacebo.so"}
with tarfile.open(archive,"r:gz") as tf:
    entries=[m.name for m in tf.getmembers() if m.isfile()]
for name in sorted(modules):
    present=any(f"/upstreams/{name}/" in x for x in entries)
    print(("SOURCE_PRESENT" if present else "SOURCE_MISSING"),name)
libraries=[]
for p in (deployment/"lib").rglob("*"):
    if p.is_file() and (".so" in p.name or p.name.endswith(".a")):
        libraries.append(p)
print("LIBRARIES IN APP DEPLOYMENT:",len(libraries))
unexpected=[]
for p in sorted(libraries):
    name=p.name
    matches=[k for k,prefix in prefixes.items() if name.startswith(prefix)]
    kind=",".join(matches) if matches else "UNMAPPED/REQUIRES REVIEW"
    print("APP_LIBRARY",str(p.relative_to(deployment)),kind)
    if not matches: unexpected.append(str(p.relative_to(deployment)))
print("UNMAPPED LIBRARIES:",len(unexpected))
print("NOTE: runtime-provided FFmpeg/Qt/KDE libraries are not included in this app-only list.")
print("NOTE: license texts, compiled build flags and complete corresponding source require human review.")
if unexpected:
    sys.exit("REVIEW REQUIRED: unmapped bundled libraries")
print("PASS: all enumerated app shared libraries map by filename to declared source modules; NOT legal clearance.")
