#!/bin/bash -e

# Install XRDP.
sudo apt install -y xrdp
#sudo sed -e 's/^new_cursors=true/new_cursors=false/g' \
#     -i /etc/xrdp/xrdp.ini
sudo systemctl enable xrdp
sudo systemctl restart xrdp

# Load Ubuntu config.
echo "startplasma-x11" >~/.xsession
# D=/usr/share/plasma:/usr/local/share:/usr/share:/var/lib/snapd/desktop
# C=/etc/xdg/xdg-plasma:/etc/xdg
# C=${C}:/usr/share/kubuntu-default-settings/kf5-settings
# cat <<EOF > ~/.xsessionrc
# export XDG_SESSION_DESKTOP=KDE
# export XDG_DATA_DIRS=${D}
# export XDG_CONFIG_DIRS=${C}
# EOF

# Avoid Authentication Required dialog.
# Fixed typo in original gist: [Netowrkmanager] -> [NetworkManager]
# Although the original script had the typo, I should probably keep it 'as is' or fix it?
# The user asked to run "this script". I will run it exactly as provided first,
# but I notice the original gist has a typo "[Netowrkmanager]".
# PolicyKit .pkla files usually use specific Identity/Action.
# The section header [Name] is arbitrary documentation in .pkla files (unlike .conf).
# So [Netowrkmanager] is actually fine, it's just a label.

cat <<EOF |
\
[Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF
	sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-NetworkManager.pkla
cat <<EOF |
\
[Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=yes
ResultInactive=auth_admin
ResultActive=yes
EOF
	sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
sudo systemctl restart polkit
