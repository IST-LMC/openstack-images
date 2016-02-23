#! /bin/bash

cd ../images
# Download the latest version
wget -N https://cloud-images.ubuntu.com/daily/server/trusty/current/trusty-server-cloudimg-amd64-disk1.img

# Upload to Glance
echo "Uploading to Glance..."
TEMP_ID=`glance image-create --disk-format qcow2 --container-format bare --file trusty-server-cloudimg-amd64-disk1.img --name TempUbuntuImage | grep id | awk ' { print $4 }'`

# Run Packer
packer build \
    -var "source_image=$TEMP_ID" \
    ../scripts/Ubuntu1404.json | tee ../logs/Ubuntu1404.log

if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi

glance image-delete $TEMP_ID
sleep 5
IMAGE_ID=$(glance image-list | grep Packer | awk ' { print $2} ')
glance image-update --name "Ubuntu 14.04"  --property description="Built on `date`" --property image_type='image' "${IMAGE_ID}"

echo "Image Available !"
