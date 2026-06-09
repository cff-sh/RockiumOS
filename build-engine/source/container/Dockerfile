FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core ChromiumOS build dependencies
RUN apt-get update && apt-get install -y \
    git \
    git-core \
    python3 \
    curl \
    sudo \
    lsb-release \
    tzdata \
    &>& apt-get clean

# Create a non-root build user matching ChromiumOS requirements
RUN useradd -m -s /bin/bash aegisbuild && echo "aegisbuild ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER aegisbuild
WORKDIR /home/aegisbuild/workspace

# Install Google depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /home/aegisbuild/depot_tools
ENV PATH="/home/aegisbuild/depot_tools:${PATH}"

CMD ["/bin/bash"]