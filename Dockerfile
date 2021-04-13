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
    apt-transport-https libcap2-bin nginx-plus=${NGINX_PLUS_VERSION} nginx-plus-module-njs=${NGINX_NJS_VERSION} \
    && apt-get purge --auto-remove -y apt-transport-https gnupg wget \
    && rm -rf /var/lib/apt/lists/*

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# FROM alpine:3.11

# LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

# Define NGINX versions for NGINX Plus and NGINX Plus modules
# Uncomment this block and the versioned nginxPackages in the main RUN
# instruction to install a specific release
# ENV NGINX_VERSION 21
# ENV NJS_VERSION   0.3.9
# ENV PKG_RELEASE   1

# RUN --mount=type=secret,id=nginx-repo.crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
#     --mount=type=secret,id=nginx-repo.key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
#     set -x \
#     && addgroup -g 101 -S nginx \
#     && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
#     && nginxPackages="nginx-plus" \
#     KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin" \
#     && apk add --no-cache --virtual .cert-deps \
#     openssl \
#     && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
#     && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then \
#     echo "key verification succeeded!"; \
#     mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
#     else \
#     echo "key verification failed!"; \
#     exit 1; \
#     fi \
#     && apk del .cert-deps \
#     && apk add -X "https://plus-pkgs.nginx.com/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
#     && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
#     && if [ -n "/etc/apk/cert.key" && -n "/etc/apk/cert.pem"]; then rm -f /etc/apk/cert.key /etc/apk/cert.pem; fi \
#     # Bring in gettext so we can get `envsubst`, then throw
#     # the rest away. To do this, we need to install `gettext`
#     # then move `envsubst` out of the way so `gettext` can
#     # be deleted completely, then move `envsubst` back.
#     && apk add --no-cache --virtual .gettext gettext \
#     && mv /usr/bin/envsubst /tmp/ \
#     \
#     && runDeps="$( \
#     scanelf --needed --nobanner /tmp/envsubst \
#     | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
#     | sort -u \
#     | xargs -r apk info --installed \
#     | sort -u \
#     )" \
#     && apk add --no-cache $runDeps \
#     && apk del .gettext \
#     && mv /tmp/envsubst /usr/local/bin/ \
#     # Bring in tzdata so users could set the timezones through the environment
#     # variables
#     && apk add --no-cache tzdata \
#     # Bring in curl and ca-certificates to make registering on DNS SD easier
#     && apk add --no-cache curl ca-certificates \
#     # Forward request and error logs to Docker log collector
#     && ln -sf /dev/stdout /var/log/nginx/access.log \
#     && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]