#!/bin/bash
. ubiquitous_bash.sh

mustBeRoot

#Execute instructions in ChRoot environment.
executeChRoot() {
        env -i HOME="/root" SHELL="/bin/bash" TERM="xterm" PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" $(which chroot) ./ChRoot /bin/bash -c "$@"
}

#Automatically merge proposed etc filesystem changes.
autoEtcUpdate() {
        executeChRoot "echo -e y\\ny\\ny\\ny\\ny\\ny\\ny\\ny\\ny | etc-update --automode -3"
}

#####-Pack Up OS-#####

./umountChRoot.sh

executeChRoot "tar -cpf mirage335OS-buildAssets.tar -C / ./usr/portage/distfiles ./usr/portage/packages"

executeChRoot "tar --exclude usr/portage/packages --exclude usr/portage/distfiles --exclude mirage335OS-buildAssets.tar -cpf mirage335OS-lite.tar -C / ."
