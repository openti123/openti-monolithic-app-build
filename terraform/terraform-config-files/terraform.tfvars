region                  = "us-east-1"
vpc_id                  = "vpc-049e7c5d2a7fe68ba"

subnet_ids = [
  "subnet-06cf741bcc6df9cf3",
  "subnet-0b6dc6b8b92580f6a"
]

instance_ami            = "ami-068c0051b15cdb816"
db_secret_name          = "itgenius-db-secret-openti"
instance_key_name       = "new-server"
instance_subnet_id      = "subnet-06cf741bcc6df9cf3"
instance_type           = "t2.micro"
sonar_nexus_instance_type = "t2.medium"
db_name                 = "opentidb"
db_instance_class       = "db.t3.micro"
db_engine_version       = "8.0"
s3_bucket_name          = "openti-s3-bucket-state-file"
