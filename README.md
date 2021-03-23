# tfcoding

[![Push latest version to DockerHub](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml/badge.svg)](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml) [![Dockerhub pulls](https://img.shields.io/docker/pulls/unfor19/tfcoding)](https://hub.docker.com/r/unfor19/tfcoding)

<img alt="tfcoding-logo" src="https://user-images.githubusercontent.com/15122452/111926094-22f28e80-8ab4-11eb-9a72-ca2394d6bb33.png" width="400" />

![tfcoding](https://user-images.githubusercontent.com/15122452/111927698-4caeb400-8aba-11eb-9d80-a19ba48c6e6a.gif)

Render Terraform's [Expressions](https://www.terraform.io/docs/language/expressions/index.html) and [Functions](https://www.terraform.io/docs/language/functions/index.html) locally without any hassle.

This application runs in the background and watches for changes in the file `tfcoding.tf`, once this file is modified its [Local Values](https://www.terraform.io/docs/language/values/locals.html) are automatically rendered to the terminal's output (stdout).

This is especially useful for learning about Expressions and Functions that you are not familiar with, while avoiding the whole shebang of terraform init, plan and apply. The goal here is to "compile Terraform" locally to speed up the development (and learning) process.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- (Optional) [Docker Compose](https://docs.docker.com/compose/install/)

## Usage

The Docker container is a self-contained CLI; to view the help menu, execute the following command:

```bash
$ docker run --rm -it -v "${PWD}"/:/src/:ro \
  unfor19/tfcoding --help
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

### Create the file tfcoding.tf

This file contains the code that will be rendered. Currently supports Variables and Local Values, does not work when referencing to Resources and Modules. The file must stored in a relative directory to `$PWD`.

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

### Render Local Values

#### Docker

Mount the source code directory to `/src/` (read-only) and provide a relative path from `$PWD` to a directory that contains `tfcoding.tf`. The files that will be included in the rendering process are `tfcoding.tf` `*.tpl` and `*.json`.

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ docker run --rm -it -v "${PWD}"/:/src/:ro \
  unfor19/tfcoding --src_dir_relative_path examples/basic --watching

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

#### Docker Compose

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ docker-compose up
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

### Mock AWS

This feature relies on the open-source project [localstack](https://github.com/localstack/localstack), which means you can provision the [AWS core resources](https://github.com/localstack/localstack#overview), see [examples/mock-aws/](./examples/mock-aws/)

#### IMPORTANT

You might encounter the below warning after executing `docker-compose up` - **DO NOT** add the `--remove-orphans` flag

> *WARNING: Found orphan containers (tfcoding, localstack) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.*

Let's go!

```bash
$ git clone https://github.com/unfor19/tfcoding.git
$ cd tfcoding
$ docker-compose -p tfcoding -f docker-compose-localstack.yml up --detached
$ docker-compose -p tfcoding -f docker-compose-aws.yml up
...
# Change something in examples/mock-aws/tfcoding.tf
```

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/tfcoding/blob/master/LICENSE) file for details
