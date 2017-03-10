clang -S -emit-llvm --target=wasm32 native/fft.c -Oz -c -o fft.bc
llc -asm-verbose=false -o fft.s fft.bc
rm fft.bc
s2wasm fft.s > native/fft.wast
rm fft.s
wast2wasm native/fft.wast -o native/fft.wasm
