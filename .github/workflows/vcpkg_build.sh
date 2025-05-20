#!/bin/bash

set -e

proj="$1"
if [ -z "$proj" ]; then
  echo "❌ Error: Missing project file name (.csolution.yml)"
  echo "Usage: ./build_project.sh <your_project.csolution.yml>"
  exit 1
fi

# 產生 env.json
echo "🔧 Activating vcpkg environment..."
vcpkg activate --downloads-root="${GITHUB_WORKSPACE:-$(pwd)}/.vcpkg/downloads" --json=env.json

# 加入 PATH
echo "Preserving vcpkg PATH ..."
jq -r '.paths.PATH[]' env.json >> "${GITHUB_PATH:-./.github_path_tmp}"

# 加入 ENV
echo "Preserving vcpkg ENV ..."
jq -r '.tools | to_entries[] | "\(.key)=\(.value)"' env.json >> "${GITHUB_ENV:-./.github_env_tmp}"

# 立即在本 shell 套用（方便你直接執行）
echo "🔧 Applying toolchain environment from env.json ..."
eval $(jq -r '.tools | to_entries[] | "export \(.key)=\(.value)"' env.json)
export PATH="$(jq -r '.paths.PATH[]' env.json | paste -sd ':' -):$PATH"

# 檢查工具鏈
echo "✅ Compiler path: $(which arm-none-eabi-gcc)"
arm-none-eabi-gcc --version

# 執行建置
echo "🛠 Running cbuild (clean)..."
cbuild "$proj" --clean

echo "📦 Running cbuild (update-rte & packs)..."
cbuild "$proj" --update-rte --packs

# 結束
vcpkg deactivate
echo "✅ Build complete: $proj"
