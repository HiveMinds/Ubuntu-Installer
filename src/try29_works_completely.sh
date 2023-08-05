#!/bin/bash
# Still requires two enters

# Download the live-server ISO
# wget -O ~/Downloads/ubuntu-22.04.2-live-server-amd64.iso https://releases.ubuntu.com/22.10/ubuntu-22.04.2-live-server-amd64.iso

# Create user-data and meta-data files
mkdir -p ~/cidata
cd ~/cidata
cat > user-data << 'EOF'
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ubuntu-server
    password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
    username: ubuntu
EOF
touch meta-data

# Create an ISO to use as a cloud-init data source
sudo apt-get install cloud-image-utils -y
cloud-localds ~/seed.iso user-data meta-data

# Create a target disk
truncate -s 10G image.img

# Run the install
kvm -no-reboot -m 2048 \
    -drive file=image.img,format=raw,cache=none,if=virtio \
    -drive file=~/seed.iso,format=raw,cache=none,if=virtio \
    -cdrom ~/Downloads/ubuntu-22.04.2-live-server-amd64.iso

# Boot the installed system
kvm -no-reboot -m 2048 \
    -drive file=image.img,format=raw,cache=none,if=virtio
