#define ROUNDTAIL(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 t1;\n\t" \
		".reg .u32 t2;\n\t" \
		".reg .u32 t3;\n\t" \
		"shf.r.clamp.b32 t1, %6, %6, 11;\n\t" \
		"shf.r.clamp.b32 t2, %6, %6, 25;\n\t" \
		"shf.r.clamp.b32 t3, %6, %6, 6;\n\t" \
		"xor.b32 t1, t1, t2;\n\t" \
		"xor.b32 t3, t3, t1;\n\t" \
		"add.u32 %1, %1, %2;\n\t" \
		"mov.u32 t1, %8;\n\t" \
		"xor.b32 t1, t1, %7;\n\t" \
		"and.b32 t1, t1, %6;\n\t" \
		"xor.b32 t1, t1, %8;\n\t" \
		"add.u32 t3, t3, t1;\n\t" \
		"add.u32 t3, t3, %9;\n\t" \
		"add.u32 %1, %1, t3;\n\t" \
		"add.u32 %0, %0, %1;\n\t" \
		"shf.r.clamp.b32 t1, %3, %3, 13;\n\t" \
		"shf.r.clamp.b32 t2, %3, %3, 22;\n\t" \
		"shf.r.clamp.b32 t3, %3, %3, 2;\n\t" \
		"xor.b32 t1, t1, t2;\n\t" \
		"xor.b32 t3, t3, t1;\n\t" \
		"mov.u32 t1, %5;\n\t" \
		"add.u32 %1, %1, t3;\n\t" \
		"mov.u32 t3, %5;\n\t" \
		"or.b32 t3, t3, %4;\n\t" \
		"and.b32 t1, t1, %4;\n\t" \
		"and.b32 t3, t3, %3;\n\t" \
		"or.b32 t3, t3, t1;\n\t" \
		"add.u32 %1, %1, t3;\n\t" \
		"}" \
		: "+r"(d), "+r"(h) : "r"(schedule[i % 16]), "r"(a), "r"(b), "r"(c), "r"(e), "r"(f), "r"(g), "r"(k));
// 4 8 0 1 2 3 5 6 7 9
// 0 1 2 3 4 5 6 7 8 9
#define ROUNDa(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 t1;\n\t" \
		"shl.b32 %0, %1 ,24;\n\t" \
		"shl.b32 t1, %2, 16;\n\t" \
		"xor.b32 %0, %0, t1;\n\t" \
		"shl.b32 t1, %3, 8;\n\t" \
		"xor.b32 %0, %0, t1;\n\t" \
		"xor.b32 %0, %0, %4;\n\t" \
		"}" \
		: "+r"(schedule[i]) : "r"((unsigned int)data[i*4]), "r"((unsigned int)data[i*4+1]), "r"((unsigned int)data[i*4+2]), "r"((unsigned int)data[i*4+3])); \
		ROUNDTAIL(i, a, b, c, d, e, f, g, h, k)

#define ROUNDb(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[i % 16]) : "r"(schedule[(i-15)%16]), "r"(schedule[(i-16)%16]), "r"(schedule[(i-7)%16]), "r"(schedule[(i-2)%16])); \
		ROUNDTAIL(i, a, b, c, d, e, f, g, h, k)

#define ROUND16(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[0]) : "r"(schedule[1]), "r"(schedule[0]), "r"(schedule[9]), "r"(schedule[14])); \
		ROUNDTAIL(0, a, b, c, d, e, f, g, h, k)

#define ROUND17(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[1]) : "r"(schedule[2]), "r"(schedule[1]), "r"(schedule[10]), "r"(schedule[15])); \
		ROUNDTAIL(1, a, b, c, d, e, f, g, h, k)

#define ROUND18(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[2]) : "r"(schedule[3]), "r"(schedule[2]), "r"(schedule[11]), "r"(schedule[0])); \
		ROUNDTAIL(2, a, b, c, d, e, f, g, h, k)

#define ROUND19(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[3]) : "r"(schedule[4]), "r"(schedule[3]), "r"(schedule[12]), "r"(schedule[1])); \
		ROUNDTAIL(3, a, b, c, d, e, f, g, h, k)

#define ROUND20(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[4]) : "r"(schedule[5]), "r"(schedule[4]), "r"(schedule[13]), "r"(schedule[2])); \
		ROUNDTAIL(4, a, b, c, d, e, f, g, h, k)

#define ROUND21(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[5]) : "r"(schedule[6]), "r"(schedule[5]), "r"(schedule[14]), "r"(schedule[3])); \
		ROUNDTAIL(5, a, b, c, d, e, f, g, h, k)

#define ROUND22(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[6]) : "r"(schedule[7]), "r"(schedule[6]), "r"(schedule[15]), "r"(schedule[4])); \
		ROUNDTAIL(6, a, b, c, d, e, f, g, h, k)

#define ROUND23(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[7]) : "r"(schedule[8]), "r"(schedule[7]), "r"(schedule[0]), "r"(schedule[5])); \
		ROUNDTAIL(7, a, b, c, d, e, f, g, h, k)

#define ROUND24(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[8]) : "r"(schedule[9]), "r"(schedule[8]), "r"(schedule[1]), "r"(schedule[6])); \
		ROUNDTAIL(8, a, b, c, d, e, f, g, h, k)

#define ROUND25(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[9]) : "r"(schedule[10]), "r"(schedule[9]), "r"(schedule[2]), "r"(schedule[7])); \
		ROUNDTAIL(9, a, b, c, d, e, f, g, h, k)

#define ROUND26(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[10]) : "r"(schedule[11]), "r"(schedule[10]), "r"(schedule[3]), "r"(schedule[8])); \
		ROUNDTAIL(10, a, b, c, d, e, f, g, h, k)

#define ROUND27(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[11]) : "r"(schedule[12]), "r"(schedule[11]), "r"(schedule[4]), "r"(schedule[9])); \
		ROUNDTAIL(11, a, b, c, d, e, f, g, h, k)

#define ROUND28(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[12]) : "r"(schedule[13]), "r"(schedule[12]), "r"(schedule[5]), "r"(schedule[10])); \
		ROUNDTAIL(12, a, b, c, d, e, f, g, h, k)

#define ROUND29(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[13]) : "r"(schedule[14]), "r"(schedule[13]), "r"(schedule[6]), "r"(schedule[11])); \
		ROUNDTAIL(13, a, b, c, d, e, f, g, h, k)

#define ROUND30(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[14]) : "r"(schedule[15]), "r"(schedule[14]), "r"(schedule[7]), "r"(schedule[12])); \
		ROUNDTAIL(14, a, b, c, d, e, f, g, h, k)

#define ROUND31(i, a, b, c, d, e, f, g, h, k) \
		asm("{\n\t" \
		".reg .u32 eax;\n\t" \
		".reg .u32 ebx;\n\t" \
		".reg .u32 ecx;\n\t" \
		".reg .u32 edx;\n\t" \
		"mov.u32 eax, %1;\n\t" \
		"mov.u32 ebx, %2;\n\t" \
		"add.u32 ebx, ebx, %3;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 18;\n\t" \
		"shr.u32 edx, edx, 3;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 7;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 eax, %4;\n\t" \
		"mov.u32 ecx, eax;\n\t" \
		"mov.u32 edx, eax;\n\t" \
		"shf.r.clamp.b32 ecx, ecx, ecx, 19;\n\t" \
		"shr.u32 edx, edx, 10;\n\t" \
		"shf.r.clamp.b32 eax, eax, eax, 17;\n\t" \
		"xor.b32 ecx, ecx, edx;\n\t" \
		"xor.b32 eax, eax, ecx;\n\t" \
		"add.u32 ebx, ebx, eax;\n\t" \
		"mov.u32 %0, ebx;\n\t" \
		"}" \
		: "=r"(schedule[15]) : "r"(schedule[0]), "r"(schedule[15]), "r"(schedule[8]), "r"(schedule[13])); \
		ROUNDTAIL(15, a, b, c, d, e, f, g, h, k)
