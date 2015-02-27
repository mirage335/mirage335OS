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

#####

./mountChRoot.sh

executeChRoot "emerge --sync"
executeChRoot "emerge -vuDN --newuse --with-bdeps y --keep-going world"
autoEtcUpdate
executeChRoot "emerge -vuDN --newuse --with-bdeps y --keep-going world"

executeChRoot "revdep-rebuild"
#executeChRoot "perl-cleaner --reallyall" #Not usually necessary post-install, causes problems.
executeChRoot "emerge @preserved-rebuild"
executeChRoot "emerge -vuDN --newuse --with-bdeps y --keep-going world"
executeChRoot "emerge @preserved-rebuild"

./umountChRoot.sh
