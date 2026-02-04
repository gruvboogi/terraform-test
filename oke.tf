# oke.tf

# OKE Cluster
resource "oci_containerengine_cluster" "test_oke_cluster" {
  compartment_id     = oci_identity_compartment.terraform_test.id
  kubernetes_version = var.oke_k8s_version
  name               = "terraform-oke-cluster"
  vcn_id             = oci_core_vcn.test_vcn.id
  type               = "ENHANCED_CLUSTER"

  # CNI Type: OCI_VCN_IP_NATIVE (Pods use VCN IPs)
  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public_subnet.id
    nsg_ids              = [] 
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    admission_controller_options {
      is_pod_security_policy_enabled = false
    }
    service_lb_subnet_ids = [oci_core_subnet.public_subnet.id]

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "test_node_pool" {
  cluster_id         = oci_containerengine_cluster.test_oke_cluster.id
  compartment_id     = oci_identity_compartment.terraform_test.id
  kubernetes_version = var.oke_k8s_version
  name               = "pool1"
  node_shape         = "VM.Standard.A1.Flex"
  
  # Image Source Details
  node_source_details {
    image_id    = "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaavrbkqtfdpqfgnhpfjmyknjdh7rsm23bele247ina5sw7wspjnwqa"
    source_type = "IMAGE"
  }

  node_shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  node_config_details {
    size = 0

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private_subnet.id
    }

    node_pool_pod_network_option_details {
      cni_type       = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [oci_core_subnet.private_subnet.id]
    }
  }

  ssh_public_key = file(var.ssh_public_key_path)
}

# OKE Addons from oke_sample
resource "oci_containerengine_addon" "test_addon_coredns" {
  addon_name                       = "CoreDNS"
  cluster_id                       = oci_containerengine_cluster.test_oke_cluster.id
  remove_addon_resources_on_delete = true
  override_existing                = true
}

resource "oci_containerengine_addon" "test_addon_kubeproxy" {
  addon_name                       = "KubeProxy"
  cluster_id                       = oci_containerengine_cluster.test_oke_cluster.id
  remove_addon_resources_on_delete = true
  override_existing                = true
}

resource "oci_containerengine_addon" "test_addon_nvidiagpu" {
  addon_name                       = "NvidiaGpuPlugin"
  cluster_id                       = oci_containerengine_cluster.test_oke_cluster.id
  remove_addon_resources_on_delete = true
  override_existing                = true
}

resource "oci_containerengine_addon" "test_addon_vcn_ip_native" {
  addon_name                       = "OciVcnIpNative"
  cluster_id                       = oci_containerengine_cluster.test_oke_cluster.id
  remove_addon_resources_on_delete = true
  override_existing                = true
}

output "oke_cluster_id" {
  value = oci_containerengine_cluster.test_oke_cluster.id
}
