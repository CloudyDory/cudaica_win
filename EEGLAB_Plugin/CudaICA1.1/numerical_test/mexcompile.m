% You need to have a supported compiler to do this
% I use Microsoft Visual Studio 2017
mex -setup

mex r250_init.c randlcg.c
mex r250.c 