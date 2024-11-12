#!/bin/sh
# example custom installation file
# INITRD_UNPACKED contains full path to initrd root filesystem
VENDOR=/system/vendor/unknown321

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

install() {
  log "installing my binary"
#  mkdir -p ${VENDOR}/bin/
#  cp binary ${VENDOR}/bin/
#  chmod 0744 ${VENDOR}/bin/binary

  log "installing my service"
#  cp my.binary.init.rc ${INITRD_UNPACKED}/
#  chmod 0600 ${INITRD_UNPACKED}/my.binary.init.rc
#  grep -q "my.binary.init.rc" "${INITRD_UNPACKED}/init.rc"
#  if test $? -ne 0; then
#    log "adding service"
#    echo -e "import my.binary.init.rc\n$(cat ${INITRD_UNPACKED}/init.rc)" > "${INITRD_UNPACKED}/init.rc"
#  fi
}

mount -t ext4 -o rw /emmc@android /system

install

sync
umount /system