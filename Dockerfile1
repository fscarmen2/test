FROM alpine

ENV DIR=/unlock

WORKDIR $DIR

RUN apk add --no-cache wireguard-tools curl \
 && rm -rf /var/cache/apk/* \
 && arch=$(arch | sed s/aarch64/armv8/ | sed s/x86_64/amd64/) \
 && latest=$(curl -sSL "https://api.github.com/repos/ginuerzh/gost/releases/latest" | grep "tag_name" | head -n 1 | cut -d : -f2 | sed 's/[ \"v,]//g') \
 && wget -O gost.gz https://github.com/ginuerzh/gost/releases/download/v$latest/gost-linux-"$arch"-"$latest".gz \
 && gzip -d gost.gz \
 && echo -e "wg-quick up wgcf\n./gost -L :40000" > run.sh \
 && chmod +x gost run.sh

ENTRYPOINT ./run.sh
