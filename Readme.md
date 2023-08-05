# Install Ubuntu in 1 command

[![Travis Build Status](https://img.shields.io/travis/a-t-0/shell_unit_testing_template.svg)](https://travis-ci.org/a-t-0/shell_unit_testing_template)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

If you want to share a MWE with someone that does not affect their system, give
these commands to let them:

- Install Qemu
- Download an Ubuntu .iso from the trusted Ubuntu website.
- Run your `kickstart.cfg` file to automatically install that `.iso` in Qemu.
- Include the setup you want to share as a post-script such that the other
  person has the exact same system as you.

Alternatively, use this to automatically configure your pc/laptop from an
empty hardrive.

## Usage

```bash
# Install qemu.
sudo apt-get install qemu-kvm
# Install the virtual installer that installs Ubuntu on Qemu.
sudo apt-get install virt-install
# Allow copy paste between qemu Ubuntu and your own device
sudo apt-get install spice-vdagent
# Allow a bridge between qemu and your own device to grant Ubuntu internet.
sudo apt-get install libvirt-daemon-system
sudo apt-get install libvirt-clients
#sudo apt-get install python-libvirt



# Create working directory
cd ~
mkdir -p ~/qemus
cd ~/qemus

# Download the Ubuntu iso.
#wget https://releases.ubuntu.com/jammy/ubuntu-22.04.2-desktop-amd64.iso
wget https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso


# Then create image with:
qemu-img create ubuntu.img 30G

# Set ubuntu release to create
release="trusty"
# Create vm drive for installation
qemu-img create -f qcow2 \
  ./${release}.qcow2 30G

# Allow a network bridge between qemu and your laptop.
sudo mkdir -p /usr/local/etc/qemu
sudo mkdir -p /etc/qemu
sudo sh -c 'echo "allow virbr0" > /usr/local/etc/qemu/bridge.conf'
sudo sh -c 'echo "allow virbr0" > /etc/qemu/bridge.conf'


# Start installation
virt-install --name base-${release} --ram 2048 \
  --disk path=./${release}.qcow2,size=8 \
  --check path_in_use=off \
  --vcpus 1 \
  --os-variant ubuntu-lts-latest \
  --network default \
  --graphics none \
  --console pty,target_type=serial \
  --noreboot \
  --location \
  "http://archive.ubuntu.com/ubuntu/dists/${release}/main/installer-amd64/" \
  --extra-args "console=ttyS0,115200n8 ks=src/kickstart.cfg"

# To boot the Virtual machine, run:
qemu-system-x86_64 \
  --enable-kvm \
  -m 1024 \
  -machine smm=off \
  -cdrom $PWD/ubuntu-23.04-desktop-amd64.iso \
  -cdrom ~/Downloads/ubuntu-22.04.1-desktop-amd64.iso \
  -boot order=d ${release}.qcow2
```

## Debugging

If you get:
`is already in use by other guests ['base-trusty']` error, the following
resolved the issue:

```bash
ps ax | grep -i trusty
```

Gives long output with some process id, e.g.:

```txt
 508724 ?        Sl     0:09 /usr/bin/qemu-system-x86_64 -name
 guest=base-trusty,debug-threads=on -S -object {"qom-type":"secret","id":
 "masterKey0","format":"raw","file":"/home/
 /.config/libvirt/qemu/lib/domain-2-base-trusty/ etc.
```

Then stop that process with:

```bash
sudo kill 508724
```

Repeat until no, or only 1 line with `base-trusty` remains in
the `ps ax | grep -i trusty` command.

Alternative [strategy I](https://serverfault.com/questions/765874/cant-create-kvm-virtual-machine-with-same-name-after-initial-failed-attempt)

```bash
# Delete any old files from a previous installation
sudo rm -r /etc/libvirt/*
sudo rm -r /var/lib/libvirt/*
```

Alternative [strategy II](https://askubuntu.com/questions/160152/virt-install-says-name-is-in-use-but-virsh-list-all-is-empty-where-is-virt-i)

```bash
virsh
undefine base-trusty
quit
```

Note, the later two strategies were ran before the first strategy was found
working. It is not sure whether they are required for the first strategy to
work.

## Testing

Put your unit test files (with extension .bats) in folder: `/test/`

### Prerequisites

(Re)-install the required submodules with:

```sh
chmod +x install-bats-libs.sh
./install-bats-libs.sh
```

Install:

```sh
sudo gem install bats
sudo gem install bashcov
sudo apt install shfmt -y
pre-commit install
pre-commit autoupdate
```

### Pre-commit

Run pre-commit with:

```sh
pre-commit run --all
```
