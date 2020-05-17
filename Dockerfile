FROM armpits/portola-openjdk-build:v10-x86_64 AS portola-java-build

FROM alpine:3.11

ARG OPENJDK_VERSION=openjdk-11
ARG JRE_VERSION=jre-11
ARG OPENJDK_VARIANT=server
ARG BOOTJDK_VERSION=portola-openjdk-10-server-x86_64
ARG ARCH=x86_64
ARG PREFIX=/usr/local
ARG TMP_DIR=/${OPENJDK_VERSION}-build
ARG BOOTJDK_DIR=${TMP_DIR}/${BOOTJDK_VERSION}

# CPU cores given to the build
ARG CORES=4

RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    linux-headers \
    alpine-sdk \
    autoconf \
    bash \
    coreutils \
    mercurial \
    gawk \
    grep \
    zip \
    zlib-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    libxt-dev \
    libffi-dev \
    alsa-lib-dev \
    cups-dev \
    fontconfig-dev && \
    mkdir ${TMP_DIR} && \
    mkdir ${TMP_DIR}/${OPENJDK_VERSION} && \
    mkdir ${TMP_DIR}/${BOOTJDK_VERSION} 

COPY --from=portola-java-build /${BOOTJDK_VERSION}.tar.xz ${TMP_DIR}/${BOOTJDK_VERSION}.tar.xz
COPY src/portola-${OPENJDK_VERSION}-src.tar.xz ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz

#COPY src/${BOOTJDK_VERSION}.tar.xz ${TMP_DIR}/${BOOTJDK_VERSION}.tar.xz
#COPY src/portola-${OPENJDK_VERSION}-src.tar.xz ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz

RUN tar -C ${TMP_DIR}/${OPENJDK_VERSION} -xf ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz && \
    tar -C ${TMP_DIR}/${BOOTJDK_VERSION} -xf ${TMP_DIR}/${BOOTJDK_VERSION}.tar.xz && \
    ln -sf ${TMP_DIR}/${BOOTJDK_VERSION}/lib/server/libjvm.so ${PREFIX}/lib/libjvm.so && \
    cd ${TMP_DIR}/${OPENJDK_VERSION} && \
    CONF=linux-${ARCH}-normal-${OPENJDK_VARIANT}-release \
    LOG=debug \
    bash configure \
    --with-boot-jdk=${BOOTJDK_DIR} \
    --with-jvm-variants=${OPENJDK_VARIANT} \
    --disable-warnings-as-errors && \
    make \
    JOBS=${CORES} \
    LOG=debug \
    CONF=linux-${ARCH}-normal-${OPENJDK_VARIANT}-release && \
    make install && \
    ${PREFIX}/jvm/${OPENJDK_VERSION}-internal/bin/jlink \
    --compress=2 \
    --module-path ${PREFIX}/jvm/${OPENJDK_VERSION}-internal/jmods \
    --add-modules jdk.httpserver,jdk.sctp,jdk.unsupported,java.base,java.compiler,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.smartcardio,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto \
    --no-header-files \
    --no-man-pages \
    --output ${TMP_DIR}/portola-${JRE_VERSION} && \
    tar --numeric-owner -zcvf /portola-${OPENJDK_VERSION}-${OPENJDK_VARIANT}-${ARCH}.tar.xz -C ${PREFIX}/jvm/${OPENJDK_VERSION}-internal . && \
    tar --numeric-owner -zcvf /portola-${JRE_VERSION}-${ARCH}.tar.xz -C ${TMP_DIR}/portola-${JRE_VERSION} . && \
    cd / && rm -rf ${TMP_DIR} ${PREFIX}/jvm

RUN apk del \
    linux-headers \
    alpine-sdk \
    autoconf \
    bash \
    coreutils \
    mercurial \
    gawk \
    grep \
    zip \
    zlib-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    libxt-dev \
    libffi-dev \
    alsa-lib-dev \
    cups-dev \
    fontconfig-dev && \
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

CMD ["/bin/sh"]
