#!/usr/bin/env bash
#
# Download existing xcframework zips, merge onnxruntime into sherpa-onnx,
# and create a single combined zip with the correct checksum.
#
# This avoids needing to do a full native build of sherpa-onnx.
#
set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"

WORK_DIR="$(pwd)/merge-work-${VERSION}"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "=== Merging sherpa-onnx ${VERSION} xcframeworks ==="

# Download zips
echo "--- Downloading release assets ---"
SHERPA_URL="https://github.com/willwade/sherpa-onnx-spm/releases/download/${VERSION}/sherpa-onnx.xcframework.zip"
ORT_URL="https://github.com/willwade/sherpa-onnx-spm/releases/download/${VERSION}/onnxruntime.xcframework.zip"

curl -fSL -o sherpa-onnx.xcframework.zip "$SHERPA_URL"
curl -fSL -o onnxruntime.xcframework.zip "$ORT_URL"

# Extract both
echo "--- Extracting ---"
unzip -q sherpa-onnx.xcframework.zip -d sherpa-onnx-work
unzip -q onnxruntime.xcframework.zip -d onnxruntime-work

SHERPA_XCFW="sherpa-onnx-work/sherpa-onnx.xcframework"
ORT_XCFW="$(find onnxruntime-work -name "onnxruntime.xcframework" -type d | head -1)"

if [[ ! -d "$SHERPA_XCFW" ]]; then
  echo "ERROR: sherpa-onnx.xcframework not found after extraction"
  exit 1
fi

# Merge onnxruntime into sherpa-onnx slices
echo "--- Merging slices ---"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for slice_dir in "$SHERPA_XCFW"/*/; do
  slice_name="$(basename "$slice_dir")"
  headers_dir="${slice_dir}Headers"

  if [[ ! -d "$headers_dir" ]]; then
    continue
  fi

  ort_slice="${ORT_XCFW}/${slice_name}"
  if [[ ! -d "$ort_slice" ]]; then
    echo "  WARNING: No matching onnxruntime slice for ${slice_name}, skipping"
    continue
  fi

  echo "  Merging: ${slice_name}"

  # Copy onnxruntime .a files
  for lib in "$ort_slice"/*.a; do
    [[ -f "$lib" ]] && cp "$lib" "$slice_dir/" && echo "    Copied $(basename "$lib")"
  done

  # Copy onnxruntime headers
  ort_headers="${ort_slice}/Headers"
  if [[ -d "$ort_headers" ]]; then
    for h in "$ort_headers"/*.h; do
      [[ -f "$h" ]] && cp "$h" "$headers_dir/"
    done
    echo "    Copied onnxruntime headers"
  fi

  # Write combined modulemap
  cat > "${headers_dir}/module.modulemap" << 'MODULEMAP'
module sherpa_onnx {
    header "sherpa-onnx/c-api/c-api.h"
    export *
}
module onnxruntime {
    header "onnxruntime_c_api.h"
    export *
}
MODULEMAP
  echo "    Wrote combined modulemap"
done

# Patch Info.plist to include both libraries
echo "--- Patching Info.plist ---"
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" ios-arm64 libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" ios-arm64 onnxruntime.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" ios-arm64_x86_64-simulator libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" ios-arm64_x86_64-simulator onnxruntime.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" macos-arm64_x86_64 libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$SHERPA_XCFW/Info.plist" macos-arm64_x86_64 onnxruntime.a

# Create new zip
echo "--- Creating combined zip ---"
cd sherpa-onnx-work
zip -ry "$OLDPWD/sherpa-onnx-combined.xcframework.zip" sherpa-onnx.xcframework > /dev/null
cd "$OLDPWD"

echo "  Created: sherpa-onnx-combined.xcframework.zip ($(du -h sherpa-onnx-combined.xcframework.zip | cut -f1))"

# Compute checksum
echo "--- Checksum ---"
CHECKSUM=$(swift package compute-checksum sherpa-onnx-combined.xcframework.zip)
echo "  checksum = \"$CHECKSUM\""

echo ""
echo "=== Done ==="
echo "Upload sherpa-onnx-combined.xcframework.zip to GitHub release as sherpa-onnx.xcframework.zip"
echo "Update Package.swift checksum to: $CHECKSUM"
echo "Remove the onnxruntime binary target from Package.swift"
