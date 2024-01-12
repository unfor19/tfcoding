import pulumi
import pulumi_kubernetes as kubernetes

# Get some values from the Pulumi stack configuration, or use defaults
config = pulumi.Config()
k8sNamespace = config.get("namespace", "apps")
numReplicas = config.get_float("replicas", 1)
app_labels = {
    "app": "tfcoding",
}

# Create a namespace
webserverns = kubernetes.core.v1.Namespace(
    "apps",
    metadata=kubernetes.meta.v1.ObjectMetaArgs(
        name=k8sNamespace,
    )
)

rootPath = "/home/appuser"
workdirPath = f"{rootPath}/tfcoding"

webserverdeployment = kubernetes.apps.v1.Deployment(
    "webserverdeployment",
    metadata=kubernetes.meta.v1.ObjectMetaArgs(
        namespace=webserverns.metadata.name,
    ),
    spec=kubernetes.apps.v1.DeploymentSpecArgs(
        selector=kubernetes.meta.v1.LabelSelectorArgs(
            match_labels=app_labels,
        ),
        replicas=numReplicas,
        template=kubernetes.core.v1.PodTemplateSpecArgs(
            metadata=kubernetes.meta.v1.ObjectMetaArgs(
                labels=app_labels,
            ),
            spec=kubernetes.core.v1.PodSpecArgs(
                init_containers=[
                    kubernetes.core.v1.ContainerArgs(
                        working_dir=rootPath,
                        image="unfor19/tfcoding:latest",
                        name="git",
                        command=["git", "clone"],
                        args=["https://github.com/unfor19/tfcoding.git"],
                        volume_mounts=[
                            kubernetes.core.v1.VolumeMountArgs(
                                name="workdir-volume",
                                mount_path=rootPath,
                                read_only=False,
                            )
                        ],
                    ),
                    kubernetes.core.v1.ContainerArgs(
                        image="unfor19/tfcoding:latest",
                        working_dir=workdirPath,
                        name="prepare",
                        command=["bash", "-c"],
                        args=[
                            "git checkout feature/kubernetes && \
                                chmod +x localstack/healthcheck-init.sh"
                        ],
                        volume_mounts=[
                            kubernetes.core.v1.VolumeMountArgs(
                                name="workdir-volume",
                                mount_path=workdirPath,
                                read_only=False,
                                sub_path="tfcoding"
                            )
                        ],
                        restart_policy="Always",
                    )
                ],
                containers=[
                    kubernetes.core.v1.ContainerArgs(
                        image="unfor19/tfcoding:latest",
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
                                name="workdir-volume",
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
                    kubernetes.core.v1.ContainerArgs(
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
                                name="workdir-volume",
                                read_only=False,
                                sub_path=f"tfcoding/localstack/healthcheck-init.sh",
                            )
                        ],
                    )
                ],
                volumes=[
                    kubernetes.core.v1.VolumeArgs(
                        empty_dir=kubernetes.core.v1.EmptyDirVolumeSourceArgs(),
                        name="workdir-volume",
                    ),
                ],
            ),
        ),
    )
)

pulumi.export("deploymentName", webserverdeployment.metadata.name)
