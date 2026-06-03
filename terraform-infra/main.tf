terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. The Isolated VPC Network
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "defense-project-vpc"
  }
}

# 2. Public Subnet (Tier 1: Gateway/Load Balancer Zone)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "public-subnet-1a"
    "kubernetes.io/role/elb" = "1" # Prepares this subnet for future EKS ingress
  }
}

# 3. Private Subnet (Tier 2: Secure Application/EKS Workload Zone)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "private-subnet-1a"
    "kubernetes.io/role/internal-elb" = "1" # Prepares this subnet for internal routing
  }
}

# 4. Internet Gateway (The Traffic Bridge)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-vpc-igw"
  }
}

# 5. Public Routing Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# 6. Link Public Subnet to the Routing Rules
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# TIER 3: KUBERNETES WORKLOAD MANAGEMENT (EKS)
# ==========================================

# 1. IAM Role to give EKS Cluster Control Plane permission to manage AWS resources
resource "aws_iam_role" "eks_cluster_role" {
  name = "defense-project-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

# Attach core Amazon EKS policy to the cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 2. The Managed EKS Kubernetes Cluster Control Plane
resource "aws_eks_cluster" "defense_cluster" {
  name     = "defense-kubernetes-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Controls which networking layers your master nodes tie into
    subnet_ids = [
      aws_subnet.public_1.id,
      aws_subnet.private_1.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# ==========================================
# COMPUTE LAYER: KUBERNETES WORKER NODES
# ==========================================

# 1. IAM Role for Worker Nodes to communicate with EKS and pull images from AWS ECR
resource "aws_iam_role" "eks_node_role" {
  name = "defense-project-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach mandatory policies for EKS worker functionality
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# 2. Managed Node Group (The actual servers running your application pods)
resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.defense_cluster.name
  node_group_name = "defense-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  # Keeps your application servers tucked safely inside the private security tier
  subnet_ids = [aws_subnet.private_1.id]

  instance_types = ["t3.medium"] # Recommended minimum size for EKS system pods

  scaling_config {
    desired_size = 2 # Runs 2 replica nodes for high availability
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}