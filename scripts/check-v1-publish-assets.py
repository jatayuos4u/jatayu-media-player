#!/usr/bin/env python3
"""Final immutable release-asset audit; never publishes or modifies files."""
import hashlib
import json
import tarfile
from pathlib import Path

root=Path(__file__).resolve().parents[1]
staged=root/"dist/release-candidate-1.0.0-theme-fixed"
expected={
 "jatayu-media-player_1.0.0_x86_64.deb":"f6a763dcffac6376b47d8d69eefbfe319c35f91834843612284a1fd0ae6980ee",
 "io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak":"42b5139bd5aeb3e6a0096b1d9f60f4233d1be534a5ce8078e36ec6acd142490b",
 "jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz":"cd9aaca96d5d1af7aeb4cfcd4430ee35981dd282ca67d9e70865019bcf51c180"
}
errors=[]
for filename,digest in expected.items():
 p=staged/filename
 if not p.is_file():
  errors.append("MISSING "+filename)
  continue
 h=hashlib.file_digest(p.open("rb"),"sha256").hexdigest()
 print(("PASS" if h==digest else "FAIL")+" SHA256 "+filename+" "+h)
 if h!=digest: errors.append("HASH MISMATCH "+filename)
p=staged/"SOURCE-COMMIT.txt"
if not p.is_file() or p.read_text().strip()!="3d6ba15be78e4555d5f81267c92a21fe62caf702":
 errors.append("Source-commit identifier mismatch")
else: print("PASS source-commit identity")
manifest=json.loads((root/"flatpak/libmpv.json").read_text())
opts=manifest.get("config-opts",[])
mode=next((x for x in opts if x.startswith("-Dgpl=")),None)
print("mpv GPL config in build manifest:",mode or "NOT EXPLICIT: upstream default expected; build binary option UNVERIFIED")
if manifest["name"]!="libmpv":errors.append("Unexpected libmpv manifest")
source=staged/"jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz"
if source.is_file():
 with tarfile.open(source,"r:gz") as t:
  entries=[m.name for m in t.getmembers() if m.isfile()]
  required=["upstreams/libmpv/","upstreams/luajit/","upstreams/libass/","upstreams/uchardet/","upstreams/libplacebo/","license-texts/","build-manifests/","project-patches/","jatayu-media-player-1.0.0-source.tar.gz"]
  for prefix in required:
   if not any(prefix in entry for entry in entries):errors.append("Missing review archive entry "+prefix)
  print("REVIEW archive files:",len(entries))
print("Compliance status: NOT AUTOMATICALLY CLEARED. Copyright, exact compiled options and source-offer obligations require sign-off.")
if errors:
 for e in errors:print("BLOCKER",e)
 raise SystemExit(2)
print("PASS immutable release-asset checks; safe for manual compliance review (NOT publication authorization).")
