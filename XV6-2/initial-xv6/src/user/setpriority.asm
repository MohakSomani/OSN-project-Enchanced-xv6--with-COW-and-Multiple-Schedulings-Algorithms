
user/_setpriority:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
   0:	1101                	add	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	add	s0,sp,32
    if (argc != 3) {
   c:	478d                	li	a5,3
   e:	02f50063          	beq	a0,a5,2e <main+0x2e>
        fprintf(2, "Usage: setpriority <pid> <priority>\n");
  12:	00001597          	auipc	a1,0x1
  16:	81e58593          	add	a1,a1,-2018 # 830 <malloc+0xe8>
  1a:	4509                	li	a0,2
  1c:	00000097          	auipc	ra,0x0
  20:	646080e7          	jalr	1606(ra) # 662 <fprintf>
        exit(1);
  24:	4505                	li	a0,1
  26:	00000097          	auipc	ra,0x0
  2a:	2ea080e7          	jalr	746(ra) # 310 <exit>
  2e:	84ae                	mv	s1,a1
    }

    int pid = atoi(argv[1]);
  30:	6588                	ld	a0,8(a1)
  32:	00000097          	auipc	ra,0x0
  36:	1e4080e7          	jalr	484(ra) # 216 <atoi>
  3a:	892a                	mv	s2,a0
    int priority = atoi(argv[2]);
  3c:	6888                	ld	a0,16(s1)
  3e:	00000097          	auipc	ra,0x0
  42:	1d8080e7          	jalr	472(ra) # 216 <atoi>
  46:	84aa                	mv	s1,a0

    if (setpriority(pid, priority) == 0) {
  48:	85aa                	mv	a1,a0
  4a:	854a                	mv	a0,s2
  4c:	00000097          	auipc	ra,0x0
  50:	374080e7          	jalr	884(ra) # 3c0 <setpriority>
  54:	e105                	bnez	a0,74 <main+0x74>
        printf("Priority set for process %d: %d\n", pid, priority);
  56:	8626                	mv	a2,s1
  58:	85ca                	mv	a1,s2
  5a:	00000517          	auipc	a0,0x0
  5e:	7fe50513          	add	a0,a0,2046 # 858 <malloc+0x110>
  62:	00000097          	auipc	ra,0x0
  66:	62e080e7          	jalr	1582(ra) # 690 <printf>
    } else {
        fprintf(2, "Failed to set priority for process %d.\n", pid);
    }

    exit(0);
  6a:	4501                	li	a0,0
  6c:	00000097          	auipc	ra,0x0
  70:	2a4080e7          	jalr	676(ra) # 310 <exit>
        fprintf(2, "Failed to set priority for process %d.\n", pid);
  74:	864a                	mv	a2,s2
  76:	00001597          	auipc	a1,0x1
  7a:	80a58593          	add	a1,a1,-2038 # 880 <malloc+0x138>
  7e:	4509                	li	a0,2
  80:	00000097          	auipc	ra,0x0
  84:	5e2080e7          	jalr	1506(ra) # 662 <fprintf>
  88:	b7cd                	j	6a <main+0x6a>

000000000000008a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  8a:	1141                	add	sp,sp,-16
  8c:	e406                	sd	ra,8(sp)
  8e:	e022                	sd	s0,0(sp)
  90:	0800                	add	s0,sp,16
  extern int main();
  main();
  92:	00000097          	auipc	ra,0x0
  96:	f6e080e7          	jalr	-146(ra) # 0 <main>
  exit(0);
  9a:	4501                	li	a0,0
  9c:	00000097          	auipc	ra,0x0
  a0:	274080e7          	jalr	628(ra) # 310 <exit>

00000000000000a4 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  a4:	1141                	add	sp,sp,-16
  a6:	e422                	sd	s0,8(sp)
  a8:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  aa:	87aa                	mv	a5,a0
  ac:	0585                	add	a1,a1,1
  ae:	0785                	add	a5,a5,1
  b0:	fff5c703          	lbu	a4,-1(a1)
  b4:	fee78fa3          	sb	a4,-1(a5)
  b8:	fb75                	bnez	a4,ac <strcpy+0x8>
    ;
  return os;
}
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	add	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  c0:	1141                	add	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	add	s0,sp,16
  while(*p && *p == *q)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cb91                	beqz	a5,de <strcmp+0x1e>
  cc:	0005c703          	lbu	a4,0(a1)
  d0:	00f71763          	bne	a4,a5,de <strcmp+0x1e>
    p++, q++;
  d4:	0505                	add	a0,a0,1
  d6:	0585                	add	a1,a1,1
  while(*p && *p == *q)
  d8:	00054783          	lbu	a5,0(a0)
  dc:	fbe5                	bnez	a5,cc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  de:	0005c503          	lbu	a0,0(a1)
}
  e2:	40a7853b          	subw	a0,a5,a0
  e6:	6422                	ld	s0,8(sp)
  e8:	0141                	add	sp,sp,16
  ea:	8082                	ret

00000000000000ec <strlen>:

uint
strlen(const char *s)
{
  ec:	1141                	add	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  f2:	00054783          	lbu	a5,0(a0)
  f6:	cf91                	beqz	a5,112 <strlen+0x26>
  f8:	0505                	add	a0,a0,1
  fa:	87aa                	mv	a5,a0
  fc:	86be                	mv	a3,a5
  fe:	0785                	add	a5,a5,1
 100:	fff7c703          	lbu	a4,-1(a5)
 104:	ff65                	bnez	a4,fc <strlen+0x10>
 106:	40a6853b          	subw	a0,a3,a0
 10a:	2505                	addw	a0,a0,1
    ;
  return n;
}
 10c:	6422                	ld	s0,8(sp)
 10e:	0141                	add	sp,sp,16
 110:	8082                	ret
  for(n = 0; s[n]; n++)
 112:	4501                	li	a0,0
 114:	bfe5                	j	10c <strlen+0x20>

0000000000000116 <memset>:

void*
memset(void *dst, int c, uint n)
{
 116:	1141                	add	sp,sp,-16
 118:	e422                	sd	s0,8(sp)
 11a:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 11c:	ca19                	beqz	a2,132 <memset+0x1c>
 11e:	87aa                	mv	a5,a0
 120:	1602                	sll	a2,a2,0x20
 122:	9201                	srl	a2,a2,0x20
 124:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 128:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 12c:	0785                	add	a5,a5,1
 12e:	fee79de3          	bne	a5,a4,128 <memset+0x12>
  }
  return dst;
}
 132:	6422                	ld	s0,8(sp)
 134:	0141                	add	sp,sp,16
 136:	8082                	ret

0000000000000138 <strchr>:

char*
strchr(const char *s, char c)
{
 138:	1141                	add	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	add	s0,sp,16
  for(; *s; s++)
 13e:	00054783          	lbu	a5,0(a0)
 142:	cb99                	beqz	a5,158 <strchr+0x20>
    if(*s == c)
 144:	00f58763          	beq	a1,a5,152 <strchr+0x1a>
  for(; *s; s++)
 148:	0505                	add	a0,a0,1
 14a:	00054783          	lbu	a5,0(a0)
 14e:	fbfd                	bnez	a5,144 <strchr+0xc>
      return (char*)s;
  return 0;
 150:	4501                	li	a0,0
}
 152:	6422                	ld	s0,8(sp)
 154:	0141                	add	sp,sp,16
 156:	8082                	ret
  return 0;
 158:	4501                	li	a0,0
 15a:	bfe5                	j	152 <strchr+0x1a>

000000000000015c <gets>:

char*
gets(char *buf, int max)
{
 15c:	711d                	add	sp,sp,-96
 15e:	ec86                	sd	ra,88(sp)
 160:	e8a2                	sd	s0,80(sp)
 162:	e4a6                	sd	s1,72(sp)
 164:	e0ca                	sd	s2,64(sp)
 166:	fc4e                	sd	s3,56(sp)
 168:	f852                	sd	s4,48(sp)
 16a:	f456                	sd	s5,40(sp)
 16c:	f05a                	sd	s6,32(sp)
 16e:	ec5e                	sd	s7,24(sp)
 170:	1080                	add	s0,sp,96
 172:	8baa                	mv	s7,a0
 174:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 176:	892a                	mv	s2,a0
 178:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 17a:	4aa9                	li	s5,10
 17c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 17e:	89a6                	mv	s3,s1
 180:	2485                	addw	s1,s1,1
 182:	0344d863          	bge	s1,s4,1b2 <gets+0x56>
    cc = read(0, &c, 1);
 186:	4605                	li	a2,1
 188:	faf40593          	add	a1,s0,-81
 18c:	4501                	li	a0,0
 18e:	00000097          	auipc	ra,0x0
 192:	19a080e7          	jalr	410(ra) # 328 <read>
    if(cc < 1)
 196:	00a05e63          	blez	a0,1b2 <gets+0x56>
    buf[i++] = c;
 19a:	faf44783          	lbu	a5,-81(s0)
 19e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1a2:	01578763          	beq	a5,s5,1b0 <gets+0x54>
 1a6:	0905                	add	s2,s2,1
 1a8:	fd679be3          	bne	a5,s6,17e <gets+0x22>
  for(i=0; i+1 < max; ){
 1ac:	89a6                	mv	s3,s1
 1ae:	a011                	j	1b2 <gets+0x56>
 1b0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1b2:	99de                	add	s3,s3,s7
 1b4:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b8:	855e                	mv	a0,s7
 1ba:	60e6                	ld	ra,88(sp)
 1bc:	6446                	ld	s0,80(sp)
 1be:	64a6                	ld	s1,72(sp)
 1c0:	6906                	ld	s2,64(sp)
 1c2:	79e2                	ld	s3,56(sp)
 1c4:	7a42                	ld	s4,48(sp)
 1c6:	7aa2                	ld	s5,40(sp)
 1c8:	7b02                	ld	s6,32(sp)
 1ca:	6be2                	ld	s7,24(sp)
 1cc:	6125                	add	sp,sp,96
 1ce:	8082                	ret

00000000000001d0 <stat>:

int
stat(const char *n, struct stat *st)
{
 1d0:	1101                	add	sp,sp,-32
 1d2:	ec06                	sd	ra,24(sp)
 1d4:	e822                	sd	s0,16(sp)
 1d6:	e426                	sd	s1,8(sp)
 1d8:	e04a                	sd	s2,0(sp)
 1da:	1000                	add	s0,sp,32
 1dc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1de:	4581                	li	a1,0
 1e0:	00000097          	auipc	ra,0x0
 1e4:	170080e7          	jalr	368(ra) # 350 <open>
  if(fd < 0)
 1e8:	02054563          	bltz	a0,212 <stat+0x42>
 1ec:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ee:	85ca                	mv	a1,s2
 1f0:	00000097          	auipc	ra,0x0
 1f4:	178080e7          	jalr	376(ra) # 368 <fstat>
 1f8:	892a                	mv	s2,a0
  close(fd);
 1fa:	8526                	mv	a0,s1
 1fc:	00000097          	auipc	ra,0x0
 200:	13c080e7          	jalr	316(ra) # 338 <close>
  return r;
}
 204:	854a                	mv	a0,s2
 206:	60e2                	ld	ra,24(sp)
 208:	6442                	ld	s0,16(sp)
 20a:	64a2                	ld	s1,8(sp)
 20c:	6902                	ld	s2,0(sp)
 20e:	6105                	add	sp,sp,32
 210:	8082                	ret
    return -1;
 212:	597d                	li	s2,-1
 214:	bfc5                	j	204 <stat+0x34>

0000000000000216 <atoi>:

int
atoi(const char *s)
{
 216:	1141                	add	sp,sp,-16
 218:	e422                	sd	s0,8(sp)
 21a:	0800                	add	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 21c:	00054683          	lbu	a3,0(a0)
 220:	fd06879b          	addw	a5,a3,-48
 224:	0ff7f793          	zext.b	a5,a5
 228:	4625                	li	a2,9
 22a:	02f66863          	bltu	a2,a5,25a <atoi+0x44>
 22e:	872a                	mv	a4,a0
  n = 0;
 230:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 232:	0705                	add	a4,a4,1
 234:	0025179b          	sllw	a5,a0,0x2
 238:	9fa9                	addw	a5,a5,a0
 23a:	0017979b          	sllw	a5,a5,0x1
 23e:	9fb5                	addw	a5,a5,a3
 240:	fd07851b          	addw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 244:	00074683          	lbu	a3,0(a4)
 248:	fd06879b          	addw	a5,a3,-48
 24c:	0ff7f793          	zext.b	a5,a5
 250:	fef671e3          	bgeu	a2,a5,232 <atoi+0x1c>
  return n;
}
 254:	6422                	ld	s0,8(sp)
 256:	0141                	add	sp,sp,16
 258:	8082                	ret
  n = 0;
 25a:	4501                	li	a0,0
 25c:	bfe5                	j	254 <atoi+0x3e>

000000000000025e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 25e:	1141                	add	sp,sp,-16
 260:	e422                	sd	s0,8(sp)
 262:	0800                	add	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 264:	02b57463          	bgeu	a0,a1,28c <memmove+0x2e>
    while(n-- > 0)
 268:	00c05f63          	blez	a2,286 <memmove+0x28>
 26c:	1602                	sll	a2,a2,0x20
 26e:	9201                	srl	a2,a2,0x20
 270:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 274:	872a                	mv	a4,a0
      *dst++ = *src++;
 276:	0585                	add	a1,a1,1
 278:	0705                	add	a4,a4,1
 27a:	fff5c683          	lbu	a3,-1(a1)
 27e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 282:	fee79ae3          	bne	a5,a4,276 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 286:	6422                	ld	s0,8(sp)
 288:	0141                	add	sp,sp,16
 28a:	8082                	ret
    dst += n;
 28c:	00c50733          	add	a4,a0,a2
    src += n;
 290:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 292:	fec05ae3          	blez	a2,286 <memmove+0x28>
 296:	fff6079b          	addw	a5,a2,-1
 29a:	1782                	sll	a5,a5,0x20
 29c:	9381                	srl	a5,a5,0x20
 29e:	fff7c793          	not	a5,a5
 2a2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2a4:	15fd                	add	a1,a1,-1
 2a6:	177d                	add	a4,a4,-1
 2a8:	0005c683          	lbu	a3,0(a1)
 2ac:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2b0:	fee79ae3          	bne	a5,a4,2a4 <memmove+0x46>
 2b4:	bfc9                	j	286 <memmove+0x28>

00000000000002b6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b6:	1141                	add	sp,sp,-16
 2b8:	e422                	sd	s0,8(sp)
 2ba:	0800                	add	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2bc:	ca05                	beqz	a2,2ec <memcmp+0x36>
 2be:	fff6069b          	addw	a3,a2,-1
 2c2:	1682                	sll	a3,a3,0x20
 2c4:	9281                	srl	a3,a3,0x20
 2c6:	0685                	add	a3,a3,1
 2c8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ca:	00054783          	lbu	a5,0(a0)
 2ce:	0005c703          	lbu	a4,0(a1)
 2d2:	00e79863          	bne	a5,a4,2e2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d6:	0505                	add	a0,a0,1
    p2++;
 2d8:	0585                	add	a1,a1,1
  while (n-- > 0) {
 2da:	fed518e3          	bne	a0,a3,2ca <memcmp+0x14>
  }
  return 0;
 2de:	4501                	li	a0,0
 2e0:	a019                	j	2e6 <memcmp+0x30>
      return *p1 - *p2;
 2e2:	40e7853b          	subw	a0,a5,a4
}
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	add	sp,sp,16
 2ea:	8082                	ret
  return 0;
 2ec:	4501                	li	a0,0
 2ee:	bfe5                	j	2e6 <memcmp+0x30>

00000000000002f0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2f0:	1141                	add	sp,sp,-16
 2f2:	e406                	sd	ra,8(sp)
 2f4:	e022                	sd	s0,0(sp)
 2f6:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
 2f8:	00000097          	auipc	ra,0x0
 2fc:	f66080e7          	jalr	-154(ra) # 25e <memmove>
}
 300:	60a2                	ld	ra,8(sp)
 302:	6402                	ld	s0,0(sp)
 304:	0141                	add	sp,sp,16
 306:	8082                	ret

0000000000000308 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 308:	4885                	li	a7,1
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <exit>:
.global exit
exit:
 li a7, SYS_exit
 310:	4889                	li	a7,2
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <wait>:
.global wait
wait:
 li a7, SYS_wait
 318:	488d                	li	a7,3
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 320:	4891                	li	a7,4
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <read>:
.global read
read:
 li a7, SYS_read
 328:	4895                	li	a7,5
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <write>:
.global write
write:
 li a7, SYS_write
 330:	48c1                	li	a7,16
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <close>:
.global close
close:
 li a7, SYS_close
 338:	48d5                	li	a7,21
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <kill>:
.global kill
kill:
 li a7, SYS_kill
 340:	4899                	li	a7,6
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <exec>:
.global exec
exec:
 li a7, SYS_exec
 348:	489d                	li	a7,7
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <open>:
.global open
open:
 li a7, SYS_open
 350:	48bd                	li	a7,15
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 358:	48c5                	li	a7,17
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 360:	48c9                	li	a7,18
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 368:	48a1                	li	a7,8
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <link>:
.global link
link:
 li a7, SYS_link
 370:	48cd                	li	a7,19
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 378:	48d1                	li	a7,20
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 380:	48a5                	li	a7,9
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <dup>:
.global dup
dup:
 li a7, SYS_dup
 388:	48a9                	li	a7,10
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 390:	48ad                	li	a7,11
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 398:	48b1                	li	a7,12
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3a0:	48b5                	li	a7,13
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3a8:	48b9                	li	a7,14
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 3b0:	48d9                	li	a7,22
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 3b8:	48dd                	li	a7,23
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <setpriority>:
.global setpriority
setpriority:
 li a7, SYS_setpriority
 3c0:	48e1                	li	a7,24
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c8:	1101                	add	sp,sp,-32
 3ca:	ec06                	sd	ra,24(sp)
 3cc:	e822                	sd	s0,16(sp)
 3ce:	1000                	add	s0,sp,32
 3d0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3d4:	4605                	li	a2,1
 3d6:	fef40593          	add	a1,s0,-17
 3da:	00000097          	auipc	ra,0x0
 3de:	f56080e7          	jalr	-170(ra) # 330 <write>
}
 3e2:	60e2                	ld	ra,24(sp)
 3e4:	6442                	ld	s0,16(sp)
 3e6:	6105                	add	sp,sp,32
 3e8:	8082                	ret

00000000000003ea <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3ea:	7139                	add	sp,sp,-64
 3ec:	fc06                	sd	ra,56(sp)
 3ee:	f822                	sd	s0,48(sp)
 3f0:	f426                	sd	s1,40(sp)
 3f2:	f04a                	sd	s2,32(sp)
 3f4:	ec4e                	sd	s3,24(sp)
 3f6:	0080                	add	s0,sp,64
 3f8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3fa:	c299                	beqz	a3,400 <printint+0x16>
 3fc:	0805c963          	bltz	a1,48e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 400:	2581                	sext.w	a1,a1
  neg = 0;
 402:	4881                	li	a7,0
 404:	fc040693          	add	a3,s0,-64
  }

  i = 0;
 408:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 40a:	2601                	sext.w	a2,a2
 40c:	00000517          	auipc	a0,0x0
 410:	4fc50513          	add	a0,a0,1276 # 908 <digits>
 414:	883a                	mv	a6,a4
 416:	2705                	addw	a4,a4,1
 418:	02c5f7bb          	remuw	a5,a1,a2
 41c:	1782                	sll	a5,a5,0x20
 41e:	9381                	srl	a5,a5,0x20
 420:	97aa                	add	a5,a5,a0
 422:	0007c783          	lbu	a5,0(a5)
 426:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 42a:	0005879b          	sext.w	a5,a1
 42e:	02c5d5bb          	divuw	a1,a1,a2
 432:	0685                	add	a3,a3,1
 434:	fec7f0e3          	bgeu	a5,a2,414 <printint+0x2a>
  if(neg)
 438:	00088c63          	beqz	a7,450 <printint+0x66>
    buf[i++] = '-';
 43c:	fd070793          	add	a5,a4,-48
 440:	00878733          	add	a4,a5,s0
 444:	02d00793          	li	a5,45
 448:	fef70823          	sb	a5,-16(a4)
 44c:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
 450:	02e05863          	blez	a4,480 <printint+0x96>
 454:	fc040793          	add	a5,s0,-64
 458:	00e78933          	add	s2,a5,a4
 45c:	fff78993          	add	s3,a5,-1
 460:	99ba                	add	s3,s3,a4
 462:	377d                	addw	a4,a4,-1
 464:	1702                	sll	a4,a4,0x20
 466:	9301                	srl	a4,a4,0x20
 468:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 46c:	fff94583          	lbu	a1,-1(s2)
 470:	8526                	mv	a0,s1
 472:	00000097          	auipc	ra,0x0
 476:	f56080e7          	jalr	-170(ra) # 3c8 <putc>
  while(--i >= 0)
 47a:	197d                	add	s2,s2,-1
 47c:	ff3918e3          	bne	s2,s3,46c <printint+0x82>
}
 480:	70e2                	ld	ra,56(sp)
 482:	7442                	ld	s0,48(sp)
 484:	74a2                	ld	s1,40(sp)
 486:	7902                	ld	s2,32(sp)
 488:	69e2                	ld	s3,24(sp)
 48a:	6121                	add	sp,sp,64
 48c:	8082                	ret
    x = -xx;
 48e:	40b005bb          	negw	a1,a1
    neg = 1;
 492:	4885                	li	a7,1
    x = -xx;
 494:	bf85                	j	404 <printint+0x1a>

0000000000000496 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 496:	715d                	add	sp,sp,-80
 498:	e486                	sd	ra,72(sp)
 49a:	e0a2                	sd	s0,64(sp)
 49c:	fc26                	sd	s1,56(sp)
 49e:	f84a                	sd	s2,48(sp)
 4a0:	f44e                	sd	s3,40(sp)
 4a2:	f052                	sd	s4,32(sp)
 4a4:	ec56                	sd	s5,24(sp)
 4a6:	e85a                	sd	s6,16(sp)
 4a8:	e45e                	sd	s7,8(sp)
 4aa:	e062                	sd	s8,0(sp)
 4ac:	0880                	add	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ae:	0005c903          	lbu	s2,0(a1)
 4b2:	18090c63          	beqz	s2,64a <vprintf+0x1b4>
 4b6:	8aaa                	mv	s5,a0
 4b8:	8bb2                	mv	s7,a2
 4ba:	00158493          	add	s1,a1,1
  state = 0;
 4be:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4c0:	02500a13          	li	s4,37
 4c4:	4b55                	li	s6,21
 4c6:	a839                	j	4e4 <vprintf+0x4e>
        putc(fd, c);
 4c8:	85ca                	mv	a1,s2
 4ca:	8556                	mv	a0,s5
 4cc:	00000097          	auipc	ra,0x0
 4d0:	efc080e7          	jalr	-260(ra) # 3c8 <putc>
 4d4:	a019                	j	4da <vprintf+0x44>
    } else if(state == '%'){
 4d6:	01498d63          	beq	s3,s4,4f0 <vprintf+0x5a>
  for(i = 0; fmt[i]; i++){
 4da:	0485                	add	s1,s1,1
 4dc:	fff4c903          	lbu	s2,-1(s1)
 4e0:	16090563          	beqz	s2,64a <vprintf+0x1b4>
    if(state == 0){
 4e4:	fe0999e3          	bnez	s3,4d6 <vprintf+0x40>
      if(c == '%'){
 4e8:	ff4910e3          	bne	s2,s4,4c8 <vprintf+0x32>
        state = '%';
 4ec:	89d2                	mv	s3,s4
 4ee:	b7f5                	j	4da <vprintf+0x44>
      if(c == 'd'){
 4f0:	13490263          	beq	s2,s4,614 <vprintf+0x17e>
 4f4:	f9d9079b          	addw	a5,s2,-99
 4f8:	0ff7f793          	zext.b	a5,a5
 4fc:	12fb6563          	bltu	s6,a5,626 <vprintf+0x190>
 500:	f9d9079b          	addw	a5,s2,-99
 504:	0ff7f713          	zext.b	a4,a5
 508:	10eb6f63          	bltu	s6,a4,626 <vprintf+0x190>
 50c:	00271793          	sll	a5,a4,0x2
 510:	00000717          	auipc	a4,0x0
 514:	3a070713          	add	a4,a4,928 # 8b0 <malloc+0x168>
 518:	97ba                	add	a5,a5,a4
 51a:	439c                	lw	a5,0(a5)
 51c:	97ba                	add	a5,a5,a4
 51e:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 520:	008b8913          	add	s2,s7,8
 524:	4685                	li	a3,1
 526:	4629                	li	a2,10
 528:	000ba583          	lw	a1,0(s7)
 52c:	8556                	mv	a0,s5
 52e:	00000097          	auipc	ra,0x0
 532:	ebc080e7          	jalr	-324(ra) # 3ea <printint>
 536:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 538:	4981                	li	s3,0
 53a:	b745                	j	4da <vprintf+0x44>
        printint(fd, va_arg(ap, uint64), 10, 0);
 53c:	008b8913          	add	s2,s7,8
 540:	4681                	li	a3,0
 542:	4629                	li	a2,10
 544:	000ba583          	lw	a1,0(s7)
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	ea0080e7          	jalr	-352(ra) # 3ea <printint>
 552:	8bca                	mv	s7,s2
      state = 0;
 554:	4981                	li	s3,0
 556:	b751                	j	4da <vprintf+0x44>
        printint(fd, va_arg(ap, int), 16, 0);
 558:	008b8913          	add	s2,s7,8
 55c:	4681                	li	a3,0
 55e:	4641                	li	a2,16
 560:	000ba583          	lw	a1,0(s7)
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	e84080e7          	jalr	-380(ra) # 3ea <printint>
 56e:	8bca                	mv	s7,s2
      state = 0;
 570:	4981                	li	s3,0
 572:	b7a5                	j	4da <vprintf+0x44>
        printptr(fd, va_arg(ap, uint64));
 574:	008b8c13          	add	s8,s7,8
 578:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 57c:	03000593          	li	a1,48
 580:	8556                	mv	a0,s5
 582:	00000097          	auipc	ra,0x0
 586:	e46080e7          	jalr	-442(ra) # 3c8 <putc>
  putc(fd, 'x');
 58a:	07800593          	li	a1,120
 58e:	8556                	mv	a0,s5
 590:	00000097          	auipc	ra,0x0
 594:	e38080e7          	jalr	-456(ra) # 3c8 <putc>
 598:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 59a:	00000b97          	auipc	s7,0x0
 59e:	36eb8b93          	add	s7,s7,878 # 908 <digits>
 5a2:	03c9d793          	srl	a5,s3,0x3c
 5a6:	97de                	add	a5,a5,s7
 5a8:	0007c583          	lbu	a1,0(a5)
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	e1a080e7          	jalr	-486(ra) # 3c8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5b6:	0992                	sll	s3,s3,0x4
 5b8:	397d                	addw	s2,s2,-1
 5ba:	fe0914e3          	bnez	s2,5a2 <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 5be:	8be2                	mv	s7,s8
      state = 0;
 5c0:	4981                	li	s3,0
 5c2:	bf21                	j	4da <vprintf+0x44>
        s = va_arg(ap, char*);
 5c4:	008b8993          	add	s3,s7,8
 5c8:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 5cc:	02090163          	beqz	s2,5ee <vprintf+0x158>
        while(*s != 0){
 5d0:	00094583          	lbu	a1,0(s2)
 5d4:	c9a5                	beqz	a1,644 <vprintf+0x1ae>
          putc(fd, *s);
 5d6:	8556                	mv	a0,s5
 5d8:	00000097          	auipc	ra,0x0
 5dc:	df0080e7          	jalr	-528(ra) # 3c8 <putc>
          s++;
 5e0:	0905                	add	s2,s2,1
        while(*s != 0){
 5e2:	00094583          	lbu	a1,0(s2)
 5e6:	f9e5                	bnez	a1,5d6 <vprintf+0x140>
        s = va_arg(ap, char*);
 5e8:	8bce                	mv	s7,s3
      state = 0;
 5ea:	4981                	li	s3,0
 5ec:	b5fd                	j	4da <vprintf+0x44>
          s = "(null)";
 5ee:	00000917          	auipc	s2,0x0
 5f2:	2ba90913          	add	s2,s2,698 # 8a8 <malloc+0x160>
        while(*s != 0){
 5f6:	02800593          	li	a1,40
 5fa:	bff1                	j	5d6 <vprintf+0x140>
        putc(fd, va_arg(ap, uint));
 5fc:	008b8913          	add	s2,s7,8
 600:	000bc583          	lbu	a1,0(s7)
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	dc2080e7          	jalr	-574(ra) # 3c8 <putc>
 60e:	8bca                	mv	s7,s2
      state = 0;
 610:	4981                	li	s3,0
 612:	b5e1                	j	4da <vprintf+0x44>
        putc(fd, c);
 614:	02500593          	li	a1,37
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	dae080e7          	jalr	-594(ra) # 3c8 <putc>
      state = 0;
 622:	4981                	li	s3,0
 624:	bd5d                	j	4da <vprintf+0x44>
        putc(fd, '%');
 626:	02500593          	li	a1,37
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	d9c080e7          	jalr	-612(ra) # 3c8 <putc>
        putc(fd, c);
 634:	85ca                	mv	a1,s2
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	d90080e7          	jalr	-624(ra) # 3c8 <putc>
      state = 0;
 640:	4981                	li	s3,0
 642:	bd61                	j	4da <vprintf+0x44>
        s = va_arg(ap, char*);
 644:	8bce                	mv	s7,s3
      state = 0;
 646:	4981                	li	s3,0
 648:	bd49                	j	4da <vprintf+0x44>
    }
  }
}
 64a:	60a6                	ld	ra,72(sp)
 64c:	6406                	ld	s0,64(sp)
 64e:	74e2                	ld	s1,56(sp)
 650:	7942                	ld	s2,48(sp)
 652:	79a2                	ld	s3,40(sp)
 654:	7a02                	ld	s4,32(sp)
 656:	6ae2                	ld	s5,24(sp)
 658:	6b42                	ld	s6,16(sp)
 65a:	6ba2                	ld	s7,8(sp)
 65c:	6c02                	ld	s8,0(sp)
 65e:	6161                	add	sp,sp,80
 660:	8082                	ret

0000000000000662 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 662:	715d                	add	sp,sp,-80
 664:	ec06                	sd	ra,24(sp)
 666:	e822                	sd	s0,16(sp)
 668:	1000                	add	s0,sp,32
 66a:	e010                	sd	a2,0(s0)
 66c:	e414                	sd	a3,8(s0)
 66e:	e818                	sd	a4,16(s0)
 670:	ec1c                	sd	a5,24(s0)
 672:	03043023          	sd	a6,32(s0)
 676:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 67a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 67e:	8622                	mv	a2,s0
 680:	00000097          	auipc	ra,0x0
 684:	e16080e7          	jalr	-490(ra) # 496 <vprintf>
}
 688:	60e2                	ld	ra,24(sp)
 68a:	6442                	ld	s0,16(sp)
 68c:	6161                	add	sp,sp,80
 68e:	8082                	ret

0000000000000690 <printf>:

void
printf(const char *fmt, ...)
{
 690:	711d                	add	sp,sp,-96
 692:	ec06                	sd	ra,24(sp)
 694:	e822                	sd	s0,16(sp)
 696:	1000                	add	s0,sp,32
 698:	e40c                	sd	a1,8(s0)
 69a:	e810                	sd	a2,16(s0)
 69c:	ec14                	sd	a3,24(s0)
 69e:	f018                	sd	a4,32(s0)
 6a0:	f41c                	sd	a5,40(s0)
 6a2:	03043823          	sd	a6,48(s0)
 6a6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6aa:	00840613          	add	a2,s0,8
 6ae:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6b2:	85aa                	mv	a1,a0
 6b4:	4505                	li	a0,1
 6b6:	00000097          	auipc	ra,0x0
 6ba:	de0080e7          	jalr	-544(ra) # 496 <vprintf>
}
 6be:	60e2                	ld	ra,24(sp)
 6c0:	6442                	ld	s0,16(sp)
 6c2:	6125                	add	sp,sp,96
 6c4:	8082                	ret

00000000000006c6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c6:	1141                	add	sp,sp,-16
 6c8:	e422                	sd	s0,8(sp)
 6ca:	0800                	add	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6cc:	ff050693          	add	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d0:	00001797          	auipc	a5,0x1
 6d4:	9307b783          	ld	a5,-1744(a5) # 1000 <freep>
 6d8:	a02d                	j	702 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6da:	4618                	lw	a4,8(a2)
 6dc:	9f2d                	addw	a4,a4,a1
 6de:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6e2:	6398                	ld	a4,0(a5)
 6e4:	6310                	ld	a2,0(a4)
 6e6:	a83d                	j	724 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6e8:	ff852703          	lw	a4,-8(a0)
 6ec:	9f31                	addw	a4,a4,a2
 6ee:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6f0:	ff053683          	ld	a3,-16(a0)
 6f4:	a091                	j	738 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f6:	6398                	ld	a4,0(a5)
 6f8:	00e7e463          	bltu	a5,a4,700 <free+0x3a>
 6fc:	00e6ea63          	bltu	a3,a4,710 <free+0x4a>
{
 700:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 702:	fed7fae3          	bgeu	a5,a3,6f6 <free+0x30>
 706:	6398                	ld	a4,0(a5)
 708:	00e6e463          	bltu	a3,a4,710 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 70c:	fee7eae3          	bltu	a5,a4,700 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 710:	ff852583          	lw	a1,-8(a0)
 714:	6390                	ld	a2,0(a5)
 716:	02059813          	sll	a6,a1,0x20
 71a:	01c85713          	srl	a4,a6,0x1c
 71e:	9736                	add	a4,a4,a3
 720:	fae60de3          	beq	a2,a4,6da <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 724:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 728:	4790                	lw	a2,8(a5)
 72a:	02061593          	sll	a1,a2,0x20
 72e:	01c5d713          	srl	a4,a1,0x1c
 732:	973e                	add	a4,a4,a5
 734:	fae68ae3          	beq	a3,a4,6e8 <free+0x22>
    p->s.ptr = bp->s.ptr;
 738:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 73a:	00001717          	auipc	a4,0x1
 73e:	8cf73323          	sd	a5,-1850(a4) # 1000 <freep>
}
 742:	6422                	ld	s0,8(sp)
 744:	0141                	add	sp,sp,16
 746:	8082                	ret

0000000000000748 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 748:	7139                	add	sp,sp,-64
 74a:	fc06                	sd	ra,56(sp)
 74c:	f822                	sd	s0,48(sp)
 74e:	f426                	sd	s1,40(sp)
 750:	f04a                	sd	s2,32(sp)
 752:	ec4e                	sd	s3,24(sp)
 754:	e852                	sd	s4,16(sp)
 756:	e456                	sd	s5,8(sp)
 758:	e05a                	sd	s6,0(sp)
 75a:	0080                	add	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 75c:	02051493          	sll	s1,a0,0x20
 760:	9081                	srl	s1,s1,0x20
 762:	04bd                	add	s1,s1,15
 764:	8091                	srl	s1,s1,0x4
 766:	0014899b          	addw	s3,s1,1
 76a:	0485                	add	s1,s1,1
  if((prevp = freep) == 0){
 76c:	00001517          	auipc	a0,0x1
 770:	89453503          	ld	a0,-1900(a0) # 1000 <freep>
 774:	c515                	beqz	a0,7a0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 776:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 778:	4798                	lw	a4,8(a5)
 77a:	02977f63          	bgeu	a4,s1,7b8 <malloc+0x70>
  if(nu < 4096)
 77e:	8a4e                	mv	s4,s3
 780:	0009871b          	sext.w	a4,s3
 784:	6685                	lui	a3,0x1
 786:	00d77363          	bgeu	a4,a3,78c <malloc+0x44>
 78a:	6a05                	lui	s4,0x1
 78c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 790:	004a1a1b          	sllw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 794:	00001917          	auipc	s2,0x1
 798:	86c90913          	add	s2,s2,-1940 # 1000 <freep>
  if(p == (char*)-1)
 79c:	5afd                	li	s5,-1
 79e:	a895                	j	812 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7a0:	00001797          	auipc	a5,0x1
 7a4:	87078793          	add	a5,a5,-1936 # 1010 <base>
 7a8:	00001717          	auipc	a4,0x1
 7ac:	84f73c23          	sd	a5,-1960(a4) # 1000 <freep>
 7b0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7b2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7b6:	b7e1                	j	77e <malloc+0x36>
      if(p->s.size == nunits)
 7b8:	02e48c63          	beq	s1,a4,7f0 <malloc+0xa8>
        p->s.size -= nunits;
 7bc:	4137073b          	subw	a4,a4,s3
 7c0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7c2:	02071693          	sll	a3,a4,0x20
 7c6:	01c6d713          	srl	a4,a3,0x1c
 7ca:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7cc:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7d0:	00001717          	auipc	a4,0x1
 7d4:	82a73823          	sd	a0,-2000(a4) # 1000 <freep>
      return (void*)(p + 1);
 7d8:	01078513          	add	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7dc:	70e2                	ld	ra,56(sp)
 7de:	7442                	ld	s0,48(sp)
 7e0:	74a2                	ld	s1,40(sp)
 7e2:	7902                	ld	s2,32(sp)
 7e4:	69e2                	ld	s3,24(sp)
 7e6:	6a42                	ld	s4,16(sp)
 7e8:	6aa2                	ld	s5,8(sp)
 7ea:	6b02                	ld	s6,0(sp)
 7ec:	6121                	add	sp,sp,64
 7ee:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7f0:	6398                	ld	a4,0(a5)
 7f2:	e118                	sd	a4,0(a0)
 7f4:	bff1                	j	7d0 <malloc+0x88>
  hp->s.size = nu;
 7f6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7fa:	0541                	add	a0,a0,16
 7fc:	00000097          	auipc	ra,0x0
 800:	eca080e7          	jalr	-310(ra) # 6c6 <free>
  return freep;
 804:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 808:	d971                	beqz	a0,7dc <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 80a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 80c:	4798                	lw	a4,8(a5)
 80e:	fa9775e3          	bgeu	a4,s1,7b8 <malloc+0x70>
    if(p == freep)
 812:	00093703          	ld	a4,0(s2)
 816:	853e                	mv	a0,a5
 818:	fef719e3          	bne	a4,a5,80a <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 81c:	8552                	mv	a0,s4
 81e:	00000097          	auipc	ra,0x0
 822:	b7a080e7          	jalr	-1158(ra) # 398 <sbrk>
  if(p == (char*)-1)
 826:	fd5518e3          	bne	a0,s5,7f6 <malloc+0xae>
        return 0;
 82a:	4501                	li	a0,0
 82c:	bf45                	j	7dc <malloc+0x94>
