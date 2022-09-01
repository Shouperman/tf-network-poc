# Divide the IP space by 'segment', and each segment by resource type.
#
# In this PoC, 4 segements are defined. The vpc_cidr is the top-level cidr for the entire IP space.
locals {
  # Dividing the VPC into 4 of equal size, hence 2, 2, 2, 2 'newbits'.
  # The monikers do not need to be aligned with the AZ names.
  segment_keys = [
    "a",
    "b",
    "c",
    "d"
  ]
  segment_weights = [
    2,
    2,
    2,
    2
  ]

  # Define the AZs for each segment.
  availability_zones = [
    "a",
    "b",
    "e",
    "f"
  ]

  # Defined as a map so the same cidr is assigned to each segment, regardless of which segments are active.
  segment_cidrs = { for i, cidr in cidrsubnets(var.vpc_cidr, local.segment_weights...) : local.segment_keys[i] => { zone = local.availability_zones[i],  cidr = cidr } }
  # Should result in something like the following for 192.168.0.0
  # {
  #   "a" = {
  #     "cidr" = "10.0.0.0/18",
  #     "zone" = "a"
  #   },
  #   "b" = {
  #     "cidr" = "10.0.64.0/18",
  #     "zone" = "b"
  #   },
  #   "c" = {
  #     "cidr" = "10.1680.128.0/18",
  #     "zone" = "c"
  #   },
  #   "d" = {
  #     "cidr" = "10.0.192.0/18",
  #     "zone" = "d"
  #   }
  # }

  # Divide the segment by subnet type. The weights are not equal.
  # - Private subnets take one-half of the allowed space.
  # - Lambdas take one-quarter.
  # - Public and Protected take one-eighth.

  # When using cidrsubnets, the order of the divisions matter.
  # The values() method returns values _lexigraphically_. This is why the var is defined separately.
  # If the weights change, their order and the key order may need to change as well.
  type_keys = [
    "private",
    "lambda",
    "public",
    "protected"
  ]
  type_weights = [
    1,
    2,
    3,
    3
  ]

  # For each segment cidr, define the type cidrs. This _may_ be consolidated with the segment_cidr for loop, but this division is less complcated.
  segment_type_cidrs = { for i, segment_cidr in local.segment_cidrs : i => { for j, cidr in cidrsubnets(segment_cidr.cidr, local.type_weights...) : local.type_keys[j] => { zone = segment_cidr.zone, cidr = cidr } } }

  # Should result in something like the following for 192.168.0.0 top level.
  # {
  #   a = {
  #     lambda = {
  #       cidr = "10.0.32.0/20",
  #       zone = "a"
  #     }
  #     private = {
  #       cidr = "10.0.0.0/19",
  #       zone = "a"
  #     }
  #     protected = {
  #       cidr = "10.0.56.0/21",
  #       zone = "a"
  #     }
  #     public = {
  #       cidr = "10.0.48.0/21",
  #       zone = "a"
  #     }
  #   }
  # ...
  # }

  # for_each only accepts a map or set. In order to use the above cidr definitions, the map must be flattened.
  # This looks redundant, but reduces the above into a list of objects.
  # Each includes the keys required to index on segment and type.
  # The flatten docs even use subnets as an example: https://www.terraform.io/language/functions/flatten
  st_flat = flatten([
    for segment, types in local.segment_type_cidrs : [
      for type, config in types : {
        cidr    = config.cidr
        zone    = config.zone
        type    = type
        segment = segment
    }]
  ])

  # Should result in something like the following
  # [
  #   {
  #     cidr    = "10.0.32.0/20"
  #     segment = "a"
  #     type    = "lambda"
  #     zone    = "a"
  #   },
  # ...
  # ]
}

# NOTE: the vpc_id will likely be defined by a resource within this repo. For the PoC, the value is stubbed.
resource "aws_subnet" "segment_type" {
  for_each = {
    for subnet in local.st_flat : "${subnet.segment}.${subnet.type}" => subnet
  }
  vpc_id            = 1 # aws_vpc.primary.id
  availability_zone = "${var.aws_region}${each.value.zone}"
  cidr_block        = each.value.cidr

  tags = {
    names   = "${each.value.segment}-${each.value.type}-${each.value.zone}"
    segment = each.value.segment
    type    = each.value.type
  }
}
