pipeline {
    options {
        buildDiscarder(logRotator(numToKeepStr: '2'))
    }
    agent any

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }

        stage('checkout github') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/itsurvey6-lab/netflix-clone.git'
            }
        }

        stage('sonarqube analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=Netflix \
                        -Dsonar.projectKey=Netflix
                    '''
                }
            }
        }

        stage('Dependency Check') {
            steps {
                dependencyCheck(
                    additionalArguments: '--scan ./',
                    nvdCredentialsId: 'nvd-api-key',
                    odcInstallation: 'DP-Check'
                )

                dependencyCheckPublisher(
                    pattern: '**/dependency-check-report.xml'
                )
            }
        }

        stage('TRIVY SCAN') {
            steps {
                sh 'trivy fs . > trivyfs.txt'

                input(
                    message: 'Are you sure to proceed?',
                    ok: 'proceed'
                )
            }
        }

        stage('docker build') {
            steps {
                sh 'docker build --build-arg API_KEY=YOUR_KEY -t netflix ./nextflix'
            }
        }

        stage('image scan') {
            steps {
                sh 'trivy image netflix > trivyimage.txt'

                input(
                    message: 'Are you sure to proceed?',
                    ok: 'proceed'
                )
            }
        }

        stage('docker push') {
            steps {
                withDockerRegistry(
                    credentialsId: 'Docker-hub',
                    url: 'https://index.docker.io/v1/'
                ) {
                    sh 'docker tag netflix itsurvey6/netflix:${BUILD_NUMBER}'
                    sh 'docker push itsurvey6/netflix:${BUILD_NUMBER}'
                }
            }
        }
        stage('Update Deployment') {
            steps {
                sh '''
                    sed -i "s|image: itsurvey6/netflix:.*|image: itsurvey6/netflix:${BUILD_NUMBER}|" k8s/deployment.yml

                    git config user.email "itsurvey6@gmail.com"
                    git config user.name "itsurvey6-lab"

                    git add k8s/deployment.yml
                    git commit -m "Update image to ${BUILD_NUMBER}" || true
                    git push origin main
                '''
            }
        }
    }
}