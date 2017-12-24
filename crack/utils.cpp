#include "utils.h"
#include <algorithm>

//struct Chain chains[CHAINS_SIZE];

#define EXTRACT_9 0x7fffffffffffffff
#define EXTRACT_8 0x00ffffffffffffff
#define EXTRACT_7 0x0001ffffffffffff

extern bool flag;

uint k[64] = {
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};
//

void PrintHash(uchar* Hash)
{
	printf("%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		Hash[0], Hash[1], Hash[2], Hash[3], Hash[4], Hash[5], Hash[6], Hash[7],
		Hash[8], Hash[9], Hash[10], Hash[11], Hash[12], Hash[13], Hash[14], Hash[15],
		Hash[16], Hash[17], Hash[18], Hash[19], Hash[20], Hash[21], Hash[22], Hash[23],
		Hash[24], Hash[25], Hash[26], Hash[27], Hash[28], Hash[29], Hash[30], Hash[31]);
}


//void CChainWalkContext::IndexToPlain()
//{
//	int i;
//	for (i = m_nPlainLenMax - 1; i >= m_nPlainLenMin - 1; i--)
//	{
//		if (m_nIndex >= m_nPlainSpaceUpToX[i])
//		{
//			m_nPlainLen = i + 1;
//			break;
//		}
//	}
//
//	uint64 nIndexOfX = m_nIndex - m_nPlainSpaceUpToX[m_nPlainLen - 1];
//
//	// Slow version
//	for (i = m_nPlainLen - 1; i >= 0; i--)
//	{
//		m_Plain[i] = m_PlainCharset[nIndexOfX % m_nPlainCharsetLen];
//		nIndexOfX /= m_nPlainCharsetLen;
//	}
//
//
//	// Fast version
//	/*for (i = m_nPlainLen - 1; i >= 0; i--)
//	{
//	#ifdef _WIN32a
//	if (nIndexOfX < 0x100000000I64)
//	break;
//	#else
//	if (nIndexOfX < 0x100000000llu)
//	break;
//	#endif
//
//	m_Plain[i] = m_PlainCharset[nIndexOfX % m_nPlainCharsetLen];
//	nIndexOfX /= m_nPlainCharsetLen;
//	}
//	unsigned int nIndexOfX32 = (unsigned int)nIndexOfX;
//	for (; i >= 0; i--)
//	{
//	//m_Plain[i] = m_PlainCharset[nIndexOfX32 % m_nPlainCharsetLen];
//	//nIndexOfX32 /= m_nPlainCharsetLen;
//
//	unsigned int nPlainCharsetLen = m_nPlainCharsetLen;
//	unsigned int nTemp;
//	#ifdef _WIN32
//	__asm
//	{
//	mov eax, nIndexOfX32
//	xor edx, edx
//	div nPlainCharsetLen
//	mov nIndexOfX32, eax
//	mov nTemp, edx
//	}
//	#else
//	__asm__ __volatile__ (	"mov %2, %%eax;"
//	"xor %%edx, %%edx;"
//	"divl %3;"
//	"mov %%eax, %0;"
//	"mov %%edx, %1;"
//	: "=m"(nIndexOfX32), "=m"(nTemp)
//	: "m"(nIndexOfX32), "m"(nPlainCharsetLen)
//	: "%eax", "%edx"
//	);
//	#endif
//	m_Plain[i] = m_PlainCharset[nTemp];
//	}*/
//}
//
//void CChainWalkContext::PlainToHash()
//{
//	m_pHashRoutine(m_Plain, m_nPlainLen, m_Hash);
//}
//
//void CChainWalkContext::HashToIndex(int nPos)
//{
//	m_nIndex = (uint64)(*(uint64*)m_Hash + m_nReduceOffset + nPos) % m_nPlainSpaceTotal;
//}
//
//void indexToPlainCPU(ulong index, size_t plainCharsetSize, const char* plainCharset,
//	size_t plainLength, char* plain)
//{
//	for (size_t i = 0;i < plainLength;i++) {
//		plain[i] = plainCharset[index % plainCharsetSize];
//		index /= plainCharsetSize;
//	}
//}
//
void plainToHashCPU(const char* plain, const uint8_t length, unsigned char* res)
{
	unsigned int bitlen0 = 0;
	unsigned int bitlen1 = 0;
	unsigned int stateP[8];

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

void plainToHashCPU(ulong index, const uint8_t length, unsigned char* res, const uint8_t charSetSize)
{
	unsigned int bitlen0 = 0;
	unsigned int bitlen1 = 0;
	unsigned int stateP[8];

	unsigned char data[64];

	unsigned int l;
	//for (l = 0; l < length; ++l) {
	//	data[l] = plain[l];
	//}

	for (int i = length - 1; i >= 0; i--) {
		data[i] = ((uint8_t)(index & 0x7f)) % charSetSize + 32;
		index >>= 7;
	}

	l = length;

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
//

void indexToPlainCPU(ulong index, char* plain, const uint8_t plainLength, const char* charSet, const uint32_t charSetSize)
{
	for (int i = plainLength - 1; i >= 0; i--) {
		//plain[i] = charSet[(index & 0x7f) % charSetSize];
		plain[i] = (index & 0x7f) + 32;
		index >>= 7;
	}
}

bool compareIndex(ulong lhs, ulong rhs, const uint8_t plainLength, const uint8_t plainCharSetSize)
{
	for (auto i = plainLength - 1; i != 0; i--) {
		uint8_t tempa = (lhs & 0x7f) % plainCharSetSize;
		uint8_t tempb = (rhs & 0x7f) % plainCharSetSize;
		if (tempa != tempb) {
			return false;
		}
		lhs >>= 7;
		rhs >>= 7;
	}
	return true;
}

ulong plainToIndexCPU(const char* plain, size_t plainLength, const char* charSet, size_t charSetSize, map<const char, size_t>* charIndexMap)
{
	ulong index = 0;
	int i;

	for (i = 0;i<plainLength - 1;i++) {
		index += charIndexMap->operator[](plain[i]) & 0x7f;
		index <<= 7;
	}
	index += charIndexMap->operator[](plain[i]) & 0x7f;
	return index;
}

ulong hashToIndexPaperVersion(unsigned char* hash, int pos, const uint8_t plainLength, const char* plainCharSetP, size_t plainCharSetSize)
{
	unsigned int* hashP = (unsigned int*)hash;
	unsigned int p0 = *(hashP + 4) ^ pos;
	unsigned int p2 = *(hashP + 5) ^ (pos >> 12);
	unsigned int p4 = *(hashP + 6) ^ (pos >> 24);
	unsigned int p6 = *(hashP + 7);
	unsigned __int16 b0 = plainCharSetP[p0 % plainCharSetSize] << 8 | plainCharSetP[(p0 >> 16) % plainCharSetSize];
	unsigned __int16 b1 = plainCharSetP[p2 % plainCharSetSize] << 8 | plainCharSetP[(p2 >> 16) % plainCharSetSize];
	unsigned __int16 b2 = plainCharSetP[p4 % plainCharSetSize] << 8 | plainCharSetP[(p4 >> 16) % plainCharSetSize];
	unsigned __int16 b3 = plainCharSetP[p6 % plainCharSetSize] << 8 | plainCharSetP[(p6 >> 16) % plainCharSetSize];
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

ulong hashToIndexCPU(unsigned char * hash, int pos)
{
	ulong* hashP = (ulong*)hash;
	return (ulong)(((*(hashP) ^ *(hashP + 1) ^ *(hashP + 2) ^ *(hashP + 3)) + pos));
}


size_t getCharSet(char* charSet, const char* filePath, size_t charSetSize)
{
	FILE* charSetFile;

	if ((charSetFile = fopen(filePath, "r")) == NULL) {
		printf("no file exist");
		return 0;
	}
	return fread(charSet, sizeof(char), charSetSize, charSetFile);
}


//inline ulong generateSingleChainCPU(ulong indexS, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal)
//{
//	unsigned char hash[32];
//	char plain[9];
//	ulong indexE;
//	for (int i = 0;i < chainLength;i++) {
//		indexToPlainCPU(indexS, plain, plainLength, plainCharSet, plainCharSetSize);
//		plainToHashCPU(plain, plainLength, hash);
//		indexE = hashToIndexPaperVersion(hash, i, plainLength, plainCharSet, plainCharSetSize);
//	}
//	return indexE;
//}

//void generateChains(struct Chain* chains, size_t chainsSize, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal)
//{
//	for (size_t i = 0;i < chainsSize;i++) {
//		struct Chain* chain = &chains[i];
//		chain->indexE = generateSingleChain(chain->indexS, i, plainCharSetSize, plainCharSet, plainLength, chainLength, plainSpaceTotal);
//	}
//}

void writeToFile(const char* filePath, const void* buffer, size_t elementSize, size_t bufferSize)
{
	FILE* fp;
	fp = fopen(filePath, "wb");
	if (fp == NULL) {
		printf("can't write to file");
		return;
	}
	fwrite(buffer, elementSize, bufferSize, fp);
}

void generateInitialIndex(struct Chain* chains, size_t chainsSize) {
	std::default_random_engine randomEngine;
	std::uniform_int_distribution<ulong> randomDistribution;

	for (size_t i = 0;i < chainsSize;i++) {
		chains[i].indexS = randomDistribution(randomEngine);
	}
}

void openTableFile(const char * filePath, void * buffer, size_t elementSize, size_t elementCount)
{
	FILE* fp;
	fp = fopen(filePath, "rb");
	if (fp == NULL) {
		printf("can't open file");
		return;
	}
	fread(buffer, elementSize, elementCount, fp);
}

bool compareHash(const unsigned char * lhs, const unsigned char * rhs)
{
	const ulong* lhsP = (const ulong *)lhs;
	const ulong* rhsP = (const ulong *)rhs;
	if (*lhsP == *rhsP &&
		*(lhsP + 1) == *(rhsP + 1) &&
		*(lhsP + 2) == *(rhsP + 2) &&
		*(lhsP + 3) == *(rhsP + 3)) {
		return true;
	}
	return false;
}

int compareHash_(const unsigned char * lhs, const unsigned char * rhs)
{
	//const ulong* lhsP = (const ulong *)lhs;
	//const ulong* rhsP = (const ulong *)rhs;
	///*
	//*(rhsP + 1 2 3 )
	//*/
	//if (*lhsP == *rhsP
	//	&& *(lhsP + 1) == *(rhsP + 1)
	//	&& *(lhsP + 2) == *(rhsP + 2)
	//	&& *(lhsP + 3) == *(rhsP + 3)) {
	//	return 0;
	//}
	//if (*lhsP > *rhsP
	//	|| *lhsP == *rhsP && *(lhsP + 1) > *(rhsP + 1)
	//	|| *lhsP == *rhsP && *(lhsP + 1) == *(rhsP + 1) && *(lhsP + 2) > *(rhsP + 2)
	//	|| *lhsP == *rhsP && *(lhsP + 1) == *(rhsP + 1) && *(lhsP + 2) == *(rhsP + 2) && *(lhsP + 3) > *(rhsP + 3)) {
	//	return 1;
	//}
	//return -1;
	int flap = 0;
	for (int i = 0;i < 32;i++) {
		if (lhs[i] == rhs[i]) {
			continue;
		}else if (lhs[i] < rhs[i]){
			flap = -1;
			break;
		}else {
			flap = 1;
			break;
		}
	}
	return flap;
}

int searchThroughChains(const Chain * chains, size_t chainsSize, ulong index)
{
	int left = 0;
	int right = chainsSize - 1;

	// 这里必须是 <=
	while (left <= right) {
		int mid = (left + right) / 2;
		if (chains[mid].indexE == index) {
			return mid;
		}
		else if (chains[mid].indexE < index) {
			left = mid + 1;
		}
		else {
			right = mid - 1;
		}
	}

	return -1;
	//the array does not contain the target
	//for (int i = 0;i < chainsSize;i++) {
	//	if (chains[i].indexE == index) {
	//		return i;
	//	}
	//}
	//return -1;
}

//bool rebuildAndCompare(char* res, unsigned char* givenHash, ulong indexS, int pos, size_t plainCharSetSize, const char * plainCharSet, size_t plainLength, ulong plainSpaceTotal)
//{
//	unsigned char hash[32];
//	ulong indexE = indexS;
//	for (int i = 0;i < pos;i++) {
//		indexToPlainCPU(indexS, plainCharSetSize, plainCharSet, plainLength, res);
//		plainToHashCPU(res, plainLength, hash);
//		indexE = hashToIndexCPU(hash, i, plainSpaceTotal);
//	}
//	return compareHash(givenHash, hash);
//}

bool rebuildAndCompare(unsigned char* givenHash, unsigned char* hash, char* plain, ulong indexS, int pos, uint plainCharSetSize, const char * plainCharSet, uint8_t plainLength)
{
	ulong indexE = indexS;
	plainToHashCPU(indexE, plainLength, hash, plainCharSetSize);
	for (int i = 0;i < pos;i++) {
		//indexToPlainCPU(indexS, res, plainLength, plainCharSet, plainCharSetSize);
		indexE = hashToIndexCPU(hash, i);
		//indexE = hashToIndexPaperVersion(hash, i, plainLength, plainCharSet, plainCharSetSize);
		plainToHashCPU(indexE, plainLength, hash,plainCharSetSize);
		//plainToHashCPU((char*)&indexE, INDEX_SIZE_IN_BYTES, hash);
	}
	if (compareHash(givenHash, hash) == true) {
		indexToPlainCPU(indexE, plain, plainLength, plainCharSet, plainCharSetSize);
		return true;
	}
	return false;
}

void searchAndRebuildPerThread(const uint beginPos, const uint endPos, const DecryptedInfo* hostDecryptedInfo, const Chain * chains, const size_t chainsSize, unsigned char * givenHash, const uint plainCharSetSize, const char * plainCharSet, const uint8_t plainLength, char* resultStore)
{
	unsigned char hash[32];
	char res[9];
	for (int i = beginPos;i < endPos;i++) {
		if (flag) {
			return;
		}
		ulong index = hostDecryptedInfo[i].index;
		int pos = searchThroughChains(chains, chainsSize, index);
		if (pos != -1) {
			printf("%d\n", pos);
			if (rebuildAndCompare(givenHash, hash, res, chains[pos].indexS, hostDecryptedInfo[i].pos, plainCharSetSize, plainCharSet, plainLength)) {
				for (int i = 0; i < plainLength;i++) {
					resultStore[i] = res[i];
				}
				//putchar(res[0]);
				//putchar(res[1]);
				//putchar(res[2]);
				//putchar(res[3]);
				//putchar(res[4]);
				//putchar(res[5]);
				//putchar('\n');
				flag = true;
				return;
			}
		}
	}
}

void processCommandInstruction(int argc, const char * argv[], int * passwordLength, char * charSetPath, char * tablePath)
{
	sscanf_s(argv[0], "%d", &passwordLength);
	sscanf_s(argv[1], "%s", charSetPath);
	sscanf_s(argv[2], "%s", tablePath);
}

//  二分查找 >1  <-1
int binarySearch(const struct PasswordMapping* mapping, const int CHAINS_SIZE, unsigned char hash[]) {
	int head = 0;
	int tail = CHAINS_SIZE - 1;
	while (head <= tail) {
		int mid = (head + tail) / 2;
		if (compareHash_(mapping[mid].hash, hash) == 0) {
			return (head + tail) / 2;
		}
		else if (compareHash_(mapping[mid].hash, hash) == 1) {
			tail = mid - 1;
		}
		else {
			head = mid + 1;
		}
	}
	return -1;
}

void hashTransfer(const char * src, unsigned char hash[])
{
	sscanf_s(src, "%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx",
		&hash[0], &hash[1], &hash[2], &hash[3], &hash[4], &hash[5], &hash[6], &hash[7],
		&hash[8], &hash[9], &hash[10], &hash[11], &hash[12], &hash[13], &hash[14], &hash[15],
		&hash[16], &hash[17], &hash[18], &hash[19], &hash[20], &hash[21], &hash[22], &hash[23],
		&hash[24], &hash[25], &hash[26], &hash[27], &hash[28], &hash[29], &hash[30], &hash[31]);
}

//int main() {
//	//char data[] = "Hello World!";
//	//unsigned char hash[32];
//
//	//mySHA256Implement(data, strlen(data), hash);
//
//	char charSet[36];
//	getCharSet(charSet, "../charsets/loweralpha-numeric.txt", 36);
//
//	int plainLength = 12;
//
//	generateInitialIndex(chains, CHAINS_SIZE);
//
//	generateChains(chains, CHAINS_SIZE, 36, charSet, plainLength, 100, (ulong)pow(36, plainLength));
//
//	writeToFile("t1.rt", chains, sizeof(struct Chain), CHAINS_SIZE);
//
//	return 0;
//}