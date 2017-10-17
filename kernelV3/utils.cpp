#include "utils.h"

//struct Chain chains[CHAINS_SIZE];

//uint k[64] = {
//	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
//	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
//	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
//	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
//	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
//	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
//	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
//	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
//};
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
////
//void plainToHashCPU(char* plain, size_t length, unsigned char* res)
//{
//	unsigned int bitlen0 = 0;
//	unsigned int bitlen1 = 0;
//	unsigned int state[8];
//	
//	unsigned char data[64];
//	
//	unsigned int l;
//	
//	for (l = 0; l < length; ++l) {
//		data[l] = plain[l];
//	}
//	
//	state[0] = 0x6a09e667;
//	state[1] = 0xbb67ae85;
//	state[2] = 0x3c6ef372;
//	state[3] = 0xa54ff53a;
//	state[4] = 0x510e527f;
//	state[5] = 0x9b05688c;
//	state[6] = 0x1f83d9ab;
//	state[7] = 0x5be0cd19;
//	
//	
//	// Pad whatever data is left in the buffer. 
//	data[l++] = 0x80;
//	while (l < 56)
//		data[l++] = 0x00;
//	
//	
//	// Append to the padding the total message's length in bits and transform. 
//	DBL_INT_ADD(bitlen0, bitlen1, length * 8);
//	data[63] = bitlen0;
//	data[62] = bitlen0 >> 8;
//	data[61] = bitlen0 >> 16;
//	data[60] = bitlen0 >> 24;
//	data[59] = bitlen1;
//	data[58] = bitlen1 >> 8;
//	data[57] = bitlen1 >> 16;
//	data[56] = bitlen1 >> 24;
//	
//	unsigned int a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];
//	
//	for (i = 0, j = 0; i < 16; ++i, j += 4)
//		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
//	for (; i < 64; ++i)
//		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];
//	
//	a = state[0];
//	b = state[1];
//	c = state[2];
//	d = state[3];
//	e = state[4];
//	f = state[5];
//	g = state[6];
//	h = state[7];
//	
//	for (i = 0; i < 64; ++i) {
//		t1 = h + EP1(e) + CH(e, f, g) + k[i] + m[i];
//		t2 = EP0(a) + MAJ(a, b, c);
//		h = g;
//		g = f;
//		f = e;
//		e = d + t1;
//		d = c;
//		c = b;
//		b = a;
//		a = t1 + t2;
//	}
//	
//	state[0] += a;
//	state[1] += b;
//	state[2] += c;
//	state[3] += d;
//	state[4] += e;
//	state[5] += f;
//	state[6] += g;
//	state[7] += h;
//	
//	// Since this implementation uses little endian byte ordering and SHA uses big endian,
//	// reverse all the bytes when copying the final state to the output hash. 
//	for (i = 0; i < 4; ++i) {
//		l = i << 3;
//		*(res) = (state[0] >> (24 - l)) & 0x000000ff;
//		*(res + 4) = (state[1] >> (24 - l)) & 0x000000ff;
//		*(res + 8) = (state[2] >> (24 - l)) & 0x000000ff;
//		*(res + 12) = (state[3] >> (24 - l)) & 0x000000ff;
//		*(res + 16) = (state[4] >> (24 - l)) & 0x000000ff;
//		*(res + 20) = (state[5] >> (24 - l)) & 0x000000ff;
//		*(res + 24) = (state[6] >> (24 - l)) & 0x000000ff;
//		*(res + 28) = (state[7] >> (24 - l)) & 0x000000ff;
//		++res;
//	}
//}
////
//ulong hashToIndexCPU(unsigned char* hash, int pos, ulong PlainSpaceTotal)
//{
//	ulong* hashP = (ulong*)hash;
//	return (ulong)(((*(hashP) ^ *(hashP + 1) ^ *(hashP + 2) ^ *(hashP + 3)) + pos) % PlainSpaceTotal);
//}

size_t getCharSet(char* charSet, const char* filePath, size_t charSetSize)
{
	FILE* charSetFile;

	if ((charSetFile = fopen(filePath, "r")) == NULL) {
		printf("no file exist");
		return 0;
	}
	return fread(charSet, sizeof(char), charSetSize, charSetFile);
}


//inline ulong generateSingleChainCPU(ulong indexS, int offset, size_t plainCharSetSize,
//	const char* plainCharSet, size_t plainLength, size_t chainLength, ulong plainSpaceTotal)
//{
//	unsigned char hash[32];
//	char plain[12];
//	ulong indexE;
//	for (int i = 0;i < chainLength;i++) {
//		indexToPlainCPU(indexS, plainCharSetSize, plainCharSet, plainLength, plain);
//		plainToHashCPU(plain, plainLength, hash);
//		indexE = hashToIndexCPU(hash, i, plainSpaceTotal);
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