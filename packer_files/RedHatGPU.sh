#! /bin/bash -x

# This script installs the drivers for the NVIDIA graphics cards

cat <<EOF | sudo tee -a /etc/yum.conf
exclude=dhclient* dhcp-*
EOF

sudo yum -y update
sudo yum -y install kernel-devel kernel-headers gcc make pciutils
sudo yum -y groupinstall "Development Tools"

cat <<EOF | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
alias nouveau off
alias lbm-nouveau off
EOF

echo blacklist nouveau | sudo tee -a /etc/modprobe.d/blacklist.conf

sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
sudo yum -y install kmod-nvidia

sudo yum -y install perl-Env
sudo yum install -y epel-release
sudo yum install -y @xfce
sudo yum groupinstall -y "X Window System"
sudo systemctl set-default graphical.target

sudo yum install -y VirtualGL
sudo yum install -y wget

wget -q https://swift-yyc.cloud.cybera.ca:8080/v1/AUTH_ca447e24e0f84eab8e6f6b93703b774a/public_files/turbovnc-2.0.91.x86_64.rpm
sudo rpm -Uhv turbovnc-2.0.91.x86_64.rpm
sudo vglserver_config -config +s +f +t

sudo chmod +s /usr/lib64/VirtualGL/libdlfaker.so
sudo chmod +s /usr/lib64/VirtualGL/librrfaker.so

cd /home/centos
mkdir .vnc
cat > .vnc/xstartup.turbovnc <<EOF
vglrun /usr/bin/startxfce4 &
EOF
chmod +x .vnc/xstartup.turbovnc
touch .vnc/passwd
chown -R centos: .vnc

sudo ln -fs /etc/pam.d/password-auth /etc/pam.d/turbovnc
cat <<EOF | sudo tee /etc/sysconfig/tvncservers
VNCSERVERS="1:centos"
VNCSERVERARGS[1]="-securitytypes unixlogin -pamsession -geometry 1240x900 -depth 24"
EOF
sudo chkconfig --level 345 tvncserver on


#Configure X11 and nvidia
cat <<EOF | sudo tee /etc/X11/xorg.conf
Section "DRI"
        Mode 0666
EndSection

Section "ServerLayout"
    Identifier     "Layout0"
    Screen      0  "Screen0"
    InputDevice    "Keyboard0" "CoreKeyboard"
    InputDevice    "Mouse0" "CorePointer"
EndSection
Section "Files"
    ModulePath   "/usr/lib64/xorg/modules/extensions/nvidia"
    ModulePath   "/usr/lib64/xorg/modules"
EndSection
Section "InputDevice"
    # generated from default
    Identifier     "Mouse0"
    Driver         "mouse"
    Option         "Protocol" "auto"
    Option         "Device" "/dev/input/mice"
    Option         "Emulate3Buttons" "no"
    Option         "ZAxisMapping" "4 5"
EndSection
Section "InputDevice"
    # generated from default
    Identifier     "Keyboard0"
    Driver         "kbd"
EndSection
Section "Monitor"
    Identifier     "Monitor0"
    VendorName     "Unknown"
    ModelName      "Unknown"
    HorizSync       28.0 - 33.0
    VertRefresh     43.0 - 72.0
    Option         "DPMS"
EndSection
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "0:7:0"
EndSection
Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    Monitor        "Monitor0"
    DefaultDepth    24
    Option         "UseDisplayDevice" "None"
    SubSection     "Display"
        Virtual     1280 1024
        Depth       24
    EndSubSection
EndSection

EOF
sudo chattr +i /etc/X11/xorg.conf

wget http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-7.5-18.x86_64.rpm
sudo rpm -i cuda-repo-rhel7-7.5-18.x86_64.rpm
sudo yum clean all
sudo yum -y install cuda
sudo rm -rf /{root,home/*}/{.ssh,.bash_history} && history -c
  
cat "" | sudo tee /etc/hostname

#Ensure changes are written to disk
sync