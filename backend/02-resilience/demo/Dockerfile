# 動画の実演用イメージ。不安定な上流 API（:4000）と、タイムアウト・リトライ・冪等性・プール・fd の実演スクリプト。
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends nodejs curl jq ca-certificates lsof \
 && rm -rf /var/lib/apt/lists/* \
 && printf '%s\n' 'PS1="\u@\h:\w\$ "' >> /etc/bash.bashrc
COPY upstream.js retry.js pool.js fdtest.js /srv/
COPY scenario.sh /usr/local/bin/scenario.sh
RUN chmod 755 /usr/local/bin/scenario.sh
WORKDIR /srv
ENTRYPOINT ["/usr/local/bin/scenario.sh"]
