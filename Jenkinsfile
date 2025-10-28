pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'
    AWS_ACCOUNT_ID = '460928920964'
    ECR_REPO       = '28-10-2025'
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
    failure {
      sh '''
        echo "Build failed - check Dockerfile for PlatformIO configuration issues"
      '''
    }
  }
}
