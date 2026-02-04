# Load Balancer Configuration (Network Load Balancer)

# Create Network Load Balancer in Public Subnet
resource "oci_network_load_balancer_network_load_balancer" "test_nlb" {
  compartment_id = oci_identity_compartment.terraform_test.id
  display_name   = "test-nlb"
  subnet_id      = oci_core_subnet.public_subnet.id
  is_private     = false # Public Facing
  
  # Optional: Freeform tags
  freeform_tags = {
    "Project" = "Terraform-OCI-Test"
  }
}

# Create Backend Set
resource "oci_network_load_balancer_backend_set" "test_backend_set" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.test_nlb.id
  name                     = "test-backend-set"
  policy                   = "FIVE_TUPLE" # Default policy for distribution

  health_checker {
    protocol = "TCP"
    port     = 22
    # Optional parameters (defaults are usually sufficient)
    # interval_in_millis = 10000
    # timeout_in_millis  = 3000
    # retries            = 3
  }
}

# Create Listener (Listen on Port 80)
resource "oci_network_load_balancer_listener" "test_listener" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.test_nlb.id
  default_backend_set_name = oci_network_load_balancer_backend_set.test_backend_set.name
  name                     = "test-listener-80"
  port                     = 80
  protocol                 = "TCP"
}

# Attach Compute Instances as Backends
# Iterates over the instances created in compute.tf
resource "oci_network_load_balancer_backend" "test_backend" {
  for_each                 = oci_core_instance.testcompute_instance
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.test_nlb.id
  backend_set_name         = oci_network_load_balancer_backend_set.test_backend_set.name
  port                     = 80
  target_id                = each.value.id
}
