# tfcoding

[![Push latest version to DockerHub](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml/badge.svg)](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml) [![Dockerhub pulls](https://img.shields.io/docker/pulls/unfor19/tfcoding)](https://hub.docker.com/r/unfor19/tfcoding)

Speed up development cycle when using terraform's [Expressions](https://www.terraform.io/docs/language/expressions/index.html) and [Functions](https://www.terraform.io/docs/language/functions/index.html) by rendering [Local Values](https://www.terraform.io/docs/language/values/locals.html). This app attempts to imitate the behavior of the [helm template](https://helm.sh/docs/helm/helm_template/) command on terraform's local values.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)

## Usage

### Create the file tfcoding.tf

This file contains the code that will be rendered. Currently supports Variables and Local Values, does not work when referencing to Resources and Modules.

```go
variable "environment" {
  default = "stg"
}

variable "cidr_ab" {
  type = map
  default = {
    "dev": "10.10"
    "stg": "10.11"
    "prd": "10.12"
  }
}

locals {
  cidr_ab = "${lookup(var.cidr_ab, var.environment)}"
  private_subnets = [
    "${local.cidr_ab}.0.0/24",
    "${local.cidr_ab}.1.0/24",
  ]
}
```

### Render the local values

Mount the source code directory to `/src/` (read-only) and provide a relative path from `$PWD` to a directory that contains `tfcoding.tf`.

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ RELATIVE_PATH="examples/basic"
$ docker run --rm -it -v "${PWD}"/:/src/:ro \
  unfor19/tfcoding "$RELATIVE_PATH" watch

# Output - auto-updates on changes in /src/$RELATIVE_PATH
{
  "cidr_ab": 10.11,
  "private_subnets": [
    "10.11.0.0/24",
    "10.11.1.0/24"
  ]
}

# Hit CTRL+C to stop the app (container)
# To see a more complicated example change basic to complex
```

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/tfcoding/blob/master/LICENSE) file for details
