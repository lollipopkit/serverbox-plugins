#!/bin/sh
# Publish one theme: pack its folder, attach the package to a release, and add
# the version to the theme's file here with the digest just computed.
#
#   scripts/publish-themes.sh <id> <version>
#
# The release goes up before the file that names it. A file pointing at an
# address that answers 404 is broken for everybody who reads it; a release
# nothing lists yet is invisible and harmless.
#
# Needs `zip`, `shasum` or `sha256sum`, `awk` and an authenticated `gh`.
set -eu

[ $# -eq 2 ] || { echo "usage: $0 <theme id> <version>" >&2; exit 2; }
id=$1
version=$2

root=$(cd "$(dirname "$0")/.." && pwd)
source_dir="$root/themes/$id"
manifest="$source_dir/manifest.toml"
listing="$root/themes/$id.toml"

[ -f "$listing" ] || { echo "$listing does not exist" >&2; exit 1; }
[ -f "$manifest" ] || { echo "$manifest does not exist" >&2; exit 1; }

# One value out of the manifest, so what is written here is what the package
# itself says rather than a second copy of it.
scalar() {
  awk -v sect="$1" -v key="$2" '
    /^[[:space:]]*\[/ {section = $0}
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" && section ~ "\\[" sect "\\]" {
      sub(/^[^=]*=[[:space:]]*/, ""); gsub(/["[:space:]]/, ""); print; exit
    }
  ' "$manifest"
}

# A theme's id is the one its folder and its file are named after, and the same
# one its package carries. The app installs what the manifest says, so a folder
# holding somebody else's theme is refused here rather than published.
manifest_id=$(awk -F'"' '/^[[:space:]]*id[[:space:]]*=/{print $2; exit}' "$manifest")
[ "$manifest_id" = "$id" ] || {
  echo "$manifest says its id is '$manifest_id'" >&2
  exit 1
}

# The manifest's own range, because it is what the app compares against to
# decide whether it can read this package at all. A listing that widened it
# would offer a version whose installation then fails.
schema_min=$(scalar schema min)
schema_max=$(scalar schema max)
[ -n "$schema_min" ] && [ -n "$schema_max" ] || {
  echo "$manifest declares no [schema] min and max" >&2
  exit 1
}

remote=$(git -C "$root" remote get-url origin |
  sed -e 's#^git@github.com:#https://github.com/#' -e 's#\.git$##')
slug=${remote#https://github.com/}
tag="$id-$version"
url="$remote/releases/download/$tag/$tag.fsbt"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
asset="$work/$tag.fsbt"

# -X leaves out the extra file attributes a macOS zip records, which would
# otherwise differ per machine for identical contents. `-x .*` keeps .DS_Store
# and a stray .git from reaching the package, and the entries are named relative
# to the folder so manifest.toml lands at the archive root.
(cd "$source_dir" && zip -rXq "$asset" . -x '.*' -x '*/.*')

if command -v shasum >/dev/null 2>&1; then
  digest=$(shasum -a 256 "$asset" | awk '{print $1}')
else
  digest=$(sha256sum "$asset" | awk '{print $1}')
fi
size=$(wc -c < "$asset" | tr -d ' ')

# A version number that no longer identifies bytes makes every other check here
# meaningless. Nothing breaks the instant it happens, so it is refused.
recorded=$(awk -v v="$version" '
  $0 ~ "^[[:space:]]*version[[:space:]]*=[[:space:]]*\"" v "\"[[:space:]]*$" {found=1}
  found && /^[[:space:]]*sha256[[:space:]]*=/ && !got {print $3; got=1}
  /^[[:space:]]*\[\[/ {if (found) exit}
' "$listing" | tr -d '"')

published=false
gh release view "$tag" --repo "$slug" >/dev/null 2>&1 && published=true

if [ -n "$recorded" ]; then
  [ "$recorded" = "$digest" ] || {
    echo "$id $version is published as $recorded and this build is $digest" >&2
    echo "bump the version instead of replacing the bytes" >&2
    exit 1
  }
  # The other direction, which the ordering rule above exists to prevent: a file
  # naming an address that answers 404 is broken for everybody who reads it, and
  # nothing else here would notice it.
  $published || {
    echo "$listing records $version and no release $tag is up" >&2
    exit 1
  }
  echo "$id $version is already recorded, with these bytes"
else
  if $published; then
    echo "release $tag exists and $listing does not record it" >&2
    exit 1
  fi
  gh release create "$tag" "$asset" \
    --repo "$slug" \
    --title "$id $version" \
    --notes "The $id theme, version $version."
  echo "released $tag"

  # Appended rather than inserted: the file's own order means nothing — the app
  # picks by version number and by what each version says it can run on — so
  # rewriting the rest of the file to put this one first would only be a place
  # for a comment to be lost.
  cat >> "$listing" <<EOF

[[version]]
version = "$version"
schema_min = $schema_min
schema_max = $schema_max
url = "$url"
sha256 = "$digest"
size = $size
EOF
  echo "added $id $version to themes/$id.toml"
fi

echo "url    $url"
echo "sha256 $digest"
echo "size   $size"
