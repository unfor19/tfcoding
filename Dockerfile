ARG PYTHON_VERSION="3.9.18"
ARG OS_ARCH="amd64"
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
ARG OS_ARCH

WORKDIR /downloads/
RUN apk add --no-cache unzip curl
RUN curl -sL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${OS_ARCH}.zip"
RUN unzip terraform.zip && rm terraform.zip
RUN curl -sL -o hcl2json "https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_${OS_ARCH}" && chmod +x hcl2json
RUN curl -sL -o fswatch.tar.gz "https://github.com/emcrisostomo/fswatch/releases/download/${FSWATCH_VERSION}/fswatch-${FSWATCH_VERSION}.tar.gz"
RUN tar -xzf fswatch.tar.gz && mv "fswatch-${FSWATCH_VERSION}" fswatch && rm fswatch.tar.gz
# Output: /downloads/ terraform, hcl2json, fswatch


FROM alpine:${ALPINE_VERSION} as build-fswatch
RUN apk add --no-cache file git autoconf automake libtool make g++ texinfo curl
ENV ROOT_HOME /root
WORKDIR ${ROOT_HOME}
COPY --from=download /downloads/fswatch .
RUN ./configure && make -j
RUN make install
# Output: /usr/local/bin/fswatch, /usr/local/lib/*.so, /usr/local/lib/*.so.*


FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION} as app
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"

RUN apk add --no-cache bash jq libstdc++ util-linux git openssh-client curl aws-cli
RUN python -m pip install -U pip setuptools wheel && \
    python -m pip install awscli-local terraform-local
COPY --from=download /downloads/terraform /usr/local/bin/terraform
COPY --from=download /downloads/hcl2json /usr/local/bin/hcl2json
COPY --from=build-fswatch /usr/local/lib/*.so /usr/local/lib/*.so.* /usr/local/lib/
COPY --from=build-fswatch /usr/local/bin/fswatch /usr/local/bin/fswatch
WORKDIR /src/
RUN \
    addgroup -g "${APP_GROUP_ID}" "${APP_GROUP_NAME}" && \
    adduser -H -D -u "$APP_USER_ID" -G "$APP_GROUP_NAME" "$APP_USER_NAME" && \
    chown -R "$APP_USER_ID":"$APP_GROUP_ID" .
USER "$APP_USER_NAME"
COPY . /usr/local/bin/
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
