# cudaica_win
CUDAICA on Windows.

The source code is adapted from <https://github.com/fraimondo/cudaica> to build under Windows.

## Requirements

1. NVIDIA GPU with enough GPU Memory (> 4GB recommend, depending on your data size).

2. NVIDIA CUDA runtime
   
   recommended link -> https://developer.nvidia.com/cuda-downloads
   
   However, you may need java development environment if you want to log CUDA occupation status with Nsight Systems.
            
      recommended link -> https://github.com/openjdk/jdk
      
   For normal users (recommeded for most people): Install only the CUDA runitme and latest drivers.
   
   For developers who need to compile the source code: Install CUDA runtime, CUDA development and latest drivers.

3. Intel Math Kernel Library
   
   recommended link ->  https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html
   
   Both the old Intel Parallel Studio XE/Intel Math Kernel Library 2020 and the new Intel OneAPI base toolkit are supported.
   
   Only MKL is needed, there is no need to install other components for both normal users and developers.

4. EEGLAB with MATLAB

5. Add MKL library directory in system path of Windows environment variables. 

   Note: This path has to be added manually because the MKL installation includes 'ONEAPI_ROOT' but the syspath in 'cudaica.m' points to the 'PATH' varible.

   If you install the old Intel Parallel Studio XE or Intel MKL 2020 in the default location, the directory should be:
        “C:\Program Files (x86)\IntelSWTools\compilers_and_libraries\windows\redist\intel64\mkl”.
   
   If you install the new Intel OneAPI base toolkit in the default location, the directory should be: 
        "C:\Program Files (x86)\Intel\oneAPI\mkl\latest\redist\intel64"
   
   Note: 'cudaica.m' automatically detects whether the Windows system path contains “IntelSWTools” or “oneAPI”, and selects the correct cudaica binary exe file to use. Please make sure your Intel MKL installation path contains one of the above two patterns.


## How to use

**Option 1: Use pre-built binary**

Please download "EEGLAB_Plugin" folder, and follow the readme file in CudaICA1.1 folder. You need to replace or modify EEGLAB's default "pop_runica,m" to let CUDAICA be callable from GUI and command line. It should run under Windows 10 and Windows 7.

After installation, I recommend to do a numerical test to show that CUDAICA and EEGLAB's RUNICA should behave the same when the randomness in the algorithm are controlled. The detailed steps are in the "numerical_test" folder.

Note: 

1. Microsoft Visual Studio is NOT needed if you use the pre-built binary. 

2. In old versions of CUDAICA_Win you also need to modify the EEGLAB's default "icadefs.m" file. This is not needed now.

**Option 2: Build the source code**

Install Microsoft Visual Studio supported by CUDA and MKL first. Note: the latest Visual Studio is not always supported by CUDA and MKL. Check the documents of CUDA and MKL before you install visual studio.

Install all softwares in the requirements section. Make sure to install visual studio integration in CUDA and MKL.

Tested build environment:
1. Microsoft Visual Studio 15.6.7,  CUDA 9.2,  Intel Math Kernel Library 2018 Update 3
2. Microsoft Visual Studio 16.11.6, CUDA 11.5, Intel Math Kernel Library 2020 Update 4
3. Microsoft Visual Studio 17.1.5,  CUDA 11.6, Intel OneAPI base toolkit 2022

The source code will only compile "cudaica_win_*.exe". You still need other files in "EEGLAB_Plugin" folder to run it.

## Tested environment

CUDAICA for Windows has been tested in the following machine environment:

1. Windows 10 1809, NVIDIA GTX 1050Ti, CUDA 10.1
2. Windows 10 1809, NVIDIA GTX 1080Ti, CUDA 10.1
3. Windows 7 SP1, NVIDIA RTX 2070, CUDA 10.1 (no longer tested in 2022)
4. Windows Server 2019, NVIDIA GTX 1070, CUDA 10.1
5. Windows 10 1809, NVIDIA RTX 2080, CUDA 10.1
6. Windows 10 21H1, NVIDIA RTX 2080 Super, CUDA 11.5
7. Windows 10 21H2, NVIDIA GTX 1050Ti, CUDA 11.6
8. Windows 11 21H2, NVIDIA RTX 3070Ti, CUDA 11.7

Last change: 2022/08/15
