# Builder stage
FROM debian:bookworm-slim AS builder

ENV GOSU_VERSION=1.17
ENV TINI_VERSION=v0.19.0
ENV MONGO_TOOLS_VERSION=100.10.0
ENV POSTGRESQL_VERSION=16
ENV MONGO_DEBIAN_VERSION=debian12
ENV MONGO_UBUNTU_VERSION=ubuntu2404
ENV TZ=Asia/Seoul

RUN set -eux; \
    # Save list of currently installed packages for later cleanup
        savedAptMark="$(apt-mark showmanual)"; \
        apt-get update; \
        apt-get install -y --no-install-recommends ca-certificates gnupg wget; \
        rm -rf /var/lib/apt/lists/*; \
        \
    # Install gosu
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
            wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
            wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
        export GNUPGHOME="$(mktemp -d)"; \
            gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
            gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
            gpgconf --kill all; \
            rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
        chmod +x /usr/local/bin/gosu; \
        gosu --version; \
            gosu nobody true; \
        \
    # Install Tini
        : "${TINI_VERSION:?TINI_VERSION is not set}"; \
        dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
            echo "Downloading Tini version ${TINI_VERSION} for architecture ${dpkgArch}"; \
            wget -O /usr/bin/tini "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$dpkgArch"; \
            wget -O /usr/bin/tini.asc "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-$dpkgArch.asc"; \
        export GNUPGHOME="$(mktemp -d)"; \
            gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7; \
            gpg --batch --verify /usr/bin/tini.asc /usr/bin/tini; \
            gpgconf --kill all; \
            rm -rf "$GNUPGHOME" /usr/bin/tini.asc; \
        chmod +x /usr/bin/tini; \
            echo "Tini version: $(/usr/bin/tini --version)"; \
        \
    # Clean up
        apt-mark auto '.*' > /dev/null; \
            [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
                apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Install necessary packages and tools
RUN set -eux; \
    # Update and install basic packages
        apt-get update && \
        apt-get install -y --no-install-recommends \
        wget curl gnupg2 lsb-release ca-certificates \
        locales cron rclone openssh-client && \
        \
    # Get the version codename from /etc/os-release
        VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2) && \
    # Add and install Percona APT repository
        wget https://repo.percona.com/apt/percona-release_latest.${VERSION_CODENAME}_all.deb && \
            dpkg -i percona-release_latest.${VERSION_CODENAME}_all.deb && \
            rm percona-release_latest.${VERSION_CODENAME}_all.deb && \
        percona-release setup ps80 && \
        \
    # Add PostgreSQL GPG key and repository
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-archive-keyring.gpg && \
        echo "deb [signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg] https://apt.postgresql.org/pub/repos/apt/ ${VERSION_CODENAME}-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
        \
    # Update package list and install required packages
        apt-get update && \
        apt-get install -y --no-install-recommends \
            percona-server-client \
            postgresql-client-16 && \
        \
    # Install MongoDB Database Tools
        ARCH=$(dpkg --print-architecture) && \
        case "$ARCH" in \
            amd64) DOWNLOAD_URL="https://fastdl.mongodb.org/tools/db/mongodb-database-tools-debian12-x86_64-${MONGO_TOOLS_VERSION}.tgz" ;; \
            arm64) DOWNLOAD_URL="https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2404-arm64-${MONGO_TOOLS_VERSION}.tgz" ;; \
            *) echo "Unsupported architecture: $ARCH" && exit 1 ;; \
        esac && \
        wget --quiet "$DOWNLOAD_URL" -O /tmp/mongodb-tools.tgz && \
            tar -xzf /tmp/mongodb-tools.tgz -C /usr/local && \
            mv /usr/local/mongodb-database-tools-*/bin/* /usr/bin/ && \
            chmod +x /usr/bin/* && \
        \
    # Clean up unnecessary packages and files
        apt-get purge -y gnupg2 lsb-release && \
        apt-get autoremove -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/mongodb-tools.tgz /usr/local/mongodb-database-tools-* && \
    # Update locales
        sed -i -e 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen && \
        dpkg-reconfigure --frontend=noninteractive locales

COPY templates /templates
COPY main.sh /usr/bin/
ENTRYPOINT [ "tini", "--" ]
CMD ["main.sh"]
