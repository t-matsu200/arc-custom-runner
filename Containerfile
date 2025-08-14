FROM ghcr.io/actions/actions-runner:2.328.0

USER root

# TARGETARCH is a build-time argument provided by buildx.
# It can be amd64, arm64, etc.
# We declare it here so it can be used in subsequent RUN commands.
ARG TARGETARCH=amd64

RUN apt-get update -y \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -y --no-install-recommends \
      git curl wget ca-certificates unzip jq sshpass openssh-client iptables nodejs

# GihHub CLIのインストール
RUN apt-get update \
    && GH_DEB_URL=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | jq -r ".assets[] | select(.name | endswith(\"linux_${TARGETARCH}.deb\")) | .browser_download_url") \
    && curl -fsSL -o /tmp/ghcli.deb "${GH_DEB_URL}" \
    && apt-get install -y /tmp/ghcli.deb \
    && rm -f /tmp/ghcli.deb \
    && rm -rf /var/lib/apt/lists/* \
    && gh --version

# dumb-initのインストール
ARG DUMB_INIT_VERSION=1.2.5
RUN case ${TARGETARCH} in \
      amd64) DUMB_INIT_ARCH="x86_64";; \
      arm64) DUMB_INIT_ARCH="aarch64";; \
    esac \
    && curl -fLo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_${DUMB_INIT_ARCH} \
    && chmod +x /usr/bin/dumb-init

# docker composeのインストール
ARG DOCKER_COMPOSE_VERSION=2.39.2
RUN case ${TARGETARCH} in \
      amd64) COMPOSE_ARCH="x86_64";; \
      arm64) COMPOSE_ARCH="aarch64";; \
    esac \
    && mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -fLo /usr/libexec/docker/cli-plugins/docker-compose https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH} \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose \
    && which docker-compose \
    && docker compose version

# helmのインストール
ARG HELM_VERSION=3.18.5
RUN curl -LO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && tar -xzf "helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    && chmod +x "linux-${TARGETARCH}/helm" \
    && mv "linux-${TARGETARCH}/helm" /usr/local/bin/ \
    && helm version \
    && rm -rf "linux-${TARGETARCH}" "helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz"

# kubectlのインストール
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && kubectl version --client

# kustomizeのインストール
ARG KUSTOMIZE_VERSION=5.7.1
RUN curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz" \
    && tar -xzf "kustomize_v${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz" \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm "kustomize_v${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz" \
    && kustomize version

COPY --chown=runner:docker --chmod=755 entrypoint.sh /usr/bin/

USER runner

VOLUME /var/lib/docker

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]
