# TF Network PoC

This is a brief proof of concept for how to manage the network resources.

## Core Concepts

1. A VPC should have a predetermined maximum number of 'segments'. These _may_ be aligned to a particular AWS availability zone (AZ), however, more than one segment may target the same AZ. In this PoC, four segments are defined.

   - Using a dynamic number of segments is not advised; this will re-align the IP space and will likely cause issues with assets already deployed.
   - It's recommended to use a base 2 number of segments. This assists with the IP math.

2. Each segment has its space split across application type/need. This is intended to allow each application type to be distributed across multiple segments.

   The primary types are as follows.

   - public
   - private
   - protected

   From there, the choice of 'specialized' subnets may include

   - lambda
   - database
   - etc.

   This can be expanded as needed. Again, it's recommended that this subdivision is also across a base 2 value, but this is not as strict. The types can be balanced with more or fewer IPs as needed.

3. A local module is leveraged to avoid indexing issues. It may be possible to flatten this with more complex preparation of the divisions, and multiple indexing segments for resources names (i.e. foo[:az][:type]).

4. The PoC makes heavy use of [cidrsubnets](https://www.terraform.io/language/functions/cidrsubnets). Being familiar with how it operates is critical.

5. [Subnet Calculator](). This tool is useful for visualizing how an IP space can be divided. Particularly, the 'Join' column can identify how 'newbits' added restrict the space. This is just as critical for expermenting with how to split the subnets assigned to each 'type'. Please reference the weights used for the types.

6. Maps are heavily utilized. A core issue with the existing way subnets are divided is that anonymous loops are used. If a segment, type, subnet, or other are looped over, changes to the range have an impact on the resulting IP range. If at specific levels, this range is indexed by 'name', if one of the index values is remove, the IP ranges for the raminaing indexes are not affected.

7. The first pass attempted to use maps, utilizing keys() and values() where possible. However, these methods return values in _lexicographical_ order. As a result, cidrsubnets() may fail due to the way the subnets are split. The values for `newbits` should be in an increasing order which the method can use to properly divide the IP space. This may require re-ordering the key and value lists. These maps were already used to generate `*_keys` and `*_weights` lists. This logic isn't much different, with the exception that it requires manual intervention to ensure that the key and value are in the same index across the variables.
