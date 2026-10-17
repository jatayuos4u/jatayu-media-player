#!/usr/bin/env python3
"""Extract review copies of upstream licensing files without extracting untrusted paths.
Not legal approval. Keeps original verified source archives unchanged.
"""
from pathlib import Path
import csv
import tarfile
import shutil

root=Path(__file__).resolve().parents[1]/"dist/v1-upstream-source-review"
index=root/"LICENSE-FILE-INVENTORY.tsv"
if not index.exists():
    raise SystemExit("Run scripts/inventory-v1-upstream-licenses.py first.")
dest=root/"license-review"
dest.mkdir(parents=True,exist_ok=True)
copied=0
with index.open(newline="",encoding="utf-8") as f:
    for rec in csv.DictReader(f,delimiter="\t"):
        module,source,name=rec["module"],rec["archive-or-directory"],rec["license-file-path"]
        if not module or not name: continue
        relative=Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"Unsafe path: {name}")
        destpath=dest/module/source/relative
        destpath.parent.mkdir(parents=True,exist_ok=True)
        if source=="git-source":
            origin=(root/module/source/relative).resolve()
            directory=(root/module/source).resolve()
            if not origin.is_relative_to(directory) or not origin.is_file():
                raise ValueError(f"Unsafe source path: {name}")
            shutil.copyfile(origin,destpath)
        else:
            archive=root/module/source
            with tarfile.open(archive,"r:gz") as tf:
                member=tf.getmember(name)
                if not member.isfile():
                    raise ValueError(f"Not regular file: {name}")
                handle=tf.extractfile(member)
                if handle is None: raise ValueError(f"Missing data: {name}")
                with handle, destpath.open("wb") as output:
                    shutil.copyfileobj(handle,output)
        copied+=1
print(f"Extracted {copied} identified notice/license files into {dest}")
print("Review and preserve full texts, project-specific attribution, build options and transitive dependencies before distribution.")
