#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "math_functions.h"
#include "round.cuh"

#include <cmath>
#include <stdio.h>
#include <curand_kernel.h>
#include "utils.h"
#include <thrust\device_ptr.h>
#include <thrust\sort.h>
#include <map>
#include <string>
#include <sstream>

//#pragma comment(lib, "curand.lib")

using std::map;
using std::string;
using std::stringstream;

#define INDEX_SIZE_IN_BYTES 8
#define EXTRACT_9 0x7fffffffffffffff
#define EXTRACT_8 0x00ffffffffffffff
#define EXTRACT_7 0x0001ffffffffffff
#define EXTRACT_6 0x000003ffffffffff

#define ROTR32(x, n)  (((0U + (x)) << (32 - (n))) | ((x) >> (n)))  // Assumes that x is uint32_t and 0 < n < 32

#define LOADSCHEDULE(i)  \
		schedule[i] = (uint32_t)data[i * 4 + 0] << 24  \
		            | (uint32_t)data[i * 4 + 1] << 16  \
		            | (uint32_t)data[i * 4 + 2] <<  8  \
		            | (uint32_t)data[i * 4 + 3] <<  0;

#define SCHEDULE(i)  \
		schedule[i] = 0U + schedule[i - 16] + schedule[i - 7]  \
			+ (ROTR32(schedule[i - 15], 7) ^ ROTR32(schedule[i - 15], 18) ^ (schedule[i - 15] >> 3))  \
			+ (ROTR32(schedule[i - 2], 17) ^ ROTR32(schedule[i - 2], 19) ^ (schedule[i - 2] >> 10));

//#define SCHEDULE(i) \
//	asm("{\n\t" \
//		".reg .u32 t1;\n\t" \
//		".reg .u32 t2;\n\t" \
//		".reg .u32 t3;\n\t" \
//		".reg .u32 s1;\n\t" \
//		".reg .u32 s2;\n\t" \
//		".reg .u32 s3;\n\t" \
//		".reg .u32 s4;\n\t" \
//		"mov.u32 s1, %1;\n\t" \
//		"mov.u32 s2, %2;\n\t" \
//		"mov.u32 s3, %3;\n\t" \
//		"mov.u32 s4, %4;\n\t" \
//		"add.u32 t1, s1, s2;\n\t" \
//		"shf.r.clamp.b32 t2, s3, s3, 7;\n\t" \
//		"shf.r.clamp.b32 t3, s3, s3, 18;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"shr.u32 t3, s3, 3;\n\t" \
//		"xor.b32 t2, t2 ,t3;\n\t" \
//		"add.u32 t1, t1, t2;\n\t" \
//		"shf.r.clamp.b32 t2, s4, s4, 17;\n\t" \
//		"shf.r.clamp.b32 t3, s4, s4, 19;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"shr.u32 t3, %4, 10;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"add.u32 t1, t1, t2;\n\t" \
//		"mov.u32 %0, t1;\n\t" \
//		"}" \
//		: "=r"(schedule[i]) : "r"(schedule[i - 16]), "r"(schedule[i - 7]), "r"(schedule[i - 15]), "r"(schedule[i - 2]));

//#define SCHEDULE(i) \
//	asm("{\n\t" \
//		".reg .u32 t2;\n\t" \
//		".reg .u32 t3;\n\t" \
//		"shf.r.clamp.b32 t2, %3, %3, 7;\n\t" \
//		"shf.r.clamp.b32 t3, %3, %3, 18;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"shr.u32 t3, %3, 3;\n\t" \
//		"xor.b32 t2, t2 ,t3;\n\t" \
//		"add.u32 %0, %0, t2;\n\t" \
//		"shf.r.clamp.b32 t2, %4, %4, 17;\n\t" \
//		"shf.r.clamp.b32 t3, %4, %4, 19;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"shr.u32 t3, %4, 10;\n\t" \
//		"xor.b32 t2, t2, t3;\n\t" \
//		"add.u32 %0, %0, t2;\n\t" \
//		"add.u32 t2, %1, %2;\n\t" \
//		"add.u32 %0, %0, t2;\n\t" \
//		"}" \
//		: "=r"(schedule[i]) : "r"(schedule[i - 16]), "r"(schedule[i - 7]), "r"(schedule[i - 15]), "r"(schedule[i - 2]));

#define ROUND(a, b, c, d, e, f, g, h, i, k) \
		h = 0U + h + (ROTR32(e, 6) ^ ROTR32(e, 11) ^ ROTR32(e, 25)) + (g ^ (e & (f ^ g))) + UINT32_C(k) + schedule[i];  \
		d = 0U + d + h;  \
		h = 0U + h + (ROTR32(a, 2) ^ ROTR32(a, 13) ^ ROTR32(a, 22)) + ((a & (b | c)) | (b & c));

#define CUDA_CALL(x) {const cudaError_t a = (x);if(a!=cudaSuccess){printf("\nCUDA Error:%s(err_num=%d)\n",cudaGetErrorString(a),a);}}
#define CURAND_CALL(x) do { if((x)!=CURAND_STATUS_SUCCESS) { \ printf("Error at %s:%d\n",__FILE__,__LINE__);\ return EXIT_FAILURE;}} while(0)

//__shared__ uint k[64];

__constant__ char constantAreaPlainCharSet[36];

__shared__ char plainCharSet[384][95];

__shared__ uint state[384][8];

struct ChainComparator {
	__host__ __device__
		bool operator()(const struct Chain& lhs, const struct Chain& rhs) {
		return lhs.indexE < rhs.indexE;
	}
};

struct HashCompartor {
	__host__ __device__
		bool operator()(const struct PasswordMapping& lhs, const struct PasswordMapping& rhs) {
		//const ulong* lhsP = (const ulong*)lhs.hash;
		//const ulong* rhsP = (const ulong*)rhs.hash;
		//ulong lhs4 = *(lhsP + 3);
		//ulong lhs3 = *(lhsP + 2);
		//ulong lhs2 = *(lhsP + 1);
		//ulong lhs1 = *(lhsP);
		//ulong rhs4 = *(rhsP + 3);
		//ulong rhs3 = *(rhsP + 2);
		//ulong rhs2 = *(rhsP + 1);
		//ulong rhs1 = *(rhsP);
		//return lhs1 < rhs1
		//	|| lhs1 == rhs1 && lhs2 < rhs2
		//	|| lhs1 == rhs1 && lhs2 == rhs2 && lhs3 < rhs3
		//	|| lhs1 == rhs1 && lhs2 == rhs2 && lhs3 == rhs3 && lhs4 < rhs4;
		bool flap = true;
		for (int i = 0; i < 32; i++) {
			if (lhs.hash[i] > rhs.hash[i]) {
				flap = false;
				break;
			}
		}
		if (flap) {
			return true;
		}
		else {
			return false;
		}
	}
};

void QSort(struct PasswordMapping* mappings, uint32_t CHAINS_SIZE) {
	thrust::device_ptr<struct PasswordMapping> thrustChainP(mappings);
	thrust::sort(thrustChainP, thrustChainP + CHAINS_SIZE, HashCompartor());
}

__device__ void indexToPlain(ulong index, const uint8_t plainLength,
	const uint8_t plainCharsetSize, char* plain)
{
	for (int i = plainLength - 1;i >= 0;i--) {
		plain[i] = index % plainCharsetSize;
		index /= plainCharsetSize;
	}
}

__device__ inline void indexToPlain(ulong index, char* plain, const uint8_t plainLength, const char* charSet, const unsigned int charSetSize)
{
	for (int i = plainLength - 1; i >= 0; i--) {
		plain[i] = charSet[(index & 0x7f) % charSetSize];
		index >>= 7;
	}
}

/*__device__ ulong plainToIndex(const char* plain, size_t plainLength, const char* charSet, size_t charSetSize, map<char, size_t>* charIndexMap)
{
ulong index = 0;
int i;

for (i = 0;i<plainLength - 1;i++) {
index += charIndexMap->operator[](plain[i]) & 0x7f;
index <<= 7;
}
index += charIndexMap->operator[](plain[i]) & 0x7f;
return index;
}*/

__device__ inline ulong hashToIndexPaperVersion(unsigned char* hash, int pos, const uint8_t plainCharSetSize)
{
	unsigned int* hashP = (unsigned int*)hash;
	unsigned int p0 = *(hashP + 4) ^ pos;
	unsigned int p2 = *(hashP + 5) ^ (pos >> 12);
	unsigned int p4 = *(hashP + 6) ^ (pos >> 24);
	unsigned int p6 = *(hashP + 7);
	char* plainCharSetP = plainCharSet[threadIdx.x];

	unsigned __int16 b0 = plainCharSetP[p0 % plainCharSetSize] << 8 | plainCharSetP[(p0 >> 16) % plainCharSetSize];
	unsigned __int16 b1 = plainCharSetP[p2 % plainCharSetSize] << 8 | plainCharSetP[(p2 >> 16) % plainCharSetSize];
	unsigned __int16 b2 = plainCharSetP[p4 % plainCharSetSize] << 8 | plainCharSetP[(p4 >> 16) % plainCharSetSize];
	unsigned __int16 b3 = plainCharSetP[p6 % plainCharSetSize] << 8 | plainCharSetP[(p6 >> 16) % plainCharSetSize];
	/*unsigned __int16 b0 = constantAreaPlainCharSet[p0 % plainCharSetSize] << 8 | constantAreaPlainCharSet[(p0 >> 16) % plainCharSetSize];
	unsigned __int16 b1 = constantAreaPlainCharSet[p2 % plainCharSetSize] << 8 | constantAreaPlainCharSet[(p2 >> 16) % plainCharSetSize];
	unsigned __int16 b2 = constantAreaPlainCharSet[p4 % plainCharSetSize] << 8 | constantAreaPlainCharSet[(p4 >> 16) % plainCharSetSize];
	unsigned __int16 b3 = constantAreaPlainCharSet[p6 % plainCharSetSize] << 8 | constantAreaPlainCharSet[(p6 >> 16) % plainCharSetSize];*/
	ulong index = 0;
	index += b0;
	index <<= 16;
	index += b1;
	index <<= 16;
	index += b2;
	index <<= 16;
	index += b3;
	return index;
}

__device__ inline ulong hashToIndexWithoutCharSet(unsigned char* hash, int pos, const uint8_t plainCharSetSize)
{
	unsigned int* hashP = (unsigned int*)hash;
	unsigned int p0 = *(hashP + 4) ^ pos;
	unsigned int p2 = *(hashP + 5) ^ (pos >> 12);
	unsigned int p4 = *(hashP + 6) ^ (pos >> 24);
	unsigned int p6 = *(hashP + 7);

	unsigned __int16 b0 = ((p0 % plainCharSetSize) << 8) | ((p0 >> 16) % plainCharSetSize);
	unsigned __int16 b1 = ((p2 % plainCharSetSize) << 8) | ((p2 >> 16) % plainCharSetSize);
	unsigned __int16 b2 = ((p4 % plainCharSetSize) << 8) | ((p4 >> 16) % plainCharSetSize);
	unsigned __int16 b3 = ((p6 % plainCharSetSize) << 8) | ((p6 >> 16) % plainCharSetSize);

	ulong index = 0;
	index += b0;
	index <<= 16;
	index += b1;
	index <<= 16;
	index += b2;
	index <<= 16;
	index += b3;
	return index;
}

__device__ inline void plainToHashWithInlinePTX(const char* plain, const uint8_t length, unsigned char* res) {
	unsigned int bitlen0 = 0;
	unsigned int bitlen1 = 0;
	unsigned int stateP[8];

	//unsigned int* stateP = state[threadIdx.x];

	unsigned char data[64];

	unsigned int l;

	for (l = 0; l < length; ++l) {
		data[l] = plain[l];
	}


	stateP[0] = 0x6a09e667;
	stateP[1] = 0xbb67ae85;
	stateP[2] = 0x3c6ef372;
	stateP[3] = 0xa54ff53a;
	stateP[4] = 0x510e527f;
	stateP[5] = 0x9b05688c;
	stateP[6] = 0x1f83d9ab;
	stateP[7] = 0x5be0cd19;


	data[l++] = 0x80;
	while (l < 56)
		data[l++] = 0x00;


	//// Append to the padding the total message's length in bits and transform. 
	DBL_INT_ADD(bitlen0, bitlen1, length * 8);

	data[63] = bitlen0;
	data[62] = bitlen0 >> 8;
	data[61] = bitlen0 >> 16;
	data[60] = bitlen0 >> 24;
	data[59] = bitlen1;
	data[58] = bitlen1 >> 8;
	data[57] = bitlen1 >> 16;
	data[56] = bitlen1 >> 24;

	uint32_t schedule[16];

	uint32_t a = stateP[0];
	uint32_t b = stateP[1];
	uint32_t c = stateP[2];
	uint32_t d = stateP[3];
	uint32_t e = stateP[4];
	uint32_t f = stateP[5];
	uint32_t g = stateP[6];
	uint32_t h = stateP[7];

	ROUNDa(0, a, b, c, d, e, f, g, h, 0x428A2F98)
	ROUNDa(1, h, a, b, c, d, e, f, g, 0x71374491)
	ROUNDa(2, g, h, a, b, c, d, e, f, -0x4A3F0431)
	ROUNDa(3, f, g, h, a, b, c, d, e, -0x164A245B)
	ROUNDa(4, e, f, g, h, a, b, c, d, 0x3956C25B)
	ROUNDa(5, d, e, f, g, h, a, b, c, 0x59F111F1)
	ROUNDa(6, c, d, e, f, g, h, a, b, -0x6DC07D5C)
	ROUNDa(7, b, c, d, e, f, g, h, a, -0x54E3A12B)
	ROUNDa(8, a, b, c, d, e, f, g, h, -0x27F85568)
	ROUNDa(9, h, a, b, c, d, e, f, g, 0x12835B01)
	ROUNDa(10, g, h, a, b, c, d, e, f, 0x243185BE)
	ROUNDa(11, f, g, h, a, b, c, d, e, 0x550C7DC3)
	ROUNDa(12, e, f, g, h, a, b, c, d, 0x72BE5D74)
	ROUNDa(13, d, e, f, g, h, a, b, c, -0x7F214E02)
	ROUNDa(14, c, d, e, f, g, h, a, b, -0x6423F959)
	ROUNDa(15, b, c, d, e, f, g, h, a, -0x3E640E8C)
	ROUND16(16, a, b, c, d, e, f, g, h, -0x1B64963F)
	ROUND17(17, h, a, b, c, d, e, f, g, -0x1041B87A)
	ROUND18(18, g, h, a, b, c, d, e, f, 0x0FC19DC6)
	ROUND19(19, f, g, h, a, b, c, d, e, 0x240CA1CC)
	ROUND20(20, e, f, g, h, a, b, c, d, 0x2DE92C6F)
	ROUND21(21, d, e, f, g, h, a, b, c, 0x4A7484AA)
	ROUND22(22, c, d, e, f, g, h, a, b, 0x5CB0A9DC)
	ROUND23(23, b, c, d, e, f, g, h, a, 0x76F988DA)
	ROUND24(24, a, b, c, d, e, f, g, h, -0x67C1AEAE)
	ROUND25(25, h, a, b, c, d, e, f, g, -0x57CE3993)
	ROUND26(26, g, h, a, b, c, d, e, f, -0x4FFCD838)
	ROUND27(27, f, g, h, a, b, c, d, e, -0x40A68039)
	ROUND28(28, e, f, g, h, a, b, c, d, -0x391FF40D)
	ROUND29(29, d, e, f, g, h, a, b, c, -0x2A586EB9)
	ROUND30(30, c, d, e, f, g, h, a, b, 0x06CA6351)
	ROUND31(31, b, c, d, e, f, g, h, a, 0x14292967)
	ROUND16(32, a, b, c, d, e, f, g, h, 0x27B70A85)
	ROUND17(33, h, a, b, c, d, e, f, g, 0x2E1B2138)
	ROUND18(34, g, h, a, b, c, d, e, f, 0x4D2C6DFC)
	ROUND19(35, f, g, h, a, b, c, d, e, 0x53380D13)
	ROUND20(36, e, f, g, h, a, b, c, d, 0x650A7354)
	ROUND21(37, d, e, f, g, h, a, b, c, 0x766A0ABB)
	ROUND22(38, c, d, e, f, g, h, a, b, -0x7E3D36D2)
	ROUND23(39, b, c, d, e, f, g, h, a, -0x6D8DD37B)
	ROUND24(40, a, b, c, d, e, f, g, h, -0x5D40175F)
	ROUND25(41, h, a, b, c, d, e, f, g, -0x57E599B5)
	ROUND26(42, g, h, a, b, c, d, e, f, -0x3DB47490)
	ROUND27(43, f, g, h, a, b, c, d, e, -0x3893AE5D)
	ROUND28(44, e, f, g, h, a, b, c, d, -0x2E6D17E7)
	ROUND29(45, d, e, f, g, h, a, b, c, -0x2966F9DC)
	ROUND30(46, c, d, e, f, g, h, a, b, -0x0BF1CA7B)
	ROUND31(47, b, c, d, e, f, g, h, a, 0x106AA070)
	ROUND16(48, a, b, c, d, e, f, g, h, 0x19A4C116)
	ROUND17(49, h, a, b, c, d, e, f, g, 0x1E376C08)
	ROUND18(50, g, h, a, b, c, d, e, f, 0x2748774C)
	ROUND19(51, f, g, h, a, b, c, d, e, 0x34B0BCB5)
	ROUND20(52, e, f, g, h, a, b, c, d, 0x391C0CB3)
	ROUND21(53, d, e, f, g, h, a, b, c, 0x4ED8AA4A)
	ROUND22(54, c, d, e, f, g, h, a, b, 0x5B9CCA4F)
	ROUND23(55, b, c, d, e, f, g, h, a, 0x682E6FF3)
	ROUND24(56, a, b, c, d, e, f, g, h, 0x748F82EE)
	ROUND25(57, h, a, b, c, d, e, f, g, 0x78A5636F)
	ROUND26(58, g, h, a, b, c, d, e, f, -0x7B3787EC)
	ROUND27(59, f, g, h, a, b, c, d, e, -0x7338FDF8)
	ROUND28(60, e, f, g, h, a, b, c, d, -0x6F410006)
	ROUND29(61, d, e, f, g, h, a, b, c, -0x5BAF9315)
	ROUND30(62, c, d, e, f, g, h, a, b, -0x41065C09)
	ROUND31(63, b, c, d, e, f, g, h, a, -0x398E870E)

	stateP[0] += a;
	stateP[1] += b;
	stateP[2] += c;
	stateP[3] += d;
	stateP[4] += e;
	stateP[5] += f;
	stateP[6] += g;
	stateP[7] += h;

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash. 

	for (int i = 0; i < 4; ++i) {
		l = i << 3;
		*(res) = (stateP[0] >> (24 - l)) & 0x000000ff;
		*(res + 4) = (stateP[1] >> (24 - l)) & 0x000000ff;
		*(res + 8) = (stateP[2] >> (24 - l)) & 0x000000ff;
		*(res + 12) = (stateP[3] >> (24 - l)) & 0x000000ff;
		*(res + 16) = (stateP[4] >> (24 - l)) & 0x000000ff;
		*(res + 20) = (stateP[5] >> (24 - l)) & 0x000000ff;
		*(res + 24) = (stateP[6] >> (24 - l)) & 0x000000ff;
		*(res + 28) = (stateP[7] >> (24 - l)) & 0x000000ff;
		++res;
	}

	//unsigned int* resP = (unsigned int*)res;
	//unsigned char* stateCP = (unsigned char*)stateP;

	//*(resP) = (((unsigned int)*(stateCP)<<0)| ((unsigned int)*(stateCP+1)<<8)| ((unsigned int)*(stateCP+2)<<16)| ((unsigned int)*(stateCP+3)<<24));
	//*(resP+1) = ((unsigned int)(*(stateCP+4) << 0) | ((unsigned int)*(stateCP + 5) << 8) | ((unsigned int)*(stateCP + 6) << 16) | ((unsigned int)*(stateCP + 7) << 24));
	//*(resP+2) = (((unsigned int)*(stateCP+8) << 0) | ((unsigned int)*(stateCP + 9) << 8) | ((unsigned int)*(stateCP + 10) << 16) | ((unsigned int)*(stateCP + 11) << 24));
	//*(resP+3) = (((unsigned int)*(stateCP+12) << 0) | ((unsigned int)*(stateCP + 13) << 8) | ((unsigned int)*(stateCP + 14) << 16) | ((unsigned int)*(stateCP + 15) << 24));
	//*(resP+4) = (((unsigned int)*(stateCP+16) << 0) | ((unsigned int)*(stateCP + 17) << 8) | ((unsigned int)*(stateCP + 18) << 16) | ((unsigned int)*(stateCP + 19) << 24));
	//*(resP+5) = (((unsigned int)*(stateCP+20) << 0) | ((unsigned int)*(stateCP + 21) << 8) | ((unsigned int)*(stateCP + 22) << 16) | ((unsigned int)*(stateCP + 23) << 24));
	//*(resP+6) = (((unsigned int)*(stateCP+24) << 0) | ((unsigned int)*(stateCP + 25) << 8) | ((unsigned int)*(stateCP + 26) << 16) | ((unsigned int)*(stateCP + 27) << 24));
	//*(resP+7) = (((unsigned int)*(stateCP+28) << 0) | ((unsigned int)*(stateCP + 29) << 8) | ((unsigned int)*(stateCP + 30) << 16) | ((unsigned int)*(stateCP + 31) << 24));

	///**((unsigned int*)res) = ((*((unsigned char*)stateP) << 0) | (*((unsigned char*)stateP + 1) << 8) | (*((unsigned char*)stateP + 2) << 16) | (*((unsigned char*)stateP + 3) << 24));
	//*((unsigned int*)res + 1) = ((*((unsigned char*)stateP + 4) << 0) | (*((unsigned char*)stateP + 5) << 8) | (*((unsigned char*)stateP + 6) << 16) | (*((unsigned char*)stateP + 7) << 24));
	//*((unsigned int*)res + 2) = ((*((unsigned char*)stateP + 8) << 0) | (*((unsigned char*)stateP + 9) << 8) | (*((unsigned char*)stateP + 10) << 16) | (*((unsigned char*)stateP + 11) << 24));
	//*((unsigned int*)res + 3) = ((*((unsigned char*)stateP + 12) << 0) | (*((unsigned char*)stateP + 13) << 8) | (*((unsigned char*)stateP + 14) << 16) | (*((unsigned char*)stateP + 15) << 24));
	//*((unsigned int*)res + 4) = ((*((unsigned char*)stateP + 16) << 0) | (*((unsigned char*)stateP + 17) << 8) | (*((unsigned char*)stateP + 18) << 16) | (*((unsigned char*)stateP + 19) << 24));
	//*((unsigned int*)res + 5) = ((*((unsigned char*)stateP + 20) << 0) | (*((unsigned char*)stateP + 21) << 8) | (*((unsigned char*)stateP + 22) << 16) | (*((unsigned char*)stateP + 23) << 24));
	//*((unsigned int*)res + 6) = ((*((unsigned char*)stateP + 24) << 0) | (*((unsigned char*)stateP + 25) << 8) | (*((unsigned char*)stateP + 26) << 16) | (*((unsigned char*)stateP + 27) << 24));
	//*((unsigned int*)res + 7) = ((*((unsigned char*)stateP + 28) << 0) | (*((unsigned char*)stateP + 29) << 8) | (*((unsigned char*)stateP + 30) << 16) | (*((unsigned char*)stateP + 31) << 24));*/
}

__device__ inline void plainToHashWithInlinePTX(ulong index, const uint8_t length, unsigned char* res, const uint8_t charSetSize) {
	unsigned int bitlen0 = 0;
	unsigned int bitlen1 = 0;
	unsigned int stateP[8];

	unsigned char data[64];

	unsigned int l;

	// reduct the index in the plain space
	for (l = length - 1; l >= 1; l--) {
		data[l] = (index & 0x7f) % charSetSize + 32;
		index >>= 7;
	}
	data[0] = (index & 0x7f) % charSetSize + 32;
	l = length;

	stateP[0] = 0x6a09e667;
	stateP[1] = 0xbb67ae85;
	stateP[2] = 0x3c6ef372;
	stateP[3] = 0xa54ff53a;
	stateP[4] = 0x510e527f;
	stateP[5] = 0x9b05688c;
	stateP[6] = 0x1f83d9ab;
	stateP[7] = 0x5be0cd19;


	data[l++] = 0x80;
	while (l < 56)
		data[l++] = 0x00;


	//// Append to the padding the total message's length in bits and transform. 
	DBL_INT_ADD(bitlen0, bitlen1, length * 8);

	data[63] = bitlen0;
	data[62] = bitlen0 >> 8;
	data[61] = bitlen0 >> 16;
	data[60] = bitlen0 >> 24;
	data[59] = bitlen1;
	data[58] = bitlen1 >> 8;
	data[57] = bitlen1 >> 16;
	data[56] = bitlen1 >> 24;

	uint32_t schedule[16];

	uint32_t a = stateP[0];
	uint32_t b = stateP[1];
	uint32_t c = stateP[2];
	uint32_t d = stateP[3];
	uint32_t e = stateP[4];
	uint32_t f = stateP[5];
	uint32_t g = stateP[6];
	uint32_t h = stateP[7];

	ROUNDa(0, a, b, c, d, e, f, g, h, 0x428A2F98)
	ROUNDa(1, h, a, b, c, d, e, f, g, 0x71374491)
	ROUNDa(2, g, h, a, b, c, d, e, f, -0x4A3F0431)
	ROUNDa(3, f, g, h, a, b, c, d, e, -0x164A245B)
	ROUNDa(4, e, f, g, h, a, b, c, d, 0x3956C25B)
	ROUNDa(5, d, e, f, g, h, a, b, c, 0x59F111F1)
	ROUNDa(6, c, d, e, f, g, h, a, b, -0x6DC07D5C)
	ROUNDa(7, b, c, d, e, f, g, h, a, -0x54E3A12B)
	ROUNDa(8, a, b, c, d, e, f, g, h, -0x27F85568)
	ROUNDa(9, h, a, b, c, d, e, f, g, 0x12835B01)
	ROUNDa(10, g, h, a, b, c, d, e, f, 0x243185BE)
	ROUNDa(11, f, g, h, a, b, c, d, e, 0x550C7DC3)
	ROUNDa(12, e, f, g, h, a, b, c, d, 0x72BE5D74)
	ROUNDa(13, d, e, f, g, h, a, b, c, -0x7F214E02)
	ROUNDa(14, c, d, e, f, g, h, a, b, -0x6423F959)
	ROUNDa(15, b, c, d, e, f, g, h, a, -0x3E640E8C)
	ROUND16(16, a, b, c, d, e, f, g, h, -0x1B64963F)
	ROUND17(17, h, a, b, c, d, e, f, g, -0x1041B87A)
	ROUND18(18, g, h, a, b, c, d, e, f, 0x0FC19DC6)
	ROUND19(19, f, g, h, a, b, c, d, e, 0x240CA1CC)
	ROUND20(20, e, f, g, h, a, b, c, d, 0x2DE92C6F)
	ROUND21(21, d, e, f, g, h, a, b, c, 0x4A7484AA)
	ROUND22(22, c, d, e, f, g, h, a, b, 0x5CB0A9DC)
	ROUND23(23, b, c, d, e, f, g, h, a, 0x76F988DA)
	ROUND24(24, a, b, c, d, e, f, g, h, -0x67C1AEAE)
	ROUND25(25, h, a, b, c, d, e, f, g, -0x57CE3993)
	ROUND26(26, g, h, a, b, c, d, e, f, -0x4FFCD838)
	ROUND27(27, f, g, h, a, b, c, d, e, -0x40A68039)
	ROUND28(28, e, f, g, h, a, b, c, d, -0x391FF40D)
	ROUND29(29, d, e, f, g, h, a, b, c, -0x2A586EB9)
	ROUND30(30, c, d, e, f, g, h, a, b, 0x06CA6351)
	ROUND31(31, b, c, d, e, f, g, h, a, 0x14292967)
	ROUND16(32, a, b, c, d, e, f, g, h, 0x27B70A85)
	ROUND17(33, h, a, b, c, d, e, f, g, 0x2E1B2138)
	ROUND18(34, g, h, a, b, c, d, e, f, 0x4D2C6DFC)
	ROUND19(35, f, g, h, a, b, c, d, e, 0x53380D13)
	ROUND20(36, e, f, g, h, a, b, c, d, 0x650A7354)
	ROUND21(37, d, e, f, g, h, a, b, c, 0x766A0ABB)
	ROUND22(38, c, d, e, f, g, h, a, b, -0x7E3D36D2)
	ROUND23(39, b, c, d, e, f, g, h, a, -0x6D8DD37B)
	ROUND24(40, a, b, c, d, e, f, g, h, -0x5D40175F)
	ROUND25(41, h, a, b, c, d, e, f, g, -0x57E599B5)
	ROUND26(42, g, h, a, b, c, d, e, f, -0x3DB47490)
	ROUND27(43, f, g, h, a, b, c, d, e, -0x3893AE5D)
	ROUND28(44, e, f, g, h, a, b, c, d, -0x2E6D17E7)
	ROUND29(45, d, e, f, g, h, a, b, c, -0x2966F9DC)
	ROUND30(46, c, d, e, f, g, h, a, b, -0x0BF1CA7B)
	ROUND31(47, b, c, d, e, f, g, h, a, 0x106AA070)
	ROUND16(48, a, b, c, d, e, f, g, h, 0x19A4C116)
	ROUND17(49, h, a, b, c, d, e, f, g, 0x1E376C08)
	ROUND18(50, g, h, a, b, c, d, e, f, 0x2748774C)
	ROUND19(51, f, g, h, a, b, c, d, e, 0x34B0BCB5)
	ROUND20(52, e, f, g, h, a, b, c, d, 0x391C0CB3)
	ROUND21(53, d, e, f, g, h, a, b, c, 0x4ED8AA4A)
	ROUND22(54, c, d, e, f, g, h, a, b, 0x5B9CCA4F)
	ROUND23(55, b, c, d, e, f, g, h, a, 0x682E6FF3)
	ROUND24(56, a, b, c, d, e, f, g, h, 0x748F82EE)
	ROUND25(57, h, a, b, c, d, e, f, g, 0x78A5636F)
	ROUND26(58, g, h, a, b, c, d, e, f, -0x7B3787EC)
	ROUND27(59, f, g, h, a, b, c, d, e, -0x7338FDF8)
	ROUND28(60, e, f, g, h, a, b, c, d, -0x6F410006)
	ROUND29(61, d, e, f, g, h, a, b, c, -0x5BAF9315)
	ROUND30(62, c, d, e, f, g, h, a, b, -0x41065C09)
	ROUND31(63, b, c, d, e, f, g, h, a, -0x398E870E)

	stateP[0] += a;
	stateP[1] += b;
	stateP[2] += c;
	stateP[3] += d;
	stateP[4] += e;
	stateP[5] += f;
	stateP[6] += g;
	stateP[7] += h;

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash. 

	for (int i = 0; i < 4; ++i) {
		l = i << 3;
		*(res) = (stateP[0] >> (24 - l)) & 0x000000ff;
		*(res + 4) = (stateP[1] >> (24 - l)) & 0x000000ff;
		*(res + 8) = (stateP[2] >> (24 - l)) & 0x000000ff;
		*(res + 12) = (stateP[3] >> (24 - l)) & 0x000000ff;
		*(res + 16) = (stateP[4] >> (24 - l)) & 0x000000ff;
		*(res + 20) = (stateP[5] >> (24 - l)) & 0x000000ff;
		*(res + 24) = (stateP[6] >> (24 - l)) & 0x000000ff;
		*(res + 28) = (stateP[7] >> (24 - l)) & 0x000000ff;
		++res;
	}
}

__device__ inline void plainToHash(char* plain, const uint8_t length, unsigned char* res)
{
	unsigned int bitlen0 = 0;
	unsigned int bitlen1 = 0;
	//unsigned int stateP[8];

	unsigned char data[64];

	unsigned int l;

	for (l = 0; l < length; ++l) {
		data[l] = plain[l];
	}

	uint* stateP = state[threadIdx.x];

	stateP[0] = 0x6a09e667;
	stateP[1] = 0xbb67ae85;
	stateP[2] = 0x3c6ef372;
	stateP[3] = 0xa54ff53a;
	stateP[4] = 0x510e527f;
	stateP[5] = 0x9b05688c;
	stateP[6] = 0x1f83d9ab;
	stateP[7] = 0x5be0cd19;


	// Pad whatever data is left in the buffer. 
	data[l++] = 0x80;
	while (l < 56)
		data[l++] = 0x00;


	// Append to the padding the total message's length in bits and transform. 
	DBL_INT_ADD(bitlen0, bitlen1, length * 8);
	data[63] = bitlen0;
	data[62] = bitlen0 >> 8;
	data[61] = bitlen0 >> 16;
	data[60] = bitlen0 >> 24;
	data[59] = bitlen1;
	data[58] = bitlen1 >> 8;
	data[57] = bitlen1 >> 16;
	data[56] = bitlen1 >> 24;


	uint32_t schedule[64];
	LOADSCHEDULE(0)
	LOADSCHEDULE(1)
	LOADSCHEDULE(2)
	LOADSCHEDULE(3)
	LOADSCHEDULE(4)
	LOADSCHEDULE(5)
	LOADSCHEDULE(6)
	LOADSCHEDULE(7)
	LOADSCHEDULE(8)
	LOADSCHEDULE(9)
	LOADSCHEDULE(10)
	LOADSCHEDULE(11)
	LOADSCHEDULE(12)
	LOADSCHEDULE(13)
	LOADSCHEDULE(14)
	LOADSCHEDULE(15)
	SCHEDULE(16)
	SCHEDULE(17)
	SCHEDULE(18)
	SCHEDULE(19)
	SCHEDULE(20)
	SCHEDULE(21)
	SCHEDULE(22)
	SCHEDULE(23)
	SCHEDULE(24)
	SCHEDULE(25)
	SCHEDULE(26)
	SCHEDULE(27)
	SCHEDULE(28)
	SCHEDULE(29)
	SCHEDULE(30)
	SCHEDULE(31)
	SCHEDULE(32)
	SCHEDULE(33)
	SCHEDULE(34)
	SCHEDULE(35)
	SCHEDULE(36)
	SCHEDULE(37)
	SCHEDULE(38)
	SCHEDULE(39)
	SCHEDULE(40)
	SCHEDULE(41)
	SCHEDULE(42)
	SCHEDULE(43)
	SCHEDULE(44)
	SCHEDULE(45)
	SCHEDULE(46)
	SCHEDULE(47)
	SCHEDULE(48)
	SCHEDULE(49)
	SCHEDULE(50)
	SCHEDULE(51)
	SCHEDULE(52)
	SCHEDULE(53)
	SCHEDULE(54)
	SCHEDULE(55)
	SCHEDULE(56)
	SCHEDULE(57)
	SCHEDULE(58)
	SCHEDULE(59)
	SCHEDULE(60)
	SCHEDULE(61)
	SCHEDULE(62)
	SCHEDULE(63)

	uint32_t a = stateP[0];
	uint32_t b = stateP[1];
	uint32_t c = stateP[2];
	uint32_t d = stateP[3];
	uint32_t e = stateP[4];
	uint32_t f = stateP[5];
	uint32_t g = stateP[6];
	uint32_t h = stateP[7];
	ROUND(a, b, c, d, e, f, g, h, 0, 0x428A2F98)
	ROUND(h, a, b, c, d, e, f, g, 1, 0x71374491)
	ROUND(g, h, a, b, c, d, e, f, 2, 0xB5C0FBCF)
	ROUND(f, g, h, a, b, c, d, e, 3, 0xE9B5DBA5)
	ROUND(e, f, g, h, a, b, c, d, 4, 0x3956C25B)
	ROUND(d, e, f, g, h, a, b, c, 5, 0x59F111F1)
	ROUND(c, d, e, f, g, h, a, b, 6, 0x923F82A4)
	ROUND(b, c, d, e, f, g, h, a, 7, 0xAB1C5ED5)
	ROUND(a, b, c, d, e, f, g, h, 8, 0xD807AA98)
	ROUND(h, a, b, c, d, e, f, g, 9, 0x12835B01)
	ROUND(g, h, a, b, c, d, e, f, 10, 0x243185BE)
	ROUND(f, g, h, a, b, c, d, e, 11, 0x550C7DC3)
	ROUND(e, f, g, h, a, b, c, d, 12, 0x72BE5D74)
	ROUND(d, e, f, g, h, a, b, c, 13, 0x80DEB1FE)
	ROUND(c, d, e, f, g, h, a, b, 14, 0x9BDC06A7)
	ROUND(b, c, d, e, f, g, h, a, 15, 0xC19BF174)
	ROUND(a, b, c, d, e, f, g, h, 16, 0xE49B69C1)
	ROUND(h, a, b, c, d, e, f, g, 17, 0xEFBE4786)
	ROUND(g, h, a, b, c, d, e, f, 18, 0x0FC19DC6)
	ROUND(f, g, h, a, b, c, d, e, 19, 0x240CA1CC)
	ROUND(e, f, g, h, a, b, c, d, 20, 0x2DE92C6F)
	ROUND(d, e, f, g, h, a, b, c, 21, 0x4A7484AA)
	ROUND(c, d, e, f, g, h, a, b, 22, 0x5CB0A9DC)
	ROUND(b, c, d, e, f, g, h, a, 23, 0x76F988DA)
	ROUND(a, b, c, d, e, f, g, h, 24, 0x983E5152)
	ROUND(h, a, b, c, d, e, f, g, 25, 0xA831C66D)
	ROUND(g, h, a, b, c, d, e, f, 26, 0xB00327C8)
	ROUND(f, g, h, a, b, c, d, e, 27, 0xBF597FC7)
	ROUND(e, f, g, h, a, b, c, d, 28, 0xC6E00BF3)
	ROUND(d, e, f, g, h, a, b, c, 29, 0xD5A79147)
	ROUND(c, d, e, f, g, h, a, b, 30, 0x06CA6351)
	ROUND(b, c, d, e, f, g, h, a, 31, 0x14292967)
	ROUND(a, b, c, d, e, f, g, h, 32, 0x27B70A85)
	ROUND(h, a, b, c, d, e, f, g, 33, 0x2E1B2138)
	ROUND(g, h, a, b, c, d, e, f, 34, 0x4D2C6DFC)
	ROUND(f, g, h, a, b, c, d, e, 35, 0x53380D13)
	ROUND(e, f, g, h, a, b, c, d, 36, 0x650A7354)
	ROUND(d, e, f, g, h, a, b, c, 37, 0x766A0ABB)
	ROUND(c, d, e, f, g, h, a, b, 38, 0x81C2C92E)
	ROUND(b, c, d, e, f, g, h, a, 39, 0x92722C85)
	ROUND(a, b, c, d, e, f, g, h, 40, 0xA2BFE8A1)
	ROUND(h, a, b, c, d, e, f, g, 41, 0xA81A664B)
	ROUND(g, h, a, b, c, d, e, f, 42, 0xC24B8B70)
	ROUND(f, g, h, a, b, c, d, e, 43, 0xC76C51A3)
	ROUND(e, f, g, h, a, b, c, d, 44, 0xD192E819)
	ROUND(d, e, f, g, h, a, b, c, 45, 0xD6990624)
	ROUND(c, d, e, f, g, h, a, b, 46, 0xF40E3585)
	ROUND(b, c, d, e, f, g, h, a, 47, 0x106AA070)
	ROUND(a, b, c, d, e, f, g, h, 48, 0x19A4C116)
	ROUND(h, a, b, c, d, e, f, g, 49, 0x1E376C08)
	ROUND(g, h, a, b, c, d, e, f, 50, 0x2748774C)
	ROUND(f, g, h, a, b, c, d, e, 51, 0x34B0BCB5)
	ROUND(e, f, g, h, a, b, c, d, 52, 0x391C0CB3)
	ROUND(d, e, f, g, h, a, b, c, 53, 0x4ED8AA4A)
	ROUND(c, d, e, f, g, h, a, b, 54, 0x5B9CCA4F)
	ROUND(b, c, d, e, f, g, h, a, 55, 0x682E6FF3)
	ROUND(a, b, c, d, e, f, g, h, 56, 0x748F82EE)
	ROUND(h, a, b, c, d, e, f, g, 57, 0x78A5636F)
	ROUND(g, h, a, b, c, d, e, f, 58, 0x84C87814)
	ROUND(f, g, h, a, b, c, d, e, 59, 0x8CC70208)
	ROUND(e, f, g, h, a, b, c, d, 60, 0x90BEFFFA)
	ROUND(d, e, f, g, h, a, b, c, 61, 0xA4506CEB)
	ROUND(c, d, e, f, g, h, a, b, 62, 0xBEF9A3F7)
	ROUND(b, c, d, e, f, g, h, a, 63, 0xC67178F2)
	stateP[0] += a;
	stateP[1] += b;
	stateP[2] += c;
	stateP[3] += d;
	stateP[4] += e;
	stateP[5] += f;
	stateP[6] += g;
	stateP[7] += h;

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash. 

	for (int i = 0; i < 4; ++i) {
		l = i << 3;
		*(res) = (stateP[0] >> (24 - l)) & 0x000000ff;
		*(res + 4) = (stateP[1] >> (24 - l)) & 0x000000ff;
		*(res + 8) = (stateP[2] >> (24 - l)) & 0x000000ff;
		*(res + 12) = (stateP[3] >> (24 - l)) & 0x000000ff;
		*(res + 16) = (stateP[4] >> (24 - l)) & 0x000000ff;
		*(res + 20) = (stateP[5] >> (24 - l)) & 0x000000ff;
		*(res + 24) = (stateP[6] >> (24 - l)) & 0x000000ff;
		*(res + 28) = (stateP[7] >> (24 - l)) & 0x000000ff;
		++res;
	}
}

__device__ inline void initSHA256ConstantAndCharSet(const unsigned int charSetSize)
{
	char* plainCharSetP = plainCharSet[threadIdx.x];
	//for (i = 0;i < charSetSize;i++) {
	//	plainCharSetP[i] = srcCharSet[i];
	//}
	for (int i = 0;i < charSetSize;i++) {
		plainCharSetP[i] = constantAreaPlainCharSet[i];
	}
}

__device__ inline ulong hashToIndex(unsigned char* hash, int pos, ulong plainSpace)
{
	ulong* hashP = (ulong*)hash;
	return (ulong)((*(hashP)+ pos)) % plainSpace;
}

__device__ ulong hashToIndex(unsigned char* hash, int pos)
{
	ulong* hashP = (ulong*)hash;
	return (ulong)(((*(hashP) ^ *(hashP + 1) ^ *(hashP + 2) ^ *(hashP + 3)) + pos));
}

__device__ inline ulong reductFinalIndex(ulong index, uint8_t plainLength, uint8_t plainCharSize)
{
	ulong res = 0;
	uint8_t plainIndex[9];
	for (int l = plainLength - 1; l >= 0; l--) {
		// 32 - 126
		plainIndex[l] = ((uint8_t)(index & 0x7f)) % plainCharSize + 32;
		index >>= 7;
	}
	int j;
	for (j = 0; j < plainLength - 1; j++) {
		res += plainIndex[j];
		res <<= 7;
	}
	res += plainIndex[j];
	return res;
}

__global__ void generateChainPaperVersion(struct Chain* chains, const uint8_t plainCharSetSize,
	const uint8_t plainLength, const unsigned int chainLength)
{
	//initSHA256ConstantAndCharSet(plainCharSetSize);

	unsigned char hash[32];

	char plain[8];

	uint offset = (blockIdx.x * blockDim.x) + threadIdx.x;

	struct Chain* chain;

	chain = chains + offset;

	ulong indexE = chain->indexS;

	for (int i = 0;i < chainLength;i++) {
		//plainToHashWithInlinePTX((char *)&indexE, INDEX_SIZE_IN_BYTES, hash);
		plainToHashWithInlinePTX(indexE, plainLength, hash, plainCharSetSize);
		//indexE = hashToIndexWithoutCharSet(hash, i, plainCharSetSize);
		indexE = hashToIndex(hash, i);
	}
	chain->indexE = reductFinalIndex(indexE,plainLength,plainCharSetSize);
	

	//for (int i = 0;i < chainLength;i++) {
	//	indexToPlain(indexE, plainLength, plainCharSetSize, plain);
	//	plainToHashWithInlinePTX(plain, plainLength, hash);
	//	hashToIndex(hash, i);
	//}
}

__global__ void generateChainPaperVersion(struct Chain* chains, const uint8_t plainCharSetSize,
	const uint8_t plainLength, const unsigned int chainLength, ulong plainSpace)
{
	//initSHA256ConstantAndCharSet(plainCharSetSize);

	unsigned char hash[32];

	char plain[8];

	uint offset = (blockIdx.x * blockDim.x) + threadIdx.x;

	struct Chain* chain;

	chain = chains + offset;

	ulong indexE = chain->indexS;

	//for (int i = 0;i < chainLength;i++) {
	//	//plainToHashWithInlinePTX((char *)&indexE, INDEX_SIZE_IN_BYTES, hash);
	//	plainToHashWithInlinePTX(indexE, plainLength, hash, plainCharSetSize);
	//	//indexE = hashToIndexWithoutCharSet(hash, i, plainCharSetSize);
	//	indexE = hashToIndex(hash, i, 0x0fffffff);
	//}
	//chain->indexE = reductFinalIndex(indexE,plainLength,plainCharSetSize);
	//}

	for (int i = 0;i < chainLength;i++) {
		indexToPlain(indexE, plainLength, plainCharSetSize, plain);
		plainToHashWithInlinePTX(plain, plainLength, hash);
		indexE = hashToIndex(hash, i, plainSpace);
	}

	chain->indexE = indexE;
}

__global__ void generateChain(struct PasswordMapping* chains, const uint8_t plainCharSetSize)
{
	uint32_t offset = (blockIdx.x * blockDim.x) + threadIdx.x;
	if (offset < plainCharSetSize) {
		struct PasswordMapping* chain = chains + offset;
		plainToHash(chain->plain, 1, chain->hash);
	}else if (offset < plainCharSetSize + plainCharSetSize * plainCharSetSize) {
		struct PasswordMapping* chain = chains + offset;
		plainToHash(chain->plain, 2, chain->hash);
	}else if (offset < plainCharSetSize + plainCharSetSize * plainCharSetSize + plainCharSetSize * plainCharSetSize * plainCharSetSize) {
		struct PasswordMapping* chain = chains + offset;
		plainToHash(chain->plain, 3, chain->hash);
	}
}

void generateTableWhilePasswordLengthLowerOrEqualThan3(const char* hostCharSetPath , const uint8_t plainCharSetSize)
{
	const uint32_t CHAINS_SIZE = plainCharSetSize + plainCharSetSize * plainCharSetSize + plainCharSetSize * plainCharSetSize * plainCharSetSize;
	struct PasswordMapping* deviceChains;
	struct PasswordMapping* hostChains;
	char* hostCharSet;
	CUDA_CALL(cudaHostAlloc(&hostChains, CHAINS_SIZE * sizeof(struct PasswordMapping), cudaHostAllocDefault));
	CUDA_CALL(cudaHostAlloc(&hostCharSet, plainCharSetSize * sizeof(char), cudaHostAllocDefault));
	getCharSet(hostCharSet, hostCharSetPath, plainCharSetSize);
	
	generateInitialIndex(hostChains, hostCharSet, plainCharSetSize);

	CUDA_CALL(cudaMalloc(&deviceChains, CHAINS_SIZE * sizeof(struct PasswordMapping)));
	CUDA_CALL(cudaMemcpy(deviceChains, hostChains, CHAINS_SIZE * sizeof(struct PasswordMapping), cudaMemcpyHostToDevice));

	uint32_t threadPerBlock = 384;
	uint32_t blockNum = CHAINS_SIZE / threadPerBlock + 1;
	
	cudaEvent_t startEvent;
	cudaEvent_t endEvent;
	float cudaElapsedTime = 0.0f;
	cudaEventCreate(&startEvent);
	cudaEventCreate(&endEvent);
	cudaEventRecord(startEvent, 0);

	generateChain<<<blockNum, threadPerBlock>>>(deviceChains, plainCharSetSize);

	cudaEventRecord(endEvent, 0);
	cudaEventSynchronize(endEvent);
	cudaEventElapsedTime(&cudaElapsedTime, startEvent, endEvent);

	QSort(deviceChains, CHAINS_SIZE);

	CUDA_CALL(cudaMemcpy(hostChains, deviceChains, CHAINS_SIZE * sizeof(struct PasswordMapping), cudaMemcpyDeviceToHost));
	
	writeToFile((string("../") + "1-3#" + "ascii-32-95#" + "1").c_str(), hostChains, sizeof(struct PasswordMapping), CHAINS_SIZE);

	cudaFreeHost(hostChains);
	cudaFreeHost(hostCharSet);
	cudaFree(deviceChains);
	//cudaEventDestroy(startEvent);
	//cudaEventDestroy(endEvent);

	cudaDeviceReset();

	printf("%.3lf MH/S", (CHAINS_SIZE) / (cudaElapsedTime * 1000.0));
}

//int main()
//{
//	generateTableWhilePasswordLengthLowerOrEqualThan3("../charsets/ascii-32-95.txt", 95);
//
//	//constexpr uint32_t CHAINS_SIZE = 95 + 95 * 95 + 95 * 95 * 95;
//	//struct PasswordMapping* mappings;
//	//cudaHostAlloc(&mappings, sizeof(struct PasswordMapping) * CHAINS_SIZE, cudaHostAllocDefault);
//	//openTableFile((string("../") + "1-3#" + "ascii-32-95#" + "1").c_str(), mappings, sizeof(struct PasswordMapping), CHAINS_SIZE);
//	//for (int i = 0;i < CHAINS_SIZE;i++) {
//	//	printf("%s\n", mappings[i].hash);
//	//}
//	//getchar();
//
//	return 0;
//}

void generateTable(const uint8_t plainLength, const char* hostCharSetPath, const uint8_t plainCharSetSize)
{
	// chainSize = blockNum * threadPerBlock
	// cover = chainSize * chainLength
	const uint32_t threadPerBlock = 384;
	uint32_t blockNum = 0;

	uint32_t CHAINS_SIZE = 0;
	uint32_t chainLength = 0;
	// default plainCharSetSize == 95
	// strategy
	switch (plainLength) {
	// the collision ration is quite high, especially when the plainLength is low
	// the paper's reductant version is better when the plainLength is low (4,5,6)
	// must split the table , even when the table size is low
	case 4:
		chainLength = 350;
		CHAINS_SIZE = 384000;
		blockNum = 1000;
		break;
	case 5:
		chainLength = 3600;
		CHAINS_SIZE = 2304000;
		blockNum = 6000;
		break;
	case 6:
		chainLength = 60000;
		CHAINS_SIZE = 15360000;
		blockNum = 40000;
	}

	struct Chain* devicePointer;
	struct Chain* hostPointer;
	char* hostCharSet;
	char* deviceCharSet;
	//CUDA_CALL(cudaHostAlloc(&hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaHostAllocDefault | cudaHostAllocMapped));
	//CUDA_CALL(cudaHostAlloc(&hostCharSet, 36 * sizeof(char), cudaHostAllocDefault | cudaHostAllocMapped));
	CUDA_CALL(cudaHostAlloc(&hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaHostAllocDefault));
	CUDA_CALL(cudaHostAlloc(&hostCharSet, plainCharSetSize * sizeof(char), cudaHostAllocDefault));
	
	getCharSet(hostCharSet, hostCharSetPath, plainCharSetSize);
	
	generateInitialIndex(hostPointer, CHAINS_SIZE);
	
	//printf("%llu", hostPointer[0].indexS);
	
	CUDA_CALL(cudaMalloc(&devicePointer, CHAINS_SIZE * sizeof(struct Chain)));
	CUDA_CALL(cudaMalloc(&deviceCharSet, plainCharSetSize * sizeof(char)));
	
	CUDA_CALL(cudaMemcpy(deviceCharSet, hostCharSet, plainCharSetSize * sizeof(char), cudaMemcpyHostToDevice));
	CUDA_CALL(cudaMemcpy(devicePointer, hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaMemcpyHostToDevice));
	
	//CUDA_CALL(cudaMemcpyToSymbol(constantAreaPlainCharSet, hostCharSet, sizeof(char) * plainCharSetSize));
	
	ulong plainSpace = pow(plainCharSetSize, plainLength);

	cudaEvent_t startEvent;
	cudaEvent_t endEvent;
	float cudaElapsedTime = 0.0f;
	cudaEventCreate(&startEvent);
	cudaEventCreate(&endEvent);
	cudaEventRecord(startEvent, 0);
	
	generateChainPaperVersion << <blockNum, threadPerBlock >> > (devicePointer, plainCharSetSize, plainLength, chainLength);
	
	cudaEventRecord(endEvent, 0);
	cudaEventSynchronize(endEvent);
	cudaEventElapsedTime(&cudaElapsedTime, startEvent, endEvent);
	
	thrust::device_ptr<struct Chain> thrustChainP(devicePointer);
	thrust::sort(thrustChainP, thrustChainP + CHAINS_SIZE, ChainComparator());
	
	

	CUDA_CALL(cudaMemcpy(hostPointer, devicePointer, CHAINS_SIZE * sizeof(struct Chain), cudaMemcpyDeviceToHost));

	struct Chain* forWrite;
	CUDA_CALL(cudaHostAlloc(&forWrite, sizeof(struct Chain) * CHAINS_SIZE, cudaHostAllocDefault));
	uint32_t actualSize = removeDuplicate(forWrite, hostPointer, CHAINS_SIZE);

	writeToFile(fileNameBuilder("../", plainLength, hostCharSetPath, 1, actualSize, chainLength).c_str(), forWrite, sizeof(struct Chain), actualSize);
	//writeToFile("../5#ascii-32-95#1#384000#350", hostPointer, sizeof(struct Chain), CHAINS_SIZE);

	cudaFreeHost(hostPointer);
	cudaFreeHost(hostCharSet);
	cudaFree(deviceCharSet);
	cudaFree(devicePointer);
	//cudaEventDestroy(startEvent);
	//cudaEventDestroy(endEvent);
	
	cudaDeviceReset();
	
	printf("%.3lf MH/S", (CHAINS_SIZE * (ulong)chainLength) / (cudaElapsedTime * 1000.0));
}

int main()
{
	generateTable(4, "../charsets/ascii-32-95.txt", 95);
	return 0;
}

//int main(int argc, char *argv[])
//{
//	const uint CHAINS_SIZE = 7680000;
//	int plainLength = 4;
//	int chainLength = 100000;
//
//	int plainCharSetSize = 95;
//
//	//cudaSetDeviceFlags(cudaDeviceMapHost);
//	struct Chain* devicePointer;
//	struct Chain* hostPointer;
//	char* hostCharSet;
//	char* deviceCharSet;
//	//CUDA_CALL(cudaHostAlloc(&hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaHostAllocDefault | cudaHostAllocMapped));
//	//CUDA_CALL(cudaHostAlloc(&hostCharSet, 36 * sizeof(char), cudaHostAllocDefault | cudaHostAllocMapped));
//	CUDA_CALL(cudaHostAlloc(&hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaHostAllocDefault));
//	CUDA_CALL(cudaHostAlloc(&hostCharSet, plainCharSetSize * sizeof(char), cudaHostAllocDefault));
//
//	getCharSet(hostCharSet, "../charsets/ascii-32-95.txt", plainCharSetSize);
//
//	generateInitialIndex(hostPointer, CHAINS_SIZE);
//
//	//printf("%llu", hostPointer[0].indexS);
//
//	CUDA_CALL(cudaMalloc(&devicePointer, CHAINS_SIZE * sizeof(struct Chain)));
//	CUDA_CALL(cudaMalloc(&deviceCharSet, plainCharSetSize * sizeof(char)));
//
//	CUDA_CALL(cudaMemcpy(deviceCharSet, hostCharSet, plainCharSetSize * sizeof(char), cudaMemcpyHostToDevice));
//	CUDA_CALL(cudaMemcpy(devicePointer, hostPointer, CHAINS_SIZE * sizeof(struct Chain), cudaMemcpyHostToDevice));
//
//	CUDA_CALL(cudaMemcpyToSymbol(constantAreaPlainCharSet, hostCharSet, sizeof(char) * plainCharSetSize));
//
//	/*curandGenerator_t randGeneratorDevice;
//	const ulong seed = 987654321;
//	const curandRngType_t generatorType = CURAND_RNG_PSEUDO_DEFAULT;
//
//	curandCreateGenerator(&randGeneratorDevice, generatorType);
//	curandSetPseudoRandomGeneratorSeed(randGeneratorDevice, seed);
//	curandGenerateLongLong(randGeneratorDevice, (ulong *)devicePointer, CHAINS_SIZE * 2);*/
//
//	int threadPerBlock = 384;
//	uint blockNum = CHAINS_SIZE / threadPerBlock;
//
//	cudaEvent_t startEvent;
//	cudaEvent_t endEvent;
//	float cudaElapsedTime = 0.0f;
//	cudaEventCreate(&startEvent);
//	cudaEventCreate(&endEvent);
//	cudaEventRecord(startEvent, 0);
//
//	generateChainPaperVersion << <blockNum, threadPerBlock >> > (devicePointer, plainCharSetSize, plainLength, chainLength);
//
//	cudaEventRecord(endEvent, 0);
//	cudaEventSynchronize(endEvent);
//	cudaEventElapsedTime(&cudaElapsedTime, startEvent, endEvent);
//
//	thrust::device_ptr<struct Chain> thrustChainP(devicePointer);
//	thrust::sort(thrustChainP, thrustChainP + CHAINS_SIZE, ChainComparator());
//
//	CUDA_CALL(cudaMemcpy(hostPointer, devicePointer, CHAINS_SIZE * sizeof(struct Chain), cudaMemcpyDeviceToHost));
//
//	// plainLength#charSet#table#tableLength#chainLength
//
//	// 1-3#ascii-32-95#1#0#chainLength
//	//writeToFile((string("../") + "1-3#" + "ascii-32-95#" + "1#" + "0#" + ).c_str(), hostPointer, sizeof(struct Chain), CHAINS_SIZE);
//	writeToFile("../t5.rt", hostPointer, sizeof(struct Chain), CHAINS_SIZE);
//
//
//	cudaFreeHost(hostPointer);
//	cudaFreeHost(hostCharSet);
//	cudaFree(deviceCharSet);
//	cudaFree(devicePointer);
//	//cudaEventDestroy(startEvent);
//	//cudaEventDestroy(endEvent);
//
//	cudaDeviceReset();
//
//	printf("%.3lf MH/S", (CHAINS_SIZE * (ulong)chainLength) / (cudaElapsedTime * 1000.0));
//
//	getchar();
//
//
//
//	return 0;
//}
