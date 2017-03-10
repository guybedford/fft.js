#include <stdlib.h>

int main () {}

void singleTransform2(double out[], double data[], int outOff, int off, int step);
void singleTransform4(double out[], double data[], int inv, int outOff, int off, int step);

float* allocateNode (size_t size, int len) {
  return (float*) malloc(size * len);
}

void freeNode (int* addr) {
  return free(addr);
}

void transform4(double out[], double data[], int inv, int size, int width, int bitrev[], double table[]) {
  // Initial step (permute and transform)
  int step = 1 << width;
  int len = (size / step) << 1;

  if (len == 4) {
    for (int outOff = 0, t = 0; outOff < size; outOff += len, t++) {
      int off = bitrev[t];
      singleTransform2(out, data, outOff, off, step);
    }
  } else {
    // len === 8
    for (int outOff = 0, t = 0; outOff < size; outOff += len, t++) {
      int off = bitrev[t];
      singleTransform4(out, data, inv, outOff, off, step);
    }
  }

  // Loop through steps in decreasing order
  for (step >>= 2; step >= 2; step >>= 2) {
    len = (size / step) << 1;
    int quarterLen = len >> 2;

    // Loop through offsets in the data
    for (int outOff = 0; outOff < size; outOff += len) {
      // Full case
      int limit = outOff + quarterLen;
      for (int i = outOff, k = 0; i < limit; i += 2, k += step) {
        int A = i;
        int B = A + quarterLen;
        int C = B + quarterLen;
        int D = C + quarterLen;

        // Original values
        double Ar = out[A];
        double Ai = out[A + 1];
        double Br = out[B];
        double Bi = out[B + 1];
        double Cr = out[C];
        double Ci = out[C + 1];
        double Dr = out[D];
        double Di = out[D + 1];

        // Middle values
        double MAr = Ar;
        double MAi = Ai;

        double tableBr = table[k];
        double tableBi = inv * table[k + 1];
        double MBr = Br * tableBr - Bi * tableBi;
        double MBi = Br * tableBi + Bi * tableBr;

        double tableCr = table[2 * k];
        double tableCi = inv * table[2 * k + 1];
        double MCr = Cr * tableCr - Ci * tableCi;
        double MCi = Cr * tableCi + Ci * tableCr;

        double tableDr = table[3 * k];
        double tableDi = inv * table[3 * k + 1];
        double MDr = Dr * tableDr - Di * tableDi;
        double MDi = Dr * tableDi + Di * tableDr;

        // Pre-Final values
        double T0r = MAr + MCr;
        double T0i = MAi + MCi;
        double T1r = MAr - MCr;
        double T1i = MAi - MCi;
        double T2r = MBr + MDr;
        double T2i = MBi + MDi;
        double T3r = inv * (MBr - MDr);
        double T3i = inv * (MBi - MDi);

        // Final values
        double FAr = T0r + T2r;
        double FAi = T0i + T2i;

        double FCr = T0r - T2r;
        double FCi = T0i - T2i;

        double FBr = T1r + T3i;
        double FBi = T1i - T3r;

        double FDr = T1r - T3i;
        double FDi = T1i + T3r;

        out[A] = FAr;
        out[A + 1] = FAi;
        out[B] = FBr;
        out[B + 1] = FBi;
        out[C] = FCr;
        out[C + 1] = FCi;
        out[D] = FDr;
        out[D + 1] = FDi;
      }
    }
  }
};

void singleTransform2(double out[], double data[], int outOff, int off, int step) {
  double evenR = data[off];
  double evenI = data[off + 1];
  double oddR = data[off + step];
  double oddI = data[off + step + 1];

  double leftR = evenR + oddR;
  double leftI = evenI + oddI;
  double rightR = evenR - oddR;
  double rightI = evenI - oddI;

  out[outOff] = leftR;
  out[outOff + 1] = leftI;
  out[outOff + 2] = rightR;
  out[outOff + 3] = rightI;
};

void singleTransform4(double out[], double data[], int inv, int outOff, int off, int step) {
  int step2 = step * 2;
  int step3 = step * 3;

  // Original values
  double Ar = data[off];
  double Ai = data[off + 1];
  double Br = data[off + step];
  double Bi = data[off + step + 1];
  double Cr = data[off + step2];
  double Ci = data[off + step2 + 1];
  double Dr = data[off + step3];
  double Di = data[off + step3 + 1];

  // Pre-Final values
  double T0r = Ar + Cr;
  double T0i = Ai + Ci;
  double T1r = Ar - Cr;
  double T1i = Ai - Ci;
  double T2r = Br + Dr;
  double T2i = Bi + Di;
  double T3r = inv * (Br - Dr);
  double T3i = inv * (Bi - Di);

  // Final values
  double FAr = T0r + T2r;
  double FAi = T0i + T2i;

  double FBr = T1r + T3i;
  double FBi = T1i - T3r;

  double FCr = T0r - T2r;
  double FCi = T0i - T2i;

  double FDr = T1r - T3i;
  double FDi = T1i + T3r;

  out[outOff] = FAr;
  out[outOff + 1] = FAi;
  out[outOff + 2] = FBr;
  out[outOff + 3] = FBi;
  out[outOff + 4] = FCr;
  out[outOff + 5] = FCi;
  out[outOff + 6] = FDr;
  out[outOff + 7] = FDi;
};
