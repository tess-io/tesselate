locals {
  kubeconfig = yamldecode(file(var.kubeconfig_path))
  cluster    = one(local.kubeconfig.clusters).cluster
  user       = one(local.kubeconfig.users).user
  ca_data    = base64decode(local.cluster["certificate-authority-data"])

  client = {
    cert_data = base64decode(local.user["client-certificate-data"])
    key_data  = base64decode(local.user["client-key-data"])
  }
}

data "http" "requests" {
  for_each = toset([ "healthz", "readyz", "livez" ])
  
  url = "${local.cluster["server"]}/${each.value}"
  
  ca_cert_pem     = local.ca_data
  client_cert_pem = local.client.cert_data
  client_key_pem  = local.client.key_data
}

data "http" "cilium" {
  url = "${local.cluster["server"]}/apis/cilium.io/v2"

  ca_cert_pem     = local.ca_data
  client_cert_pem = local.client.cert_data
  client_key_pem  = local.client.key_data
}
