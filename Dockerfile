FROM debian:buster-slim AS debian-plus

ENV NGINX_PLUS_VERSION 23-1~buster
ENV NGINX_NJS_VERSION 23+0.5.0-1~buster

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

RUN --mount=type=secret,id=nginx-repo.crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
    --mount=type=secret,id=nginx-repo.key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
    set -x \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y ca-certificates gnupg wget \
    && wget https://nginx.org/keys/nginx_signing.key \
    && gpg --no-default-keyring --keyring nginx_keyring.gpg --import nginx_signing.key \
    && gpg --no-default-keyring --keyring nginx_keyring.gpg --export > /etc/apt/trusted.gpg.d/nginx_signing.gpg \
    && echo "Acquire::https::plus-pkgs.nginx.com::Verify-Peer \"true\";" >> /etc/apt/apt.conf.d/90nginx \
    && echo "Acquire::https::plus-pkgs.nginx.com::Verify-Host \"true\";" >> /etc/apt/apt.conf.d/90nginx \
    && echo "Acquire::https::plus-pkgs.nginx.com::SslCert     \"/etc/ssl/nginx/nginx-repo.crt\";" >> /etc/apt/apt.conf.d/90nginx \
    && echo "Acquire::https::plus-pkgs.nginx.com::SslKey      \"/etc/ssl/nginx/nginx-repo.key\";" >> /etc/apt/apt.conf.d/90nginx \
    && printf "deb https://plus-pkgs.nginx.com/debian buster nginx-plus\n" > /etc/apt/sources.list.d/nginx-plus.list \
    && apt-get update && apt-get install --no-install-recommends --no-install-suggests -y \
    apt-transport-https libcap2-bin nginx-plus=${NGINX_PLUS_VERSION} nginx-plus-module-njs=${NGINX_NJS_VERSION}

# Install NIM Agent
RUN --mount=type=secret,id=nginx-repo.crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
    --mount=type=secret,id=nginx-repo.key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
    set -x \
    && printf "deb https://pkgs.nginx.com/instance-manager/debian stable nginx-plus\n" > /etc/apt/sources.list.d/instance-manager.list \
    && wget -q -O /etc/apt/apt.conf.d/90pkgs-nginx https://cs.nginx.com/static/files/90pkgs-nginx \
    && apt-get clean \
    && apt-get update \
    && apt-get install -y nginx-agent \
    && apt-get purge --auto-remove -y apt-transport-https gnupg wget \
    && rm -rf /var/lib/apt/lists/* 

COPY nginx-agent.conf /etc/nginx-agent/nginx-agent.conf

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

STOPSIGNAL SIGTERM

# CMD ["nginx", "-g", "daemon off;"]
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]