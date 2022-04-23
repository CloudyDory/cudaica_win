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

#ifdef NO_PROTO
void r250_init(sd)
int seed;
#else
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])   // void r250_init(int sd)
#endif
{
    int sd = (int)mxGetScalar(prhs[0]);
	unsigned int r250_buffer[250];
	int r250_index[1];
    // printf("Random seed = %d.\n\n",sd);
    int j, k;
	unsigned int mask, msb;
    unsigned int* rowvec1;
    int* rowvec2;

#ifdef TRUST_RAND        

#if BITS == 32 || BITS == 31       
	srand48( sd );
#else
	srand( sd );
#endif	


#else
	set_seed( sd );
#endif
	
	r250_index[0] = 0;
	for (j = 0; j < 250; j++)  {    /* fill r250 buffer with BITS-1 bit values */
#ifdef TRUST_RAND
#if BITS == 32 || BITS == 31
		r250_buffer[j] = (unsigned int)lrand48();
#else
		r250_buffer[j] = rand();
#endif
#else
		r250_buffer[j] = randlcg();
        // printf("r250_buffer[%d] = %d.\n",j,r250_buffer[j]);
#endif
    }
    
    //printf("\n");
	for (j = 0; j < 250; j++) {	/* set some MSBs to 1 */
#ifdef TRUST_RAND
		if ( rand() > HALF_RANGE ) {
			r250_buffer[j] |= MSB;
        }
#else
		if ( randlcg() > HALF_RANGE ) {
			r250_buffer[j] |= MSB;
            // printf("r250_buffer[%d] = %d.\n",j,r250_buffer[j]);
        }
#endif
    }

	msb = MSB;	        /* turn on diagonal bit */
	mask = ALL_BITS;	/* turn off the leftmost bits */
    
    //printf("\n");
	for (j = 0; j < BITS; j++)
	{
		k = STEP * j + 3;	/* select a word to operate on */
		r250_buffer[k] &= mask; /* turn off bits left of the diagonal */
		r250_buffer[k] |= msb;	/* turn on the diagonal bit */
        // printf("r250_buffer[%d] = %d.\n",j,r250_buffer[j]);
		mask >>= 1;
		msb  >>= 1;
	}
    
    // Return value
    plhs[0] = mxCreateNumericMatrix(1,250,mxUINT32_CLASS,mxREAL);
    rowvec1 = (unsigned int*)mxGetData(plhs[0]);
    for (int i=0; i<250; i++) {
        rowvec1[i] = r250_buffer[i];
    }
    
    plhs[1] = mxCreateNumericMatrix(1,1,mxINT32_CLASS,mxREAL);
    rowvec2 = (int*)mxGetData(plhs[1]);
    rowvec2[0] = r250_index[0];
}

