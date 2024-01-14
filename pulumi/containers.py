import pulumi_kubernetes as kubernetes
import constants


InitContainers = {
    "git": kubernetes.core.v1.ContainerArgs(
        working_dir=constants.ROOT_DIR,
        image="unfor19/tfcoding:latest",
        name="git",
        command=["git", "clone"],
        args=["https://github.com/unfor19/tfcoding.git"],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                name=constants.WORKDIR_VOLUME_NAME,
                mount_path=constants.ROOT_DIR,
                read_only=False,
            )
        ],
    ),
    "prepare": kubernetes.core.v1.ContainerArgs(
        image="unfor19/tfcoding:latest",
        working_dir=constants.WORKDIR_PATH,
        name="prepare",
        command=["bash", "-c"],
        args=[
            "git checkout feature/kubernetes && \
            chmod +x localstack/healthcheck-init.sh"
        ],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                name=constants.WORKDIR_VOLUME_NAME,
                mount_path=constants.WORKDIR_PATH,
                read_only=False,
                sub_path="tfcoding"
            )
        ],
        restart_policy="Always",
    )
}

Containers = {
    "localstack": kubernetes.core.v1.ContainerArgs(
        image="localstack/localstack:latest",
        name="localstack",
        env=[kubernetes.core.v1.EnvVarArgs(
            name="LS_LOG",
            value="error"
        )],
        ports=[
            kubernetes.core.v1.ContainerPortArgs(
                container_port=4566,
            ),
            kubernetes.core.v1.ContainerPortArgs(
                container_port=4571,
            )
        ],
        readiness_probe=kubernetes.core.v1.ProbeArgs(
            exec_=kubernetes.core.v1.ExecActionArgs(
                command=[
                    "/bin/bash", "-c", "curl -s http://localhost:4566/_localstack/init/ready | jq -r .completed==true || exit 1"
                ],
            ),
            initial_delay_seconds=5,
            period_seconds=5,
        ),
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                mount_path="/etc/localstack/init/ready.d/healthcheck-init.sh",
                name=constants.WORKDIR_VOLUME_NAME,
                read_only=False,
                sub_path=f"tfcoding/localstack/healthcheck-init.sh",
            )
        ],
    ),
    "tfcoding": kubernetes.core.v1.ContainerArgs(
        image="unfor19/tfcoding:latest",
        security_context=kubernetes.core.v1.SecurityContextArgs(
            run_as_user=1000,  # appuser
            capabilities=kubernetes.core.v1.CapabilitiesArgs(
                drop=["all"]
            )
        ),
        name="tfcoding",
        env=[
            kubernetes.core.v1.EnvVarArgs(
                name="AWS_REGION",
                value="us-east-1"
            ),
            kubernetes.core.v1.EnvVarArgs(
                name="AWS_DEFAULT_REGION",
                value="us-east-1"
            )
        ],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                mount_path="/src",
                name=constants.WORKDIR_VOLUME_NAME,
                read_only=False,
                sub_path="tfcoding",
            )
        ],
        args=[
            "--src_dir_relative_path",
            "examples/mock-aws-pulumi",
            "--watching",
            "--mock_aws"]
    ),
    "code-server": kubernetes.core.v1.ContainerArgs(
        name="code-server",
        working_dir="/home/coder/project",
        image="codercom/code-server:latest",
        security_context=kubernetes.core.v1.SecurityContextArgs(
            run_as_user=1000,  # appuser
            capabilities=kubernetes.core.v1.CapabilitiesArgs(
                drop=["all"]
            )
        ),
        ports=[
            kubernetes.core.v1.ContainerPortArgs(
                container_port=8080,
            )
        ],
        args=[
            "--app-name",
            "tfcoding-playground",
            "--auth",
            "none",
        ],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                mount_path="/home/coder/project",
                name=constants.WORKDIR_VOLUME_NAME,
                read_only=False,
                sub_path="tfcoding/examples/mock-aws-pulumi",
            )
        ],
    ),
    "loki": kubernetes.core.v1.ContainerArgs(
        name="loki",
        image="grafana/loki:latest",
        args=[
            "-config.file=/etc/loki/local-config.yaml"
        ],
        ports=[
            kubernetes.core.v1.ContainerPortArgs(
                container_port=3100,
            )
        ],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                name="loki-volume",
                mount_path="/etc/loki",
                read_only=True
            )
        ]
    ),
    "promtail": kubernetes.core.v1.ContainerArgs(
        name="promtail",
        image="grafana/promtail:latest",
        args=[
            "-config.file=/etc/promtail/config.yaml"
        ],
        volume_mounts=[
            kubernetes.core.v1.VolumeMountArgs(
                name="promtail-volume",
                mount_path="/etc/promtail",
                read_only=True
            )
        ]
    )
}
