variable "name" {
  default     = null
  description = "Name of the autoscaling group. If null, a unique name is generated."
}

variable "min_size" {
  default     = null
  description = "Fewest instances the group maintains. Scaling policies never take it below this."
}

variable "max_size" {
  default     = null
  description = "Most instances the group may run. Scaling policies never take it above this."
}

variable "desired_capacity" {
  default     = null
  description = "Instances the group tries to run right now, between min_size and max_size. If null, the group starts at min_size. Leave it null once a scaling policy owns capacity, so Terraform does not fight the policy by resetting the count on every apply."
}

variable "vpc_zone_identifier" {
  default     = null
  description = "IDs of the subnets the group launches instances into, from terraform-aws-vpc-subnet or terraform-aws-vpc's subnet_ids output. Span several availability zones so the loss of one does not take the whole group with it."
}

variable "launch_template_id" {
  default     = null
  description = "ID of the launch template describing the instances, from terraform-aws-launch-template. Mutually exclusive with launch_template_name."
}

variable "launch_template_name" {
  default     = null
  description = "Name of the launch template describing the instances. Mutually exclusive with launch_template_id."

  validation {
    condition     = var.launch_template_id == null || var.launch_template_name == null
    error_message = "At most one of launch_template_id or launch_template_name may be set."
  }
}

variable "launch_template_version" {
  default     = "$Default"
  description = "Version of the launch template to launch. '$Default' follows the template's default version, '$Latest' always takes the newest, or a literal number pins one. Defaults to '$Default', which pairs with terraform-aws-launch-template's own update_default_version so a template change actually reaches new instances."
}

variable "health_check_type" {
  default     = null
  description = "What the group treats as an unhealthy instance: 'EC2' (the instance itself has failed) or 'ELB' (a load balancer health check has failed). Use 'ELB' whenever the group sits behind a load balancer, or the group will happily keep an instance whose application has died. If null, AWS's own default ('EC2') applies."
}

variable "health_check_grace_period" {
  default     = null
  description = "Seconds after an instance launches before health checks count against it. Too short and a slow-booting application is killed and relaunched forever. If null, AWS's own default (300) applies."
}

variable "target_group_arns" {
  default     = null
  description = "ARNs of load balancer target groups the group registers its instances with, from terraform-aws-alb-target-group or terraform-aws-nlb-target-group."
}

variable "capacity_rebalance" {
  default     = null
  description = "Whether the group proactively replaces a Spot instance AWS has marked for interruption, rather than waiting for it to be reclaimed. If null, AWS's own default (disabled) applies."
}

variable "default_cooldown" {
  default     = null
  description = "Seconds after a scaling activity before another may start, giving the previous one time to take effect. If null, AWS's own default (300) applies."
}

variable "default_instance_warmup" {
  default     = null
  description = "Seconds a newly launched instance takes to begin serving its share of traffic. Scaling metrics ignore the instance until it elapses, so a still-warming instance does not look overloaded and trigger further scaling."
}

variable "max_instance_lifetime" {
  default     = null
  description = "Seconds an instance may run before the group replaces it, forcing regular rotation onto fresh AMIs. Minimum 86400 (one day). If null, instances are never replaced on age alone."
}

variable "termination_policies" {
  default     = null
  description = "Order in which the group picks instances to terminate when scaling in (e.g. ['OldestInstance'], ['Default']). If null, AWS's own default policy applies."
}

variable "protect_from_scale_in" {
  default     = null
  description = "Whether new instances are protected from termination by scale-in, leaving them to be removed deliberately. Standard for an ECS capacity provider, where ECS itself decides when an instance may go. If null, AWS's own default (disabled) applies."
}

variable "suspended_processes" {
  default     = null
  description = "Autoscaling processes to suspend (e.g. ['AZRebalance', 'ReplaceUnhealthy']). Suspending 'Launch' or 'Terminate' stops the group acting on its own capacity at all."
}

variable "enabled_metrics" {
  default     = null
  description = "Group metrics published to CloudWatch (e.g. ['GroupInServiceInstances', 'GroupPendingInstances']). Free, and off by default — without them the group's own capacity is invisible in CloudWatch."
}

variable "metrics_granularity" {
  default     = null
  description = "Granularity of enabled_metrics. AWS accepts only '1Minute'. If null, AWS's own default applies."
}

variable "instance_refresh" {
  default     = null
  description = "How the group rolls existing instances when the launch template changes. Without it, a template change only affects instances launched afterward, leaving the running ones on the old version indefinitely. strategy must be 'Rolling'. min_healthy_percentage sets how much capacity stays in service during the roll; skip_matching leaves instances already on the new version alone."
  type = object({
    strategy               = optional(string, "Rolling")
    triggers               = optional(list(string))
    min_healthy_percentage = optional(number)
    max_healthy_percentage = optional(number)
    instance_warmup        = optional(string)
    checkpoint_delay       = optional(string)
    checkpoint_percentages = optional(list(number))
    skip_matching          = optional(bool)
    auto_rollback          = optional(bool)
  })

  validation {
    condition     = var.instance_refresh == null || var.instance_refresh.strategy == "Rolling"
    error_message = "An instance refresh's strategy must be 'Rolling', the only strategy AWS supports."
  }
}

variable "instance_tags" {
  default     = null
  description = "Tags applied to the group and propagated to every instance it launches. Kept separate from tags because an autoscaling group models tags as blocks carrying a propagate_at_launch flag rather than a plain map."
}

variable "wait_for_capacity_timeout" {
  default     = null
  description = "How long Terraform waits for instances to become healthy before declaring the apply failed (e.g. '10m'). Set '0' to skip waiting entirely. If null, AWS's own default ('10m') applies."
}

variable "force_delete" {
  default     = null
  description = "Whether destroying the group skips waiting for its instances to terminate first. Leaves AWS to clean up asynchronously. If null, AWS's own default (wait) applies."
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the autoscaling group itself, without propagating them to launched instances. Use instance_tags to tag the instances too."
}
