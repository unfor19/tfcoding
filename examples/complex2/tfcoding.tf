locals {
    vm_configuration_template = jsondecode(templatefile("${path.module}/vmconfig.tpl", {}))
    vm_configuration_rendered = {
        for key in keys(local.vm_configuration_template) :
        key => local.vm_configuration_template[key]
    }
}