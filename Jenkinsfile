#!groovy

pipeline {
    agent {
        label 'master'
    }
    parameters {
        string(name: 'APP_GIT_BRANCH', defaultValue: 'master', description: 'Git branch to build.')
    }
    environment {
        PACKER = '/usr/local/bin/packer -machine-readable'
        AWS_ACCESS_KEY = credentials('aws-access-key')
        AWS_SECRET_KEY = credentials('aws-secret-key')
        AWS_TIMEOUT_SECONDS = '900'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout poll:false, scm: [
                    $class: 'GitSCM',
                    branches: [[name: "${APP_GIT_BRANCH}"]],
                    userRemoteConfigs: [[
                    url: "${APP_GIT_URL}",
                    credentialsId: 'daitc-github',
                    ]]
                ]
            }
        }
        stage('Validate') {
            steps {
                dir('PACKER') {
                    sh " ${PACKER} inspect packer-backup.json"
                    sh " ${PACKER} validate packer-backup.json"
                }
            }
        }        
        stage('Build') {
            steps {
                dir('PACKER') {
                    sh " ${PACKER} build packer-backup.json"
                }
            }
        }        
    }
}
