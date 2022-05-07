output "normal_variable" {
  description = "これは通常の variable"
  value       = var.normal_variable
}
# 結果: normal_variable = "これは通常の variable"

# sensitive がないと terraform validate の段階でエラーになる。
output "sensitive_variable" {
  description = "これはsensitiveな variable"
  value       = var.sensitive_variable
  sensitive   = true
}
# 結果: sensitive_variable = <sensitive>

output "basic" {
  description = "ベーシック"
  value       = local.basic
}
# 結果: basic = "ベーシック"

output "params" {
  value = var.params
}

output "params_param1_name" {
  value = var.params.param1.name
}
# 結果: params_param1_name = "param1"

output "params_param2_value" {
  value = var.params.param2.value
}
# 結果: params_param2_value = "fuga"

output "list_values" {
  value = local.list_values
}
# 結果: list_values = ["hoge", "fuga", "moga"]

output "list_value_count" {
  value = length(local.list_values)
}
# 結果: list_value_count = 3

output "list_value_element" {
  value = element(local.list_values, 2) # 2番目の引数にインデックスを指定する
}
# 結果: list_value_element = "moga"

output "list_value_1" {
  value = local.list_values[0]
}
# 結果: list_value_1 = "hoge"
