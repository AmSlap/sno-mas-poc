terraform {
  required_version = ">= 1.6.0"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.70"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
