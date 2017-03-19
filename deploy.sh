#!/system/bin/sh
#Cara kerjanya:
#membuat file IMG
#membuat file IMG menjadi file system (ext2,ext3,ext4)
#mount file IMG ke folder (/data/local/mnt)
#extract file rootfs.tar.gz (tar.xz) ke tempat file IMG di mount (/data/local/mnt)
#selesai extract langsung chroot (/data/local/mnt)/bin/bash

### Linux rootfs manager ###
### BETA VERSION ###
### By Alkemis ####
### lin0x4ndroid.blogspot.com ###

### SETUP ALL ENVIRONTMENT ###
bs=1048576 # Byte size = 1MB.
img=linux.img #IMG file
rootfs=kalifs-minimal.tar.xz #tar file of rootfs
img_size=1000 #MB
filesystem=ext2 #File system of IMG file
mount_point=/data/local/mnt #Path where rootfs will be placed
source_path=${EXTERNAL_STORAGE}/$rootfs #Source path of rootfs file
installation_path=${EXTERNAL_STORAGE}/$img #Path where rootfs will be installed
loop=/dev/block/loop255
chroot_dir=$mount_point/kali-armhf
shell="/bin/bash"

### preparing commands ###
bbox=busybox
mkfs="$bbox mkfs.ext2"

logg(){
now=$(date +"[ %H:%M:%S ]")
echo $now $*
}

die(){
    logg $*
    exit 1
}

status(){
args=${*}
exit_status=0
$args
st=$?
if [  $st != $exit_status ]; then
logg "[ FAIL ]"
die "[ ! ] perintah yg dijalankan ($args) error dgn status exit: $st\n[ + ] status exit yg diharapkan: $exit_status"
fi
logg "[ OK ]"
}


### Periksa busybox ###
logg "Memeriksa busybox"
status "busybox"

# Periksa akses root #
logg "Memeriksa akses root.."
perms=$(id|cut -b 5)
if [ $perms != 0 ]; then
die "[ ! ] ketik:\nsu [enter]\nsh $0 [enter]"
fi

un_mount(){
logg "Memeriksa apakah $installation_path sdh dimount ke $mount_point"
$bbox losetup $loop|grep -i $installation_path
if [ $? = 0 ]; then
logg "Menghilangkan $mount_point"
$bbox umount $mount_point
$bbox losetup -d $loop
fi
}

on_create_img(){
un_mount
logg "Membuat file IMG baru di $installation_path"
logg "Ukuran file IMG: $img_size MB"
status "dd if=/dev/zero of=$installation_path bs=$bs count=$img_size"
logg "[OK]"
}

on_mkfs(){
logg "Memeriksa ketersediaan loopback..."
# Periksa loop device #
if [ -b $loop ]; then
    logg "[ FOUND ]"
else
    logg "[ MISSING ]"
    logg "Membuat loop device $loop"
    status $bbox mknod $loop b 7 255
    if [ -b $loop ]; then
        logg "[ OK ]"
    else
        die "Gagal membuat loop device $loop"
    fi
fi
logg "Membuat file system..."
status $mkfs -m 1 -v $loop
if [ ! -r $mount_point ]; then
    mkdir $mount_point
fi
}

on_mount(){
logg "Mounting $loop ke $mount_point dgn file system $filesystem"
status $bbox mount -t $filesystem $loop $mount_point
}

on_extract(){
logg "Mengextract $source_path ke $mount_point"
echo -n "** Tekan [enter] untuk melanjutkan **"
read tanya
rm -rf $mount_point
status $bbox tar -xvf $source_path -C $mount_point
}

on_chroot(){
######### EXPORT ENVIRONMENT #########
export bin=/system/bin
export mnt=$mount_point
PRESERVED_PATH=$PATH
export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH
export TERM=linux
export HOME=/root
export USER=root
export LOGNAME=root
unset LD_PRELOAD

logg "Chrooting..."
boot(){
$*
if [ $? != 0 ]; then
logg "Error waktu chrooting ke $mount_point/$shell"
logg "Pastikan folder $shell ada di $mount_point"
die
fi
logg "Shutting DOWN Linux ARMHF"
$bbox umount $mount_point
$bbox losetup -d $loop
}

boot $bbox chroot $chroot_dir $shell -i
}

### Let's Go ! ###
un_mount
logg "rootfs: "$source_path
logg "file IMG: "$installation_path

logg "Let's Go ! "

on_install(){
logg "Proses pemasangan $rootfs ke $installation_path dimulai"
un_mount
# periksa file img #
if [ -f $installation_path ]; then
echo -n "File IMG ditemukan ! \nApakah anda ingin membuat ulang filenya? [y/n] "
read tanya
    if [ 0$tanya = 0y ]; then
        on_create_img
    fi
else
logg "File IMG tdk ditemukan !"
on_create_img
fi

# pasang ke mount_point #
logg "Memasang $installation_path ke $loop"
status $bbox losetup $loop $installation_path
# buat jd file system #
echo -n "Apakah anda ingin membuatnya menjadi file system ($filesystem) ? [y/n] "
read tanya
if [ 0$tanya = 0y ]; then
    on_mkfs
fi

# mount ke mount point #
on_mount
# extract #
waktu=$(date)
on_extract
logg "Waktu mengextract: $waktu"
logg "Selesai pada: $(date)"
# chroot #
logg "Hampir selesai !"
on_chroot
}

on_start(){
logg "Proses memulai $installation_path dimulai"
un_mount
logg "Memasang $installation_path ke $loop"
status $bbox losetup $loop $installation_path
on_mount
on_chroot
}

echo "Silakan pilih salah satu opsi:"
echo "\t[p]asang $rootfs ke $img"
echo "\t[m]ulai $img"
echo -n "Pilihan anda: "
read tanya
if [ 0$tanya = "0p" ]; then
on_install
elif [ 0$tanya = "0m" ]; then
on_start
fi
