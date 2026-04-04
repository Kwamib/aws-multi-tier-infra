#!/bin/bash
# ------------------------------------------
# Base Image Setup (Baked into AMI via Packer)
# ------------------------------------------
set -euo pipefail

echo ">>> Updating system packages..."
sudo yum update -y
sudo yum install -y git httpd mariadb-server amazon-efs-utils lvm2
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

echo ">>> Configuring Apache..."
sudo systemctl start httpd
sudo systemctl enable httpd

# Secure /var/www directory
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo find /var/www -type d -exec chmod 2775 {} +
sudo find /var/www -type f -exec chmod 0664 {} +

# Enable .htaccess overrides
sudo sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf

echo ">>> Creating health check endpoint..."
echo "OK" | sudo tee /var/www/html/healthcheck.html

echo ">>> Cloning application codebase..."
git clone https://github.com/stackitgit/CliXX_Retail_Repository.git /tmp/wordpress-temp
sudo cp -r /tmp/wordpress-temp/* /var/www/html/
sudo rm -rf /tmp/wordpress-temp

# Ensure wp-config placeholder exists
if [ ! -f /var/www/html/wp-config.php ]; then
  cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
fi

echo ">>> Installing WP-CLI..."
curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
sudo chmod +x /usr/local/bin/wp

sudo systemctl restart httpd

echo ">>> Base image setup complete."
