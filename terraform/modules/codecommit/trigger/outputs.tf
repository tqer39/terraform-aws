output "repository_name" {
  description = "(Required) The name for the repository. This needs to be less than 100 characters."
  value       = aws_codecommit_trigger.this.repository_name
}

output "name" {
  description = "(Required) The name of the trigger."
  value       = aws_codecommit_trigger.this.name
}

output "destination_arn" {
  description = "(Required) The ARN of the resource that is the target for a trigger. For example, the ARN of a topic in Amazon Simple Notification Service (SNS)."
  value       = aws_codecommit_trigger.this.destination_arn
}

output "custom_data" {
  description = "(Optional) Any custom data associated with the trigger that will be included in the information sent to the target of the trigger."
  value       = aws_codecommit_trigger.this.custom_data
}

output "branches" {
  description = "(Optional) The branches that will be included in the trigger configuration. If no branches are specified, the trigger will apply to all branches."
  value       = aws_codecommit_trigger.this.branches
}

output "events" {
  description = "(Required) The repository events that will cause the trigger to run actions in another service, such as sending a notification through Amazon Simple Notification Service (SNS). If no events are specified, the trigger will run for all repository events. Event types include: all, updateReference, createReference, deleteReference."
  value       = aws_codecommit_trigger.this.events
}
