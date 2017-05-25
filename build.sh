#!/bin/bash

rm .version 2>/dev/null
rm arch/arm/boot/dt.img
rm arch/arm/boot/zImage

# Bash colors
green='\033[01;32m'
red='\033[01;31m'
cyan='\033[01;36m'
blue='\033[01;34m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(nproc --all)"
DEFCONFIG="caesium_defconfig"
KERNEL="zImage"

# Caesium Kernel Details
KERNEL_NAME="Caesium"
VER="v1.9"
VER="-$(date +"%Y%m%d"-"%H%M%S")-$VER"
DEVICE="-jalebi"
FINAL_VER="$KERNEL_NAME""$DEVICE""$VER"

# Vars
export ARCH=arm
export SUBARCH=arm
export KBUILD_BUILD_USER=MSF

# Paths
KERNEL_DIR=$(pwd)
RESOURCE_DIR="${KERNEL_DIR}"
ANYKERNEL_DIR="$RESOURCE_DIR/AnyKernel2"
TOOLCHAIN_DIR="/home/msfjarvis/git-repos/toolchains/arm-linux-gnueabi/"
#TOOLCHAIN_DIR="/home/msfjarvis/git-repos/toolchains/arm-eabi-4.8/"
REPACK_DIR="$ANYKERNEL_DIR"
ZIP_MOVE="$RESOURCE_DIR/out/"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm/boot"

# Functions
function make_kernel() {
  [ "$(hostname)" ] && ccache -z
  [ "${CLEAN}" ] && make clean
  make "${DEFCONFIG}" "${THREAD}"
  if [ "${MODULE}" ]; then
      make "${MODULE}" "${THREAD}"
  else
      make "${KERNEL}" "${THREAD}"
  fi
  [ -f "${ZIMAGE_DIR}/${KERNEL}" ] && cp -vr "${ZIMAGE_DIR}/${KERNEL}" "${REPACK_DIR}/zImage" || exit 1
}

function make_dtb() {
  make dtbs "${THREAD}"
  "${KERNEL_DIR}/dtbToolCM" -2 -o "${KERNEL_DIR}/arch/arm/boot/dt.img" -s 2048 -p "${KERNEL_DIR}/scripts/dtc/" "${KERNEL_DIR}/arch/arm/boot/dts/"
  [ -f "${KERNEL_DIR}/arch/arm/boot/dt.img" ] && cp -vr "${KERNEL_DIR}/arch/arm/boot/dt.img" "${REPACK_DIR}/dtb" || exit 1
}

function make_zip() {
  cd "${REPACK_DIR}"
  zip -ur kernel_temp.zip *
  mkdir -p "${ZIP_MOVE}"
  cp  kernel_temp.zip "${ZIP_MOVE}/${FINAL_VER}.zip"
  cd "${KERNEL_DIR}"
}

function tg() {
  curl -F chat_id="$TG_BETA_CHANNEL_ID" -F document="@$1" "https://api.telegram.org/bot$TG_BOT_ID/sendDocument"
  echo ""
}

function upload_to_tg() {
    echo -e "${cyan} Uploading file to Telegram ${restore}"
    tg "${ZIP_MOVE}/${FINAL_VER}.zip"
}

function afh_upload() {
  cd "${ZIP_MOVE}"
  wput ftp://${AFH_CREDENTIALS}@uploads.androidfilehost.com/ ${FINAL_VER}.zip
  cd ${KERNEL_DIR}
}

function push_and_flash() {
  adb push "${ZIP_MOVE}"/${FINAL_VER}.zip /external_sd/Caesium/
  adb shell twrp install "/external_sd/Caesium/${FINAL_VER}.zip"
}

while getopts ":ctabfm:" opt; do
  case $opt in
    c)
      echo -e "${cyan} Building clean ${restore}" >&2
      CLEAN=true
      ;;
    t)
      echo -e "${cyan} Will upload build to Telegram! ${restore}" >&2
      TG_UPLOAD=true
      ;;
    a)
      echo -e "${cyan} Will upload build to AFH ${restore}" >&2
      AFH_UPLOAD=true
      ;;
    b)
      echo -e "${cyan} Building ZIP only ${restore}" >&2
      ONLY_ZIP=true
      ;;
    f)
      echo -e "${cyan} Will auto-flash kernel ${restore}" >&2
      FLASH=true
      ;;
    m)
      MODULE="${OPTARG}"
      [[ "${MODULE}" == */ ]] || MODULE="${MODULE}/"
      if [[ ! "$(ls ${MODULE}Kconfig*  2>/dev/null)" ]]; then
          echo -e "${red} Invalid module specified - ${MODULE} ${restore}"
          exit 1
      fi
      echo -e "${cyan} Building module ${MODULE} ${restore}"
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      ;;
  esac
done

DATE_START=$(date +"%s")

# TC tasks
export CROSS_COMPILE=$TOOLCHAIN_DIR/bin/arm-linux-gnueabi-
export LD_LIBRARY_PATH=$TOOLCHAIN_DIR/lib/
cd "${KERNEL_DIR}"

# Make
if [ "${ONLY_ZIP}" ]; then
  make_dtb
  make_zip
else
  make_kernel
  make_dtb
  make_zip
fi

echo -e "${green}"
echo "${FINAL_VER}.zip"
echo "------------------------------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo " "

[ "${AFH_UPLOAD}" ] && afh_upload
[ "${TG_UPLOAD}" ] && upload_to_tg
[ "${FLASH}" ] && push_and_flash
