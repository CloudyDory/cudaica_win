The programs in this folder demonstrates that CUDAICA and RunICA should behave the same if they use the same random number generator and block separation method.

1. (Optional) Compile the random number generator used by RunICA.
   Please skip to step 3 first. If the following step fails because of the mex files provided here, recompile them. To do this, you need to have a supported C compiler in Matlab, and run "mexcompile.m".

2. (Optional) Compile CUDAICA with fixed random number generator
   Please skip to step 3 first. If the following step fails because of the CUDAICA_Win_Text.exe file provided here, recompile it. To do this, search for "set->config.seed = (int)time(NULL);" in the source code file "config.cu" (should be near line 500), and change it to "set->config.seed = (int)1;". Recompile the project.

3. Install CudaICA1.1 plugin to EEGLAB folder. Override or modify default "pop_runica.m" in EEGLAB according to the readme there.

4. Launch EEGLAB first, then include this folder ("numerical_test") in Matlab path. 
   Type "which runica" in Matlab command line to verify our custom version of "runica.m" overrides EEGLAB's default one.
   Then edit "CUDAICABINARY" variable in cudaica.m (near line 130) to use "cudaica_win_test_mkl2020.exe" or "cudaica_win_test_oneapi.exe" (depending on whether you have installed the old Intel MKL 2020 or the new Intel OneAPI base toolkit) in *this* folder.
   You are now ready to run RunICA and CUDAICA with the same random number generator and the same block separation method. 

5. Load a small, clean EEG dataset (I use 64*697500 samples). Run ICA with runica and cudaica method, and they should converge after identical steps, and produce identical components with the same order.
   
   Note that if you perform PCA operation before ICA, RUNICA and CUDAICA may return weights and sphere matrix with them same absolute values but opposite signs in some rows, and this is because of the rounding errors when calculate the sphere matrix (it is, thereotically, a diagonal matrix, but in reality the off-diagonal elements are not exactly zero, but very small numbers (1e-17 ~ 1e-18), and they may have opposite signs). As far as I know this behavior is expected and does not need to concern.

   For large dataset runica and cudaica may return similar but different results despite controling the randomness. This is the result of accumulating rounding errors when calculating on different hardware, and currently there is nothing I can do about it.

Yunhui Zhou
2022-04-23
