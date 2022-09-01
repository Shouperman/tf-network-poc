output "segment_cidrs" {
  value = local.segment_cidrs
}

output "segment_type_cidrs" {
  value = local.segment_type_cidrs
}

output "sf_flat" {
  value = local.st_flat
}

output "subnets" {
  value = aws_subnet.segment_type[*]
}
