FROM alpine:3.11

ARG OPENJDK_VERSION=openjdk-9
ARG JRE_VERSION=jre-9
ARG OPENJDK_VARIANT=server
ARG BOOTJDK_VERSION=openjdk-8
ARG ARCH=x86_64
ARG PREFIX=/usr/local
ARG TMP_DIR=/${OPENJDK_VERSION}-build
ARG BOOTJDK_DIR=/usr/lib/jvm/java-1.8-openjdk

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
    openjdk8 \
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
    mkdir ${TMP_DIR}/${OPENJDK_VERSION}

# Not recommended running here as this can take many hours depending on your connection.
# If using hg clone here be sure to comment the next COPY step.
# RUN mkdir /tmp/portola-${OPENJDK_VERSION}-src && cd /tmp/portola-${OPENJDK_VERSION}-src && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/corba && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/hotspot && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/jaxp && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/jaxws && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/jdk && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/langtools && \
#     hg clone https://hg.openjdk.java.net/portola/jdk9/nashorn && \
#     rm -rf corba/.hg* hotspot/.hg* jaxp/.hg* jaxws/.hg* jdk/.hg* langtools/.hg* nashorn/.hg* && \
#     tar --numeric-owner -zcvf ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz -C /tmp/portola-${OPENJDK_VERSION}-src . && \
#     rm -rf /tmp/portola-${OPENJDK_VERSION}-src

# Get the full portola openjdk9 repository then tar and name it in local src directory for the COPY step below.
# Otherwise proceed as-is to use prepared tar archive from the project S3 bucket.
# COPY src/portola-${OPENJDK_VERSION}-src.tar.xz ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz

RUN curl -o ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz https://armpits-build-src.s3.us-east-2.amazonaws.com/openjdk/portola/src/portola-${OPENJDK_VERSION}-src.tar.xz && \
    tar -C ${TMP_DIR}/${OPENJDK_VERSION} -xf ${TMP_DIR}/portola-${OPENJDK_VERSION}-src.tar.xz && \
    ln -sf ${BOOTJDK_DIR}/jre/lib/aarch32/server/libjvm.so /usr/local/lib/libjvm.so && \
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
    cd ${TMP_DIR}/${OPENJDK_VERSION} && \
    make install && \
    ${PREFIX}/jvm/${OPENJDK_VERSION}-internal/bin/jlink \
    --compress=2 \
    --module-path ${PREFIX}/jvm/${OPENJDK_VERSION}-internal/jmods \
    --add-modules jdk.httpserver,jdk.sctp,jdk.unsupported,java.activation,java.base,java.compiler,java.corba,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.prefs,java.rmi,java.se,java.se.ee,java.security.jgss,java.security.sasl,java.smartcardio,java.sql,java.sql.rowset,java.transaction,java.xml,java.xml.bind,java.xml.crypto,java.xml.ws,java.xml.ws.annotation \
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
    openjdk8 \
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
