FROM alpine:3.10

# Default configuration
ENV GPTD_GIT_WORKING_BRANCH=master
ENV GPTD_GIT_USER_NAME=githook
ENV GPTD_GIT_USER_EMAIL=auto@commit

# Packages
RUN apk add --no-cache \
        git=2.22.0-r0 \
        openssh=8.0_p1-r0 \
        openrc=0.41.2-r1 \
        su-exec=0.2-r0; \
    chmod u+s /sbin/su-exec

# Ensure www-data user exists
RUN set -eux; \
	addgroup -g 82 -S www-data; \
	adduser -u 82 -D -S -s /bin/sh -G www-data www-data; \
    passwd -d www-data;
# 82 is the standard uid/gid for "www-data" in Alpine

# App location
RUN mkdir /home/repository
WORKDIR /home/repository

# SSHD
# COPY sshd_config /etc/ssh
# RUN rc-update add sshd
# ssh-keygen -A generates all necessary host keys (rsa, dsa, ecdsa, ed25519) at default location.
RUN mkdir /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keygen -A \
    && sed -i s/^#PermitEmptyPasswords\ no/PermitEmptyPasswords\ yes/ /etc/ssh/sshd_config

# Entrypoint and scripts
COPY docker-entrypoint.sh /docker-entrypoint.sh

# Git hooks must be copied to a temporary location
COPY git /home/git-push-to-deploy
RUN chmod +x /docker-entrypoint.sh /home/git-push-to-deploy/hooks/* ; \
    chown -R www-data:www-data /home/git-push-to-deploy

# USER www-data

ENTRYPOINT ["/docker-entrypoint.sh"]

# -D in CMD below prevents sshd from becoming a daemon. -e is to log everything to stderr.
CMD ["/usr/sbin/sshd","-D","-e"]