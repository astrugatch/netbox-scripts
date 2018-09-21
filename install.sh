#!/usr/bin/env bash

VERSION=2.4.4
URL=https://github.com/digitalocean/netbox/archive/v${VERSION}.tar.gz
CURDIR=`pwd`
POSTGRESPWD=N3TB0XD@T@B@S3
PRIVATE_KEY='Yb3QMW1VI6Ln8xUWLqZc7h3G4csdouHDTq5zclbES9EtjIclyM'

# Install pre-requisites
sudo apt-get install -y postgresql libpq-dev

# Setup postgres
sudo -u postgres psql < ${CURDIR}/conf/postgres.conf

# Install app pre-requisites
sudo apt-get install -y python3 python3-dev python3-setuptools build-essential libxml2-dev libxslt1-dev libffi-dev graphviz libpq-dev libssl-dev zlib1g-dev
sudo easy_install3 pip

# Download and install app
mkdir /tmp/netbox/
cd /tmp/netbox/
wget ${URL}
tar xzvf v${VERSION}.tar.gz -C /opt/
sudo ln -s /opt/netbox-${VERSION} /opt/netbox

#Take ownership of netbox media
sudo chown -R netbox:netbox /opt/netbox/netbox/media/

# Install app requirements
cd /opt/netbox/
sudo pip3 install -r requirements.txt

# Setup configuration
cd netbox/netbox/
sudo cp configuration.example.py configuration.py
sudo sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" /opt/netbox/netbox/netbox/configuration.py
sudo sed -i "s/'USER': '',/'USER': 'netbox',/" /opt/netbox/netbox/netbox/configuration.py
sudo sed -i "s/'PASSWORD': '',           # PostgreSQL password/'PASSWORD': '{POSTGRESPWD}',/" /opt/netbox/netbox/netbox/configuration.py
sudo sed -i "s/SECRET_KEY = ''/SECRET_KEY = '${PRIVATE_KEY}'/" /opt/netbox/netbox/netbox/configuration.py

# Run database migrations
cd /opt/netbox/netbox/
sudo python3 manage.py migrate

# Create super user
sudo python3 manage.py createsuperuser

# Collect static files
sudo python3 manage.py collectstatic

# Install webservers
sudo apt-get install -y supervisor nginx

# Install gunicorn
sudo pip3 install gunicorn

# Configure webservers
sudo cp ${CURDIR}/conf/nginx_netbox.conf /etc/nginx/sites-available/netbox.conf
sudo ln -s /etc/nginx/sites-available/netbox.conf /etc/nginx/sites-enabled/netbox.conf
sudo unlink /etc/nginx/sites-enabled/default
sudo service nginx restart

sudo cp ${CURDIR}/conf/gunicorn_config.py /opt/netbox/
sudo cp ${CURDIR}/conf/supervisor_netbox.conf /etc/supervisor/conf.d/netbox.conf
sudo service supervisor restart

echo "DONE"
