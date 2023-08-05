#!/bin/bash
# Source: https://clouddocs.web.cern.ch/advanced_topics/own_images_from_ks.html

# USERNAME="$(echo $whoami)"
USERNAME="$(whoami)"
# read -p "USERNAME=$USERNAME"
CURRENT_DIR="$PWD"
echo "CURRENT_DIR=$CURRENT_DIR"

# echo -en "Enter VM name: "
# read VM_NAME
version=21
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
sudo apt-get install genisoimage >>/dev/null 2>&1
#sudo apt-get install python-libvirt

# Create working directory
cd /home/$USERNAME/
mkdir -p /home/$USERNAME/qemus
cd /home/$USERNAME/qemus

# Create iso of autoinstall.yaml
sudo rm /home/$USERNAME/qemus/seed.iso
sudo rm "$CURRENT_DIR/seed$version/meta-data"
touch "$CURRENT_DIR/seed$version/meta-data"
genisoimage -o /home/$USERNAME/qemus/seed.iso -r -J "$CURRENT_DIR/seed$version/"
sudo rm "$CURRENT_DIR/seed$version/meta-data"
read -p "Got iso?"

## Define variables
MEM_SIZE=3072            # Memory setting in MiB
VCPUS=1                  # CPU Cores count
OS_VARIANT="ubuntu22.04" # Select from the output of "osinfo-query os"
# LOCATION="/home/$USERNAME/qemus/ubuntu-23.04-desktop-amd64.iso"
OS_TYPE="linux"

# Download the Ubuntu iso.
# wget -O "$LOCATION" https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso

# DISK_FILE="./${VM_NAME}.qcow2"
DISK_FILE="/home/$USERNAME/qemus/${VM_NAME}.qcow2"
sudo rm "$DISK_FILE"
touch "$DISK_FILE"
chmod 777 "$DISK_FILE"

# TODO: manually:
#    sudo gedit /etc/libvirt/qemu.conf
#    # And set
#    user = "root"
#    group = "root"
#    # And then:
#    sudo systemctl restart libvirtd


virt-install \
  --name ${VM_NAME} \
  --description "Test" \
  --os-type Linux \
  --os-variant ubuntu22.04 \
  --memory=${MEM_SIZE} \
  --vcpus 2 \
  --disk path=${DISK_FILE},bus=virtio,size=50 \
  --disk /home/$USERNAME/qemus/seed.iso,format=raw,cache=none \
  --graphics none \
  --network bridge:virbr0 \
  --location /home/$USERNAME/qemus/ubuntu-22.04.2-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/hwe-initrd \
  --noreboot \
  --extra-args 'console=ttyS0,115200n8 serial autoinstall'
# --location /var/lib/libvirt/images/ubuntu-20.04.3-live-server-amd64.iso,kernel=casper/hwe-vmlinuz,initrd=casper/hwe-initrd \

# sudo virt-install \
  # --name ${VM_NAME} \
  # --memory=${MEM_SIZE} \
  # --vcpus=${VCPUS} \
  # --os-type ${OS_TYPE} \
  # --graphics=none \
  # --location ${LOCATION},initrd=casper/initrd,kernel=casper/vmlinuz \
  # --disk path=/home/$USERNAME/qemus/seed.iso,device=cdrom,bus=sata \
  # --location /home/$USERNAME/qemus/ubuntu-22.04.2-live-server-amd64.iso,kernel=casper/vmlinuz,initrd=casper/initrd \
  # --network bridge=virbr0 \
  # --os-variant=${OS_VARIANT} \
  # --console pty,target_type=serial \
  # --extra-args='autoinstall' \
  # --extra-args 'console=ttyS0,115200n8 serial autoinstall'
  
  
# virsh change-media jammy_cis sdc --eject --force