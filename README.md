# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

## Requirements
NVIDAI GPU with enough GPU Memory.

## How to use

**Option 1. Use pre-built binary**

Please download "EEGLAB_Plugin" folder, and follow the readme file in CudaICA1.0 folder. Basically you need to replace or modify EEGLAB's default "icadefs.m" and "pop_runica,m" to let CUDAICA be callable from GUI and command line. It should run under Windows 10 and Windows 7.

After installation, I recommend to do a numerical test to show that CUDAICA and EEGLAB's RUNICA should behave the same when the randomness in the algorithm are controlled. The detailed steps are in the "numerical_test" folder.


**Option 2. Build the source code**

Dependencies:

1. NVIDIA CUDA (current latest v9.2) (free).

2. Intel MKL in Intel Parallel Studio XE (current latest 2018 update 3) (free for student).

3. Microsoft visual studio supported by both above (current 15.6.7, latest one may not be supported).

It will only compile "cudaica_win.exe". You still need other files in "EEGLAB_Plugin" folder to run it.

Last change: 2018/09/10
