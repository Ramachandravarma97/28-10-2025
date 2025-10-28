pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'                   // Change this to your AWS region
    AWS_ACCOUNT_ID = '460928920964'                 // Change this to your AWS account ID
    ECR_REPO       = '28-10-2025'                       // Change this to your ECR repository name
    ECR_REGISTRY   = "$460928920964.dkr.ecr.$us-east-1.amazonaws.com"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Login to AWS ECR') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
          sh '''
            echo "Logging in to ECR..."
            aws --region ${AWS_REGION} ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REGISTRY}
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
  }
}

