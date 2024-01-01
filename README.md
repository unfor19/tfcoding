# tfcoding

[![Push latest version to DockerHub](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml/badge.svg)](https://github.com/unfor19/tfcoding/actions/workflows/docker-latest.yml) [![Dockerhub pulls](https://img.shields.io/docker/pulls/unfor19/tfcoding)](https://hub.docker.com/r/unfor19/tfcoding)

![tfcoding](https://d33vo9sj4p3nyc.cloudfront.net/tfcoding/tfcoding-localstack-aws.gif)

Render Terraform's [Expressions](https://www.terraform.io/docs/language/expressions/index.html) and [Functions](https://www.terraform.io/docs/language/functions/index.html) locally without any hassle.

This application runs in the background and watches for changes in the file `tfcoding.tf`, once this file is modified its [Local Values](https://www.terraform.io/docs/language/values/locals.html) are automatically rendered to the terminal's output (stdout).

This is especially useful for learning about Expressions and Functions that you are not familiar with, while avoiding the whole shebang of terraform init, plan and apply. The goal here is to "compile Terraform" locally to speed up the development (and learning) process.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- (Optional) [Docker Compose](https://docs.docker.com/compose/install/)
- **Windows**

  - [Windows Git Bash](https://gitforwindows.org/)
  - [Chocolatey Windows Package Manager](https://chocolatey.org/install)

    **IMPORTANT**: Open a PowerShell terminal as Administrator

    ```powershell
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    ```

  - Install requirements

    **IMPORTANT**: Open a PowerShell terminal as Administrator

    ```bash
    choco install -y make
    ```

- **macOS**:
  - [Homebrew macOS Package Manager](https://brew.sh/)
    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
  - Install requirements
    ```bash
    brew install make
    ```

## Quick Start

1. Clone this repo
   ```bash
   git clone https://github.com/unfor19/tfcoding.git
   ```
1. From now on your working direcotry should be `tfcoding`
   ```
   cd tfcoding
   ```
1. Render [examples/basic/tfcoding.tf](./examples/basic/tfcoding.tf) - Make changes in that file, like checking new [Terraform Expressions](https://developer.hashicorp.com/terraform/language/expressions)
   ```
   make run
   ```
1. Clean resources - Removes `tfcoding` container
   ```bash
   make clean
   ```

## Getting Started

This project uses [localstack](https://github.com/localstack/localstack), which means you can provision the [AWS core resources](https://github.com/localstack/localstack#overview), see [examples/mock-aws/](./examples/mock-aws/).

1. Clone this repo
   ```bash
   git clone https://github.com/unfor19/tfcoding.git
   ```
1. From now on your working direcotry should be `tfcoding`
   ```
   cd tfcoding
   ```
1. Render [examples/mock-aws/tfcoding.tf](./examples/mock-aws/tfcoding.tf) - Make changes in that file, like changing the CIDR of subnets
   ```
   make up-aws-localstack
   ```
1. Execute `terraform destroy` on changing `tfcoding.tf`, add the Local Value `terraform_destroy = true`. For example:

   ```go
   // After "destroying" the infra, comment out this variable to execute `terraform apply`
   locals {
     terraform_destroy = true
   }
   ```

1. Clean resources - Removes `tfcoding` and `localstack` containers
   ```bash
   make clean-all
   ```

## Help Menu

```bash
make help
```

With Docker:

```bash
docker run --rm -it unfor19/tfcoding --help
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
