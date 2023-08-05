#!/bin/bash

# USERNAME="$(echo $whoami)"
USERNAME="$(whoami)"
# read -p "USERNAME=$USERNAME"
CURRENT_DIR="$PWD"
echo "CURRENT_DIR=$CURRENT_DIR"

version=27
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
SEED_PATH="$ISO_DIR/"seed.iso

mkdir -p $CURRENT_DIR/seed$version
cat > $CURRENT_DIR/seed$version/user-data << 'EOF'
version: 1
reporting:
    hook:
        type: webhook
        endpoint: http://example.com/endpoint/path
early-commands:
    - ping -c1 198.162.1.1
locale: en_US
keyboard:
    layout: gb
    variant: dvorak
network:
    network:
        version: 2
        ethernets:
            enp0s25:
               dhcp4: yes
            enp3s0: {}
            enp4s0: {}
        bonds:
            bond0:
                dhcp4: yes
                interfaces:
                    - enp3s0
                    - enp4s0
                parameters:
                    mode: active-backup
                    primary: enp3s0
proxy: http://squid.internal:3128/
apt:
    primary:
        - arches: [default]
          uri: http://repo.internal/
    sources:
        my-ppa.list:
            source: "deb http://ppa.launchpad.net/curtin-dev/test-archive/ubuntu $RELEASE main"
            keyid: B59D 5F15 97A5 04B7 E230  6DCA 0620 BBCF 0368 3F77
storage:
    layout:
        name: lvm
identity:
    hostname: hostname
    username: username
    password: $6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46
snaps:
    - name: go
      channel: 1.14/stable
      classic: true
debconf-selections: |
    bind9      bind9/run-resolvconf    boolean false
packages:
    - libreoffice
    - dns-server^
user-data:
    disable_root: false
late-commands:
    - sed -ie 's/GRUB_TIMEOUT=.\*/GRUB_TIMEOUT=30/' /target/etc/default/grub
error-commands:
    - tar c /var/log/installer | nc 192.168.0.1 1000
EOF
touch $CURRENT_DIR/seed$version/meta-data
sudo cloud-localds "$SEED_PATH" $CURRENT_DIR/seed$version/user-data $CURRENT_DIR/seed$version/meta-data





# Proceed with the rest of the parent.sh content

# Example:
read -p "Check user-data content and meta-data, Python script is running..."
cd $CURRENT_DIR

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
  --disk path="$SEED_PATH",device=cdrom \
  --location ${LOCATION},kernel=casper/vmlinuz,initrd=casper/initrd \
  --graphics vnc,port=5903,listen=0.0.0.0 \
  --os-variant ubuntu22.04 \
  --network bridge=virbr0 \
  --console pty,target_type=virtio \
	--extra-args 'autoinstall'