#!/bin/sh

echo "------ flag reset ------"
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
MKDIR="/xbin/busybox mkdir"
CP="/xbin/busybox cp"
RM="/xbin/busybox rm"
CHMOD="/xbin/busybox chmod"
CHOWN="/xbin/busybox chown"
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

${RM} -r ${WORKDIR}
${MKDIR} -p "${WORKDIR}"
${MKDIR} -p "${TOOLS}"

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
    MODEL_ID=$(nvpflag -x mid | cut -c1-8)
    case "${MODEL_ID}" in
      "0x240000")
        MODEL=nw-a40
        ;;
      "0x250000")
        MODEL=nw-a50
        ;;
      "0x210000")
        MODEL=nw-wm1z
        ;;
    esac

    KAS=$(nvpstr kas)
    if test $KAS == "37af6a313e5c0a2c24353937a87352d6dd49de9dab2bce5a59090c01049576d5"; then
        MODEL=nw-a50z
        WALKMAN_ONE_FLAG="--a50z"
    fi

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
  ${CHMOD} 777 ${CPIOSTRIP}

  fwpchk -f $FWUP_FILE_PATH -3 ${MTKHEADER}
  ${CHMOD} 777 ${MTKHEADER}

  fwpchk -f $FWUP_FILE_PATH -4 ${CPIO}
  ${CHMOD} 777 ${CPIO}

  fwpchk -f $FWUP_FILE_PATH -5 ${GZIP}
  ${CHMOD} 777 ${GZIP}

  fwpchk -f $FWUP_FILE_PATH -6 ${ABOOTIMG}
  ${CHMOD} 777 ${ABOOTIMG}

  fwpchk -f $FWUP_FILE_PATH -7 ${UPGTOOL}
  ${CHMOD} 777 ${UPGTOOL}

  fwpchk -f $FWUP_FILE_PATH -8 /update_orig.sh
  ${CHMOD} 0755 /update_orig.sh

  if test -f ${USERDATA_CONTENTS}; then
    USERDATA=${USERDATA_CONTENTS}
    log "using ${USERDATA_CONTENTS} as data source"
  else
    fwpchk -f $FWUP_FILE_PATH -9 ${USERDATA}
    ${CHMOD} 0644 ${USERDATA}
  fi
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
  ${MKDIR} -p $P
  ${CP} ${BLOCK_FILE} $P
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

  ${MKDIR} -p "${INITRD_UNPACKED}"

  P="${TEMPDIR}/1.extractInitrd/"
  ${MKDIR} -p $P

  ${CP} ${INITRD} $P
  ${CP} ${INITRD}_header $P

  log "unarchiving initrd cpio"

  log "${CPIO} -D \"${INITRD_UNPACKED}\" -idmv --no-absolute-filenames --file \"${INITRD}\""
  ${CPIO} -D "${INITRD_UNPACKED}" -idm --no-absolute-filenames --file "${INITRD}"

  if test ! -f "${INITRD_UNPACKED}/init.hagoromo.rc"; then
    log "unarchiving failed"
    log "$(/xbin/busybox find ${WORKDIR})"
    exit 0
  fi

  ${RM} ${INITRD} ${INITRD}.gz ${INITRD}.img
}

install() {
  log "installing"
  ${MKDIR} -p ${USERDATA_DIR}
  ${TAR} -C ${USERDATA_DIR} -xf ${USERDATA}

  log "executing userscript"
  cd ${USERDATA_DIR}
  log "$(INITRD_UNPACKED=${INITRD_UNPACKED} LOG_FILE=${LOG_FILE} /bin/sh ${USERDATA_DIR}/run.sh)"

  log "removing unpacked userdata"
  ${RM} -r "${USERDATA_DIR}"

  log "removing userdata ${USERDATA}"
  ${RM} -r "${USERDATA}"

  cd ${WORKDIR}
}

pack() {
  ${RM} ${INITRD_UNPACKED}/lib/1 # ???
  ${MKDIR} ${INITRD_UNPACKED}/install_update_script/logs
  ${CHMOD} 0755 ${INITRD_UNPACKED}/install_update_script/logs
  ${CHOWN} 1000:1000 ${INITRD_UNPACKED}/install_update_script/logs

  ${MKDIR} ${INITRD_UNPACKED}/logs
  ${CHMOD} 0755 ${INITRD_UNPACKED}/logs
  ${CHOWN} 1000:1000 ${INITRD_UNPACKED}/logs

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
  ${MKDIR} -p $P
  ${CP} ${INITRD} $P

  log "gzipping patched initrd"
  ${GZIP} -9 -f "${INITRD}"

  log "$(${MD5SUM} ${INITRD}.gz)"

  ${CP} ${INITRD}.gz $P

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

  ${CP} ${INITRD}.img $P
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
  ${MKDIR} -p $P
  ${CP} ${BLOCK_FILE} $P

  log "${CP} -v ${BLOCK_FILE} ${BLOCK_FILE}.img"
  log "$(${CP} -v ${BLOCK_FILE} ${BLOCK_FILE}.img 2>&1)"
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


createUPG() {
  ${RM} $FWUP_FILE_PATH

  cd ${WORKDIR}

  echo -n > empty.txt
  log "${UPGTOOL} -m ${MODEL} ${WALKMAN_ONE_FLAG} --create $FWUP_FILE_PATH -z 2,boot.img /update_orig.sh empty.txt ${BLOCK_FILE}.img"
  log "$(${UPGTOOL} -m ${MODEL} ${WALKMAN_ONE_FLAG} --create $FWUP_FILE_PATH -z 2,boot.img /update_orig.sh empty.txt ${BLOCK_FILE}.img 2>&1)"

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
    ${RM} -r "${TEMPDIR}"
    ${RM} -r "${WORKDIR}"
}

##################################

${RM} $LOG_FILE

_UPDATE_FN_=`nvpstr ufn`
if [ "$?" != 0 ]; then
	log "nvpstr(ufn) error"
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
