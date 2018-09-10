/* r250.c	the r250 uniform random number algorithm

		Kirkpatrick, S., and E. Stoll, 1981; "A Very Fast
		Shift-Register Sequence Random Number Generator",
		Journal of Computational Physics, V.40

		also:

		see W.L. Maier, DDJ May 1991



*/

static char rcsid[] = "@(#)r250.c	1.2 15:50:31 11/21/94   EFC";

#include <mex.h>
#include <limits.h>
#include "r250.h"

/* set the following if you trust rand(), otherwise txhe minimal standard
   generator is used
*/
/* #define TRUST_RAND */


#ifndef TRUST_RAND
#include "randlcg.h"
#endif

/* defines to allow for 16 or 32 bit integers */
#define BITS 31


#if WORD_BIT == 32
#ifndef BITS
#define BITS	32
#endif
#else
#ifndef BITS
#define BITS    16
#endif
#endif

#if BITS == 31
#define MSB          0x40000000L
#define ALL_BITS     0x7fffffffL
#define HALF_RANGE   0x20000000L
#define STEP         7
#endif

#if BITS == 32
#define MSB          0x80000000L
#define ALL_BITS     0xffffffffL
#define HALF_RANGE   0x40000000L
#define STEP         7
#endif

#if BITS == 16
#define MSB         0x8000
#define ALL_BITS    0xffff
#define HALF_RANGE  0x4000
#define STEP        11
#endif

//unsigned int r250()		/* returns a random unsigned integer */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
	register int j;
	register unsigned int new_rand;
    unsigned int* result;
	int* result1;
	unsigned int* r250_buffer_vec = (unsigned int*)mxGetData(prhs[0]);

	// Print error if nrhs < 2
	if (nrhs < 2) {
		printf("\n[random_number, random_buffer, index] = r250(random_buffer, index)\n");
		mexErrMsgIdAndTxt("MATLAB:minrhs", "Not enough input arguments.");
	}

	// Get data to r250_index and r250_buffer
	unsigned int r250_buffer[250];
	for (int i = 0; i < 250; i++) {
		r250_buffer[i] = r250_buffer_vec[i];
	}
	int r250_index = (int)mxGetScalar(prhs[1]);

	// Generate random number
	if ( r250_index >= 147 )
		j = r250_index - 147;	/* wrap pointer around */
	else
		j = r250_index + 103;

	new_rand = r250_buffer[ r250_index ] ^ r250_buffer[ j ];
	r250_buffer[ r250_index ] = new_rand;

	if ( r250_index >= 249 )	/* increment pointer for next time */
		r250_index = 0;
	else
		r250_index++;

	//return new_rand;
    plhs[0] = mxCreateNumericMatrix(1,1,mxUINT32_CLASS,mxREAL);
	result = (unsigned int*)mxGetData(plhs[0]);
	result[0] = new_rand;

	plhs[1] = mxCreateNumericMatrix(1, 250, mxUINT32_CLASS, mxREAL);
	unsigned int* rowvec1 = (unsigned int*)mxGetData(plhs[1]);
	for (int i = 0; i<250; i++) {
		rowvec1[i] = r250_buffer[i];
	}

	plhs[2] = mxCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
	result1 = (int*)mxGetData(plhs[2]);
	result1[0] = r250_index;
}

