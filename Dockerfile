FROM docker.io/library/ubuntu:22.04 as BUILDER

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /hashcat

RUN apt update && \
    apt install --yes --no-install-recommends \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN make install -j4


FROM docker.io/library/ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PATH=/usr/local/nvidia/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

LABEL com.nvidia.volumes.needed="nvidia_driver"

RUN apt update && \
    apt install --yes --no-install-recommends \
    ca-certificates \
    ocl-icd-libopencl1 \
    opencl-headers \
    clinfo \
    pciutils \
    pkg-config \
    gpg \
    gcc \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    rm cuda-keyring_1.0-1_all.deb

RUN apt update && \
    apt install --yes --no-install-recommends \
    cuda-toolkit && \
    rm -rf /var/lib/apt/lists/*

RUN update-pciids && \
    groupadd --gid 1000 hashcat && \
    useradd --uid 1000 --gid 1000 -m hashcat && \
    mkdir -p \
    /home/hashcat/.cache/hashcat \
    /home/hashcat/.local/share/hashcat \
    /home/hashcat/.nv/ComputeCache && \
    chown -R hashcat:hashcat /home/hashcat

COPY --from=BUILDER /usr/local/bin/hashcat   /usr/local/bin/hashcat
COPY --from=BUILDER /usr/local/share/doc     /usr/local/share/doc
COPY --from=BUILDER /usr/local/share/hashcat /usr/local/share/hashcat

USER hashcat:hashcat

VOLUME [ "/home/hashcat/.cache/hashcat", "/home/hashcat/.local/share/hashcat", "/home/hashcat/.nv/ComputeCache" ]

ENTRYPOINT [ "hashcat" ]
