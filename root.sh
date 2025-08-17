#!/bin/sh
# Foxytoux Ubuntu + Docker + systemctl installer (Refactored)

ROOTFS_DIR=$(pwd)
ARCH=$(uname -m)
MAX_RETRIES=50
TIMEOUT=30

# Detect architecture
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

banner() {
  clear
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

# Already installed?
if [ -e "$ROOTFS_DIR/.installed" ]; then
  banner
  exec $ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/bash
fi

echo "#######################################################################################"
echo "#"
echo "#                          Foxytoux INSTALLER (Ubuntu + Docker)"
echo "#"
echo "#######################################################################################"
echo

read -p "Do you want to install Ubuntu? (YES/no): " install_ubuntu

case $install_ubuntu in
  [yY][eE][sS])
    echo "[*] Downloading Ubuntu base rootfs..."
    wget --tries=$MAX_RETRIES --timeout=$TIMEOUT --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz" || {
        echo "Download failed."
        exit 1
      }
    echo "[*] Extracting..."
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Ubuntu installation."
    ;;
esac

echo "[*] Installing proot..."
mkdir -p $ROOTFS_DIR/usr/local/bin
wget --tries=$MAX_RETRIES --timeout=$TIMEOUT --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
  "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
chmod 755 $ROOTFS_DIR/usr/local/bin/proot

echo "[*] Setting DNS..."
printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > ${ROOTFS_DIR}/etc/resolv.conf

echo "[*] Installing Docker + systemctl (inside rootfs)..."
$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/sh -c "
    apt-get update &&
    DEBIAN_FRONTEND=noninteractive apt-get install -y systemd docker.io docker-compose &&
    ln -s /usr/bin/systemctl /bin/systemctl || true
"

touch $ROOTFS_DIR/.installed

banner
exec $ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit /bin/bash
