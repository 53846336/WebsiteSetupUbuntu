#!/bin/bash

# Variables
domain_name="website_domain"
email_address="website_mail_id"
app_path="project_directory"
server_ip="server_ip"

# Update system
sudo apt-get update

# Install necessary software
sudo apt-get install -y python3 python3-pip nginx

# Create and activate a virtual environment
cd "$app_path" || exit
python3 -m venv venv
source venv/bin/activate

# Install Flask and Gunicorn within the virtual environment
pip install flask gunicorn

# Install Certbot and the Nginx plugin
sudo apt-get install -y certbot python3-certbot-nginx
#!/bin/bash

# Variables
domain_name="tradingtick.org"
email_address="tradingtick.org@gmail.com"
app_path="/var/www/coming_soon"
server_ip="45.79.122.228"

# Update system
sudo apt-get update

# Install necessary software
sudo apt-get install -y python3 python3-pip nginx

# Create and activate a virtual environment
cd "$app_path" || exit
python3 -m venv venv
source venv/bin/activate

# Install Flask and Gunicorn within the virtual environment
pip install flask gunicorn

# Install Certbot and the Nginx plugin
sudo apt-get install -y certbot python3-certbot-nginx

# Remove existing Nginx configuration for the domain
sudo rm /etc/nginx/sites-enabled/$domain_name
sudo rm /etc/nginx/sites-available/$domain_name

# Obtain SSL certificate with Certbot
sudo certbot certonly --nginx --agree-tos --redirect --non-interactive --email "$email_address" -d $domain_name -d "www.$domain_name"

# Check SSL certificate paths before configuring Nginx
if [[ ! -f "/etc/letsencrypt/live/$domain_name/fullchain.pem" || ! -f "/etc/letsencrypt/live/$domain_name/privkey.pem" ]]; then
    echo "SSL certificates not found. Please check Certbot configuration."
    exit 1
fi

# Create an Nginx configuration file for your app
sudo tee /etc/nginx/sites-available/$domain_name > /dev/null <<EOF
server {
    listen 80;
    server_name $domain_name www.$domain_name;

    location / {
        proxy_pass http://$server_ip:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}

server {
    listen 443 ssl;
    server_name $domain_name www.$domain_name;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;

    location / {
        proxy_pass http://$server_ip:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1.2 TLSv1.3;
        proxy_ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
        proxy_ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;
    }
}
EOF

# Enable the site by creating a symbolic link
sudo ln -s /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/

# Test Nginx configuration
sudo nginx -t

# Restart Nginx to apply changes
sudo systemctl restart nginx

# Start Gunicorn to run your Flask app on port 80 (requires root privileges)
#gunicorn -w 4 -b 0.0.0.0:80 app:app
nohup gunicorn -w 4 -b 0.0.0.0:8000 app:app > nohup.log &


