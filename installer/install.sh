#!/bin/sh

nvpflag fup -1
##################################
echo "------ DEFINITION ------"

UBOOT_PARTITION_NAME=uboot
COMMON_KERNEL_PARTITION_NAME=bootimg
RECOVERY_KERNEL_PARTITION_NAME=recovery
SEC_RO_PARTITION_NAME=sec_ro
LOGO_PARTITION_NAME=logo
TEE1_PARTITION_NAME=tee1
TEE2_PARTITION_NAME=tee2
SYSTEM_PARTITION_NAME=android
CHROME_PARTITION_NAME=chrome
CM4_PARTITION_NAME=cm4
OPTION1_PARTITION_NAME=option1
OPTION2_PARTITION_NAME=option2
OPTION3_PARTITION_NAME=option3
NVP_PARTITION_NAME=nvp

FWUP_BG_IMG_NVP=fwup_bg.dat
LOG_FILE=/contents/upgrade.log
CONSOLE=/dev/console

#IMPORT_RC="import init.nw-scrob.rc"

# taken from original firmware
#state='{"xflash": false, "hwcode": 34192, "flashtype": "emmc", "flashsize": 15634268160, "m_emmc_ua_size": 15634268160, "m_emmc_boot1_size": 4194304, "m_emmc_boot2_size": 4194304, "m_emmc_gp_size": [0, 0, 0, 0], "m_nand_flash_size": 0, "m_sdmmc_ua_size": 0, "m_nor_flash_size": 0}'

# why opt2?
# cpio --create breaks symlinks on rootfs
WORKDIR=/opt2/workdir
TEMPDIR="/contents/steps"
BLOCK_FILE="${WORKDIR}/boot"
DD="/xbin/busybox dd"
GUNZIP="/xbin/busybox gunzip"
FIND="/xbin/busybox find"
SORT="/xbin/busybox sort"
GREP="/xbin/busybox grep"
MD5SUM="/xbin/busybox md5sum"
TAR="/xbin/busybox tar"
INITRD_UNPACKED="${WORKDIR}/unpacked"
INITRD="${WORKDIR}/initrd"
TOOLS="${WORKDIR}/tools"
ABOOTIMG="${TOOLS}/abootimg"
UPGTOOL="${TOOLS}/upgtool"
CPIO="${TOOLS}/cpio"
CPIOSTRIP="${TOOLS}/cpiostrip"
MTKHEADER="${TOOLS}/mtkheader"
USERDATA="${WORKDIR}/userdata.tar.gz"
USERDATA_CONTENTS="/contents/userdata.tar.gz"
USERDATA_DIR="/contents/userdata"
GZIP="${TOOLS}/gzip"
ANDROID_HEADER_SKIP=576
USB_MOUNTED_FILE="/contents/DevIcon.fil"
MODEL="nw-a50"
WALKMAN_ONE_FLAG=

mount -o remount,rw,noatime /opt2

rm -r ${WORKDIR}
mkdir -p "${WORKDIR}"
mkdir -p "${TOOLS}"

log()
{
        oldIFS=$IFS

        IFS="
"
        for line in $(echo "${1}"); do
                echo "$(date) ${line}" >> $LOG_FILE
        done

        IFS=$oldIFS
}

##################################
echo "------ FUNCTION ------"

# detectModel looks for patched fwpchk with modified decryption keys
detectModel() {
  # walkmanOne?
  if test -f /opt2/stock/conf_bk; then
    MODEL=nw-wm1a
    WALKMAN_ONE_FLAG="-w"
    ${DD} if=/opt2/stock/conf_bk skip=40960 bs=1 count=24 > /tmp/real_model
    REAL_MODEL=$(cat /tmp/real_model)
    log "Model: $REAL_MODEL, walkmanOne ($MODEL)"
  else
    MODEL_ID=$(nvpflag -x mid)
    case "${MODEL_ID}" in
      "0x24000004")
        MODEL=nw-a40
        ;;
      "0x25000004")
        MODEL=nw-a50
        ;;
      "0x21000008")
        MODEL=nw-wm1z
        ;;
    esac
    log "Model: $MODEL"
  fi
}

infoCollect() {
  log "==========================="
  log "nvpflag -x mid: $(nvpflag -x mid)"
  log "nvpstr fpi: $(nvpstr fpi)"
  log "mem:"
  log "$(cat /proc/meminfo)"
  log "cpu:"
  log "$(cat /proc/cpuinfo)"
  log "emmc:"
  log "$(cat /proc/emmc)"
  log "storage:"
  log "$(busybox df -h)"
  log "busybox:"
  log "$(busybox)"
  log "==========================="
}

preflightTest() {
  if test ! -f ${USB_MOUNTED_FILE}; then
    echo "usb mounted, unmount usb and rerun"
    log "usb mounted, unmount usb and rerun"
    exit 0
  fi
}

unpack() {
  fwpchk -f $FWUP_FILE_PATH -2 ${CPIOSTRIP}
  chmod 777 ${CPIOSTRIP}

  fwpchk -f $FWUP_FILE_PATH -3 ${MTKHEADER}
  chmod 777 ${MTKHEADER}

  fwpchk -f $FWUP_FILE_PATH -4 ${CPIO}
  chmod 777 ${CPIO}

  fwpchk -f $FWUP_FILE_PATH -5 ${GZIP}
  chmod 777 ${GZIP}

  fwpchk -f $FWUP_FILE_PATH -6 ${ABOOTIMG}
  chmod 777 ${ABOOTIMG}

  fwpchk -f $FWUP_FILE_PATH -7 ${UPGTOOL}
  chmod 777 ${UPGTOOL}

  fwpchk -f $FWUP_FILE_PATH -8 ${USERDATA}
  chmod 0644 ${USERDATA}

  fwpchk -f $FWUP_FILE_PATH -9 /update_orig.sh
  chmod 0755 /update_orig.sh
}

isAndroid() {
 MAGIC=$(/xbin/busybox head -c 8 ${BLOCK_DEVICE})

 if test "${MAGIC}" != "ANDROID!"; then
   log "not android"
   exit 0
 fi
}

getBlockDevice() {
  PARTITION_NAME=bootimg
  BLOCK_DEVICE=`cat /proc/dumchar_info | ${GREP} $PARTITION_NAME | busybox awk '{print $NF}'`
  unset PARTITION_NAME
}

dumpBlockDevice() {
  ${DD} if=${BLOCK_DEVICE} of="${BLOCK_FILE}"

  P="${TEMPDIR}/0.dump/"
  mkdir -p $P
  cp ${BLOCK_FILE} $P
  log "$(${MD5SUM} ${BLOCK_FILE} 2>&1)"
}

extractInitrd() {
  log "extracting initrd"

  cd "${WORKDIR}"

  log "$(${ABOOTIMG} -i ${BLOCK_FILE})"

  ${ABOOTIMG} -x "${BLOCK_FILE}"

  log "splitting initrd"
  ${DD} if=initrd.img of=${INITRD}_header bs=512 count=1
  ${DD} if=initrd.img of=${INITRD}.gz bs=512 skip=1
  log "$(${MD5SUM} ${INITRD}_header)"
  log "$(${MD5SUM} ${INITRD}.gz)"

  log "unzipping initrd"
  ${GUNZIP} ${INITRD}.gz
  log "$(${MD5SUM} ${INITRD})"

  mkdir -p "${INITRD_UNPACKED}"

  P="${TEMPDIR}/1.extractInitrd/"
  mkdir -p $P
  cp ${INITRD} $P
  cp ${INITRD}_header $P

  log "unarchiving initrd cpio"

  log "${CPIO} -D \"${INITRD_UNPACKED}\" -idmv --no-absolute-filenames --file \"${INITRD}\""
  ${CPIO} -D "${INITRD_UNPACKED}" -idm --no-absolute-filenames --file "${INITRD}"

  if test ! -f "${INITRD_UNPACKED}/init.hagoromo.rc"; then
    log "unarchiving failed"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  rm ${INITRD} ${INITRD}.gz ${INITRD}.img
}

install() {
  log "installing"
  mkdir -p ${USERDATA_DIR}
  if test -f ${USERDATA_CONTENTS}; then
    USERDATA=${USERDATA_CONTENTS}
  fi
  log "using ${USERDATA_CONTENTS} as data source"
  ${TAR} -C ${USERDATA_DIR} -xf ${USERDATA}

  log "executing userscript"
  cd ${USERDATA_DIR}
  log "$(INITRD_UNPACKED=${INITRD_UNPACKED} LOG_FILE=${LOG_FILE} /bin/sh ${USERDATA_DIR}/run.sh)"

  log "removing unpacked userdata"
  rm -r "${USERDATA_DIR}"

  log "removing userdata ${USERDATA}"
  rm -r "${USERDATA}"

  cd ${WORKDIR}
}

pack() {
  rm ${INITRD_UNPACKED}/lib/1 # ???
  mkdir ${INITRD_UNPACKED}/install_update_script/logs
  chmod 0755 ${INITRD_UNPACKED}/install_update_script/logs
  chown 1000:1000 ${INITRD_UNPACKED}/install_update_script/logs

  mkdir ${INITRD_UNPACKED}/logs
  chmod 0755 ${INITRD_UNPACKED}/logs
  chown 1000:1000 ${INITRD_UNPACKED}/logs

#  echo -n "${state}" > ${INITRD_UNPACKED}/install_update_script/.state
#  chown 1000:1000 ${INITRD_UNPACKED}/install_update_script/.state
#  chmod 0644 ${INITRD_UNPACKED}/install_update_script/.state

#  echo -n "${state}" > ${INITRD_UNPACKED}/.state
#  chown 1000:1000 ${INITRD_UNPACKED}/.state
#  chmod 0644 ${INITRD_UNPACKED}/.state

  cd ${INITRD_UNPACKED}

  log "archiving cpio, directory ${INITRD_UNPACKED} = $(pwd)"
  log "${FIND} . | ${GREP} -vE \"^.$\" | ${SORT} -sd | ${CPIO} --create --device-independent --reset-access-time --format="newc" -O \"${INITRD}\""
  ${FIND} . | ${GREP} -vE "^.$" | ${SORT} -sd | ${CPIO} --create --device-independent --reset-access-time --format="newc" -O "${INITRD}"

   size=$(busybox stat -c %s "${INITRD}")
   # size might be less than original, but definitely not less than 1mb
   if test $size -lt $((1024*1024)); then
     log "${INITRD} size is $size, expected at least 1mb"
     exit 0
   fi

  log "$(${MD5SUM} ${INITRD})"

  log "stripping timestamps"
  ${CPIOSTRIP} ${INITRD}

  log "$(${MD5SUM} ${INITRD})"

  if test ! -s "${INITRD}"; then
    log "archiving failed"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  cd ${WORKDIR}

  P="${TEMPDIR}/2.pack/"
  mkdir -p $P
  cp ${INITRD} $P

  log "gzipping patched initrd"
  ${GZIP} -9 -f "${INITRD}"

  log "$(${MD5SUM} ${INITRD}.gz)"

  cp ${INITRD}.gz $P

  if test ! -s "${INITRD}.gz"; then
    log "gzipping failed"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  log "adding back header"
  cat ${INITRD}_header ${INITRD}.gz > "${INITRD}.img"

  log "patching header"
  ${MTKHEADER} -header "${INITRD}.img" -content "${INITRD}.gz"

  size=$(busybox stat -c %s "${INITRD}.img")

  # size might be less than original initrd due to compression, but definitely not less than 1mb
  if test $size -lt $((1024*1024)); then
    log "${INITRD}.img size is $size, expected at least 1mb"
    exit 0
  fi

  log "$(${MD5SUM} ${INITRD}.img)"

  cp ${INITRD}.img $P
}

updateBootImg() {
  log "updating boot image"
  cd "${WORKDIR}"

  ${ABOOTIMG} -u ${BLOCK_FILE} -r ${INITRD}.img -c bootsize=

  if test $? -ne 0; then
    log "abootimg update bootimg failed"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  log "$(${MD5SUM} ${BLOCK_FILE})"
  log "$(${ABOOTIMG} -i ${BLOCK_FILE})"

  P="${TEMPDIR}/3.updateBootImg/"
  mkdir -p $P
  cp ${BLOCK_FILE} $P

  cp ${BLOCK_FILE} ${BLOCK_FILE}.img
}

updateBlockDevice() {
  log "updating block device ${BLOCK_DEVICE}"
  ${DD} if="${BLOCK_FILE}" of=${BLOCK_DEVICE}

    if test $? -ne 0; then
      log "update block device failed"
      log "$(/xbin/busybox find ${WORKDIR})"
      exit 0
    fi
}

newBootImg() {
  log "creating new bootimg file with patched initrd"

  cd "${WORKDIR}"

  ${ABOOTIMG} --create ${BLOCK_FILE}.img -f bootimg.cfg -k zImage -r initrd.img

  log "$(${MD5SUM} ${BLOCK_FILE}.img)"

  # patch image id
  ${DD} if=${BLOCK_FILE} of=${BLOCK_FILE}.img skip=${ANDROID_HEADER_SKIP} seek=${ANDROID_HEADER_SKIP} ibs=1 obs=1 count=32 conv=notrunc

  log "$(${MD5SUM} ${BLOCK_FILE}.img)"

  # abootimg also checks if image valid
  ID_ORIG=$(${ABOOTIMG} -i ${BLOCK_DEVICE} | ${GREP} "id =")
  ID_NEW=$(${ABOOTIMG} -i ${BLOCK_FILE}.img | ${GREP} "id =")

  if test "${ID_NEW}" != "${ID_ORIG}"; then
    log "android image id mismatch"
    log "new image id: ${ID_NEW}"
    log "orig image id: ${ID_ORIG}"
    exit 0
  fi

  log "$(${ABOOTIMG} -i ${BLOCK_FILE})"
}

createUPG() {
  rm $FWUP_FILE_PATH

  cd ${WORKDIR}

  echo -n > empty.txt
  log "${UPGTOOL} -m ${MODEL} ${WALKMAN_ONE_FLAG} --create $FWUP_FILE_PATH -z 2,boot.img /update_orig.sh empty.txt ${BLOCK_FILE}.img"
  ${UPGTOOL} -m ${MODEL} ${WALKMAN_ONE_FLAG} --create $FWUP_FILE_PATH -z 2,boot.img /update_orig.sh empty.txt ${BLOCK_FILE}.img

  if test $? -ne 0; then
    log "creating upg failed"
    exit 0
  fi

  log "pre-flash check, upg"
  if test ! -s $FWUP_FILE_PATH; then
    log "failed pre-flash check, upg"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  fwpchk -c -f ${FWUP_FILE_PATH}
  if test $? -ne 0; then
    log "fwpchk failed"
    log "$(fwpchk -c -f ${FWUP_FILE_PATH})"
    exit 0
  fi

  log "$(${MD5SUM} ${FWUP_FILE_PATH})"
}

clean() {
    rm -r "${TEMPDIR}"
    rm -r "${WORKDIR}"
}
##################################

rm $LOG_FILE

log "------ INIT SEQUENCE ------"

_UPDATE_FN_=`nvpstr ufn`
if [ "$?" != 0 ]; then
	echo "nvpstr(ufn) error"
	fwfb /root/fwup_err.rgb
    nvpflag fur $E_NVP
	exit 1
fi

FWUP_FILE_PATH=/contents/$_UPDATE_FN_.UPG
log "FWUP_FILE_PATH=$FWUP_FILE_PATH"

preflightTest
infoCollect
detectModel
unpack
getBlockDevice
isAndroid
dumpBlockDevice
extractInitrd
install
pack
#newBootImg
updateBootImg
createUPG
clean

nvpflag fup 0x70555766 # run update again with new upg
nvpflag fur 0x4C504D43 # complete

log "done"

umount /contents
umount /var

sync
sync

# prevent parent script from unsetting update flag
reboot
