#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include <string>
#include <random>
#include <math.h>

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


using std::string;

__declspec(align(16)) struct Chain {
	ulong indexS;
	ulong indexE;
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
//void indexToPlainCPU(ulong index, size_t plainCharsetSize, const char* plainCharset,
//	size_t plainLength, char* plain);
//
//void plainToHashCPU(char* plain, size_t length, unsigned char* hash);
//
//ulong hashToIndexCPU(unsigned char* hash, int pos, ulong PlainSpaceTotal);

size_t getCharSet(char* charSet, const char* filePath, size_t charSetSize);

void hashToPlain(char* plain, int pos, unsigned char* hash, char* charSet, size_t charSetSize);


//inline ulong generateSingleChainCPU(ulong indexS, int offset, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal);
//
//void generateChains(struct Chain* chains, size_t chainsSize, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal);

void writeToFile(const char* filePath, const void* buffer, size_t elementSize, size_t bufferSize);

void generateInitialIndex(struct Chain* chains, size_t chainsSize);

void openTableFile(const char* filePath,void* buffer, size_t elementSize, size_t bufferSize);


