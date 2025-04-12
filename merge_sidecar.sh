#!/bin/bash
set -e
set -o pipefail

# Check for prerequisites
for cmd in unzip exiftool jq; do
  if ! command -v "$cmd" > /dev/null; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done

trap 'echo "Error: Script failed at line $LINENO" >&2' ERR

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_zip_dir> <output_dir>"
  exit 1
fi

OS=$(uname)
convert_date() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    if [ "$OS" = "Darwin" ]; then
      date -r "$1" +"%Y:%m:%d %H:%M:%S"
    else
      date -d @"$1" +"%Y:%m:%d %H:%M:%S"
    fi
  else
    if [ "$OS" = "Darwin" ]; then
      # Normalize the date string:
      normalized=$(printf "%s" "$1" | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null)
      normalized=$(echo "$normalized" | sed -E 's/[[:space:]]+/ /g')
      if [[ "$normalized" == *","* ]]; then
        # Try with abbreviated month first
        converted=$(date -j -f "%b %d, %Y, %I:%M:%S %p %Z" "$normalized" +"%Y:%m:%d %H:%M:%S" 2>/dev/null)
        if [ $? -ne 0 ]; then
          # Fallback to full month name format
          converted=$(date -j -f "%B %d, %Y, %I:%M:%S %p %Z" "$normalized" +"%Y:%m:%d %H:%M:%S")
        fi
        echo "$converted"
      else
        date -j -f "%Y-%m-%d %H:%M:%S" "$normalized" +"%Y:%m:%d %H:%M:%S"
      fi
    else
      date -d "$1" +"%Y:%m:%d %H:%M:%S"
    fi
  fi
}

input_dir="$1"
output_dir="$2"

mkdir -p "$output_dir"

temp_dir=$(mktemp -d)

for zip_file in "$input_dir"/*.zip; do
  [ -e "$zip_file" ] || continue
  echo "Processing $zip_file"
  extract_dir="${temp_dir}/$(basename "$zip_file" .zip)"
  mkdir -p "$extract_dir"
  unzip -q "$zip_file" -d "$extract_dir"

  find "$extract_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mp4" -o -iname "*.mov" \) | while read -r media_file; do
    sidecar="${media_file}.supplemental-metadata.json"
    if [ -f "$sidecar" ]; then
      echo "Merging metadata for $rel_path using supplemental metadata"
      title=$(jq -r '.title' "$sidecar")
      description=$(jq -r '.description' "$sidecar")
      imageViews=$(jq -r '.imageViews' "$sidecar")
      photoTakenTime=$(jq -r '.photoTakenTime.timestamp' "$sidecar")
      creationTime=$(jq -r '.creationTime.timestamp' "$sidecar")
      latitude=$(jq -r '.geoData.latitude' "$sidecar")
      longitude=$(jq -r '.geoData.longitude' "$sidecar")
      altitude=$(jq -r '.geoData.altitude' "$sidecar")
      args=()
      [ "$title" != "" ] && args+=("-Title=$title")
      [ "$description" != "" ] && args+=("-Description=$description")
      if [ "$photoTakenTime" != "null" ]; then
          convertedPhotoTakenTime=$(convert_date "$photoTakenTime")
          args+=("-DateTimeOriginal=$convertedPhotoTakenTime" "-FileCreateDate=$convertedPhotoTakenTime")
      fi
      if [ "$creationTime" != "null" ]; then
          convertedCreationTime=$(convert_date "$creationTime")
          args+=("-CreateDate=$convertedCreationTime")
      fi
      [ "$latitude" != "null" ] && args+=("-GPSLatitude=$latitude")
      [ "$longitude" != "null" ] && args+=("-GPSLongitude=$longitude")
      [ "$altitude" != "null" ] && args+=("-GPSAltitude=$altitude")
      exiftool -overwrite_original "${args[@]}" "$media_file"
    else
      echo "No sidecar found for $rel_path"
    fi
    rel_path="${media_file#$extract_dir/}"
    target_file="$output_dir/$rel_path"
    target_dir="$(dirname "$target_file")"
    mkdir -p "$target_dir"
    if [ -f "$target_file" ]; then
      echo "Warning: File $target_file already exists, renaming incoming file."
      base=$(basename "$target_file")
      ext="${base##*.}"
      name="${base%.*}"
      target_file="$target_dir/${name}_$(date +%s).${ext}"
    fi
    cp "$media_file" "$target_file"
  done

  rm -rf "$extract_dir"
done

rm -rf "$temp_dir"

echo "Processing complete. Merged files are in $output_dir. Original zip files are retained."
