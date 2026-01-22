terraform {
  backend "s3" {
    bucket         = "openti-s3-bucket-state-file"
    key            = "openti-app/terraform_statefile"
    region         = "us-east-1"
    use_lockfile   = true
  }
}

