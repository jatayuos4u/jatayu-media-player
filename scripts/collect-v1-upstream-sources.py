#!/usr/bin/env python3
"""Collect exact external sources pinned in Flatpak manifests for manual review.
Does not publish, alter the release binaries, or certify licensing compliance.
"""
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys
import tarfile
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "dist" / "v1-upstream-source-review"
MANIFEST = ROOT / "flatpak" / "libmpv.json"

def run(*args, cwd=None):
    subprocess.run(args, cwd=cwd, check=True)

def safe(name):
    return "".join(c if c.isalnum() or c in "-._" else "_" for c in name)

def main():
    m = json.loads(MANIFEST.read_text())
    DEST.mkdir(parents=True, exist_ok=True)
    records = []
    for module in [m] + m.get("modules", []):
        name = safe(module["name"])
        target = DEST / name
        target.mkdir(exist_ok=True)
        for idx, source in enumerate(module.get("sources", [])):
            typ = source.get("type")
            if typ == "archive":
                url = source["url"]
                extension = ".tar.gz" if url.endswith((".tar.gz", ".tgz")) else ".archive"
                dest = target / (f"{idx}-upstream" + extension)
                if not dest.is_file():
                    print("Fetching", name, url, flush=True)
                    urllib.request.urlretrieve(url, dest)
                actual = hashlib.sha256(dest.read_bytes()).hexdigest()
                if actual != source["sha256"]:
                    dest.unlink(missing_ok=True)
                    raise ValueError(f"Hash mismatch for {name}")
                records.append((name, "archive", url, source["sha256"]))
            elif typ == "git":
                gitpath = target / "git-source"
                if not (gitpath / ".git").exists():
                    run("git", "clone", "--no-checkout", source["url"], str(gitpath))
                run("git", "fetch", "origin", source["commit"], cwd=gitpath)
                run("git", "checkout", "--detach", source["commit"], cwd=gitpath)
                actual = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=gitpath, text=True).strip()
                if actual != source["commit"]:
                    raise ValueError(f"Revision mismatch for {name}")
                run("git", "archive", "--format=tar.gz", "-o", str(target / "pinned-upstream.tar.gz"), actual, cwd=gitpath)
                records.append((name, "git", source["url"], actual))
            elif typ == "patch":
                p = ROOT / "flatpak" / source["path"]
                if not p.is_file():
                    raise FileNotFoundError(p)
                shutil.copy2(p, target / p.name)
                records.append((name, "patch", str(p.relative_to(ROOT)), hashlib.sha256(p.read_bytes()).hexdigest()))
            elif typ == "shell":
                (target / f"{idx}-build-commands.txt").write_text("\n".join(source["commands"]) + "\n")
                records.append((name, "shell modification", "manifest commands", "review required"))
            else:
                raise ValueError(f"Unexpected source type: {typ}")
    (DEST / "SOURCE-INVENTORY.tsv").write_text("module\ttype\tsource\trevision-or-hash\n" + "".join("\t".join(x) + "\n" for x in records))
    shutil.copy2(MANIFEST, DEST / "libmpv-manifest.json")
    print("Collected original upstream source records in", DEST)
    print("NOT verified: licensing compatibility, complete transitive bundled dependencies, or corresponding-source completeness.")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print("COLLECTION INCOMPLETE:", exc, file=sys.stderr)
        sys.exit(1)
