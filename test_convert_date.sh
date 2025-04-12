#!/usr/bin/env bash
set -e

# Detect the operating system.
OS=$(uname)

# Updated convert_date function with normalization.
convert_date() {
  # If input is numeric, treat it as a timestamp.
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
        # Try with abbreviated month first.
        converted=$(date -j -f "%b %d, %Y, %I:%M:%S %p %Z" "$normalized" +"%Y:%m:%d %H:%M:%S" 2>/dev/null)
        if [ $? -ne 0 ]; then
          # Fallback to full month name format.
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

# Test cases using epoch timestamps from supplemental-metadata.json.
test_dates=(
  "1714973853"
  "1422016410"
)

echo "Running date conversion tests on OS: $OS"
for d in "${test_dates[@]}"; do
   result=$(convert_date "$d")
   echo "Input: '$d'  -> Converted: '$result'"
done
