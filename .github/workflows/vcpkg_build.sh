#!/bin/bash

set -e

proj_path="$1"
if [ -z "$proj_path" ]; then
  echo "❌ Error: Missing project file path (.csolution.yml)"
  echo "Usage: ./vcpkg_buld.sh <your_project.csolution.yml>"
  exit 1
fi

proj_dir=$(dirname "$proj_path")
proj=$(basename "$proj_path")

#proj_name="${proj%.csolution.yml}"
#if [[ "$proj_name" != "Project" ]]; then
#    exit 0 #PASS
#fi

cd "$proj_dir"
#echo "current -> $(pwd)"
echo "Building: $proj_path"

# Generate env.json
echo "🔧 Activating vcpkg environment..."
vcpkg activate --downloads-root="${GITHUB_WORKSPACE:-$(pwd)}/.vcpkg/downloads" --json=env.json

# Add PATH
echo "Preserving vcpkg PATH ..."
jq -r '.paths.PATH[]' env.json >> "${GITHUB_PATH:-./.github_path_tmp}"

# Add ENV
echo "Preserving vcpkg ENV ..."
jq -r '.tools | to_entries[] | "\(.key)=\(.value)"' env.json >> "${GITHUB_ENV:-./.github_env_tmp}"

# Apply env in shell
echo "🔧 Applying toolchain environment from env.json ..."
eval $(jq -r '.tools | to_entries[] | "export \(.key)=\(.value)"' env.json)
export PATH="$(jq -r '.paths.PATH[]' env.json | paste -sd ':' -):$PATH"

# Check toolchain
echo "✅ Compiler path: $(which arm-none-eabi-gcc)"
#arm-none-eabi-gcc --version

# run cbuild clean & build
echo "🛠 Running cbuild (clean)..."
cbuild "$proj" --clean --packs

echo "📦 Running cbuild (update-rte & packs)..."
cbuild "$proj" --update-rte --packs

# Complete
vcpkg deactivate
echo "✅ Build complete: $proj"
