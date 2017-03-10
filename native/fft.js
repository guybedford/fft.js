import { memory, getOrAllocatePrecomputation, allocateBuffer, freeBuffer,
  transform4, singleTransform4, singleTransform2 } from './fft.wasm';

const boolReturnValue = 0x80000000;

export default function FFT (size) {
  this.size = size | 0;
  if (this.size <= 1 || (this.size & (this.size - 1)) !== 0)
    throw new Error('FFT size must be a power of two and bigger than 1');

  this._csize = size << 1;

  var tableAddr = getOrAllocatePrecomputation(this._csize * 8 + 0x80000000);

  var alreadyComputed = tableAddr & boolReturnValue;
  if (alreadyComputed)
    tableAddr ^= boolReturnValue;

  // NOTE: Use of `var` is intentional for old V8 versions
  var table = new Float64Array(memory.buffer, tableAddr, this._csize);
  // if (!alreadyComputed) // disabled for benchmark equality
    for (var i = 0; i < table.length; i += 2) {
      const angle = Math.PI * i / this.size;
      table[i] = Math.cos(angle);
      table[i + 1] = -Math.sin(angle);
    }
  this.table = table;

  // Find size's power of two
  var power = 0;
  for (var t = 1; this.size > t; t <<= 1)
    power++;

  // Calculate initial step's width:
  //   * If we are full radix-4 - it is 2x smaller to give inital len=8
  //   * Otherwise it is the same as `power` to give len=4
  this._width = power % 2 === 0 ? power - 1 : power;

  var bitReversalAddr = getOrAllocatePrecomputation((1 << this._width) * 4);

  var alreadyComputed = bitReversalAddr & boolReturnValue;
  if (alreadyComputed)
    bitReversalAddr ^= boolReturnValue;

  // Pre-compute bit-reversal patterns
  this._bitrev = new Uint32Array(memory.buffer, bitReversalAddr, 1 << this._width);
  // if (!alreadyComputed) // disabled for benchmark equality
    for (var shift = 0; shift < this._width; shift += 2) {
      var revShift = this._width - shift - 2;
      for (let j = 0; j < this._bitrev.length; j++)
        this._bitrev[j] |= ((j >>> shift) & 3) << revShift;
    }
};

FFT.prototype.fromComplexArray = function(complex, arr) {
  var res = arr || new Float64Array(complex.length >>> 1);
  for (var i = 0; i < complex.length; i += 2)
    res[i >>> 1] = complex[i];
  return res;
};

FFT.prototype.createComplexArray = function(skipClearMem) {
  // allocate buffer to WASM memory
  var addr = allocateBuffer(this._csize, skipClearMem ? 1 : 0);
  return new Float64Array(memory.buffer, addr, this._csize);
};

FFT.prototype.disposeBuffer = function (arr) {
  if (arr.buffer !== memory.buffer)
    throw new TypeError('Can only dispose complex array.');
  freeBuffer(arr.byteOffset, arr.byteLength);
};

FFT.prototype.toComplexArray = function(input, arr) {
  var res = arr || this.createComplexArray(true);
  for (var i = 0; i < res.length; i += 2) {
    res[i] = input[i >>> 1];
    res[i + 1] = 0;
  }
  return res;
};

FFT.prototype.transform = function(out, data) {
  if (out.byteOffset === data.byteOffset)
    throw new Error('Input and output buffers must be different');

  transform4(out.byteOffset, data.byteOffset, 1, this._csize, this._width, this._bitrev.byteOffset, this.table.byteOffset);
};

FFT.prototype.inverseTransform = function(out, data) {
  if (out.byteOffset === data.byteOffset)
    throw new Error('Input and output buffers must be different');

  transform4(out.byteOffset, data.byteOffset, -1, this._csize, this._width, this._bitrev.byteOffset, this.table.byteOffset);
  for (var i = 0; i < out.length; i++)
    out[i] /= this.size;
};
