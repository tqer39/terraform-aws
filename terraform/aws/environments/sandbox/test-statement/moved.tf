moved {
  from = module.create-users.module.iam-user["hoge"].aws_iam_user.this
  to   = module.create-users.aws_iam_user.this["hoge"]
}

moved {
  from = module.create-users.module.iam-user["fuga"].aws_iam_user.this
  to   = module.create-users.aws_iam_user.this["fuga"]
}

moved {
  from = module.create-users.module.iam-user["moga"].aws_iam_user.this
  to   = module.create-users.aws_iam_user.this["moga"]
}
