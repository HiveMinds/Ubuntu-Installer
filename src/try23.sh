#!/bin/bash

# USERNAME="$(echo $whoami)"
USERNAME="$(whoami)"
# read -p "USERNAME=$USERNAME"
CURRENT_DIR="$PWD"
echo "CURRENT_DIR=$CURRENT_DIR"

version=23
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
touch "$CURRENT_DIR/seed$version/meta-data"
# genisoimage -o "$SEED_PATH" -r -J "$CURRENT_DIR/seed$version/"
# sudo cloud-localds "$SEED_PATH" $CURRENT_DIR/seed$version/ubuntu-cloud-init.cfg
# sudo cloud-localds --network-config "$CURRENT_DIR/seed$version/ubuntu-network-init.cfg" "$SEED_PATH" \
#    $CURRENT_DIR/seed$version/ubuntu-cloud-init.cfg

sudo cloud-localds --network-config "$ISO_DIR/ubuntu-network-init.cfg" "$SEED_PATH" \
   $ISO_DIR/ubuntu-cloud-init.cfg
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


virt-install --name ubuntu22 \
  --virt-type kvm \
  --name ${VM_NAME} \
  --memory=${MEM_SIZE} \
  --vcpus=${VCPUS} \
  --os-type ${OS_TYPE} \
  --boot hd,menu=on \
  --disk path="$SEED_PATH",device=cdrom \
  --location ${LOCATION},kernel=casper/vmlinuz,initrd=casper/initrd \
  --graphics vnc,port=5901,listen=0.0.0.0 \
  --os-variant ubuntu22.04 \
  --network bridge=virbr0 \
  --console pty,target_type=virtio \
  --unattended

#virt-install \
#    --virt-type kvm \
#    --name ${VM_NAME} \
#    --memory=${MEM_SIZE} \
#    --vcpus=${VCPUS} \
#    --os-type ${OS_TYPE} \
#    --cpu host-passthrough \
#    --features smm.state=on \
#    --disk path="$SEED_PATH",device=cdrom \
#    --disk path="$DISK_FILE",size=${DISK_SIZE},format=qcow2,sparse=true,bus=scsi,discard=unmap \
#    --controller type=scsi,model=virtio-scsi \
#    --network bridge=virbr0 \
#    --metadata title='Ubuntu 22.04 (CIS)' \
#    --disk path="$SEED_PATH",size=${DISK_SIZE},device=cdrom,bus=sata \
#    --location ${LOCATION},kernel=casper/vmlinuz,initrd=casper/initrd \
#    --graphics spice,gl.enable=no,listen=none \
#    --video qxl \
#    --noautoconsole \
#    --noreboot
    # --channel spicevmc,target_type=virtio,name=com.redhat.spice.0 \
    # --channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
    # --console pty,target_type=virtio \
    # --tpm type=emulator,version=2.0,model=tpm-tis \
    # --boot loader=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd,loader.readonly=yes,loader.type=pflash,loader.secure=yes,nvram.template=/usr/share/OVMF/OVMF_VARS_4M.ms.fd \
    # --extra-args='autoinstall' \
    

# virsh change-media jammy_cis sdc --eject --force