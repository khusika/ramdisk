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
