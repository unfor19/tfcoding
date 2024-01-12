## Requirements

```bash
brew install minikube pulumi/tap/pulumi
```

## Getting Started

```bash
minikube start --driver=docker --kubernetes-version=v1.28.5
```

```bash
pulumi login
```

```bash
pulumi up
```

```bash
pulumi refresh
```

```bash
pulumi destroy
```

Forces cancel deployment - Resolves 409 errors

```bash
pulumi cancel -y
```
