FROM debian

RUN apt-get update -yqq && \
    apt-get install -yqq squashfs-tools rsync ncdu procps && \
    rm -rf /tmp /var/cache /var/lib/apt/lists/*
COPY start.sh /start.sh
COPY sync.sh /sync.sh
RUN chmod +x /start.sh /sync.sh
ENTRYPOINT ["/start.sh"]