ARG BASE_VERSION=3.16.2

FROM alpine:${BASE_VERSION} AS base
  # hadolint ignore=DL3018
  RUN set -ex \
   && apk add --no-cache bash curl git make parallel openssh ncurses \
   && git config --global --add safe.directory /app

  ENV BATS_LIB_PATH=/opt/bats

  WORKDIR /app

FROM base AS build
  # https://github.com/bats-core/bats-core/releases/latest
  ARG BATS_CORE_VERSION=1.8.0
  # https://github.com/ztombol/bats-support/releases/latest
  ARG BATS_SUPPORT_VERSION=0.3.0
  # https://github.com/ztombol/bats-assert/releases/latest
  ARG BATS_ASSERT_VERSION=0.3.0
  # https://github.com/ztombol/bats-file/releases/latest
  ARG BATS_FILE_VERSION=0.2.0

  SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

  WORKDIR /opt/bats

  RUN set -ex \
   && curl -fsSL https://github.com/bats-core/bats-core/archive/v${BATS_CORE_VERSION}.tar.gz | tar xzv \
   && curl -fsSL https://github.com/ztombol/bats-support/archive/v${BATS_SUPPORT_VERSION}.tar.gz | tar xzv \
   && curl -fsSL https://github.com/ztombol/bats-assert/archive/v${BATS_ASSERT_VERSION}.tar.gz | tar xzv \
   && curl -fsSL https://github.com/ztombol/bats-file/archive/v${BATS_FILE_VERSION}.tar.gz | tar xzv

  RUN set -ex \
   && mv bats-core-* bats-core \
   && mv bats-support-* bats-support \
   && mv bats-assert-* bats-assert \
   && mv bats-file-* bats-file

FROM base
  COPY --from=build /opt/bats /opt/bats

  RUN set -ex \
   && ln -s "${BATS_LIB_PATH}/bats-core/bin/bats" /usr/local/bin/bats \
   && mkdir -p ~/.ssh \
   && ssh-keyscan github.com >> ~/.ssh/known_hosts

  ENTRYPOINT ["/usr/local/bin/bats"]
  CMD ["--help"]
