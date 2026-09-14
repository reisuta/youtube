# 動画の実演用イメージ。Node のアプリ（:3000）、nginx のキャッシュ（:8080）、Redis を 1 つのコンテナで動かす。
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends nodejs nginx redis-server curl jq ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default \
 && printf '%s\n' 'PS1="\u@\h:\w\$ "' >> /etc/bash.bashrc
COPY app.js /srv/app.js
COPY nginx.conf /etc/nginx/conf.d/cache.conf
COPY scenario.sh /usr/local/bin/scenario.sh
RUN chmod 755 /usr/local/bin/scenario.sh
WORKDIR /srv
ENTRYPOINT ["/usr/local/bin/scenario.sh"]
