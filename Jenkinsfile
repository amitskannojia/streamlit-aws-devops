
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = 'ap-south-1'
        EKS_CLUSTER_NAME = 'streamlit-eks'
        ECR_REPOSITORY = 'streamlit-app'
        K8S_NAMESPACE = 'streamlit'
        APP_DEPLOYMENT = 'streamlit-app'
        APP_CONTAINER = 'streamlit'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh '''
                    echo "Repository checked out successfully"
                    git rev-parse --short HEAD
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    set -eu

                    python3 -m venv .venv
                    . .venv/bin/activate

                    python -m pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install pytest

                    pytest -q tests/
                '''
            }
        }

        stage('Verify AWS and EKS') {
            steps {
                sh '''
                    set -eu

                    aws sts get-caller-identity

                    aws eks describe-cluster \
                      --region "$AWS_REGION" \
                      --name "$EKS_CLUSTER_NAME" \
                      --query 'cluster.status' \
                      --output text

                    mkdir -p "$WORKSPACE/.kube"
                    chmod 700 "$WORKSPACE/.kube"

                    export KUBECONFIG="$WORKSPACE/.kube/config"

                    aws eks update-kubeconfig \
                      --region "$AWS_REGION" \
                      --name "$EKS_CLUSTER_NAME" \
                      --kubeconfig "$KUBECONFIG"

                    kubectl get nodes
                '''
            }
        }

        stage('Build and Push to ECR') {
            steps {
                sh '''
                    set -eu

                    ACCOUNT_ID=$(aws sts get-caller-identity \
                      --query Account --output text)

                    ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                    IMAGE_URI="${ECR_REGISTRY}/${ECR_REPOSITORY}:${BUILD_NUMBER}"

                    aws ecr describe-repositories \
                      --region "$AWS_REGION" \
                      --repository-names "$ECR_REPOSITORY"

                    aws ecr get-login-password \
                      --region "$AWS_REGION" \
                      | docker login \
                          --username AWS \
                          --password-stdin "$ECR_REGISTRY"

                    docker build -t "$IMAGE_URI" .
                    docker push "$IMAGE_URI"

                    echo "IMAGE_URI=$IMAGE_URI" > image.env
                    echo "Image pushed: $IMAGE_URI"
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    set -eu

                    . ./image.env

                    export KUBECONFIG="$WORKSPACE/.kube/config"

                    aws eks update-kubeconfig \
                      --region "$AWS_REGION" \
                      --name "$EKS_CLUSTER_NAME" \
                      --kubeconfig "$KUBECONFIG"

                    sed "s|REPLACE_WITH_ECR_IMAGE|${IMAGE_URI}|g" \
                      k8s/deployment.yaml \
                      > "$WORKSPACE/deployment.generated.yaml"

                    kubectl apply -f k8s/namespace.yaml

                    kubectl apply \
                      -n "$K8S_NAMESPACE" \
                      -f "$WORKSPACE/deployment.generated.yaml"

                    kubectl apply \
                      -n "$K8S_NAMESPACE" \
                      -f k8s/service.yaml

                    kubectl apply \
                      -n "$K8S_NAMESPACE" \
                      -f k8s/hpa.yaml

                    kubectl apply \
                      -n "$K8S_NAMESPACE" \
                      -f k8s/ingress.yaml

                    kubectl rollout status \
                      deployment/"$APP_DEPLOYMENT" \
                      -n "$K8S_NAMESPACE" \
                      --timeout=300s

                    kubectl get deployments,services,ingress,hpa \
                      -n "$K8S_NAMESPACE"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                rm -rf "$WORKSPACE/.kube"
                rm -f "$WORKSPACE/deployment.generated.yaml"
                rm -f "$WORKSPACE/image.env"
                rm -rf "$WORKSPACE/.venv"
            '''
        }
    }
}
