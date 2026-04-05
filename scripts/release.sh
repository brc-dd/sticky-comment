#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 1.2.0"
  exit 1
fi

version=$1
major=$(echo "$version" | cut -d. -f1)

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must be in semver format (e.g. 1.2.0)"
  exit 1
fi

echo "Tagging v${version} and updating v${major}..."

git tag -a "v${version}" -m "v${version}"
git tag -fa "v${major}" -m "v${major}"

git push origin "v${version}"
git push origin "v${major}" --force

echo "Done. Published v${version} (v${major} alias updated)."
