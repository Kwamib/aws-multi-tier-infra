# ==========================================
# Route Tables
# ==========================================

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.clixx_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clixx_igw.id
  }

  tags = merge(local.common_tags, {
    Name = "${title(var.project_name)}-Public-RT"
  })
}

resource "aws_route_table_association" "public_rta" {
  for_each       = toset(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Tables (one per AZ for HA NAT routing)
resource "aws_route_table" "private_rt" {
  for_each = toset(var.public_subnet_cidr)
  vpc_id   = aws_vpc.clixx_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.clixx_nat[each.key].id
  }

  tags = merge(local.common_tags, {
    Name = "${title(var.project_name)}-Private-RT-${each.key}"
  })
}

# Associate private subnets with the NAT gateway in their AZ
resource "aws_route_table_association" "private_rta" {
  for_each = toset(var.private_subnet_cidr)

  subnet_id = aws_subnet.private_subnets[each.key].id
  route_table_id = aws_route_table.private_rt[
    var.az_mapping[each.key] == "${var.aws_region}a" ? var.public_subnet_cidr[0] : var.public_subnet_cidr[1]
  ].id
}
