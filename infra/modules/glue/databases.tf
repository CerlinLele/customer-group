# Create Glue Catalog databases
resource "aws_glue_catalog_database" "databases" {
  for_each = local.databases_map

  name        = each.value.database_name
  description = each.value.description

  tags = merge(
    var.tags,
    {
      Name = each.value.database_name
    }
  )
}
