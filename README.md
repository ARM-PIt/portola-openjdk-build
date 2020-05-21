# Portola OpenJDK Build

This is a transparent build of the [Portola OpenJDK Project](https://openjdk.java.net/projects/portola/). The Portola project was created to add compatibility between OpenJDK the [musl libc](https://www.musl-libc.org/), and the need for this becomes very apparent if the need to build or modify Java under Alpine Linux comes up. Using the glibc compatibility package for Alpine has been the preferred solution, and this works perfectly fine. However, some may want a from-scratch process for making a native build of OpenJDK using musl libc. The hosted images here contain the resulting tar archives of JDK and JRE, and have had all dependencies removed to keep a smaller foot print. As the previous version's JDK is necessary for building the desired version as the [boot JDK](https://hg.openjdk.java.net/jdk-updates/jdk9u/raw-file/tip/common/doc/building.html#boot-jdk-requirements), the previous version build image is used as a multi-stage source for the necessary JDK. Since Portola started with version 9, the version 8 boot JDK came from the [Alpine community repository](https://pkgs.alpinelinux.org/package/v3.11/community/x86_64/openjdk8).

## Usage

Here are the intended uses for this image.

### Multi-stage source

The quickest way of getting started is to simply add the image as a FROM source and copy over the tar archive to the target build. The archives are named in this format /portola-{jdk | jre}-{version number}-{architecture}.tar.xz

#### JDK

```
FROM armpits/portola-openjdk-build:v14-x86_64 AS portola-java-build
  
FROM alpine:3.11

COPY --from=portola-java-build /portola-jre-14-armhf.tar.xz /tmp/jdk.tar.xz

RUN mkdir -p /opt/java/jdk && \
    tar -C /opt/java/jdk -xf /tmp/jdk.tar.xz && \
    ln -sf /opt/java/jdk/lib/server/libjvm.so /usr/local/lib/libjvm.so && \
    ln -sf /opt/java/jdk/bin/java /usr/local/bin/java && \
    rm -rf /tmp/*

CMD ["/bin/sh"]
```

#### JRE

```
FROM armpits/portola-openjdk-build:v14-x86_64 AS portola-java-build
  
FROM alpine:3.11

COPY --from=portola-java-build /portola-jdk-14-armhf.tar.xz /tmp/jre.tar.xz

RUN mkdir -p /opt/java/jre && \
    tar -C /opt/java/jre -xf /tmp/jre.tar.xz && \
    ln -sf /opt/java/jre/lib/server/libjvm.so /usr/local/lib/libjvm.so && \
    ln -sf /opt/java/jre/bin/java /usr/local/bin/java && \
    rm -rf /tmp/*

CMD ["/bin/sh"]
```

### Local copy

If just the archives are needed they can be extracted with a host volume and copy command.

```
mkdir $(pwd)/tmp

docker pull armpits/portola-openjdk-build:v14-x86_64

docker run \
  -v "$(pwd)"/tmp:/tmp \
  -it armpits/portola-openjdk-build:v14-x86_64 \
  /bin/bash -c "/bin/cp /*.tar.xz ./tmp/"
```

## Sources

https://hg.openjdk.java.net/portola
https://pkgs.alpinelinux.org/package/v3.11/community/x86_64/openjdk8
