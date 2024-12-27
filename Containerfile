FROM ghcr.io/actions/actions-runner:2.321.0

USER root

RUN apt-get update -y \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get install -y --no-install-recommends git curl wget ca-certificates unzip jq sshpass openssh-client iptables \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# docker composeのインストール
ARG DOCKER_COMPOSE_VERSION=v2.32.0
RUN mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -fLo /usr/libexec/docker/cli-plugins/docker-compose https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64 \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose \
    && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose \
    && which docker-compose \
    && docker compose version

# kubectlのインストール
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/ \
    && kubectl version --client

# kustomizeのインストール
ARG KUSTOMIZE_VERSION=5.5.0
RUN curl -LO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && tar -xzf kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && chmod +x kustomize \
    && mv kustomize /usr/local/bin/ \
    && rm kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    && kustomize version

# dumb-initのインストール
ARG DUMB_INIT_VERSION=1.2.5
RUN curl -fLo /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
    && chmod +x /usr/bin/dumb-init

COPY --chown=runner:docker --chmod=755 entrypoint.sh /usr/bin/

USER runner

VOLUME /var/lib/docker

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["entrypoint.sh"]
