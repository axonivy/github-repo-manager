FROM maven:3.9.16-eclipse-temurin-25

RUN apt update && \
    apt install curl git gettext-base unzip gh ssh wget rsync libatomic1 -y && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=26.13.0

# Install node and npm with nvm
RUN mkdir $NVM_DIR && \
    curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    npm install -g pnpm@12

ENV NODE_PATH=$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
