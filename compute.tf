# compute.tf

# Get a list of Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.parent_compartment_id
}

# Define an OCI Compute Instance
resource "oci_core_instance" "testcompute_instance" {
  for_each = toset([for i in range(var.instance_count) : tostring(i + 1)])

  compartment_id      = oci_identity_compartment.terraform_test.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  # IMPORTANT: Replace this with the actual OCID of an Oracle Linux 9 image in your region.
  # You can find this using the OCI console or OCI CLI:
  # oci compute image list --compartment-id <compartment_id> --operating-system "Oracle Linux" --operating-system-version "9" --query "data[0].id"
  source_details {
    source_id   = var.instance_image_ocid
    source_type = "image"
  }

  shape = var.instance_shape

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    display_name     = "test-vnic-${each.key}"
    hostname_label   = "test-${each.key}"
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }

  display_name = "test-${each.key}"

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  state = "RUNNING"
}
