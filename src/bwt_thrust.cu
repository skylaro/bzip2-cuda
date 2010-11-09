/*
Pseudocode:
char string;
char key -> string;
int value -> index; -> send to gpu to assign values 0-blah
thrust::stable_sort_by_key();
get sorted value
send to gpu -> sorted value, string
return string[value[tid]-1]
*/

#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/device_ptr.h>
#include <thrust/copy.h>
#include <thrust/sequence.h>
#include <thrust/sort.h>
#include <thrust/fill.h>

#include<cuda.h>

#include <iostream>
#include <cstring>

#define ARGC_EXPECTED_VAL 2

__global__ void fnKern(char *key, int *val, char *str)
{
	str[threadIdx.x] = key[val[threadIdx.x] - 1];
}

int main(int argc, char *argv[])
{
	if (argc != ARGC_EXPECTED_VAL)
	{
		std::cout << "Usage: sort_thrust <string to be sorted>\n";
		return 1;
	}
	
	int N = strlen(argv[1]);
	
	char *key, *str;
	int *val;
	
	cudaMalloc((void**)&key, sizeof(char) * N);
	cudaMalloc((void**)&val, sizeof(int) * N);
	cudaMalloc((void**)&str, sizeof(char) * N);
	
	thrust::device_ptr<char> keyD(key);	
	thrust::device_ptr<char> strD(str);
	thrust::device_ptr<int> valD(val);
	
	thrust::copy(argv[1], argv[1] + N, keyD);	//The string to be sorted is taken from the command line.
							//We originally had keyH.begin() here, but I did not see the need for a keyH at all

	thrust::sequence(valD, valD + N);	//set valD's values to a sequence from 0 to N-1
	
	thrust::stable_sort_by_key(keyD, keyD + N, valD);
	
	//thrust::copy(valD.begin(), valD.end(), valH.begin());	//Copy sorted values to host
	//thrust::copy(valH.begin(), valH.end(), valD.begin());	//Copy sorted values to device
	//Whuuut are these two lines??? Table tennis? :P
	
	fnKern<<<1, N>>>(key, val, str);
	
	//Insert vanilla code for reading the output here

	cudaFree(key);
	cudaFree(str);
	cudaFree(val);
	
	return 0;
}
