clang -S -emit-llvm --target=wasm32 native/fft.c -Oz -c -D USE_MEMCPY=0 -D MALLOC_FAILURE_ACTION -D LACKS_UNISTD_H=1 -D LACKS_STRING_H=1 -D LACKS_ERRNO_H=1 -D USE_LOCKS=0 -D LACKS_SYS_TYPES_H=1 -D LACKS_STDLIB_H=1 -D LACKS_TIME_H=1 -D HAVE_MMAP=0 -D MORECORE_CANNOT_TRIM=1 -D malloc_getpagesize='65536' -D ABORT='assert(false)' -D NO_MALLOC_STATS=1 -o - | llc -asm-verbose=false fft.bc
s2wasm fft.s > native/fft.wast
# rm fft.s fft.opt fft.bc
wast2wasm native/fft.wast -o native/fft.wasm
