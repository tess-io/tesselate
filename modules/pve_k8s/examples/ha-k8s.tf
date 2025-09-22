module "pve_k8s" {
  source = "./modules/pve_k8s"

  network = {
    cidr   = "192.168.0.0/24"
    dns    = "8.8.8.8"
    domain = "cluster.local"
  }

  groups = {
    control = {
      size       = 4
      node_name  = "control-node"
      is_control = true

      resources = {
        cpu    = 4
        memory = 8         
      }
    }
    worker = {
      size      = 4
      node_name = "worker-node"

      resources = {
        cpu    = 4
        memory = 8
      }
    }
  }
}
