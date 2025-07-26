# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    wget \
    gnupg \
    ca-certificates \
    build-essential \
    openjdk-11-jdk \
    unzip \
    python3 \
    python3-pip \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18 (LTS) and npm
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Note: Removed JavaScriptCore dependencies since we're only using Hermes and V8

# Create symlinks for ICU version compatibility
RUN cd /usr/lib/x86_64-linux-gnu && \
    ln -sf libicudata.so.70 libicudata.so.73 && \
    ln -sf libicui18n.so.70 libicui18n.so.73 && \
    ln -sf libicuuc.so.70 libicuuc.so.73

# Install Bazel 7.4.1 (specific version required by perses)
RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > /usr/share/keyrings/bazel-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list && \
    apt-get update && \
    apt-get install -y bazel-7.4.1 && \
    ln -sf /usr/bin/bazel-7.4.1 /usr/bin/bazel && \
    rm -rf /var/lib/apt/lists/*

# Install jsvu globally
RUN npm install -g jsvu

# Set up jsvu for x64 and install Hermes, V8, and GraalJS
RUN jsvu --os=linux64 --engines=hermes && \
    jsvu --os=linux64 --engines=v8 && \
    jsvu --os=linux64 --engines=graaljs

# Create symlinks for easier access to JavaScript engines
RUN ln -sf ~/.jsvu/engines/v8/v8 ~/.jsvu/bin/v8 && \
    ln -sf ~/.jsvu/engines/graaljs/graaljs-24.2.2-linux-amd64/bin/js ~/.jsvu/bin/graaljs && \
    echo 'export PATH="$HOME/.jsvu/bin:$PATH"' >> ~/.bashrc

# Clone the perses repository
RUN git clone https://github.com/srina1h/perses.git /perses

# Build the required JAR files with Bazel
WORKDIR /perses
RUN bazel build kitten/src/org/perses/fuzzer:kitten_deploy.jar \
    && bazel build kitten/src/org/perses/fuzzer/organizer:kitten_organizer_deploy.jar \
    && cp bazel-bin/kitten/src/org/perses/fuzzer/kitten_deploy.jar . \
    && cp bazel-bin/kitten/src/org/perses/fuzzer/organizer/kitten_organizer_deploy.jar .

# Generate the JavaScript config file
RUN chmod +x kitten/scripts/javascript/generate-config.sh \
    && kitten/scripts/javascript/generate-config.sh

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Default command
ENTRYPOINT ["/startup.sh"] 