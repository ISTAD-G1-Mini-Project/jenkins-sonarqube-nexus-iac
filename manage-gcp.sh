#!/bin/bash

# GCP Infrastructure Management Script
# Simplified commands for common operations

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

function print_header() {
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
}

function print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

function print_error() {
    echo -e "${RED}✗ $1${NC}"
}

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

function check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Ansible
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible is not installed"
        echo "Install with: sudo apt install ansible  (or)  brew install ansible"
        exit 1
    fi
    print_success "Ansible: $(ansible --version | head -1)"
    
    # Check gcp_vars.yml
    if [ ! -f "gcp_vars.yml" ]; then
        print_error "gcp_vars.yml not found"
        echo "Copy gcp_vars.yml.example to gcp_vars.yml and edit it"
        exit 1
    fi
    print_success "Configuration file: Found"
    
    # Check service account file
    SA_FILE=$(grep "gcp_service_account_file:" gcp_vars.yml | awk '{print $2}' | tr -d '"')
    if [ ! -f "$SA_FILE" ]; then
        print_error "Service account key file not found: $SA_FILE"
        exit 1
    fi
    print_success "Service account key: Found"
    
    # Check SSH key
    SSH_KEY=$(grep "ssh_public_key_file:" gcp_vars.yml | awk '{print $2}' | tr -d '"' | sed "s|~|$HOME|")
    if [ ! -f "$SSH_KEY" ]; then
        print_error "SSH public key not found: $SSH_KEY"
        echo "Generate with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa"
        exit 1
    fi
    print_success "SSH public key: Found"
    
    # Check Ansible collections
    if ! ansible-galaxy collection list | grep -q "google.cloud"; then
        print_warning "GCP collection not found. Installing..."
        ansible-galaxy collection install -r requirements.yml
    fi
    print_success "Ansible collections: OK"
    
    echo ""
}

function create_infrastructure() {
    print_header "Creating GCP Infrastructure"
    print_warning "This will create 3 VMs and install all services"
    print_warning "Estimated time: 15-20 minutes"
    print_warning "Estimated cost: ~$136/month"
    echo ""
    read -p "Continue? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Cancelled"
        exit 0
    fi
    
    ansible-playbook create-and-setup-infrastructure.yml
    
    print_success "Infrastructure created!"
    echo ""
    echo "Next steps:"
    echo "1. Check vm-info.txt for IP addresses"
    echo "2. Configure DNS records (see vm-info.txt)"
    echo "3. Wait for DNS propagation (5-60 minutes)"
    echo "4. Run: ./manage-gcp.sh ssl"
    echo ""
}

function setup_ssl() {
    print_header "Setting Up SSL Certificates"
    
    if [ ! -f "inventory.ini" ]; then
        print_error "inventory.ini not found. Create infrastructure first."
        exit 1
    fi
    
    print_warning "Ensure DNS is configured and propagated before proceeding"
    echo ""
    read -p "DNS configured and propagated? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Configure DNS first, then run this again"
        exit 0
    fi
    
    ansible-playbook setup-ssl.yml
    print_success "SSL certificates installed!"
    echo ""
}

function verify_infrastructure() {
    print_header "Verifying Infrastructure"
    
    if [ ! -f "inventory.ini" ]; then
        print_error "inventory.ini not found. Create infrastructure first."
        exit 1
    fi
    
    ansible-playbook verify-infrastructure.yml
    echo ""
}

function show_info() {
    print_header "Infrastructure Information"
    
    if [ ! -f "vm-info.txt" ]; then
        print_error "vm-info.txt not found. Create infrastructure first."
        exit 1
    fi
    
    cat vm-info.txt
    echo ""
}

function get_passwords() {
    print_header "Service Credentials"
    
    if [ ! -f "inventory.ini" ]; then
        print_error "inventory.ini not found. Create infrastructure first."
        exit 1
    fi
    
    JENKINS_IP=$(grep "ansible_host=" inventory.ini | grep jenkins | cut -d= -f3)
    NEXUS_IP=$(grep "ansible_host=" inventory.ini | grep nexus | cut -d= -f3)
    SSH_USER=$(grep "ansible_user=" inventory.ini | head -1 | cut -d= -f2)
    
    echo "Jenkins:"
    echo "  Username: admin"
    echo -n "  Password: "
    ssh -o StrictHostKeyChecking=no ${SSH_USER}@${JENKINS_IP} "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null" || echo "Not available yet"
    echo ""
    
    echo "SonarQube:"
    echo "  Username: admin"
    echo "  Password: admin (change on first login)"
    echo ""
    
    echo "Nexus:"
    echo "  Username: admin"
    echo -n "  Password: "
    ssh -o StrictHostKeyChecking=no ${SSH_USER}@${NEXUS_IP} "docker exec nexus-docker cat /nexus-data/admin.password 2>/dev/null" || echo "Not available yet"
    echo ""
}

function show_status() {
    print_header "Service Status"
    
    if [ ! -f "inventory.ini" ]; then
        print_error "inventory.ini not found. Create infrastructure first."
        exit 1
    fi
    
    echo "Checking services..."
    ansible all -i inventory.ini -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}'" -b 2>/dev/null || print_error "Cannot connect to VMs"
    echo ""
}

function destroy_infrastructure() {
    print_header "Destroy Infrastructure"
    print_error "⚠⚠⚠ WARNING ⚠⚠⚠"
    print_error "This will PERMANENTLY DELETE all VMs and data!"
    print_error "This action CANNOT be undone!"
    echo ""
    read -p "Type 'DESTROY' to confirm: " confirm
    
    if [ "$confirm" != "DESTROY" ]; then
        print_warning "Destruction cancelled"
        exit 0
    fi
    
    ansible-playbook destroy-gcp-infrastructure.yml
    print_success "Infrastructure destroyed"
    echo ""
}

function show_costs() {
    print_header "Cost Estimation"
    
    cat << EOF
Monthly costs (us-central1):

Current configuration (e2-standard-2):
  3x e2-standard-2 VMs (2 vCPU, 8GB RAM): ~\$147
  3x 50GB standard disks:                 ~\$6
  3x External IP addresses:               ~\$10
  ──────────────────────────────────────────
  Total:                                  ~\$163/month

To reduce costs:
  • Use e2-medium (1 vCPU, 4GB): ~\$88/month total
  • Use preemptible VMs: up to 80% discount
  • Stop VMs when not in use
  • Use smaller disks (minimum 20GB)

Check current costs:
  gcloud billing accounts list
  https://console.cloud.google.com/billing

EOF
}

function show_menu() {
    clear
    print_header "GCP Infrastructure Management"
    echo "1)  Check Prerequisites"
    echo "2)  Create Full Infrastructure (VMs + Services)"
    echo "3)  Setup SSL Certificates"
    echo "4)  Verify Infrastructure"
    echo "5)  Show Infrastructure Info"
    echo "6)  Get Service Passwords"
    echo "7)  Show Service Status"
    echo "8)  Show Cost Estimation"
    echo "9)  Destroy Infrastructure"
    echo "0)  Exit"
    echo ""
}

# Main script
if [ $# -eq 0 ]; then
    # Interactive mode
    while true; do
        show_menu
        read -p "Select option (0-9): " option
        echo ""
        
        case $option in
            1) check_prerequisites ;;
            2) create_infrastructure ;;
            3) setup_ssl ;;
            4) verify_infrastructure ;;
            5) show_info ;;
            6) get_passwords ;;
            7) show_status ;;
            8) show_costs ;;
            9) destroy_infrastructure ;;
            0) 
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
        
        read -p "Press Enter to continue..."
    done
else
    # Command line mode
    case $1 in
        check) check_prerequisites ;;
        create) create_infrastructure ;;
        ssl) setup_ssl ;;
        verify) verify_infrastructure ;;
        info) show_info ;;
        passwords|creds) get_passwords ;;
        status) show_status ;;
        costs) show_costs ;;
        destroy) destroy_infrastructure ;;
        *)
            echo "Usage: $0 [check|create|ssl|verify|info|passwords|status|costs|destroy]"
            echo "Or run without arguments for interactive menu"
            exit 1
            ;;
    esac
fi
