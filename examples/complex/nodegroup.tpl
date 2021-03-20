${jsonencode(
{
    "override_instance_types": {
      "dev": ["t2.micro", "t3.micro"]
      "stg": ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      "prd": ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
    }
    "asg_min_size": {
      "dev": 1
      "stg": 2
      "prd": 2
    }
    "asg_max_size": {
      "dev": 2
      "stg": 4
      "prd": 4
    }
    "asg_desired_capacity": {
      "dev": 1
      "stg": 2
      "prd": 2
    }
    "root_volume_size": {
      "dev": 30
      "stg": 50
      "prd": 50
    }
}
)}