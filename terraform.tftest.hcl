mock_provider "aws" {}

run "both_launch_template_forms_are_rejected" {
  command = plan

  variables {
    min_size             = 1
    max_size             = 3
    launch_template_id   = "lt-1111"
    launch_template_name = "app"
  }

  expect_failures = [var.launch_template_name]
}

run "invalid_refresh_strategy_is_rejected" {
  command = plan

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
    instance_refresh   = { strategy = "AllAtOnce" }
  }

  expect_failures = [var.instance_refresh]
}

run "name_defaults_to_random_uuid" {
  command = apply

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
  }

  assert {
    condition     = aws_autoscaling_group.resource.name == random_uuid.resource.id
    error_message = "Leaving name unset should fall back to the generated random_uuid."
  }
}

run "launch_template_version_defaults_to_default" {
  command = plan

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
  }

  assert {
    condition     = aws_autoscaling_group.resource.launch_template[0].version == "$Default"
    error_message = "The launch template version should default to '$Default', pairing with the launch template module's update_default_version."
  }

  assert {
    condition     = aws_autoscaling_group.resource.launch_template[0].id == "lt-1111"
    error_message = "The launch template ID should pass through unchanged."
  }
}

run "no_instance_refresh_by_default" {
  command = plan

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
  }

  assert {
    condition     = length(aws_autoscaling_group.resource.instance_refresh) == 0
    error_message = "Leaving instance_refresh unset should emit no instance_refresh block."
  }
}

run "instance_refresh_defaults_to_rolling" {
  command = plan

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
    instance_refresh   = { min_healthy_percentage = 90 }
  }

  assert {
    condition     = aws_autoscaling_group.resource.instance_refresh[0].strategy == "Rolling"
    error_message = "An instance refresh should default to the only strategy AWS supports."
  }

  assert {
    condition     = aws_autoscaling_group.resource.instance_refresh[0].preferences[0].min_healthy_percentage == 90
    error_message = "The refresh's min_healthy_percentage should pass through to its preferences block."
  }
}

run "no_tags_by_default" {
  command = plan

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
  }

  assert {
    condition     = length(aws_autoscaling_group.resource.tag) == 0
    error_message = "Leaving both tag variables unset should emit no tag blocks."
  }
}

run "instance_tags_propagate_and_group_tags_do_not" {
  command = apply

  variables {
    min_size           = 1
    max_size           = 3
    launch_template_id = "lt-1111"
    instance_tags      = { Name = "app" }
    tags               = { Owner = "platform" }
  }

  assert {
    condition     = length(aws_autoscaling_group.resource.tag) == 2
    error_message = "Each entry across instance_tags and tags should produce one tag block."
  }

  assert {
    condition     = one([for t in aws_autoscaling_group.resource.tag : t.propagate_at_launch if t.key == "Name"]) == true
    error_message = "An instance_tags entry should propagate to launched instances."
  }

  assert {
    condition     = one([for t in aws_autoscaling_group.resource.tag : t.propagate_at_launch if t.key == "Owner"]) == false
    error_message = "A tags entry should stay on the group and not propagate to instances."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    name                = "app"
    min_size            = 2
    max_size            = 6
    vpc_zone_identifier = ["subnet-1111", "subnet-2222"]
    launch_template_id  = "lt-1111"

    health_check_type         = "ELB"
    health_check_grace_period = 300
    target_group_arns         = ["arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/app/1111"]

    instance_refresh = {
      min_healthy_percentage = 90
      skip_matching          = true
    }

    instance_tags = { Name = "app" }
  }
}

run "readme_minimal_example" {
  command = plan

  variables {
    min_size            = 1
    max_size            = 3
    vpc_zone_identifier = ["subnet-1111", "subnet-2222"]
    launch_template_id  = "lt-1111"
  }
}
