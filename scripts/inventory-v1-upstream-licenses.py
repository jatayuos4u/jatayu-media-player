#!/usr/bin/env python3
"""Inventory licenses within already verified pinned upstream archives.
Read only: does not alter packages or approve redistribution.
"""
from pathlib import Path
import tarfile

root=Path(__file__).resolve().parents[1]/"dist/v1-upstream-source-review"
if not root.is_dir():
    raise SystemExit("Source review folder missing: first run collect-v1-upstream-sources.py")
out=root/"LICENSE-FILE-INVENTORY.tsv"
rows=["module\tarchive-or-directory\tlicense-file-path"]
keys=("license","copying","copyright","notice")
for module in ("libmpv","luajit","libass","uchardet","libplacebo"):
    folder=root/module
    if not folder.is_dir():
        print("MISSING module directory:",module)
        continue
    for archive in sorted(folder.glob("*.tar.gz")):
        try:
            with tarfile.open(archive,"r:gz") as tf:
                matches=[m.name for m in tf.getmembers() if m.isfile() and any(m.name.rsplit("/",1)[-1].lower().startswith(k) for k in keys)]
            for path in matches:
                rows.append(f"{module}\t{archive.name}\t{path}")
        except tarfile.TarError as exc:
            print("BAD ARCHIVE",archive,exc)
    tree=folder/"git-source"
    if tree.is_dir():
        for path in tree.rglob("*"):
            if path.is_file() and ".git" not in path.parts and any(path.name.lower().startswith(k) for k in keys):
                rows.append(f"{module}\tgit-source\t{path.relative_to(tree)}")
out.write_text("\n".join(rows)+"\n",encoding="utf-8")
print("Found",len(rows)-1,"candidate license/notice files.")
print("Saved:",out)
for row in rows[:100]:
    print(row)
if len(rows)>100: print("... additional records saved to inventory")
print("CAUTION: file names alone cannot determine effective licensing or binary build configuration.")
