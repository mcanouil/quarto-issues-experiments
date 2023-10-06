#!/usr/bin/env bash

# For Quarto latest dev version
apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends xz-utils \
  && cd / \
  && git clone https://github.com/quarto-dev/quarto-cli.git \
  && cd quarto-cli \
  && ./configure.sh \
  && apt-get clean -y && rm -rf /var/lib/apt/lists/*


quarto create project website demo

echo -e '{\n"quarto.render.renderOnSave": true\n}' > .vscode/settings.json
