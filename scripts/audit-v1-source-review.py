#!/usr/bin/env python3
"""Read-only audit of pinned uchardet source licensing and source-review archive.
Reports incomplete/unknown findings rather than assuming legal compliance.
"""
from pathlib import Path
import csv
import re
import tarfile
import hashlib
import sys

root=Path(__file__).resolve().parents[1]
src=root/"dist/uchardet-license-check/uchardet-v0.0.7/src"
archive=root/"dist/release-candidate-1.0.0/jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz"
if not src.is_dir() or not archive.is_file():
    sys.exit("MISSING: uchardet extracted src or corresponding-source review archive")
files=[p for p in src.rglob("*") if p.is_file() and p.suffix.lower() in (".c",".cpp",".h",".hpp",".cc")]
unknown=[]
tri=[]
for p in files:
    head=p.read_text(encoding="utf-8",errors="replace")[:2800]
    if re.search(r"MPL\\s*1\\.1\\s*/\\s*GPL|Alternatively, the contents of this file may be used",head,re.I):
        tri.append(str(p.relative_to(src)))
    elif re.search(r"GPL|LGPL|MIT|ISC|BSD|public domain|copyright|mozilla public license",head,re.I):
        unknown.append((str(p.relative_to(src)),"license wording requires inspection"))
    else:
        unknown.append((str(p.relative_to(src)),"no recognized license header in first 2800 characters"))
with tarfile.open(archive,"r:gz") as tf:
    members=[m.name for m in tf.getmembers() if m.isfile()]
expected=("upstreams/libmpv/","upstreams/luajit/","upstreams/libass/","upstreams/uchardet/","upstreams/libplacebo/","license-texts/","build-manifests/","project-patches/","jatayu-media-player-1.0.0-source.tar.gz")
missing=[x for x in expected if not any(x in n for n in members)]
print(f"uchardet source/header files: {len(files)}")
print(f"Explicit tri-license matches: {len(tri)}")
print(f"Not established by scanner: {len(unknown)}")
for name,reason in unknown[:35]: print("NEEDS REVIEW",name,reason)
if len(unknown)>35: print(f"... {len(unknown)-35} additional files need review")
print(f"Archive members: {len(members)}")
print("Review-archive SHA256:",hashlib.sha256(archive.read_bytes()).hexdigest())
for x in missing: print("MISSING EXPECTED ARCHIVE ENTRY:",x)
print("No binaries rebuilt or release published.")
if missing: sys.exit(2)
print("Structural review passed; legal/source completeness NOT certified.")
