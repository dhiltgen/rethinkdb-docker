FROM ubuntu:19.10 AS builder

ARG VERSION=2.3.6

# Also: ppc64le, s390x
ARG CARCH=x86_64

RUN \
    apt-get update && apt-get install -y \
         ash \
         bash \
         build-essential \
         icu-devtools \
         libboost-dev \
         libcurl4 \
         libcurl4-openssl-dev \
         libssl-dev \
         m4 \
         paxctl \
         perl \
         protobuf-compiler \
         python \
         wget \
         xattr

RUN \
    wget https://download.rethinkdb.com/dist/rethinkdb-$VERSION.tgz && \
    gunzip rethinkdb-$VERSION.tgz && \
    tar xvf rethinkdb-$VERSION.tar && \
    rm rethinkdb-$VERSION.tar

COPY *.patch ./rethinkdb-$VERSION/
ADD paxmark /usr/bin/

ARG PATCHES="openssl-1.1-all.patch \
    paxmark-x86_64.patch \
    extproc-js-all.patch"

WORKDIR rethinkdb-$VERSION 
RUN for i in $PATCHES; do \
        case $i in \
        *-$CARCH.patch|*-all.patch) \
            echo $i; patch -p1 < "$i"; \
        esac; \
    done

RUN ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --dynamic all \
        --with-system-malloc
RUN export CXXFLAGS="$CXXFLAGS -DBOOST_NO_CXX11_EXPLICIT_CONVERSION_OPERATORS -fno-delete-null-pointer-checks" && \
    make --jobs $(grep -c '^processor' /proc/cpuinfo) SPLIT_SYMBOLS=1 || \
    (find build; paxmark -m build/external/v8_3.30.33.16/build/out/x64.release/mksnapshot) && \
    make --jobs $(grep -c '^processor' /proc/cpuinfo) SPLIT_SYMBOLS=1 && \
    mv build/release_system/rethinkdb /usr/local/bin/

FROM ubuntu:19.10

#    apk add --update \
#        ca-certificates libstdc++ libgcc libcurl protobuf libexecinfo
RUN \
    apt-get update && apt-get install -y \
         libcurl4  \
         libprotobuf17 \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* /usr/share/man /usr/share/doc


COPY --from=builder /usr/local/bin/rethinkdb /usr/local/bin/rethinkdb

ENTRYPOINT ["rethinkdb"]
