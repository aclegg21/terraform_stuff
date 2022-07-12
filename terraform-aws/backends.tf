terraform {
  cloud {
    organization = "AC-Demo-ORG"

    workspaces {
      name = "ac-dev"
    }
  }
}