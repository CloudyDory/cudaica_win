/*
*	Copyright (C) 2011, Federico Raimondo (fraimondo@dc.uba.ar)
*  Modified to build under Windows by Yunhui Zhou.
*
*	This file is part of Cudaica.
*
*  Cudaica is free software: you can redistribute it and/or modify
*  it under the terms of the GNU General Public License as published by
*  the Free Software Foundation, either version 3 of the License, or
*  any later version.
*
*  Cudaica is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with Cudaica.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Modification Log:
 * [Project-wise]
 * 1.Use Intel MKL for the CBLAS functions. You need to install Intel MKL, and add Intel MKL path to environment variables.
 *   Otherwise you may encounter "missing dll" error.
 * 2.Add "mman.h" and "mman.c" to project to support some low-level IO functions.
 * 3.Add some necessary header files to .c and .cu files.
 *
 * [cudaica_win.c]
 * 1.Remove the "-s" option. For me it is unnecessary.
 * 2.Remove the post-processing part. Post-precessing is now down on Matlab part (cudaica.m). I remove it 
 *   because I have added "PCA" option in cudaica.m, CUDAICA.exe only operates on the saved PCA-ed data.
 *
 * [infomax.cu]
 * 1.Remove some unnecessary output on command-line.
 * 2.Step 3 and 4 of ICA is changed back to CUDA kernel function. Original code use cuBLAS functions, but seems to be slower.
 * 3."SYMBOL(xxx)" cannot be build under Windows. Directly use the symbol name here.
 * 4.Remove "cudaDeviceSynchronize()" as it is unnecessary.
 * 5.Remove "tmpweights" and "tmpwpitch" as they are unnecessary.
 * 
 * [config.cu]
 * 1.Remove the "-s" option information in help() function. 
 * 2.Remove the "PCA not supported" warning. PCA is performed in cudaica.m, CUDAICA.exe only operates on the saved PCA-ed data.
 *
 * [device.cu]
 * 1.The "fprintf(stdout, "	Global Mem: %lu\n", properties->totalGlobalMem);" and the following line in function printCapabilities()
 *	 is changed to fprintf(..., "... %llu ..."), otherwise "totalGlobalMem" is displayed as "0". 
 * 2. Remove the test for free memory part. On high-end GPUs this step is slow.
 *
 * [common.cu]
 * 1.Memory allocation to "buffer" and "floatbuffer" change from mapmalloc() to malloc() to fix "\dev\zero" not supported on Windows issue.
 *   Correspondingly, mapfree() is changed to free().
 * 2. Write data to double precision file.
 *
 * [loader.cu]
 * 1. When reading data, read double precision number because it is now saved in double precision number.
 *
 * [centering.cu]
 * 1. Use double precision when calculating the mean of each channel.
 *
 *   Yunhui Zhou, 2018/08/21
 */

#include <stdio.h>
#include <stdlib.h>
#include <config.h>
#include <device.h>
#include <preprocess.h>
#include <postprocess.h>
#include <loader.h>
#include <time.h>
#include <error.h>
#include <infomax.h>
#include <string.h>
#include <math.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char* argv[]) {
	char* programname = argv[0];

	/*
	if (isParam("-s", argv, argc)) {
		char * out = getParam("-s", argv, argc);
		int fd = open(out, O_RDWR | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR);
		if (fd == -1) {
			printf("ERROR: cannot open stdout redirection file: %s\n", out);
			exit(-1);
		}
		if (dup2(fd, STDOUT_FILENO) == -1) {
			printf("ERROR: cannot redirect stdout to file: %s\n", out);
			exit(-1);
		}
		if (dup2(fd, STDERR_FILENO) == -1) {
			fprintf(stderr, "ERROR: cannot redirect stderr to file: %s\n", out);
			exit(-1);
		}
		(void)signal(SIGHUP, SIG_IGN);

	} */
	
#ifdef DEBUG
	printf("Starting CUDAICA v1.0 with floating point numbers size = %lu bytes and DEBUG level %d\n", sizeof(real), DEBUG);
#else
	printf("Starting CUDAICA v1.0 with floating point numbers size = %lu bytes\n", sizeof(real));
#endif

	if (isParam("-h", argv, argc) || isParam("--help", argv, argc)) {
		help();
		return -1;
	}

	if (isParam("-d", argv, argc)) {
		int device = atoi(getParam("-d", argv, argc));
		selectDevice(device, 1);
	}
	else {
		selectDevice(0, 1);
	}

	if (!isParam("-f", argv, argc)) {
		printf("\nERROR::Script configuration file is mandatory\n\n\n");
		help();
		return -1;
	}
	
	char *filename = getParam("-f", argv, argc);

	eegdataset_t *dataset = malloc(sizeof(eegdataset_t));
	initDefaultConfig(dataset);
	error err = parseConfig(filename, dataset);
	checkDefaultConfig(dataset);

	
	if (err == SUCCESS) {
		fprintf(stdout, "====================================\n");
		fprintf(stdout, " Pre processing\n");
		fprintf(stdout, "====================================\n\n");
		printf("Loading dataset...");
		err = loadEEG(dataset);
		if (err != SUCCESS) exit(0);
		err = loadToDevice(dataset);
		if (err != SUCCESS) {
			printf("Cannot load data to device\n");
			return 0;
		}
		printf("Done!\n");

		printf("Centering dataset...");
		time_t start, end;
		time(&start);
		centerData(dataset);
		printf("Done!\n");
		if (dataset->config.sphering == 1 || dataset->config.sphering == 0) {
			printf("Whitening dataset...");
			whiten(dataset);
			printf("Done!\n");
		}

		printDatasetInfo(dataset);
		time(&end);
		time_t dif = difftime(end, start);
		time_t hour = (dif) / 3600;
		time_t min = (dif / 60) % 60;
		time_t sec = ((dif)) % 60;
		fprintf(stdout, "Elapsed pre-processing time = %llu h %llu m %llu s\n", hour, min, sec);
		fprintf(stdout, "====================================\n\n");
		fprintf(stdout, "====================================\n");
		fprintf(stdout, " Starting Infomax\n");
		fprintf(stdout, "====================================\n\n");
		infomax(dataset);

		// Do not post-process the weights here in order to be compatitable with pca option.
		// Post-processing will be done in matlab scipt.
		//fprintf(stdout, "====================================\n");
		//fprintf(stdout, " Post processing\n");
		//fprintf(stdout, "====================================\n\n");
		//postprocess(dataset);

		saveEEG(dataset);
		freeEEG(dataset);
	}
	
	return 0;
}

