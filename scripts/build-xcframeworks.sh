#!/usr/bin/env bash
#
# Clone sherpa-onnx, build iOS XCFrameworks, and create a single merged
# xcframework containing both sherpa-onnx and onnxruntime (avoids Xcode
# module.modulemap collision when two binary targets share the same output dir).
#
set -euo pipefail

VERSION=""
WORK_DIR="$(pwd)/build-work"

usage() {
  echo "Usage: $0 --version <X.Y.Z>"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    *) usage ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  usage
fi

echo "=== Building sherpa-onnx v${VERSION} ==="

# Working directory
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Clone sherpa-onnx
echo "--- Cloning sherpa-onnx v${VERSION} ---"
git clone --depth 1 --branch "v${VERSION}" https://github.com/k2-fsa/sherpa-onnx.git
cd sherpa-onnx

# iOS build (with TTS, static library)
echo "--- Running build-ios.sh ---"
bash build-ios.sh

# Verify build artifacts
XCFW_DIR="build-ios/sherpa-onnx.xcframework"
if [[ ! -d "$XCFW_DIR" ]]; then
  echo "ERROR: sherpa-onnx.xcframework not found at $XCFW_DIR"
  exit 1
fi

echo "--- sherpa-onnx.xcframework built successfully ---"

# Locate onnxruntime.xcframework
echo "--- Locating onnxruntime.xcframework ---"
ONNX_XCFW_DIR="build-ios/ios-onnxruntime/onnxruntime.xcframework"
if [[ ! -d "$ONNX_XCFW_DIR" ]]; then
  echo "ERROR: onnxruntime.xcframework not found at $ONNX_XCFW_DIR"
  exit 1
fi

# --- Merge into single xcframework ---
echo "--- Merging sherpa-onnx and onnxruntime into single xcframework ---"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for slice_dir in "$XCFW_DIR"/*/; do
  slice_name="$(basename "$slice_dir")"
  headers_dir="${slice_dir}Headers"

  if [[ ! -d "$headers_dir" ]]; then
    continue
  fi

  # Find matching onnxruntime slice
  onnx_slice="${ONNX_XCFW_DIR}/${slice_name}"
  if [[ ! -d "$onnx_slice" ]]; then
    echo "  WARNING: No matching onnxruntime slice for ${slice_name}, skipping"
    continue
  fi

  echo "  Merging slice: ${slice_name}"

  # Copy onnxruntime static library into sherpa-onnx slice
  for lib in "$onnx_slice"/*.a; do
    if [[ -f "$lib" ]]; then
      cp "$lib" "$slice_dir/"
      echo "    Copied $(basename "$lib")"
    fi
  done

  # Copy onnxruntime headers into sherpa-onnx Headers/
  onnx_headers="${onnx_slice}/Headers"
  if [[ -d "$onnx_headers" ]]; then
    for h in "$onnx_headers"/*.h; do
      if [[ -f "$h" ]]; then
        cp "$h" "$headers_dir/"
      fi
    done
    echo "    Copied onnxruntime headers"
  fi

  # Write combined module.modulemap with both modules
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
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" ios-arm64 libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" ios-arm64 onnxruntime.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" ios-arm64_x86_64-simulator libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" ios-arm64_x86_64-simulator onnxruntime.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" macos-arm64_x86_64 libsherpa-onnx.a
python3 "$SCRIPT_DIR/patch-info-plist.py" "$XCFW_DIR/Info.plist" macos-arm64_x86_64 onnxruntime.a

# Copy merged xcframework to output
OUTPUT_DIR="${WORK_DIR}/output"
mkdir -p "$OUTPUT_DIR"
cp -R "$XCFW_DIR" "$OUTPUT_DIR/"

echo ""
echo "=== Build completed ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

# Verify architectures
echo "--- Verifying architectures ---"
for lib in "$OUTPUT_DIR"/sherpa-onnx.xcframework/*/*.a; do
  if [[ -f "$lib" ]]; then
    slice="$(basename "$(dirname "$lib")")"
    echo "  ${slice}/$(basename "$lib"): $(lipo -info "$lib" 2>/dev/null || echo "not a fat binary")"
  fi
done
