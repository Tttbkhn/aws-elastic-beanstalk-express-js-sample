pipeline {
  agent {
    // Use Node 16 as the build agent (Dockerized)
    docker {
      image 'node:16'
    }
  }

  environment {
    // Docker remote host
    DOCKER_HOST       = credentials('DOCKER_HOST')               // The Docker host value stored on Jenkins credentials
    DOCKER_TLS_VERIFY = '1'                                      // 1 for TLS
    DOCKER_CERT_PATH  = '/certs/client'                          // the location of the certs in Docker

    // ----- Image naming -----
    IMAGE_NAME        = 'thanhthutruong/devsecops_assessment_2'
    IMAGE_TAG         = "${env.BRANCH_NAME ?: 'main'}-${env.BUILD_NUMBER}"
    DOCKER_IMAGE      = "docker.io/${IMAGE_NAME}:${IMAGE_TAG}"

    // Keep npm logs concise
    npm_config_loglevel = 'warn'
  }

  options {
    timestamps()                                                // Prefixes every console log line with a timestamp
    buildDiscarder(logRotator(numToKeepStr: '20'))              // Keeps only the most recent 20 completed builds; older ones are deleted
    ansiColor('xterm')                                          // Enables ANSI color in the Jenkins console so tools that print colored output (npm, docker, test runners) render properly.
  }

  stages {
    stage('Install Dependencies') {
      steps {
        sh 'node -v && npm -v'                                  // Checks Node.js and npm versions. Verify that this is Node 16
        sh 'npm install --save'                                 // Installs dependencies from package.json.
      }
      post {
        failure {
          archiveArtifacts artifacts: 'npm-debug.log,**/npm-debug.log', allowEmptyArchive: true       // Archives debug logs if the stage fails.
        }
      }
    }

    stage('Run Unit Tests') {
      steps {
        sh 'npm test'                                           // Running npm test by executing the jest test suite
      }
    }

    stage('Dependency Scan (Snyk)') {
      environment { SNYK_TOKEN = credentials('SNYK_TOKEN') }
      steps {
        sh '''
          npx -y snyk@latest auth "${SNYK_TOKEN}"
          npx -y snyk@latest test --severity-threshold=high
        '''
      }
    }

    stage('Docker Build Image') {
      steps {
        script {
            IMG = docker.build(DOCKER_IMAGE)
        }
      }
    }

    stage('Docker Push') {
      steps {
        script {
          docker.withRegistry('https://index.docker.io/v1/', 'DOCKERHUB_CREDS') {       // Establishes a connection to Docker Hub
            IMG.push()                                                                  // push BRANCH-BUILD tag
            if ((env.BRANCH_NAME ?: 'main') == 'main') {
              IMG.push('latest')                                                        // Conditionally pushes the image with the latest tag if the current branch is main
            }
          }
        }
      }
    }
  }

  post {
    always {
      echo "Build finished: ${currentBuild.currentResult}"
    }
    success {
      echo "Image pushed: ${DOCKER_IMAGE}"
    }
    failure {
      echo "Build failed. Check logs above."
    }
  }
}
