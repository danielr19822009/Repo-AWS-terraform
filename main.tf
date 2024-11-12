provider "aws" {
  region = "us-east-1"  # Cambia la región según sea necesario

  access_key = "aca id"
  secret_key = "aca valor"
}

# Crear una VPC
resource "aws_vpc" "vpc_1" {
  cidr_block = "192.168.50.0/24"
}

# Crear una Gateway de Internet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc_1.id
}

# Crear una subred pública en la VPC
resource "aws_subnet" "subnet_publica" {
  vpc_id                  = aws_vpc.vpc_1.id
  cidr_block              = "192.168.50.0/25"  # Subred pública
  map_public_ip_on_launch = true  # Asigna IP pública a instancias lanzadas
  availability_zone       = "us-east-1a"  # Ajustar según la zona de disponibilidad
}

# Crear una tabla de rutas para la subred pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_1.id
}

# Crear una ruta para la Gateway de Internet
resource "aws_route" "default_internet_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Asociar la tabla de rutas con la subred pública
resource "aws_route_table_association" "subnet_publica_association" {
  subnet_id      = aws_subnet.subnet_publica.id
  route_table_id = aws_route_table.public_route_table.id
}

# Crear un grupo de seguridad
resource "aws_security_group" "securityGroup1" {
  name        = "securityGroup1"
  description = "Seguridad para SSH y HTTP"
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "mybucketubuntuaws01" {
  bucket = "mybucketubuntuaws01"   #Nombre del bucket (debe ser único globalmente)
  acl    = "private"  # Permiso para el bucket (private, public-read, etc.)

  tags = {
    Name        = "mybucketubuntuaws01"
    Environment = "pru"
  }
}


# Crear el recurso acl por separado
resource "aws_s3_bucket_acl" "mybucketubuntuaws01_acl" {
  bucket = aws_s3_bucket.mybucketubuntuaws01.bucket
  acl    = "private"  # Permiso para el bucket (private, public-read, etc.)
}


# Crear una instancia EC2 en la subred pública
resource "aws_instance" "ubuntu_v2" {
  ami                    = "ami-0866a3c8686eaeeba"  # AMI de Ubuntu (ajusta si es necesario)
  instance_type          = "t2.micro"
  key_name               = "aca acess key"  # Asegúrate de que la clave SSH esté configurada en AWS
  subnet_id              = aws_subnet.subnet_publica.id
  vpc_security_group_ids = [aws_security_group.securityGroup1.id]
  associate_public_ip_address = true  # Asignar IP pública
  tags = {
    Name = "Ubuntu_v2"
  }

  # Configuración de user_data para instalar paquetes y configurar la instancia
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update && sudo apt upgrade -y
              sudo apt install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              sudo apt install -y awscli

              aws s3 sync s3://mybucketubuntuaws01/ /var/www/
              sudo chmod -R 755 /var/www/
              EOF
}
