#!/bin/bash

if [ $2=="all" ];then
	SKIP_KERNEL=${SKIP_KERNEL:-0}
	SKIP_KODI=${SKIP_KODI:-0}
	SKIP_KODI_ADDONS=${SKIP_KODI_ADDONS:-0}
	SKIP_LOADING_VIDEO=${SKIP_LOADING_VIDEO:-0}
	SKIP_STARTUP=${SKIP_STARTUP:-0}
	SKIP_SOURCES=${SKIP_SOURCES:-1}
	SKIP_UNPACK=${SKIP_UNPACK:-0}
	SKIP_NAVIT=${SKIP_NAVIT:-0}
else
	SKIP_KERNEL=${SKIP_KERNEL:-1}
	SKIP_KODI=${SKIP_KODI:-1}
	SKIP_KODI_ADDONS=${SKIP_KODI_ADDONS:-1}
	SKIP_LOADING_VIDEO=${SKIP_LOADING_VIDEO:-1}
	SKIP_STARTUP=${SKIP_STARTUP:-1}
	SKIP_SOURCES=${SKIP_SOURCES:-1}
	SKIP_UNPACK=${SKIP_UNPACK:-1}
	SKIP_NAVIT=${SKIP_NAVIT:-1}
fi

PASS="a"
UPDATE_DIR="rpi-carpc-update"

IP=""
FROM=""
FROM_SU=""
TO=""
CARPC="/opt/carpc/"

if [ $1 == "create" ];then
	IP="192.168.0.107"
	FROM="sshpass -p $PASS scp -r pi@$IP:"
	FROM_SU=$FROM
	TO="$UPDATE_DIR"
	mkdir -p $TO/${CARPC}
elif [ $1 == "update" ];then
	FROM="cp -r ${PWD}/$UPDATE_DIR/"
	FROM_SU="sudo cp -r ${PWD}/$UPDATE_DIR/"
	TO="/"
else
	echo "The first argument is unknown"
	exit 1
fi

echo $SKIP_KODI
echo $SKIP_KODI_ADDONS
echo $SKIP_LOADING_VIDEO
echo $SKIP_STARTUP
echo $SKIP_SOURCES
echo $SKIP_UNPACK
echo $SKIP_NAVIT
echo $FROM_SU
echo $FROM
echo $TO
#echo $1


#############################################################
# Unpack archive
#############################################################
if [ $1 == 'update' ];then
	sudo killall -9 kodi.bin
	sudo killall -9 carpc-controller
	sudo killall -9 navit
	sudo mkdir ${CARPC}
	sudo chmod -R a+rwx ${CARPC}
	if [ $SKIP_UNPACK -eq 0 ];then
		echo -e "\e[1;32mUnpacking archive\e[0m"
		tar -zxf ${PWD}/$UPDATE_DIR.tar.gz
		rm -rf ${PWD}/$UPDATE_DIR.tar.gz
	fi
fi


#############################################################
# System
#############################################################
# Kernel
if [ $SKIP_KERNEL -eq 0 ];then
	echo -e "\e[1;32mKernel\e[0m"
	if [ $1 == 'update' ];then
		sudo rm -rf /boot/kernel7.img
		sudo rm -rf /lib/firmware/
		sudo rm -rf /lib/modules/
	fi
	mkdir -p $TO/boot/
	mkdir -p $TO/lib/
	$FROM_SU/lib/modules/ $TO/lib/
	$FROM_SU/lib/firmware/ $TO/lib/
	$FROM_SU/boot/kernel7.img $TO/boot/
fi

# Autostart KODI
if [ $1 == 'create' ];then
	mkdir -p $TO/etc/modprobe.d/
fi
$FROM_SU/etc/inittab $TO/etc/
$FROM_SU/etc/profile $TO/etc/
$FROM_SU/etc/modprobe.d/raspi-blacklist.conf $TO/etc/modprobe.d/

#############################################################
# KODI
#############################################################
if [ $SKIP_KODI -eq 0 ];then
	echo -e "\e[1;32mKODI core\e[0m"
	# Create local directories
	mkdir -p $TO/usr/local/include/
	mkdir -p $TO/usr/local/lib/
	mkdir -p $TO/usr/local/share/

	# Copy Kodi new files
	$FROM_SU/usr/local/include/libcec/ $TO/usr/local/include/
	$FROM_SU/usr/local/include/shairport/ $TO/usr/local/include/
	$FROM_SU/usr/local/include/taglib/ $TO/usr/local/include/
	$FROM_SU/usr/local/include/kodi $TO/usr/local/include/
	$FROM_SU/usr/local/lib/kodi/ $TO/usr/local/lib/
	$FROM_SU/usr/local/lib/libcec* $TO/usr/local/lib/
	$FROM_SU/usr/local/lib/libshair* $TO/usr/local/lib/
	$FROM_SU/usr/local/lib/libtag* $TO/usr/local/lib/
	$FROM_SU/usr/local/share/kodi/ $TO/usr/local/share/

	if [ $1 == 'update' ];then
		sudo rm /usr/local/lib/libshairport.so.0
		sudo ln -s /usr/local/lib/libshairport.so /usr/local/lib/libshairport.so.0
		sudo rm /usr/local/lib/libcec.so.2
		sudo ln -s /usr/local/lib/libcec.so /usr/local/lib/libcec.so.2
	fi
fi

# KODI Addons
if [ $SKIP_KODI_ADDONS -eq 0 ];then
	echo -e "\e[1;32mKODI Addons\e[0m"
	mkdir -p $TO/home/pi/.kodi/
	$FROM/home/pi/.kodi/addons $TO/home/pi/.kodi/
	#mkdir -p $TO/home/pi/.kodi/userdata
	#$FROM/home/pi/.kodi/userdata/advancedsettings.xml $TO/home/pi/.kodi/userdata
	#$FROM/home/pi/.kodi/userdata/guisettings.xml $TO/home/pi/.kodi/userdata
fi

#############################################################
# Navit
#############################################################
if [ $SKIP_NAVIT -eq 0 ];then
	echo -e "\e[1;32mNavit\e[0m"
	mkdir -p $TO/home/pi/.navit/xml/skins
	$FROM/${CARPC}/navit $TO/${CARPC}/
	$FROM/home/pi/.navit/ $TO/home/pi/
fi

#############################################################
# Binaries: carpc-controller, set_date
#############################################################
echo -e "\e[1;32mBinaries\e[0m"
mkdir -p $TO/usr/bin/
$FROM_SU/usr/bin/carpc-controller $TO/usr/bin/
$FROM_SU/usr/bin/carpc-setdate $TO/usr/bin/


#############################################################
# Configuration
#############################################################
echo -e "\e[1;32mConfig\e[0m"
mkdir -p $TO/${CARPC}
$FROM/${CARPC}/config $TO/${CARPC}/


#############################################################
# Tools
#############################################################
echo -e "\e[1;32mTools\e[0m"
mkdir -p $TO/${CARPC}
$FROM/${CARPC}/tools $TO/${CARPC}/


#############################################################
# Startup
#############################################################
if [ $SKIP_STARTUP -eq 0 ];then
	echo -e "\e[1;32mStarup\e[0m"
	mkdir -p $TO/etc/xdg/lxsession/LXDE-pi/
	$FROM_SU/etc/xdg/lxsession/LXDE-pi/autostart $TO/etc/xdg/lxsession/LXDE-pi/

	mkdir -p $TO/etc/init.d/
	$FROM_SU/etc/init.d/splashscreen $TO/etc/init.d/

	# /home/pi/startup/
	if [ $SKIP_LOADING_VIDEO -eq 0 ];then
		echo -e "\e[1;32mStartup Video\e[0m"
		mkdir -p $TO/${CARPC}/startup/
		$FROM/${CARPC}/startup/loading_video.mp4 $TO/${CARPC}/startup/loading_video.mp4
	fi
	mkdir -p $TO/${CARPC}/startup/
	$FROM/${CARPC}/startup/StartCarPC $TO/${CARPC}/startup/StartCarPC
	$FROM/${CARPC}/startup/StartCarPC_stage2 $TO/${CARPC}/startup/StartCarPC_stage2
fi


#############################################################
# Sources
#############################################################
if [ $SKIP_SOURCES -eq 0 ];then
	echo -e "\e[1;32mSources\e[0m"
	mkdir -p $TO/${CARPC}/
	$FROM/${CARPC}/src/ $TO/${CARPC}
fi


if [ $1 == 'create' ];then
	echo "$(date +'%d-%m-%Y')" > $UPDATE_DIR/version
else
	cp -f $UPDATE_DIR/version /${CARPC}/.carpc.version
fi

#############################################################
# Create archive
#############################################################
if [ $1 == 'create' ];then
	echo -e "\e[1;32mCreating archive\e[0m"
	tar -zcf $UPDATE_DIR.tar.gz $UPDATE_DIR
fi

sync
echo -e "\e[1;32mDone\e[0m"
