#!/usr/bin/env sh

set -eu

OPENSSL_VERSION=3.0.5
OPENSSL_SRC="https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"

OUTDIR="$PWD/output"
ORIGINAL_LIST="$OUTDIR/original_list"

mkdir -p "$OUTDIR"
cd "$OUTDIR"

curl -L "$OPENSSL_SRC" | tar xfz -

cd "openssl-$OPENSSL_VERSION"

export CC=gcc
export CXX=g++
export CFLAGS="-march=x86-64 -mtune=generic -pipe -Os"
export CXXFLAGS="$CFLAGS"

find . -type f > "$ORIGINAL_LIST"

./Configure \
    --prefix=/usr \
    --openssldir=/etc/ssl \
    --libdir=lib \
    no-unit-test \
    no-makedepend \
    shared \
    linux-x86_64

make build_all_generated

while read -r file; do
    rm -f "$file"
done < "$ORIGINAL_LIST"

rm "$ORIGINAL_LIST"

tar c . | gzip > "$OUTDIR/openssl-$OPENSSL_VERSION-generated.tar.gz"

cd "$OUTDIR"

rm -rf "openssl-$OPENSSL_VERSION"
