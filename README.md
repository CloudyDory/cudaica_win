# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

[![LICENSE](https://img.shields.io/badge/license-Anti%20996-blue.svg)](https://github.com/996icu/996.ICU/blob/master/LICENSE)
[![Badge](https://img.shields.io/badge/link-996.icu-red.svg)](https://996.icu/)

## Requirements

1. NVIDIA GPU with enough GPU Memory (> 4GB recommend, depend on your data size).

2. NVIDIA CUDA

3. Intel MKL in Intel Parallel Studio XE

4. (Optional) Microsoft Visual Studio supported by CUDA and MKL above. (Only necessary if you need to build the executable by yourself. I build it with Microsoft Visual Studio 15.6.7, with CUDA 9.2 and Intel Parallel Studio XE 2018 Update 3).

5. EEGLAB with MATLAB

6. Add MKL library directory in system path of Windows environment variables. (directory is the same or similar to “C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\redist\intel64\mkl”)


## How to use

**Option 1. Use pre-built binary**

Please download "EEGLAB_Plugin" folder, and follow the readme file in CudaICA1.0 folder. Basically you need to replace or modify EEGLAB's default "icadefs.m" and "pop_runica,m" to let CUDAICA be callable from GUI and command line. It should run under Windows 10 and Windows 7.

After installation, I recommend to do a numerical test to show that CUDAICA and EEGLAB's RUNICA should behave the same when the randomness in the algorithm are controlled. The detailed steps are in the "numerical_test" folder.


**Option 2. Build the source code**

Install all softwares in the requirements section.

The source code will only compile "cudaica_win.exe". You still need other files in "EEGLAB_Plugin" folder to run it.

Last change: 2018/09/10
