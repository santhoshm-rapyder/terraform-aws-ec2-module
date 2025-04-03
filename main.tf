resource "aws_instance" "sonarqube" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "SonarQubeServer"
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update the system and install Docker
              yum update -y
              yum install -y docker

              # Start and enable Docker service
              systemctl start docker
              systemctl enable docker

              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Create the SonarQube Docker Compose directory
              mkdir -p /home/ec2-user/sonarqube
              cd /home/ec2-user/sonarqube

              # Create a docker-compose.yml file
              cat <<EOL > docker-compose.yml
              version: '3.8'
              services:
                postgres:
                  image: postgres:14
                  container_name: sonarqube_postgres
                  environment:
                    POSTGRES_USER: sonar
                    POSTGRES_PASSWORD: sonar
                    POSTGRES_DB: sonarqube
                  volumes:
                    - postgres_data:/var/lib/postgresql/data
                  networks:
                    - sonarnet

                sonarqube:
                  image: sonarqube:community
                  container_name: sonarqube
                  environment:
                    SONAR_JDBC_URL: jdbc:postgresql://postgres:5432/sonarqube
                    SONAR_JDBC_USERNAME: sonar
                    SONAR_JDBC_PASSWORD: sonar
                  ports:
                    - "9000:9000"
                  networks:
                    - sonarnet
                  depends_on:
                    - postgres

              networks:
                sonarnet:
                  driver: bridge

              volumes:
                postgres_data:
              EOL

              # Run docker-compose
              sudo /usr/local/bin/docker-compose up -d
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

output "instance_id" {
  value = aws_instance.sonarqube.id
}

output "public_ip" {
  value = aws_instance.sonarqube.public_ip
}
