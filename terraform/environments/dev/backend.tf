terraform {
  backend "gcs" {
    bucket = "ezcopro-tfstate"
    prefix = "terraform/state/dev"
  }
}
