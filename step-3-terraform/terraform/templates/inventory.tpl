[azure]
${vm_public_ip}

[azure:vars]
ansible_user=${ansible_user}
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
# ansible_ssh_private_key_file=~/.ssh/id_itlab
