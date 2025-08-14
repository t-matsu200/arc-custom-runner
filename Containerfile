FROM ghcr.io/actions/actions-runner:2.328.0

USER root

RUN apt-get update -y \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -y --no-install-recommends \
      git curl wget ca-certificates unzip jq sshpass openssh-client iptables

# nodejsのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# GihHub CLIのインストール
RUN curl -s https://api.github.com/repos/cli/cli/releases/latest | jq .assets[].browser_download_url | grep linux_amd64.deb | xargs -I '{}' curl -sL -o /tmp/ghcli.deb '{}' \
    && dpkg -i /tmp/ghcli.deb \
    && rm /tmp/ghcli.deb \
    && gh --version

# dumb-initのインストール
ARG DUMB_INIT_VERSION=1.2.5
RUN curl -fLo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/bin/dumb-init

# docker composeのインストール
ARG DOCKER_COMPOSE_VERSION=2.39.2
RUN mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -fLo /usr/libexec/docker/cli-plugins/docker-compose https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose \
    && which docker-compose \
    && docker compose version

# helmのインストール
ARG HELM_VERSION=3.18.5
RUN curl -LO "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
    && tar -xzf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && chmod +x linux-amd64/helm \
    && mv linux-amd64/helm /usr/local/bin/ \
    && helm version \
    && rm -rf linux-amd64 helm-v${HELM_VERSION}-linux-amd64.tar.gz

# kubectlのインストール
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && kubectl version --client

# kustomizeのインストール
ARG KUSTOMIZE_VERSION=5.7.1
RUN curl -LO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && tar -xzf kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && kustomize version

COPY --chown=runner:docker --chmod=755 entrypoint.sh /usr/bin/

USER runner

VOLUME /var/lib/docker

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]
