FROM php:7.4.24-apache
MAINTAINER Rotimi opraise139@gmail.com

# Install docker php dependencies
RUN docker-php-ext-install mysqli pdo_mysql

# copy virtualhost config file unto the apache deafult conf in the container
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
COPY start-apache /usr/local/bin
RUN a2enmod rewrite

# Install php dependency - composer
RUN curl -sS https://getcomposer.org/installer |php && mv composer.phar /usr/local/bin/composer

#Copy all files 
COPY . /var/www
RUN chown -R www-data:www-data /var/www

CMD ["start-apache"]