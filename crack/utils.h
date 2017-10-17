#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include <string>
#include <random>
#include <math.h>
#include <map>
#include <mutex>

#define uchar unsigned char // 8-bit byte
#define uint unsigned int // 32-bit word
#define ulong unsigned __int64

#define SHA256_ROTL(a,b) (((a>>(32-b))&(0x7fffffff>>(31-b)))|(a<<b))
#define SHA256_SR(a,b) ((a>>b)&(0x7fffffff>>(b-1)))
#define SHA256_Ch(x,y,z) ((x&y)^((~x)&z))
#define SHA256_Maj(x,y,z) ((x&y)^(x&z)^(y&z))
#define SHA256_E0(x) (SHA256_ROTL(x,30)^SHA256_ROTL(x,19)^SHA256_ROTL(x,10))
#define SHA256_E1(x) (SHA256_ROTL(x,26)^SHA256_ROTL(x,21)^SHA256_ROTL(x,7))
#define SHA256_O0(x) (SHA256_ROTL(x,25)^SHA256_ROTL(x,14)^SHA256_SR(x,3))
#define SHA256_O1(x) (SHA256_ROTL(x,15)^SHA256_ROTL(x,13)^SHA256_SR(x,10))

#define DBL_INT_ADD(a,b,c) if (a > 0xffffffff - (c)) ++b; a += c;
#define ROTLEFT(a,b) (((a) << (b)) | ((a) >> (32-(b))))
#define ROTRIGHT(a,b) (((a) >> (b)) | ((a) << (32-(b))))

#define CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTRIGHT(x,2) ^ ROTRIGHT(x,13) ^ ROTRIGHT(x,22))
#define EP1(x) (ROTRIGHT(x,6) ^ ROTRIGHT(x,11) ^ ROTRIGHT(x,25))
#define SIG0(x) (ROTRIGHT(x,7) ^ ROTRIGHT(x,18) ^ ((x) >> 3))
#define SIG1(x) (ROTRIGHT(x,17) ^ ROTRIGHT(x,19) ^ ((x) >> 10))

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

#define ROUND(a, b, c, d, e, f, g, h, i, k) \
		h = 0U + h + (ROTR32(e, 6) ^ ROTR32(e, 11) ^ ROTR32(e, 25)) + (g ^ (e & (f ^ g))) + UINT32_C(k) + schedule[i];  \
		d = 0U + d + h;  \
		h = 0U + h + (ROTR32(a, 2) ^ ROTR32(a, 13) ^ ROTR32(a, 22)) + ((a & (b | c)) | (b & c));

#define ROUND16(a, b, c, d, e, f, g, h, i, k) \
		h = 0U + h + (ROTR32(e, 6) ^ ROTR32(e, 11) ^ ROTR32(e, 25)) + (g ^ (e & (f ^ g))) + UINT32_C(k) + schedule[i];  \
		d = 0U + d + h;  \
		h = 0U + h + (ROTR32(a, 2) ^ ROTR32(a, 13) ^ ROTR32(a, 22)) + ((a & (b | c)) | (b & c));


#define INDEX_SIZE_IN_BYTES 8


using std::string;
using std::map;

extern uint k[];
extern std::mutex lock;

typedef struct {
	uchar data[64];
	uint datalen;
	uint bitlen[2];
	uint state[8];
} SHA256_CTX;

__declspec(align(16)) struct Chain {
	ulong indexS;
	ulong indexE;
};

__declspec(align(16)) struct DecryptedInfo{
	int pos;
	ulong index;
};

//inline void mySHA256Implement(char * str, size_t length, unsigned char * res);

void PrintHash(uchar* Hash);


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
void indexToPlainCPU(ulong index, size_t plainCharsetSize, const char* plainCharset,
	size_t plainLength, char* plain);

void indexToPlainCPU(ulong index, char* plain, const uint8_t plainLength, const char* charSet, const uint32_t charSetSize);

bool compareIndex(const ulong lhs, const ulong rhs, const uint8_t plainLength, const uint8_t plainCharSetSize);
void plainToHashCPU(const char* plain, const uint8_t length, unsigned char* hash);
void plainToHashCPU(ulong index, const uint8_t length, unsigned char* hash, const uint8_t charSetSize);

ulong plainToIndexCPU(const char* plain, size_t plainLength, const char* charSet, size_t charSetSize, map<const char, size_t>* charIndexMap);

ulong hashToIndexPaperVersion(unsigned char* hash, int pos, const uint8_t plainLength, const char* plainCharSetP, size_t plainCharSetSize);

ulong hashToIndexCPU(unsigned char* hash, int pos);

size_t getCharSet(char* charSet, const char* filePath, size_t charSetSize);

void hashToPlain(char* plain, int pos, unsigned char* hash, char* charSet, size_t charSetSize);


inline ulong generateSingleChainCPU(ulong indexS, size_t plainCharSetSize,
	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal);
//
//void generateChains(struct Chain* chains, size_t chainsSize, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal);

void writeToFile(const char* filePath, const void* buffer, size_t elementSize, size_t bufferSize);

void generateInitialIndex(struct Chain* chains, size_t chainsSize);

void openTableFile(const char* filePath, void* buffer, size_t elementSize, size_t bufferSize);

bool compareHash(const unsigned char* givenHash, const unsigned char* calHash);

int searchThroughChains(const struct Chain* chains, size_t chainsSize, ulong index);

bool rebuildAndCompare(unsigned char* givenHash, unsigned char* hash, char* plain, ulong indexS, int pos, uint plainCharSetSize, const char * plainCharSet, uint8_t plainLength);

void searchAndRebuildPerThread(const uint beginPos, const uint endPos, const DecryptedInfo* hostDecryptedInfo, const Chain * chains, const size_t chainsSize, unsigned char * givenHash, const uint plainCharSetSize, const char * plainCharSet, const uint8_t plainLength, char* resultStore);