FROM mcr.microsoft.com/devcontainers/base:${templateOption:imageVariant}

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
