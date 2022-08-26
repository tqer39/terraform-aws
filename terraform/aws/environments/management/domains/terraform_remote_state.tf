# TODO: portfolio のアカウントから取得できるようになったらハードコーディングをやめる
# data "terraform_remote_state" "portfolio-domains" {
#   backend = "s3"

#   config = {
#     bucket = "terraform-tfstate-tqer39-072693953877-ap-northeast-1"
#     key    = "private-lab/terraform/environments/portfolio/portfolio-domains.tfstate"
#     region = "ap-northeast-1"
#   }
# }
