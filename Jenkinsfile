pipeline {
  agent any

  environment {
    AWS_REGION     = 'us-east-1'
    AWS_ACCOUNT_ID = '460928920964'
    ECR_REPO       = '28-10-2025'
    ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    EKS_CLUSTER    = 'floral-monster-1761574697'   // your actual EKS cluster name
    KUBE_NAMESPACE = 'app-prod'
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

    stage('Configure kubeconfig for EKS') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins']]) {
          sh '''
            echo "Setting up kubeconfig for cluster ${EKS_CLUSTER}..."
            aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}

            # Verify Kubernetes access
            kubectl version --client=true
            kubectl get nodes
          '''
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          echo "Deploying manifests to Kubernetes..."

          # Create namespace if not exists
          kubectl get ns ${KUBE_NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${KUBE_NAMESPACE}

          # Apply manifests (skip if file missing)
          [ -f namespace.yaml ] && kubectl apply -f namespace.yaml || true
          [ -f configmap.yaml ] && kubectl -n ${KUBE_NAMESPACE} apply -f configmap.yaml || true
          [ -f secret.yaml ]    && kubectl -n ${KUBE_NAMESPACE} apply -f secret.yaml || true
          [ -f service.yaml ]   && kubectl -n ${KUBE_NAMESPACE} apply -f service.yaml || true
          [ -f deployment.yaml ]&& kubectl -n ${KUBE_NAMESPACE} apply -f deployment.yaml || true

          # Update image in Deployment
          kubectl -n ${KUBE_NAMESPACE} set image deployment/app app=${ECR_REGISTRY}/${ECR_REPO}:${BUILD_NUMBER}

          # Wait for rollout completion
          kubectl -n ${KUBE_NAMESPACE} rollout status deployment/app --timeout=120s

          # Show running pods
          kubectl -n ${KUBE_NAMESPACE} get pods -o wide
        '''
      }
    }
  }

  post {
    always {
      sh '''
        echo "Cleaning up Docker resources..."
        docker logout ${ECR_REGISTRY} || true
        docker image prune -f || true
      '''
    }
  }
}
