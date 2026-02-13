# Quick Reference Guide

## Essential Commands

### Testing
```bash
# Test connectivity
ansible all -m ping

# Check facts
ansible all -m setup | less

# Test specific host
ansible machine01 -m ping
```

### Deployment
```bash
# Full deployment
ansible-playbook setup-infrastructure.yml

# Deploy specific machine
ansible-playbook setup-infrastructure.yml --limit machine01

# Deploy specific role
ansible-playbook setup-infrastructure.yml --tags jenkins

# Dry run
ansible-playbook setup-infrastructure.yml --check

# Verbose mode
ansible-playbook setup-infrastructure.yml -vvv
```

### SSL Setup
```bash
# Setup SSL for all services
ansible-playbook setup-ssl.yml

# Setup SSL for specific machine
ansible-playbook setup-ssl.yml --limit machine01
```

### Destruction
```bash
# Destroy all infrastructure
ansible-playbook destroy-infrastructure.yml

# Destroy specific machine
ansible-playbook destroy-infrastructure.yml --limit machine01
```

### Ad-hoc Commands
```bash
# Check Docker status
ansible all -m shell -a "docker ps" -b

# Restart Nginx
ansible all -m systemd -a "name=nginx state=restarted" -b

# Check disk space
ansible all -m shell -a "df -h"

# Update packages
ansible all -m apt -a "update_cache=yes upgrade=dist" -b

# Reboot machines
ansible all -m reboot -b
```

## Service-Specific Commands

### Jenkins
```bash
# Get initial password
ssh machine01 "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"

# Restart Jenkins
ssh machine01 "docker restart jenkins"

# View logs
ssh machine01 "docker logs -f jenkins"

# Backup Jenkins
ssh machine01 "docker run --rm -v jenkins_home:/data -v /tmp:/backup ubuntu tar czf /backup/jenkins-backup.tar.gz /data"
```

### SonarQube
```bash
# Restart SonarQube
ssh machine02 "docker restart sonarqube"

# View logs
ssh machine02 "docker logs -f sonarqube"

# Database backup
ssh machine02 "docker exec sonarqube-db pg_dump -U sonar sonarqube > /tmp/sonarqube-backup.sql"
```

### Nexus
```bash
# Get initial password
ssh machine03 "docker exec nexus-docker cat /nexus-data/admin.password"

# Restart Nexus
ssh machine03 "docker restart nexus-docker"

# View logs
ssh machine03 "docker logs -f nexus-docker"

# Backup Nexus
ssh machine03 "docker run --rm -v nexus_data:/data -v /tmp:/backup ubuntu tar czf /backup/nexus-backup.tar.gz /data"
```

## Troubleshooting

### Check Service Status
```bash
# All services
ansible all -m shell -a "docker ps -a"

# Specific service
ssh machine01 "docker ps -a | grep jenkins"
```

### View System Resources
```bash
# Memory usage
ansible all -m shell -a "free -h"

# CPU usage
ansible all -m shell -a "top -bn1 | head -20"

# Disk usage
ansible all -m shell -a "df -h"
```

### Network Diagnostics
```bash
# Check open ports
ansible all -m shell -a "netstat -tulpn | grep LISTEN" -b

# Test connectivity to service
curl -I https://jenkins.yourdomain.com

# Check DNS resolution
nslookup jenkins.yourdomain.com
```

### SSL Certificate Issues
```bash
# Check certificate
ssh machine01 "sudo certbot certificates"

# Test SSL
openssl s_client -connect jenkins.yourdomain.com:443

# Force renewal
ssh machine01 "sudo certbot renew --force-renewal"
```

### Docker Issues
```bash
# Check Docker daemon
ansible all -m systemd -a "name=docker" -b

# Docker system info
ansible all -m shell -a "docker info"

# Clean up Docker
ansible all -m shell -a "docker system prune -af"
```

## Inventory Variables

Key variables in `inventory.ini`:
- `ansible_user`: SSH user
- `ansible_ssh_private_key_file`: Path to SSH key
- `jenkins_domain`: Jenkins domain name
- `sonarqube_domain`: SonarQube domain name
- `nexus_domain`: Nexus domain name
- `admin_email`: Email for Let's Encrypt

## Default Credentials

### Jenkins
- Username: `admin`
- Password: From `/var/jenkins_home/secrets/initialAdminPassword`

### SonarQube
- Username: `admin`
- Password: `admin` (change on first login)

### Nexus
- Username: `admin`
- Password: From `/nexus-data/admin.password`

### Portainer (all machines)
- Port: `9000`
- Setup on first access

## Useful Docker Commands

```bash
# List all containers
docker ps -a

# View container logs
docker logs <container_name>

# Execute command in container
docker exec -it <container_name> /bin/bash

# Container stats
docker stats

# Remove stopped containers
docker container prune

# Remove unused volumes
docker volume prune

# Full cleanup
docker system prune -a --volumes
```

## Best Practices

1. **Always test in non-production first**
2. **Backup before making changes**
3. **Use version control for playbooks**
4. **Document any custom configurations**
5. **Regularly update Docker images**
6. **Monitor resource usage**
7. **Keep SSH keys secure**
8. **Use strong passwords**
9. **Review logs regularly**
10. **Test disaster recovery procedures**
