#!/usr/bin/env bash
# Kalp Odası'nı tek başına çalışan, web için küçültülmüş bir sayfa olarak derler.
# Repo kopyası geçici bir klasörde değiştirilir; çalışma klasörüne dokunulmaz.
#
#   tools/web_heart/build.sh [çıktı klasörü]      # varsayılan: build/web-heart
#   cd build/web-heart && npx vercel deploy --prod
#
# Gerekenler: Godot 4.7.2 (PATH'te `godot`), web thread'siz dışa aktarma şablonu, Node (npx), rsync.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$(mkdir -p "${1:-$ROOT/build/web-heart}" && cd "${1:-$ROOT/build/web-heart}" && pwd)"
WORK="$(mktemp -d)"
SRC="$WORK/src"
trap 'rm -rf "$WORK"' EXIT

echo "== Kopya: $SRC"
mkdir -p "$SRC/stations"
cd "$ROOT"
rsync -a --exclude '.godot' project.godot scripts scenes fonts assets "$SRC/"
rsync -a \
  --exclude concept --exclude art \
  --exclude 'assets/segmented/archive' \
  --exclude 'assets/segmented/heart_segmented*' \
  --exclude 'assets/segmented/myocardium_*' \
  --exclude 'assets/segmented/vessel_wall_*' \
  --exclude 'assets/segmented/capture_review.*' \
  --exclude 'assets/segmented/build_heart.py' \
  --exclude 'assets/model/heart_cutaway_light*' \
  --exclude 'heart_segmented_inspector.*' \
  --exclude 'capture_segmented_inspector.*' \
  stations/heart "$SRC/stations/"
cp "$ROOT/tools/web_heart/export_presets.cfg" "$SRC/"

cd "$SRC"
echo "== Kalp sahnesinin yüklemediği dosyalar çıkarılıyor"
# Kalp sahnesi bu modellerden yalnızca akciğer ve kas modelini yükler (heart_stage.gd).
find assets/models -mindepth 1 -maxdepth 1 ! -name 'human-lungs*' ! -name 'human-muscles*' -exec rm -rf {} +
# PBR malzemelerinden yalnızca Metal009 kullanılır (heart_stage.gd _pbr çağrıları).
find assets/materials -mindepth 1 -maxdepth 1 ! -name Metal009 -exec rm -rf {} +
# Kontrol merkezi, açılış ve diğer istasyonların paylaşılan dosyaları.
rm -rf assets/polyhaven assets/story assets/characters assets/intro assets/ui/archive assets/world assets/backgrounds \
  assets/ui/control_center_bg.jpg* assets/app_icon/app_icon.icns \
  scenes/control_center.tscn scenes/intro scripts/control_center.gd* scripts/physics

echo "== Tek başına açılış"
sed -i.bak 's#^run/main_scene=.*#run/main_scene="res://stations/heart/mission.tscn"#' project.godot
# Kontrol merkezi bu derlemede yok: "Merkeze dön" görevi baştan başlatır.
sed -i.bak 's#get_tree().change_scene_to_file("res://scenes/control_center.tscn")#get_tree().reload_current_scene()#' stations/heart/mission.gd
grep -q 'reload_current_scene()' stations/heart/mission.gd || { echo "mission.gd geri dönüş satırı bulunamadı" >&2; exit 1; }
find . -name '*.bak' -delete

echo "== Modeller sadeleştiriliyor"
simplify() { # dosya oran
  npx -y @gltf-transform/cli@4.1.1 weld "$1" "$WORK/w.glb" >/dev/null
  npx -y @gltf-transform/cli@4.1.1 simplify "$WORK/w.glb" "$1" --ratio "$2" --error 0.002 >/dev/null
}
simplify stations/heart/assets/model/heart_cutaway.glb 0.25   # 800 bin -> 200 bin üçgen
simplify assets/models/human-muscles.glb 0.2                  # 300 bin -> 60 bin
simplify assets/models/human-lungs.glb 0.2                    # 205 bin -> 41 bin

echo "== İçe aktarma ayarları"
find . -name '*.glb.import' -exec sed -i.bak 's#^meshes/generate_lods=true#meshes/generate_lods=false#; s#^meshes/create_shadow_meshes=true#meshes/create_shadow_meshes=false#' {} +
for f in stations/heart/assets/model/heart_cutaway_Image_*.jpg.import assets/models/human-*_Image_*.jpg.import; do
  [ -f "$f" ] && sed -i.bak 's#^process/size_limit=.*#process/size_limit=2048#' "$f"
done
for f in assets/materials/Metal009/*.jpg.import; do sed -i.bak 's#^process/size_limit=.*#process/size_limit=1024#' "$f"; done
find . -name '*.bak' -delete

echo "== Godot içe aktarma ve web dışa aktarma"
godot --headless --path . --import >"$WORK/import.log" 2>&1 || { tail -20 "$WORK/import.log"; exit 1; }
rm -rf "$OUT"/index.*
godot --headless --path . --export-release "Web" "$OUT/index.html" >"$WORK/export.log" 2>&1 || { tail -20 "$WORK/export.log"; exit 1; }

ls -la "$OUT"
echo "== Hazır: $OUT"
