variable "region" {
  description = "OCI Region (e.g., ap-seoul-1)"
  type        = string
}

variable "parent_compartment_id" {
  description = "The OCID of the parent compartment where the new compartment will be created"
  type        = string
}

variable "compartment_name" {
  description = "The name of the compartment to create"
  type        = string
  default     = "terraform-test"
}

variable "instance_image_ocid" {
  description = "The OCID of the image to use for the instance."
  type        = string
}

variable "instance_shape" {
  description = "The shape of the instance (e.g., VM.Standard.E3.Flex, VM.Standard.E4.Flex)."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance."
  type        = number
  default     = 1
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GBs for the instance."
  type        = number
  default     = 6
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key to be installed on the instance for access."
  type        = string
}

variable "instance_count" {
  description = "The number of compute instances to create."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "The name of the Autonomous Database."
  type        = string
  default     = "terraformdb"
}

variable "db_admin_password" {
  description = "Password for the database ADMIN user."
  type        = string
  sensitive   = true
}

variable "db_workload" {
  description = "The workload type for the Autonomous Database (OLTP or DW)."
  type        = string
  default     = "OLTP"
}

variable "oke_k8s_version" {
  description = "Kubernetes version for OKE cluster"
  type        = string
  default     = "v1.34.1"
}
