#!/usr/bin/env bash
set -e

INPUT="$1"

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <file-or-folder>"
  exit 1
fi

process_file() {
  FILE="$1"
  EXT="${FILE##*.}"
  BASENAME="$(basename "$FILE" ."$EXT")"
  DIR="$(dirname "$FILE")"

  echo "🔍 Checking: $FILE"

  # Check if Dolby Vision exists
  if ! mediainfo "$FILE" | grep -qi "Dolby Vision"; then
    echo "✅ No Dolby Vision → skipping"
    return
  fi

  # Extract Dolby Vision profile
  DV_PROFILE=$(mediainfo --Output=JSON "$FILE" \
    | jq -r '.. | objects | select(has("DolbyVision_Profile")) | .DolbyVision_Profile' \
    | head -n 1)

  if [[ -z "$DV_PROFILE" ]]; then
    echo "⚠ Dolby Vision detected but profile unknown → skipping for safety"
    return
  fi

  echo "🎯 Dolby Vision profile detected: $DV_PROFILE"

  # Profiles safe on LG B9
  if [[ "$DV_PROFILE" == "8.1" ]]; then
    echo "✅ DV Profile 8.1 supported → leaving file untouched"
    return
  fi

  # Profiles to strip
  if [[ "$DV_PROFILE" != "5" && "$DV_PROFILE" != "7" ]]; then
    echo "⚠ Unsupported or uncommon DV profile ($DV_PROFILE) → skipping"
    return
  fi

  echo "❌ DV Profile $DV_PROFILE not suitable for LG B9 → stripping DV"

  TMP_HEVC="${DIR}/${BASENAME}_hdr10.hevc"
  TMP_MP4="${DIR}/${BASENAME}_hdr10.mp4"
  OUT_FILE="${DIR}/${BASENAME}.HDR10.mkv"

  # Step 1: Remove DV metadata
  ffmpeg -y -loglevel error \
    -i "$FILE" -map 0:v:0 -c:v copy \
    -bsf:v hevc_mp4toannexb -f hevc - | \
    dovi_tool remove - -o "$TMP_HEVC"

  # Step 2: Wrap HEVC
  ffmpeg -y -loglevel error \
    -fflags +genpts -i "$TMP_HEVC" -c:v copy "$TMP_MP4"

  # Step 3: Remux everything back
  ffmpeg -y -loglevel error \
    -i "$TMP_MP4" -i "$FILE" \
    -map_chapters 1 \
    -map 0:v:0 -map 1:a? -map 1:s? \
    -c copy \
    "$OUT_FILE"

  rm -f "$TMP_HEVC" "$TMP_MP4"

  echo "✅ Converted → $OUT_FILE"
}

export -f process_file

if [[ -d "$INPUT" ]]; then
  find "$INPUT" -type f \( -iname "*.mkv" -o -iname "*.mp4" \) -print0 |
  while IFS= read -r -d '' f; do
    process_file "$f"
  done
else
  process_file "$INPUT"
fi

