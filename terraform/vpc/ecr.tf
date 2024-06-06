module "mass_ecr_repo" {
  for_each             = toset(["mass", "chain-scanner", "explore"])
  source               = "git::github.com/vechain/terraform_infrastructure_modules.git//ecr?ref=v.1.0.25"
  enable               = true
  enable_private_ecr   = true
  env                  = local.env.environment
  project              = local.env.project
  app_name             = each.key
  image_tag_mutability = "MUTABLE"
}
