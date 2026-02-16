# GCP Infrastructure Automation with Ansible

Complete automation to **create GCP VMs** and deploy Jenkins, SonarQube, and Nexus with HTTPS.

## 🚀 What This Does

This Ansible project will:

1. ✅ **Create 3 GCP VM instances** automatically
2. ✅ **Configure networking** (VPC, subnets, firewall rules)
3. ✅ **Install all software** (Docker, Jenkins, SonarQube, Nexus)
4. ✅ **Setup HTTPS** with Let's Encrypt SSL certificates
5. ✅ **Deploy services** in Docker containers
6. ✅ **Configure reverse proxies** with Nginx
7. ✅ **Clean destruction** of all resources when done

**Everything from zero to fully working infrastructure in one command!**

## 📋 Prerequisites

### 1. On Your Local Machine

```bash
# Install Ansible
sudo apt install ansible  # Ubuntu/Debian
brew install ansible      # macOS

# Install Python modules
pip3 install requests google-auth

```

### 2. GCP Setup

#### A. Create/Get Service Account Key

```bash
# Option 1: Use existing service account
# Download the JSON key file from GCP Console:
# IAM & Admin → Service Accounts → Your Service Account → Keys → Add Key

# Option 2: Create new service account via gcloud
gcloud iam service-accounts create ansible-automation \
    --display-name="Ansible Automation"

# Grant necessary permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:ansible-automation@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:ansible-automation@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create ~/gcp-key.json \
    --iam-account=ansible-automation@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### B. Required GCP APIs

Enable these APIs in your GCP project:
- Compute Engine API
- Cloud Resource Manager API

```bash
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### 3. SSH Keys

```bash
# Generate SSH key pair if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### 4. Domain Names

You need 3 domain names (or subdomains):
- `jenkins.yourdomain.com`
- `sonarqube.yourdomain.com`
- `nexus.yourdomain.com`

### 5. Cloudflare Setup (Automatic DNS Records)

To automatically create DNS records for your services, configure **Cloudflare**:

#### 1. Add Your Domain
- Log in to Cloudflare.
- Click **Add a Site** and enter your domain.
- Choose a plan (Free plan is enough).
- Update your domain nameservers to the ones provided by Cloudflare.

#### 2. Create API Token
- Go to **Profile → API Tokens → Create Token**.
- Use **Edit zone DNS** template.
- Set permissions:
  - Zone → DNS → Edit
  - Zone → Zone → Read
- Select your specific domain (zone).
- Create the token and save it securely.

#### 3. Install Required Tools

```bash
pip install cloudflare
# or for Ansible
ansible-galaxy collection install community.general
```
#### 4. Set Environment Variable

```bash
CLOUDFLARE_API_TOKEN=your_api_token  # using ansible-vault to store " ansible-vault create secrets.yml "
CLOUDFLARE_ZONE=yourdomain.com
```

### 6. Local Python Environment

We recommend using a **Python virtual environment** to isolate dependencies.

```bash
# 1. Create a virtual environment
python3 -m venv .venv

# 2. Activate it
# macOS / Linux
source .venv/bin/activate

# Upgrade pip inside venv
pip install --upgrade pip

# 3. Install required Python packages
pip install -r requirements.txt
```

## ⚙️ Configuration

### 1. Edit `gcp_vars.yml`

```yaml
# GCP Project Configuration
gcp_project_id: "my-gcp-project-123"
gcp_service_account_file: "/path/to/your-service-account-key.json"
gcp_region: "us-central1"
gcp_zone: "us-central1-a"

# VM Configuration  
machine_type: "e2-standard-2"  # 2 vCPUs, 8GB RAM
boot_disk_size: 50  # GB

# Domain Configuration
jenkins_domain: "jenkins.yourdomain.com"
sonarqube_domain: "sonarqube.yourdomain.com"
nexus_domain: "nexus.yourdomain.com"
admin_email: "admin@yourdomain.com"

# SSH Configuration
ssh_user: "ansible"
ssh_public_key_file: "~/.ssh/id_rsa.pub"
```

### 2. Verify Configuration

```bash
# Test GCP authentication
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your-key.json"
gcloud auth activate-service-account --key-file=/path/to/your-key.json
gcloud compute zones list --project=YOUR_PROJECT_ID
```

## 🎯 Deployment

### One-Command Full Deployment

```bash
# This creates VMs + installs everything + add domain names
ansible-playbook -i localhost playbooks/deploy-all.yml \
    --vault-password-file ./secrets/vault_pass.txt
```

This single command will:
1. Create VPC network and subnets
2. Create firewall rules
3. Create 3 GCP VM instances
4. Wait for VMs to be ready
5. Install Docker on all machines
6. Deploy Jenkins (Machine01)
7. Deploy SonarQube (Machine02)
8. Deploy Nexus (Machine03)
9. Configure Nginx reverse proxies
10. Install Certbot for SSL

**Duration**: 15-20 minutes

### Step-by-Step Deployment (Optional)

```bash
# Step 1: Create VMs only
ansible-playbook playbooks/tasks/create-gcp-infrastructure.yml

# Step 2: Configure services
ansible-playbook playbooks/tasks/setup-infrastructure.yml

# Step 3: Setup domain/DNS
ansible-playbook playbooks/tasks/setup-domain.yml \
--vault-password-file ./secrets/vault_pass.txt

# Step 4: Setup SSL (after DNS propagation)
ansible-playbook playbooks/tasks/setup-ssl.yml
```

## 🌐 DNS Configuration

After VMs are created, you'll see output like:

```
DNS Records to Create:
jenkins.yourdomain.com A 34.123.45.67
sonarqube.yourdomain.com A 34.123.45.68
nexus.yourdomain.com A 34.123.45.69
```

**Add these DNS records in your domain provider's control panel.**

### DNS Propagation

Wait 5-60 minutes for DNS to propagate. Check with:

```bash
nslookup jenkins.yourdomain.com
dig jenkins.yourdomain.com
```

## 🔒 SSL Setup

After DNS propagates:

```bash
ansible-playbook playbooks/tasks/setup-ssl.yml
```

This obtains Let's Encrypt certificates for all domains.

## 🌍 Access Your Services

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Jenkins | https://jenkins.yourdomain.com | admin / [initial password] |
| SonarQube | https://sonarqube.yourdomain.com | admin / admin |
| Nexus | https://nexus.yourdomain.com | admin / [initial password] |

### Get Initial Passwords

The playbook saves all information to `vm-info.txt`. Or retrieve manually:

```bash
# Jenkins password
ssh ansible@JENKINS_IP "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"

# Nexus password
ssh ansible@NEXUS_IP "docker exec nexus-docker cat /nexus-data/admin.password"
```

## 🔧 Management

### Check Status

```bash
ansible-playbook playbooks/tasks/verify-infrastructure.yml
```

### View Logs

```bash
# SSH to machine
ssh ansible@MACHINE_IP

# View container logs
docker logs jenkins
docker logs sonarqube
docker logs nexus-docker
```

## 🗑️ Destroy Infrastructure

**⚠️ WARNING: This permanently deletes everything!**

```bash
ansible-playbook playbooks/tasks/destroy-gcp-infrastructure.yml
```

This will:
1. Stop all Docker containers
2. Delete all 3 VM instances
3. Delete firewall rules
4. Delete VPC network and subnets
5. Remove all GCP resources

Type `DESTROY` when prompted to confirm.

## 📁 Project Structure

```
ansible-gcp-infrastructure/       
├── ansible.cfg                        # Ansible configuration
├── requirements.yml                   # Required collections
├── README.md                          # This file
├── vars/
│   └── gcp_vars.yml                             # GCP configuration
├── playbooks/
│   ├── deploy-all.yml                           # Main playbook ( creates VMs + setup + Add domain names)
│   ├── Justfile
│   └── tasks/                          
│       ├── create-and-setup-infrastructure.yml      # creates VMs + setup
│       ├── destroy-gcp-infrastructure.yml           # Destroy all resources
│       ├── setup-domain.yml                         # set up domain name
│       ├── setup-infrastructure.yml                 # Configure existing VMs
│       ├── setup-ssl.yml                            # SSL certificate setup
│       └── verify-infrastructure.yml                # Health checks
├── templates/
│    └── inventory.j2                  # Inventory Template with Jinja2
└── roles/
    ├── common/                        # Base configuration
    ├── docker/                        # Docker installation
    ├── jenkins/                       # Jenkins setup
    ├── sonarqube/                     # SonarQube setup
    └── nexus/                         # Nexus setup
```

## 🔍 Troubleshooting

### VM Creation Fails

```bash
# Check quotas
gcloud compute project-info describe --project=YOUR_PROJECT_ID

# Verify APIs are enabled
gcloud services list --enabled
```

### SSH Connection Issues

```bash
# Test SSH key
ssh-add ~/.ssh/id_rsa
ssh ansible@VM_IP

# Check firewall rules
gcloud compute firewall-rules list
```

### Service Not Starting

```bash
# Check Docker
ssh ansible@VM_IP
docker ps -a
docker logs <container_name>

# Check system resources
free -h
df -h
```

### SSL Certificate Issues

```bash
# Check DNS resolution
nslookup jenkins.yourdomain.com

# Manual certificate request
ssh ansible@JENKINS_IP
sudo certbot certificates
sudo certbot renew --dry-run
```

## 🎓 What Gets Installed

### Machine01 (Jenkins)
- Jenkins (Docker)
- Docker & Docker Compose
- Portainer
- Ansible
- glab (GitLab CLI)
- OhMyZsh
- Nginx
- Certbot

### Machine02 (SonarQube)
- SonarQube (Docker)
- PostgreSQL (Docker)
- Portainer
- OhMyZsh  
- Nginx
- Certbot

### Machine03 (Nexus)
- Nexus Repository Manager (Docker)
- Docker & Docker Compose
- Portainer
- OhMyZsh
- Nginx
- Certbot
- Docker Blob Store
- Helm Blob Store
