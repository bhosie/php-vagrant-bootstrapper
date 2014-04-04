DEFAULT="/etc/apache2/sites-available/default"
DEFAULT_SSL="/etc/apache2/sites-available/default-ssl"

sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password vagrant'
sudo debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password vagrant'
sudo apt-get update
sudo apt-get -y install mysql-server-5.5 php5-mysql apache2 php5 php5-curl php5-gd libapache2-mod-php5 vim sendmail


## Create a root folder for apache
if [ ! -d "/vagrant/apache_root" ]; 
then
mkdir /vagrant/apache_root
fi

## Create a resources folder if one doesn't exist
if [ ! -d "/vagrant/resources" ]; 
then
mkdir /vagrant/resources
fi

## Create some default 'project' folders
if [ ! -d "/vagrant/project1" ]; 
then
mkdir /vagrant/project1
fi

if [ ! -d "/vagrant/project2" ]; 
then
mkdir /vagrant/project2
fi

if [ ! -d "/vagrant/project3" ]; 
then
mkdir /vagrant/project3
fi

## Change apache's root location to the folder we created above
if [ ! -h /var/www ];
then 
    rm -rf /var/www
    sudo ln -s /vagrant/apache_root /var/www

    sed -i '/AllowOverride None/c AllowOverride All' $DEFAULT

fi

#enable common modules
a2enmod rewrite
a2enmod ssl
a2enmod headers

##Enable default-ssl
a2ensite default-ssl
service apache2 restart

## Update /etc/sites-available/default
echo "<VirtualHost *:80>
	ServerName proj.1
	DocumentRoot /vagrant/project1
</VirtualHost>
<VirtualHost *:80>
	ServerName b.api
	DocumentRoot /vagrant/project2
</VirtualHost>
<VirtualHost *:80>
	ServerName b.grid
	DocumentRoot /vagrant/project3
</VirtualHost> " >> $DEFAULT

##delete the last line of default-ssl (</IfModule>)
sed -i '' -e '$ d' $DEFAULT_SSL

## Update /etc/sites-available/default-ssl
echo "<VirtualHost *:443>
	ServerName proj.1
	DocumentRoot /vagrant/project1
	SSLEngine on
	SSLCertificateFile    /vagrant/resources/server.crt
    SSLCertificateKeyFile /vagrant/resources/server.key
</VirtualHost>
<VirtualHost *:443>
	ServerName proj.2
	DocumentRoot /vagrant/project2
	SSLEngine on
	SSLCertificateFile    /vagrant/resources/server.crt
    SSLCertificateKeyFile /vagrant/resources/server.key
</VirtualHost>
<VirtualHost *:443>
	ServerName proj.3
	DocumentRoot /vagrant/project3
	SSLEngine on
	SSLCertificateFile    /vagrant/resources/server.crt
    SSLCertificateKeyFile /vagrant/resources/server.key
</VirtualHost>
</IfModule>" >> $DEFAULT_SSL

##### add NameVirtualHost *:443 to /etc/apache2/ports.conf
echo "ServerName	localhost" >> /etc/apache2/httpd.conf
sed -i '/<IfModule mod_ssl.c>/a 	NameVirtualHost *:443' /etc/apache2/ports.conf
sed -i '/AllowOverride None/c AllowOverride All' $DEFAULT
sed -i '/AllowOverride None/c AllowOverride All' $DEFAULT_SSL
sed -i 's|/etc/ssl/certs/ssl-cert-snakeoil.pem|/vagrant/resources/server.crt|' $DEFAULT_SSL
sed -i 's|/etc/ssl/private/ssl-cert-snakeoil.key|/vagrant/resources/server.key|' $DEFAULT_SSL

####add to apache conf to fix shared folder refresh EnableSendfile Off
## https://github.com/mitchellh/vagrant/issues/351

echo "
#Vagrant / VB fix   
EnableSendfile Off

"  >> /etc/apache2/apache2.conf                                    

##always start apache on boot
update-rc.d apache2 defaults

sudo service apache2 restart

###manual stuff
echo "*Don\'t forget to generate ssl certs and edit root ssl host key files if you want to use something besides the default!*"
echo ""
echo "*If you want to use Mailcatcher for testing, update the sendmail path in php.ini to '/usr/bin/env catchmail'*"
echo ""
echo ""
echo "*** At the next prompt, type 'vagrant ssh', then type 'sudo apt-get -y install phpmyadmin' and follow the prompts ***"
echo ""
echo ""
echo "******Remember to add this line to your host computer's /etc/hosts file: '192.168.33.12 proj.1 proj.2 proj.3'******" 
