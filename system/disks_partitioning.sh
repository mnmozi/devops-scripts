#!/bin/bash

set -e

# === CONFIGURATION ===

# If you want to manually control which disks to format, list them here (e.g., sdc sdd).
# If empty, will auto-discover all unpartitioned disks.
DISKS_TO_FORMAT=("sdc" "sdd")

# Mount points corresponding to the disks above.
MOUNT_POINTS=("/data1" "/data2")

# === END CONFIGURATION ===


# === FUNCTIONS ===

error_exit() {
  echo "❌ ERROR: $1" >&2
  exit 1
}

format_and_mount() {
  local disk=$1
  local mount_point=$2

  echo "🛠️ Preparing /dev/$disk and mounting on $mount_point..."

  # Create partition
  sudo parted /dev/$disk --script mklabel gpt mkpart primary ext4 0% 100%

  # Wait for partition table refresh
  sleep 2

  # Format partition
  sudo mkfs.ext4 /dev/${disk}1

  # Create mount point
  sudo mkdir -p $mount_point

  # Mount partition
  sudo mount /dev/${disk}1 $mount_point

  echo "/dev/${disk}1 mounted at ${mount_point} ✅"

  # Make it persistent
  UUID=$(sudo blkid -s UUID -o value /dev/${disk}1)
  echo "UUID=$UUID $mount_point ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
}


# === LOGIC ===

if [ ${#DISKS_TO_FORMAT[@]} -gt 0 ]; then
  # User specified disks manually

  if [ ${#DISKS_TO_FORMAT[@]} -ne ${#MOUNT_POINTS[@]} ]; then
    error_exit "DISKS_TO_FORMAT and MOUNT_POINTS arrays must have the same length!"
  fi

  for i in "${!DISKS_TO_FORMAT[@]}"; do
    disk="${DISKS_TO_FORMAT[$i]}"
    mount_point="${MOUNT_POINTS[$i]}"

    if [ -b /dev/$disk ]; then
      format_and_mount $disk $mount_point
    else
      error_exit "/dev/$disk does not exist!"
    fi
  done

else
  # Auto-discover all unpartitioned disks
  echo "🔎 No disks specified manually, auto-discovering unpartitioned disks..."

  COUNTER=1
  for disk in $(lsblk -dn -o NAME | grep -E 'sd[b-z]' | while read d; do
      if ! lsblk /dev/$d | grep -q part; then
          echo $d
      fi
  done); do
    MOUNT_DIR="/data$COUNTER"
    format_and_mount $disk $MOUNT_DIR
    COUNTER=$((COUNTER+1))
  done

fi

echo "🎯 All done!"

