terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
  }
}

# Création des buckets
# Note : on utilise le provider AWS configuré pour pointer sur OVH S3
resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  
  bucket = each.value.name
  
  tags = merge(
    var.common_tags,
    {
      Name        = each.value.name
      LogicalName = each.key
    }
  )
}

# Lifecycle : appliquer une règle d'expiration pour les buckets qui le demandent
# Filtré sur les buckets où expiration_days > 0
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for k, v in var.buckets : k => v
    if v.expiration_days > 0
  }
  
  bucket = aws_s3_bucket.this[each.key].id
  
  rule {
    id     = "expire-objects"
    status = "Enabled"
    
    # Filtre vide = s'applique à tous les objets du bucket
    filter {}
    
    expiration {
      days = each.value.expiration_days
    }
    
    # Cleanup des uploads multipart abandonnés (bonne hygiène S3)
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
