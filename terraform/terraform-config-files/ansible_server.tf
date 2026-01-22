resource "aws_iam_role" "ansible_ec2_role" {
  name = "ansible-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "secretsmanager_full_access" {
  name        = "SecretsManagerFullAccessPolicy"
  description = "Allows full access to Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "secretsmanager:*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secretsmanager_policy" {
  role       = aws_iam_role.ansible_ec2_role.name
  policy_arn = aws_iam_policy.secretsmanager_full_access.arn
}

resource "aws_iam_instance_profile" "ansible_instance_profile" {
  name = "ansible-instance-profile"
  role = aws_iam_role.ansible_ec2_role.name
}


resource "aws_instance" "ansible_server" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  key_name                    = var.instance_key_name
  vpc_security_group_ids      = [aws_security_group.ansible_sg.id]
  subnet_id                   = var.instance_subnet_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ansible_instance_profile.name

  tags = {
    Name = "ansible_server"
  }

  user_data = <<-EOF
  #!/bin/bash
  exec > >(tee -a /var/log/ansible_user_data.log) 2>&1

  ####################################
  # Hostname
  ####################################
  hostnamectl set-hostname ansible_server

  ####################################
  # System Update
  ####################################
  yum update -y

  ####################################
  # Python 3.11 Installation
  ####################################
  yum install -y python3.11
  python3.11 --version

  ####################################
  # Pip Installation
  ####################################
  yum install -y python3.11-pip
  pip3.11 --version

  ####################################
  # AWS CLI Installation
  ####################################
  yum install -y awscli
  aws --version

  ####################################
  # Ansible Installation
  ####################################
  pip3.11 install ansible
  ansible --version

  ####################################
  # AWS Dependencies for Ansible
  ####################################
  pip3.11 install boto3 botocore
  yum install -y jq

  ####################################
  # Ansible Directory
  ####################################
  mkdir -p /etc/ansible

  ####################################
  # Retrieve Private Key from Secrets Manager
  ####################################
  aws secretsmanager get-secret-value \
    --secret-id project-key \
    --query 'SecretString' \
    --output text \
    --region us-east-1 | jq -r '.private_key' > /etc/ansible/project-key

  chmod 400 /etc/ansible/project-key

  ####################################
  # Ansible Configuration
  ####################################
  cat <<EOC > /etc/ansible/ansible.cfg
  [defaults]
  inventory = /etc/ansible/hosts
  remote_user = ec2-user
  private_key_file = /etc/ansible/project-key
  log_path = /etc/ansible/ansible.log
  host_key_checking = False
  EOC

  ####################################
  # Ansible Inventory (Static IPs)
  ####################################
  cat <<EOH > /etc/ansible/hosts
  [jenkins]
  3.94.55.249 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key   ## Jenkins_server

  [nexus]
  34.201.145.176 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key ## Nexus_server

  [grafana]
  54.224.86.120 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key  ## Grafana_server

  [sonarqube]
  3.91.154.79 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key    ## Sonarqube_server

  [monolithic_server]
  54.91.177.119 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key  ## Monolithic_server

  [prometheus]
  3.94.192.239 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key   ## Prometheus_server

  [servers]
  54.91.177.119 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key  ## Monolithic_server
  34.201.145.176 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key ## Nexus_server
  3.91.154.79 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key    ## Sonarqube_server
  3.94.192.239 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key   ## Prometheus_server
  54.224.86.120 ansible_ssh_user=ec2-user ansible_private_key_file=/etc/ansible/project-key  ## Grafana_server
  EOH

  ####################################
  # Test Ansible
  ####################################
  ansible localhost -m ping

EOF


}
