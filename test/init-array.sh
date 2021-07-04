#!/bin/bash
set -e
cd $(dirname $0)
echo -n "Testing $(basename -s .sh $0) ... "
t=$(pwd)/tmp/$(basename -s .sh $0)
mkdir -p $t

cat <<EOF | cc -c -o $t/a.o -x assembler -Wa,-no-warn -
.globl init1, init2, fini1, fini2

.section .init_array,"aw",@progbits
.align 8
.quad init1

.section .init_array,"aw",@init_array
.align 8
.quad init2

.section .fini_array,"aw",@progbits
.align 8
.quad fini1

.section .fini_array,"aw",@fini_array
.align 8
.quad fini2
EOF

cat <<EOF | cc -c -o $t/b.o -xc -
#include <stdio.h>

void init1() { printf("init1 "); }
void init2() { printf("init2 "); }
void fini1() { printf("fini1\n"); }
void fini2() { printf("fini2 "); }

int main() {
  return 0;
}
EOF

clang -fuse-ld=`pwd`/../mold -o $t/exe $t/a.o $t/b.o
$t/exe | grep -q 'init1 init2 fini2 fini1'

echo OK
