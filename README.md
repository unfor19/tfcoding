# tfcoding

[![Push latest version to DockerHub](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml/badge.svg)](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml) [![Dockerhub pulls](https://img.shields.io/docker/pulls/unfor19/tfcoding)](https://hub.docker.com/r/unfor19/tfcoding)

<img alt="tfcoding-logo" src="https://user-images.githubusercontent.com/15122452/111926094-22f28e80-8ab4-11eb-9a72-ca2394d6bb33.png" width="400" />

![tfcoding](https://d33vo9sj4p3nyc.cloudfront.net/tfcoding/tfcoding-localstack-aws.gif)

Render Terraform's [Expressions](https://www.terraform.io/docs/language/expressions/index.html) and [Functions](https://www.terraform.io/docs/language/functions/index.html) locally without any hassle.

This application runs in the background and watches for changes in the file `tfcoding.tf`, once this file is modified its [Local Values](https://www.terraform.io/docs/language/values/locals.html) are automatically rendered to the terminal's output (stdout).

This is especially useful for learning about Expressions and Functions that you are not familiar with, while avoiding the whole shebang of terraform init, plan and apply. The goal here is to "compile Terraform" locally to speed up the development (and learning) process.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- (Optional) [Docker Compose](https://docs.docker.com/compose/install/)

## Quick Start

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ make run

docker run --rm -it \
-v /home/meir/tfcoding/:/src/:ro \
unfor19/tfcoding:latest-tf0.13.5 -r examples/basic --watching 
[LOG] Thu Mar 25 00:23:59 UTC 2021 :: Terraform v0.13.6
[LOG] Thu Mar 25 00:23:59 UTC 2021 :: Rendered for the first time
{
  "cidr_ab": "10.11",
  "private_subnets": [
    "10.11.0.0/24",
    "10.11.1.0/24"
  ]
}
[LOG] Thu Mar 25 00:23:59 UTC 2021 :: Watching for changes in /src/examples/basic/tfcoding.tf
```

### Modify the file [examples/basic/tfcoding.tf](./examples/basic/tfcoding.tf)

This file contains the code that will be rendered and it must be stored in a relative directory to `$PWD`. Currently supports Variables and Local Values. To use Resources and Modules scroll down to Mock AWS.

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

## Docker Specific dir

Mount the source code directory to `/src/` (read-only) and provide a relative path from `$PWD` to a directory that contains `tfcoding.tf`. The files that will be included in the rendering process are `tfcoding.tf` `*.tpl` and `*.json`.

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ make run SRC_DIR_RELATIVE_PATH=examples/basic
```

<details>

<summary>Docker output - Expand/Collapse</summary>

```bash
[LOG] Sun Mar 21 22:28:24 UTC 2021 :: Terraform v0.13.5
[LOG] Sun Mar 21 22:28:24 UTC 2021 :: Rendered for the first time
{
  "cidr_ab": "10.11",
  "private_subnets": [
    "10.11.0.0/24",
    "10.11.1.0/24"
  ]
}
[LOG] Sun Mar 21 22:28:24 UTC 2021 :: Watching for changes in /src/examples/basic/tfcoding.tf
# Meanwhile ... Changed the map variable cidr_ab.stg from 10.11 to 10.17
[LOG] Sun Mar 21 22:29:46 UTC 2021 :: Rendered
{
  "cidr_ab": "10.17",
  "private_subnets": [
    "10.17.0.0/24",
    "10.17.1.0/24"
  ]
}

# Hit CTRL+C to stop the app (container)
# To see a more complicated example change basic to complex
```

</details>

### Clean

Stopping the container automatically removes it (`-rm`)

## Docker Compose

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ make up
```

<details>

<summary>docker-compose output - Expand/Collapse</summary>

```bash
Starting tfcoding ... done
Attaching to tfcoding
tfcoding    | [LOG] Mon Mar 22 00:00:35 UTC 2021 :: Terraform v0.13.5
tfcoding    | [LOG] Mon Mar 22 00:00:35 UTC 2021 :: Rendered for the first time
tfcoding    | {
tfcoding    |   "cidr_ab": "10.11",
tfcoding    |   "private_subnets": [
tfcoding    |     "10.11.0.0/24",
tfcoding    |     "10.11.1.0/24"
tfcoding    |   ]
tfcoding    | }
tfcoding    | [LOG] Mon Mar 22 00:00:36 UTC 2021 :: Watching for changes in /src/examples/basic/tfcoding.tf
# Meanwhile ... Changed the map variable cidr_ab.stg from 10.11 to 10.17
tfcoding    | [LOG] Mon Mar 22 00:00:58 UTC 2021 :: Rendered
tfcoding    | {
tfcoding    |   "cidr_ab": "10.17",
tfcoding    |   "private_subnets": [
tfcoding    |     "10.17.0.0/24",
tfcoding    |     "10.17.1.0/24"
tfcoding    |   ]
tfcoding    | }
```

</details>

### Clean

```bash
$ make clean
```

## Mock AWS

This feature relies on the open-source project [localstack](https://github.com/localstack/localstack), which means you can provision the [AWS core resources](https://github.com/localstack/localstack#overview), see [examples/mock-aws/](./examples/mock-aws/)


### Run

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ make up-aws-localstack
```

### terraform destroy

To execute `terraform destroy` on changing `tfcoding.tf`, add the Local Value `terraform_destroy = true`. For example:

```go
// After "destroying" the infra, remove this variable to execute `terraform apply`
locals {
  terraform_destroy = true
}
```

### Clean

```bash
$ make clean-aws
# OR
$ make clean-localstack
# OR
$ make clean-aws-localstack
```

## Clean All

Removes tfcoding, tfcoding-aws and localstack, including orphaned resources.

```bash
$ make clean-all
```

## Help Menu

```bash
$ make help
# OR
$ docker run --rm -it unfor19/tfcoding --help
```

<!-- replacer_start_helpmenu -->

```bash
Usage: bash entrypoint.sh -r basic/exmaples --watching -o private_subnets

	--src_dir_relative_path  |  -r    [REQUIRED]  Relative path to the dir that contains tfcoding.tf
	--single_value_output    |  -o    [all]       Render a single local variable
	--src_dir_root           |  -s    [/src]      Source root dir in container
	--logging                |  -l    [true]      Show logging messages
	--debug                  |  -d    [false]     Print verbose output
	--watching               |  -w    [FLAG]      Auto-render tfcoding.tf on change
	--mock_aws               |  -aws  [FLAG]      Use this flag for communicating with Localstack
```

<!-- replacer_end_helpmenu -->


## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/tfcoding/blob/master/LICENSE) file for details
