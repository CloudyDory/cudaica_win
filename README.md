# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

## How to use

**Option 1. Use pre-built binary**

Please download "EEGLAB_Plugin" folder, and follow the readme file in CudaICA1.0 folder. It should run under Windows 10 and Windows 7.

**Option 2. Build the source code**

Dependencies:

NVIDIA CUDA (current latest v9.2) (free).

Intel MKL in Intel Parallel Studio XE (current latest 2018 update 3) (free for student).

Microsoft visual studio supported by both above (current 15.6.7, latest one may not be supported).

It will only compile "cudaica_win.exe". You still need other files in "EEGLAB_Plugin" folder to run it.

Last change: 2018/09/10
