# minimal, deterministic build for the firewall container
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      iptables iproute2 curl suricata suricata-update conntrack jq && \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /root
CMD ["/usr/local/bin/start.sh"]
