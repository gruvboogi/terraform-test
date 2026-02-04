terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.32.0"
    }
  }
}

provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}
