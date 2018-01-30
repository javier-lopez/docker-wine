############################################################
# Copyright (c) 2015 Jonathan Yantis
# Released under the MIT license
############################################################
#
# ├─yantis/archlinux-tiny
#   ├─yantis/archlinux-small
#     ├─yantis/archlinux-small-ssh-hpn
#       ├─yantis/ssh-hpn-x
#         ├─yantis/dynamic-video
#           ├─yantis/virtualgl
#             ├─yantis/wine

FROM yantis/virtualgl
MAINTAINER Jonathan Yantis <yantis@yantis.net>

#RUN cat /etc/pacman.conf  && exit 1
#RUN cat /etc/pacman.d/mirrorlist  && exit 1

# Update and force a refresh of all package lists even if they appear up to date.
RUN  sed -i -e '/^\[blackarch\]$/,+1d' /etc/pacman.conf && \
     echo '[blackarch]' | tee -a /etc/pacman.conf       && \
     echo 'Include = /etc/pacman.d/black_arch_mirrorlist' | tee -a /etc/pacman.conf && \

    wget -q -O- --no-check-certificate \
        https://raw.githubusercontent.com/BlackArch/blackarch/master/mirror/mirror.lst | \
        awk -F'|' '{print $2}' | grep -v "^ftp"  | \
        awk 'BEGIN{srand()}{print rand()"\t"$0}' | \
        sort | cut -f2- | awk '{print "Server =", $0}' | head -20 | \
        tee /etc/pacman.d/black_arch_mirrorlist && \

    echo "====================================================================" && \

    wget -q -O- --no-check-certificate \
        http://www.archlinux.org/mirrors/status/json/ | \
        sed 's,{,\n{,g' | sed -n '/rsync/d; /pct": 1.0/p' | \
        sed 's,^.*"url": "\([^"]\+\)".*,\1,g' | awk '{print $0"$repo/os/$arch"}' | \
        grep -v "^ftp" | \
        awk 'BEGIN{srand()}{print rand()"\t"$0}' | \
        sort | cut -f2- | awk '{print "Server =", $0}' | head -20 | \
        tee /etc/pacman.d/mirrorlist && \

    #life is too short for this stuff, disable gpg verification
    #pacman-key --populate && \
    #pacman-key --lsign-key 753E0F1F && pacman-key -r 753E0F1F && \
    sed -i '0,/^SigLevel.*/s//SigLevel = Never/' /etc/pacman.conf && \

    #https://bugs.archlinux.org/task/53217
    #pacman -Syuw --noconfirm && rm /etc/ssl/certs/ca-certificates.crt && \
    #echo "====================================================================" && \

    #if it works don't touch it
    #pacman -Syyu --noconfirm && \

    #only update pacman package db
    pacman -Syy --noconfirm && \

    # Install Wine & Winetricks dependencies
    pacman --noconfirm -S \
    glibc                 \
    cabextract            \
    lib32-gnutls          \
    lib32-mpg123          \
    lib32-ncurses         \
    p7zip                 \
    unzip                 \
    wine-mono             \
    wine_gecko            \
    wine               && \

    # Install samba for ntlm_auth
    pacman --noconfirm -S samba --assume-installed python2 && \

    # Install Winetricks from github as it is more recent.
    curl -o winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    install -Dm755 winetricks /usr/bin/winetricks &&  \
    rm winetricks && \

    ##########################################################################
    # CLEAN UP SECTION - THIS GOES AT THE END                                #
    ##########################################################################
    localepurge && \

    # Remove info, man and docs
    rm -r /usr/share/info/* && \
    rm -r /usr/share/man/*  && \
    rm -r /usr/share/doc/*  && \

    # Delete any backup files like /etc/pacman.d/gnupg/pubring.gpg~
    find /. -name "*~" -type f -delete && \

    # Cleanup pacman
    bash -c "echo 'y' | pacman -Scc >/dev/null 2>&1" && \
    paccache -rk0 >/dev/null 2>&1 &&  \
    pacman-optimize && \
    rm -r /var/lib/pacman/sync/*

# Thow in some sample templates (bash scripts)
ADD examples/skype.template  /home/docker/templates/skype.template
ADD examples/sqlyog.template /home/docker/templates/sqlyog.template

CMD /init
