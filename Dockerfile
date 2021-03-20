ARG ALPINE_VERSION="3.13"
ARG TERRAFORM_VERSION="0.13.5"
ARG HCL2JSON_VERSION="v0.3.2"
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"

FROM alpine:${ALPINE_VERSION} as download
ARG TERRAFORM_VERSION
ARG HCL2JSON_VERSION

WORKDIR /downloads/
RUN apk add --no-cache unzip curl
RUN curl -sL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
RUN unzip terraform.zip && rm terraform.zip
RUN curl -sL -o hcl2json "https://github.com/tmccombs/hcl2json/releases/download/${HCL2JSON_VERSION}/hcl2json_linux_amd64" && chmod +x hcl2json


FROM alpine:${ALPINE_VERSION} as app
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"

RUN apk add --no-cache bash jq perl
COPY --from=download /downloads/terraform /usr/local/bin/terraform
COPY --from=download /downloads/hcl2json /usr/local/bin/hcl2json

WORKDIR /code/
RUN \
    addgroup -g "${APP_GROUP_ID}" "${APP_GROUP_NAME}" && \
    adduser -H -D -u "$APP_USER_ID" -G "$APP_GROUP_NAME" "$APP_USER_NAME" && \
    chown -R "$APP_USER_ID":"$APP_GROUP_ID" .
USER "$APP_USER_NAME"

COPY entrypoint.sh .
ENTRYPOINT ["bash", "/code/entrypoint.sh"]
