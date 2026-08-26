# Exporte le preset Web (sans threads) vers docs/index.html
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"
mkdir -p "$ROOT/docs"
"$GODOT" --headless --path "$ROOT" --export-release "Web" "$ROOT/docs/index.html"
echo "Export HTML5 → $ROOT/docs/index.html"
