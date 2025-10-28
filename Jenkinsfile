pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'         // your AWS region
    AWS_ACCOUNT_ID = '460928920964'      // your AWS account ID
    ECR_REPO       = '28-10-2025'        // your ECR repository name (must be lowercase/valid)
    ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    DOCKER_BUILDKIT = '1'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Login to AWS ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
          sh '''
            echo "Logging in to ECR..."
            aws --region ${AWS_REGION} ecr get-login-password | \
              docker login --username AWS --password-stdin ${ECR_REGISTRY}
          '''
        }
      }
    }

    // (Optional) uncomment to auto-create the repo if it doesn't exist
    // stage('Ensure ECR Repo') {
    //   steps {
    //     withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
    //       sh '''
    //         aws --region ${AWS_REGION} ecr describe-repositories \
    //           --repository-names ${ECR_REPO} >/dev/null 2>&1 || \
    //         aws --region ${AWS_REGION} ecr create-repository \
    //           --repository-name ${ECR_REPO} >/dev/null
    //       '''
    //     }
    //   }
    // }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "Building Docker image..."
          docker build -t ${ECR_REPO}:${BUILD_NUMBER} .
          docker tag ${ECR_REPO}:${BUILD_NUMBER} ${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}
          docker tag ${ECR_REPO}:${BUILD_NUMBER} ${ECR_REGISTRY}/${ECR_REPO}:latest
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        sh '''
          echo "Pushing image to ECR..."
          docker push ${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}
          docker push ${ECR_REGISTRY}/${ECR_REPO}:latest
        '''
      }
    }
  }

  post {
    always {
      sh '''
        echo "Cleaning up..."
        docker logout ${ECR_REGISTRY} || true
        docker image prune -f || true
      '''
    }
  }
}


