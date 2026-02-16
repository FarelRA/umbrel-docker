# Build Phase
FROM alpine:latest AS fetch

# Install minimal tools:
# - curl: For downloading the image
# - libarchive-tools: For streaming unzip
# - sfdisk: For getting partition table
# - jq: For parsing partition table
# - e2fsprogs-extra: For debugfs
RUN apk add --no-cache \
    curl \
    libarchive-tools \
    sfdisk \
    jq \
    e2fsprogs-extra

# 1. Download and stream-unzip directly to disk.img
# 2. Parse partition to selects the single largest partition
# 3. Extract that partition to rootfs.img
# 4. Extract files via debugfs and cleanup
RUN curl -L https://download.umbrel.com/release/latest/umbrelos-pi5.img.zip \
    | bsdtar -xO -f - > disk.img \
    && sfdisk --json disk.img | jq -r ' \
        .partitiontable as $pt | \
        ($pt.partitions \
            | map(select(.type != "5" and .type != "f")) \
            | max_by(.size) \
        ) as $part | \
        "\($part.start) \($part.size) \($pt.sectorsize // 512)"' > part.info \
    && read START SIZE SS < part.info \
    && echo "Extracting Largest Partition: Start=$START, Size=$SIZE, Sector=$SS" \
    && dd if=disk.img of=rootfs.img bs=$SS skip=$START count=$SIZE \
    && rm disk.img \
    && mkdir -p /rootfs \
    && debugfs -R "rdump / /rootfs" rootfs.img \
    && rm rootfs.img part.info \
    && rm -rf /rootfs/dev /rootfs/proc /rootfs/sys /rootfs/run


# Final Phase
FROM scratch

# Copy the rootfs to the final step
COPY --from=fetch /rootfs/ /

STOPSIGNAL SIGRTMIN+3
VOLUME ["/sys/fs/cgroup"]
VOLUME ["/home/umbrel"]
CMD ["/sbin/init"]
