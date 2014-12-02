#!/usr/bin/linux32 bash
#x32
#Assuming major version changes have not broken the script, some editing will still be required. Look for x32 and x64 comments.

echo $$

. ubiquitous_bash.sh

mustBeRoot

#Execute instructions in ChRoot environment.
executeChRoot() {
	env -i HOME="/root" SHELL="/bin/bash" TERM="xterm" PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" $(which chroot) ./ChRoot /bin/bash -c "$@"
}

#Automatically merge proposed etc filesystem changes.
autoEtcUpdate() {
	executeChRoot "yes | etc-update --automode -3"
}

#####-Initial Filesystem-#####

mkdir -p ChRoot

cd ChRoot
wget http://ftp.osuosl.org/pub/funtoo/funtoo-stable/x86-32bit/i686/stage3-latest.tar.xz #x32
#wget http://ftp.osuosl.org/pub/funtoo/funtoo-stable/x86-64bit/generic_64/stage3-latest.tar.xz #x64
tar -xpf stage3-latest.tar.xz
rm -f stage3-latest.tar.xz

cd usr
wget http://ftp.osuosl.org/pub/funtoo/funtoo-current/snapshots/portage-latest.tar.xz

tar xf ./portage-latest.tar.xz
rm -f ./portage-latest.tar.xz
cd ../..

#####-Initial Configuration-#####

executeChRoot "cd /usr/portage ; git checkout funtoo.org"

executeChRoot "rm /etc/localtime"
executeChRoot "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"

cp ./Config/make.conf ./ChRoot/etc/portage/make.conf
cp -a ./Config/distfiles ./ChRoot/usr/portage/
cp -a ./Config/packages ./ChRoot/usr/portage/

cp /etc/resolv.conf ./ChRoot/etc/resolv.conf

./mountChRoot.sh

executeChRoot "source /etc/profile ; env-update"

executeChRoot "emerge --sync"

#####-Optional DistCC-#####
#Note GCC must be the same version across participating machines.

#executeChRoot "emerge distcc"
#echo FEATURES='"${FEATURES} distcc"' | tee -a ./ChRoot/etc/make.conf

#executeChRoot "/usr/bin/distcc-config --set-hosts 192.168.50.195/48"

#####-Layman-#####
executeChRoot "emerge --usepkg layman"
executeChRoot "echo 'source /var/lib/layman/make.conf' | tee -a /etc/portage/make.conf"

#####-PROFILES-#####
#PROFILES
#Note stable branch has been chosen. It is assumed this is now functional enough, or if not, only a few packages (eg. xf86-video-intel) will be required from testing.

executeChRoot "eselect profile set-build funtoo/1.0/linux-gnu/build/stable"
executeChRoot "eselect profile set-flavor funtoo/1.0/linux-gnu/flavor/core"

executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/audio"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/console-extras"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/kde"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/media"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/print"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/X"
executeChRoot "eselect profile add funtoo/1.0/linux-gnu/mix-ins/xfce"

#####-Custom Softload Configuration-#####

executeChRoot "cd ; git clone https://github.com/mirage335/mirage335-Overlays.git"
executeChRoot "cd ~/mirage335-Overlays ; ./install.sh"

#Dangerous command.
#executeChRoot "rm -rf ~/mirage335-Overlays"

executeChRoot "layman -L"
executeChRoot "layman -a BaseEbuilds-mirage335"

executeChRoot "cd ; git clone https://github.com/mirage335/mirage335-sets.git"
executeChRoot "cd ~/mirage335-sets ; ./install.sh"

executeChRoot "emerge --usepkg --quiet-build y prelink"

#####-Custom Softload Installation-#####

#WARNING. This could become an infinite loop.
while ! executeChRoot "emerge --usepkg --quiet-build y --backtrack 500 -uDN world xorg-x11 kdebase-meta kdm lxde-meta xdm metalog vixie-cron dhcpcd boot-update @m335-all"
do
	autoEtcUpdate
	
	executeChRoot "perl-cleaner --reallyall"
	
	executeChRoot "emerge --sync"
	
	sleep 90
done

executeChRoot "emerge python:2.7 python:3.3"
executeChRoot "emerge python-updater"

executeChRoot "emerge @preserved-rebuild"

executeChRoot "source /etc/profile ; env-update ; revdep-rebuild"

executeChRoot "emerge -uDN world"

executeChRoot "emerge --depclean"

executeChRoot "env-update"

#####-Kernel-#####
executeChRoot "emerge --usepkg lzop gentoo-sources"

#executeChRoot "cd /usr/src/linux ; wget http://kernel.ubuntu.com/~kernel-ppa/configs/quantal/amd64-config.flavour.generic -O .config" #x64
executeChRoot "cd /usr/src/linux ; wget http://kernel.ubuntu.com/~kernel-ppa/configs/quantal/i386-config.flavour.generic -O .config" #x32

#executeChRoot "cd /usr/src/linux ; make clean ; make olddefconfig ; make -j 6 ; make modules_install ; cp ./arch/x86_64/boot/bzImage /boot/ProductionKernel" #x64
executeChRoot "cd /usr/src/linux ; make clean ; make olddefconfig ; make -j 6 ; make modules_install ; cp ./arch/x86/boot/bzImage /boot/ProductionKernel" #x86

#####-Attempt Exceptional Softload Installation-#####
executeChRoot "emerge  --usepkg chromium"
autoEtcUpdate
executeChRoot "emerge  --usepkg chromium"
autoEtcUpdate

if executeChRoot "emerge  --usepkg chromium"
then
	sleep 1
else
	executeChRoot "emerge  --usepkg google-chrome"
	autoEtcUpdate
	executeChRoot "emerge  --usepkg google-chrome"
fi

autoEtcUpdate

executeChRoot "env MAKEOPTS=\"\" emerge app-emulation/virtualbox[additions,alsa,pulseaudio,sdk] \>=app-emulation/IQEmu-9999"
autoEtcUpdate
executeChRoot "env MAKEOPTS=\"\" emerge app-emulation/virtualbox[additions,alsa,pulseaudio,sdk] \>=app-emulation/IQEmu-9999"

#####-Configuration-#####
executeChRoot "echo FEATURES=\"${FEATURES} getbinpkg\" >> /etc/make.conf"

executeChRoot "sed -i 's/DISPLAYMANAGER=\"xdm\"/DISPLAYMANAGER=\"kdm\"/'  /etc/conf.d/xdm "

executeChRoot "echo rc_parallel=\"YES\" >> /etc/rc.conf"

executeChRoot "echo clock_systohc=\"YES\" >> /etc/conf.d/hwclock"

#####-Init Scripts-#####
executeChRoot "rc-update del dhcpcd default"
executeChRoot "rc-update add wicd default"

executeChRoot "rc-update add consolekit default"
executeChRoot "rc-update add dbus default"
executeChRoot "rc-update add xdm default"
executeChRoot "rc-update add cupsd default"

executeChRoot "rc-update add vixie-cron default"
executeChRoot "rc-update add metalog default"

#####-Pack Up OS-#####

./umountChRoot.sh

executeChRoot "tar -cpf mirage335OS-buildAssets.tar -C / ./usr/portage/distfiles ./usr/portage/packages"

executeChRoot "tar --exclude usr/portage/packages --exclude usr/portage/distfiles --exclude mirage335OS-buildAssets.tar -cpf mirage335OS-lite.tar -C / ."

exit

# Perform the follwing, post installation to a real machine.

#-Filesystem-#
#sudo mke2fs -m 0 -I 256 -G 64 -E lazy_itable_init=0 -O has_journal,ext_attr,resize_inode,dir_index,extent,flex_bg,sparse_super,large_file,huge_file,uninit_bg,dir_nlink,extra_isize /dev/sda1
#Split up options list for readability.
#tune2fs /dev/sda1 -o journal_data_writeback

#-Configuration Files-#
#/etc/conf.d/hostname
#/etc/fstab

#-UserSetup-#
#Perform commands inside chroot.

#passwd

#useradd -m user
#usermod -a -G tty,kmem,wheel,uucp,cron,audio,video,usb,users,portage user
#passwd user

#-Bootloader-#
#Perform commands inside chroot.

#grub-install /dev/sda
#boot-update

#-Post Install-
#Perform these operations after booting the installation.

#Add PDF printer at localhost:631 . Symlink /var/spool/cups-pdf/${USER} to ~/Downloads/PDF .

#Configure KDE .

#Install any remaining exceptional software.

#rsyncBackup.sh