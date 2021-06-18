# Déploiement de l'application
# lamp-mariadb10.2-php7.2
echo "sudo yum update -y
sudo amazon-linux-extras install -y php7.4
sudo amazon-linux-extras enable php7.4
sudo yum install -y httpd
sudo yum install -y mariadb-server
sudo yum install -y php-cli php-pdo php-fpm php-json php-mysqlnd
sudo service mariadb start
sudo service httpd start
mysqladmin -u root create blog
mysql_secure_installation
cd /var/www/html
sudo wget http://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress/* .
sudo rm -rf wordpress
exit" > script_deploiement.sh

scp -i $KEY_NAME.pem script_deploiement.sh ec2-user@$INSTANCE_IP:/home/ec2-user/

ssh -i $KEY_NAME.pem ec2-user@$INSTANCE_IP sudo chmod +x script_deploiement.sh && sudo ./script_deploiement.sh


echo "déploiement de l'application terminée"
echo "Veuillez effectuer les dernières étapes sur http://"$INSTANCE_IP
