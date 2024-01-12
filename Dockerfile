ARG PYTHON_VERSION="3.9.18"
ARG ALPINE_VERSION="3.19"
ARG TERRAFORM_VERSION="1.6.6"
ARG HCL2JSON_VERSION="v0.6.0"
ARG FSWATCH_VERSION="1.17.1"
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"

FROM alpine:${ALPINE_VERSION} as download
ARG TERRAFORM_VERSION
ARG HCL2JSON_VERSION
ARG FSWATCH_VERSION

ENV OS_ARCH="amd64"
WORKDIR /downloads/
RUN if [ "$(uname -m)" = "aarch64" ]; then export OS_ARCH=arm64; fi && \
    apk add --no-cache unzip curl && \
    curl -sL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${OS_ARCH}.zip" && \
    unzip terraform.zip && rm terraform.zip && \
    curl -sL -o hcl2json "https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_${OS_ARCH}" && chmod +x hcl2json && \
    mkdir fswatch && cd fswatch && \
    curl -sL -o fswatch.tar.gz "https://github.com/unfor19/fswatch/releases/download/${FSWATCH_VERSION}/fswatch-${FSWATCH_VERSION}-linux-${OS_ARCH}.tar.gz" && \
    tar -xzf fswatch.tar.gz && chmod +x fswatch && rm fswatch.tar.gz
# Output: /downloads/ terraform, hcl2json, fswatch

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} as app
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"

RUN apk add --no-cache bash jq libstdc++ util-linux git openssh-client curl aws-cli && \
    python -m pip install -U pip setuptools wheel && \
    python -m pip install awscli-local terraform-local
COPY --from=download /downloads/terraform /usr/local/bin/terraform
COPY --from=download /downloads/hcl2json /usr/local/bin/hcl2json
COPY --from=download /downloads/fswatch/*.so /usr/local/lib/*.so.* /usr/local/lib/
COPY --from=download /downloads/fswatch/fswatch /usr/local/bin/fswatch
WORKDIR /src/
RUN \
    addgroup -g "${APP_GROUP_ID}" "${APP_GROUP_NAME}" && \
    adduser -H -D -u "$APP_USER_ID" -G "$APP_GROUP_NAME" "$APP_USER_NAME" && \
    chown -R "$APP_USER_ID":"$APP_GROUP_ID" .
USER "$APP_USER_NAME"
COPY . /usr/local/bin/
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
