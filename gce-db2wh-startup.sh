#!/bin/bash -eu
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/usr/bin/env bash

if [ -f /root/INSTALLATION_DONE ]; then
    echo "Skipping because installation completed"
    exit 0
fi

apt-get update

# Docker installation
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

STORAGE_TYPE=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/storagetype -H "Metadata-Flavor: Google")
echo "Desired storage type: $STORAGE_TYPE"
if [ $STORAGE_TYPE = "nfs_filestore" ]; then
    echo "Installing NFS packages"
    apt-get install -y nfs-common
    mkdir -p /mnt/clusterfs
    FILESTORE_IP=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/filestoreip -H "Metadata-Flavor: Google")
    mount "${FILESTORE_IP}:/db2whdata" /mnt/clusterfs
elif [ $STORAGE_TYPE = "gluster" ]; then
    echo "Initializing filesystem"
    DEVICE_NAME=sdb
    DEVICE_PATH="/dev/$DEVICE_NAME"
    PARTITION_NAME="$DEVICE_NAME"1
    PARTITION_PATH="/dev/$PARTITION_NAME"
    MOUNT_PATH="/mnt/$PARTITION_NAME"
    parted --script "$DEVICE_PATH" mklabel gpt
    parted --script -a optimal "$DEVICE_PATH" mkpart primary 0% 100%
    mkfs.xfs -f -i size=512 "$PARTITION_PATH"
    mkdir -p /mnt/"$PARTITION_NAME"
    grep -q -F "$PARTITION_PATH" /etc/fstab || echo "$PARTITION_PATH $MOUNT_PATH xfs defaults 0 0" >> /etc/fstab
    mount -a
    BRICK_PATH="$MOUNT_PATH"/brick
    mkdir -p "$BRICK_PATH"

    echo "Installing GlusterFS packages"
    add-apt-repository ppa:gluster/glusterfs-4.1
    apt-get update
    apt-get install -y glusterfs-server parted

    echo "Initializing glusterfs cluster"
    until gluster peer probe db2wh-1; do sleep 5; echo "Retry adding db2wh-1"; done
    until gluster peer probe db2wh-2; do sleep 5; echo "Retry adding db2wh-2"; done
    until gluster peer probe db2wh-3; do sleep 5; echo "Retry adding db2wh-3"; done

    echo "Initializing glusterfs volume"
    HOSTNAME="$(hostname -s)"
    VOLUME_NAME="gv0"
    if [ $HOSTNAME = "db2wh-1" ]; then
        until gluster volume create "$VOLUME_NAME" replica 3 db2wh-1:"$BRICK_PATH" db2wh-2:"$BRICK_PATH" db2wh-3:"$BRICK_PATH" force --mode=script ; do
            sleep 5;
            echo "Retry creating volume $VOLUME_NAME";
        done
        
        until gluster volume start "$VOLUME_NAME" force; do
            sleep 5;
            echo "Retry starting volume $VOLUME_NAME";
        done
    fi

    echo "Configuring kernel modules"
    modprobe fuse
    grep -qs -F "fuse" /etc/modules-load.d/glusterfs.conf || echo "fuse" >> /etc/modules-load.d/glusterfs.conf

    echo "Mounting glusterfs volume"
    GLUSTER_MOUNT_PATH=/mnt/clusterfs
    mkdir -p "$GLUSTER_MOUNT_PATH"
    grep -q -F "glusterfs" /etc/fstab || echo "db2wh-1:/$VOLUME_NAME $GLUSTER_MOUNT_PATH glusterfs defaults,_netdev,log-level=INFO,log-file=/var/log/gluster.log 0 0" >> /etc/fstab
    until mount -a; do sleep 5; echo "Retry mounting volumes"; done
else
    echo "No storage type selected"
    exit 1
fi

touch /root/INSTALLATION_DONE
