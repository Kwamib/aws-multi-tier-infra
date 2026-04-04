#!/bin/bash
# ------------------------------------------
# EC2 Instance Bootstrap (runs on launch)
# ------------------------------------------
set -euo pipefail

echo ">>> Starting instance bootstrap..."
echo "  Environment: ${ENVIRONMENT}"
echo "  Region:      ${REGION}"

# Mount EFS
echo ">>> Mounting EFS filesystem..."
mkdir -p ${MOUNT_POINT}
mount -t efs -o tls ${EFS_ID}:/ ${MOUNT_POINT}

# Persist EFS mount across reboots
echo "${EFS_ID}:/ ${MOUNT_POINT} efs _netdev,tls 0 0" >> /etc/fstab

# Configure application database connection
echo ">>> Configuring database connection..."
DB_ENDPOINT="${DB_HOST}"
DB_HOST_CLEAN=$(echo "$DB_ENDPOINT" | cut -d: -f1)

# Update WordPress config with database endpoint
if [ -f ${MOUNT_POINT}/wp-config.php ]; then
  sed -i "s/localhost/$DB_HOST_CLEAN/g" ${MOUNT_POINT}/wp-config.php
fi

# Restart Apache to pick up changes
sudo systemctl restart httpd

echo ">>> Instance bootstrap complete."
