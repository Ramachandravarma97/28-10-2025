pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'          // your AWS region
    AWS_ACCOUNT_ID = '460928920964'       // your AWS account ID
    ECR_REPO       = '28-10-2025'         // your ECR repository name
    ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    KUBE_NAMESPACE = 'app-prod'           // namespace to deploy
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

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
          sh '''
            echo "Deploying to Kubernetes..."

            # update kubeconfig for your cluster (replace cluster name)
            aws eks update-kubeconfig --region ${AWS_REGION} --name my-eks-cluster

            # replace image tag in deployment.yaml before applying
            sed -i "s|image:.*|image: ${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}|g" deployment.yaml

            # apply all manifests
            kubectl apply -f namespace.yaml || true
            kubectl apply -f configmap.yaml || true
            kubectl apply -f secret.yaml || true
            kubectl apply -f service.yaml
            kubectl apply -f deployment.yaml

            # verify rollout
            kubectl rollout status deployment/app -n ${KUBE_NAMESPACE} --timeout=120s
          '''
        }
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
