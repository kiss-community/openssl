#!/usr/bin/env sh

set -eu

OPENSSL_VERSION=3.0.5
OPENSSL_SRC="https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"

OUTDIR="$PWD/output"
ORIGINAL_LIST="$OUTDIR/original_list"

TMPDIR="$(mktemp -d)"

mkdir -p "$OUTDIR"

cd "$TMPDIR"

curl -L "$OPENSSL_SRC" | tar xfz -
cd "openssl-$OPENSSL_VERSION"

# Make the generated Makefile use host toolchain
patch -p1 < "$OUTDIR/../host-toolchain.patch"

sed -i \
    -e '/util\/write-man-symlinks/d' \
    -e 's|@$(PERL) $(SRCDIR)/util/mkdir-p.pl|@-mkdir -p|' \
    Configurations/unix-Makefile.tmpl

find . -type f > "$ORIGINAL_LIST"

env -i PATH=/usr/bin ./Configure \
    --prefix=/usr \
    --openssldir=/etc/ssl \
    --libdir=lib \
    no-unit-test \
    no-makedepend \
    shared \
    linux-x86_64

env -i PATH=/usr/bin make build_all_generated -j"$(nproc)"

while read -r file; do
    rm -f "$file"
done < "$ORIGINAL_LIST"

rm "$ORIGINAL_LIST"

tar c . | gzip > "$OUTDIR/openssl-$OPENSSL_VERSION-generated.tar.gz"

cd "$OUTDIR"
rm -rf "$TMPDIR"
