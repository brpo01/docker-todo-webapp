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

        
    }
}