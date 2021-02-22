FROM debian:latest

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# install build tools
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        autoconf \
        libtool \
        git \
        bison \
        flex \
        python3 \
        python3-pip \
        wget

RUN pip3 install pipenv

# clone jq and its submodules
RUN git clone https://github.com/stedolan/jq.git /app/ && \
    (cd /app/docs && pipenv sync) && \
    (cd /app && \
        git submodule init && \
        git submodule update)

# configure jq
RUN (cd /app && \
        autoreconf -fi && \
        ./configure \
            --with-oniguruma=builtin)
# build jq
RUN (cd /app && \
    make -j8 && \
    make check && \
    make install)

# ensure jq is available regardless of path
RUN ln -s /usr/local/bin/jq /usr/bin/jq
RUN ln -s /usr/local/bin/jq /bin/jq

# remove onigurama build
RUN (cd /app/modules/oniguruma && \
        make uninstall ) 

# clean up the build files
RUN (cd /app && \
        make distclean ) 

# remove build tools
RUN apt-get purge -y \
        build-essential \
        autoconf \
        libtool \
        bison \
        git \
        flex \
        python3 \
        python3-pip && \
    apt-get autoremove -y && \
    rm -rf /app/modules/oniguruma/* && \
    rm -rf /app/modules/oniguruma/.git && \
    rm -rf /app/modules/oniguruma/.gitignore && \
    rm -rf /var/lib/apt/lists/* /var/lib/gems

COPY ./tests /tests
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]