#!/bin/bash

# USERNAME="$(echo $whoami)"
USERNAME="$(whoami)"
# read -p "USERNAME=$USERNAME"
CURRENT_DIR="$PWD"
echo "CURRENT_DIR=$CURRENT_DIR"

version=24
VM_NAME="ubu$version"

DISK_SIZE=30

# Install qemu.
sudo apt-get install qemu-kvm >>/dev/null 2>&1
# Install the virtual installer that installs Ubuntu on Qemu.
#sudo apt-get install virt-install
sudo apt-get install virt-manager >>/dev/null 2>&1
# Allow copy paste between qemu Ubuntu and your own device
sudo apt-get install spice-vdagent >>/dev/null 2>&1
# Allow a bridge between qemu and your own device to grant Ubuntu internet.
sudo apt-get install libvirt-daemon-system >>/dev/null 2>&1
sudo apt-get install libvirt-clients >>/dev/null 2>&1
sudo apt-get install genisoimage >>/dev/null 2>&1
sudo apt-get install cloud-image-utils  >>/dev/null 2>&1
#sudo apt-get install python-libvirt

# Create working directory
cd /home/$USERNAME/
mkdir -p /home/$USERNAME/qemus
cd /home/$USERNAME/qemus

ISO_DIR="/home/$USERNAME/qemus"
# Create iso of autoinstall.yaml
SEED_PATH="$ISO_DIR/"seed.qcow2
sudo rm "$SEED_PATH"
# sudo rm "$CURRENT_DIR/seed$version/meta-data"
# touch "$CURRENT_DIR/seed$version/meta-data"
# genisoimage -o "$SEED_PATH" -r -J "$CURRENT_DIR/seed$version/"
sudo cloud-localds "$SEED_PATH" $CURRENT_DIR/seed$version/ubuntu-cloud-init.cfg $CURRENT_DIR/seed$version/user-data

VM_PASSWORD_FILE="$CURRENT_DIR/seed$version/password.txt"
echo "ubuntu" > "$VM_PASSWORD_FILE"

# Create in seedxy folder.
# sudo cloud-localds --network-config "$CURRENT_DIR/seed$version/ubuntu-network-init.cfg" "$SEED_PATH" \
  #  $CURRENT_DIR/seed$version/ubuntu-cloud-init.cfg
# cp "$CURRENT_DIR/seed$version/ubuntu-network-init.cfg" "$ISO_DIR/ubuntu-network-init.cfg"
cp "$CURRENT_DIR/seed$version/ubuntu-cloud-init.cfg" "$ISO_DIR/ubuntu-cloud-init.cfg"
# Export to iso dir.
# sudo cloud-localds --network-config "$ISO_DIR/ubuntu-network-init.cfg" "$SEED_PATH" \
  #  $ISO_DIR/ubuntu-cloud-init.cfg
# sudo rm "$CURRENT_DIR/seed$version/meta-data"

## Define variables
MEM_SIZE=3072            # Memory setting in MiB
VCPUS=1                  # CPU Cores count
OS_VARIANT="ubuntu22.04" # Select from the output of "osinfo-query os"
# LOCATION="$ISO_DIRubuntu-23.04-desktop-amd64.iso"
LOCATION="$ISO_DIR/ubuntu-22.04.2-live-server-amd64.iso"
OS_TYPE="linux"



# Download the Ubuntu iso.
# wget -O "$LOCATION" https://releases.ubuntu.com/lunar/ubuntu-22.04-desktop-amd64.iso
# wget -O "$LOCATION" https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso

# DISK_FILE="./${VM_NAME}.qcow2"
DISK_FILE="$ISO_DIR/${VM_NAME}.qcow2"
sudo rm "$DISK_FILE"
touch "$DISK_FILE"
chmod 777 "$DISK_FILE"
# virt-customize --add "$DISK_FILE" --root-password password:ubuntu


virt-install --name ubuntu22 \
  --virt-type kvm \
  --name ${VM_NAME} \
  --memory=${MEM_SIZE} \
  --vcpus=${VCPUS} \
  --os-type ${OS_TYPE} \
  --boot hd,menu=on \
  --location ${LOCATION},kernel=casper/vmlinuz,initrd=casper/initrd \
  --graphics vnc,port=5901,listen=0.0.0.0 \
  --os-variant ubuntu22.04 \
  --network bridge=virbr0 \
  --console pty,target_type=virtio \
	--unattended user-password-file="$VM_PASSWORD_FILE" \


# --disk path="$SEED_PATH",device=cdrom \