# ---- Base ------------------------------------------------------------------------------------------------------------
FROM ubuntu:22.04

# Avoid interactive tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Common tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip git \
    build-essential \
    python3 python3-pip \
    openjdk-17-jdk \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ---- PlatformIO (ESP32 / Arduino) -----------------------------------------------------------------------------------
# PlatformIO CLI for building sketches in ESP32/Arduino* folders.
RUN pip3 install --no-cache-dir platformio

# Pre-pull popular platforms/toolchains (optional but speeds up CI on first run)
# Comment out if you want a slimmer image.
RUN pio pkg update && \
    pio pkg install -g \
      platformio/tool-scons@>=4.4.0 \
      platformio/framework-arduinoespressif32@~3

# ---- Android SDK + Build tools ---------------------------------------------------------------------------------------
ARG ANDROID_SDK_VERSION=11076708      # commandlinetools-linux latest-ish
ARG ANDROID_API_LEVEL=33
ARG ANDROID_BUILD_TOOLS=33.0.2

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/tools/bin:$PATH

RUN mkdir -p /opt && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    cd /opt && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip -O cmdline.zip && \
    unzip -q cmdline.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm cmdline.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

# Accept licenses & install required packages
RUN yes | sdkmanager --licenses >/dev/null && \
    sdkmanager "platform-tools" \
               "platforms;android-${ANDROID_API_LEVEL}" \
               "build-tools;${ANDROID_BUILD_TOOLS}" \
               "cmdline-tools;latest"

# Gradle (optional—most Android projects use the wrapper; keep for convenience)
ARG GRADLE_VERSION=8.7
RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -O /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && rm /tmp/gradle.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle

# ---- Non-root user for safer CI --------------------------------------------------------------------------------------
RUN useradd -ms /bin/bash builder
USER builder
WORKDIR /workspace

# Helpful env for Java/Gradle builds
ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport"

# ---- Usage hints (kept as comments) ----------------------------------------------------------------------------------
# Build Android (inside Jenkins stage):
#   cd Android && ./gradlew assembleDebug
#
# Build ESP32/Arduino with PlatformIO:
#   cd ESP32   && pio run
#   cd ArduinoNano33 && pio run
#
# You can mount the repo into /workspace:
#   docker run --rm -it -v "$PWD":/workspace <image> bash

# Default command
CMD [ "bash" ]

