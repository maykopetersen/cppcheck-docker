ARG BASE_IMAGE=ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive
FROM ${BASE_IMAGE} as builder

WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential=12.10ubuntu1 \
      ca-certificates=20240203 \
      cmake=3.28.3-1build7 \
      git=1:2.43.0-1ubuntu7.3 \
      python3=3.12.3-0ubuntu2.1 \
      libpcre3-dev=2:8.39-15build1 \
      libboost-dev=1.83.0.1ubuntu2 \
      && rm -rf /var/lib/apt/lists/*

RUN git clone \
      --single-branch \
      --branch 2.21.x \
      --depth 1 \
      https://github.com/cppcheck-opensource/cppcheck.git .

RUN cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DHAVE_RULES=ON \
      -DBUILD_TESTING=ON \
      -DUSE_MATCHCOMPILER=ON \
      -DFILESDIR=/usr/share/cppcheck && \
      cmake --build build -j"$(nproc)"

FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.authors="Mayko Petersen de Freitas"
ARG BUILD_DIR="/opt/build-dir"
ARG WORKSPACE_DIR="/workspace"

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcre3=2:8.39-15build1 \
    python3=3.12.3-0ubuntu2.1 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir ${BUILD_DIR} ${WORKSPACE_DIR} \
    && chown 1000 ${BUILD_DIR} ${WORKSPACE_DIR}

COPY --from=builder /src/build/bin/cppcheck /usr/bin/cppcheck
COPY --from=builder /src/cfg /usr/share/cppcheck/cfg
COPY --from=builder /src/addons /usr/share/cppcheck/addons
COPY --from=builder /src/platforms /usr/share/cppcheck/platform

USER 1000

WORKDIR ${WORKSPACE_DIR}
ENTRYPOINT ["cppcheck"]
