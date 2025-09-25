FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Neovim 0.11.4 from GitHub releases (ARM64 for M1/M2 Macs)
RUN wget https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-arm64.tar.gz \
    && tar xzf nvim-linux-arm64.tar.gz \
    && cp -r nvim-linux-arm64/* /usr/local/ \
    && rm -rf nvim-linux-arm64*

# Create test user
RUN useradd -m -s /bin/bash nvimtest
USER nvimtest
WORKDIR /home/nvimtest

# Copy plugin files
COPY --chown=nvimtest:nvimtest . /home/nvimtest/traverse-lsp.nvim/

# Setup minimal Neovim config
RUN mkdir -p /home/nvimtest/.config/nvim \
    && echo 'vim.opt.runtimepath:prepend("/home/nvimtest/traverse-lsp.nvim")' > /home/nvimtest/.config/nvim/init.lua \
    && echo 'require("traverse-lsp").setup({ auto_install = true, auto_start = true })' >> /home/nvimtest/.config/nvim/init.lua

# Copy test fixture for testing
RUN mkdir -p /home/nvimtest/test-project \
    && cp /home/nvimtest/traverse-lsp.nvim/test/fixtures/example.sol /home/nvimtest/test-project/

WORKDIR /home/nvimtest/test-project

CMD ["/bin/bash"]