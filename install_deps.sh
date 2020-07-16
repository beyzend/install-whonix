#!/bin/bash

set -euo pipefail
source ./common.sh

step "Installing required dependencies."
substep "Requesting sudo password to install packages."
sudo apt-get update
#sudo apt-get install -y qemu-kvm libvirt-bin virt-manager libvirt-daemon-system libvirt-clients
sudo apt-get install qemu-kvm libvirt-daemon-system libvirt-clients virt-manager gir1.2-spiceclientgtk-3.0 dnsmasq
step "Done! You may also want to install and enable apparmor if you haven't already."
step "The next step is 'user_setup.sh'."
