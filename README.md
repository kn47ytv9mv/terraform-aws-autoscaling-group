# terraform-aws-autoscaling-group

Terraform module for an EC2 autoscaling group — a pool of instances
launched from a launch template, kept at a target size across
availability zones and replaced automatically when one fails.

## Cost

Autoscaling groups carry no charge of their own. The instances they run
bill normally, so `min_size` is the floor on what this costs while
idle. See AWS's
[EC2 pricing](https://aws.amazon.com/ec2/pricing/) page for current
rates.

## Design

Pair with
[`terraform-aws-launch-template`](https://github.com/kn47ytv9mv/terraform-aws-launch-template),
which describes the instances this group launches. They are separate
modules because one template is routinely shared by several groups, and
a template is useful on its own.

`launch_template_version` defaults to `'$Default'`, which pairs with
that module's own `update_default_version` — together they mean editing
the template actually reaches instances launched afterward. `'$Latest'`
is the more aggressive choice and a pinned number the most
conservative.

**Set `health_check_type = "ELB"` whenever the group sits behind a load
balancer.** The default, `'EC2'`, only notices an instance whose
underlying virtual machine has failed — an instance whose application
has crashed while the machine keeps running stays in service
indefinitely, and the group has no idea anything is wrong.

`instance_refresh` is how existing instances get rolled when the
launch template changes. Without it, a template change only affects
instances launched afterward; the ones already running stay on the old
version until something else replaces them. `max_instance_lifetime` is
the blunter companion, forcing rotation on age alone.

Leave `desired_capacity` null once a scaling policy owns capacity.
Otherwise every `terraform apply` resets the count to whatever the
configuration says, undoing whatever the policy had scaled to.

Tags are split across two variables because AWS models an autoscaling
group's tags as blocks carrying a `propagate_at_launch` flag rather
than a plain map: `instance_tags` propagate to launched instances,
`tags` stay on the group.

### Deliberately not covered

Mixed instances policies — combining several instance types and Spot
with On-Demand in one group — are not exposed. The block is deeply
nested and would roughly double this module's surface for a feature
most groups do not use. Scaling policies are likewise separate: a group
commonly has several, each independently created and tuned, so they do
not belong bundled here. Reach for the raw resources directly for
either.

## Usage

```hcl
module "group" {
  source = "kn47ytv9mv/autoscaling-group/aws"

  name     = "app"
  min_size = 2
  max_size = 6

  vpc_zone_identifier = module.vpc.subnet_ids["private"]
  launch_template_id  = module.template.id

  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [module.target_group.arn]

  instance_refresh = {
    min_healthy_percentage = 90
    skip_matching          = true
  }

  instance_tags = { Name = "app" }
}
```

Or directly from this repository:

```hcl
module "group" {
  source = "github.com/kn47ytv9mv/terraform-aws-autoscaling-group"

  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = ["subnet-1111", "subnet-2222"]
  launch_template_id  = "lt-1111"
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.9 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the autoscaling group. If null, a unique name is generated. | `null` | no |
| min_size | Fewest instances the group maintains. | `null` | no |
| max_size | Most instances the group may run. | `null` | no |
| desired_capacity | Instances the group tries to run right now. Leave null once a scaling policy owns capacity. | `null` | no |
| vpc_zone_identifier | IDs of the subnets the group launches into. Span several availability zones. | `null` | no |
| launch_template_id | ID of the launch template, from `terraform-aws-launch-template`. Mutually exclusive with the name form. | `null` | no |
| launch_template_name | Name of the launch template. Mutually exclusive with the ID form. | `null` | no |
| launch_template_version | Version to launch: `'$Default'`, `'$Latest'`, or a literal number. | `"$Default"` | no |
| health_check_type | What counts as unhealthy: `'EC2'` or `'ELB'`. Use `'ELB'` behind a load balancer. | `null` | no |
| health_check_grace_period | Seconds after launch before health checks count against an instance. | `null` | no |
| target_group_arns | ARNs of target groups the group registers instances with, from `terraform-aws-alb-target-group` or `terraform-aws-nlb-target-group`. | `null` | no |
| capacity_rebalance | Whether the group proactively replaces a Spot instance marked for interruption. | `null` | no |
| default_cooldown | Seconds after a scaling activity before another may start. | `null` | no |
| default_instance_warmup | Seconds a new instance takes to begin serving traffic, excluded from scaling metrics. | `null` | no |
| max_instance_lifetime | Seconds an instance may run before replacement. Minimum 86400. | `null` | no |
| termination_policies | Order in which instances are picked for termination when scaling in. | `null` | no |
| protect_from_scale_in | Whether new instances are protected from scale-in termination. Standard for an ECS capacity provider. | `null` | no |
| suspended_processes | Autoscaling processes to suspend (e.g. `['AZRebalance']`). | `null` | no |
| enabled_metrics | Group metrics published to CloudWatch. Free, and off by default. | `null` | no |
| metrics_granularity | Granularity of `enabled_metrics`. AWS accepts only `'1Minute'`. | `null` | no |
| instance_refresh | How the group rolls existing instances when the launch template changes. `strategy` must be `'Rolling'`. | `null` | no |
| instance_tags | Tags applied to the group and propagated to every instance it launches. | `null` | no |
| tags | Tags on the group itself, not propagated to instances. | `null` | no |
| wait_for_capacity_timeout | How long Terraform waits for instances to become healthy (e.g. `'10m'`). `'0'` skips waiting. | `null` | no |
| force_delete | Whether destroying the group skips waiting for instances to terminate. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID (name) of the autoscaling group. |
| arn | The ARN of the autoscaling group. |
| name | The name of the autoscaling group. |
| availability_zones | Availability zones the group spans, derived from its subnets. |

## License

MIT — see [LICENSE.md](LICENSE.md).
