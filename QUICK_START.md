# Quick Start Guide - GCP Infrastructure

## ⚡ 5-Minute Setup

### 1. Prerequisites Check

```bash
# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Verify you have:
# ✓ GCP service account JSON key
# ✓ SSH keys (~/.ssh/id_rsa)
# ✓ 5 domain names ready
```

### 2. Configure

Edit `gcp_vars.yml`:

```yaml
gcp_project_id: "your-project-id"
gcp_service_account_file: "/path/to/key.json"
gcp_zone: "us-central1-a"

jenkins_domain: "jenkins.yourdomain.com"
sonarqube_domain: "sonarqube.yourdomain.com"
nexus_domain: "nexus.yourdomain.com"
admin_email: "admin@yourdomain.com"

ssh_public_key_file: "~/.ssh/id_rsa.pub"
```

### 3. Deploy Everything

```bash
ansible-playbook create-and-setup-infrastructure.yml
```

**Wait 15-20 minutes** ☕

### 4. Configure DNS

After deployment, check `vm-info.txt` for IP addresses, then add DNS A records:

```
jenkins.yourdomain.com        -> JENKINS_IP
sonarqube.yourdomain.com      -> SONARQUBE_IP
nexus.yourdomain.com          -> NEXUS_IP
```

### 5. Setup SSL

After DNS propagates (5-60 minutes):

```bash
ansible-playbook setup-ssl.yml
```

### 6. Access Services

```
✅ Jenkins:    https://jenkins.yourdomain.com
✅ SonarQube:  https://sonarqube.yourdomain.com
✅ Nexus:      https://nexus.yourdomain.com
```

Get passwords from `vm-info.txt` or:

```bash
ssh ansible@JENKINS_IP "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
ssh ansible@NEXUS_IP "docker exec nexus-docker cat /nexus-data/admin.password"
```

## 🗑️ Destroy Everything

```bash
ansible-playbook destroy-gcp-infrastructure.yml
```

Type `DESTROY` to confirm.

## 📊 What You Get

- ✅ 3 GCP VMs (2 vCPU, 8GB RAM each)
- ✅ Jenkins CI/CD server
- ✅ SonarQube code quality
- ✅ Nexus repository (Docker + Helm)
- ✅ All services with HTTPS
- ✅ Portainer on all machines
- ✅ Automated backups possible

## 💡 Common Commands

```bash
# Check status
ansible-playbook verify-infrastructure.yml

# View logs
ssh ansible@VM_IP
docker logs jenkins

# Restart service
ansible machine01 -i inventory.ini -m shell -a "docker restart jenkins" -b

# Get VM info
cat vm-info.txt
```

## ⚠️ Troubleshooting

### VMs not creating?
- Check GCP quotas: `gcloud compute project-info describe --project=PROJECT_ID`
- Verify APIs enabled: `gcloud services list --enabled`

### Can't SSH?
- Check `~/.ssh/id_rsa.pub` exists
- Verify firewall: `gcloud compute firewall-rules list`

### SSL fails?
- Ensure DNS propagated: `nslookup jenkins.yourdomain.com`
- Wait longer (up to 60 min for DNS)

### Service won't start?
```bash
ssh ansible@VM_IP
docker ps -a
docker logs <container>
```

## 💰 Monthly Cost

~$136/month for 3x e2-standard-2 VMs in us-central1

Reduce costs:
- Use `e2-medium` (1 vCPU, 4GB): ~$70/month
- Stop VMs when not in use
- Use preemptible VMs (80% cheaper)

## 📚 Full Documentation

See `README.md` for complete documentation.

---

**Need help?** Check the troubleshooting section in README.md
