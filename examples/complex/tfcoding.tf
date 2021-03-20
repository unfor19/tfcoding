variable "environment" {
  default = "stg"
}

locals {
  node_group_template = jsondecode(templatefile("${path.module}/nodegroup.tpl", {}))
  node_group_template_rendered = {
    for ng_key in keys(local.node_group_template) :
    ng_key => local.node_group_template[ng_key][var.environment]
  }
  my_keys = keys(local.node_group_template_rendered)
}
