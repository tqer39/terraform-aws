moved {
  from = module.organizations.module.accounts["audit"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["audit"]
}

moved {
  from = module.organizations.module.accounts["log"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["log"]
}

moved {
  from = module.organizations.module.accounts["management"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["management"]
}

moved {
  from = module.organizations.module.accounts["portfolio"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["portfolio"]
}

moved {
  from = module.organizations.module.accounts["portfolio-dev"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["portfolio-dev"]
}

moved {
  from = module.organizations.module.accounts["sandbox"].aws_organizations_account.this
  to   = module.organizations.aws_organizations_account.this["sandbox"]
}

moved {
  from = module.organizations.module.organization.aws_organizations_organization.this
  to   = module.organizations.aws_organizations_organization.this
}

moved {
  from = module.organizations.module.organizational-units["Sandbox"].aws_organizations_organizational_unit.this
  to   = module.organizations.aws_organizations_organizational_unit.this["Sandbox"]
}

moved {
  from = module.organizations.module.organizational-units["Security"].aws_organizations_organizational_unit.this
  to   = module.organizations.aws_organizations_organizational_unit.this["Security"]
}

moved {
  from = module.organizations.module.organizational-units["WorkLoad"].aws_organizations_organizational_unit.this
  to   = module.organizations.aws_organizations_organizational_unit.this["WorkLoad"]
}
