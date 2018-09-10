The programs in this folder demonstrates that CUDAICA and RunICA should behave the same if they use the same random number generator and block separation method.

1. (Optional) Compile the random number generator used by RunICA.
   Please skip to step 2 first. If the following step fails because of the mex files provided here, recompile them. To do this, you need to have a supported C compiler in Matlab, and run "mexcompile.m".

2. Install CudaICA1.0 plugin to EEGLAB folder. Override or modify default "icadefs.m" and "pop_runica.m" in EEGLAB according to the readme there.

3. Launch EEGLAB first, then include this folder ("numerical_test") in Matlab path. 
   Type "which runica" in Matlab command line to verify our custom version of "runica.m" overrides EEGLAB's default one.
   Then edit "CUDAICABINARY" variable in icadefs.m (near line 144) to use "CUDAICA_Win_Test.exe" in this folder.
   You are now ready to run RunICA and CUDAICA with the same random number generator and the same block separation method. 

4. Load a small, clean EEG dataset (I use 64*697500 samples). Run ICA with runica and cudaica method, and they should converge after identical steps, and produce identical components with the same order.
   
   Note that if you perform PCA operation before ICA, RUNICA and CUDAICA may return weights and sphere matrix with them same absolute values but opposite signs in some rows, and this is because of the rounding errors when calculate the sphere matrix (it is, thereotically, a diagonal matrix, but in reality the off-diagonal elements are not exactly zero, but very small numbers (1e-17 ~ 1e-18), and they may have opposite signs). As far as I know this behavior is expected and does not need to concern.

   For large dataset runica and cudaica may return similar but different results despite controling the randomness. This is the result of accumulating rounding errors when calculating on different hardware, and currently there is nothing I can do about it.

Yunhui Zhou
2018-09-10