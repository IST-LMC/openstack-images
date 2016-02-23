#! /bin/bash

cd ../images
# Download the latest version
wget -N https://cloud-images.ubuntu.com/daily/server/precise/current/precise-server-cloudimg-amd64-disk1.img

# Upload to Glance
echo "Uploading to Glance..."
TEMP_ID=`glance image-create --disk-format qcow2 --container-format bare --file precise-server-cloudimg-amd64-disk1.img --name TempUbuntu12Image | grep id | awk ' { print $4 }'`

# Run Packer
packer build \
    -var "source_image=$TEMP_ID" \
    ../scripts/Ubuntu1204.json | tee ../logs/Ubuntu1204.log

if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi

glance image-delete $TEMP_ID
sleep 5
IMAGE_ID=$(glance image-list | grep Packer | awk ' { print $2} ')
glance image-update --name "Ubuntu 12.04" --property description="Built on `date`" --property image_type='image' "${IMAGE_ID}"

echo "Image Available!"
