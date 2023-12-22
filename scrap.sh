docker run -it --entrypoint /bin/bash stedolan/jq
apt-get update 
apt-get install curl

cd /tmp/
curl -sL https://github.com/stedolan/jq/releases/ | \
    grep -P "/archive/jq-.+?\.tar\.gz" | \
    sed -n '1p' | \
    perl -pe 's/^.+?href="([^"]+)".+$/https:\/\/github\.com\/$1/g' | \
    wget -qi -

cd /tmp/
file=$(find -name *tar.gz)
dir="/tmp/jq"
mkdir -p "$dir"
tar -xzvf "$file" -C "$dir"
cd "$dir"
dir=$(find -maxdepth 1 -type d | grep jq)
cd "$dir"


            # # valgrind is a tool for debugging and testing 
            # --disable-valgrind \
            # # configure where oniguruma (regex submodule) is
            # --with-oniguruma=builtin \
            # # link jq with static libraries only
            # --enable-all-static \
            # # # build without flex or bison
            # # --disable-maintainer-mode \
            # # --prefix=/usr/local \

(
    apt-get update && \
    apt-get install -y \
        build-essential \
        autoconf \
        libtool \
        git \
        bison \
        flex \
        python3 \
        python3-pip \
        wget && \
    python3 -m pip install --upgrade pip && \
    pip3 install pipenv && \
    git clone https://github.com/stedolan/jq.git /app/ && \
    cd /app && \
    (cd /app/jq/docs && pipenv sync) && \
    (cd /app/jq && \
        git submodule init && \
        git submodule update && \
        autoreconf -fi && \
        ./configure \
            --disable-valgrind \
            --with-oniguruma=builtin \
            --enable-all-static \
        && \
        make -j8 && \
        make check && \
        make install 
    )
)
(cd /app/jq/modules/oniguruma && \
        make uninstall ) && \
    (cd /app/jq && \
        make distclean ) && \
    apt-get purge -y \
        build-essential \
        autoconf \
        libtool \
        bison \
        git \
        flex \
        python3 \
        python3-pip && \
    apt-get autoremove -y && \
    rm -rf /app/jq/modules/oniguruma/* && \
    rm -rf /app/jq/modules/oniguruma/.git && \
    rm -rf /app/jq/modules/oniguruma/.gitignore && \
    rm -rf /var/lib/apt/lists/* /var/lib/gems
apt-get update && \
    apt-get install -y \
        build-essential \
        autoconf \
        libtool \
        git \
        bison \
        flex \
        python3 \
        python3-pip \
        wget && \
    pip3 install pipenv && \
    (cd /app/docs && pipenv sync) && \
    (cd /app && \
        git submodule init && \
        git submodule update && \
        autoreconf -i && \
        ./configure --disable-valgrind --enable-all-static --prefix=/usr/local && \
        make -j8 && \
        make check && \
        make install ) && \
    (cd /app/modules/oniguruma && \
        make uninstall ) && \
    (cd /app && \
        make distclean ) && \
    apt-get purge -y \
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