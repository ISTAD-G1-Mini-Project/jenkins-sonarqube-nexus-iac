ping-all: 
    echo "Ping all instances inside inventory.ini " 
    ansible -i playbooks/inventory.ini \
        all -m ping 
        
setup-all:
    ansible-playbook -i inventory.ini playbooks/deploy-all.yml \
    --vault-password-file ./secrets/vault_pass.txt

create-machine:
    ansible-playbook -i localhost playbooks/tasks/create-gcp-infrastructure.yml
    
destroy-machine:
    ansible-playbook -i localhost playbooks/tasks/destroy-gcp-infrastructure.yml

setup-infra:
    ansible-playbook -i localhost playbooks/tasks/setup-infrastructure.yml

verify-infra:
    ansible-playbook -i inventory.ini playbooks/tasks/verify-infrastructure.yml

setup-domain:
    ansible-playbook -i localhost playbooks/tasks/setup-domain.yml \
    --vault-password-file ./secrets/vault_pass.txt

setup-ssl:
    ansible-playbook -i localhost playbooks/tasks/setup-ssl.yml

