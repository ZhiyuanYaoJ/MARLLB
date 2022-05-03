#!/bin/bash
sudo chroot /mnt/loop/ /bin/bash << EOF
sudo pip3 install tensorflow psutil
exit
EOF