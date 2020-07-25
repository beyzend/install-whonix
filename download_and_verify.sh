#!/bin/bash

set -euo pipefail
source ./common.sh

error_if_root # Running this with sudo privileges can't be a good idea.

# See config.sh for the $VERSION variable
BASE="https://download.whonix.org/libvirt/$VERSION"

# https://download.whonix.org/libvirt/15.0.1.3.9/Whonix-XFCE-15.0.1.3.9.libvirt.xz

WHONIX_FILE="Whonix-XFCE-$VERSION.libvirt.xz"
WHONIX_URL="$BASE/$WHONIX_FILE"
WHONIX_SIG="$WHONIX_FILE.asc"
WHONIX_SIG_URL="$BASE/$WHONIX_SIG"

GATEWAY_URL="$BASE/Whonix-Gateway-$VERSION.libvirt.xz"
GATEWAY_SIG="$BASE/Whonix-Gateway-$VERSION.libvirt.xz.asc"
GATEWAY_SHA="$BASE/Whonix-Gateway-$VERSION.sha512sums"
GATEWAY_SHA_SIG="$BASE/Whonix-Gateway-$VERSION.sha512sums.asc"

WORKSTATION_URL="$BASE/Whonix-Workstation-$VERSION.libvirt.xz"
WORKSTATION_SIG="$BASE/Whonix-Workstation-$VERSION.libvirt.xz.asc"
WORKSTATION_SHA="$BASE/Whonix-Workstation-$VERSION.sha512sums"
WORKSTATION_SHA_SIG="$BASE/Whonix-Workstation-$VERSION.sha512sums.asc"

SIGNING_KEY_URL='https://www.whonix.org/patrick.asc'
SIGNING_ID='8D66066A2EEACCDA'
SIGNING_EMAIL='Patrick Schleizer <adrelanos@riseup.net>'
SIGNING_FINGERPRINT='Key fingerprint = 916B 8D99 C38E AF5E 8ADC  7A2A 8D66 066A 2EEA CCDA'

#SIGNING_ID_HULA='50C78B6F9FF2EC85'

THIS_COMMAND="$0"

function get {
    curl --tlsv1.2 --proto =https $1 -o $2 
}

function fail_signing_key_verification {
    error "Unable to verify signing key! This really shouldn't happen."
}

function fail_verification {
    error "Unable to verify $1! This can happen with interrupted or corrupted downloads.\n Try deleting the '$WORKING_DIR' directory and running '$THIS_COMMAND' again."
}

step "Network Start: Ensure KVM's / QEMU's default networking is enabled and has started"
virsh -c qemu:///system net-autostart default || true
virsh -c qemu:///system net-start default || true
step "DONE!"

# See config.sh for the $WORKING_DIR variable
mkdir -p $WORKING_DIR
cd $WORKING_DIR

# delete any signatures or checksums that may be lying around
silently rm *.asc *.sha512sums *.xml *.qcow2 || true

step "Downloading Whonix VM's."
substep "Downloading Whonix images"
#curl --tlsv1.2 --proto =https $WHONIX_URL -o $WHONIX_FILE 
#get $WHONIX_URL $WHONIX_FILE
get $WHONIX_SIG_URL $WHONIX_SIG



step "Verifying the downloads."

substep "Downloading and verifying the signing key."
quietly gpg --fingerprint # just in case this has never been run
quietly chmod --recursive og-rwx ~/.gnupg
#get $SIGNING_KEY_URL -O patrick.asc
get $SIGNING_KEY_URL patrick.asc
gpg --keyid-format long --with-fingerprint patrick.asc | grep -q "$SIGNING_ID" || \
    fail_signing_key_verification
gpg --keyid-format long --with-fingerprint patrick.asc | grep -q "$SIGNING_EMAIL" || \
    fail_signing_key_verification
gpg --keyid-format long --with-fingerprint patrick.asc | grep -q "$SIGNING_FINGERPRINT" || \
    fail_signing_key_verification

substep "Signing key verified. Importing."
gpg --import patrick.asc

substep "Verifying Whonix Download."
gpg --verify-options show-notations --verify Whonix*.libvirt.xz.asc Whonix*.libvirt.xz || \
    fail_verification "Whonix-Gateway"
substep "Success!"

substep "Files verified successfully."

step "Decompressing verified VMs."
tar -xf Whonix*.libvirt.xz

step "Done!"
step "The next step is 'setup_kvm.sh'."
