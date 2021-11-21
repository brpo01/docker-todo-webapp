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

        // stage('Start the application') {
        //     steps {
        //         sh "docker-compose up -d"
        //     }
        // }

        stage('Test endpoint & Push Image to Registry') {
            steps{
                script {
                    while(true) {
                        def response = httpRequest 'http://localhost:8000'
                        if (response.status == 200) {
                            sh "docker push tobyrotimi/docker-php-todo:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
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