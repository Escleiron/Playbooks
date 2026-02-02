#!/bin/bash

#######################################
# CONFIG
#######################################
clear

#######################################
# FUNCTIONS
#######################################

usage() {
  echo "Usage: $0 <mount_inventory_file.txt>"
  exit 1
}

check_file() {
  [[ -z "$FILE" || ! -f "$FILE" ]] && usage
}

pause() {
  read -rp "Press ENTER to continue.."
}

show_analysis() {
  echo
  echo "=============================="
  echo " TOTAL SHARES"
  echo "=============================="

  awk 'NR>1 {print $2}' "$FILE" \
    | sort \
    | uniq -c \
    | sort -nr \
    | awk '{printf "%6s  %s\n", $1, $2}'

  echo
  echo "------------------------------"
  echo "TOTAL $(awk 'NR>1 {print $2}' "$FILE" | wc -l)"
  echo "------------------------------"

  echo
  echo "=============================="
  echo " TOTAL MOUNTPOINTS"
  echo "=============================="

  awk 'NR>1 {print $3}' "$FILE" \
    | sort \
    | uniq -c \
    | sort -nr \
    | awk '{printf "%6s  %s\n", $1, $2}'

  echo
  echo "------------------------------"
  echo "TOTAL $(awk 'NR>1 {print $3}' "$FILE" | wc -l)"
  echo "------------------------------"
}

show_servers() {
  echo
  echo "=============================="
  echo " SERVERS"
  echo "=============================="

  awk 'NR>1 {print $1}' "$FILE" | sort -u

  echo
  echo "------------------------------"
  echo "TOTAL $(awk 'NR>1 {print $1}' "$FILE" | sort -u | wc -l)"
  echo "------------------------------"
}

convert_to_csv() {
  OUTPUT_FILE="${FILE%.txt}.csv"

  echo "SERVER,SHARE,MOUNTPOINT,TYPE" > "$OUTPUT_FILE"

  awk 'NR>1 {
    server=$1
    share=$2
    type=$NF

    mount=""
    for (i=3; i<NF; i++) {
      mount = mount (i==3 ? "" : " ") $i
    }

    printf "%s,%s,%s,%s\n", server, share, mount, type
  }' "$FILE" >> "$OUTPUT_FILE"

  echo "CSV generated successfully: $OUTPUT_FILE"
}

menu() {
  while true; do
    echo
    echo "======================================"
    echo " MOUNT INVENTORY MENU"
    echo "======================================"
    echo "1) Review analyzed results"
    echo "2) Show unique servers"
    echo "3) Convert inventory to CSV"
    echo "4) Exit"
    echo "--------------------------------------"
    read -rp "Option: " OPT

    case "$OPT" in
      1) show_analysis; pause ;;
      2) show_servers; pause ;;
      3)
        read -rp "Confirm CSV conversion? (y/n): " C
        [[ "$C" =~ ^[yY]$ ]] && convert_to_csv
        pause
        ;;
      4) exit 0 ;;
      *) echo "Invalid option" ;;
    esac
  done
}

#######################################
# MAIN
#######################################

FILE="$1"
check_file
menu
