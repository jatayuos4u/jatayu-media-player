#!/usr/bin/env bash
# Final release operation: explicit owner sign-off required; no rebuild.
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="jatayuos4u/jatayu-media-player"
EXPECTED="3d6ba15be78e4555d5f81267c92a21fe62caf702"
[[ "${PUBLISH_APPROVED:-}" == YES ]] || { echo "STOP: set PUBLISH_APPROVED=YES only after accepting the remaining documented compliance review risk." >&2; exit 2; }
[[ "${COMPLIANCE_REVIEW_COMPLETED:-}" == YES ]] || { echo "STOP: compliance/source review has not been signed off." >&2; exit 2; }
command -v gh >/dev/null
gh auth status >/dev/null
python3 scripts/check-v1-publish-assets.py
# Check existing draft, expected target and uploaded asset hashes directly via GitHub.
gh api "repos/$REPO/releases" --paginate --jq '.[] | select(.tag_name == "v1.0.0") | [.id,.draft,.target_commitish] | @tsv' |
while IFS=$'\t' read -r id draft target; do
 [[ "$draft" == true && "$target" == "$EXPECTED" ]] || { echo "STOP: draft state or target mismatch" >&2; exit 2; }
done
DRAFT="$(gh api "repos/$REPO/releases" --paginate --jq '.[] | select(.tag_name == "v1.0.0" and .draft == true) | .id' | head -1)"
[[ -n "$DRAFT" ]] || { echo "STOP: v1.0.0 draft not found" >&2; exit 2; }
python3 - "$REPO" "$DRAFT" <<'PY'
import json, subprocess, sys
repo,rid=sys.argv[1:]
info=json.loads(subprocess.check_output(["gh","api",f"repos/{repo}/releases/{rid}"]))
expected={
"jatayu-media-player_1.0.0_x86_64.deb":"f6a763dcffac6376b47d8d69eefbfe319c35f91834843612284a1fd0ae6980ee",
"io.github.jatayuos4u.JatayuMediaPlayer-1.0.0-x86_64.flatpak":"42b5139bd5aeb3e6a0096b1d9f60f4233d1be534a5ce8078e36ec6acd142490b",
"jatayu-media-player-1.0.0-corresponding-sources-REVIEW.tar.gz":"020b7acdca7ef58680cf595357020bdd11680b36464e0410b8c83a6e155ddbbf"}
by_name={a["name"]:a for a in info["assets"]}
assert len(by_name)==9, "Expected exactly nine assets"
for name, sha in expected.items():
 a=by_name[name]
 assert a["state"]=="uploaded" and a["digest"]=="sha256:"+sha, f"Asset mismatch: {name}"
assert info["draft"] and info["target_commitish"]=="3d6ba15be78e4555d5f81267c92a21fe62caf702"
print("Release asset hashes and draft target verified.")
PY
# Update notes in the existing draft, then publish it without re-uploading binaries.
gh release edit v1.0.0 --repo "$REPO" --notes-file docs/V1-FINAL-RELEASE-NOTES.md
gh release edit v1.0.0 --repo "$REPO" --draft=false
gh release view v1.0.0 --repo "$REPO" --json url,isDraft,tagName,targetCommitish
