resource "oci_identity_compartment" "terraform_test" {
  # Required
  compartment_id = var.parent_compartment_id
  name           = var.compartment_name
  description    = "Compartment created by Terraform for testing"

  # Optional
  enable_delete  = true # Allows deletion via Terraform (Be careful in production)
}

output "new_compartment_id" {
  value = oci_identity_compartment.terraform_test.id
}
