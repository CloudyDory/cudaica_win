# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

## Requirements

1. NVIDIA GPU with enough GPU Memory (> 4GB recommend, depend on your data size).

2. NVIDIA CUDA

3. Intel Math Kernel Library

4. EEGLAB with MATLAB

5. Add MKL library directory in system path of Windows environment variables. (directory is the same or similar to “C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\redist\intel64\mkl”)


## How to use

**Option 1: Use pre-built binary**

Please download "EEGLAB_Plugin" folder, and follow the readme file in CudaICA1.0 folder. Basically you need to replace or modify EEGLAB's default "icadefs.m" and "pop_runica,m" to let CUDAICA be callable from GUI and command line. It should run under Windows 10 and Windows 7.

After installation, I recommend to do a numerical test to show that CUDAICA and EEGLAB's RUNICA should behave the same when the randomness in the algorithm are controlled. The detailed steps are in the "numerical_test" folder.


**Option 2: Build the source code**

Install all softwares in the requirements section.

Install Microsoft Visual Studio supported by CUDA and MKL above (only necessary if you need to build the executable by yourself).

Tested build environment:
1. Microsoft Visual Studio 15.6.7,  CUDA 9.2,  Intel Math Kernel Library 2018 Update 3.
2. Microsoft Visual Studio 16.11.6, CUDA 11.5, Intel Math Kernel Library 2020 Update 4

The source code will only compile "cudaica_win.exe". You still need other files in "EEGLAB_Plugin" folder to run it.

## Tested environment

CUDAICA for Windows has been tested in the following machine environment:

1. Windows 10 1809, NVIDIA GTX 1050Ti, CUDA 10.1
2. Windows 10 1809, NVIDIA GTX 1080Ti, CUDA 10.1
3. Windows 7 sp1, NVIDIA RTX 2070, CUDA 10.1
4. Windows Server 2019, NVIDIA GTX 1070, CUDA 10.1
5. Windows 10 1809, NVIDIA RTX 2080, CUDA 10.1
7. Windows 10 21H1, NVIDIA RTX 2080 Super, CUDA 11.5

Last change: 2021/11/13