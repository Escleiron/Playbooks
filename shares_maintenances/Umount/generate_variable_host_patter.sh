#!/bin/bash
set -euo pipefail

INPUT_FILE="$1"

PATTERN=$(awk 'NR>1 {
  share = $2

  # CIFS: //host/share -> //host
  if (share ~ /^\/\//) {
    split(share, a, "/")
    print "//" a[3]
  }
  # NFS: host:/path -> host
  else if (share ~ /:/) {
    split(share, a, ":")
    print a[1]
  }
}' "$INPUT_FILE" | sort -u | paste -sd '|')

if [[ -z "$PATTERN" ]]; then
  echo "ERROR: empty pattern generated" >&2
  exit 1
fi

echo "---" > fstab_pattern.yml 
echo "fstab_host_pattern: \"$PATTERN\"" >> fstab_pattern.yml
echo "File fstab_pattern.yml generated with this variables:"
echo "fstab_host_pattern: \"$PATTERN\""
