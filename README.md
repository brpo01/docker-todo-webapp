## PHP-TODO Application Containerization using Docker

- Clone php-todo repository using `wget`(and unzip it) or `git clone`

- Write a dockerfile for php-todo app and save it in the php-todo directory
```
FROM php:7-apache
MAINTAINER Rotimi opraise139@gmail.com

# Install docker php dependencies
RUN docker-php-ext-install mysqli 

# copy virtualhost config file unto the apache deafult conf in the container
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf
COPY start-apache /usr/local/bin
RUN a2enmod rewrite

# Install php dependency - composer
RUN curl -sS https://getcomposer.org/installer |php && mv composer.phar /usr/local/bin/composer

#Copy all files 
COPY . /var/www/html
RUN chown -R www-data:www-data /var/www

EXPOSE 80

CMD ["start-apache"]
```

- Open the `start-apache` file, add the following commands below in addition to the commands already in the file:

```
#!/usr/bin/env bash
sed -i "s/Listen 80/Listen ${PORT:-80}/g" /etc/apache2/ports.conf
sed -i "s/:80/:${PORT:-80}/g" /etc/apache2/sites-enabled/*

composer install --no-plugins --no-scripts

php artisan migrate
php artisan key:generate
php artisan db:seed

apache2-foreground
```

- Create a docker-compose.yml in the php-todo directory and paste the code below:

```yaml
version: "3.3"

services: 
  todo-app:
    build: .
    links:
      - todo-db
    depends_on: 
      - todo-db
    restart: always
    volumes:
      - todo-app:/var/www/html
    ports:
      - ${APP_PORT}:80
  todo-db:
    image: mysql:5.7
    hostname: ${MYSQL_HOSTNAME}
    volumes:
      - todo-db:/var/lib/mysql
    restart: always
    environment:
      MYSQL_DATABASE: ${MYSQL_DB}
      MYSQL_USERNAME: ${MYSQL_USERNAME}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}

volumes:
  todo-app:
  todo-db:
```

- Update the `.env` file

```
APP_ENV=local
APP_DEBUG=true
APP_KEY=SomeRandomString
APP_URL=http://localhost

MYSQL_HOSTNAME=mysqlserverhost
MYSQL_DB=homestead
MYSQL_USERNAME=homestead
MYSQL_PASSWORD=sePret^i
MYSQL_ROOT_PASSWORD=password1234567
APP_PORT=8000

CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_DRIVER=sync

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_DRIVER=smtp
MAIL_HOST=mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

- Make sure you change directory to php-todo directory. Build image using this command:
```
docker build -t php-todo:latest .
```

- Make sure you change directory to php-todo directory. Deploy the containers:
```
docker-compose up -d
```
![16](https://user-images.githubusercontent.com/47898882/145481880-aff9ae4d-cd12-4063-ac02-1501276823fe.JPG)

- We are going to open a docker hub account if we do not have already. Go to  your bbroswer and open a dockerhub account
- On your terminal/editor, create a new tag for the image you want to push using the
proper syntax.

```
docker tag php-todo:latest tobyrotimi/php-todo:1.0.0
```

- Run this command to see the image with the newly created tag

```
docker ps -a
```

Login to your dockerhub account and type in your credentials

```
docker login
```

![18](https://user-images.githubusercontent.com/47898882/145481888-79739991-eb03-461d-9b0a-9d295569c41b.JPG)

- Push the docker image from the local machine to the dockerhub repository
```
docker push tobyrotimi/php-todo:1.0.0
```

![17](https://user-images.githubusercontent.com/47898882/145481885-fcd096d6-4e39-4d95-8910-af9e2d952a5b.JPG)

![19](https://user-images.githubusercontent.com/47898882/145481892-9da33784-9efe-451b-81c1-3864ebb420d2.JPG)

## CI/CD with Jenkins (Php-Todo Application) - Deploying/Building Docker Containers & Pushing to Dockerhub using Jenkins

### 1. Using Local Machine

-Stop and remove the manually deployed containers of above
```
docker-compose down
```

- Run the following command in your home directory to install java runtime:
```
sudo apt update -y
sudo apt install openjdk-11-jdk
```
- Run the following commands to install jenkins:
```
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > \
    /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
```

#### Unlocking Jenkins
- When you first access a new Jenkins instance, you are asked to unlock it using an automatically-generated password.

- Browse to http://ip-address:8080 (or whichever port you configured for Jenkins when installing it) and wait until the Unlock Jenkins page appears and you can use

`sudo cat /var/lib/jenkins/secrets/initialAdminPassword` to print the password on the terminal.

#### Jenkins Pipeline
- First we will install the plugins needed
  - On the Jenkins Dashboard, click on `Manage Jenkins` and go to `Manage Plugins`.
  - Search and install the following plugins:
    - Blue Ocean
    - Docker
    - Docker Compose Build Steps
    - HttpRequest

- We need to create credentials that we will reference so as to be able to push our image to the docker hub repository

  - Click on  `Manage Jenkins` and go to `Manage Credentials`.
  - Click on `global`
  - Click on `add credentials` and choose `username with password`
  - Input your dockerhub username and password

- Create a Jenkinsfile in the php-todo directory that will build image from context in the github repo; deploy application; make http request to see if it returns the status code 200 & push the image to the dockerhub repository and finally clean-up stage where the  image is deleted on the Jenkins server

```
pipeline {
    environment {
        REGISTRY = credentials('dockerhub-cred')
    }
    agent any

    stages{

        stage('Initial Cleanup') {
            steps {
                dir("${WORKSPACE}") {
                deleteDir()
                }
            }
        }

        stage('Checkout SCM') {
            steps {
                git branch: 'master', url: 'https://github.com/brpo01/docker-todo-webapp.git'
            }
        }

        stage('Build Image') {
            steps {
                sh "docker build -t tobyrotimi/docker-php-todo:${env.BRANCH_NAME}-${env.BUILD_NUMBER} ."
            }
        }

        stage('Start the application') {
            steps {
                sh "docker-compose up -d"
            }
        }

        stage('Test endpoint & Push Image to Registry') {
            steps{
                script {
                    while(true) {
                        def response = httpRequest 'http://localhost'
                        if (response.status == 200) {
                            withCredentials([usernamePassword(credentialsId: 'dockerhub-cred', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                                sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                                sh "docker push tobyrotimi/docker-php-todo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
                            }
                            break 
                        }
                    }
                }
            }
        }

        stage('Remove Images') {
            steps {
                sh "docker-compose down"
                sh "docker rmi tobyrotimi/docker-php-todo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
            }
        }
    }
}
```

- Go To Jenkins Blue Ocean & trigger a build.

- A build will start. The pipeline should be successful now

![20](https://user-images.githubusercontent.com/47898882/145481897-1dae5b91-9140-41c3-9aac-53a7d8abe839.JPG)

#### Github Webhook
We need to create  a webhook so that Jenkins will automatically pick up changes in our github repo and trigger a build instead of having to click "Scan Repository Now" all the time on jenkins. We will input that URL in github webhooks so any changes we make to our github repo will automatically trigger a build.

\
- Go to github repository and click on `Settings`
	- Click on `Webhooks`
	- Click on `Add Webhooks`
	- Input http://ip-address:8080/github-webhook
	- Select application/json as the Content-Type
	- Click on `Add Webhook` to save the webhook

- Go to your terminal and change something in your jenkinsfile and save and push to your github repo. If everything works out fine, this will trigger a build which you can see on your Jenkins Dashboard.

![20](https://user-images.githubusercontent.com/47898882/145481897-1dae5b91-9140-41c3-9aac-53a7d8abe839.JPG)