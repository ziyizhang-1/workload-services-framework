resource "aws_vpc" "default" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    {
      Name  = "wsf-${var.job_id}-vpc"
      JobId = var.job_id
    },
  )
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.common_tags,
    {
      Name  = "wsf-${var.job_id}-igw"
      JobId = var.job_id
    },
  )
}

resource "aws_subnet" "default" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 1)
  availability_zone       = var.zone
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    {
      Name  = "wsf-${var.job_id}-subnet"
      JobId = var.job_id
    },
  )
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.default.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = merge(
    var.common_tags,
    {
      Name  = "wsf-${var.job_id}-rt"
      JobId = var.job_id
    },
  )
}

resource "aws_default_security_group" "default" {
  vpc_id      = aws_vpc.default.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.sg_whitelist_cidr_blocks
  }

  ingress {
    description      = "PING"
    from_port        = 8
    to_port          = 0
    protocol         = "icmp"
    cidr_blocks      = var.sg_whitelist_cidr_blocks
  }

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [ var.vpc_cidr_block ]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name  = "wsf-${var.job_id}-sg"
      JobId = var.job_id
    },
  )
}

locals {
  networks_flat = flatten([
    for k,v in local.instances : [
      for i in range(v.network_spec!=null?v.network_spec.network_count:0) : {
        name         = "network-interface-${i+1}"
        instance     = k
        network_type = v.network_spec.network_type
        lun          = i+1
      }
    ]
  ])
  networks = {
    for net in local.networks_flat : net.name => {
      instance     = net.instance
      network_type = net.network_type
      lun          = net.lun
    }
  }
}

resource "aws_network_interface" "secondary" {
  for_each = local.networks

  subnet_id       = aws_subnet.default.id
  description     = "vm-${var.job_id}-${each.key}"
  interface_type  = each.value.network_type
  security_groups = [aws_default_security_group.default.id]
  tags            = var.common_tags

  attachment {
    instance = var.spot_instance?aws_spot_instance_request.default[each.value.instance].spot_instance_id:aws_instance.default[each.value.instance].id
    device_index = each.value.lun
  }
}
