import FFT from '../';
import FFT_WASM from '../native/fft.js';
import benchmark from 'benchmark';
import jensnockert from 'fft';
import dspjs from 'dsp.js';
import drom from 'fourier';
import fourierTransform from 'fourier-transform';

const external = {
  jensnockert,
  dspjs,
  drom,
  fourierTransform
};

function regexFilter(value) {
  if (value !== undefined && value.length !== 0)
    return new RegExp(value, 'ig');
  else
    return /./g;
}

/*eslint-disable no-undef */
const filter0 = regexFilter(process.argv[2]);
const filter1 = regexFilter(process.argv[3]);
/*eslint-enable no-undef */

function addFiltered(suite, name, body) {
  if (name.match(filter1) === null)
    return;

  suite.add(name, body);
}

function createInput(size) {
  const res = new Array(size);
  for (let i = 0; i < res.length; i++)
    res[i] = Math.random() * 2 - 1;
  return res;
}

function construct(size) {
  const suite = new benchmark.Suite();

  addFiltered(suite, 'fft.js', () => {
    new FFT(size);
  });

  suite.add('fft.js wasm', () => {
    new FFT_WASM(size);
  });

  return suite;
}

function addSelf(suite, size) {
  const f = new FFT(size);
  const input = createInput(f.size);
  const data = f.toComplexArray(input);
  const out = f.createComplexArray();

  addFiltered(suite, 'fft.js', () => {
    f.transform(out, data);
  });
}

function addSelfNative(suite, size) {
  const f = new FFT_WASM(size);
  const input = createInput(f.size);
  const data = f.toComplexArray(input);
  const out = f.createComplexArray();

  addFiltered(suite, 'fft.js wasm', () => {
    f.transform(out, data);
  });

  f.disposeBuffer(data);
  f.disposeBuffer(out);
}

function addJensNockert(suite, size) {
  const f = new external.jensnockert.complex(size, false);

  const input = createInput(size * 2);
  const output = new Array(size * 2);

  addFiltered(suite, 'jensnockert', () => {
    f.simple(output, input, 'complex');
  });
}

function addDSPJS(suite, size) {
  const f = new external.dspjs.FFT(size, 44100);

  // Make benchmark fair
  f.calculateSpectrum = function nop() {};

  const input = createInput(size);
  addFiltered(suite, 'dsp.js', () => {
    f.forward(input);
  });
}

function addDrom(suite, size) {
  const heap = external.drom.custom.alloc(size, 3);
  const stdlib = {
    Math: Math,
    Float32Array: Float32Array,
    Float64Array: Float64Array
  };
  const f = new external.drom.custom[`fft_f64_${size}_asm`](stdlib, null, heap);

  f.init();

  addFiltered(suite, 'drom', () => {
    f.transform();
  });
}

function transform(size) {
  const suite = new benchmark.Suite();

  addSelf(suite, size);
  addSelfNative(suite, size);
  addJensNockert(suite, size);
  addDSPJS(suite, size);
  addDrom(suite, size);

  return suite;
}

function addRealSelf(suite, size) {
  const f = new FFT(size);
  const input = createInput(f.size);
  const data = f.toComplexArray(input);
  const out = f.createComplexArray();

  addFiltered(suite, 'fft.js', () => {
    f.realTransform(out, data);
  });
}

function addRealNative(suite, size) {
  const f = new FFT_WASM(size);
  const input = createInput(f.size);
  const data = f.createComplexArray();
  f.toComplexArray(input, data);
  const out = f.createComplexArray();

  addFiltered(suite, 'fft.js wasm', () => {
    f.realTransform(out, data);
  });
}

function addFourierTransform(suite, size) {
  const forward = external.fourierTransform;

  const input = createInput(size);
  addFiltered(suite, 'fourier-transform', () => {
    // It is not exactly fair, since `fourier-transform` also computes
    // magnitude. However, when removing this magnitude code locally, fft.js
    // outperforms `fourier-transform` by almost the same margin.
    forward(input);
  });
}

function realTransform(size) {
  const suite = new benchmark.Suite();

  addRealSelf(suite, size);
  addRealNative(suite, size);
  addFourierTransform(suite, size);

  return suite;
}

const benchmarks = [
  /* { title: 'table construction', suite: construct(16384) },
  { title: 'transform size=2048', suite: transform(2048) },
  { title: 'transform size=4096', suite: transform(4096) },
  { title: 'transform size=8192', suite: transform(8192) },
  { title: 'transform size=16384', suite: transform(16384) },
  { title: 'realTransform size=2048', suite: realTransform(2048) },
  { title: 'realTransform size=4096', suite: realTransform(4096) }, */
  { title: 'realTransform size=8192', suite: realTransform(8192) },
  { title: 'realTransform size=16384', suite: realTransform(16384) }
];

/* eslint-disable no-console */
benchmarks.forEach((bench) => {
  if (bench.title.match(filter0) === null)
    return;
  console.log('===== %s =====', bench.title);
  bench.suite.on('cycle', (event) => {
    console.log('    '+ String(event.target));
  }).on('complete', function() {
    console.log('  Fastest is ' + this.filter('fastest').map('name'));
  });
  bench.suite.run();
});
