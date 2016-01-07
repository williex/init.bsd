#!/bin/bash
#
# Check boot files for tampering, aka evil maid.
# Add this file to rc.local, examples for rc.local and conky at the end of this file

# Exit on any errors
set -e

# Boot disk
BOOTDISK=/dev/sda

# Set this to the unencrypted boot partition
BOOTPART=/dev/sda1

# Set this to the location to store the boot hashes
STORAGE=/mnt/data/checkboot

# No changes needed below this line

if [ `id -u` != "0" ]; then 
  echo "Please run this script as root";
  exit 1;
fi

# Remove old warning file if it exists
rm -f "$STORAGE/warning"

# Create the storage dir if it does not exist yet
mkdir -p "$STORAGE"

# Create a temporary working directory, the X chars are replace by a random number
WDIR=$(mktemp -d /tmp/checkboot.boot.XXXXXXXXXX)

# Mount the boot partition at a temporary place
echo "Mounting $BOOTPART at $WDIR"
mount "$BOOTPART" "$WDIR"

# Current date and time
DATE=`date +%Y-%m-%d_%H:%M:%S`
FILE="$STORAGE/checkboot.$DATE.txt"

# Generated sha256sum of each file
echo -n "Generating checksums..."
cd "$WDIR"
# In case there is no dedicated boot partition but a boot directory on this filesystem, use that one
if [[ -d boot ]]; then
  echo -n "found boot directory..."
  cd boot
fi
find . -type f -exec sha256sum {} \; | sort > "$FILE"
echo "done"

# Check MBR
TMPHEAD=$(mktemp /tmp/checkboot.mbr.XXXXXXXXXX)
echo -n "Copying MBR from $BOOTDISK to $TMPHEAD..."
dd if="$BOOTDISK" of="$TMPHEAD" bs=512 count=1 > /dev/null 2>&1
sha256sum "$TMPHEAD" | head -c 64 >> "$FILE"
echo "done"

# Clean up
cd /tmp
umount "$WDIR"
rm -fr "$WDIR" "$TMPHEAD"

# Check if this file is the same as the last file
PREV=`ls "$STORAGE/checkboot"* | tail -n 2 | head -n 1`
if [[ "$PREV" == "0" ]]; then
  # Should not happen, $FILE is already created
  echo "Nothing to compare"
else
  echo "Comparing $FILE to $PREV..."
  PREVSUM=`sha256sum "$PREV" | head -c 64`
  THISSUM=`sha256sum "$FILE" | head -c 64`
  if [[ $PREVSUM != $THISSUM ]]; then
    echo "Warning boot changes!"
    echo "$PREVSUM"
    echo "$THISSUM"
    touch "$STORAGE/warning"
  else
    echo "All good, the boot files are the same as last boot"
  fi
fi

# Conky example (uncomment these lines in ~/.conkyrc):
#${if_existing /mnt/data/checkboot/warning}${hr 2}
#${color}${font DejaVu Sans Mono:size=18:bold}Warning boot files changed!
#${hr 2}${endif}

# Add to rc.local and uncomment
#if [ -x /usr/bin/checkboot ]; then
#  echo "Checking boot sectors..."
#  /usr/bin/checkboot &
#fi
