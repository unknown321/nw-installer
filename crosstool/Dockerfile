FROM debian:9-slim
RUN \
    echo "deb http://snapshot.debian.org/archive/debian/20220622T000000Z stretch main" > /etc/apt/sources.list && \
    echo "deb http://snapshot.debian.org/archive/debian-security/20220622T000000Z stretch/updates main" >> /etc/apt/sources.list && \
    echo "deb http://snapshot.debian.org/archive/debian/20220622T000000Z stretch-updates main" >> /etc/apt/sources.list && \
    echo "deb-src http://snapshot.debian.org/archive/debian/20220622T000000Z stretch main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until false;' > /etc/apt/apt.conf.d/archive && \
    apt-get update && \
    apt-get install -y \
        vim wget sudo \
        autoconf make && \
    apt-get install -y git && \
    apt-get install -y flex bison texinfo && \
    apt-get install -y build-essential && \
    apt-get install -y unzip help2man gawk libtool-bin libncurses-dev zlib1g-dev pkg-config libcrypto++-dev nsis && \
    apt-get clean && \
    wget https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-1.26.0/crosstool-ng-1.26.0.tar.xz && \
    tar xf crosstool-ng-1.26.0.tar.xz && \
    rm crosstool-ng-1.26.0.tar.xz && \
    mkdir /x-tools && \
    useradd -u 1000 user && \
    chown -R user:user crosstool-ng-1.26.0 && \
    chown -R user:user /x-tools

COPY config /config
RUN \
    mv /config /crosstool-ng-1.26.0/.config && \
    cd /crosstool-ng-1.26.0 && \
    sudo -u user ./configure --enable-local && \
    sudo -u user make && \
    sudo -u user ./ct-ng build && \
    rm -rf /crosstool-ng-1.26.0

RUN \
    wget https://go.dev/dl/go1.23.3.linux-amd64.tar.gz && \
    echo "a0afb9744c00648bafb1b90b4aba5bdb86f424f02f9275399ce0c20b93a2c3a8 go1.23.3.linux-amd64.tar.gz" | sha256sum --check --status && \
    tar xf go1.23.3.linux-amd64.tar.gz && ln -s /go/bin/go /usr/local/bin/go
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]