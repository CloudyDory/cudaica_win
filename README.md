# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

## Modification log:

**[Project-wise]**

1.Use Intel MKL for the CBLAS functions. You need to install Intel MKL, and add Intel MKL path to environment variables. Otherwise you may encounter "missing dll" error.

2.Add "mman.h" and "mman.c" to project to support some low-level IO functions.

3.Add some necessary header files to .c and .cu files.

**[cudaica_win.c]**

1.Remove the "-s" option. For me it is unnecessary.

2.Remove the post-processing part. Post-precessing is now down on Matlab part (cudaica.m). I remove it because I have added "PCA" option in cudaica.m, CUDAICA.exe only operates on the saved PCA-ed data.

**[infomax.cu]**

1.Remove some unnecessary output on command-line.

2.Step 3 and 4 of ICA is changed back to CUDA kernel function. Original code use cuBLAS functions, but is much slower.

3.Remove "sum2" in "step3<<<>>>", and integrate it into the calculation of "sum".

3."SYMBOL(xxx)" cannot be build under Windows. Directly use the symbol name here.

4.Remove "cudaDeviceSynchronize()" or "cudaThreadSynchronize" as it is unnecessary. CUDA function in a stream is executed serially.

5.Remove "tmpweights" and "tmpwpitch" as they are unnecessary.

**[config.cu]**

1.Remove the "-s" option information in help() function. 

2.Remove the "PCA not supported" warning. PCA is performed in cudaica.m, CUDAICA.exe only operates on the saved PCA-ed data.

**[device.cu]**

1.The "fprintf(stdout, "	Global Mem: %lu\n", properties->totalGlobalMem);" and the following line in function printCapabilities() is changed to fprintf(..., "... %llu ..."), otherwise "totalGlobalMem" is displayed as "0". 

2. Remove the test for free memory part. On high-end GPUs this step is slow.

**[common.cu]**

1.Memory allocation to "buffer" and "floatbuffer" change from mapmalloc() to malloc() to fix "\dev\zero" not supported on Windows issue. Correspondingly, mapfree() is changed to free().

Yunhui Zhou, 2018/08/21
