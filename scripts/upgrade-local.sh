#!/usr/bin/env bash
# Upgrade local Hugo (extended) and PaperMod from GitHub release artifacts.
# Hugo: official hugo_extended tarball. PaperMod: release tarball (no binary).
#
#   scripts/upgrade-local.sh
#   scripts/upgrade-local.sh --hugo 0.165.0 --papermod v8.0
#   scripts/upgrade-local.sh --prefix "$HOME/.local/bin" --hugo-only
set -euo pipefail

HUGO_REPO="gohugoio/hugo"
PAPERMOD_REPO="adityatelange/hugo-PaperMod"
PAPERMOD_DIR="themes/PaperMod"

hugo_version=""
papermod_tag=""
prefix=""
hugo_only=0
papermod_only=0
force=0
dry_run=0

usage() {
  cat <<'EOF'
Upgrade local Hugo and PaperMod from GitHub release artifacts.

Usage: scripts/upgrade-local.sh [options]

  --hugo VERSION       Hugo version (default: latest). With or without v.
  --papermod TAG       PaperMod release tag (default: latest). Example: v8.0
  --prefix DIR         Install hugo here (default: directory of current hugo,
                       or /usr/local/bin)
  --hugo-only          Skip PaperMod
  --papermod-only      Skip Hugo
  --force              Allow PaperMod to move to an older release tag
  --dry-run            Print actions only
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hugo)
      hugo_version="${2:?--hugo requires a version}"
      shift 2
      ;;
    --papermod)
      papermod_tag="${2:?--papermod requires a tag}"
      shift 2
      ;;
    --prefix)
      prefix="${2:?--prefix requires a directory}"
      shift 2
      ;;
    --hugo-only)
      hugo_only=1
      shift
      ;;
    --papermod-only)
      papermod_only=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ $hugo_only -eq 1 && $papermod_only -eq 1 ]]; then
  echo "use only one of --hugo-only and --papermod-only" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

need_cmd curl
need_cmd python3
need_cmd tar

run() {
  if [[ $dry_run -eq 1 ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

github_release_json() {
  local repo="$1"
  local spec="$2"
  local url
  if [[ "$spec" == "latest" ]]; then
    url="https://api.github.com/repos/${repo}/releases/latest"
  else
    url="https://api.github.com/repos/${repo}/releases/tags/${spec}"
  fi
  local headers=(
    -fsSL
    -H "Accept: application/vnd.github+json"
    -H "X-GitHub-Api-Version: 2022-11-28"
    -H "User-Agent: ad8fd-upgrade-local"
  )
  if [[ -n "${GITHUB_TOKEN:-}${GH_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN:-$GH_TOKEN}")
  fi
  curl "${headers[@]}" "$url"
}

json_field() {
  python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$1"
}

json_asset_url() {
  python3 -c '
import json, sys
want = sys.argv[1]
for asset in json.load(sys.stdin).get("assets", []):
    if asset.get("name") == want:
        print(asset["browser_download_url"])
        raise SystemExit(0)
raise SystemExit(f"release has no asset named {want}")
' "$1"
}

normalize_hugo_version() {
  local raw="$1"
  raw="${raw#v}"
  printf '%s\n' "$raw"
}

current_hugo_version() {
  if ! command -v hugo >/dev/null 2>&1; then
    return 1
  fi
  hugo version 2>/dev/null | python3 -c '
import re, sys
m = re.search(r"v(\d+\.\d+\.\d+)", sys.stdin.read())
print(m.group(1) if m else "")
'
}

hugo_os_arch() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
    *)
      echo "unsupported OS: $os" >&2
      exit 1
      ;;
  esac
  case "$arch" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac
  printf '%s %s\n' "$os" "$arch"
}

hugo_asset_name() {
  local version="$1" os="$2" arch="$3"
  if [[ "$os" == "darwin" ]]; then
    printf 'hugo_extended_%s_darwin-universal.tar.gz\n' "$version"
    return
  fi
  printf 'hugo_extended_%s_%s-%s.tar.gz\n' "$version" "$os" "$arch"
}

resolve_hugo_prefix() {
  if [[ -n "$prefix" ]]; then
    printf '%s\n' "$prefix"
    return
  fi
  if command -v hugo >/dev/null 2>&1; then
    dirname "$(command -v hugo)"
    return
  fi
  printf '/usr/local/bin\n'
}

install_file() {
  local src="$1" dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"
  if [[ $dry_run -eq 1 ]]; then
    run mkdir -p "$dest_dir"
    run install -m 755 "$src" "$dest"
    return
  fi
  mkdir -p "$dest_dir"
  if [[ -w "$dest_dir" && ( ! -e "$dest" || -w "$dest" ) ]]; then
    install -m 755 "$src" "$dest"
    return
  fi
  if command -v sudo >/dev/null 2>&1; then
    echo "installing hugo to $dest with sudo"
    sudo install -m 755 "$src" "$dest"
    return
  fi
  echo "cannot write $dest; pass --prefix DIR" >&2
  exit 1
}

verify_sha256() {
  local file="$1" checksums="$2" asset="$3"
  local expected
  expected="$(awk -v name="$asset" '$2 == name { print $1; exit }' "$checksums")"
  if [[ -z "$expected" ]]; then
    echo "no checksum for $asset" >&2
    exit 1
  fi
  python3 -c '
import hashlib, sys
path, expected = sys.argv[1], sys.argv[2]
digest = hashlib.sha256(open(path, "rb").read()).hexdigest()
if digest != expected:
    raise SystemExit(f"checksum mismatch: got {digest}, expected {expected}")
' "$file" "$expected"
}

upgrade_hugo() {
  local spec json tag version os arch asset work checksums_url tarball_url
  local dest current
  spec="${hugo_version:-latest}"
  if [[ "$spec" != "latest" ]]; then
    spec="v$(normalize_hugo_version "$spec")"
  fi

  echo "resolving Hugo release ($spec)"
  json="$(github_release_json "$HUGO_REPO" "$spec")"
  tag="$(printf '%s' "$json" | json_field tag_name)"
  version="$(normalize_hugo_version "$tag")"
  read -r os arch < <(hugo_os_arch)
  asset="$(hugo_asset_name "$version" "$os" "$arch")"
  dest="$(resolve_hugo_prefix)/hugo"

  current="$(current_hugo_version || true)"
  if [[ -n "$current" && "$current" == "$version" && $force -eq 0 ]]; then
    echo "Hugo $version already installed ($(command -v hugo))"
    return
  fi

  tarball_url="$(printf '%s' "$json" | json_asset_url "$asset")"
  checksums_url="$(printf '%s' "$json" | json_asset_url "hugo_${version}_checksums.txt")"

  echo "Hugo $version ($asset) -> $dest"
  if [[ $dry_run -eq 1 ]]; then
    echo "dry-run: download $tarball_url"
    echo "dry-run: verify sha256 from $checksums_url"
    echo "dry-run: install binary to $dest"
    return
  fi

  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN
  curl -fsSL -H "User-Agent: ad8fd-upgrade-local" -o "$work/$asset" "$tarball_url"
  curl -fsSL -H "User-Agent: ad8fd-upgrade-local" -o "$work/checksums.txt" "$checksums_url"
  verify_sha256 "$work/$asset" "$work/checksums.txt" "$asset"
  tar -xzf "$work/$asset" -C "$work" hugo
  install_file "$work/hugo" "$dest"
  echo "installed $($dest version)"
}

papermod_head() {
  if [[ ! -e "$PAPERMOD_DIR/.git" ]]; then
    return 1
  fi
  git -C "$PAPERMOD_DIR" describe --tags --always --dirty
}

upgrade_papermod() {
  local spec json tag tarball_url work src current
  spec="${papermod_tag:-latest}"

  echo "resolving PaperMod release ($spec)"
  json="$(github_release_json "$PAPERMOD_REPO" "$spec")"
  tag="$(printf '%s' "$json" | json_field tag_name)"
  tarball_url="$(printf '%s' "$json" | json_field tarball_url)"

  if [[ ! -d "$PAPERMOD_DIR" ]]; then
    echo "missing $PAPERMOD_DIR; init the PaperMod submodule first" >&2
    exit 1
  fi

  current="$(papermod_head || echo "unknown")"
  if [[ "$current" == "$tag" && $force -eq 0 ]]; then
    echo "PaperMod $tag already checked out"
    return
  fi
  if [[ "$current" == "$tag"-* && $force -eq 0 ]]; then
    echo "PaperMod is $current, ahead of release $tag. pass --force to replace it." >&2
    if [[ $dry_run -eq 1 ]]; then
      echo "dry-run: would stop here"
      return
    fi
    exit 1
  fi

  echo "PaperMod $tag (release tarball) -> $PAPERMOD_DIR"
  if [[ $dry_run -eq 1 ]]; then
    echo "dry-run: download $tarball_url"
    echo "dry-run: replace $PAPERMOD_DIR (keep .git)"
    return
  fi

  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN
  curl -fsSL -H "User-Agent: ad8fd-upgrade-local" -o "$work/papermod.tar.gz" "$tarball_url"
  mkdir -p "$work/src"
  tar -xzf "$work/papermod.tar.gz" -C "$work/src"
  src="$(find "$work/src" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  if [[ -z "$src" ]]; then
    echo "PaperMod tarball had no top-level directory" >&2
    exit 1
  fi

  find "$PAPERMOD_DIR" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  cp -a "$src"/. "$PAPERMOD_DIR/"

  if [[ -e "$PAPERMOD_DIR/.git" ]] && git -C "$PAPERMOD_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$PAPERMOD_DIR" fetch --tags --force origin >/dev/null
    if git -C "$PAPERMOD_DIR" show-ref --verify --quiet "refs/tags/$tag"; then
      git -C "$PAPERMOD_DIR" checkout --detach --quiet "$tag"
    fi
  fi

  echo "PaperMod is now $(papermod_head || echo "$tag")"
  echo "submodule pointer is local-only until you commit themes/PaperMod"
}

if [[ $papermod_only -eq 0 ]]; then
  upgrade_hugo
fi
if [[ $hugo_only -eq 0 ]]; then
  upgrade_papermod
fi
