import pulumi
import pulumi_kubernetes as kubernetes

from containers import Containers, InitContainers
import constants

# Get some values from the Pulumi stack configuration, or use defaults
config = pulumi.Config()
k8sNamespace = config.get("namespace", "apps")
numReplicas = config.get_float("replicas", 1)
app_labels = {
    "app": "tfcoding-playground",
}

# Create a namespace
webserverns = kubernetes.core.v1.Namespace(
    "apps",
    metadata=kubernetes.meta.v1.ObjectMetaArgs(
        name=k8sNamespace,
    )
)


tfcoding_playground_deployment = kubernetes.apps.v1.Deployment(
    "tfcoding-playground",
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
                    InitContainers["git"],
                    InitContainers["prepare"]
                ],
                containers=[
                    Containers["tfcoding"],
                    Containers["localstack"],
                    Containers["code-server"],
                ],
                volumes=[
                    kubernetes.core.v1.VolumeArgs(
                        name=constants.WORKDIR_VOLUME_NAME,
                        empty_dir=kubernetes.core.v1.EmptyDirVolumeSourceArgs(),
                    ),
                ],
            ),
        ),
    )
)


codeServerService = kubernetes.core.v1.Service(
    "code-server-service",
    metadata=kubernetes.meta.v1.ObjectMetaArgs(
        namespace=webserverns.metadata.name,
    ),
    spec=kubernetes.core.v1.ServiceSpecArgs(
        type="LoadBalancer",
        ports=[
            kubernetes.core.v1.ServicePortArgs(
                port=8080,
                target_port=8080
            )
        ],
        selector=app_labels
    )
)

pulumi.export("namespace", webserverns.metadata.name)
pulumi.export("code-server-service", codeServerService.metadata.name)
pulumi.export("deploymentName", tfcoding_playground_deployment.metadata.name)
