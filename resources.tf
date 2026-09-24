resource "random_uuid" "resource" {}

resource "aws_autoscaling_group" "resource" {
  name = coalesce(var.name, random_uuid.resource.id)

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.vpc_zone_identifier
  target_group_arns   = var.target_group_arns

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  capacity_rebalance      = var.capacity_rebalance
  default_cooldown        = var.default_cooldown
  default_instance_warmup = var.default_instance_warmup
  max_instance_lifetime   = var.max_instance_lifetime
  termination_policies    = var.termination_policies
  protect_from_scale_in   = var.protect_from_scale_in
  suspended_processes     = var.suspended_processes

  enabled_metrics     = var.enabled_metrics
  metrics_granularity = var.metrics_granularity

  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  force_delete              = var.force_delete

  launch_template {
    id      = var.launch_template_id
    name    = var.launch_template_name
    version = var.launch_template_version
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh[*]

    content {
      strategy = instance_refresh.value.strategy
      triggers = instance_refresh.value.triggers

      preferences {
        min_healthy_percentage = instance_refresh.value.min_healthy_percentage
        max_healthy_percentage = instance_refresh.value.max_healthy_percentage
        instance_warmup        = instance_refresh.value.instance_warmup
        checkpoint_delay       = instance_refresh.value.checkpoint_delay
        checkpoint_percentages = instance_refresh.value.checkpoint_percentages
        skip_matching          = instance_refresh.value.skip_matching
        auto_rollback          = instance_refresh.value.auto_rollback
      }
    }
  }

  dynamic "tag" {
    for_each = coalesce(var.instance_tags, {})

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = coalesce(var.tags, {})

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }
}

output "id" {
  description = "The ID (name) of the autoscaling group."
  value       = aws_autoscaling_group.resource.id
}

output "arn" {
  description = "The ARN of the autoscaling group."
  value       = aws_autoscaling_group.resource.arn
}

output "name" {
  description = "The name of the autoscaling group."
  value       = aws_autoscaling_group.resource.name
}

output "availability_zones" {
  description = "Availability zones the group spans, derived from its subnets."
  value       = aws_autoscaling_group.resource.availability_zones
}
