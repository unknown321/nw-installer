#!/bin/sh

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
PERIPHERAL_DIR=/system/etc/PeripheralUpdate
LOG_FILE=/var/update.log
CONSOLE=/dev/console

log()
{
    echo $1 > $CONSOLE
    echo $1 >> $LOG_FILE
}

##################################
# SOURCE_FILES should be same as mkfwp*.sh
# except update_uu.sh, md5.txt

SOURCE_FILES=" \
             boot.img \
             "

#             secro.img \
#             logo.bin \
#             tz.img \
#             system.img \
#             cm4.bin \
#             $FWUP_BG_IMG_NVP \


##################################
echo "------ FUNCTION ------"

format_and_write_partition()
{
    log "PARTITION=$PARTITION_NAME ORDER=$ORDER_PARTITION"

    # ex. "838860800 294884e0fcdae415462b72cf340acb35 system.img"
    cat md5.txt.0 | /xbin/busybox grep $SOURCE_FILE > md5.txt
    MD5_INFO=`cat md5.txt`

    OUT_PARTITION=/emmc@$PARTITION_NAME

    # ex. "android 0x0000000032000000 0x0000000006200000 2 /dev/block/mmcblk0p19"
    PARTITION_SIZE_HEX=`cat /proc/dumchar_info | busybox grep $PARTITION_NAME | busybox awk '{print $2}'`
    PARTITION_SIZE=`echo $(($PARTITION_SIZE_HEX))`

    if [ "$MD5_INFO" = "" ]; then
        log "/bin/dd if=/dev/zero of=$OUT_PARTITION bs=32768 count=`busybox expr $PARTITION_SIZE / 32768`"
        /bin/dd if=/dev/zero of=$OUT_PARTITION bs=32768 count=`busybox expr $PARTITION_SIZE / 32768`
        if [ "$?" != 0 ]; then
            log "dd erase($OUT_PARTITION) error"
            fwfb /root/fwup_err.rgb
            nvpflag fur $E_PARTITION
            exit 1
        fi

        log "fwpup -f $FWUP_FILE_PATH -$ORDER_PARTITION $OUT_PARTITION"
        fwpup -f $FWUP_FILE_PATH -$ORDER_PARTITION $OUT_PARTITION
        if [ "$?" != 0 ]; then
            log "fwpup($OUT_PARTITION) error"
            fwfb /root/fwup_err.rgb
            nvpflag fur $E_PARTITION
            exit 1
        fi
    else
        log "MD5_INFO=$MD5_INFO"
        # check binary image after write partition
        log "fwpup -z -f $FWUP_FILE_PATH -$ORDER_PARTITION $OUT_PARTITION"
        fwpup -z -f $FWUP_FILE_PATH -$ORDER_PARTITION $OUT_PARTITION
        if [ "$?" != 0 ]; then
            log "fwpup($OUT_PARTITION) error"
            fwfb /root/fwup_err.rgb
            nvpflag fur $E_PARTITION
            exit 1
        fi
    fi
}

write_bg_image()
{
    log "PARTITION=$PARTITION_NAME ORDER=$ORDER_PARTITION"

    fwpchk -f $FWUP_FILE_PATH -$ORDER_PARTITION $FWUP_BG_IMG_NVP
    if [ "$?" != 0 ]; then
        log "failed to get $FWUP_BG_IMG_NVP"
        /usr/local/bin/fwfb /root/fwup_err.rgb
        nvpflag fur $E_PARTITION
    else
        # ex. "-rw------- root root 12109 1970-01-01 00:00 fwup_bg.dat"
        size=`ls -l $FWUP_BG_IMG_NVP | awk '{print $4}'`
        nvp zwf 75 $size $FWUP_BG_IMG_NVP
    fi
}

optproc_for_updater()
{
    mount -t ext4 -o ro /emmc@android /system
    /system/usr/bin/optproc_for_updater.sh
    umount /system
}

##################################
log "------ INIT SEQUENCE ------"

#echo 0 >  /sys/class/leds/dtb:gpio:LED_RED_1/brightness
#echo 0 >  /sys/class/leds/dtb:gpio:LED_GREEN_1/brightness
#echo 0 >  /sys/class/leds/dtb:pwm:LED_RED_2/brightness
#echo 0 >  /sys/class/leds/dtb:pwm:LED_GREEN_2/brightness

_UPDATE_FN_=`nvpstr ufn`
if [ "$?" != 0 ]; then
	echo "nvpstr(ufn) error"
	fwfb /root/fwup_err.rgb
    nvpflag fur $E_NVP
	exit 1
fi

FWUP_FILE_PATH=/contents/$_UPDATE_FN_.UPG
log "FWUP_FILE_PATH=$FWUP_FILE_PATH"

ORDER_PARTITION=2

for SOURCE_FILE in ${SOURCE_FILES[@]}
do
    case $SOURCE_FILE in
         lk.bin)            PARTITION_NAME=$UBOOT_PARTITION_NAME
                            E_PARTITION=$E_UBOOT
                            #echo 255 > /sys/class/leds/dtb:gpio:LED_RED_1/brightness
                            ;;
         boot.img)          PARTITION_NAME=$COMMON_KERNEL_PARTITION_NAME
                            E_PARTITION=$E_KERNEL
                            #echo 255 > /sys/class/leds/dtb:gpio:LED_RED_1/brightness
                            ;;
         recovery.img)      PARTITION_NAME=$RECOVERY_KERNEL_PARTITION_NAME
                            E_PARTITION=$E_RECOVERY
                            ;;
         secro.img)         PARTITION_NAME=$SEC_RO_PARTITION_NAME
                            E_PARTITION=$E_SECRO
                            ;;
         logo.bin)          PARTITION_NAME=$LOGO_PARTITION_NAME
                            E_PARTITION=$E_LOGO
                            ;;
         tz.img)            PARTITION_NAME=$TEE1_PARTITION_NAME
                            E_PARTITION=$E_TEE1
                            ;;
         system.img)        PARTITION_NAME=$SYSTEM_PARTITION_NAME
                            E_PARTITION=$E_SYSTEM
                            #echo 255 > /sys/class/leds/dtb:gpio:LED_GREEN_1/brightness
                            ;;
         chrome.img)        PARTITION_NAME=$CHROME_PARTITION_NAME
                            E_PARTITION=$E_CHROME
                            #echo 255 > /sys/class/leds/dtb:pwm:LED_RED_2/brightness
                            ;;
         cm4.bin)           PARTITION_NAME=$CM4_PARTITION_NAME
                            E_PARTITION=$E_CM4
                            ;;
         option1.img)       PARTITION_NAME=$OPTION1_PARTITION_NAME
                            E_PARTITION=$E_OPT1
                            ;;
         option2.img)       PARTITION_NAME=$OPTION2_PARTITION_NAME
                            E_PARTITION=$E_OPT2
                            ;;
         option3.img)       PARTITION_NAME=$OPTION3_PARTITION_NAME
                            E_PARTITION=$E_OPT3
                            ;;
         $FWUP_BG_IMG_NVP)  PARTITION_NAME=$NVP_PARTITION_NAME
                            E_PARTITION=$E_BGI
                            ;;
         *)                 echo $SOURCE_FILE does not exist
                            continue
                            ;;
    esac

    if [ $SOURCE_FILE = $FWUP_BG_IMG_NVP ]; then
        write_bg_image
    else
        format_and_write_partition
        if [ $SOURCE_FILE = tz.img ]; then
            # update tee2 partition by using same image file as tee1
            PARTITION_NAME=$TEE2_PARTITION_NAME
            E_PARTITION=$E_TEE2
            format_and_write_partition
        fi
    fi

    ORDER_PARTITION=`busybox expr $ORDER_PARTITION + 1`
done

optproc_for_updater

sync
sync

log "------ UPDATED!! ------"
#echo 255 >  /sys/class/leds/dtb:pwm:LED_GREEN_2/brightness

exit 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
