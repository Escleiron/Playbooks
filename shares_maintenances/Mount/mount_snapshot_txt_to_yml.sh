#!/usr/bin/env bash

INPUT_FILE="$1"
OUTPUT_FILE="${2:-mount_snapshot.yml}"

if [[ -z "$INPUT_FILE" || ! -f "$INPUT_FILE" ]]; then
  echo "Usage: $0 <mount_inventory.txt> [output.yml]"
  exit 1
fi

echo "mounts:" > "$OUTPUT_FILE"

awk '
NR==1 { next }               # skip header
NF < 4 { next }              # skip malformed lines
{
  host=$1
  mount=$3

  if (!(host in seen)) {
    seen[host]=1
    hosts[++hcount]=host
  }

  mounts[host]=mounts[host] "  - path: " mount "\n"
}
END {
  for (i=1; i<=hcount; i++) {
    h=hosts[i]
    print "  " h ":" >> out
    printf "%s", mounts[h] >> out
  }
}
' out="$OUTPUT_FILE" "$INPUT_FILE"