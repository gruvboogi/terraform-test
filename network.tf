# VCN 생성
resource "oci_core_vcn" "test_vcn" {
  compartment_id = oci_identity_compartment.terraform_test.id
  cidr_block     = "192.0.0.0/16"
  display_name   = "terraform-test-vcn"
  dns_label      = "testvcn"
}

# Internet Gateway (Public Subnet용)
resource "oci_core_internet_gateway" "test_igw" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "test-igw"
  enabled        = true
}

# Route Table for Public Subnet (Internet Gateway 연결)
resource "oci_core_route_table" "public_rt" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.test_igw.id
  }
}

# OKE API Endpoint Security List (Public Subnet)
resource "oci_core_security_list" "oke_api_endpoint_sl" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "oke-api-endpoint-security-list"

  # Ingress: External access to Kubernetes API endpoint (6443)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "External access to Kubernetes API endpoint"
  }

  # Ingress: Worker Nodes to Kubernetes API endpoint communication (6443)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "192.0.10.0/24" # Private Subnet CIDR
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Kubernetes worker to Kubernetes API endpoint communication"
  }

  # Ingress: Worker Nodes to Control Plane communication (12250)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "192.0.10.0/24" # Private Subnet CIDR
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 12250
      max = 12250
    }
    description = "Kubernetes worker to control plane communication"
  }

  # Ingress: Path Discovery (ICMP)
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "192.0.10.0/24" # Private Subnet CIDR
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
    description = "Path discovery"
  }

  # Egress: Allow Kubernetes Control Plane to communicate with OKE (OSN)
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = false
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow Kubernetes Control Plane to communicate with OKE"
  }

  # Egress: All traffic to worker nodes
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = "192.0.10.0/24" # Private Subnet CIDR
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "All traffic to worker nodes"
  }

  # Egress: Path Discovery (ICMP)
  egress_security_rules {
    protocol         = "1" # ICMP
    destination      = "192.0.10.0/24" # Private Subnet CIDR
    destination_type = "CIDR_BLOCK"
    stateless        = false
    icmp_options {
      type = 3
      code = 4
    }
    description = "Path discovery"
  }
}

# Public Subnet (192.0.1.0/24)
resource "oci_core_subnet" "public_subnet" {
  compartment_id    = oci_identity_compartment.terraform_test.id
  vcn_id            = oci_core_vcn.test_vcn.id
  cidr_block        = "192.0.1.0/24"
  display_name      = "public-subnet"
  dns_label         = "public"
  route_table_id    = oci_core_route_table.public_rt.id
  # Added OKE API Endpoint Security List and LB Security List
  security_list_ids = [
    oci_core_vcn.test_vcn.default_security_list_id,
    oci_core_security_list.oke_api_endpoint_sl.id,
    oci_core_security_list.lb_security_list.id
  ]
}

# NAT Gateway (Private Subnet용 - 외부 통신 필요 시)
resource "oci_core_nat_gateway" "test_nat" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "test-nat"
}

# Service Gateway (OCI 서비스 접근용 - 필수 for OKE)
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "test_sgw" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
  display_name = "test-sgw"
}

# Route Table for Private Subnet (NAT Gateway + Service Gateway 연결)
resource "oci_core_route_table" "private_rt" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.test_nat.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.test_sgw.id
  }
}

# Load Balancer Security List (Public Subnet)
resource "oci_core_security_list" "lb_security_list" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "lb-security-list"

  # Ingress: Allow HTTP (80) traffic from anywhere
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    tcp_options {
      min = 80
      max = 80
    }
    description = "Allow HTTP traffic to Load Balancer and Backends"
  }
}

# OKE Worker Security List (Private Subnet)
resource "oci_core_security_list" "oke_worker_sl" {
  compartment_id = oci_identity_compartment.terraform_test.id
  vcn_id         = oci_core_vcn.test_vcn.id
  display_name   = "oke-worker-security-list"

  # Ingress: Allow pods on one worker node to communicate with pods on other worker nodes
  ingress_security_rules {
    protocol    = "all"
    source      = "192.0.10.0/24" # Private Subnet CIDR
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow pods on one worker node to communicate with pods on other worker nodes"
  }

  # Ingress: TCP access from Kubernetes Control Plane (to Pods)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "192.0.1.0/24" # Public Subnet (API Endpoint)
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "TCP access from Kubernetes Control Plane"
  }

  # Ingress: Path Discovery
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "192.0.1.0/24" # Public Subnet (API Endpoint)
    source_type = "CIDR_BLOCK"
    stateless   = false
    icmp_options {
      type = 3
      code = 4
    }
    description = "Path discovery"
  }
  
  # Ingress: SSH access (Optional, from Bastion/VCN)
  ingress_security_rules {
      protocol    = "6"
      source      = "192.0.0.0/16"
      source_type = "CIDR_BLOCK"
      stateless   = false
      tcp_options {
          min = 22
          max = 22
      }
      description = "Inbound SSH traffic to worker nodes"
  }


  # Egress: Worker Nodes access to Internet (via NAT)
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Worker Nodes access to Internet"
  }

  # Egress: Allow pods on one worker node to communicate with pods on other worker nodes
  egress_security_rules {
    protocol         = "all"
    destination      = "192.0.10.0/24" # Private Subnet CIDR
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow pods on one worker node to communicate with pods on other worker nodes"
  }

  # Egress: Access to Kubernetes API Endpoint
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = "192.0.1.0/24" # Public Subnet (API Endpoint)
    destination_type = "CIDR_BLOCK"
    stateless        = false
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "Access to Kubernetes API Endpoint"
  }

  # Egress: Kubernetes worker to control plane communication
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = "192.0.1.0/24" # Public Subnet (API Endpoint)
    destination_type = "CIDR_BLOCK"
    stateless        = false
    tcp_options {
      min = 12250
      max = 12250
    }
    description = "Kubernetes worker to control plane communication"
  }

  # Egress: Path Discovery
  egress_security_rules {
    protocol         = "1" # ICMP
    destination      = "192.0.1.0/24" # Public Subnet (API Endpoint)
    destination_type = "CIDR_BLOCK"
    stateless        = false
    icmp_options {
      type = 3
      code = 4
    }
    description = "Path discovery"
  }

  # Egress: Allow nodes to communicate with OKE (OSN)
  egress_security_rules {
    protocol         = "6" # TCP
    destination      = data.oci_core_services.all_services.services[0].cidr_block
    destination_type = "SERVICE_CIDR_BLOCK"
    stateless        = false
    tcp_options {
      min = 443
      max = 443
    }
    description = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
  }
}

# Private Subnet (192.0.10.0/24)
resource "oci_core_subnet" "private_subnet" {
  compartment_id             = oci_identity_compartment.terraform_test.id
  vcn_id                     = oci_core_vcn.test_vcn.id
  cidr_block                 = "192.0.10.0/24"
  display_name               = "private-subnet"
  dns_label                  = "private"
  route_table_id             = oci_core_route_table.private_rt.id
  # Updated OKE Security List + Default
  security_list_ids          = [
    oci_core_vcn.test_vcn.default_security_list_id,
    oci_core_security_list.oke_worker_sl.id
  ]
  prohibit_public_ip_on_vnic = true
}