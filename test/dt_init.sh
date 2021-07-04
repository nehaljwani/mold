#!/bin/bash
set -e
cd $(dirname $0)
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/tmp/$(basename -s .sh $0)
mkdir -p $t

cat <<EOF | clang -c -o $t/a.o -x assembler -
.globl main, init, fini
main:
  ret
init:
  ret
fini:
  ret
EOF

clang -fuse-ld=`pwd`/../mold -o $t/exe $t/a.o
readelf -a $t/exe > $t/log

grep -Pqz '(?s)\(INIT\)\s+0x([0-9a-f]+)\b.*\1\s+0 FUNC    GLOBAL HIDDEN\s+\d+ _init\b' $t/log

grep -Pqz '(?s)\(FINI\)\s+0x([0-9a-f]+)\b.*\1\s+0 FUNC    GLOBAL HIDDEN\s+\d+ _fini\b' $t/log

clang -fuse-ld=`pwd`/../mold -o $t/exe $t/a.o -Wl,-init,init -Wl,-fini,fini
readelf -a $t/exe > $t/log

grep -Pqz '(?s)\(INIT\)\s+0x([0-9a-f]+)\b.*\1\s+0 NOTYPE  GLOBAL DEFAULT\s+\d+ init\b' $t/log

grep -Pqz '(?s)\(FINI\)\s+0x([0-9a-f]+)\b.*\1\s+0 NOTYPE  GLOBAL DEFAULT\s+\d+ fini\b' $t/log

echo OK
