FROM alpine

ENV ARTILLERY_YAML_FILE=''
ENV REPORT_NAME='artillery-report'
ENV AZURE_STORAGE_CONNECTION_STRING=''

WORKDIR /artillery

COPY ./scripts/ . 

RUN apk add --update nodejs npm && \
    npm install -g artillery && \
    apk update && \
    apk add bash py-pip && \
    apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make && \
    pip --no-cache-dir install -U pip && \
    pip --no-cache-dir install azure-cli && \
    apk del --purge build

ENTRYPOINT ["/bin/ash","run-tests.sh"]