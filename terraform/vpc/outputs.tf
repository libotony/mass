output "explore_public_zone_id" {
    description = "The ID of the public hosted zone for the explore application"
    value = aws_route53_zone.explore_public_zone.id
}

output "chatbot_sns_topic_name" {
  description = "The name of the chatbot/slack SNS topic"
  value       = aws_sns_topic.chatbot_sns_topic.name
}