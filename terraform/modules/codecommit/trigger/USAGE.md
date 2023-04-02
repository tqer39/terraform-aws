<!-- BEGIN_TF_DOCS -->


## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_codecommit_trigger.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_trigger) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_codecommit_trigger"></a> [aws\_codecommit\_trigger](#input\_aws\_codecommit\_trigger) | Provides a CodeCommit Trigger Resource. aws\_codecommit\_trigger, see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codecommit_trigger | `any` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_branches"></a> [branches](#output\_branches) | (Optional) The branches that will be included in the trigger configuration. If no branches are specified, the trigger will apply to all branches. |
| <a name="output_custom_data"></a> [custom\_data](#output\_custom\_data) | (Optional) Any custom data associated with the trigger that will be included in the information sent to the target of the trigger. |
| <a name="output_destination_arn"></a> [destination\_arn](#output\_destination\_arn) | (Required) The ARN of the resource that is the target for a trigger. For example, the ARN of a topic in Amazon Simple Notification Service (SNS). |
| <a name="output_events"></a> [events](#output\_events) | (Required) The repository events that will cause the trigger to run actions in another service, such as sending a notification through Amazon Simple Notification Service (SNS). If no events are specified, the trigger will run for all repository events. Event types include: all, updateReference, createReference, deleteReference. |
| <a name="output_name"></a> [name](#output\_name) | (Required) The name of the trigger. |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | (Required) The name for the repository. This needs to be less than 100 characters. |
<!-- END_TF_DOCS -->