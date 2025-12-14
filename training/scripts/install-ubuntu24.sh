#!/bin/bash

#===============================================================================
# Kubernetes with Helm - Environment Setup Script for Ubuntu 24.04 LTS
#===============================================================================
# This script installs Docker, kubectl, Minikube, and Helm on Ubuntu 24.04
# Run with: chmod +x install-ubuntu24.sh && ./install-ubuntu24.sh
#===============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root or with sudo"
        print_info "The script will ask for sudo password when needed"
        exit 1
    fi
}

# Check Ubuntu version
check_ubuntu_version() {
    print_header "Checking Ubuntu Version"
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            print_success "Detected: $PRETTY_NAME"
            if [[ "$VERSION_ID" != "24.04" ]]; then
                print_warning "This script is optimized for Ubuntu 24.04"
                print_warning "You are running Ubuntu $VERSION_ID - some commands may differ"
                read -p "Do you want to continue? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    exit 1
                fi
            fi
        else
            print_error "This script is designed for Ubuntu. Detected: $ID"
            exit 1
        fi
    else
        print_error "Cannot detect OS version"
        exit 1
    fi
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    
    sudo apt update
    sudo apt upgrade -y
    print_success "System packages updated"
}

# Install prerequisites
install_prerequisites() {
    print_header "Installing Prerequisites"
    
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
        gnupg \
        lsb-release \
        wget
    
    print_success "Prerequisites installed"
}

# Install Docker
install_docker() {
    print_header "Installing Docker"
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        print_warning "Docker is already installed: $DOCKER_VERSION"
        read -p "Do you want to reinstall Docker? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Docker installation"
            return
        fi
        # Remove old Docker installation
        sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    fi
    
    # Add Docker's official GPG key
    print_info "Adding Docker GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add the Docker repository
    print_info "Adding Docker repository..."
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    print_info "Installing Docker packages..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add current user to docker group
    print_info "Adding user to docker group..."
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Fix Docker socket permissions for immediate use (avoids permission denied errors)
    print_info "Fixing Docker socket permissions for immediate use..."
    sudo chmod 666 /var/run/docker.sock
    
    print_success "Docker installed successfully"
    print_warning "For permanent docker group membership, log out and back in"
    print_info "Or run: newgrp docker"
    print_info "Docker socket permissions have been temporarily fixed for this session"
}

# Install kubectl
install_kubectl() {
    print_header "Installing kubectl"
    
    # Check if kubectl is already installed
    if command -v kubectl &> /dev/null; then
        KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client)
        print_warning "kubectl is already installed"
        print_info "$KUBECTL_VERSION"
        read -p "Do you want to reinstall kubectl? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping kubectl installation"
            return
        fi
    fi
    
    # Download the latest stable kubectl
    print_info "Downloading kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    # Verify the binary (optional but recommended)
    print_info "Verifying kubectl binary..."
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    
    # Install kubectl
    print_info "Installing kubectl..."
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Cleanup
    rm -f kubectl kubectl.sha256
    
    print_success "kubectl installed successfully: $KUBECTL_VERSION"
}

# Install Minikube
install_minikube() {
    print_header "Installing Minikube"
    
    # Check if Minikube is already installed
    if command -v minikube &> /dev/null; then
        MINIKUBE_VERSION=$(minikube version --short)
        print_warning "Minikube is already installed: $MINIKUBE_VERSION"
        read -p "Do you want to reinstall Minikube? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Minikube installation"
            return
        fi
    fi
    
    # Download Minikube
    print_info "Downloading Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    
    # Install Minikube
    print_info "Installing Minikube..."
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    
    # Cleanup
    rm -f minikube-linux-amd64
    
    # Set Docker as default driver
    print_info "Setting Docker as default driver..."
    minikube config set driver docker
    
    print_success "Minikube installed successfully"
}

# Install Helm
install_helm() {
    print_header "Installing Helm"
    
    # Check if Helm is already installed
    if command -v helm &> /dev/null; then
        HELM_VERSION=$(helm version --short)
        print_warning "Helm is already installed: $HELM_VERSION"
        read -p "Do you want to reinstall Helm? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping Helm installation"
            return
        fi
    fi
    
    # Install Helm using official script
    print_info "Downloading and installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    print_success "Helm installed successfully"
}

# Verify all installations
verify_installations() {
    print_header "Verifying Installations"
    
    echo -e "\n${BLUE}Checking installed versions:${NC}\n"
    
    # Docker
    if command -v docker &> /dev/null; then
        print_success "Docker: $(docker --version)"
    else
        print_error "Docker: NOT INSTALLED"
    fi
    
    # kubectl
    if command -v kubectl &> /dev/null; then
        print_success "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    else
        print_error "kubectl: NOT INSTALLED"
    fi
    
    # Minikube
    if command -v minikube &> /dev/null; then
        print_success "Minikube: $(minikube version --short)"
    else
        print_error "Minikube: NOT INSTALLED"
    fi
    
    # Helm
    if command -v helm &> /dev/null; then
        print_success "Helm: $(helm version --short)"
    else
        print_error "Helm: NOT INSTALLED"
    fi
}

# Start Minikube cluster
start_minikube() {
    print_header "Starting Minikube Cluster"
    
    print_info "This will start a Minikube cluster using Docker driver..."
    print_warning "Make sure Docker is running and you have sufficient resources"
    
    read -p "Do you want to start Minikube now? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping Minikube start"
        print_info "You can start it later with: minikube start --driver=docker"
        return
    fi
    
    # Apply docker group in current shell if possible
    if ! groups | grep -q docker; then
        print_warning "Docker group not active in current shell"
        print_info "Trying to activate docker group..."
        sg docker -c "minikube start --driver=docker --cpus=2 --memory=4096"
    else
        minikube start --driver=docker --cpus=2 --memory=4096
    fi
    
    # Verify cluster is running
    if minikube status | grep -q "Running"; then
        print_success "Minikube cluster is running!"
        
        # Show cluster info
        echo -e "\n${BLUE}Cluster Information:${NC}"
        kubectl cluster-info
        
        echo -e "\n${BLUE}Nodes:${NC}"
        kubectl get nodes
    else
        print_error "Minikube cluster failed to start"
        print_info "Try running: minikube start --driver=docker"
    fi
}

# Add Helm repositories
setup_helm_repos() {
    print_header "Setting Up Helm Repositories"
    
    read -p "Do you want to add common Helm repositories? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping Helm repository setup"
        return
    fi
    
    # Add Bitnami repository
    print_info "Adding Bitnami repository..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    
    # Add Prometheus community repository
    print_info "Adding Prometheus community repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    
    # Add Grafana repository
    print_info "Adding Grafana repository..."
    helm repo add grafana https://grafana.github.io/helm-charts
    
    # Update repositories
    print_info "Updating Helm repositories..."
    helm repo update
    
    print_success "Helm repositories configured"
    
    echo -e "\n${BLUE}Configured Repositories:${NC}"
    helm repo list
}

# Verify environment by deploying a test Helm chart
verify_helm_deployment() {
    print_header "Verifying Helm Deployment"
    
    read -p "Do you want to deploy a test Nginx chart to verify everything works? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping test deployment"
        return
    fi
    
    # Check if minikube is running
    if ! minikube status 2>/dev/null | grep -q "Running"; then
        print_error "Minikube is not running. Please start it first."
        return 1
    fi
    
    # Deploy nginx using Helm
    print_info "Deploying test nginx chart..."
    helm install test-nginx bitnami/nginx --set service.type=ClusterIP --wait --timeout 300s
    
    if [ $? -eq 0 ]; then
        print_success "Test nginx chart deployed successfully!"
        
        # Show the release
        echo -e "\n${BLUE}Helm Releases:${NC}"
        helm list
        
        # Show the pods
        echo -e "\n${BLUE}Pods created:${NC}"
        kubectl get pods -l app.kubernetes.io/name=nginx
        
        # Show the service
        echo -e "\n${BLUE}Service created:${NC}"
        kubectl get svc test-nginx
        
        print_success "Helm deployment verification complete!"
        
        # Offer to clean up
        echo ""
        read -p "Do you want to remove the test deployment? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            helm uninstall test-nginx
            print_success "Test deployment removed"
        else
            print_info "Test deployment left running. Remove later with: helm uninstall test-nginx"
        fi
    else
        print_error "Failed to deploy test nginx chart"
        print_info "Check the error messages above and try manually:"
        print_info "  helm install test-nginx bitnami/nginx"
    fi
}

# Show final status of the environment
show_environment_status() {
    print_header "Environment Status"
    
    echo -e "${BLUE}═══ MINIKUBE STATUS ═══${NC}"
    minikube status 2>/dev/null || print_warning "Minikube not running"
    
    echo -e "\n${BLUE}═══ CLUSTER INFO ═══${NC}"
    kubectl cluster-info 2>/dev/null || print_warning "Cannot connect to cluster"
    
    echo -e "\n${BLUE}═══ NODES ═══${NC}"
    kubectl get nodes -o wide 2>/dev/null || print_warning "No nodes available"
    
    echo -e "\n${BLUE}═══ ALL PODS (all namespaces) ═══${NC}"
    kubectl get pods --all-namespaces 2>/dev/null || print_warning "No pods found"
    
    echo -e "\n${BLUE}═══ HELM VERSION ═══${NC}"
    helm version
    
    echo -e "\n${BLUE}═══ HELM REPOSITORIES ═══${NC}"
    helm repo list 2>/dev/null || print_info "No repositories configured yet"
    
    echo -e "\n${BLUE}═══ HELM RELEASES ═══${NC}"
    helm list --all-namespaces 2>/dev/null || print_info "No releases installed yet"
    
    print_success "Environment status check complete!"
}

# Print final instructions
print_final_instructions() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}All components have been installed successfully!${NC}\n"
    
    echo -e "${YELLOW}Important Next Steps:${NC}"
    echo "1. Log out and log back in (or run 'newgrp docker') for Docker group to take effect"
    echo "2. Start Minikube: minikube start --driver=docker"
    echo "3. Verify kubectl connection: kubectl get nodes"
    echo "4. Verify Helm: helm version"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  minikube status          - Check Minikube status"
    echo "  minikube dashboard       - Open Kubernetes dashboard"
    echo "  minikube stop            - Stop the cluster"
    echo "  minikube delete          - Delete the cluster"
    echo "  helm repo list           - List Helm repositories"
    echo "  helm search repo nginx   - Search for charts"
    echo ""
    echo -e "${BLUE}Training Resources:${NC}"
    echo "  See the training/labs/ directory for hands-on exercises"
    echo ""
    print_success "Happy Helming! 🎉"
}

# Main function
main() {
    print_header "Kubernetes with Helm - Ubuntu 24.04 Setup Script"
    
    echo "This script will install:"
    echo "  • Docker CE"
    echo "  • kubectl"
    echo "  • Minikube"
    echo "  • Helm 3"
    echo ""
    
    read -p "Do you want to proceed with the installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Run installation steps
    check_not_root
    check_ubuntu_version
    update_system
    install_prerequisites
    install_docker
    install_kubectl
    install_minikube
    install_helm
    verify_installations
    start_minikube
    setup_helm_repos
    verify_helm_deployment
    show_environment_status
    print_final_instructions
}

# Run main function
main "$@"
