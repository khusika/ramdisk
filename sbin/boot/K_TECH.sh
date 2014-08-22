#!/system/bin/sh

#
# Kernel customizations post initialization
# Created by Christopher83
# Adapted for K_TECH's Kernel
# | Credit and Thanks :
# | @arco68,@Christopher83,@Hurtsky,@Darky's,@DorianX,@Dknzo,@zeppelinrox,@Exit_Only,@slaid480,@Ryuinferno
# | at XDA-Developers

export PATH=/sbin:/system/sbin:/system/bin:/system/xbin
exec 0>&1
export PATH=/system/etc/CrossBreeder:$PATH:/sbin:/vendor/bin:/system/sbin:/system/bin:/system/xbin:
export LD_LIBRARY_PATH=/system/etc/CrossBreeder:$LD_LIBRARY_PATH

# Start logging
K_TECH=/data/K_TECH.log
busybox rm -f $K_TECH
busybox touch $K_TECH

echo "*********************************************" | tee -a $K_TECH;
echo "| Kernel customizations post initialization |" | tee -a $K_TECH;
echo "*********************************************" | tee -a $K_TECH;
echo

# Print kernel version
cat /proc/version  | tee -a $K_TECH;
echo | tee -a $K_TECH;

# Mount system for read and write
echo "Mount system for read and write"
mount -o rw,remount /system
echo

#
# Cifs support on boot
#
if [ -f "/lib/modules/cifs.ko" ]; then
	# Load cifs module
	echo "Cifs: Loading module..." | tee -a $K_TECH;
	insmod /lib/modules/cifs.ko
	echo "" | tee -a $K_TECH;
fi

#
# CrossBreeder Support on Boot = http://forum.xda-developers.com/showthread.php?t=2113150
# Adapted by Hurtsky
echo "Frandom Support on Boot" | tee -a $K_TECH;
alias BUSYBOX='/system/etc/CrossBreeder/busybox'

if [ -f /system/lib/modules/frandom.ko ]; then
  insmod /system/lib/modules/frandom.ko 2>/dev/null
  BUSYBOX insmod /system/lib/modules/frandom.ko 2>/dev/null
  insmod -f /system/lib/modules/frandom.ko 2>/dev/null
  BUSYBOX insmod -f /system/lib/modules/frandom.ko 2>/dev/null
fi

if [ -f /system/lib/modules/frandom.ko ]; then sleep 5; fi

RANDOMDEVICE=urandom
if [ -c /dev/erandom ]; then 
  chmod 444 /dev/frandom
  chmod 444 /dev/erandom
  if [ ! -f /dev/urandom.MOD ]; then 
    touch /dev/urandom.MOD
    mv /dev/urandom /dev/urandom.ORIG && ln /dev/erandom /dev/urandom
    sleep 2
  fi
  if [ ! -c /dev/urandom.ORIG ]; then 
    BUSYBOX mknod -m 666 /dev/urandom.ORIG c 1 9
    sleep 2
  fi
  ( CB_RunHaveged /dev/urandom.ORIG 0<&- &>/dev/null 2>&1 ) &
  RANDOMDEVICE=frandom
else
  if [ ! -c /dev/urandom ]; then
    BUSYBOX mknod -m 666 /dev/urandom c 1 9
    sleep 2
  fi
  ( CB_RunHaveged /dev/urandom 0<&- &>/dev/null 2>&1 ) &
fi

if [ ! -f /dev/random.MOD ]; then  
  touch /dev/random.MOD
  rm /dev/random && ln /dev/$RANDOMDEVICE /dev/random
fi
 
echo 256 > /proc/sys/kernel/random/write_wakeup_threshold
echo 64 > /proc/sys/kernel/random/read_wakeup_threshold

sys_pid=`BUSYBOX pgrep system_server 2>/dev/null`

BUSYBOX renice -10 $sys_pid 2>/dev/null
BUSYBOX renice -5 $(BUSYBOX pgrep com.android.phone 2>/dev/null) 2>/dev/null

for i in $(BUSYBOX pgrep haveged 2>/dev/null); do 
# echo -8 > /proc/$i/oom_adj 2>/dev/null
  BUSYBOX renice +20 $i 2>/dev/null
  echo "" | tee -a $K_TECH;
done

#
# LowMemoryKiller tweaks
#
if [ -d /sys/module/lowmemorykiller/parameters ]; then
	echo "Setting LowMemoryKiller tweaks..." | tee -a $K_TECH;
	echo "0,20,50,100,250,500" > /sys/module/lowmemorykiller/parameters/adj
	echo "2048,4096,6656,9216,14336,19456" > /sys/module/lowmemorykiller/parameters/minfree
	echo "" | tee -a $K_TECH;
fi

#
# VM tweaks
#
if [ -d /proc/sys/vm ]; then
	echo "Setting VM tweaks..." | tee -a $K_TECH;
	echo "50" > /proc/sys/vm/dirty_ratio
	echo "10" > /proc/sys/vm/dirty_background_ratio
	echo "90" > /proc/sys/vm/vfs_cache_pressure
	echo "500" > /proc/sys/vm/dirty_expire_centisecs

	if [ -f /proc/sys/vm/dynamic_dirty_writeback ]; then
		echo "3000" > /proc/sys/vm/dirty_writeback_active_centisecs
		echo "1000" > /proc/sys/vm/dirty_writeback_suspend_centisecs
	else
		echo "1000" > /proc/sys/vm/dirty_writeback_centisecs
	fi

	echo "" | tee -a $K_TECH;
fi

#
# Zipalign script by Slaid480(Thanks to Darky) 
# Zipalign /system/app

echo "Zipalign /system/app/*.apk =>>" | tee -a $K_TECH;
RUN_EVERY=86400

ZIPALIGNDB=/data/zipalign.db

if [ ! -f $ZIPALIGNDB ]; then
  touch $ZIPALIGNDB;
fi;


echo "Starting FV Automatic ZipAlign $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $K_TECH

for DIR in /system/app /data/app ; do
  cd $DIR
  for APK in *.apk ; do
    if [ $APK -ot $ZIPALIGNDB ] && [ $(grep "$DIR/$APK" $ZIPALIGNDB|wc -l) -gt 0 ] ; then
      echo "Already checked: $DIR/$APK" | tee -a $K_TECH
    else
      zipalign -c 4 $APK
      if [ $? -eq 0 ] ; then
        echo "Already aligned: $DIR/$APK" | tee -a $K_TECH
        grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB
      else
        echo "Now aligning: $DIR/$APK" | tee -a $K_TECH
        zipalign -f 4 $APK /cache/$APK
        busybox mount -o rw,remount /system
        cp -f -p /cache/$APK $APK
        busybox rm -f /cache/$APK
        grep "$DIR/$APK" $ZIPALIGNDB > /dev/null || echo $DIR/$APK >> $ZIPALIGNDB
      fi
    fi
  done
done

busybox mount -o ro,remount /system
touch $ZIPALIGNDB

# Automatic ZipAlign by slaid480
# ZipAlign files in /data that have not been previously
# Thanks to mcbyte_it
# Zipalign /data/app

echo "Zipalign /data/app/*.apk =>>" | tee -a $K_TECH;
RUN_EVERY=86400

echo "Starting Automatic ZipAlign $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $K_TECH;
    for apk in /data/app/*.apk ; do
  zipalign -c 4 $apk;
  ZIPCHECK=$?;
  if [ $ZIPCHECK -eq 1 ]; then
    echo ZipAligning $(basename $apk)  | tee -a $K_TECH;
    zipalign -f 4 $apk /cache/$(basename $apk);
      if [ -e /cache/$(basename $apk) ]; then
        cp -f -p /cache/$(basename $apk) $apk  | tee -a $K_TECH;
        rm /cache/$(basename $apk);
      else
        echo ZipAligning $(basename $apk) Failed  | tee -a $K_TECH;
      fi;
  else
    echo ZipAlign already completed on $apk  | tee -a $K_TECH;
  fi;
       done;

echo "Automatic ZipAlign finished at $( date +"%m-%d-%Y %H:%M:%S" )" | tee -a $K_TECH;
echo "" | tee -a $K_TECH;

#
# script by Pikachu01 and improved by Slaid480!
# Optimize SQlite databases of apps

echo "# Fly-On Mod LOGGING ENGINE" | tee -a $K_TECH
echo "$( date +"%m-%d-%Y %H:%M:%S" ) iptimizing and defragging your database files,please wait..." | tee -a $K_TECH;

#Interval between Optimize SQlite runs, in seconds, 86400=24 hours
RUN_EVERY=86400


echo "";
echo "*********************************************";
echo "Optimizing and defragging your database files (*.db)";
echo "Ignore the 'database disk image is malformed' error";
echo "Ignore the 'no such collation sequence' error";
echo "*********************************************";
echo "";

for i in \
`busybox find /data -iname "*.db"`;
do \
  /system/xbin/sqlite3 $i 'VACUUM;';
  /system/xbin/sqlite3 $i 'REINDEX;';
done;

if [ -d "/dbdata" ]; then
  for i in \
  `busybox find /dbdata -iname "*.db"`;
  do \
    /system/xbin/sqlite3 $i 'VACUUM;';
    /system/xbin/sqlite3 $i 'REINDEX;';
  done;
fi;


if [ -d "/datadata" ]; then
  for i in \
  `busybox find /datadata -iname "*.db"`;
  do \
    /system/xbin/sqlite3 $i 'VACUUM;';
    /system/xbin/sqlite3 $i 'REINDEX;';
  done;
fi;


for i in \
`busybox find /sdcard -iname "*.db"`;
do \
  /system/xbin/sqlite3 $i 'VACUUM;';
  /system/xbin/sqlite3 $i 'REINDEX;';
done;

echo "$( date +"%m-%d-%Y %H:%M:%S" ) database files optimization done!" | tee -a $K_TECH;
echo "" | tee -a $K_TECH;

#
# Block tweaks
#
echo "Setting block tweaks..." | tee -a $K_TECH;
for queue in /sys/block/*/queue
do
	echo 0 > $queue/rotational
	echo "" | tee -a $K_TECH;
done

# Mount system read-only
echo "Mount system read-only"
mount -o ro,remount /system
