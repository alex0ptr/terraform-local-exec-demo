provider azurerm {
  version = "2.32.0"
  features {}
}

provider random {
  version = "3.0.0"
}

provider null {
  version = "3.0.0"
}

resource random_string id_suffix {
  length  = 4
  special = false
  upper   = false
}

locals {
  # use this variable as prefix for all resource names. This avoids conflicts with globally unique resources (all resources with a hostname)
  env              = "${terraform.workspace}-${random_string.id_suffix.result}"
  env_alphanumeric = replace(local.env, "-", "")
  env_human        = terraform.workspace

  # use this map to apply env-specific values for certain components.
  # please see README.MD for usage details
  env_config = {
    prd = {
      image = "nginx:1.18.0"
    }
    stg = {
    }
    dev = {
    }
    default = {
      image = "nginx:1.19.3"
    }
  }
  config = merge(local.env_config["default"], lookup(local.env_config, terraform.workspace, {}))

  # tag all resources at least with these tags
  # allows filtering and distinction between environments
  standard_tags = {
    "environment"     = local.env
    "code-repository" = "git@thisrepository.com"
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.env
  location = "westeurope"
  tags     = local.standard_tags
}

resource "azurerm_container_registry" "this" {
  name                = local.env_alphanumeric
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Premium"
  tags                = local.standard_tags
}

resource null_resource initial_image {

  # note: you can put that in the above block too, but if the script fails on the first run it will not be re-tried
  provisioner "local-exec" {
    command = "./push-acr.sh ${local.config.image} ${azurerm_container_registry.this.login_server}"
  }
}

output container_registry {
  value = {
    name          = azurerm_container_registry.this.name
    dns_name      = azurerm_container_registry.this.name
    initial_image = local.config.image
  }
}




