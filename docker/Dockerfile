FROM --platform=linux/amd64 ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Build configuration
ENV THREADS=8
ENV API=21
ENV WORKDIR=/opt/android
ENV NDK_VERSION=r25c
ENV ANDROID_NDK_ROOT=/opt/android/android-ndk-${NDK_VERSION}
ENV ANDROID_NDK_HOME=${ANDROID_NDK_ROOT}
ENV ANDROID_SDK_ROOT=/opt/android/sdk
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="${FLUTTER_ROOT}/bin:${PATH}"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    automake \
    build-essential \
    file \
    pkg-config \
    git \
    python3 \
    python-is-python3 \
    libtool \
    cmake \
    openjdk-17-jdk \
    curl \
    wget \
    clang \
    ninja-build \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME based on architecture
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        ln -sf /usr/lib/jvm/java-17-openjdk-arm64 /usr/lib/jvm/java-17-openjdk; \
    else \
        ln -sf /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/java-17-openjdk; \
    fi
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Create working directory
RUN mkdir -p ${WORKDIR}
WORKDIR ${WORKDIR}

# Download and install Android NDK r25c (Linux package is x86_64; we pin the image platform to linux/amd64 above)
RUN wget -q https://dl.google.com/android/repository/android-ndk-r25c-linux.zip -O ndk.zip && \
    unzip -q ndk.zip -d ${WORKDIR} && \
    rm ndk.zip

# Install Android SDK command line tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm cmdline-tools.zip

# Setup PATH for Android tools
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

# Accept licenses and install Android SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager "platforms;android-29" "build-tools;29.0.3"

# Download and install Flutter SDK
RUN wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_2.10.5-stable.tar.xz -O flutter.tar.xz && \
    tar xf flutter.tar.xz -C /opt && \
    rm flutter.tar.xz

# Set working directory for the project
WORKDIR /opt/android/cake_wallet
