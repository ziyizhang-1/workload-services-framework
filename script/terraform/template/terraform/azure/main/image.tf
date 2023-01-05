
locals {
  os_image_publisher = {
    "ubuntu2004": "Canonical",
    "ubuntu2204": "Canonical",
    "debian11"  : "Debian",
  }
  os_image_offer = {
    "ubuntu2004": "0001-com-ubuntu-server-focal",
    "ubuntu2204": "0001-com-ubuntu-server-jammy",
    "debian11"  : "debian-11",
  }
  os_image_sku = {
    "ubuntu2004": "20_04-lts",
    "ubuntu2204": "22_04-lts",
    "debian11"  : "11",
  }
  os_image_user = {
    "ubuntu2004": "tfu",
    "ubuntu2204": "tfu",
    "debian11"  : "tfu",
  }
  # https://docs.microsoft.com/en-us/azure/virtual-machines/generation-2
  gen1_instances = [
    "Av2", "Amv2",
    "Dv2", "DSv2", 
    "Dv3", "Dsv3",
    "Dav4", "Dasv4",
    "Ev3", "Esv3", "Eisv3",
    "Ev4", "Esv4", "Eisv4",
    "H", "Hm", "Hr", "Hmr",
    "NC", "NCr", 
    "NV",
    "NPs",
  ]
  # https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  arm64_instances = [
    "Dpdsv5", "Dpldsv5", "Dpsv5", "Dplsv5",
    "Epdsv5", "Epsv5",
  ]
}

locals {
  instance_type_abvs = {
    for k,v in local.vms : k => replace(v.instance_type, "/[A-Za-z]+_([A-Za-z]+)[0-9]*([A-Za-z]*)_?([a-zA-Z0-9]*)/", "$1$2$3")
  }

  os_image_sku_suffixes = {
    for k,v in local.instance_type_abvs : k => contains(local.arm64_instances, v)?"-arm64":contains(local.gen1_instances, v)?"":"-gen2"
  }
}
