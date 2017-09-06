#!/system/bin/sh

# Linux chroot manager (cli)
# rebuild version with a new fresh syntax :D
# @author : RedFoX
# visit lin0x4ndroid.blogspot.com to get more useful post about Linux & Android

#  CHANGE THE AUTHOR NAME WON'T MADE YOU
# AS THE AUTHOR, SO RESPECT THEM
# IF YOU WANT TO BE RESPECTED TOO :)

# ada 3 opsi:
# Install chroot
# Mulai chroot
# Hentikan chroot

system=$ANDROID_ROOT
data=$ANDROID_DATA
sdcard=$EXTERNAL_STORAGE
bbox="busybox" # nama file busybox
loop_number=255
loop=/dev/block/loop$loop_number
filesystem="ext4" # file system linux dari rootfs nya
IMG=$sdcard/linux.img # file img yg berisi rootfs
rootfs_file=$sdcard/rootfs.tar.xz # file kompresi rootfs
mount_point="/data/local/mnt"
chroot_dir=$mount_point/kali-armhf # chroot dir yg berisi shell linuxnya berada
shell="/bin/bash" # shell linuxnya


die(){
    echo $*
    exit 1
}

status(){
    # check status of a command given
    success=0
    $*
    exstat=$?
    if [ $exstat != $success ]; then
    die "Invalid exit status $exstat of command \"$*\""
    fi
}

# check busybox
busy=$(ls $system/xbin/*$bbox*)
if [ $? != 0 ]; then
    busy=$(ls $system/xbin/*$bbox*)
    if [ $? != 0 ]; then
        die "Busybox tidak ditemukan, silakan pasang terlebih dahulu"
    fi
fi
echo $busy" [ OK ]"
# terkadang applet busybox (seperti which, cut, dll) tdk dapat dipasang di system dikarenakan folder
# system yg tdk dapat ditulis
# jadi untuk kompabilitas beberapa perintah saya awali dgn busybox

# check root
echo  -n "Memeriksa akses root "
user=$(id|$bbox cut -b 5)
if [ $user != 0 ]; then
    die "\nSilakan beri akses root dulu"
fi
echo "[ OK ]"

# function do actions #
mounting(){
    echo "Mounting $2 ke $3 dgn file system $1"
    $bbox mount -t $1 $2 $3
}

do_mount(){
mounting $filesystem $loop $mount_point
if [ $? = 255 ]; then
    echo "Ada masalah waktu mounting $loop ke $mount_point"
elif [ $? != 0 ]; then
    echo "Gagal mount $loop ke $mount_point"
    echo "Harap periksa apakah ada program/aplikasi yg mengakses folder $mount_point"
    die "Tutup aplikasi/program yg mengakses $mount_point dan coba lg nanti"
fi
}

do_unmount(){
echo "Memeriksa apakah $IMG sdh dimount ke $mount_point"
$bbox losetup $loop|grep -i $IMG
if [ $? = 0 ]; then
    echo "Menghilangkan $mount_point"
    $bbox umount $mount_point
    $bbox losetup -d $loop
    if [ $? != 0 ]; then
        echo "Losetup untuk menghapus $IMG dari $loop gagal [ FAIL ]"
    else
        echo "Losetup untuk menghapus $IMG dari $loop berhasil [ OK ]"
   fi
fi
}

do_chroot(){
######### EXPORT ENVIRONMENT #########
export bin=/system/bin
export mnt=$mount_point
PRESERVED_PATH=$PATH
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH
export TERM=linux
export HOME=/root
#export USER=root
#export LOGNAME=root
unset LD_PRELOAD

echo "Mengatur system..."
mounting devpts devpts $chroot_dir/dev/pts
mounting proc proc $chroot_dir/proc
mounting sysfs sysfs $chroot_dir/sys
#$bbox ln -s /system $chroot_dir/android_system

###########################################
# Sets up network forwarding              #
###########################################
$bbox sysctl -w net.ipv4.ip_forward=1
if [ $? -ne 0 ];then die "Unable to forward network!"; fi

# If NOT $chroot_dir/root/DONOTDELETE.txt exists we setup hosts and resolv.conf now
if [ ! -f $chroot_dir/root/DONOTDELETE.txt ]; then
	echo "nameserver 8.8.8.8" > $chroot_dir/etc/resolv.conf
	if [ $? -ne 0 ];then die "Unable to write resolv.conf file!"; fi
	echo "nameserver 8.8.4.4" >> $chroot_dir/etc/resolv.conf
	echo "127.0.0.1 localhost" > $chroot_dir/etc/hosts
	if [ $? -ne 0 ];then die "Unable to write hosts file!"; fi
fi
echo "" > $chroot_dir/root/DONOTDELETE.txt
prepare_system(){
    data=($(mount|grep ${data}))
    block=${data[0]}
    path=${data[1]}
    fs=${data[2]}
    mode=$(echo ${data[3]}|$bbox cut -b 1-2)
    if [ ! -r $chroot_dir/data ]; then
        mkdir $chroot_dir/data
    fi
    mounting $fs $data $chroot_dir/data
    $bbox mount -o remount,$mode $chroot_dir/data
    
    system=($(mount|grep $system))
    block=${system[0]}
    path=${system[1]}
    fs=${system[2]}
    mode=$(echo ${system[3]}|$bbox cut -b 1-2)
    if [ ! -r $chroot_dir/system ]; then
        mkdir $chroot_dir/system
    fi
    mounting $fs $system $chroot_dir/system
    $bbox mount -o remount,$mode $chroot_dir/system
    
    sdcard=($(mount|grep ${sdcard}))
    block=${sdcard[0]}
    path=${sdcard[1]}
    fs=${sdcard[2]}
    mode=$(echo ${sdcard[3]}|$bbox cut -b 1-2)
    if [ ! -r $chroot_dir/sdcard ]; then
        mkdir $chroot_dir/sdcard
    fi
    mounting $fs $sdcard $chroot_dir/sdcard
    $bbox mount -o remount,$mode $chroot_dir/sdcard
}
prepare_system
echo "Chrooting..."
$bbox chroot $chroot_dir $shell -i
echo "Shutting DOWN Linux $($bbox uname -m)"
}

# INSTALL
install_linux(){
    echo "Coming soon ;)"
}

# START
start_linux(){
echo -n "Memeriksa ketersediaan loopback..."
# Periksa loop device #
if [ -b $loop ]; then
    echo " [ FOUND ]"
else
    echo " [ MISSING ]"
    echo -n "Membuat loop device $loop"
    status $bbox mknod $loop b 7 $loop_number
    if [ -b $loop ]; then
        echo " [ OK ]"
    else
        die "\nGagal membuat loop device $loop"
    fi
fi
# pasang ke $loop #
echo "Memasang $IMG ke $loop"
$bbox losetup $loop $IMG
do_mount
do_chroot
do_unmount
}

# STOP
stop_linux(){
    echo "Coming soon ;)"
}
#
$bbox printf "Apa yang ingin anda lakukan?\n\t[m]ulai linux\n\t[i]nstall linux\n\t[s]top linux\nSilakan pilih: "
if [ $? != 0 ]; then
    die "Something when wrong.."
fi
read tanya
if [ 0$tanya = "0m" ]; then
    start_linux
    exit 0
elif [ 0$tanya = "0i" ]; then
    install_linux
    exit 0
elif [ 0$tanya = "0s" ]; then
    stop_linux
    exit 0
else
    die "Oke bye.."
fi
