#!/usr/bin/env python3
"""Audit archived sources and complete notice documents for the corrected v1.0.0.
Read-only; does not declare legal compliance or mutate built artifacts.
"""
from pathlib import Path
import hashlib, io, json, tarfile, sys

root=Path(__file__).resolve().parents[1]
outer=root/"dist/release-candidate-1.0.0-theme-fixed/jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz"
manifest=json.loads((root/"flatpak/libmpv.json").read_text())
filespec={
 "libmpv":("Copyright","LICENSE.GPL","LICENSE.LGPL"),
 "libass":("COPYING",),
 "uchardet":("COPYING",),
 "luajit":("COPYRIGHT",),
 "libplacebo":("LICENSE",),
}
issues=[]
if not outer.is_file():sys.exit("MISSING source review archive; run stage-v1-theme-fixed-candidate.sh")
with tarfile.open(outer,"r:gz") as z:
 members={m.name:m for m in z if m.isfile()}
 def lookup(key):
  hits=[m for name,m in members.items() if name.endswith("/"+key)]
  if len(hits)!=1:
   issues.append("Expected exactly one "+key+"; found "+str(len(hits)))
   return None
  return hits[0]
 for name in filespec:
  arc=lookup("upstreams/"+name+("/0-upstream.tar.gz" if name in ("libmpv","libass","uchardet") else "/pinned-upstream.tar.gz"))
  if arc is None:continue
  with tarfile.open(fileobj=io.BytesIO(z.extractfile(arc).read()),mode="r:gz") as nested:
   paths=[m.name for m in nested if m.isfile()]
  print("SOURCE",name,"archive file entries",len(paths))
  for license_file in filespec[name]:
   hits=[p for p in paths if p.endswith("/"+license_file) or p==license_file]
   if not hits:issues.append(name+" lacks "+license_file)
   else:print("LICENSE_TEXT_PRESENT",name,license_file)
 for n in ("THIRD_PARTY_NOTICES.md","build-manifests/libmpv.json","build-manifests/application.json","jatayu-media-player-1.0.0-source.tar.gz","SOURCE-COMMIT.txt"):
  lookup(n)
 print("BUNDLE_FILES",len(members))
 print("ARCHIVE_SHA256",hashlib.sha256(outer.read_bytes()).hexdigest())
 print("SOURCE-REVIEW", "FAIL" if issues else "STRUCTURAL CHECK PASS")
 for x in issues:print("MISSING/REVIEW",x)
 print("LEGAL STATUS: REQUIRES HUMAN REVIEW of individual terms, effective build flags and source obligations.")
 if issues:sys.exit(2)
