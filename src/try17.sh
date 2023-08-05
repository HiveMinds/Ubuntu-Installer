#!/bin/bash
# Source: https://clouddocs.web.cern.ch/advanced_topics/own_images_from_ks.html

# USERNAME="$(echo $whoami)"
USERNAME="$(whoami)"
# read -p "USERNAME=$USERNAME"
CURRENT_DIR="$PWD"
echo "CURRENT_DIR=$CURRENT_DIR"

# echo -en "Enter VM name: "
# read VM_NAME
version=17
VM_NAME="ubu$version"

# echo -en "Enter virtual disk size : "
# read DISK_SIZE
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
#sudo apt-get install python-libvirt

# Create working directory
cd /home/$USERNAME/
mkdir -p /home/$USERNAME/qemus
cd /home/$USERNAME//qemus


## Define variables
MEM_SIZE=3072            # Memory setting in MiB
VCPUS=1                  # CPU Cores count
OS_VARIANT="ubuntu23.04" # Select from the output of "osinfo-query os"
LOCATION="/home/$USERNAME/qemus/ubuntu-23.04-desktop-amd64.iso"
OS_TYPE="linux"

# Download the Ubuntu iso.
# wget -O "$LOCATION" https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso

# DISK_FILE="./${VM_NAME}.qcow2"
DISK_FILE="/home/$USERNAME/qemus/${VM_NAME}.qcow2"
touch "$DISK_FILE"
chmod 777 "$DISK_FILE"

# TODO: manually:
#    sudo gedit /etc/libvirt/qemu.conf
#    # And set
#    user = "root"
#    group = "root"
#    # And then:
#    sudo systemctl restart libvirtd

# sudo virt-install \
#   --name ${VM_NAME} \
#   --memory=${MEM_SIZE} \
#   --vcpus=${VCPUS} \
#   --os-type ${OS_TYPE} \
#   --graphics=none \
#   --location ${LOCATION},initrd=casper/initrd,kernel=casper/vmlinuz \
#   --disk ${DISK_FILE},size=${DISK_SIZE} \
#   --network bridge=virbr0 \
#   --os-variant=${OS_VARIANT} \
#   --console pty,target_type=serial \
#   --extra-args 'console=ttyS0,115200n8 serial autoinstall'
  
  

virt-install \
--virt-type kvm \
--name=jammy_cis \
--os-variant=ubuntu22.04 \
--vcpus 1 \
--cpu host-passthrough \
--memory 2048 \
--features smm.state=on \
--disk path="$DISK_FILE",size=50,format=qcow2,sparse=true,bus=scsi,discard=unmap  \
--controller type=scsi,model=virtio-scsi \
--network bridge=br0,model=virtio \
--metadata title='Ubuntu 22.04 (CIS)' \
--disk path=/home/$USERNAME/qemus/seed.iso,device=cdrom,bus=sata \
--location /home/$USERNAME/qemus/ubuntu-22.04.2-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
--channel spicevmc,target_type=virtio,name=com.redhat.spice.0 \
--channel unix,target_type=virtio,name=org.qemu.guest_agent.0 \
--graphics spice,gl.enable=no,listen=none \
--video qxl \
--console pty,target_type=virtio \
--tpm type=emulator,version=2.0,model=tpm-tis \
--boot loader=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd,loader.readonly=yes,loader.type=pflash,loader.secure=yes,nvram.template=/usr/share/OVMF/OVMF_VARS_4M.ms.fd \
--extra-args='autoinstall' \
--noreboot

virsh change-media jammy_cis sdc --eject --force