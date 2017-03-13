# FFT.js
[![Build Status](https://secure.travis-ci.org/indutny/fft.js.svg)](http://travis-ci.org/indutny/fft.js)
[![NPM version](https://badge.fury.io/js/fft.js.svg)](https://badge.fury.io/js/fft.js)

Implementation of Radix-4 FFT.

This is a WASM implementation of the project by Fedor Indutny at https://github.com/indutny/fft.js.

WASM execution uses the Node ES Module Loader project (https://github.com/ModuleLoader/node-es-module-loader).

```
npm install && npm run bench
```

Benchmark updated below to reflect WASM results.

## Usage

```js
const FFT = require('fft.js');

const f = new FFT(4096);

const input = new Array(4096);
input.fill(0);

const out = f.createComplexArray();
```

If `data` has just real numbers as is the case when `toComplexArray` is
used - real FFT may be run to compute it 25% faster:
```js
const realInput = new Array(f.size);
f.realTransform(out, realInput);
```

`realTransform` fills just the left half of the `out`, so if the full
spectrum is needed (which is symmetric):
```js
f.completeSpectrum(out);
```

If `data` on other hand is a complex array:
```js
const data = f.toComplexArray(input);
f.transform(out, data);
```

Inverse fourier transform:
```js
f.inverseTransform(data, out);

// necessary to free WASM memory as WeakRefs aren't a thing yet
f.disposeBuffer(data);
f.disposeBuffer(out);
f.dispose();
```

## Benchmark

```
$ npm run bench
===== table construction =====
    fft.js x 970 ops/sec ±0.90% (92 runs sampled)
    fft.js wasm x 21.36 ops/sec ±58.13% (7 runs sampled)
  Fastest is fft.js
===== transform size=2048 =====
    fft.js x 20,702 ops/sec ±4.43% (81 runs sampled)
    fft.js wasm x 20,439 ops/sec ±0.57% (94 runs sampled)
    jensnockert x 3,540 ops/sec ±1.21% (93 runs sampled)
    dsp.js x 15,350 ops/sec ±0.62% (95 runs sampled)
    drom x 10,117 ops/sec ±0.64% (93 runs sampled)
  Fastest is fft.js wasm
===== transform size=4096 =====
    fft.js x 9,172 ops/sec ±1.04% (93 runs sampled)
    fft.js wasm x 10,079 ops/sec ±0.84% (95 runs sampled)
    jensnockert x 2,485 ops/sec ±2.35% (84 runs sampled)
    dsp.js x 3,437 ops/sec ±2.71% (79 runs sampled)
    drom x 4,391 ops/sec ±1.79% (88 runs sampled)
  Fastest is fft.js wasm
===== transform size=8192 =====
    fft.js x 4,357 ops/sec ±0.85% (93 runs sampled)
    fft.js wasm x 4,258 ops/sec ±0.73% (94 runs sampled)
    jensnockert x 836 ops/sec ±1.29% (92 runs sampled)
    dsp.js x 1,997 ops/sec ±0.67% (93 runs sampled)
    drom x 2,148 ops/sec ±0.67% (91 runs sampled)
  Fastest is fft.js
===== transform size=16384 =====
    fft.js x 3,123 ops/sec ±0.84% (95 runs sampled)
    jensnockert x 855 ops/sec ±1.02% (92 runs sampled)
    dsp.js x 948 ops/sec ±0.70% (94 runs sampled)
    drom x 1,428 ops/sec ±0.56% (93 runs sampled)
  Fastest is fft.js
===== realTransform size=2048 =====
    fft.js x 47,511 ops/sec ±0.93% (91 runs sampled)
    fourier-transform x 34,859 ops/sec ±0.77% (93 runs sampled)
  Fastest is fft.js
===== realTransform size=4096 =====
    fft.js x 21,841 ops/sec ±0.70% (94 runs sampled)
    fourier-transform x 16,135 ops/sec ±0.39% (93 runs sampled)
  Fastest is fft.js
===== realTransform size=8192 =====
    fft.js x 9,665 ops/sec ±0.65% (95 runs sampled)
    fourier-transform x 6,456 ops/sec ±0.83% (93 runs sampled)
  Fastest is fft.js
===== realTransform size=16384 =====
    fft.js x 4,399 ops/sec ±0.82% (93 runs sampled)
    fourier-transform x 2,745 ops/sec ±0.68% (94 runs sampled)
  Fastest is fft.js
=======
    fft.js x 1,897 ops/sec ±0.26% (95 runs sampled)
    fft.js wasm x 2,094 ops/sec ±0.60% (93 runs sampled)
    jensnockert x 613 ops/sec ±0.89% (88 runs sampled)
    dsp.js x 619 ops/sec ±0.51% (91 runs sampled)
    drom x 905 ops/sec ±3.36% (83 runs sampled)
  Fastest is fft.js wasm
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
