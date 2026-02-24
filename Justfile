ping-all: 
    echo "Ping all instances inside inventory.ini " 
    ansible -i inventory.ini \
        all -m ping 
        
setup-all:
    ansible-playbook -i inventory.ini playbooks/deploy-all.yml \
    --vault-password-file ./secrets/vault_pass.txt

create-machines:
    ansible-playbook -i localhost playbooks/tasks/create-gcp-infrastructure.yml
    
destroy-machines:
    ansible-playbook -i inventory.ini playbooks/tasks/destroy-gcp-infrastructure.yml

setup-infra:
    ansible-playbook -i inventory.ini playbooks/tasks/setup-infrastructure.yml

verify-tools:
    ansible-playbook -i inventory.ini playbooks/tasks/verify-tools.yml

setup-domain:
    ansible-playbook -i localhost playbooks/tasks/setup-domain.yml \
    --vault-password-file ./secrets/vault_pass.txt

setup-ssl:
    ansible-playbook -i localhost playbooks/tasks/setup-ssl.yml

