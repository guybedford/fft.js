clang -S -emit-llvm --target=wasm32 native/fft.c -Oz -c -o - | llc -asm-verbose=false > fft.s
s2wasm fft.s > native/fft.wast
rm fft.s
wast2wasm native/fft.wast -o native/fft.wasm
