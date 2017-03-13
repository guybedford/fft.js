# FFT.js WASM fork
[![Build Status](https://secure.travis-ci.org/indutny/fft.js.svg)](http://travis-ci.org/indutny/fft.js)
[![NPM version](https://badge.fury.io/js/fft.js.svg)](https://badge.fury.io/js/fft.js)

This is a WASM implementation of the project by Fedor Indutny at https://github.com/indutny/fft.js,
used to compare performance of JS vs WASM.

The WASM version here is written in C and compiled via LLVM into optimized WASM, implemented to
exactly the same algorithm as the JS version of the code.

WASM execution uses the Node ES Module Loader project (https://github.com/ModuleLoader/node-es-module-loader).

```
npm install && npm run bench
```

## Benchmark

Latest benchmark running against NodeJS 8.0.0-nightly20170226813b312b0e, with V8 5.6.326.55.

```
$ npm run bench
===== table construction =====
    fft.js x 903 ops/sec ±1.83% (85 runs sampled)
    fft.js wasm x 21.74 ops/sec ±49.05% (9 runs sampled)
  Fastest is fft.js
===== transform size=2048 =====
    fft.js x 21,364 ops/sec ±1.99% (80 runs sampled)
    fft.js wasm x 18,876 ops/sec ±1.48% (85 runs sampled)
    jensnockert x 3,177 ops/sec ±4.92% (78 runs sampled)
    dsp.js x 14,031 ops/sec ±1.76% (85 runs sampled)
    drom x 8,647 ops/sec ±3.70% (80 runs sampled)
  Fastest is fft.js
===== transform size=4096 =====
    fft.js x 9,172 ops/sec ±1.59% (91 runs sampled)
    fft.js wasm x 10,101 ops/sec ±0.67% (94 runs sampled)
    jensnockert x 2,622 ops/sec ±0.96% (92 runs sampled)
    dsp.js x 3,994 ops/sec ±0.41% (93 runs sampled)
    drom x 4,641 ops/sec ±0.52% (93 runs sampled)
  Fastest is fft.js wasm
===== transform size=8192 =====
    fft.js x 4,235 ops/sec ±0.84% (93 runs sampled)
    fft.js wasm x 4,260 ops/sec ±0.61% (94 runs sampled)
    jensnockert x 822 ops/sec ±0.54% (93 runs sampled)
    dsp.js x 1,550 ops/sec ±0.61% (94 runs sampled)
    drom x 2,173 ops/sec ±0.52% (94 runs sampled)
  Fastest is fft.js wasm
===== transform size=16384 =====
    fft.js x 1,860 ops/sec ±1.25% (91 runs sampled)
    fft.js wasm x 2,076 ops/sec ±0.87% (93 runs sampled)
    jensnockert x 584 ops/sec ±1.47% (88 runs sampled)
    dsp.js x 625 ops/sec ±0.48% (92 runs sampled)
    drom x 1,009 ops/sec ±0.79% (91 runs sampled)
  Fastest is fft.js wasm
===== realTransform size=2048 =====
    fft.js x 32,188 ops/sec ±0.64% (95 runs sampled)
    fft.js wasm x 26,163 ops/sec ±0.69% (92 runs sampled)
    fourier-transform x 21,255 ops/sec ±0.61% (94 runs sampled)
  Fastest is fft.js
===== realTransform size=4096 =====
    fft.js x 14,464 ops/sec ±0.54% (95 runs sampled)
    fft.js wasm x 13,967 ops/sec ±0.74% (91 runs sampled)
    fourier-transform x 9,934 ops/sec ±0.66% (94 runs sampled)
  Fastest is fft.js
===== realTransform size=8192 =====
    fft.js x 6,507 ops/sec ±0.94% (92 runs sampled)
    fft.js wasm x 5,565 ops/sec ±0.88% (91 runs sampled)
    fourier-transform x 3,999 ops/sec ±1.54% (92 runs sampled)
  Fastest is fft.js
===== realTransform size=16384 =====
    fft.js x 3,035 ops/sec ±0.79% (94 runs sampled)
    fft.js wasm x 2,920 ops/sec ±1.01% (91 runs sampled)
    fourier-transform x 1,731 ops/sec ±1.48% (92 runs sampled)
  Fastest is fft.js
```

#### LICENSE

This software is licensed under the MIT License.

Copyright Fedor Indutny, 2017.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
