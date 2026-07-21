# Copie ce fichier en terraform.tfvars (gitignored) et remplis les valeurs

# Credentials API OVH (à générer sur https://api.ovh.com/createToken)
ovh_application_key    = "d5f20bc683317080"
ovh_application_secret = "4a87a98ace6b3dbbb4f82b10c2163257"
ovh_consumer_key       = "25203ba1dccb427b534f30dd48676e93"

# ID du Public Cloud Project OVH
ovh_service_name = "162ab4139f994b65bdf3a72e1ffd4999"  # le project_id OVH

# Credentials d'un user S3 existant (pour bootstrapper la création des buckets)
# Tu peux récupérer celles de ton user actuel utilisé pour aws-cli
bootstrap_access_key = "53e1e613ff554291bd0f7ce78f98699a"
bootstrap_secret_key = "4765319857924f818d69156db3590a8f"