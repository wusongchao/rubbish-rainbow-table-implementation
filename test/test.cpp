#include <cstdio>
#include <string>
#include <sstream>

#define ulong unsigned __int64

void hashTransfer(const char * src, unsigned char hash[])
{
	sscanf_s(src, "%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx",
		&hash[0], &hash[1], &hash[2], &hash[3], &hash[4], &hash[5], &hash[6], &hash[7],
		&hash[8], &hash[9], &hash[10], &hash[11], &hash[12], &hash[13], &hash[14], &hash[15],
		&hash[16], &hash[17], &hash[18], &hash[19], &hash[20], &hash[21], &hash[22], &hash[23],
		&hash[24], &hash[25], &hash[26], &hash[27], &hash[28], &hash[29], &hash[30], &hash[31]);
}

void PrintHash(const unsigned char* Hash)
{
	printf("%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		Hash[0], Hash[1], Hash[2], Hash[3], Hash[4], Hash[5], Hash[6], Hash[7],
		Hash[8], Hash[9], Hash[10], Hash[11], Hash[12], Hash[13], Hash[14], Hash[15],
		Hash[16], Hash[17], Hash[18], Hash[19], Hash[20], Hash[21], Hash[22], Hash[23],
		Hash[24], Hash[25], Hash[26], Hash[27], Hash[28], Hash[29], Hash[30], Hash[31]);
}

bool compartor(const unsigned char* lhs, const unsigned char* rhs)
{
	const ulong* lhsP = (const ulong *)lhs;
	const ulong* rhsP = (const ulong *)rhs;
	ulong lhs4 = *(lhsP + 3);
	ulong lhs3 = *(lhsP + 2);
	ulong lhs2 = *(lhsP + 1);
	ulong lhs1 = *(lhsP);
	ulong rhs4 = *(rhsP + 3);
	ulong rhs3 = *(rhsP + 2);
	ulong rhs2 = *(rhsP + 1);
	ulong rhs1 = *(rhsP);
	//int a = lhs1 < rhs1;
	//int b = (lhs1 == rhs1 && lhs2 < rhs2);
	//int c = (lhs1 == rhs1 && lhs2 == rhs2 && lhs3 < rhs3);
	//int d = (lhs1 == rhs1 && lhs2 == rhs2 && lhs3 == rhs3 && lhs4 < rhs4);
	//printf("\n%llx %llx\n", lhs1, rhs1);
	//printf("%llx %llx\n", lhs2, rhs2);
	//printf("%llx %llx\n", lhs3, rhs3);
	//printf("%llx %llx\n", lhs4, rhs4);
	return (lhs1 < rhs1)
		|| (lhs1 == rhs1 && lhs2 < rhs2)
		|| (lhs1 == rhs1 && lhs2 == rhs2 && lhs3 < rhs3)
		|| (lhs1 == rhs1 && lhs2 == rhs2 && lhs3 == rhs3 && lhs4 < rhs4);
	//bool flap = true;
	//for (int i = 0; i < 32; i++) {
	//	if (lhs[i] > rhs[i]) {
	//		flap = false;
	//		break;
	//	}
	//}
	//if (flap) {
	//	return true;
	//}
	//else {
	//	return false;
	//}
}

int compareHash(const unsigned char * lhs, const unsigned char * rhs)
{
	const ulong* lhsP = (const ulong *)lhs;
	const ulong* rhsP = (const ulong *)rhs;
	/*
	*(rhsP + 1 2 3 )
	*/
	if (*lhsP == *rhsP
		&& *(lhsP + 1) == *(rhsP + 1)
		&& *(lhsP + 2) == *(rhsP + 2)
		&& *(lhsP + 3) == *(rhsP + 3)) {
		return 0;
	}
	if (*lhsP > *rhsP
		|| *lhsP == *rhsP && *(lhsP + 1) > *(rhsP + 1)
		|| *lhsP == *rhsP && *(lhsP + 1) == *(rhsP + 1) && *(lhsP + 2) > *(rhsP + 2)
		|| *lhsP == *rhsP && *(lhsP + 1) == *(rhsP + 1) && *(lhsP + 2) == *(rhsP + 2) && *(lhsP + 3) > *(rhsP + 3)) {
		return 1;
	}
	return -1;
}

using std::string;
using std::stringstream;

string fileNameBuilder(const char * parentPath, const uint32_t plainLength, const char * plainCharSetPath, const uint32_t tableIndex, const uint32_t chainSize, const uint32_t chainLength)
{
	std::stringstream res;
	res << parentPath
		<< plainLength
		<< '#'
		<< plainCharSetPath
		<< '#'
		<< tableIndex
		<< '#'
		<< chainSize
		<< '#'
		<< chainLength;
	return res.str();
}



int main()
{
	//unsigned char hash1[32];
	//hashTransfer("ff3f4036a1164d1ddbad5b3edf9022fddb3e1961a54a922708a6c1ffc49e5489", hash1);
	//unsigned char hash2[32];
	//hashTransfer("ff3f4036a1164d1ddbad5b3edf9022fddb3e1961a54a922708a6c1ffc49e5489", hash2);
	//bool res = 0;
	//res = compartor(hash1, hash2);
	//printf("%d", res);
	//getchar();
	printf("%s",fileNameBuilder("../", 4, "adadada", 1, 100, 350).c_str());
	getchar();
	return 0;
}