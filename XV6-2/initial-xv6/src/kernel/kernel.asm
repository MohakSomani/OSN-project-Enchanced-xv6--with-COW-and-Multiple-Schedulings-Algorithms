
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	add	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	add	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	add	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	add	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	sllw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	add	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	sll	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	sll	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8a070713          	add	a4,a4,-1888 # 800088f0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	04e78793          	add	a5,a5,78 # 800060b0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	or	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	or	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	add	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	add	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	add	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	add	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc487>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	add	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e4478793          	add	a5,a5,-444 # 80000ef0 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	add	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	or	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srl	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	add	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	add	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	add	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	add	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	50c080e7          	jalr	1292(ra) # 80002636 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	780080e7          	jalr	1920(ra) # 800008ba <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addw	s2,s2,1
    80000144:	0485                	add	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	add	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	add	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	add	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000180:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	8ac50513          	add	a0,a0,-1876 # 80010a30 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	ac4080e7          	jalr	-1340(ra) # 80000c50 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000194:	00011497          	auipc	s1,0x11
    80000198:	89c48493          	add	s1,s1,-1892 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	92c90913          	add	s2,s2,-1748 # 80010ac8 <cons+0x98>
  while(n > 0){
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
      if(killed(myproc())){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	94c080e7          	jalr	-1716(ra) # 80001b00 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	2c4080e7          	jalr	708(ra) # 80002480 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	002080e7          	jalr	2(ra) # 800021cc <sleep>
    while(cons.r == cons.w){
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	85270713          	add	a4,a4,-1966 # 80010a30 <cons>
    800001e6:	0017869b          	addw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	and	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	add	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	3d0080e7          	jalr	976(ra) # 800025e0 <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
      break;

    dst++;
    8000021e:	0a05                	add	s4,s4,1
    --n;
    80000220:	39fd                	addw	s3,s3,-1

    if(c == '\n'){
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	80850513          	add	a0,a0,-2040 # 80010a30 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	ad4080e7          	jalr	-1324(ra) # 80000d04 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
        release(&cons.lock);
    8000023e:	00010517          	auipc	a0,0x10
    80000242:	7f250513          	add	a0,a0,2034 # 80010a30 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	abe080e7          	jalr	-1346(ra) # 80000d04 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	add	sp,sp,96
    80000264:	8082                	ret
      if(n < target){
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
        cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	84f72d23          	sw	a5,-1958(a4) # 80010ac8 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	add	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	add	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
    uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	560080e7          	jalr	1376(ra) # 800007e8 <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	add	sp,sp,16
    80000296:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	54e080e7          	jalr	1358(ra) # 800007e8 <uartputc_sync>
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	542080e7          	jalr	1346(ra) # 800007e8 <uartputc_sync>
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	538080e7          	jalr	1336(ra) # 800007e8 <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ba:	1101                	add	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	add	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c8:	00010517          	auipc	a0,0x10
    800002cc:	76850513          	add	a0,a0,1896 # 80010a30 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	980080e7          	jalr	-1664(ra) # 80000c50 <acquire>

  switch(c){
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	39e080e7          	jalr	926(ra) # 8000268c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f6:	00010517          	auipc	a0,0x10
    800002fa:	73a50513          	add	a0,a0,1850 # 80010a30 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	a06080e7          	jalr	-1530(ra) # 80000d04 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	add	sp,sp,32
    80000310:	8082                	ret
  switch(c){
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031a:	00010717          	auipc	a4,0x10
    8000031e:	71670713          	add	a4,a4,1814 # 80010a30 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
      consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00010797          	auipc	a5,0x10
    80000348:	6ec78793          	add	a5,a5,1772 # 80010a30 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	and	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00010797          	auipc	a5,0x10
    80000376:	7567a783          	lw	a5,1878(a5) # 80010ac8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000386:	00010717          	auipc	a4,0x10
    8000038a:	6aa70713          	add	a4,a4,1706 # 80010a30 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	69a48493          	add	s1,s1,1690 # 80010a30 <cons>
    while(cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a4:	37fd                	addw	a5,a5,-1
    800003a6:	07f7f713          	and	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
    while(cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	65e70713          	add	a4,a4,1630 # 80010a30 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
      cons.e--;
    800003e6:	37fd                	addw	a5,a5,-1
    800003e8:	00010717          	auipc	a4,0x10
    800003ec:	6ef72423          	sw	a5,1768(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
      consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	62278793          	add	a5,a5,1570 # 80010a30 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	and	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	68c7ad23          	sw	a2,1690(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	68e50513          	add	a0,a0,1678 # 80010ac8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	dee080e7          	jalr	-530(ra) # 80002230 <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void
consoleinit(void)
{
    8000044c:	1141                	add	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	add	s0,sp,16
  initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bbc58593          	add	a1,a1,-1092 # 80008010 <etext+0x10>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	5d450513          	add	a0,a0,1492 # 80010a30 <cons>
    80000464:	00000097          	auipc	ra,0x0
    80000468:	75c080e7          	jalr	1884(ra) # 80000bc0 <initlock>

  uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	32c080e7          	jalr	812(ra) # 80000798 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	d6c78793          	add	a5,a5,-660 # 802411e0 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	add	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	add	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	add	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	add	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	add	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	add	a3,s0,-48

  i = 0;
    800004b2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b8a60613          	add	a2,a2,-1142 # 80008040 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	sll	a5,a5,0x20
    800004c8:	9381                	srl	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	add	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

  if(sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
    buf[i++] = '-';
    800004e6:	fe070793          	add	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	add	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	add	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addw	a4,a4,-1
    8000050e:	1702                	sll	a4,a4,0x20
    80000510:	9301                	srl	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
  while(--i >= 0)
    80000522:	14fd                	add	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	add	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	add	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	add	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00010797          	auipc	a5,0x10
    8000054c:	5a07a423          	sw	zero,1448(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	add	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b5e50513          	add	a0,a0,-1186 # 800080c8 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00008717          	auipc	a4,0x8
    80000580:	32f72a23          	sw	a5,820(a4) # 800088b0 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	add	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	add	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00010d97          	auipc	s11,0x10
    800005bc:	538dad83          	lw	s11,1336(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	add	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	14050f63          	beqz	a0,80000732 <printf+0x1ac>
    800005d8:	4981                	li	s3,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b93          	li	s7,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b17          	auipc	s6,0x8
    800005e8:	a5cb0b13          	add	s6,s6,-1444 # 80008040 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00010517          	auipc	a0,0x10
    800005fa:	4e250513          	add	a0,a0,1250 # 80010ad8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	652080e7          	jalr	1618(ra) # 80000c50 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	add	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c60080e7          	jalr	-928(ra) # 80000278 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2985                	addw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050463          	beqz	a0,80000732 <printf+0x1ac>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2985                	addw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000640:	cbed                	beqz	a5,80000732 <printf+0x1ac>
    switch(c){
    80000642:	05778a63          	beq	a5,s7,80000696 <printf+0x110>
    80000646:	02fbf663          	bgeu	s7,a5,80000672 <printf+0xec>
    8000064a:	09978863          	beq	a5,s9,800006da <printf+0x154>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79563          	bne	a5,a4,8000071c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	add	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e30080e7          	jalr	-464(ra) # 80000498 <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	09578f63          	beq	a5,s5,80000710 <printf+0x18a>
    80000676:	0b879363          	bne	a5,s8,8000071c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	add	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0c080e7          	jalr	-500(ra) # 80000498 <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	add	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bce080e7          	jalr	-1074(ra) # 80000278 <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc2080e7          	jalr	-1086(ra) # 80000278 <consputc>
    800006be:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c95793          	srl	a5,s2,0x3c
    800006c4:	97da                	add	a5,a5,s6
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bae080e7          	jalr	-1106(ra) # 80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0912                	sll	s2,s2,0x4
    800006d4:	34fd                	addw	s1,s1,-1
    800006d6:	f4ed                	bnez	s1,800006c0 <printf+0x13a>
    800006d8:	b7a1                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006da:	f8843783          	ld	a5,-120(s0)
    800006de:	00878713          	add	a4,a5,8
    800006e2:	f8e43423          	sd	a4,-120(s0)
    800006e6:	6384                	ld	s1,0(a5)
    800006e8:	cc89                	beqz	s1,80000702 <printf+0x17c>
      for(; *s; s++)
    800006ea:	0004c503          	lbu	a0,0(s1)
    800006ee:	d90d                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f0:	00000097          	auipc	ra,0x0
    800006f4:	b88080e7          	jalr	-1144(ra) # 80000278 <consputc>
      for(; *s; s++)
    800006f8:	0485                	add	s1,s1,1
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	f96d                	bnez	a0,800006f0 <printf+0x16a>
    80000700:	b705                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000702:	00008497          	auipc	s1,0x8
    80000706:	91e48493          	add	s1,s1,-1762 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070a:	02800513          	li	a0,40
    8000070e:	b7cd                	j	800006f0 <printf+0x16a>
      consputc('%');
    80000710:	8556                	mv	a0,s5
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b66080e7          	jalr	-1178(ra) # 80000278 <consputc>
      break;
    8000071a:	b719                	j	80000620 <printf+0x9a>
      consputc('%');
    8000071c:	8556                	mv	a0,s5
    8000071e:	00000097          	auipc	ra,0x0
    80000722:	b5a080e7          	jalr	-1190(ra) # 80000278 <consputc>
      consputc(c);
    80000726:	8526                	mv	a0,s1
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b50080e7          	jalr	-1200(ra) # 80000278 <consputc>
      break;
    80000730:	bdc5                	j	80000620 <printf+0x9a>
  if(locking)
    80000732:	020d9163          	bnez	s11,80000754 <printf+0x1ce>
}
    80000736:	70e6                	ld	ra,120(sp)
    80000738:	7446                	ld	s0,112(sp)
    8000073a:	74a6                	ld	s1,104(sp)
    8000073c:	7906                	ld	s2,96(sp)
    8000073e:	69e6                	ld	s3,88(sp)
    80000740:	6a46                	ld	s4,80(sp)
    80000742:	6aa6                	ld	s5,72(sp)
    80000744:	6b06                	ld	s6,64(sp)
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	7c42                	ld	s8,48(sp)
    8000074a:	7ca2                	ld	s9,40(sp)
    8000074c:	7d02                	ld	s10,32(sp)
    8000074e:	6de2                	ld	s11,24(sp)
    80000750:	6129                	add	sp,sp,192
    80000752:	8082                	ret
    release(&pr.lock);
    80000754:	00010517          	auipc	a0,0x10
    80000758:	38450513          	add	a0,a0,900 # 80010ad8 <pr>
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	5a8080e7          	jalr	1448(ra) # 80000d04 <release>
}
    80000764:	bfc9                	j	80000736 <printf+0x1b0>

0000000080000766 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000766:	1101                	add	sp,sp,-32
    80000768:	ec06                	sd	ra,24(sp)
    8000076a:	e822                	sd	s0,16(sp)
    8000076c:	e426                	sd	s1,8(sp)
    8000076e:	1000                	add	s0,sp,32
  initlock(&pr.lock, "pr");
    80000770:	00010497          	auipc	s1,0x10
    80000774:	36848493          	add	s1,s1,872 # 80010ad8 <pr>
    80000778:	00008597          	auipc	a1,0x8
    8000077c:	8c058593          	add	a1,a1,-1856 # 80008038 <etext+0x38>
    80000780:	8526                	mv	a0,s1
    80000782:	00000097          	auipc	ra,0x0
    80000786:	43e080e7          	jalr	1086(ra) # 80000bc0 <initlock>
  pr.locking = 1;
    8000078a:	4785                	li	a5,1
    8000078c:	cc9c                	sw	a5,24(s1)
}
    8000078e:	60e2                	ld	ra,24(sp)
    80000790:	6442                	ld	s0,16(sp)
    80000792:	64a2                	ld	s1,8(sp)
    80000794:	6105                	add	sp,sp,32
    80000796:	8082                	ret

0000000080000798 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000798:	1141                	add	sp,sp,-16
    8000079a:	e406                	sd	ra,8(sp)
    8000079c:	e022                	sd	s0,0(sp)
    8000079e:	0800                	add	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a0:	100007b7          	lui	a5,0x10000
    800007a4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a8:	f8000713          	li	a4,-128
    800007ac:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b0:	470d                	li	a4,3
    800007b2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ba:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007be:	469d                	li	a3,7
    800007c0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c8:	00008597          	auipc	a1,0x8
    800007cc:	89058593          	add	a1,a1,-1904 # 80008058 <digits+0x18>
    800007d0:	00010517          	auipc	a0,0x10
    800007d4:	32850513          	add	a0,a0,808 # 80010af8 <uart_tx_lock>
    800007d8:	00000097          	auipc	ra,0x0
    800007dc:	3e8080e7          	jalr	1000(ra) # 80000bc0 <initlock>
}
    800007e0:	60a2                	ld	ra,8(sp)
    800007e2:	6402                	ld	s0,0(sp)
    800007e4:	0141                	add	sp,sp,16
    800007e6:	8082                	ret

00000000800007e8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e8:	1101                	add	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	add	s0,sp,32
    800007f2:	84aa                	mv	s1,a0
  push_off();
    800007f4:	00000097          	auipc	ra,0x0
    800007f8:	410080e7          	jalr	1040(ra) # 80000c04 <push_off>

  if(panicked){
    800007fc:	00008797          	auipc	a5,0x8
    80000800:	0b47a783          	lw	a5,180(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000804:	10000737          	lui	a4,0x10000
  if(panicked){
    80000808:	c391                	beqz	a5,8000080c <uartputc_sync+0x24>
    for(;;)
    8000080a:	a001                	j	8000080a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000810:	0207f793          	and	a5,a5,32
    80000814:	dfe5                	beqz	a5,8000080c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000816:	0ff4f513          	zext.b	a0,s1
    8000081a:	100007b7          	lui	a5,0x10000
    8000081e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000822:	00000097          	auipc	ra,0x0
    80000826:	482080e7          	jalr	1154(ra) # 80000ca4 <pop_off>
}
    8000082a:	60e2                	ld	ra,24(sp)
    8000082c:	6442                	ld	s0,16(sp)
    8000082e:	64a2                	ld	s1,8(sp)
    80000830:	6105                	add	sp,sp,32
    80000832:	8082                	ret

0000000080000834 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000834:	00008797          	auipc	a5,0x8
    80000838:	0847b783          	ld	a5,132(a5) # 800088b8 <uart_tx_r>
    8000083c:	00008717          	auipc	a4,0x8
    80000840:	08473703          	ld	a4,132(a4) # 800088c0 <uart_tx_w>
    80000844:	06f70a63          	beq	a4,a5,800008b8 <uartstart+0x84>
{
    80000848:	7139                	add	sp,sp,-64
    8000084a:	fc06                	sd	ra,56(sp)
    8000084c:	f822                	sd	s0,48(sp)
    8000084e:	f426                	sd	s1,40(sp)
    80000850:	f04a                	sd	s2,32(sp)
    80000852:	ec4e                	sd	s3,24(sp)
    80000854:	e852                	sd	s4,16(sp)
    80000856:	e456                	sd	s5,8(sp)
    80000858:	0080                	add	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085e:	00010a17          	auipc	s4,0x10
    80000862:	29aa0a13          	add	s4,s4,666 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000866:	00008497          	auipc	s1,0x8
    8000086a:	05248493          	add	s1,s1,82 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086e:	00008997          	auipc	s3,0x8
    80000872:	05298993          	add	s3,s3,82 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087a:	02077713          	and	a4,a4,32
    8000087e:	c705                	beqz	a4,800008a6 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000880:	01f7f713          	and	a4,a5,31
    80000884:	9752                	add	a4,a4,s4
    80000886:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088a:	0785                	add	a5,a5,1
    8000088c:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000088e:	8526                	mv	a0,s1
    80000890:	00002097          	auipc	ra,0x2
    80000894:	9a0080e7          	jalr	-1632(ra) # 80002230 <wakeup>
    
    WriteReg(THR, c);
    80000898:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089c:	609c                	ld	a5,0(s1)
    8000089e:	0009b703          	ld	a4,0(s3)
    800008a2:	fcf71ae3          	bne	a4,a5,80000876 <uartstart+0x42>
  }
}
    800008a6:	70e2                	ld	ra,56(sp)
    800008a8:	7442                	ld	s0,48(sp)
    800008aa:	74a2                	ld	s1,40(sp)
    800008ac:	7902                	ld	s2,32(sp)
    800008ae:	69e2                	ld	s3,24(sp)
    800008b0:	6a42                	ld	s4,16(sp)
    800008b2:	6aa2                	ld	s5,8(sp)
    800008b4:	6121                	add	sp,sp,64
    800008b6:	8082                	ret
    800008b8:	8082                	ret

00000000800008ba <uartputc>:
{
    800008ba:	7179                	add	sp,sp,-48
    800008bc:	f406                	sd	ra,40(sp)
    800008be:	f022                	sd	s0,32(sp)
    800008c0:	ec26                	sd	s1,24(sp)
    800008c2:	e84a                	sd	s2,16(sp)
    800008c4:	e44e                	sd	s3,8(sp)
    800008c6:	e052                	sd	s4,0(sp)
    800008c8:	1800                	add	s0,sp,48
    800008ca:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008cc:	00010517          	auipc	a0,0x10
    800008d0:	22c50513          	add	a0,a0,556 # 80010af8 <uart_tx_lock>
    800008d4:	00000097          	auipc	ra,0x0
    800008d8:	37c080e7          	jalr	892(ra) # 80000c50 <acquire>
  if(panicked){
    800008dc:	00008797          	auipc	a5,0x8
    800008e0:	fd47a783          	lw	a5,-44(a5) # 800088b0 <panicked>
    800008e4:	e7c9                	bnez	a5,8000096e <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e6:	00008717          	auipc	a4,0x8
    800008ea:	fda73703          	ld	a4,-38(a4) # 800088c0 <uart_tx_w>
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	fca7b783          	ld	a5,-54(a5) # 800088b8 <uart_tx_r>
    800008f6:	02078793          	add	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fa:	00010997          	auipc	s3,0x10
    800008fe:	1fe98993          	add	s3,s3,510 # 80010af8 <uart_tx_lock>
    80000902:	00008497          	auipc	s1,0x8
    80000906:	fb648493          	add	s1,s1,-74 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090a:	00008917          	auipc	s2,0x8
    8000090e:	fb690913          	add	s2,s2,-74 # 800088c0 <uart_tx_w>
    80000912:	00e79f63          	bne	a5,a4,80000930 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000916:	85ce                	mv	a1,s3
    80000918:	8526                	mv	a0,s1
    8000091a:	00002097          	auipc	ra,0x2
    8000091e:	8b2080e7          	jalr	-1870(ra) # 800021cc <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00093703          	ld	a4,0(s2)
    80000926:	609c                	ld	a5,0(s1)
    80000928:	02078793          	add	a5,a5,32
    8000092c:	fee785e3          	beq	a5,a4,80000916 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000930:	00010497          	auipc	s1,0x10
    80000934:	1c848493          	add	s1,s1,456 # 80010af8 <uart_tx_lock>
    80000938:	01f77793          	and	a5,a4,31
    8000093c:	97a6                	add	a5,a5,s1
    8000093e:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000942:	0705                	add	a4,a4,1
    80000944:	00008797          	auipc	a5,0x8
    80000948:	f6e7be23          	sd	a4,-132(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094c:	00000097          	auipc	ra,0x0
    80000950:	ee8080e7          	jalr	-280(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    80000954:	8526                	mv	a0,s1
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	3ae080e7          	jalr	942(ra) # 80000d04 <release>
}
    8000095e:	70a2                	ld	ra,40(sp)
    80000960:	7402                	ld	s0,32(sp)
    80000962:	64e2                	ld	s1,24(sp)
    80000964:	6942                	ld	s2,16(sp)
    80000966:	69a2                	ld	s3,8(sp)
    80000968:	6a02                	ld	s4,0(sp)
    8000096a:	6145                	add	sp,sp,48
    8000096c:	8082                	ret
    for(;;)
    8000096e:	a001                	j	8000096e <uartputc+0xb4>

0000000080000970 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000970:	1141                	add	sp,sp,-16
    80000972:	e422                	sd	s0,8(sp)
    80000974:	0800                	add	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000976:	100007b7          	lui	a5,0x10000
    8000097a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000097e:	8b85                	and	a5,a5,1
    80000980:	cb81                	beqz	a5,80000990 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000982:	100007b7          	lui	a5,0x10000
    80000986:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098a:	6422                	ld	s0,8(sp)
    8000098c:	0141                	add	sp,sp,16
    8000098e:	8082                	ret
    return -1;
    80000990:	557d                	li	a0,-1
    80000992:	bfe5                	j	8000098a <uartgetc+0x1a>

0000000080000994 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000994:	1101                	add	sp,sp,-32
    80000996:	ec06                	sd	ra,24(sp)
    80000998:	e822                	sd	s0,16(sp)
    8000099a:	e426                	sd	s1,8(sp)
    8000099c:	1000                	add	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    8000099e:	54fd                	li	s1,-1
    800009a0:	a029                	j	800009aa <uartintr+0x16>
      break;
    consoleintr(c);
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	918080e7          	jalr	-1768(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009aa:	00000097          	auipc	ra,0x0
    800009ae:	fc6080e7          	jalr	-58(ra) # 80000970 <uartgetc>
    if(c == -1)
    800009b2:	fe9518e3          	bne	a0,s1,800009a2 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009b6:	00010497          	auipc	s1,0x10
    800009ba:	14248493          	add	s1,s1,322 # 80010af8 <uart_tx_lock>
    800009be:	8526                	mv	a0,s1
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	290080e7          	jalr	656(ra) # 80000c50 <acquire>
  uartstart();
    800009c8:	00000097          	auipc	ra,0x0
    800009cc:	e6c080e7          	jalr	-404(ra) # 80000834 <uartstart>
  release(&uart_tx_lock);
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	332080e7          	jalr	818(ra) # 80000d04 <release>
}
    800009da:	60e2                	ld	ra,24(sp)
    800009dc:	6442                	ld	s0,16(sp)
    800009de:	64a2                	ld	s1,8(sp)
    800009e0:	6105                	add	sp,sp,32
    800009e2:	8082                	ret

00000000800009e4 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e4:	7179                	add	sp,sp,-48
    800009e6:	f406                	sd	ra,40(sp)
    800009e8:	f022                	sd	s0,32(sp)
    800009ea:	ec26                	sd	s1,24(sp)
    800009ec:	e84a                	sd	s2,16(sp)
    800009ee:	e44e                	sd	s3,8(sp)
    800009f0:	1800                	add	s0,sp,48
  struct run *r;
  int temp;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f2:	03451793          	sll	a5,a0,0x34
    800009f6:	e3a5                	bnez	a5,80000a56 <kfree+0x72>
    800009f8:	84aa                	mv	s1,a0
    800009fa:	00242797          	auipc	a5,0x242
    800009fe:	97e78793          	add	a5,a5,-1666 # 80242378 <end>
    80000a02:	04f56a63          	bltu	a0,a5,80000a56 <kfree+0x72>
    80000a06:	47c5                	li	a5,17
    80000a08:	07ee                	sll	a5,a5,0x1b
    80000a0a:	04f57663          	bgeu	a0,a5,80000a56 <kfree+0x72>
    panic("kfree");

  acquire(&ref_count_lock);
    80000a0e:	00010917          	auipc	s2,0x10
    80000a12:	12290913          	add	s2,s2,290 # 80010b30 <ref_count_lock>
    80000a16:	854a                	mv	a0,s2
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	238080e7          	jalr	568(ra) # 80000c50 <acquire>
  // decrease the reference count, if use reference is not zero, then return
  useReference[(uint64)pa/PGSIZE] -= 1;
    80000a20:	00c4d713          	srl	a4,s1,0xc
    80000a24:	070a                	sll	a4,a4,0x2
    80000a26:	00010797          	auipc	a5,0x10
    80000a2a:	14278793          	add	a5,a5,322 # 80010b68 <useReference>
    80000a2e:	97ba                	add	a5,a5,a4
    80000a30:	4398                	lw	a4,0(a5)
    80000a32:	377d                	addw	a4,a4,-1
    80000a34:	0007099b          	sext.w	s3,a4
    80000a38:	c398                	sw	a4,0(a5)
  temp = useReference[(uint64)pa/PGSIZE];
  release(&ref_count_lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2c8080e7          	jalr	712(ra) # 80000d04 <release>
  if (temp > 0)
    80000a44:	03305163          	blez	s3,80000a66 <kfree+0x82>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a48:	70a2                	ld	ra,40(sp)
    80000a4a:	7402                	ld	s0,32(sp)
    80000a4c:	64e2                	ld	s1,24(sp)
    80000a4e:	6942                	ld	s2,16(sp)
    80000a50:	69a2                	ld	s3,8(sp)
    80000a52:	6145                	add	sp,sp,48
    80000a54:	8082                	ret
    panic("kfree");
    80000a56:	00007517          	auipc	a0,0x7
    80000a5a:	60a50513          	add	a0,a0,1546 # 80008060 <digits+0x20>
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	ade080e7          	jalr	-1314(ra) # 8000053c <panic>
  memset(pa, 1, PGSIZE);
    80000a66:	6605                	lui	a2,0x1
    80000a68:	4585                	li	a1,1
    80000a6a:	8526                	mv	a0,s1
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	2e0080e7          	jalr	736(ra) # 80000d4c <memset>
  acquire(&kmem.lock);
    80000a74:	89ca                	mv	s3,s2
    80000a76:	00010917          	auipc	s2,0x10
    80000a7a:	0d290913          	add	s2,s2,210 # 80010b48 <kmem>
    80000a7e:	854a                	mv	a0,s2
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	1d0080e7          	jalr	464(ra) # 80000c50 <acquire>
  r->next = kmem.freelist;
    80000a88:	0309b783          	ld	a5,48(s3)
    80000a8c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a8e:	0299b823          	sd	s1,48(s3)
  release(&kmem.lock);
    80000a92:	854a                	mv	a0,s2
    80000a94:	00000097          	auipc	ra,0x0
    80000a98:	270080e7          	jalr	624(ra) # 80000d04 <release>
    80000a9c:	b775                	j	80000a48 <kfree+0x64>

0000000080000a9e <freerange>:
{
    80000a9e:	7179                	add	sp,sp,-48
    80000aa0:	f406                	sd	ra,40(sp)
    80000aa2:	f022                	sd	s0,32(sp)
    80000aa4:	ec26                	sd	s1,24(sp)
    80000aa6:	e84a                	sd	s2,16(sp)
    80000aa8:	e44e                	sd	s3,8(sp)
    80000aaa:	e052                	sd	s4,0(sp)
    80000aac:	1800                	add	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aae:	6785                	lui	a5,0x1
    80000ab0:	fff78713          	add	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ab4:	00e504b3          	add	s1,a0,a4
    80000ab8:	777d                	lui	a4,0xfffff
    80000aba:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94be                	add	s1,s1,a5
    80000abe:	0095ee63          	bltu	a1,s1,80000ada <freerange+0x3c>
    80000ac2:	892e                	mv	s2,a1
    kfree(p);
    80000ac4:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac6:	6985                	lui	s3,0x1
    kfree(p);
    80000ac8:	01448533          	add	a0,s1,s4
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	f18080e7          	jalr	-232(ra) # 800009e4 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad4:	94ce                	add	s1,s1,s3
    80000ad6:	fe9979e3          	bgeu	s2,s1,80000ac8 <freerange+0x2a>
}
    80000ada:	70a2                	ld	ra,40(sp)
    80000adc:	7402                	ld	s0,32(sp)
    80000ade:	64e2                	ld	s1,24(sp)
    80000ae0:	6942                	ld	s2,16(sp)
    80000ae2:	69a2                	ld	s3,8(sp)
    80000ae4:	6a02                	ld	s4,0(sp)
    80000ae6:	6145                	add	sp,sp,48
    80000ae8:	8082                	ret

0000000080000aea <kinit>:
{
    80000aea:	1141                	add	sp,sp,-16
    80000aec:	e406                	sd	ra,8(sp)
    80000aee:	e022                	sd	s0,0(sp)
    80000af0:	0800                	add	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000af2:	00007597          	auipc	a1,0x7
    80000af6:	57658593          	add	a1,a1,1398 # 80008068 <digits+0x28>
    80000afa:	00010517          	auipc	a0,0x10
    80000afe:	04e50513          	add	a0,a0,78 # 80010b48 <kmem>
    80000b02:	00000097          	auipc	ra,0x0
    80000b06:	0be080e7          	jalr	190(ra) # 80000bc0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b0a:	45c5                	li	a1,17
    80000b0c:	05ee                	sll	a1,a1,0x1b
    80000b0e:	00242517          	auipc	a0,0x242
    80000b12:	86a50513          	add	a0,a0,-1942 # 80242378 <end>
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	f88080e7          	jalr	-120(ra) # 80000a9e <freerange>
}
    80000b1e:	60a2                	ld	ra,8(sp)
    80000b20:	6402                	ld	s0,0(sp)
    80000b22:	0141                	add	sp,sp,16
    80000b24:	8082                	ret

0000000080000b26 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b26:	1101                	add	sp,sp,-32
    80000b28:	ec06                	sd	ra,24(sp)
    80000b2a:	e822                	sd	s0,16(sp)
    80000b2c:	e426                	sd	s1,8(sp)
    80000b2e:	e04a                	sd	s2,0(sp)
    80000b30:	1000                	add	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b32:	00010517          	auipc	a0,0x10
    80000b36:	01650513          	add	a0,a0,22 # 80010b48 <kmem>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	116080e7          	jalr	278(ra) # 80000c50 <acquire>
  r = kmem.freelist;
    80000b42:	00010497          	auipc	s1,0x10
    80000b46:	01e4b483          	ld	s1,30(s1) # 80010b60 <kmem+0x18>
  if(r) {
    80000b4a:	c0b5                	beqz	s1,80000bae <kalloc+0x88>
    kmem.freelist = r->next;
    80000b4c:	609c                	ld	a5,0(s1)
    80000b4e:	00010917          	auipc	s2,0x10
    80000b52:	fe290913          	add	s2,s2,-30 # 80010b30 <ref_count_lock>
    80000b56:	02f93823          	sd	a5,48(s2)
    acquire(&ref_count_lock);
    80000b5a:	854a                	mv	a0,s2
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0f4080e7          	jalr	244(ra) # 80000c50 <acquire>
    // initialization the ref count to 1
    useReference[(uint64)r / PGSIZE] = 1;
    80000b64:	00c4d713          	srl	a4,s1,0xc
    80000b68:	070a                	sll	a4,a4,0x2
    80000b6a:	00010797          	auipc	a5,0x10
    80000b6e:	ffe78793          	add	a5,a5,-2 # 80010b68 <useReference>
    80000b72:	97ba                	add	a5,a5,a4
    80000b74:	4705                	li	a4,1
    80000b76:	c398                	sw	a4,0(a5)
    release(&ref_count_lock);
    80000b78:	854a                	mv	a0,s2
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	18a080e7          	jalr	394(ra) # 80000d04 <release>
  }
  release(&kmem.lock);
    80000b82:	00010517          	auipc	a0,0x10
    80000b86:	fc650513          	add	a0,a0,-58 # 80010b48 <kmem>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	17a080e7          	jalr	378(ra) # 80000d04 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b92:	6605                	lui	a2,0x1
    80000b94:	4595                	li	a1,5
    80000b96:	8526                	mv	a0,s1
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	1b4080e7          	jalr	436(ra) # 80000d4c <memset>
  return (void*)r;
    80000ba0:	8526                	mv	a0,s1
    80000ba2:	60e2                	ld	ra,24(sp)
    80000ba4:	6442                	ld	s0,16(sp)
    80000ba6:	64a2                	ld	s1,8(sp)
    80000ba8:	6902                	ld	s2,0(sp)
    80000baa:	6105                	add	sp,sp,32
    80000bac:	8082                	ret
  release(&kmem.lock);
    80000bae:	00010517          	auipc	a0,0x10
    80000bb2:	f9a50513          	add	a0,a0,-102 # 80010b48 <kmem>
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	14e080e7          	jalr	334(ra) # 80000d04 <release>
  if(r)
    80000bbe:	b7cd                	j	80000ba0 <kalloc+0x7a>

0000000080000bc0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bc0:	1141                	add	sp,sp,-16
    80000bc2:	e422                	sd	s0,8(sp)
    80000bc4:	0800                	add	s0,sp,16
  lk->name = name;
    80000bc6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bcc:	00053823          	sd	zero,16(a0)
}
    80000bd0:	6422                	ld	s0,8(sp)
    80000bd2:	0141                	add	sp,sp,16
    80000bd4:	8082                	ret

0000000080000bd6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bd6:	411c                	lw	a5,0(a0)
    80000bd8:	e399                	bnez	a5,80000bde <holding+0x8>
    80000bda:	4501                	li	a0,0
  return r;
}
    80000bdc:	8082                	ret
{
    80000bde:	1101                	add	sp,sp,-32
    80000be0:	ec06                	sd	ra,24(sp)
    80000be2:	e822                	sd	s0,16(sp)
    80000be4:	e426                	sd	s1,8(sp)
    80000be6:	1000                	add	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be8:	6904                	ld	s1,16(a0)
    80000bea:	00001097          	auipc	ra,0x1
    80000bee:	efa080e7          	jalr	-262(ra) # 80001ae4 <mycpu>
    80000bf2:	40a48533          	sub	a0,s1,a0
    80000bf6:	00153513          	seqz	a0,a0
}
    80000bfa:	60e2                	ld	ra,24(sp)
    80000bfc:	6442                	ld	s0,16(sp)
    80000bfe:	64a2                	ld	s1,8(sp)
    80000c00:	6105                	add	sp,sp,32
    80000c02:	8082                	ret

0000000080000c04 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c04:	1101                	add	sp,sp,-32
    80000c06:	ec06                	sd	ra,24(sp)
    80000c08:	e822                	sd	s0,16(sp)
    80000c0a:	e426                	sd	s1,8(sp)
    80000c0c:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c0e:	100024f3          	csrr	s1,sstatus
    80000c12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c16:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c18:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c1c:	00001097          	auipc	ra,0x1
    80000c20:	ec8080e7          	jalr	-312(ra) # 80001ae4 <mycpu>
    80000c24:	5d3c                	lw	a5,120(a0)
    80000c26:	cf89                	beqz	a5,80000c40 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	ebc080e7          	jalr	-324(ra) # 80001ae4 <mycpu>
    80000c30:	5d3c                	lw	a5,120(a0)
    80000c32:	2785                	addw	a5,a5,1
    80000c34:	dd3c                	sw	a5,120(a0)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	add	sp,sp,32
    80000c3e:	8082                	ret
    mycpu()->intena = old;
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ea4080e7          	jalr	-348(ra) # 80001ae4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c48:	8085                	srl	s1,s1,0x1
    80000c4a:	8885                	and	s1,s1,1
    80000c4c:	dd64                	sw	s1,124(a0)
    80000c4e:	bfe9                	j	80000c28 <push_off+0x24>

0000000080000c50 <acquire>:
{
    80000c50:	1101                	add	sp,sp,-32
    80000c52:	ec06                	sd	ra,24(sp)
    80000c54:	e822                	sd	s0,16(sp)
    80000c56:	e426                	sd	s1,8(sp)
    80000c58:	1000                	add	s0,sp,32
    80000c5a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	fa8080e7          	jalr	-88(ra) # 80000c04 <push_off>
  if(holding(lk))
    80000c64:	8526                	mv	a0,s1
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	f70080e7          	jalr	-144(ra) # 80000bd6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6e:	4705                	li	a4,1
  if(holding(lk))
    80000c70:	e115                	bnez	a0,80000c94 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c72:	87ba                	mv	a5,a4
    80000c74:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c78:	2781                	sext.w	a5,a5
    80000c7a:	ffe5                	bnez	a5,80000c72 <acquire+0x22>
  __sync_synchronize();
    80000c7c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c80:	00001097          	auipc	ra,0x1
    80000c84:	e64080e7          	jalr	-412(ra) # 80001ae4 <mycpu>
    80000c88:	e888                	sd	a0,16(s1)
}
    80000c8a:	60e2                	ld	ra,24(sp)
    80000c8c:	6442                	ld	s0,16(sp)
    80000c8e:	64a2                	ld	s1,8(sp)
    80000c90:	6105                	add	sp,sp,32
    80000c92:	8082                	ret
    panic("acquire");
    80000c94:	00007517          	auipc	a0,0x7
    80000c98:	3dc50513          	add	a0,a0,988 # 80008070 <digits+0x30>
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	8a0080e7          	jalr	-1888(ra) # 8000053c <panic>

0000000080000ca4 <pop_off>:

void
pop_off(void)
{
    80000ca4:	1141                	add	sp,sp,-16
    80000ca6:	e406                	sd	ra,8(sp)
    80000ca8:	e022                	sd	s0,0(sp)
    80000caa:	0800                	add	s0,sp,16
  struct cpu *c = mycpu();
    80000cac:	00001097          	auipc	ra,0x1
    80000cb0:	e38080e7          	jalr	-456(ra) # 80001ae4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb8:	8b89                	and	a5,a5,2
  if(intr_get())
    80000cba:	e78d                	bnez	a5,80000ce4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cbc:	5d3c                	lw	a5,120(a0)
    80000cbe:	02f05b63          	blez	a5,80000cf4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cc2:	37fd                	addw	a5,a5,-1
    80000cc4:	0007871b          	sext.w	a4,a5
    80000cc8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cca:	eb09                	bnez	a4,80000cdc <pop_off+0x38>
    80000ccc:	5d7c                	lw	a5,124(a0)
    80000cce:	c799                	beqz	a5,80000cdc <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cd4:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cdc:	60a2                	ld	ra,8(sp)
    80000cde:	6402                	ld	s0,0(sp)
    80000ce0:	0141                	add	sp,sp,16
    80000ce2:	8082                	ret
    panic("pop_off - interruptible");
    80000ce4:	00007517          	auipc	a0,0x7
    80000ce8:	39450513          	add	a0,a0,916 # 80008078 <digits+0x38>
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	850080e7          	jalr	-1968(ra) # 8000053c <panic>
    panic("pop_off");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	39c50513          	add	a0,a0,924 # 80008090 <digits+0x50>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	840080e7          	jalr	-1984(ra) # 8000053c <panic>

0000000080000d04 <release>:
{
    80000d04:	1101                	add	sp,sp,-32
    80000d06:	ec06                	sd	ra,24(sp)
    80000d08:	e822                	sd	s0,16(sp)
    80000d0a:	e426                	sd	s1,8(sp)
    80000d0c:	1000                	add	s0,sp,32
    80000d0e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d10:	00000097          	auipc	ra,0x0
    80000d14:	ec6080e7          	jalr	-314(ra) # 80000bd6 <holding>
    80000d18:	c115                	beqz	a0,80000d3c <release+0x38>
  lk->cpu = 0;
    80000d1a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d1e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d22:	0f50000f          	fence	iorw,ow
    80000d26:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	f7a080e7          	jalr	-134(ra) # 80000ca4 <pop_off>
}
    80000d32:	60e2                	ld	ra,24(sp)
    80000d34:	6442                	ld	s0,16(sp)
    80000d36:	64a2                	ld	s1,8(sp)
    80000d38:	6105                	add	sp,sp,32
    80000d3a:	8082                	ret
    panic("release");
    80000d3c:	00007517          	auipc	a0,0x7
    80000d40:	35c50513          	add	a0,a0,860 # 80008098 <digits+0x58>
    80000d44:	fffff097          	auipc	ra,0xfffff
    80000d48:	7f8080e7          	jalr	2040(ra) # 8000053c <panic>

0000000080000d4c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d4c:	1141                	add	sp,sp,-16
    80000d4e:	e422                	sd	s0,8(sp)
    80000d50:	0800                	add	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d52:	ca19                	beqz	a2,80000d68 <memset+0x1c>
    80000d54:	87aa                	mv	a5,a0
    80000d56:	1602                	sll	a2,a2,0x20
    80000d58:	9201                	srl	a2,a2,0x20
    80000d5a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d5e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d62:	0785                	add	a5,a5,1
    80000d64:	fee79de3          	bne	a5,a4,80000d5e <memset+0x12>
  }
  return dst;
}
    80000d68:	6422                	ld	s0,8(sp)
    80000d6a:	0141                	add	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d6e:	1141                	add	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	add	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d74:	ca05                	beqz	a2,80000da4 <memcmp+0x36>
    80000d76:	fff6069b          	addw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d7a:	1682                	sll	a3,a3,0x20
    80000d7c:	9281                	srl	a3,a3,0x20
    80000d7e:	0685                	add	a3,a3,1
    80000d80:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d82:	00054783          	lbu	a5,0(a0)
    80000d86:	0005c703          	lbu	a4,0(a1)
    80000d8a:	00e79863          	bne	a5,a4,80000d9a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d8e:	0505                	add	a0,a0,1
    80000d90:	0585                	add	a1,a1,1
  while(n-- > 0){
    80000d92:	fed518e3          	bne	a0,a3,80000d82 <memcmp+0x14>
  }

  return 0;
    80000d96:	4501                	li	a0,0
    80000d98:	a019                	j	80000d9e <memcmp+0x30>
      return *s1 - *s2;
    80000d9a:	40e7853b          	subw	a0,a5,a4
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	add	sp,sp,16
    80000da2:	8082                	ret
  return 0;
    80000da4:	4501                	li	a0,0
    80000da6:	bfe5                	j	80000d9e <memcmp+0x30>

0000000080000da8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da8:	1141                	add	sp,sp,-16
    80000daa:	e422                	sd	s0,8(sp)
    80000dac:	0800                	add	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dae:	c205                	beqz	a2,80000dce <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000db0:	02a5e263          	bltu	a1,a0,80000dd4 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000db4:	1602                	sll	a2,a2,0x20
    80000db6:	9201                	srl	a2,a2,0x20
    80000db8:	00c587b3          	add	a5,a1,a2
{
    80000dbc:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dbe:	0585                	add	a1,a1,1
    80000dc0:	0705                	add	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbcc89>
    80000dc2:	fff5c683          	lbu	a3,-1(a1)
    80000dc6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dca:	fef59ae3          	bne	a1,a5,80000dbe <memmove+0x16>

  return dst;
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	add	sp,sp,16
    80000dd2:	8082                	ret
  if(s < d && s + n > d){
    80000dd4:	02061693          	sll	a3,a2,0x20
    80000dd8:	9281                	srl	a3,a3,0x20
    80000dda:	00d58733          	add	a4,a1,a3
    80000dde:	fce57be3          	bgeu	a0,a4,80000db4 <memmove+0xc>
    d += n;
    80000de2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000de4:	fff6079b          	addw	a5,a2,-1
    80000de8:	1782                	sll	a5,a5,0x20
    80000dea:	9381                	srl	a5,a5,0x20
    80000dec:	fff7c793          	not	a5,a5
    80000df0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000df2:	177d                	add	a4,a4,-1
    80000df4:	16fd                	add	a3,a3,-1
    80000df6:	00074603          	lbu	a2,0(a4)
    80000dfa:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dfe:	fee79ae3          	bne	a5,a4,80000df2 <memmove+0x4a>
    80000e02:	b7f1                	j	80000dce <memmove+0x26>

0000000080000e04 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e04:	1141                	add	sp,sp,-16
    80000e06:	e406                	sd	ra,8(sp)
    80000e08:	e022                	sd	s0,0(sp)
    80000e0a:	0800                	add	s0,sp,16
  return memmove(dst, src, n);
    80000e0c:	00000097          	auipc	ra,0x0
    80000e10:	f9c080e7          	jalr	-100(ra) # 80000da8 <memmove>
}
    80000e14:	60a2                	ld	ra,8(sp)
    80000e16:	6402                	ld	s0,0(sp)
    80000e18:	0141                	add	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e1c:	1141                	add	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	add	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e22:	ce11                	beqz	a2,80000e3e <strncmp+0x22>
    80000e24:	00054783          	lbu	a5,0(a0)
    80000e28:	cf89                	beqz	a5,80000e42 <strncmp+0x26>
    80000e2a:	0005c703          	lbu	a4,0(a1)
    80000e2e:	00f71a63          	bne	a4,a5,80000e42 <strncmp+0x26>
    n--, p++, q++;
    80000e32:	367d                	addw	a2,a2,-1
    80000e34:	0505                	add	a0,a0,1
    80000e36:	0585                	add	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e38:	f675                	bnez	a2,80000e24 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e3a:	4501                	li	a0,0
    80000e3c:	a809                	j	80000e4e <strncmp+0x32>
    80000e3e:	4501                	li	a0,0
    80000e40:	a039                	j	80000e4e <strncmp+0x32>
  if(n == 0)
    80000e42:	ca09                	beqz	a2,80000e54 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e44:	00054503          	lbu	a0,0(a0)
    80000e48:	0005c783          	lbu	a5,0(a1)
    80000e4c:	9d1d                	subw	a0,a0,a5
}
    80000e4e:	6422                	ld	s0,8(sp)
    80000e50:	0141                	add	sp,sp,16
    80000e52:	8082                	ret
    return 0;
    80000e54:	4501                	li	a0,0
    80000e56:	bfe5                	j	80000e4e <strncmp+0x32>

0000000080000e58 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e58:	1141                	add	sp,sp,-16
    80000e5a:	e422                	sd	s0,8(sp)
    80000e5c:	0800                	add	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e5e:	87aa                	mv	a5,a0
    80000e60:	86b2                	mv	a3,a2
    80000e62:	367d                	addw	a2,a2,-1
    80000e64:	00d05963          	blez	a3,80000e76 <strncpy+0x1e>
    80000e68:	0785                	add	a5,a5,1
    80000e6a:	0005c703          	lbu	a4,0(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	0585                	add	a1,a1,1
    80000e74:	f775                	bnez	a4,80000e60 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e76:	873e                	mv	a4,a5
    80000e78:	9fb5                	addw	a5,a5,a3
    80000e7a:	37fd                	addw	a5,a5,-1
    80000e7c:	00c05963          	blez	a2,80000e8e <strncpy+0x36>
    *s++ = 0;
    80000e80:	0705                	add	a4,a4,1
    80000e82:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e86:	40e786bb          	subw	a3,a5,a4
    80000e8a:	fed04be3          	bgtz	a3,80000e80 <strncpy+0x28>
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	add	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e94:	1141                	add	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	add	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e9a:	02c05363          	blez	a2,80000ec0 <safestrcpy+0x2c>
    80000e9e:	fff6069b          	addw	a3,a2,-1
    80000ea2:	1682                	sll	a3,a3,0x20
    80000ea4:	9281                	srl	a3,a3,0x20
    80000ea6:	96ae                	add	a3,a3,a1
    80000ea8:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eaa:	00d58963          	beq	a1,a3,80000ebc <safestrcpy+0x28>
    80000eae:	0585                	add	a1,a1,1
    80000eb0:	0785                	add	a5,a5,1
    80000eb2:	fff5c703          	lbu	a4,-1(a1)
    80000eb6:	fee78fa3          	sb	a4,-1(a5)
    80000eba:	fb65                	bnez	a4,80000eaa <safestrcpy+0x16>
    ;
  *s = 0;
    80000ebc:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ec0:	6422                	ld	s0,8(sp)
    80000ec2:	0141                	add	sp,sp,16
    80000ec4:	8082                	ret

0000000080000ec6 <strlen>:

int
strlen(const char *s)
{
    80000ec6:	1141                	add	sp,sp,-16
    80000ec8:	e422                	sd	s0,8(sp)
    80000eca:	0800                	add	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ecc:	00054783          	lbu	a5,0(a0)
    80000ed0:	cf91                	beqz	a5,80000eec <strlen+0x26>
    80000ed2:	0505                	add	a0,a0,1
    80000ed4:	87aa                	mv	a5,a0
    80000ed6:	86be                	mv	a3,a5
    80000ed8:	0785                	add	a5,a5,1
    80000eda:	fff7c703          	lbu	a4,-1(a5)
    80000ede:	ff65                	bnez	a4,80000ed6 <strlen+0x10>
    80000ee0:	40a6853b          	subw	a0,a3,a0
    80000ee4:	2505                	addw	a0,a0,1
    ;
  return n;
}
    80000ee6:	6422                	ld	s0,8(sp)
    80000ee8:	0141                	add	sp,sp,16
    80000eea:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eec:	4501                	li	a0,0
    80000eee:	bfe5                	j	80000ee6 <strlen+0x20>

0000000080000ef0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ef0:	1141                	add	sp,sp,-16
    80000ef2:	e406                	sd	ra,8(sp)
    80000ef4:	e022                	sd	s0,0(sp)
    80000ef6:	0800                	add	s0,sp,16
  if(cpuid() == 0){
    80000ef8:	00001097          	auipc	ra,0x1
    80000efc:	bdc080e7          	jalr	-1060(ra) # 80001ad4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f00:	00008717          	auipc	a4,0x8
    80000f04:	9c870713          	add	a4,a4,-1592 # 800088c8 <started>
  if(cpuid() == 0){
    80000f08:	c139                	beqz	a0,80000f4e <main+0x5e>
    while(started == 0)
    80000f0a:	431c                	lw	a5,0(a4)
    80000f0c:	2781                	sext.w	a5,a5
    80000f0e:	dff5                	beqz	a5,80000f0a <main+0x1a>
      ;
    __sync_synchronize();
    80000f10:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	bc0080e7          	jalr	-1088(ra) # 80001ad4 <cpuid>
    80000f1c:	85aa                	mv	a1,a0
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	19a50513          	add	a0,a0,410 # 800080b8 <digits+0x78>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	660080e7          	jalr	1632(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000f2e:	00000097          	auipc	ra,0x0
    80000f32:	0d8080e7          	jalr	216(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a6c080e7          	jalr	-1428(ra) # 800029a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f3e:	00005097          	auipc	ra,0x5
    80000f42:	1b2080e7          	jalr	434(ra) # 800060f0 <plicinithart>
  }

  scheduler();        
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	0d4080e7          	jalr	212(ra) # 8000201a <scheduler>
    consoleinit();
    80000f4e:	fffff097          	auipc	ra,0xfffff
    80000f52:	4fe080e7          	jalr	1278(ra) # 8000044c <consoleinit>
    printfinit();
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	810080e7          	jalr	-2032(ra) # 80000766 <printfinit>
    printf("\n");
    80000f5e:	00007517          	auipc	a0,0x7
    80000f62:	16a50513          	add	a0,a0,362 # 800080c8 <digits+0x88>
    80000f66:	fffff097          	auipc	ra,0xfffff
    80000f6a:	620080e7          	jalr	1568(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000f6e:	00007517          	auipc	a0,0x7
    80000f72:	13250513          	add	a0,a0,306 # 800080a0 <digits+0x60>
    80000f76:	fffff097          	auipc	ra,0xfffff
    80000f7a:	610080e7          	jalr	1552(ra) # 80000586 <printf>
    printf("\n");
    80000f7e:	00007517          	auipc	a0,0x7
    80000f82:	14a50513          	add	a0,a0,330 # 800080c8 <digits+0x88>
    80000f86:	fffff097          	auipc	ra,0xfffff
    80000f8a:	600080e7          	jalr	1536(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	b5c080e7          	jalr	-1188(ra) # 80000aea <kinit>
    kvminit();       // create kernel page table
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	326080e7          	jalr	806(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f9e:	00000097          	auipc	ra,0x0
    80000fa2:	068080e7          	jalr	104(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	a7a080e7          	jalr	-1414(ra) # 80001a20 <procinit>
    trapinit();      // trap vectors
    80000fae:	00002097          	auipc	ra,0x2
    80000fb2:	9cc080e7          	jalr	-1588(ra) # 8000297a <trapinit>
    trapinithart();  // install kernel trap vector
    80000fb6:	00002097          	auipc	ra,0x2
    80000fba:	9ec080e7          	jalr	-1556(ra) # 800029a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	11c080e7          	jalr	284(ra) # 800060da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fc6:	00005097          	auipc	ra,0x5
    80000fca:	12a080e7          	jalr	298(ra) # 800060f0 <plicinithart>
    binit();         // buffer cache
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	2fe080e7          	jalr	766(ra) # 800032cc <binit>
    iinit();         // inode table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	99c080e7          	jalr	-1636(ra) # 80003972 <iinit>
    fileinit();      // file table
    80000fde:	00004097          	auipc	ra,0x4
    80000fe2:	912080e7          	jalr	-1774(ra) # 800048f0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	212080e7          	jalr	530(ra) # 800061f8 <virtio_disk_init>
    userinit();      // first user process
    80000fee:	00001097          	auipc	ra,0x1
    80000ff2:	e0e080e7          	jalr	-498(ra) # 80001dfc <userinit>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00008717          	auipc	a4,0x8
    80001000:	8cf72623          	sw	a5,-1844(a4) # 800088c8 <started>
    80001004:	b789                	j	80000f46 <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	add	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	add	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	8c07b783          	ld	a5,-1856(a5) # 800088d0 <kernel_pagetable>
    80001018:	83b1                	srl	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	sll	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	add	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	add	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	add	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srl	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	add	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e0080e7          	jalr	1248(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	abe080e7          	jalr	-1346(ra) # 80000b26 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	cd4080e7          	jalr	-812(ra) # 80000d4c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srl	a5,s1,0xc
    80001084:	07aa                	sll	a5,a5,0xa
    80001086:	0017e793          	or	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fdbcc7f>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	and	s2,s2,511
    8000109c:	090e                	sll	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	and	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srl	s1,s1,0xa
    800010ac:	04b2                	sll	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srl	a0,s3,0xc
    800010b4:	1ff57513          	and	a0,a0,511
    800010b8:	050e                	sll	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	add	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srl	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	add	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	add	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	and	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	add	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srl	a5,a5,0xa
    8000110c:	00c79513          	sll	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	add	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	add	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	add	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	and	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srl	s1,s1,0xc
    80001166:	04aa                	sll	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	or	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	add	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3ba080e7          	jalr	954(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	add	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3aa080e7          	jalr	938(ra) # 8000053c <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	add	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	add	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	add	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	add	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	add	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	35e080e7          	jalr	862(ra) # 8000053c <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	add	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	add	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	934080e7          	jalr	-1740(ra) # 80000b26 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b4c080e7          	jalr	-1204(ra) # 80000d4c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	add	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	add	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	sll	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	sll	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	add	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	sll	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	6e4080e7          	jalr	1764(ra) # 8000198a <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	add	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	add	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	add	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00007797          	auipc	a5,0x7
    800012d0:	60a7b223          	sd	a0,1540(a5) # 800088d0 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	add	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	add	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	add	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	sll	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	sll	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	add	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	add	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	212080e7          	jalr	530(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	add	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	202080e7          	jalr	514(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	add	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f2080e7          	jalr	498(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	add	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e2080e7          	jalr	482(ra) # 8000053c <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	and	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	and	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srl	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	sll	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	64e080e7          	jalr	1614(ra) # 800009e4 <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	add	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	add	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	77c080e7          	jalr	1916(ra) # 80000b26 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	992080e7          	jalr	-1646(ra) # 80000d4c <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	add	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	add	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	add	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	73c080e7          	jalr	1852(ra) # 80000b26 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	954080e7          	jalr	-1708(ra) # 80000d4c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	990080e7          	jalr	-1648(ra) # 80000da8 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	add	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	add	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	104080e7          	jalr	260(ra) # 8000053c <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	add	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	add	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	add	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srl	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	add	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	add	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	or	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	66c080e7          	jalr	1644(ra) # 80000b26 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	882080e7          	jalr	-1918(ra) # 80000d4c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	add	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	4cc080e7          	jalr	1228(ra) # 800009e4 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	add	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	add	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srl	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	sll	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	add	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	and	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	and	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	add	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fb8080e7          	jalr	-72(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	456080e7          	jalr	1110(ra) # 800009e4 <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	add	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	add	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	add	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	add	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	add	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srl	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	ca75                	beqz	a2,800016d4 <uvmcopy+0xf4>
{
    800015e2:	715d                	add	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	e062                	sd	s8,0(sp)
    800015f8:	0880                	add	s0,sp,80
    800015fa:	8baa                	mv	s7,a0
    800015fc:	8b2e                	mv	s6,a1
    800015fe:	8ab2                	mv	s5,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001600:	4981                	li	s3,0
      *pte |= PTE_RSW;
    }
    pa = PTE2PA(*pte);

    // increment the ref count
    acquire(&ref_count_lock);
    80001602:	0000fa17          	auipc	s4,0xf
    80001606:	52ea0a13          	add	s4,s4,1326 # 80010b30 <ref_count_lock>
    useReference[pa/PGSIZE] += 1;
    8000160a:	0000fc17          	auipc	s8,0xf
    8000160e:	55ec0c13          	add	s8,s8,1374 # 80010b68 <useReference>
    80001612:	a0b5                	j	8000167e <uvmcopy+0x9e>
      panic("uvmcopy: pte should exist");
    80001614:	00007517          	auipc	a0,0x7
    80001618:	b7450513          	add	a0,a0,-1164 # 80008188 <digits+0x148>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	f20080e7          	jalr	-224(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001624:	00007517          	auipc	a0,0x7
    80001628:	b8450513          	add	a0,a0,-1148 # 800081a8 <digits+0x168>
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	f10080e7          	jalr	-240(ra) # 8000053c <panic>
    pa = PTE2PA(*pte);
    80001634:	0004b903          	ld	s2,0(s1)
    80001638:	00a95913          	srl	s2,s2,0xa
    8000163c:	0932                	sll	s2,s2,0xc
    acquire(&ref_count_lock);
    8000163e:	8552                	mv	a0,s4
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	610080e7          	jalr	1552(ra) # 80000c50 <acquire>
    useReference[pa/PGSIZE] += 1;
    80001648:	00a95793          	srl	a5,s2,0xa
    8000164c:	97e2                	add	a5,a5,s8
    8000164e:	4398                	lw	a4,0(a5)
    80001650:	2705                	addw	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fdbcc89>
    80001652:	c398                	sw	a4,0(a5)
    release(&ref_count_lock);
    80001654:	8552                	mv	a0,s4
    80001656:	fffff097          	auipc	ra,0xfffff
    8000165a:	6ae080e7          	jalr	1710(ra) # 80000d04 <release>

    flags = PTE_FLAGS(*pte);
    8000165e:	6098                	ld	a4,0(s1)
    // if((mem = kalloc()) == 0)
    //   goto err;
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    80001660:	3ff77713          	and	a4,a4,1023
    80001664:	86ca                	mv	a3,s2
    80001666:	6605                	lui	a2,0x1
    80001668:	85ce                	mv	a1,s3
    8000166a:	855a                	mv	a0,s6
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	aaa080e7          	jalr	-1366(ra) # 80001116 <mappages>
    80001674:	e915                	bnez	a0,800016a8 <uvmcopy+0xc8>
  for(i = 0; i < sz; i += PGSIZE){
    80001676:	6785                	lui	a5,0x1
    80001678:	99be                	add	s3,s3,a5
    8000167a:	0559f163          	bgeu	s3,s5,800016bc <uvmcopy+0xdc>
    if((pte = walk(old, i, 0)) == 0)
    8000167e:	4601                	li	a2,0
    80001680:	85ce                	mv	a1,s3
    80001682:	855e                	mv	a0,s7
    80001684:	00000097          	auipc	ra,0x0
    80001688:	9aa080e7          	jalr	-1622(ra) # 8000102e <walk>
    8000168c:	84aa                	mv	s1,a0
    8000168e:	d159                	beqz	a0,80001614 <uvmcopy+0x34>
    if((*pte & PTE_V) == 0)
    80001690:	611c                	ld	a5,0(a0)
    80001692:	0017f713          	and	a4,a5,1
    80001696:	d759                	beqz	a4,80001624 <uvmcopy+0x44>
    if (*pte & PTE_W) {
    80001698:	0047f713          	and	a4,a5,4
    8000169c:	df41                	beqz	a4,80001634 <uvmcopy+0x54>
      *pte &= ~PTE_W;
    8000169e:	9bed                	and	a5,a5,-5
      *pte |= PTE_RSW;
    800016a0:	1007e793          	or	a5,a5,256
    800016a4:	e11c                	sd	a5,0(a0)
    800016a6:	b779                	j	80001634 <uvmcopy+0x54>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016a8:	4685                	li	a3,1
    800016aa:	00c9d613          	srl	a2,s3,0xc
    800016ae:	4581                	li	a1,0
    800016b0:	855a                	mv	a0,s6
    800016b2:	00000097          	auipc	ra,0x0
    800016b6:	c2a080e7          	jalr	-982(ra) # 800012dc <uvmunmap>
  return -1;
    800016ba:	557d                	li	a0,-1
}
    800016bc:	60a6                	ld	ra,72(sp)
    800016be:	6406                	ld	s0,64(sp)
    800016c0:	74e2                	ld	s1,56(sp)
    800016c2:	7942                	ld	s2,48(sp)
    800016c4:	79a2                	ld	s3,40(sp)
    800016c6:	7a02                	ld	s4,32(sp)
    800016c8:	6ae2                	ld	s5,24(sp)
    800016ca:	6b42                	ld	s6,16(sp)
    800016cc:	6ba2                	ld	s7,8(sp)
    800016ce:	6c02                	ld	s8,0(sp)
    800016d0:	6161                	add	sp,sp,80
    800016d2:	8082                	ret
  return 0;
    800016d4:	4501                	li	a0,0
}
    800016d6:	8082                	ret

00000000800016d8 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016d8:	1141                	add	sp,sp,-16
    800016da:	e406                	sd	ra,8(sp)
    800016dc:	e022                	sd	s0,0(sp)
    800016de:	0800                	add	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016e0:	4601                	li	a2,0
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	94c080e7          	jalr	-1716(ra) # 8000102e <walk>
  if(pte == 0)
    800016ea:	c901                	beqz	a0,800016fa <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016ec:	611c                	ld	a5,0(a0)
    800016ee:	9bbd                	and	a5,a5,-17
    800016f0:	e11c                	sd	a5,0(a0)
}
    800016f2:	60a2                	ld	ra,8(sp)
    800016f4:	6402                	ld	s0,0(sp)
    800016f6:	0141                	add	sp,sp,16
    800016f8:	8082                	ret
    panic("uvmclear");
    800016fa:	00007517          	auipc	a0,0x7
    800016fe:	ace50513          	add	a0,a0,-1330 # 800081c8 <digits+0x188>
    80001702:	fffff097          	auipc	ra,0xfffff
    80001706:	e3a080e7          	jalr	-454(ra) # 8000053c <panic>

000000008000170a <checkcowpage>:

int checkcowpage(uint64 va, pte_t *pte, struct proc* p) {
    8000170a:	1141                	add	sp,sp,-16
    8000170c:	e422                	sd	s0,8(sp)
    8000170e:	0800                	add	s0,sp,16
  return (va < p->sz) // va should blow the size of process memory (bytes)
    && (*pte & PTE_V) 
    && (*pte & PTE_RSW); // pte is COW page
    80001710:	663c                	ld	a5,72(a2)
    80001712:	00f57c63          	bgeu	a0,a5,8000172a <checkcowpage+0x20>
    80001716:	6188                	ld	a0,0(a1)
    80001718:	10157513          	and	a0,a0,257
    8000171c:	eff50513          	add	a0,a0,-257
    80001720:	00153513          	seqz	a0,a0
}
    80001724:	6422                	ld	s0,8(sp)
    80001726:	0141                	add	sp,sp,16
    80001728:	8082                	ret
    && (*pte & PTE_RSW); // pte is COW page
    8000172a:	4501                	li	a0,0
    8000172c:	bfe5                	j	80001724 <checkcowpage+0x1a>

000000008000172e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172e:	ceed                	beqz	a3,80001828 <copyout+0xfa>
{
    80001730:	7159                	add	sp,sp,-112
    80001732:	f486                	sd	ra,104(sp)
    80001734:	f0a2                	sd	s0,96(sp)
    80001736:	eca6                	sd	s1,88(sp)
    80001738:	e8ca                	sd	s2,80(sp)
    8000173a:	e4ce                	sd	s3,72(sp)
    8000173c:	e0d2                	sd	s4,64(sp)
    8000173e:	fc56                	sd	s5,56(sp)
    80001740:	f85a                	sd	s6,48(sp)
    80001742:	f45e                	sd	s7,40(sp)
    80001744:	f062                	sd	s8,32(sp)
    80001746:	ec66                	sd	s9,24(sp)
    80001748:	e86a                	sd	s10,16(sp)
    8000174a:	e46e                	sd	s11,8(sp)
    8000174c:	1880                	add	s0,sp,112
    8000174e:	8baa                	mv	s7,a0
    80001750:	84ae                	mv	s1,a1
    80001752:	8b32                	mv	s6,a2
    80001754:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001756:	7c7d                	lui	s8,0xfffff
      return -1;

    struct proc *p = myproc();
    pte_t *pte = walk(pagetable, va0, 0);
    if (*pte == 0)
      p->killed = 1;
    80001758:	4c85                	li	s9,1
    8000175a:	a895                	j	800017ce <copyout+0xa0>
    // check
    if (checkcowpage(va0, pte, p)) 
    {
      char *mem;
      if ((mem = kalloc()) == 0) {
    8000175c:	fffff097          	auipc	ra,0xfffff
    80001760:	3ca080e7          	jalr	970(ra) # 80000b26 <kalloc>
    80001764:	8daa                	mv	s11,a0
    80001766:	c121                	beqz	a0,800017a6 <copyout+0x78>
        // kill the process
        p->killed = 1;
      }else {
        memmove(mem, (char*)pa0, PGSIZE);
    80001768:	6605                	lui	a2,0x1
    8000176a:	85d2                	mv	a1,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	63c080e7          	jalr	1596(ra) # 80000da8 <memmove>
        // PAY ATTENTION!!!
        // This statement must be above the next statement
        uint flags = PTE_FLAGS(*pte);
    80001774:	00093d03          	ld	s10,0(s2) # 1000 <_entry-0x7ffff000>
    80001778:	3ffd7d13          	and	s10,s10,1023
        // decrease the reference count of old memory that va0 point
        // and set pte to 0
        uvmunmap(pagetable, va0, 1, 1);
    8000177c:	86e6                	mv	a3,s9
    8000177e:	8666                	mv	a2,s9
    80001780:	85ce                	mv	a1,s3
    80001782:	855e                	mv	a0,s7
    80001784:	00000097          	auipc	ra,0x0
    80001788:	b58080e7          	jalr	-1192(ra) # 800012dc <uvmunmap>
        // change the physical memory address and set PTE_W to 1
        *pte = (PA2PTE(mem) | flags | PTE_W);
    8000178c:	8a6e                	mv	s4,s11
    8000178e:	00cddd93          	srl	s11,s11,0xc
    80001792:	0daa                	sll	s11,s11,0xa
    80001794:	01bd6d33          	or	s10,s10,s11
        // set PTE_RSW to 0
        *pte &= ~PTE_RSW;
    80001798:	effd7d13          	and	s10,s10,-257
    8000179c:	004d6d13          	or	s10,s10,4
    800017a0:	01a93023          	sd	s10,0(s2)
        // update pa0 to new physical memory address
        pa0 = (uint64)mem;
    800017a4:	a885                	j	80001814 <copyout+0xe6>
        p->killed = 1;
    800017a6:	039d2423          	sw	s9,40(s10)
    800017aa:	a0ad                	j	80001814 <copyout+0xe6>
    }
    
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017ac:	41348533          	sub	a0,s1,s3
    800017b0:	0009061b          	sext.w	a2,s2
    800017b4:	85da                	mv	a1,s6
    800017b6:	9552                	add	a0,a0,s4
    800017b8:	fffff097          	auipc	ra,0xfffff
    800017bc:	5f0080e7          	jalr	1520(ra) # 80000da8 <memmove>

    len -= n;
    800017c0:	412a8ab3          	sub	s5,s5,s2
    src += n;
    800017c4:	9b4a                	add	s6,s6,s2
    dstva = va0 + PGSIZE;
    800017c6:	6485                	lui	s1,0x1
    800017c8:	94ce                	add	s1,s1,s3
  while(len > 0){
    800017ca:	040a8d63          	beqz	s5,80001824 <copyout+0xf6>
    va0 = PGROUNDDOWN(dstva);
    800017ce:	0184f9b3          	and	s3,s1,s8
    pa0 = walkaddr(pagetable, va0);
    800017d2:	85ce                	mv	a1,s3
    800017d4:	855e                	mv	a0,s7
    800017d6:	00000097          	auipc	ra,0x0
    800017da:	8fe080e7          	jalr	-1794(ra) # 800010d4 <walkaddr>
    800017de:	8a2a                	mv	s4,a0
    if(pa0 == 0)
    800017e0:	c531                	beqz	a0,8000182c <copyout+0xfe>
    struct proc *p = myproc();
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	31e080e7          	jalr	798(ra) # 80001b00 <myproc>
    800017ea:	8d2a                	mv	s10,a0
    pte_t *pte = walk(pagetable, va0, 0);
    800017ec:	4601                	li	a2,0
    800017ee:	85ce                	mv	a1,s3
    800017f0:	855e                	mv	a0,s7
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	83c080e7          	jalr	-1988(ra) # 8000102e <walk>
    800017fa:	892a                	mv	s2,a0
    if (*pte == 0)
    800017fc:	611c                	ld	a5,0(a0)
    800017fe:	e399                	bnez	a5,80001804 <copyout+0xd6>
      p->killed = 1;
    80001800:	039d2423          	sw	s9,40(s10)
    if (checkcowpage(va0, pte, p)) 
    80001804:	866a                	mv	a2,s10
    80001806:	85ca                	mv	a1,s2
    80001808:	854e                	mv	a0,s3
    8000180a:	00000097          	auipc	ra,0x0
    8000180e:	f00080e7          	jalr	-256(ra) # 8000170a <checkcowpage>
    80001812:	f529                	bnez	a0,8000175c <copyout+0x2e>
    n = PGSIZE - (dstva - va0);
    80001814:	40998933          	sub	s2,s3,s1
    80001818:	6785                	lui	a5,0x1
    8000181a:	993e                	add	s2,s2,a5
    8000181c:	f92af8e3          	bgeu	s5,s2,800017ac <copyout+0x7e>
    80001820:	8956                	mv	s2,s5
    80001822:	b769                	j	800017ac <copyout+0x7e>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyout+0x100>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	70a6                	ld	ra,104(sp)
    80001830:	7406                	ld	s0,96(sp)
    80001832:	64e6                	ld	s1,88(sp)
    80001834:	6946                	ld	s2,80(sp)
    80001836:	69a6                	ld	s3,72(sp)
    80001838:	6a06                	ld	s4,64(sp)
    8000183a:	7ae2                	ld	s5,56(sp)
    8000183c:	7b42                	ld	s6,48(sp)
    8000183e:	7ba2                	ld	s7,40(sp)
    80001840:	7c02                	ld	s8,32(sp)
    80001842:	6ce2                	ld	s9,24(sp)
    80001844:	6d42                	ld	s10,16(sp)
    80001846:	6da2                	ld	s11,8(sp)
    80001848:	6165                	add	sp,sp,112
    8000184a:	8082                	ret

000000008000184c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000184c:	caa5                	beqz	a3,800018bc <copyin+0x70>
{
    8000184e:	715d                	add	sp,sp,-80
    80001850:	e486                	sd	ra,72(sp)
    80001852:	e0a2                	sd	s0,64(sp)
    80001854:	fc26                	sd	s1,56(sp)
    80001856:	f84a                	sd	s2,48(sp)
    80001858:	f44e                	sd	s3,40(sp)
    8000185a:	f052                	sd	s4,32(sp)
    8000185c:	ec56                	sd	s5,24(sp)
    8000185e:	e85a                	sd	s6,16(sp)
    80001860:	e45e                	sd	s7,8(sp)
    80001862:	e062                	sd	s8,0(sp)
    80001864:	0880                	add	s0,sp,80
    80001866:	8b2a                	mv	s6,a0
    80001868:	8a2e                	mv	s4,a1
    8000186a:	8c32                	mv	s8,a2
    8000186c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000186e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001870:	6a85                	lui	s5,0x1
    80001872:	a01d                	j	80001898 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001874:	018505b3          	add	a1,a0,s8
    80001878:	0004861b          	sext.w	a2,s1
    8000187c:	412585b3          	sub	a1,a1,s2
    80001880:	8552                	mv	a0,s4
    80001882:	fffff097          	auipc	ra,0xfffff
    80001886:	526080e7          	jalr	1318(ra) # 80000da8 <memmove>

    len -= n;
    8000188a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000188e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001890:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001894:	02098263          	beqz	s3,800018b8 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001898:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000189c:	85ca                	mv	a1,s2
    8000189e:	855a                	mv	a0,s6
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	834080e7          	jalr	-1996(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800018a8:	cd01                	beqz	a0,800018c0 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018aa:	418904b3          	sub	s1,s2,s8
    800018ae:	94d6                	add	s1,s1,s5
    800018b0:	fc99f2e3          	bgeu	s3,s1,80001874 <copyin+0x28>
    800018b4:	84ce                	mv	s1,s3
    800018b6:	bf7d                	j	80001874 <copyin+0x28>
  }
  return 0;
    800018b8:	4501                	li	a0,0
    800018ba:	a021                	j	800018c2 <copyin+0x76>
    800018bc:	4501                	li	a0,0
}
    800018be:	8082                	ret
      return -1;
    800018c0:	557d                	li	a0,-1
}
    800018c2:	60a6                	ld	ra,72(sp)
    800018c4:	6406                	ld	s0,64(sp)
    800018c6:	74e2                	ld	s1,56(sp)
    800018c8:	7942                	ld	s2,48(sp)
    800018ca:	79a2                	ld	s3,40(sp)
    800018cc:	7a02                	ld	s4,32(sp)
    800018ce:	6ae2                	ld	s5,24(sp)
    800018d0:	6b42                	ld	s6,16(sp)
    800018d2:	6ba2                	ld	s7,8(sp)
    800018d4:	6c02                	ld	s8,0(sp)
    800018d6:	6161                	add	sp,sp,80
    800018d8:	8082                	ret

00000000800018da <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018da:	c2dd                	beqz	a3,80001980 <copyinstr+0xa6>
{
    800018dc:	715d                	add	sp,sp,-80
    800018de:	e486                	sd	ra,72(sp)
    800018e0:	e0a2                	sd	s0,64(sp)
    800018e2:	fc26                	sd	s1,56(sp)
    800018e4:	f84a                	sd	s2,48(sp)
    800018e6:	f44e                	sd	s3,40(sp)
    800018e8:	f052                	sd	s4,32(sp)
    800018ea:	ec56                	sd	s5,24(sp)
    800018ec:	e85a                	sd	s6,16(sp)
    800018ee:	e45e                	sd	s7,8(sp)
    800018f0:	0880                	add	s0,sp,80
    800018f2:	8a2a                	mv	s4,a0
    800018f4:	8b2e                	mv	s6,a1
    800018f6:	8bb2                	mv	s7,a2
    800018f8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018fa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018fc:	6985                	lui	s3,0x1
    800018fe:	a02d                	j	80001928 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001900:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001904:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001906:	37fd                	addw	a5,a5,-1
    80001908:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
    8000190c:	60a6                	ld	ra,72(sp)
    8000190e:	6406                	ld	s0,64(sp)
    80001910:	74e2                	ld	s1,56(sp)
    80001912:	7942                	ld	s2,48(sp)
    80001914:	79a2                	ld	s3,40(sp)
    80001916:	7a02                	ld	s4,32(sp)
    80001918:	6ae2                	ld	s5,24(sp)
    8000191a:	6b42                	ld	s6,16(sp)
    8000191c:	6ba2                	ld	s7,8(sp)
    8000191e:	6161                	add	sp,sp,80
    80001920:	8082                	ret
    srcva = va0 + PGSIZE;
    80001922:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001926:	c8a9                	beqz	s1,80001978 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001928:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000192c:	85ca                	mv	a1,s2
    8000192e:	8552                	mv	a0,s4
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	7a4080e7          	jalr	1956(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    80001938:	c131                	beqz	a0,8000197c <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000193a:	417906b3          	sub	a3,s2,s7
    8000193e:	96ce                	add	a3,a3,s3
    80001940:	00d4f363          	bgeu	s1,a3,80001946 <copyinstr+0x6c>
    80001944:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001946:	955e                	add	a0,a0,s7
    80001948:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000194c:	daf9                	beqz	a3,80001922 <copyinstr+0x48>
    8000194e:	87da                	mv	a5,s6
    80001950:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001952:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001956:	96da                	add	a3,a3,s6
    80001958:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000195a:	00f60733          	add	a4,a2,a5
    8000195e:	00074703          	lbu	a4,0(a4)
    80001962:	df59                	beqz	a4,80001900 <copyinstr+0x26>
        *dst = *p;
    80001964:	00e78023          	sb	a4,0(a5)
      dst++;
    80001968:	0785                	add	a5,a5,1
    while(n > 0){
    8000196a:	fed797e3          	bne	a5,a3,80001958 <copyinstr+0x7e>
    8000196e:	14fd                	add	s1,s1,-1 # fff <_entry-0x7ffff001>
    80001970:	94c2                	add	s1,s1,a6
      --max;
    80001972:	8c8d                	sub	s1,s1,a1
      dst++;
    80001974:	8b3e                	mv	s6,a5
    80001976:	b775                	j	80001922 <copyinstr+0x48>
    80001978:	4781                	li	a5,0
    8000197a:	b771                	j	80001906 <copyinstr+0x2c>
      return -1;
    8000197c:	557d                	li	a0,-1
    8000197e:	b779                	j	8000190c <copyinstr+0x32>
  int got_null = 0;
    80001980:	4781                	li	a5,0
  if(got_null){
    80001982:	37fd                	addw	a5,a5,-1
    80001984:	0007851b          	sext.w	a0,a5
    80001988:	8082                	ret

000000008000198a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000198a:	7139                	add	sp,sp,-64
    8000198c:	fc06                	sd	ra,56(sp)
    8000198e:	f822                	sd	s0,48(sp)
    80001990:	f426                	sd	s1,40(sp)
    80001992:	f04a                	sd	s2,32(sp)
    80001994:	ec4e                	sd	s3,24(sp)
    80001996:	e852                	sd	s4,16(sp)
    80001998:	e456                	sd	s5,8(sp)
    8000199a:	e05a                	sd	s6,0(sp)
    8000199c:	0080                	add	s0,sp,64
    8000199e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800019a0:	0022f497          	auipc	s1,0x22f
    800019a4:	5f848493          	add	s1,s1,1528 # 80230f98 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    800019a8:	8b26                	mv	s6,s1
    800019aa:	00006a97          	auipc	s5,0x6
    800019ae:	656a8a93          	add	s5,s5,1622 # 80008000 <etext>
    800019b2:	04000937          	lui	s2,0x4000
    800019b6:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019b8:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800019ba:	00235a17          	auipc	s4,0x235
    800019be:	5dea0a13          	add	s4,s4,1502 # 80236f98 <tickslock>
    char *pa = kalloc();
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	164080e7          	jalr	356(ra) # 80000b26 <kalloc>
    800019ca:	862a                	mv	a2,a0
    if (pa == 0)
    800019cc:	c131                	beqz	a0,80001a10 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800019ce:	416485b3          	sub	a1,s1,s6
    800019d2:	859d                	sra	a1,a1,0x7
    800019d4:	000ab783          	ld	a5,0(s5)
    800019d8:	02f585b3          	mul	a1,a1,a5
    800019dc:	2585                	addw	a1,a1,1
    800019de:	00d5959b          	sllw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019e2:	4719                	li	a4,6
    800019e4:	6685                	lui	a3,0x1
    800019e6:	40b905b3          	sub	a1,s2,a1
    800019ea:	854e                	mv	a0,s3
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	7ca080e7          	jalr	1994(ra) # 800011b6 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019f4:	18048493          	add	s1,s1,384
    800019f8:	fd4495e3          	bne	s1,s4,800019c2 <proc_mapstacks+0x38>
  }
}
    800019fc:	70e2                	ld	ra,56(sp)
    800019fe:	7442                	ld	s0,48(sp)
    80001a00:	74a2                	ld	s1,40(sp)
    80001a02:	7902                	ld	s2,32(sp)
    80001a04:	69e2                	ld	s3,24(sp)
    80001a06:	6a42                	ld	s4,16(sp)
    80001a08:	6aa2                	ld	s5,8(sp)
    80001a0a:	6b02                	ld	s6,0(sp)
    80001a0c:	6121                	add	sp,sp,64
    80001a0e:	8082                	ret
      panic("kalloc");
    80001a10:	00006517          	auipc	a0,0x6
    80001a14:	7c850513          	add	a0,a0,1992 # 800081d8 <digits+0x198>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	b24080e7          	jalr	-1244(ra) # 8000053c <panic>

0000000080001a20 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001a20:	7139                	add	sp,sp,-64
    80001a22:	fc06                	sd	ra,56(sp)
    80001a24:	f822                	sd	s0,48(sp)
    80001a26:	f426                	sd	s1,40(sp)
    80001a28:	f04a                	sd	s2,32(sp)
    80001a2a:	ec4e                	sd	s3,24(sp)
    80001a2c:	e852                	sd	s4,16(sp)
    80001a2e:	e456                	sd	s5,8(sp)
    80001a30:	e05a                	sd	s6,0(sp)
    80001a32:	0080                	add	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a34:	00006597          	auipc	a1,0x6
    80001a38:	7ac58593          	add	a1,a1,1964 # 800081e0 <digits+0x1a0>
    80001a3c:	0022f517          	auipc	a0,0x22f
    80001a40:	12c50513          	add	a0,a0,300 # 80230b68 <pid_lock>
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	17c080e7          	jalr	380(ra) # 80000bc0 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a4c:	00006597          	auipc	a1,0x6
    80001a50:	79c58593          	add	a1,a1,1948 # 800081e8 <digits+0x1a8>
    80001a54:	0022f517          	auipc	a0,0x22f
    80001a58:	12c50513          	add	a0,a0,300 # 80230b80 <wait_lock>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	164080e7          	jalr	356(ra) # 80000bc0 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a64:	0022f497          	auipc	s1,0x22f
    80001a68:	53448493          	add	s1,s1,1332 # 80230f98 <proc>
  {
    initlock(&p->lock, "proc");
    80001a6c:	00006b17          	auipc	s6,0x6
    80001a70:	78cb0b13          	add	s6,s6,1932 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a74:	8aa6                	mv	s5,s1
    80001a76:	00006a17          	auipc	s4,0x6
    80001a7a:	58aa0a13          	add	s4,s4,1418 # 80008000 <etext>
    80001a7e:	04000937          	lui	s2,0x4000
    80001a82:	197d                	add	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001a84:	0932                	sll	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a86:	00235997          	auipc	s3,0x235
    80001a8a:	51298993          	add	s3,s3,1298 # 80236f98 <tickslock>
    initlock(&p->lock, "proc");
    80001a8e:	85da                	mv	a1,s6
    80001a90:	8526                	mv	a0,s1
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	12e080e7          	jalr	302(ra) # 80000bc0 <initlock>
    p->state = UNUSED;
    80001a9a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a9e:	415487b3          	sub	a5,s1,s5
    80001aa2:	879d                	sra	a5,a5,0x7
    80001aa4:	000a3703          	ld	a4,0(s4)
    80001aa8:	02e787b3          	mul	a5,a5,a4
    80001aac:	2785                	addw	a5,a5,1
    80001aae:	00d7979b          	sllw	a5,a5,0xd
    80001ab2:	40f907b3          	sub	a5,s2,a5
    80001ab6:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001ab8:	18048493          	add	s1,s1,384
    80001abc:	fd3499e3          	bne	s1,s3,80001a8e <procinit+0x6e>
  }
}
    80001ac0:	70e2                	ld	ra,56(sp)
    80001ac2:	7442                	ld	s0,48(sp)
    80001ac4:	74a2                	ld	s1,40(sp)
    80001ac6:	7902                	ld	s2,32(sp)
    80001ac8:	69e2                	ld	s3,24(sp)
    80001aca:	6a42                	ld	s4,16(sp)
    80001acc:	6aa2                	ld	s5,8(sp)
    80001ace:	6b02                	ld	s6,0(sp)
    80001ad0:	6121                	add	sp,sp,64
    80001ad2:	8082                	ret

0000000080001ad4 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001ad4:	1141                	add	sp,sp,-16
    80001ad6:	e422                	sd	s0,8(sp)
    80001ad8:	0800                	add	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ada:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001adc:	2501                	sext.w	a0,a0
    80001ade:	6422                	ld	s0,8(sp)
    80001ae0:	0141                	add	sp,sp,16
    80001ae2:	8082                	ret

0000000080001ae4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001ae4:	1141                	add	sp,sp,-16
    80001ae6:	e422                	sd	s0,8(sp)
    80001ae8:	0800                	add	s0,sp,16
    80001aea:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aec:	2781                	sext.w	a5,a5
    80001aee:	079e                	sll	a5,a5,0x7
  return c;
}
    80001af0:	0022f517          	auipc	a0,0x22f
    80001af4:	0a850513          	add	a0,a0,168 # 80230b98 <cpus>
    80001af8:	953e                	add	a0,a0,a5
    80001afa:	6422                	ld	s0,8(sp)
    80001afc:	0141                	add	sp,sp,16
    80001afe:	8082                	ret

0000000080001b00 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b00:	1101                	add	sp,sp,-32
    80001b02:	ec06                	sd	ra,24(sp)
    80001b04:	e822                	sd	s0,16(sp)
    80001b06:	e426                	sd	s1,8(sp)
    80001b08:	1000                	add	s0,sp,32
  push_off();
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	0fa080e7          	jalr	250(ra) # 80000c04 <push_off>
    80001b12:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b14:	2781                	sext.w	a5,a5
    80001b16:	079e                	sll	a5,a5,0x7
    80001b18:	0022f717          	auipc	a4,0x22f
    80001b1c:	05070713          	add	a4,a4,80 # 80230b68 <pid_lock>
    80001b20:	97ba                	add	a5,a5,a4
    80001b22:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	180080e7          	jalr	384(ra) # 80000ca4 <pop_off>
  return p;
}
    80001b2c:	8526                	mv	a0,s1
    80001b2e:	60e2                	ld	ra,24(sp)
    80001b30:	6442                	ld	s0,16(sp)
    80001b32:	64a2                	ld	s1,8(sp)
    80001b34:	6105                	add	sp,sp,32
    80001b36:	8082                	ret

0000000080001b38 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b38:	1141                	add	sp,sp,-16
    80001b3a:	e406                	sd	ra,8(sp)
    80001b3c:	e022                	sd	s0,0(sp)
    80001b3e:	0800                	add	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b40:	00000097          	auipc	ra,0x0
    80001b44:	fc0080e7          	jalr	-64(ra) # 80001b00 <myproc>
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	1bc080e7          	jalr	444(ra) # 80000d04 <release>

  if (first)
    80001b50:	00007797          	auipc	a5,0x7
    80001b54:	d107a783          	lw	a5,-752(a5) # 80008860 <first.1>
    80001b58:	eb89                	bnez	a5,80001b6a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b5a:	00001097          	auipc	ra,0x1
    80001b5e:	ef4080e7          	jalr	-268(ra) # 80002a4e <usertrapret>
}
    80001b62:	60a2                	ld	ra,8(sp)
    80001b64:	6402                	ld	s0,0(sp)
    80001b66:	0141                	add	sp,sp,16
    80001b68:	8082                	ret
    first = 0;
    80001b6a:	00007797          	auipc	a5,0x7
    80001b6e:	ce07ab23          	sw	zero,-778(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b72:	4505                	li	a0,1
    80001b74:	00002097          	auipc	ra,0x2
    80001b78:	d7e080e7          	jalr	-642(ra) # 800038f2 <fsinit>
    80001b7c:	bff9                	j	80001b5a <forkret+0x22>

0000000080001b7e <allocpid>:
{
    80001b7e:	1101                	add	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	e04a                	sd	s2,0(sp)
    80001b88:	1000                	add	s0,sp,32
  acquire(&pid_lock);
    80001b8a:	0022f917          	auipc	s2,0x22f
    80001b8e:	fde90913          	add	s2,s2,-34 # 80230b68 <pid_lock>
    80001b92:	854a                	mv	a0,s2
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	0bc080e7          	jalr	188(ra) # 80000c50 <acquire>
  pid = nextpid;
    80001b9c:	00007797          	auipc	a5,0x7
    80001ba0:	cc878793          	add	a5,a5,-824 # 80008864 <nextpid>
    80001ba4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba6:	0014871b          	addw	a4,s1,1
    80001baa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bac:	854a                	mv	a0,s2
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	156080e7          	jalr	342(ra) # 80000d04 <release>
}
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6902                	ld	s2,0(sp)
    80001bc0:	6105                	add	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <proc_pagetable>:
{
    80001bc4:	1101                	add	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	e04a                	sd	s2,0(sp)
    80001bce:	1000                	add	s0,sp,32
    80001bd0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	7ce080e7          	jalr	1998(ra) # 800013a0 <uvmcreate>
    80001bda:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bdc:	c121                	beqz	a0,80001c1c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bde:	4729                	li	a4,10
    80001be0:	00005697          	auipc	a3,0x5
    80001be4:	42068693          	add	a3,a3,1056 # 80007000 <_trampoline>
    80001be8:	6605                	lui	a2,0x1
    80001bea:	040005b7          	lui	a1,0x4000
    80001bee:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bf0:	05b2                	sll	a1,a1,0xc
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	524080e7          	jalr	1316(ra) # 80001116 <mappages>
    80001bfa:	02054863          	bltz	a0,80001c2a <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bfe:	4719                	li	a4,6
    80001c00:	05893683          	ld	a3,88(s2)
    80001c04:	6605                	lui	a2,0x1
    80001c06:	020005b7          	lui	a1,0x2000
    80001c0a:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c0c:	05b6                	sll	a1,a1,0xd
    80001c0e:	8526                	mv	a0,s1
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	506080e7          	jalr	1286(ra) # 80001116 <mappages>
    80001c18:	02054163          	bltz	a0,80001c3a <proc_pagetable+0x76>
}
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	60e2                	ld	ra,24(sp)
    80001c20:	6442                	ld	s0,16(sp)
    80001c22:	64a2                	ld	s1,8(sp)
    80001c24:	6902                	ld	s2,0(sp)
    80001c26:	6105                	add	sp,sp,32
    80001c28:	8082                	ret
    uvmfree(pagetable, 0);
    80001c2a:	4581                	li	a1,0
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	978080e7          	jalr	-1672(ra) # 800015a6 <uvmfree>
    return 0;
    80001c36:	4481                	li	s1,0
    80001c38:	b7d5                	j	80001c1c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c3a:	4681                	li	a3,0
    80001c3c:	4605                	li	a2,1
    80001c3e:	040005b7          	lui	a1,0x4000
    80001c42:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c44:	05b2                	sll	a1,a1,0xc
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	694080e7          	jalr	1684(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001c50:	4581                	li	a1,0
    80001c52:	8526                	mv	a0,s1
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	952080e7          	jalr	-1710(ra) # 800015a6 <uvmfree>
    return 0;
    80001c5c:	4481                	li	s1,0
    80001c5e:	bf7d                	j	80001c1c <proc_pagetable+0x58>

0000000080001c60 <proc_freepagetable>:
{
    80001c60:	1101                	add	sp,sp,-32
    80001c62:	ec06                	sd	ra,24(sp)
    80001c64:	e822                	sd	s0,16(sp)
    80001c66:	e426                	sd	s1,8(sp)
    80001c68:	e04a                	sd	s2,0(sp)
    80001c6a:	1000                	add	s0,sp,32
    80001c6c:	84aa                	mv	s1,a0
    80001c6e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c70:	4681                	li	a3,0
    80001c72:	4605                	li	a2,1
    80001c74:	040005b7          	lui	a1,0x4000
    80001c78:	15fd                	add	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c7a:	05b2                	sll	a1,a1,0xc
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	660080e7          	jalr	1632(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c84:	4681                	li	a3,0
    80001c86:	4605                	li	a2,1
    80001c88:	020005b7          	lui	a1,0x2000
    80001c8c:	15fd                	add	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c8e:	05b6                	sll	a1,a1,0xd
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	64a080e7          	jalr	1610(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001c9a:	85ca                	mv	a1,s2
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	908080e7          	jalr	-1784(ra) # 800015a6 <uvmfree>
}
    80001ca6:	60e2                	ld	ra,24(sp)
    80001ca8:	6442                	ld	s0,16(sp)
    80001caa:	64a2                	ld	s1,8(sp)
    80001cac:	6902                	ld	s2,0(sp)
    80001cae:	6105                	add	sp,sp,32
    80001cb0:	8082                	ret

0000000080001cb2 <freeproc>:
{
    80001cb2:	1101                	add	sp,sp,-32
    80001cb4:	ec06                	sd	ra,24(sp)
    80001cb6:	e822                	sd	s0,16(sp)
    80001cb8:	e426                	sd	s1,8(sp)
    80001cba:	1000                	add	s0,sp,32
    80001cbc:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001cbe:	6d28                	ld	a0,88(a0)
    80001cc0:	c509                	beqz	a0,80001cca <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	d22080e7          	jalr	-734(ra) # 800009e4 <kfree>
  p->trapframe = 0;
    80001cca:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001cce:	68a8                	ld	a0,80(s1)
    80001cd0:	c511                	beqz	a0,80001cdc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cd2:	64ac                	ld	a1,72(s1)
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	f8c080e7          	jalr	-116(ra) # 80001c60 <proc_freepagetable>
  p->pagetable = 0;
    80001cdc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ce0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ce4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001ce8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cec:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cf0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cf4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cf8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cfc:	0004ac23          	sw	zero,24(s1)
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6105                	add	sp,sp,32
    80001d08:	8082                	ret

0000000080001d0a <allocproc>:
{
    80001d0a:	1101                	add	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	e04a                	sd	s2,0(sp)
    80001d14:	1000                	add	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d16:	0022f497          	auipc	s1,0x22f
    80001d1a:	28248493          	add	s1,s1,642 # 80230f98 <proc>
    80001d1e:	00235917          	auipc	s2,0x235
    80001d22:	27a90913          	add	s2,s2,634 # 80236f98 <tickslock>
    acquire(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f28080e7          	jalr	-216(ra) # 80000c50 <acquire>
    if (p->state == UNUSED)
    80001d30:	4c9c                	lw	a5,24(s1)
    80001d32:	cf81                	beqz	a5,80001d4a <allocproc+0x40>
      release(&p->lock);
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	fce080e7          	jalr	-50(ra) # 80000d04 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d3e:	18048493          	add	s1,s1,384
    80001d42:	ff2492e3          	bne	s1,s2,80001d26 <allocproc+0x1c>
  return 0;
    80001d46:	4481                	li	s1,0
    80001d48:	a89d                	j	80001dbe <allocproc+0xb4>
  p->pid = allocpid();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	e34080e7          	jalr	-460(ra) # 80001b7e <allocpid>
    80001d52:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d54:	4785                	li	a5,1
    80001d56:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	dce080e7          	jalr	-562(ra) # 80000b26 <kalloc>
    80001d60:	892a                	mv	s2,a0
    80001d62:	eca8                	sd	a0,88(s1)
    80001d64:	c525                	beqz	a0,80001dcc <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001d66:	8526                	mv	a0,s1
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e5c080e7          	jalr	-420(ra) # 80001bc4 <proc_pagetable>
    80001d70:	892a                	mv	s2,a0
    80001d72:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d74:	c925                	beqz	a0,80001de4 <allocproc+0xda>
  p->priority=50;
    80001d76:	03200793          	li	a5,50
    80001d7a:	16f4ae23          	sw	a5,380(s1)
  p->wtime=0;
    80001d7e:	1604aa23          	sw	zero,372(s1)
  p->stime=0;
    80001d82:	1604ac23          	sw	zero,376(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001d86:	07000613          	li	a2,112
    80001d8a:	4581                	li	a1,0
    80001d8c:	06048513          	add	a0,s1,96
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	fbc080e7          	jalr	-68(ra) # 80000d4c <memset>
  p->context.ra = (uint64)forkret;
    80001d98:	00000797          	auipc	a5,0x0
    80001d9c:	da078793          	add	a5,a5,-608 # 80001b38 <forkret>
    80001da0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da2:	60bc                	ld	a5,64(s1)
    80001da4:	6705                	lui	a4,0x1
    80001da6:	97ba                	add	a5,a5,a4
    80001da8:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001daa:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001dae:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001db2:	00007797          	auipc	a5,0x7
    80001db6:	b2e7a783          	lw	a5,-1234(a5) # 800088e0 <ticks>
    80001dba:	16f4a623          	sw	a5,364(s1)
}
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6902                	ld	s2,0(sp)
    80001dc8:	6105                	add	sp,sp,32
    80001dca:	8082                	ret
    freeproc(p);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	ee4080e7          	jalr	-284(ra) # 80001cb2 <freeproc>
    release(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	f2c080e7          	jalr	-212(ra) # 80000d04 <release>
    return 0;
    80001de0:	84ca                	mv	s1,s2
    80001de2:	bff1                	j	80001dbe <allocproc+0xb4>
    freeproc(p);
    80001de4:	8526                	mv	a0,s1
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	ecc080e7          	jalr	-308(ra) # 80001cb2 <freeproc>
    release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	f14080e7          	jalr	-236(ra) # 80000d04 <release>
    return 0;
    80001df8:	84ca                	mv	s1,s2
    80001dfa:	b7d1                	j	80001dbe <allocproc+0xb4>

0000000080001dfc <userinit>:
{
    80001dfc:	1101                	add	sp,sp,-32
    80001dfe:	ec06                	sd	ra,24(sp)
    80001e00:	e822                	sd	s0,16(sp)
    80001e02:	e426                	sd	s1,8(sp)
    80001e04:	1000                	add	s0,sp,32
  p = allocproc();
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	f04080e7          	jalr	-252(ra) # 80001d0a <allocproc>
    80001e0e:	84aa                	mv	s1,a0
  initproc = p;
    80001e10:	00007797          	auipc	a5,0x7
    80001e14:	aca7b423          	sd	a0,-1336(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e18:	03400613          	li	a2,52
    80001e1c:	00007597          	auipc	a1,0x7
    80001e20:	a5458593          	add	a1,a1,-1452 # 80008870 <initcode>
    80001e24:	6928                	ld	a0,80(a0)
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	5a8080e7          	jalr	1448(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001e2e:	6785                	lui	a5,0x1
    80001e30:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e32:	6cb8                	ld	a4,88(s1)
    80001e34:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e38:	6cb8                	ld	a4,88(s1)
    80001e3a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e3c:	4641                	li	a2,16
    80001e3e:	00006597          	auipc	a1,0x6
    80001e42:	3c258593          	add	a1,a1,962 # 80008200 <digits+0x1c0>
    80001e46:	15848513          	add	a0,s1,344
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	04a080e7          	jalr	74(ra) # 80000e94 <safestrcpy>
  p->cwd = namei("/");
    80001e52:	00006517          	auipc	a0,0x6
    80001e56:	3be50513          	add	a0,a0,958 # 80008210 <digits+0x1d0>
    80001e5a:	00002097          	auipc	ra,0x2
    80001e5e:	4b6080e7          	jalr	1206(ra) # 80004310 <namei>
    80001e62:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e66:	478d                	li	a5,3
    80001e68:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e98080e7          	jalr	-360(ra) # 80000d04 <release>
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6105                	add	sp,sp,32
    80001e7c:	8082                	ret

0000000080001e7e <growproc>:
{
    80001e7e:	1101                	add	sp,sp,-32
    80001e80:	ec06                	sd	ra,24(sp)
    80001e82:	e822                	sd	s0,16(sp)
    80001e84:	e426                	sd	s1,8(sp)
    80001e86:	e04a                	sd	s2,0(sp)
    80001e88:	1000                	add	s0,sp,32
    80001e8a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	c74080e7          	jalr	-908(ra) # 80001b00 <myproc>
    80001e94:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e96:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e98:	01204c63          	bgtz	s2,80001eb0 <growproc+0x32>
  else if (n < 0)
    80001e9c:	02094663          	bltz	s2,80001ec8 <growproc+0x4a>
  p->sz = sz;
    80001ea0:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ea2:	4501                	li	a0,0
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6902                	ld	s2,0(sp)
    80001eac:	6105                	add	sp,sp,32
    80001eae:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001eb0:	4691                	li	a3,4
    80001eb2:	00b90633          	add	a2,s2,a1
    80001eb6:	6928                	ld	a0,80(a0)
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	5d0080e7          	jalr	1488(ra) # 80001488 <uvmalloc>
    80001ec0:	85aa                	mv	a1,a0
    80001ec2:	fd79                	bnez	a0,80001ea0 <growproc+0x22>
      return -1;
    80001ec4:	557d                	li	a0,-1
    80001ec6:	bff9                	j	80001ea4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ec8:	00b90633          	add	a2,s2,a1
    80001ecc:	6928                	ld	a0,80(a0)
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	572080e7          	jalr	1394(ra) # 80001440 <uvmdealloc>
    80001ed6:	85aa                	mv	a1,a0
    80001ed8:	b7e1                	j	80001ea0 <growproc+0x22>

0000000080001eda <fork>:
{
    80001eda:	7139                	add	sp,sp,-64
    80001edc:	fc06                	sd	ra,56(sp)
    80001ede:	f822                	sd	s0,48(sp)
    80001ee0:	f426                	sd	s1,40(sp)
    80001ee2:	f04a                	sd	s2,32(sp)
    80001ee4:	ec4e                	sd	s3,24(sp)
    80001ee6:	e852                	sd	s4,16(sp)
    80001ee8:	e456                	sd	s5,8(sp)
    80001eea:	0080                	add	s0,sp,64
  struct proc *p = myproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	c14080e7          	jalr	-1004(ra) # 80001b00 <myproc>
    80001ef4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	e14080e7          	jalr	-492(ra) # 80001d0a <allocproc>
    80001efe:	10050c63          	beqz	a0,80002016 <fork+0x13c>
    80001f02:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f04:	048ab603          	ld	a2,72(s5)
    80001f08:	692c                	ld	a1,80(a0)
    80001f0a:	050ab503          	ld	a0,80(s5)
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	6d2080e7          	jalr	1746(ra) # 800015e0 <uvmcopy>
    80001f16:	04054863          	bltz	a0,80001f66 <fork+0x8c>
  np->sz = p->sz;
    80001f1a:	048ab783          	ld	a5,72(s5)
    80001f1e:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f22:	058ab683          	ld	a3,88(s5)
    80001f26:	87b6                	mv	a5,a3
    80001f28:	058a3703          	ld	a4,88(s4)
    80001f2c:	12068693          	add	a3,a3,288
    80001f30:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f34:	6788                	ld	a0,8(a5)
    80001f36:	6b8c                	ld	a1,16(a5)
    80001f38:	6f90                	ld	a2,24(a5)
    80001f3a:	01073023          	sd	a6,0(a4)
    80001f3e:	e708                	sd	a0,8(a4)
    80001f40:	eb0c                	sd	a1,16(a4)
    80001f42:	ef10                	sd	a2,24(a4)
    80001f44:	02078793          	add	a5,a5,32
    80001f48:	02070713          	add	a4,a4,32
    80001f4c:	fed792e3          	bne	a5,a3,80001f30 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f50:	058a3783          	ld	a5,88(s4)
    80001f54:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f58:	0d0a8493          	add	s1,s5,208
    80001f5c:	0d0a0913          	add	s2,s4,208
    80001f60:	150a8993          	add	s3,s5,336
    80001f64:	a00d                	j	80001f86 <fork+0xac>
    freeproc(np);
    80001f66:	8552                	mv	a0,s4
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	d4a080e7          	jalr	-694(ra) # 80001cb2 <freeproc>
    release(&np->lock);
    80001f70:	8552                	mv	a0,s4
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d92080e7          	jalr	-622(ra) # 80000d04 <release>
    return -1;
    80001f7a:	597d                	li	s2,-1
    80001f7c:	a059                	j	80002002 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001f7e:	04a1                	add	s1,s1,8
    80001f80:	0921                	add	s2,s2,8
    80001f82:	01348b63          	beq	s1,s3,80001f98 <fork+0xbe>
    if (p->ofile[i])
    80001f86:	6088                	ld	a0,0(s1)
    80001f88:	d97d                	beqz	a0,80001f7e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f8a:	00003097          	auipc	ra,0x3
    80001f8e:	9f8080e7          	jalr	-1544(ra) # 80004982 <filedup>
    80001f92:	00a93023          	sd	a0,0(s2)
    80001f96:	b7e5                	j	80001f7e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f98:	150ab503          	ld	a0,336(s5)
    80001f9c:	00002097          	auipc	ra,0x2
    80001fa0:	b90080e7          	jalr	-1136(ra) # 80003b2c <idup>
    80001fa4:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fa8:	4641                	li	a2,16
    80001faa:	158a8593          	add	a1,s5,344
    80001fae:	158a0513          	add	a0,s4,344
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ee2080e7          	jalr	-286(ra) # 80000e94 <safestrcpy>
  pid = np->pid;
    80001fba:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fbe:	8552                	mv	a0,s4
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	d44080e7          	jalr	-700(ra) # 80000d04 <release>
  acquire(&wait_lock);
    80001fc8:	0022f497          	auipc	s1,0x22f
    80001fcc:	bb848493          	add	s1,s1,-1096 # 80230b80 <wait_lock>
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	c7e080e7          	jalr	-898(ra) # 80000c50 <acquire>
  np->parent = p;
    80001fda:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	d24080e7          	jalr	-732(ra) # 80000d04 <release>
  acquire(&np->lock);
    80001fe8:	8552                	mv	a0,s4
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	c66080e7          	jalr	-922(ra) # 80000c50 <acquire>
  np->state = RUNNABLE;
    80001ff2:	478d                	li	a5,3
    80001ff4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ff8:	8552                	mv	a0,s4
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	d0a080e7          	jalr	-758(ra) # 80000d04 <release>
}
    80002002:	854a                	mv	a0,s2
    80002004:	70e2                	ld	ra,56(sp)
    80002006:	7442                	ld	s0,48(sp)
    80002008:	74a2                	ld	s1,40(sp)
    8000200a:	7902                	ld	s2,32(sp)
    8000200c:	69e2                	ld	s3,24(sp)
    8000200e:	6a42                	ld	s4,16(sp)
    80002010:	6aa2                	ld	s5,8(sp)
    80002012:	6121                	add	sp,sp,64
    80002014:	8082                	ret
    return -1;
    80002016:	597d                	li	s2,-1
    80002018:	b7ed                	j	80002002 <fork+0x128>

000000008000201a <scheduler>:
{
    8000201a:	7139                	add	sp,sp,-64
    8000201c:	fc06                	sd	ra,56(sp)
    8000201e:	f822                	sd	s0,48(sp)
    80002020:	f426                	sd	s1,40(sp)
    80002022:	f04a                	sd	s2,32(sp)
    80002024:	ec4e                	sd	s3,24(sp)
    80002026:	e852                	sd	s4,16(sp)
    80002028:	e456                	sd	s5,8(sp)
    8000202a:	e05a                	sd	s6,0(sp)
    8000202c:	0080                	add	s0,sp,64
    8000202e:	8792                	mv	a5,tp
  int id = r_tp();
    80002030:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002032:	00779a93          	sll	s5,a5,0x7
    80002036:	0022f717          	auipc	a4,0x22f
    8000203a:	b3270713          	add	a4,a4,-1230 # 80230b68 <pid_lock>
    8000203e:	9756                	add	a4,a4,s5
    80002040:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002044:	0022f717          	auipc	a4,0x22f
    80002048:	b5c70713          	add	a4,a4,-1188 # 80230ba0 <cpus+0x8>
    8000204c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    8000204e:	498d                	li	s3,3
        p->state = RUNNING;
    80002050:	4b11                	li	s6,4
        c->proc = p;
    80002052:	079e                	sll	a5,a5,0x7
    80002054:	0022fa17          	auipc	s4,0x22f
    80002058:	b14a0a13          	add	s4,s4,-1260 # 80230b68 <pid_lock>
    8000205c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000205e:	00235917          	auipc	s2,0x235
    80002062:	f3a90913          	add	s2,s2,-198 # 80236f98 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002066:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000206a:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000206e:	10079073          	csrw	sstatus,a5
    80002072:	0022f497          	auipc	s1,0x22f
    80002076:	f2648493          	add	s1,s1,-218 # 80230f98 <proc>
    8000207a:	a811                	j	8000208e <scheduler+0x74>
      release(&p->lock);
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c86080e7          	jalr	-890(ra) # 80000d04 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002086:	18048493          	add	s1,s1,384
    8000208a:	fd248ee3          	beq	s1,s2,80002066 <scheduler+0x4c>
      acquire(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	bc0080e7          	jalr	-1088(ra) # 80000c50 <acquire>
      if (p->state == RUNNABLE)
    80002098:	4c9c                	lw	a5,24(s1)
    8000209a:	ff3791e3          	bne	a5,s3,8000207c <scheduler+0x62>
        p->state = RUNNING;
    8000209e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020a2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020a6:	06048593          	add	a1,s1,96
    800020aa:	8556                	mv	a0,s5
    800020ac:	00001097          	auipc	ra,0x1
    800020b0:	864080e7          	jalr	-1948(ra) # 80002910 <swtch>
        c->proc = 0;
    800020b4:	020a3823          	sd	zero,48(s4)
    800020b8:	b7d1                	j	8000207c <scheduler+0x62>

00000000800020ba <sched>:
{
    800020ba:	7179                	add	sp,sp,-48
    800020bc:	f406                	sd	ra,40(sp)
    800020be:	f022                	sd	s0,32(sp)
    800020c0:	ec26                	sd	s1,24(sp)
    800020c2:	e84a                	sd	s2,16(sp)
    800020c4:	e44e                	sd	s3,8(sp)
    800020c6:	1800                	add	s0,sp,48
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	a38080e7          	jalr	-1480(ra) # 80001b00 <myproc>
    800020d0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b04080e7          	jalr	-1276(ra) # 80000bd6 <holding>
    800020da:	c93d                	beqz	a0,80002150 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020dc:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020de:	2781                	sext.w	a5,a5
    800020e0:	079e                	sll	a5,a5,0x7
    800020e2:	0022f717          	auipc	a4,0x22f
    800020e6:	a8670713          	add	a4,a4,-1402 # 80230b68 <pid_lock>
    800020ea:	97ba                	add	a5,a5,a4
    800020ec:	0a87a703          	lw	a4,168(a5)
    800020f0:	4785                	li	a5,1
    800020f2:	06f71763          	bne	a4,a5,80002160 <sched+0xa6>
  if (p->state == RUNNING)
    800020f6:	4c98                	lw	a4,24(s1)
    800020f8:	4791                	li	a5,4
    800020fa:	06f70b63          	beq	a4,a5,80002170 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002102:	8b89                	and	a5,a5,2
  if (intr_get())
    80002104:	efb5                	bnez	a5,80002180 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002106:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002108:	0022f917          	auipc	s2,0x22f
    8000210c:	a6090913          	add	s2,s2,-1440 # 80230b68 <pid_lock>
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	sll	a5,a5,0x7
    80002114:	97ca                	add	a5,a5,s2
    80002116:	0ac7a983          	lw	s3,172(a5)
    8000211a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000211c:	2781                	sext.w	a5,a5
    8000211e:	079e                	sll	a5,a5,0x7
    80002120:	0022f597          	auipc	a1,0x22f
    80002124:	a8058593          	add	a1,a1,-1408 # 80230ba0 <cpus+0x8>
    80002128:	95be                	add	a1,a1,a5
    8000212a:	06048513          	add	a0,s1,96
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	7e2080e7          	jalr	2018(ra) # 80002910 <swtch>
    80002136:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002138:	2781                	sext.w	a5,a5
    8000213a:	079e                	sll	a5,a5,0x7
    8000213c:	993e                	add	s2,s2,a5
    8000213e:	0b392623          	sw	s3,172(s2)
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	add	sp,sp,48
    8000214e:	8082                	ret
    panic("sched p->lock");
    80002150:	00006517          	auipc	a0,0x6
    80002154:	0c850513          	add	a0,a0,200 # 80008218 <digits+0x1d8>
    80002158:	ffffe097          	auipc	ra,0xffffe
    8000215c:	3e4080e7          	jalr	996(ra) # 8000053c <panic>
    panic("sched locks");
    80002160:	00006517          	auipc	a0,0x6
    80002164:	0c850513          	add	a0,a0,200 # 80008228 <digits+0x1e8>
    80002168:	ffffe097          	auipc	ra,0xffffe
    8000216c:	3d4080e7          	jalr	980(ra) # 8000053c <panic>
    panic("sched running");
    80002170:	00006517          	auipc	a0,0x6
    80002174:	0c850513          	add	a0,a0,200 # 80008238 <digits+0x1f8>
    80002178:	ffffe097          	auipc	ra,0xffffe
    8000217c:	3c4080e7          	jalr	964(ra) # 8000053c <panic>
    panic("sched interruptible");
    80002180:	00006517          	auipc	a0,0x6
    80002184:	0c850513          	add	a0,a0,200 # 80008248 <digits+0x208>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3b4080e7          	jalr	948(ra) # 8000053c <panic>

0000000080002190 <yield>:
{
    80002190:	1101                	add	sp,sp,-32
    80002192:	ec06                	sd	ra,24(sp)
    80002194:	e822                	sd	s0,16(sp)
    80002196:	e426                	sd	s1,8(sp)
    80002198:	1000                	add	s0,sp,32
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	966080e7          	jalr	-1690(ra) # 80001b00 <myproc>
    800021a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	aac080e7          	jalr	-1364(ra) # 80000c50 <acquire>
  p->state = RUNNABLE;
    800021ac:	478d                	li	a5,3
    800021ae:	cc9c                	sw	a5,24(s1)
  sched();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	f0a080e7          	jalr	-246(ra) # 800020ba <sched>
  release(&p->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b4a080e7          	jalr	-1206(ra) # 80000d04 <release>
}
    800021c2:	60e2                	ld	ra,24(sp)
    800021c4:	6442                	ld	s0,16(sp)
    800021c6:	64a2                	ld	s1,8(sp)
    800021c8:	6105                	add	sp,sp,32
    800021ca:	8082                	ret

00000000800021cc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021cc:	7179                	add	sp,sp,-48
    800021ce:	f406                	sd	ra,40(sp)
    800021d0:	f022                	sd	s0,32(sp)
    800021d2:	ec26                	sd	s1,24(sp)
    800021d4:	e84a                	sd	s2,16(sp)
    800021d6:	e44e                	sd	s3,8(sp)
    800021d8:	1800                	add	s0,sp,48
    800021da:	89aa                	mv	s3,a0
    800021dc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	922080e7          	jalr	-1758(ra) # 80001b00 <myproc>
    800021e6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	a68080e7          	jalr	-1432(ra) # 80000c50 <acquire>
  release(lk);
    800021f0:	854a                	mv	a0,s2
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	b12080e7          	jalr	-1262(ra) # 80000d04 <release>

  // Go to sleep.
  p->chan = chan;
    800021fa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021fe:	4789                	li	a5,2
    80002200:	cc9c                	sw	a5,24(s1)

  sched();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	eb8080e7          	jalr	-328(ra) # 800020ba <sched>

  // Tidy up.
  p->chan = 0;
    8000220a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	af4080e7          	jalr	-1292(ra) # 80000d04 <release>
  acquire(lk);
    80002218:	854a                	mv	a0,s2
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a36080e7          	jalr	-1482(ra) # 80000c50 <acquire>
}
    80002222:	70a2                	ld	ra,40(sp)
    80002224:	7402                	ld	s0,32(sp)
    80002226:	64e2                	ld	s1,24(sp)
    80002228:	6942                	ld	s2,16(sp)
    8000222a:	69a2                	ld	s3,8(sp)
    8000222c:	6145                	add	sp,sp,48
    8000222e:	8082                	ret

0000000080002230 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002230:	7139                	add	sp,sp,-64
    80002232:	fc06                	sd	ra,56(sp)
    80002234:	f822                	sd	s0,48(sp)
    80002236:	f426                	sd	s1,40(sp)
    80002238:	f04a                	sd	s2,32(sp)
    8000223a:	ec4e                	sd	s3,24(sp)
    8000223c:	e852                	sd	s4,16(sp)
    8000223e:	e456                	sd	s5,8(sp)
    80002240:	0080                	add	s0,sp,64
    80002242:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002244:	0022f497          	auipc	s1,0x22f
    80002248:	d5448493          	add	s1,s1,-684 # 80230f98 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000224c:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000224e:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002250:	00235917          	auipc	s2,0x235
    80002254:	d4890913          	add	s2,s2,-696 # 80236f98 <tickslock>
    80002258:	a811                	j	8000226c <wakeup+0x3c>
      }
      release(&p->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	aa8080e7          	jalr	-1368(ra) # 80000d04 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002264:	18048493          	add	s1,s1,384
    80002268:	03248663          	beq	s1,s2,80002294 <wakeup+0x64>
    if (p != myproc())
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	894080e7          	jalr	-1900(ra) # 80001b00 <myproc>
    80002274:	fea488e3          	beq	s1,a0,80002264 <wakeup+0x34>
      acquire(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	9d6080e7          	jalr	-1578(ra) # 80000c50 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002282:	4c9c                	lw	a5,24(s1)
    80002284:	fd379be3          	bne	a5,s3,8000225a <wakeup+0x2a>
    80002288:	709c                	ld	a5,32(s1)
    8000228a:	fd4798e3          	bne	a5,s4,8000225a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000228e:	0154ac23          	sw	s5,24(s1)
    80002292:	b7e1                	j	8000225a <wakeup+0x2a>
    }
  }
}
    80002294:	70e2                	ld	ra,56(sp)
    80002296:	7442                	ld	s0,48(sp)
    80002298:	74a2                	ld	s1,40(sp)
    8000229a:	7902                	ld	s2,32(sp)
    8000229c:	69e2                	ld	s3,24(sp)
    8000229e:	6a42                	ld	s4,16(sp)
    800022a0:	6aa2                	ld	s5,8(sp)
    800022a2:	6121                	add	sp,sp,64
    800022a4:	8082                	ret

00000000800022a6 <reparent>:
{
    800022a6:	7179                	add	sp,sp,-48
    800022a8:	f406                	sd	ra,40(sp)
    800022aa:	f022                	sd	s0,32(sp)
    800022ac:	ec26                	sd	s1,24(sp)
    800022ae:	e84a                	sd	s2,16(sp)
    800022b0:	e44e                	sd	s3,8(sp)
    800022b2:	e052                	sd	s4,0(sp)
    800022b4:	1800                	add	s0,sp,48
    800022b6:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022b8:	0022f497          	auipc	s1,0x22f
    800022bc:	ce048493          	add	s1,s1,-800 # 80230f98 <proc>
      pp->parent = initproc;
    800022c0:	00006a17          	auipc	s4,0x6
    800022c4:	618a0a13          	add	s4,s4,1560 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022c8:	00235997          	auipc	s3,0x235
    800022cc:	cd098993          	add	s3,s3,-816 # 80236f98 <tickslock>
    800022d0:	a029                	j	800022da <reparent+0x34>
    800022d2:	18048493          	add	s1,s1,384
    800022d6:	01348d63          	beq	s1,s3,800022f0 <reparent+0x4a>
    if (pp->parent == p)
    800022da:	7c9c                	ld	a5,56(s1)
    800022dc:	ff279be3          	bne	a5,s2,800022d2 <reparent+0x2c>
      pp->parent = initproc;
    800022e0:	000a3503          	ld	a0,0(s4)
    800022e4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022e6:	00000097          	auipc	ra,0x0
    800022ea:	f4a080e7          	jalr	-182(ra) # 80002230 <wakeup>
    800022ee:	b7d5                	j	800022d2 <reparent+0x2c>
}
    800022f0:	70a2                	ld	ra,40(sp)
    800022f2:	7402                	ld	s0,32(sp)
    800022f4:	64e2                	ld	s1,24(sp)
    800022f6:	6942                	ld	s2,16(sp)
    800022f8:	69a2                	ld	s3,8(sp)
    800022fa:	6a02                	ld	s4,0(sp)
    800022fc:	6145                	add	sp,sp,48
    800022fe:	8082                	ret

0000000080002300 <exit>:
{
    80002300:	7179                	add	sp,sp,-48
    80002302:	f406                	sd	ra,40(sp)
    80002304:	f022                	sd	s0,32(sp)
    80002306:	ec26                	sd	s1,24(sp)
    80002308:	e84a                	sd	s2,16(sp)
    8000230a:	e44e                	sd	s3,8(sp)
    8000230c:	e052                	sd	s4,0(sp)
    8000230e:	1800                	add	s0,sp,48
    80002310:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	7ee080e7          	jalr	2030(ra) # 80001b00 <myproc>
    8000231a:	89aa                	mv	s3,a0
  if (p == initproc)
    8000231c:	00006797          	auipc	a5,0x6
    80002320:	5bc7b783          	ld	a5,1468(a5) # 800088d8 <initproc>
    80002324:	0d050493          	add	s1,a0,208
    80002328:	15050913          	add	s2,a0,336
    8000232c:	02a79363          	bne	a5,a0,80002352 <exit+0x52>
    panic("init exiting");
    80002330:	00006517          	auipc	a0,0x6
    80002334:	f3050513          	add	a0,a0,-208 # 80008260 <digits+0x220>
    80002338:	ffffe097          	auipc	ra,0xffffe
    8000233c:	204080e7          	jalr	516(ra) # 8000053c <panic>
      fileclose(f);
    80002340:	00002097          	auipc	ra,0x2
    80002344:	694080e7          	jalr	1684(ra) # 800049d4 <fileclose>
      p->ofile[fd] = 0;
    80002348:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000234c:	04a1                	add	s1,s1,8
    8000234e:	01248563          	beq	s1,s2,80002358 <exit+0x58>
    if (p->ofile[fd])
    80002352:	6088                	ld	a0,0(s1)
    80002354:	f575                	bnez	a0,80002340 <exit+0x40>
    80002356:	bfdd                	j	8000234c <exit+0x4c>
  begin_op();
    80002358:	00002097          	auipc	ra,0x2
    8000235c:	1b8080e7          	jalr	440(ra) # 80004510 <begin_op>
  iput(p->cwd);
    80002360:	1509b503          	ld	a0,336(s3)
    80002364:	00002097          	auipc	ra,0x2
    80002368:	9c0080e7          	jalr	-1600(ra) # 80003d24 <iput>
  end_op();
    8000236c:	00002097          	auipc	ra,0x2
    80002370:	21e080e7          	jalr	542(ra) # 8000458a <end_op>
  p->cwd = 0;
    80002374:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002378:	0022f497          	auipc	s1,0x22f
    8000237c:	80848493          	add	s1,s1,-2040 # 80230b80 <wait_lock>
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8ce080e7          	jalr	-1842(ra) # 80000c50 <acquire>
  reparent(p);
    8000238a:	854e                	mv	a0,s3
    8000238c:	00000097          	auipc	ra,0x0
    80002390:	f1a080e7          	jalr	-230(ra) # 800022a6 <reparent>
  wakeup(p->parent);
    80002394:	0389b503          	ld	a0,56(s3)
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	e98080e7          	jalr	-360(ra) # 80002230 <wakeup>
  acquire(&p->lock);
    800023a0:	854e                	mv	a0,s3
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	8ae080e7          	jalr	-1874(ra) # 80000c50 <acquire>
  p->xstate = status;
    800023aa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023ae:	4795                	li	a5,5
    800023b0:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800023b4:	00006797          	auipc	a5,0x6
    800023b8:	52c7a783          	lw	a5,1324(a5) # 800088e0 <ticks>
    800023bc:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	942080e7          	jalr	-1726(ra) # 80000d04 <release>
  sched();
    800023ca:	00000097          	auipc	ra,0x0
    800023ce:	cf0080e7          	jalr	-784(ra) # 800020ba <sched>
  panic("zombie exit");
    800023d2:	00006517          	auipc	a0,0x6
    800023d6:	e9e50513          	add	a0,a0,-354 # 80008270 <digits+0x230>
    800023da:	ffffe097          	auipc	ra,0xffffe
    800023de:	162080e7          	jalr	354(ra) # 8000053c <panic>

00000000800023e2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023e2:	7179                	add	sp,sp,-48
    800023e4:	f406                	sd	ra,40(sp)
    800023e6:	f022                	sd	s0,32(sp)
    800023e8:	ec26                	sd	s1,24(sp)
    800023ea:	e84a                	sd	s2,16(sp)
    800023ec:	e44e                	sd	s3,8(sp)
    800023ee:	1800                	add	s0,sp,48
    800023f0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023f2:	0022f497          	auipc	s1,0x22f
    800023f6:	ba648493          	add	s1,s1,-1114 # 80230f98 <proc>
    800023fa:	00235997          	auipc	s3,0x235
    800023fe:	b9e98993          	add	s3,s3,-1122 # 80236f98 <tickslock>
  {
    acquire(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	84c080e7          	jalr	-1972(ra) # 80000c50 <acquire>
    if (p->pid == pid)
    8000240c:	589c                	lw	a5,48(s1)
    8000240e:	01278d63          	beq	a5,s2,80002428 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	8f0080e7          	jalr	-1808(ra) # 80000d04 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000241c:	18048493          	add	s1,s1,384
    80002420:	ff3491e3          	bne	s1,s3,80002402 <kill+0x20>
  }
  return -1;
    80002424:	557d                	li	a0,-1
    80002426:	a829                	j	80002440 <kill+0x5e>
      p->killed = 1;
    80002428:	4785                	li	a5,1
    8000242a:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000242c:	4c98                	lw	a4,24(s1)
    8000242e:	4789                	li	a5,2
    80002430:	00f70f63          	beq	a4,a5,8000244e <kill+0x6c>
      release(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	8ce080e7          	jalr	-1842(ra) # 80000d04 <release>
      return 0;
    8000243e:	4501                	li	a0,0
}
    80002440:	70a2                	ld	ra,40(sp)
    80002442:	7402                	ld	s0,32(sp)
    80002444:	64e2                	ld	s1,24(sp)
    80002446:	6942                	ld	s2,16(sp)
    80002448:	69a2                	ld	s3,8(sp)
    8000244a:	6145                	add	sp,sp,48
    8000244c:	8082                	ret
        p->state = RUNNABLE;
    8000244e:	478d                	li	a5,3
    80002450:	cc9c                	sw	a5,24(s1)
    80002452:	b7cd                	j	80002434 <kill+0x52>

0000000080002454 <setkilled>:

void setkilled(struct proc *p)
{
    80002454:	1101                	add	sp,sp,-32
    80002456:	ec06                	sd	ra,24(sp)
    80002458:	e822                	sd	s0,16(sp)
    8000245a:	e426                	sd	s1,8(sp)
    8000245c:	1000                	add	s0,sp,32
    8000245e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	7f0080e7          	jalr	2032(ra) # 80000c50 <acquire>
  p->killed = 1;
    80002468:	4785                	li	a5,1
    8000246a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000246c:	8526                	mv	a0,s1
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	896080e7          	jalr	-1898(ra) # 80000d04 <release>
}
    80002476:	60e2                	ld	ra,24(sp)
    80002478:	6442                	ld	s0,16(sp)
    8000247a:	64a2                	ld	s1,8(sp)
    8000247c:	6105                	add	sp,sp,32
    8000247e:	8082                	ret

0000000080002480 <killed>:

int killed(struct proc *p)
{
    80002480:	1101                	add	sp,sp,-32
    80002482:	ec06                	sd	ra,24(sp)
    80002484:	e822                	sd	s0,16(sp)
    80002486:	e426                	sd	s1,8(sp)
    80002488:	e04a                	sd	s2,0(sp)
    8000248a:	1000                	add	s0,sp,32
    8000248c:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	7c2080e7          	jalr	1986(ra) # 80000c50 <acquire>
  k = p->killed;
    80002496:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	868080e7          	jalr	-1944(ra) # 80000d04 <release>
  return k;
}
    800024a4:	854a                	mv	a0,s2
    800024a6:	60e2                	ld	ra,24(sp)
    800024a8:	6442                	ld	s0,16(sp)
    800024aa:	64a2                	ld	s1,8(sp)
    800024ac:	6902                	ld	s2,0(sp)
    800024ae:	6105                	add	sp,sp,32
    800024b0:	8082                	ret

00000000800024b2 <wait>:
{
    800024b2:	715d                	add	sp,sp,-80
    800024b4:	e486                	sd	ra,72(sp)
    800024b6:	e0a2                	sd	s0,64(sp)
    800024b8:	fc26                	sd	s1,56(sp)
    800024ba:	f84a                	sd	s2,48(sp)
    800024bc:	f44e                	sd	s3,40(sp)
    800024be:	f052                	sd	s4,32(sp)
    800024c0:	ec56                	sd	s5,24(sp)
    800024c2:	e85a                	sd	s6,16(sp)
    800024c4:	e45e                	sd	s7,8(sp)
    800024c6:	e062                	sd	s8,0(sp)
    800024c8:	0880                	add	s0,sp,80
    800024ca:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	634080e7          	jalr	1588(ra) # 80001b00 <myproc>
    800024d4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024d6:	0022e517          	auipc	a0,0x22e
    800024da:	6aa50513          	add	a0,a0,1706 # 80230b80 <wait_lock>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	772080e7          	jalr	1906(ra) # 80000c50 <acquire>
    havekids = 0;
    800024e6:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024e8:	4a15                	li	s4,5
        havekids = 1;
    800024ea:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024ec:	00235997          	auipc	s3,0x235
    800024f0:	aac98993          	add	s3,s3,-1364 # 80236f98 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024f4:	0022ec17          	auipc	s8,0x22e
    800024f8:	68cc0c13          	add	s8,s8,1676 # 80230b80 <wait_lock>
    800024fc:	a0d1                	j	800025c0 <wait+0x10e>
          pid = pp->pid;
    800024fe:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002502:	000b0e63          	beqz	s6,8000251e <wait+0x6c>
    80002506:	4691                	li	a3,4
    80002508:	02c48613          	add	a2,s1,44
    8000250c:	85da                	mv	a1,s6
    8000250e:	05093503          	ld	a0,80(s2)
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	21c080e7          	jalr	540(ra) # 8000172e <copyout>
    8000251a:	04054163          	bltz	a0,8000255c <wait+0xaa>
          freeproc(pp);
    8000251e:	8526                	mv	a0,s1
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	792080e7          	jalr	1938(ra) # 80001cb2 <freeproc>
          release(&pp->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	7da080e7          	jalr	2010(ra) # 80000d04 <release>
          release(&wait_lock);
    80002532:	0022e517          	auipc	a0,0x22e
    80002536:	64e50513          	add	a0,a0,1614 # 80230b80 <wait_lock>
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	7ca080e7          	jalr	1994(ra) # 80000d04 <release>
}
    80002542:	854e                	mv	a0,s3
    80002544:	60a6                	ld	ra,72(sp)
    80002546:	6406                	ld	s0,64(sp)
    80002548:	74e2                	ld	s1,56(sp)
    8000254a:	7942                	ld	s2,48(sp)
    8000254c:	79a2                	ld	s3,40(sp)
    8000254e:	7a02                	ld	s4,32(sp)
    80002550:	6ae2                	ld	s5,24(sp)
    80002552:	6b42                	ld	s6,16(sp)
    80002554:	6ba2                	ld	s7,8(sp)
    80002556:	6c02                	ld	s8,0(sp)
    80002558:	6161                	add	sp,sp,80
    8000255a:	8082                	ret
            release(&pp->lock);
    8000255c:	8526                	mv	a0,s1
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	7a6080e7          	jalr	1958(ra) # 80000d04 <release>
            release(&wait_lock);
    80002566:	0022e517          	auipc	a0,0x22e
    8000256a:	61a50513          	add	a0,a0,1562 # 80230b80 <wait_lock>
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	796080e7          	jalr	1942(ra) # 80000d04 <release>
            return -1;
    80002576:	59fd                	li	s3,-1
    80002578:	b7e9                	j	80002542 <wait+0x90>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000257a:	18048493          	add	s1,s1,384
    8000257e:	03348463          	beq	s1,s3,800025a6 <wait+0xf4>
      if (pp->parent == p)
    80002582:	7c9c                	ld	a5,56(s1)
    80002584:	ff279be3          	bne	a5,s2,8000257a <wait+0xc8>
        acquire(&pp->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	6c6080e7          	jalr	1734(ra) # 80000c50 <acquire>
        if (pp->state == ZOMBIE)
    80002592:	4c9c                	lw	a5,24(s1)
    80002594:	f74785e3          	beq	a5,s4,800024fe <wait+0x4c>
        release(&pp->lock);
    80002598:	8526                	mv	a0,s1
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	76a080e7          	jalr	1898(ra) # 80000d04 <release>
        havekids = 1;
    800025a2:	8756                	mv	a4,s5
    800025a4:	bfd9                	j	8000257a <wait+0xc8>
    if (!havekids || killed(p))
    800025a6:	c31d                	beqz	a4,800025cc <wait+0x11a>
    800025a8:	854a                	mv	a0,s2
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	ed6080e7          	jalr	-298(ra) # 80002480 <killed>
    800025b2:	ed09                	bnez	a0,800025cc <wait+0x11a>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025b4:	85e2                	mv	a1,s8
    800025b6:	854a                	mv	a0,s2
    800025b8:	00000097          	auipc	ra,0x0
    800025bc:	c14080e7          	jalr	-1004(ra) # 800021cc <sleep>
    havekids = 0;
    800025c0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025c2:	0022f497          	auipc	s1,0x22f
    800025c6:	9d648493          	add	s1,s1,-1578 # 80230f98 <proc>
    800025ca:	bf65                	j	80002582 <wait+0xd0>
      release(&wait_lock);
    800025cc:	0022e517          	auipc	a0,0x22e
    800025d0:	5b450513          	add	a0,a0,1460 # 80230b80 <wait_lock>
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	730080e7          	jalr	1840(ra) # 80000d04 <release>
      return -1;
    800025dc:	59fd                	li	s3,-1
    800025de:	b795                	j	80002542 <wait+0x90>

00000000800025e0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e0:	7179                	add	sp,sp,-48
    800025e2:	f406                	sd	ra,40(sp)
    800025e4:	f022                	sd	s0,32(sp)
    800025e6:	ec26                	sd	s1,24(sp)
    800025e8:	e84a                	sd	s2,16(sp)
    800025ea:	e44e                	sd	s3,8(sp)
    800025ec:	e052                	sd	s4,0(sp)
    800025ee:	1800                	add	s0,sp,48
    800025f0:	84aa                	mv	s1,a0
    800025f2:	892e                	mv	s2,a1
    800025f4:	89b2                	mv	s3,a2
    800025f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	508080e7          	jalr	1288(ra) # 80001b00 <myproc>
  if (user_dst)
    80002600:	c08d                	beqz	s1,80002622 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002602:	86d2                	mv	a3,s4
    80002604:	864e                	mv	a2,s3
    80002606:	85ca                	mv	a1,s2
    80002608:	6928                	ld	a0,80(a0)
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	124080e7          	jalr	292(ra) # 8000172e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002612:	70a2                	ld	ra,40(sp)
    80002614:	7402                	ld	s0,32(sp)
    80002616:	64e2                	ld	s1,24(sp)
    80002618:	6942                	ld	s2,16(sp)
    8000261a:	69a2                	ld	s3,8(sp)
    8000261c:	6a02                	ld	s4,0(sp)
    8000261e:	6145                	add	sp,sp,48
    80002620:	8082                	ret
    memmove((char *)dst, src, len);
    80002622:	000a061b          	sext.w	a2,s4
    80002626:	85ce                	mv	a1,s3
    80002628:	854a                	mv	a0,s2
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	77e080e7          	jalr	1918(ra) # 80000da8 <memmove>
    return 0;
    80002632:	8526                	mv	a0,s1
    80002634:	bff9                	j	80002612 <either_copyout+0x32>

0000000080002636 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002636:	7179                	add	sp,sp,-48
    80002638:	f406                	sd	ra,40(sp)
    8000263a:	f022                	sd	s0,32(sp)
    8000263c:	ec26                	sd	s1,24(sp)
    8000263e:	e84a                	sd	s2,16(sp)
    80002640:	e44e                	sd	s3,8(sp)
    80002642:	e052                	sd	s4,0(sp)
    80002644:	1800                	add	s0,sp,48
    80002646:	892a                	mv	s2,a0
    80002648:	84ae                	mv	s1,a1
    8000264a:	89b2                	mv	s3,a2
    8000264c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	4b2080e7          	jalr	1202(ra) # 80001b00 <myproc>
  if (user_src)
    80002656:	c08d                	beqz	s1,80002678 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002658:	86d2                	mv	a3,s4
    8000265a:	864e                	mv	a2,s3
    8000265c:	85ca                	mv	a1,s2
    8000265e:	6928                	ld	a0,80(a0)
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	1ec080e7          	jalr	492(ra) # 8000184c <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002668:	70a2                	ld	ra,40(sp)
    8000266a:	7402                	ld	s0,32(sp)
    8000266c:	64e2                	ld	s1,24(sp)
    8000266e:	6942                	ld	s2,16(sp)
    80002670:	69a2                	ld	s3,8(sp)
    80002672:	6a02                	ld	s4,0(sp)
    80002674:	6145                	add	sp,sp,48
    80002676:	8082                	ret
    memmove(dst, (char *)src, len);
    80002678:	000a061b          	sext.w	a2,s4
    8000267c:	85ce                	mv	a1,s3
    8000267e:	854a                	mv	a0,s2
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	728080e7          	jalr	1832(ra) # 80000da8 <memmove>
    return 0;
    80002688:	8526                	mv	a0,s1
    8000268a:	bff9                	j	80002668 <either_copyin+0x32>

000000008000268c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000268c:	715d                	add	sp,sp,-80
    8000268e:	e486                	sd	ra,72(sp)
    80002690:	e0a2                	sd	s0,64(sp)
    80002692:	fc26                	sd	s1,56(sp)
    80002694:	f84a                	sd	s2,48(sp)
    80002696:	f44e                	sd	s3,40(sp)
    80002698:	f052                	sd	s4,32(sp)
    8000269a:	ec56                	sd	s5,24(sp)
    8000269c:	e85a                	sd	s6,16(sp)
    8000269e:	e45e                	sd	s7,8(sp)
    800026a0:	0880                	add	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800026a2:	00006517          	auipc	a0,0x6
    800026a6:	a2650513          	add	a0,a0,-1498 # 800080c8 <digits+0x88>
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	edc080e7          	jalr	-292(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026b2:	0022f497          	auipc	s1,0x22f
    800026b6:	a3e48493          	add	s1,s1,-1474 # 802310f0 <proc+0x158>
    800026ba:	00235917          	auipc	s2,0x235
    800026be:	a3690913          	add	s2,s2,-1482 # 802370f0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026c4:	00006997          	auipc	s3,0x6
    800026c8:	bbc98993          	add	s3,s3,-1092 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800026cc:	00006a97          	auipc	s5,0x6
    800026d0:	bbca8a93          	add	s5,s5,-1092 # 80008288 <digits+0x248>
    printf("\n");
    800026d4:	00006a17          	auipc	s4,0x6
    800026d8:	9f4a0a13          	add	s4,s4,-1548 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	00006b97          	auipc	s7,0x6
    800026e0:	becb8b93          	add	s7,s7,-1044 # 800082c8 <states.0>
    800026e4:	a00d                	j	80002706 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026e6:	ed86a583          	lw	a1,-296(a3)
    800026ea:	8556                	mv	a0,s5
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	e9a080e7          	jalr	-358(ra) # 80000586 <printf>
    printf("\n");
    800026f4:	8552                	mv	a0,s4
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	e90080e7          	jalr	-368(ra) # 80000586 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026fe:	18048493          	add	s1,s1,384
    80002702:	03248263          	beq	s1,s2,80002726 <procdump+0x9a>
    if (p->state == UNUSED)
    80002706:	86a6                	mv	a3,s1
    80002708:	ec04a783          	lw	a5,-320(s1)
    8000270c:	dbed                	beqz	a5,800026fe <procdump+0x72>
      state = "???";
    8000270e:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002710:	fcfb6be3          	bltu	s6,a5,800026e6 <procdump+0x5a>
    80002714:	02079713          	sll	a4,a5,0x20
    80002718:	01d75793          	srl	a5,a4,0x1d
    8000271c:	97de                	add	a5,a5,s7
    8000271e:	6390                	ld	a2,0(a5)
    80002720:	f279                	bnez	a2,800026e6 <procdump+0x5a>
      state = "???";
    80002722:	864e                	mv	a2,s3
    80002724:	b7c9                	j	800026e6 <procdump+0x5a>
  }
}
    80002726:	60a6                	ld	ra,72(sp)
    80002728:	6406                	ld	s0,64(sp)
    8000272a:	74e2                	ld	s1,56(sp)
    8000272c:	7942                	ld	s2,48(sp)
    8000272e:	79a2                	ld	s3,40(sp)
    80002730:	7a02                	ld	s4,32(sp)
    80002732:	6ae2                	ld	s5,24(sp)
    80002734:	6b42                	ld	s6,16(sp)
    80002736:	6ba2                	ld	s7,8(sp)
    80002738:	6161                	add	sp,sp,80
    8000273a:	8082                	ret

000000008000273c <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000273c:	711d                	add	sp,sp,-96
    8000273e:	ec86                	sd	ra,88(sp)
    80002740:	e8a2                	sd	s0,80(sp)
    80002742:	e4a6                	sd	s1,72(sp)
    80002744:	e0ca                	sd	s2,64(sp)
    80002746:	fc4e                	sd	s3,56(sp)
    80002748:	f852                	sd	s4,48(sp)
    8000274a:	f456                	sd	s5,40(sp)
    8000274c:	f05a                	sd	s6,32(sp)
    8000274e:	ec5e                	sd	s7,24(sp)
    80002750:	e862                	sd	s8,16(sp)
    80002752:	e466                	sd	s9,8(sp)
    80002754:	e06a                	sd	s10,0(sp)
    80002756:	1080                	add	s0,sp,96
    80002758:	8b2a                	mv	s6,a0
    8000275a:	8bae                	mv	s7,a1
    8000275c:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000275e:	fffff097          	auipc	ra,0xfffff
    80002762:	3a2080e7          	jalr	930(ra) # 80001b00 <myproc>
    80002766:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002768:	0022e517          	auipc	a0,0x22e
    8000276c:	41850513          	add	a0,a0,1048 # 80230b80 <wait_lock>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	4e0080e7          	jalr	1248(ra) # 80000c50 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002778:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000277a:	4a15                	li	s4,5
        havekids = 1;
    8000277c:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000277e:	00235997          	auipc	s3,0x235
    80002782:	81a98993          	add	s3,s3,-2022 # 80236f98 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002786:	0022ed17          	auipc	s10,0x22e
    8000278a:	3fad0d13          	add	s10,s10,1018 # 80230b80 <wait_lock>
    8000278e:	a8e9                	j	80002868 <waitx+0x12c>
          pid = np->pid;
    80002790:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002794:	1684a783          	lw	a5,360(s1)
    80002798:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000279c:	16c4a703          	lw	a4,364(s1)
    800027a0:	9f3d                	addw	a4,a4,a5
    800027a2:	1704a783          	lw	a5,368(s1)
    800027a6:	9f99                	subw	a5,a5,a4
    800027a8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027ac:	000b0e63          	beqz	s6,800027c8 <waitx+0x8c>
    800027b0:	4691                	li	a3,4
    800027b2:	02c48613          	add	a2,s1,44
    800027b6:	85da                	mv	a1,s6
    800027b8:	05093503          	ld	a0,80(s2)
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	f72080e7          	jalr	-142(ra) # 8000172e <copyout>
    800027c4:	04054363          	bltz	a0,8000280a <waitx+0xce>
          freeproc(np);
    800027c8:	8526                	mv	a0,s1
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	4e8080e7          	jalr	1256(ra) # 80001cb2 <freeproc>
          release(&np->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	530080e7          	jalr	1328(ra) # 80000d04 <release>
          release(&wait_lock);
    800027dc:	0022e517          	auipc	a0,0x22e
    800027e0:	3a450513          	add	a0,a0,932 # 80230b80 <wait_lock>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	520080e7          	jalr	1312(ra) # 80000d04 <release>
  }
}
    800027ec:	854e                	mv	a0,s3
    800027ee:	60e6                	ld	ra,88(sp)
    800027f0:	6446                	ld	s0,80(sp)
    800027f2:	64a6                	ld	s1,72(sp)
    800027f4:	6906                	ld	s2,64(sp)
    800027f6:	79e2                	ld	s3,56(sp)
    800027f8:	7a42                	ld	s4,48(sp)
    800027fa:	7aa2                	ld	s5,40(sp)
    800027fc:	7b02                	ld	s6,32(sp)
    800027fe:	6be2                	ld	s7,24(sp)
    80002800:	6c42                	ld	s8,16(sp)
    80002802:	6ca2                	ld	s9,8(sp)
    80002804:	6d02                	ld	s10,0(sp)
    80002806:	6125                	add	sp,sp,96
    80002808:	8082                	ret
            release(&np->lock);
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	4f8080e7          	jalr	1272(ra) # 80000d04 <release>
            release(&wait_lock);
    80002814:	0022e517          	auipc	a0,0x22e
    80002818:	36c50513          	add	a0,a0,876 # 80230b80 <wait_lock>
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	4e8080e7          	jalr	1256(ra) # 80000d04 <release>
            return -1;
    80002824:	59fd                	li	s3,-1
    80002826:	b7d9                	j	800027ec <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002828:	18048493          	add	s1,s1,384
    8000282c:	03348463          	beq	s1,s3,80002854 <waitx+0x118>
      if (np->parent == p)
    80002830:	7c9c                	ld	a5,56(s1)
    80002832:	ff279be3          	bne	a5,s2,80002828 <waitx+0xec>
        acquire(&np->lock);
    80002836:	8526                	mv	a0,s1
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	418080e7          	jalr	1048(ra) # 80000c50 <acquire>
        if (np->state == ZOMBIE)
    80002840:	4c9c                	lw	a5,24(s1)
    80002842:	f54787e3          	beq	a5,s4,80002790 <waitx+0x54>
        release(&np->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	4bc080e7          	jalr	1212(ra) # 80000d04 <release>
        havekids = 1;
    80002850:	8756                	mv	a4,s5
    80002852:	bfd9                	j	80002828 <waitx+0xec>
    if (!havekids || p->killed)
    80002854:	c305                	beqz	a4,80002874 <waitx+0x138>
    80002856:	02892783          	lw	a5,40(s2)
    8000285a:	ef89                	bnez	a5,80002874 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000285c:	85ea                	mv	a1,s10
    8000285e:	854a                	mv	a0,s2
    80002860:	00000097          	auipc	ra,0x0
    80002864:	96c080e7          	jalr	-1684(ra) # 800021cc <sleep>
    havekids = 0;
    80002868:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000286a:	0022e497          	auipc	s1,0x22e
    8000286e:	72e48493          	add	s1,s1,1838 # 80230f98 <proc>
    80002872:	bf7d                	j	80002830 <waitx+0xf4>
      release(&wait_lock);
    80002874:	0022e517          	auipc	a0,0x22e
    80002878:	30c50513          	add	a0,a0,780 # 80230b80 <wait_lock>
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	488080e7          	jalr	1160(ra) # 80000d04 <release>
      return -1;
    80002884:	59fd                	li	s3,-1
    80002886:	b79d                	j	800027ec <waitx+0xb0>

0000000080002888 <update_time>:

void update_time()
{
    80002888:	7139                	add	sp,sp,-64
    8000288a:	fc06                	sd	ra,56(sp)
    8000288c:	f822                	sd	s0,48(sp)
    8000288e:	f426                	sd	s1,40(sp)
    80002890:	f04a                	sd	s2,32(sp)
    80002892:	ec4e                	sd	s3,24(sp)
    80002894:	e852                	sd	s4,16(sp)
    80002896:	e456                	sd	s5,8(sp)
    80002898:	0080                	add	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000289a:	0022e497          	auipc	s1,0x22e
    8000289e:	6fe48493          	add	s1,s1,1790 # 80230f98 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800028a2:	4991                	li	s3,4
    {
      p->rtime++;
    }else if (p->state == RUNNABLE)
    800028a4:	4a0d                	li	s4,3
    {
      p->wtime++;
    }else if (p->state == SLEEPING)
    800028a6:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    800028a8:	00234917          	auipc	s2,0x234
    800028ac:	6f090913          	add	s2,s2,1776 # 80236f98 <tickslock>
    800028b0:	a839                	j	800028ce <update_time+0x46>
      p->rtime++;
    800028b2:	1684a783          	lw	a5,360(s1)
    800028b6:	2785                	addw	a5,a5,1
    800028b8:	16f4a423          	sw	a5,360(s1)
    {
      p->stime++;
    }
    release(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	446080e7          	jalr	1094(ra) # 80000d04 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028c6:	18048493          	add	s1,s1,384
    800028ca:	03248a63          	beq	s1,s2,800028fe <update_time+0x76>
    acquire(&p->lock);
    800028ce:	8526                	mv	a0,s1
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	380080e7          	jalr	896(ra) # 80000c50 <acquire>
    if (p->state == RUNNING)
    800028d8:	4c9c                	lw	a5,24(s1)
    800028da:	fd378ce3          	beq	a5,s3,800028b2 <update_time+0x2a>
    }else if (p->state == RUNNABLE)
    800028de:	01478a63          	beq	a5,s4,800028f2 <update_time+0x6a>
    }else if (p->state == SLEEPING)
    800028e2:	fd579de3          	bne	a5,s5,800028bc <update_time+0x34>
      p->stime++;
    800028e6:	1784a783          	lw	a5,376(s1)
    800028ea:	2785                	addw	a5,a5,1
    800028ec:	16f4ac23          	sw	a5,376(s1)
    800028f0:	b7f1                	j	800028bc <update_time+0x34>
      p->wtime++;
    800028f2:	1744a783          	lw	a5,372(s1)
    800028f6:	2785                	addw	a5,a5,1
    800028f8:	16f4aa23          	sw	a5,372(s1)
    800028fc:	b7c1                	j	800028bc <update_time+0x34>
  }
    800028fe:	70e2                	ld	ra,56(sp)
    80002900:	7442                	ld	s0,48(sp)
    80002902:	74a2                	ld	s1,40(sp)
    80002904:	7902                	ld	s2,32(sp)
    80002906:	69e2                	ld	s3,24(sp)
    80002908:	6a42                	ld	s4,16(sp)
    8000290a:	6aa2                	ld	s5,8(sp)
    8000290c:	6121                	add	sp,sp,64
    8000290e:	8082                	ret

0000000080002910 <swtch>:
    80002910:	00153023          	sd	ra,0(a0)
    80002914:	00253423          	sd	sp,8(a0)
    80002918:	e900                	sd	s0,16(a0)
    8000291a:	ed04                	sd	s1,24(a0)
    8000291c:	03253023          	sd	s2,32(a0)
    80002920:	03353423          	sd	s3,40(a0)
    80002924:	03453823          	sd	s4,48(a0)
    80002928:	03553c23          	sd	s5,56(a0)
    8000292c:	05653023          	sd	s6,64(a0)
    80002930:	05753423          	sd	s7,72(a0)
    80002934:	05853823          	sd	s8,80(a0)
    80002938:	05953c23          	sd	s9,88(a0)
    8000293c:	07a53023          	sd	s10,96(a0)
    80002940:	07b53423          	sd	s11,104(a0)
    80002944:	0005b083          	ld	ra,0(a1)
    80002948:	0085b103          	ld	sp,8(a1)
    8000294c:	6980                	ld	s0,16(a1)
    8000294e:	6d84                	ld	s1,24(a1)
    80002950:	0205b903          	ld	s2,32(a1)
    80002954:	0285b983          	ld	s3,40(a1)
    80002958:	0305ba03          	ld	s4,48(a1)
    8000295c:	0385ba83          	ld	s5,56(a1)
    80002960:	0405bb03          	ld	s6,64(a1)
    80002964:	0485bb83          	ld	s7,72(a1)
    80002968:	0505bc03          	ld	s8,80(a1)
    8000296c:	0585bc83          	ld	s9,88(a1)
    80002970:	0605bd03          	ld	s10,96(a1)
    80002974:	0685bd83          	ld	s11,104(a1)
    80002978:	8082                	ret

000000008000297a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000297a:	1141                	add	sp,sp,-16
    8000297c:	e406                	sd	ra,8(sp)
    8000297e:	e022                	sd	s0,0(sp)
    80002980:	0800                	add	s0,sp,16
  initlock(&tickslock, "time");
    80002982:	00006597          	auipc	a1,0x6
    80002986:	97658593          	add	a1,a1,-1674 # 800082f8 <states.0+0x30>
    8000298a:	00234517          	auipc	a0,0x234
    8000298e:	60e50513          	add	a0,a0,1550 # 80236f98 <tickslock>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	22e080e7          	jalr	558(ra) # 80000bc0 <initlock>
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	add	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029a2:	1141                	add	sp,sp,-16
    800029a4:	e422                	sd	s0,8(sp)
    800029a6:	0800                	add	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a8:	00003797          	auipc	a5,0x3
    800029ac:	67878793          	add	a5,a5,1656 # 80006020 <kernelvec>
    800029b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b4:	6422                	ld	s0,8(sp)
    800029b6:	0141                	add	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <cowhandler>:

int
cowhandler(pagetable_t pagetable, uint64 va)
{
    char *mem;
    if (va >= MAXVA)
    800029ba:	57fd                	li	a5,-1
    800029bc:	83e9                	srl	a5,a5,0x1a
    800029be:	08b7e063          	bltu	a5,a1,80002a3e <cowhandler+0x84>
{
    800029c2:	7179                	add	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	1800                	add	s0,sp,48
      return -1;
    pte_t *pte = walk(pagetable, va, 0);
    800029d0:	4601                	li	a2,0
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	65c080e7          	jalr	1628(ra) # 8000102e <walk>
    800029da:	892a                	mv	s2,a0
    if (pte == 0)
    800029dc:	c13d                	beqz	a0,80002a42 <cowhandler+0x88>
      return -1;
    // check the PTE
    if ((*pte & PTE_RSW) == 0 || (*pte & PTE_U) == 0 || (*pte & PTE_V) == 0) {
    800029de:	611c                	ld	a5,0(a0)
    800029e0:	1117f793          	and	a5,a5,273
    800029e4:	11100713          	li	a4,273
    800029e8:	04e79f63          	bne	a5,a4,80002a46 <cowhandler+0x8c>
      return -1;
    }
    if ((mem = kalloc()) == 0) {
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	13a080e7          	jalr	314(ra) # 80000b26 <kalloc>
    800029f4:	84aa                	mv	s1,a0
    800029f6:	c931                	beqz	a0,80002a4a <cowhandler+0x90>
      return -1;
    }
    // old physical address
    uint64 pa = PTE2PA(*pte);
    800029f8:	00093983          	ld	s3,0(s2)
    800029fc:	00a9d993          	srl	s3,s3,0xa
    80002a00:	09b2                	sll	s3,s3,0xc
    // copy old data to new mem
    memmove((char*)mem, (char*)pa, PGSIZE);
    80002a02:	6605                	lui	a2,0x1
    80002a04:	85ce                	mv	a1,s3
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	3a2080e7          	jalr	930(ra) # 80000da8 <memmove>
    // PAY ATTENTION
    // decrease the reference count of old memory page, because a new page has been allocated
    kfree((void*)pa);
    80002a0e:	854e                	mv	a0,s3
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	fd4080e7          	jalr	-44(ra) # 800009e4 <kfree>
    uint flags = PTE_FLAGS(*pte);
    // set PTE_W to 1, change the address pointed to by PTE to new memory page(mem)
    *pte = (PA2PTE(mem) | flags | PTE_W);
    80002a18:	80b1                	srl	s1,s1,0xc
    80002a1a:	04aa                	sll	s1,s1,0xa
    uint flags = PTE_FLAGS(*pte);
    80002a1c:	00093783          	ld	a5,0(s2)
    *pte = (PA2PTE(mem) | flags | PTE_W);
    80002a20:	2ff7f793          	and	a5,a5,767
    // set PTE_RSW to 0
    *pte &= ~PTE_RSW;
    80002a24:	8fc5                	or	a5,a5,s1
    80002a26:	0047e793          	or	a5,a5,4
    80002a2a:	00f93023          	sd	a5,0(s2)
    return 0;
    80002a2e:	4501                	li	a0,0
}
    80002a30:	70a2                	ld	ra,40(sp)
    80002a32:	7402                	ld	s0,32(sp)
    80002a34:	64e2                	ld	s1,24(sp)
    80002a36:	6942                	ld	s2,16(sp)
    80002a38:	69a2                	ld	s3,8(sp)
    80002a3a:	6145                	add	sp,sp,48
    80002a3c:	8082                	ret
      return -1;
    80002a3e:	557d                	li	a0,-1
}
    80002a40:	8082                	ret
      return -1;
    80002a42:	557d                	li	a0,-1
    80002a44:	b7f5                	j	80002a30 <cowhandler+0x76>
      return -1;
    80002a46:	557d                	li	a0,-1
    80002a48:	b7e5                	j	80002a30 <cowhandler+0x76>
      return -1;
    80002a4a:	557d                	li	a0,-1
    80002a4c:	b7d5                	j	80002a30 <cowhandler+0x76>

0000000080002a4e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a4e:	1141                	add	sp,sp,-16
    80002a50:	e406                	sd	ra,8(sp)
    80002a52:	e022                	sd	s0,0(sp)
    80002a54:	0800                	add	s0,sp,16
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	0aa080e7          	jalr	170(ra) # 80001b00 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a62:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a64:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a68:	00004697          	auipc	a3,0x4
    80002a6c:	59868693          	add	a3,a3,1432 # 80007000 <_trampoline>
    80002a70:	00004717          	auipc	a4,0x4
    80002a74:	59070713          	add	a4,a4,1424 # 80007000 <_trampoline>
    80002a78:	8f15                	sub	a4,a4,a3
    80002a7a:	040007b7          	lui	a5,0x4000
    80002a7e:	17fd                	add	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002a80:	07b2                	sll	a5,a5,0xc
    80002a82:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a84:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a88:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a8a:	18002673          	csrr	a2,satp
    80002a8e:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a90:	6d30                	ld	a2,88(a0)
    80002a92:	6138                	ld	a4,64(a0)
    80002a94:	6585                	lui	a1,0x1
    80002a96:	972e                	add	a4,a4,a1
    80002a98:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a9a:	6d38                	ld	a4,88(a0)
    80002a9c:	00000617          	auipc	a2,0x0
    80002aa0:	13460613          	add	a2,a2,308 # 80002bd0 <usertrap>
    80002aa4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002aa6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002aa8:	8612                	mv	a2,tp
    80002aaa:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aac:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ab0:	eff77713          	and	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ab4:	02076713          	or	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002abc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002abe:	6f18                	ld	a4,24(a4)
    80002ac0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ac4:	6928                	ld	a0,80(a0)
    80002ac6:	8131                	srl	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002ac8:	00004717          	auipc	a4,0x4
    80002acc:	5d470713          	add	a4,a4,1492 # 8000709c <userret>
    80002ad0:	8f15                	sub	a4,a4,a3
    80002ad2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ad4:	577d                	li	a4,-1
    80002ad6:	177e                	sll	a4,a4,0x3f
    80002ad8:	8d59                	or	a0,a0,a4
    80002ada:	9782                	jalr	a5
}
    80002adc:	60a2                	ld	ra,8(sp)
    80002ade:	6402                	ld	s0,0(sp)
    80002ae0:	0141                	add	sp,sp,16
    80002ae2:	8082                	ret

0000000080002ae4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ae4:	1101                	add	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	1000                	add	s0,sp,32
  acquire(&tickslock);
    80002aee:	00234497          	auipc	s1,0x234
    80002af2:	4aa48493          	add	s1,s1,1194 # 80236f98 <tickslock>
    80002af6:	8526                	mv	a0,s1
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	158080e7          	jalr	344(ra) # 80000c50 <acquire>
  ticks++;
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	de050513          	add	a0,a0,-544 # 800088e0 <ticks>
    80002b08:	411c                	lw	a5,0(a0)
    80002b0a:	2785                	addw	a5,a5,1
    80002b0c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	722080e7          	jalr	1826(ra) # 80002230 <wakeup>
  release(&tickslock);
    80002b16:	8526                	mv	a0,s1
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	1ec080e7          	jalr	492(ra) # 80000d04 <release>
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6105                	add	sp,sp,32
    80002b28:	8082                	ret

0000000080002b2a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b2a:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b2e:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002b30:	0807df63          	bgez	a5,80002bce <devintr+0xa4>
{
    80002b34:	1101                	add	sp,sp,-32
    80002b36:	ec06                	sd	ra,24(sp)
    80002b38:	e822                	sd	s0,16(sp)
    80002b3a:	e426                	sd	s1,8(sp)
    80002b3c:	1000                	add	s0,sp,32
     (scause & 0xff) == 9){
    80002b3e:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002b42:	46a5                	li	a3,9
    80002b44:	00d70d63          	beq	a4,a3,80002b5e <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002b48:	577d                	li	a4,-1
    80002b4a:	177e                	sll	a4,a4,0x3f
    80002b4c:	0705                	add	a4,a4,1
    return 0;
    80002b4e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b50:	04e78e63          	beq	a5,a4,80002bac <devintr+0x82>
  }
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6105                	add	sp,sp,32
    80002b5c:	8082                	ret
    int irq = plic_claim();
    80002b5e:	00003097          	auipc	ra,0x3
    80002b62:	5ca080e7          	jalr	1482(ra) # 80006128 <plic_claim>
    80002b66:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b68:	47a9                	li	a5,10
    80002b6a:	02f50763          	beq	a0,a5,80002b98 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002b6e:	4785                	li	a5,1
    80002b70:	02f50963          	beq	a0,a5,80002ba2 <devintr+0x78>
    return 1;
    80002b74:	4505                	li	a0,1
    } else if(irq){
    80002b76:	dcf9                	beqz	s1,80002b54 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b78:	85a6                	mv	a1,s1
    80002b7a:	00005517          	auipc	a0,0x5
    80002b7e:	78650513          	add	a0,a0,1926 # 80008300 <states.0+0x38>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a04080e7          	jalr	-1532(ra) # 80000586 <printf>
      plic_complete(irq);
    80002b8a:	8526                	mv	a0,s1
    80002b8c:	00003097          	auipc	ra,0x3
    80002b90:	5c0080e7          	jalr	1472(ra) # 8000614c <plic_complete>
    return 1;
    80002b94:	4505                	li	a0,1
    80002b96:	bf7d                	j	80002b54 <devintr+0x2a>
      uartintr();
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	dfc080e7          	jalr	-516(ra) # 80000994 <uartintr>
    if(irq)
    80002ba0:	b7ed                	j	80002b8a <devintr+0x60>
      virtio_disk_intr();
    80002ba2:	00004097          	auipc	ra,0x4
    80002ba6:	a70080e7          	jalr	-1424(ra) # 80006612 <virtio_disk_intr>
    if(irq)
    80002baa:	b7c5                	j	80002b8a <devintr+0x60>
    if(cpuid() == 0){
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	f28080e7          	jalr	-216(ra) # 80001ad4 <cpuid>
    80002bb4:	c901                	beqz	a0,80002bc4 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bb6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bba:	9bf5                	and	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bbc:	14479073          	csrw	sip,a5
    return 2;
    80002bc0:	4509                	li	a0,2
    80002bc2:	bf49                	j	80002b54 <devintr+0x2a>
      clockintr();
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	f20080e7          	jalr	-224(ra) # 80002ae4 <clockintr>
    80002bcc:	b7ed                	j	80002bb6 <devintr+0x8c>
    80002bce:	8082                	ret

0000000080002bd0 <usertrap>:
{
    80002bd0:	1101                	add	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	e04a                	sd	s2,0(sp)
    80002bda:	1000                	add	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002be0:	1007f793          	and	a5,a5,256
    80002be4:	ebad                	bnez	a5,80002c56 <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be6:	00003797          	auipc	a5,0x3
    80002bea:	43a78793          	add	a5,a5,1082 # 80006020 <kernelvec>
    80002bee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	f0e080e7          	jalr	-242(ra) # 80001b00 <myproc>
    80002bfa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bfc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bfe:	14102773          	csrr	a4,sepc
    80002c02:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c04:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c08:	47a1                	li	a5,8
    80002c0a:	04f70e63          	beq	a4,a5,80002c66 <usertrap+0x96>
    80002c0e:	14202773          	csrr	a4,scause
  else if (r_scause() == 15) {
    80002c12:	47bd                	li	a5,15
    80002c14:	08f71363          	bne	a4,a5,80002c9a <usertrap+0xca>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c18:	143025f3          	csrr	a1,stval
    if (va >= p->sz)
    80002c1c:	653c                	ld	a5,72(a0)
    80002c1e:	00f5e463          	bltu	a1,a5,80002c26 <usertrap+0x56>
      p->killed = 1;
    80002c22:	4785                	li	a5,1
    80002c24:	d51c                	sw	a5,40(a0)
    int ret = cowhandler(p->pagetable, va);
    80002c26:	68a8                	ld	a0,80(s1)
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	d92080e7          	jalr	-622(ra) # 800029ba <cowhandler>
    if (ret != 0)
    80002c30:	c119                	beqz	a0,80002c36 <usertrap+0x66>
      p->killed = 1;
    80002c32:	4785                	li	a5,1
    80002c34:	d49c                	sw	a5,40(s1)
  if(killed(p))
    80002c36:	8526                	mv	a0,s1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	848080e7          	jalr	-1976(ra) # 80002480 <killed>
    80002c40:	e55d                	bnez	a0,80002cee <usertrap+0x11e>
  usertrapret();
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	e0c080e7          	jalr	-500(ra) # 80002a4e <usertrapret>
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6902                	ld	s2,0(sp)
    80002c52:	6105                	add	sp,sp,32
    80002c54:	8082                	ret
    panic("usertrap: not from user mode");
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	6ca50513          	add	a0,a0,1738 # 80008320 <states.0+0x58>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	8de080e7          	jalr	-1826(ra) # 8000053c <panic>
    if(killed(p))
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	81a080e7          	jalr	-2022(ra) # 80002480 <killed>
    80002c6e:	e105                	bnez	a0,80002c8e <usertrap+0xbe>
    p->trapframe->epc += 4;
    80002c70:	6cb8                	ld	a4,88(s1)
    80002c72:	6f1c                	ld	a5,24(a4)
    80002c74:	0791                	add	a5,a5,4
    80002c76:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c7c:	0027e793          	or	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c80:	10079073          	csrw	sstatus,a5
    syscall();
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	2d0080e7          	jalr	720(ra) # 80002f54 <syscall>
    80002c8c:	b76d                	j	80002c36 <usertrap+0x66>
      exit(-1);
    80002c8e:	557d                	li	a0,-1
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	670080e7          	jalr	1648(ra) # 80002300 <exit>
    80002c98:	bfe1                	j	80002c70 <usertrap+0xa0>
  } else if((which_dev = devintr()) != 0){
    80002c9a:	00000097          	auipc	ra,0x0
    80002c9e:	e90080e7          	jalr	-368(ra) # 80002b2a <devintr>
    80002ca2:	892a                	mv	s2,a0
    80002ca4:	c901                	beqz	a0,80002cb4 <usertrap+0xe4>
  if(killed(p))
    80002ca6:	8526                	mv	a0,s1
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	7d8080e7          	jalr	2008(ra) # 80002480 <killed>
    80002cb0:	c529                	beqz	a0,80002cfa <usertrap+0x12a>
    80002cb2:	a83d                	j	80002cf0 <usertrap+0x120>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cb8:	5890                	lw	a2,48(s1)
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	68650513          	add	a0,a0,1670 # 80008340 <states.0+0x78>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c4080e7          	jalr	-1852(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cce:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	69e50513          	add	a0,a0,1694 # 80008370 <states.0+0xa8>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	8ac080e7          	jalr	-1876(ra) # 80000586 <printf>
    setkilled(p);
    80002ce2:	8526                	mv	a0,s1
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	770080e7          	jalr	1904(ra) # 80002454 <setkilled>
    80002cec:	b7a9                	j	80002c36 <usertrap+0x66>
  if(killed(p))
    80002cee:	4901                	li	s2,0
    exit(-1);
    80002cf0:	557d                	li	a0,-1
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	60e080e7          	jalr	1550(ra) # 80002300 <exit>
  if(which_dev == 2)
    80002cfa:	4789                	li	a5,2
    80002cfc:	f4f913e3          	bne	s2,a5,80002c42 <usertrap+0x72>
    yield();
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	490080e7          	jalr	1168(ra) # 80002190 <yield>
    80002d08:	bf2d                	j	80002c42 <usertrap+0x72>

0000000080002d0a <kerneltrap>:
{
    80002d0a:	7179                	add	sp,sp,-48
    80002d0c:	f406                	sd	ra,40(sp)
    80002d0e:	f022                	sd	s0,32(sp)
    80002d10:	ec26                	sd	s1,24(sp)
    80002d12:	e84a                	sd	s2,16(sp)
    80002d14:	e44e                	sd	s3,8(sp)
    80002d16:	1800                	add	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d18:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d20:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d24:	1004f793          	and	a5,s1,256
    80002d28:	cb85                	beqz	a5,80002d58 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d2a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d2e:	8b89                	and	a5,a5,2
  if(intr_get() != 0)
    80002d30:	ef85                	bnez	a5,80002d68 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	df8080e7          	jalr	-520(ra) # 80002b2a <devintr>
    80002d3a:	cd1d                	beqz	a0,80002d78 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d3c:	4789                	li	a5,2
    80002d3e:	06f50a63          	beq	a0,a5,80002db2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d42:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d46:	10049073          	csrw	sstatus,s1
}
    80002d4a:	70a2                	ld	ra,40(sp)
    80002d4c:	7402                	ld	s0,32(sp)
    80002d4e:	64e2                	ld	s1,24(sp)
    80002d50:	6942                	ld	s2,16(sp)
    80002d52:	69a2                	ld	s3,8(sp)
    80002d54:	6145                	add	sp,sp,48
    80002d56:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d58:	00005517          	auipc	a0,0x5
    80002d5c:	63850513          	add	a0,a0,1592 # 80008390 <states.0+0xc8>
    80002d60:	ffffd097          	auipc	ra,0xffffd
    80002d64:	7dc080e7          	jalr	2012(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	65050513          	add	a0,a0,1616 # 800083b8 <states.0+0xf0>
    80002d70:	ffffd097          	auipc	ra,0xffffd
    80002d74:	7cc080e7          	jalr	1996(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002d78:	85ce                	mv	a1,s3
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	65e50513          	add	a0,a0,1630 # 800083d8 <states.0+0x110>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	804080e7          	jalr	-2044(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d8e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d92:	00005517          	auipc	a0,0x5
    80002d96:	65650513          	add	a0,a0,1622 # 800083e8 <states.0+0x120>
    80002d9a:	ffffd097          	auipc	ra,0xffffd
    80002d9e:	7ec080e7          	jalr	2028(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002da2:	00005517          	auipc	a0,0x5
    80002da6:	65e50513          	add	a0,a0,1630 # 80008400 <states.0+0x138>
    80002daa:	ffffd097          	auipc	ra,0xffffd
    80002dae:	792080e7          	jalr	1938(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	d4e080e7          	jalr	-690(ra) # 80001b00 <myproc>
    80002dba:	d541                	beqz	a0,80002d42 <kerneltrap+0x38>
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	d44080e7          	jalr	-700(ra) # 80001b00 <myproc>
    80002dc4:	4d18                	lw	a4,24(a0)
    80002dc6:	4791                	li	a5,4
    80002dc8:	f6f71de3          	bne	a4,a5,80002d42 <kerneltrap+0x38>
    yield();
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	3c4080e7          	jalr	964(ra) # 80002190 <yield>
    80002dd4:	b7bd                	j	80002d42 <kerneltrap+0x38>

0000000080002dd6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002dd6:	1101                	add	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	1000                	add	s0,sp,32
    80002de0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	d1e080e7          	jalr	-738(ra) # 80001b00 <myproc>
  switch (n) {
    80002dea:	4795                	li	a5,5
    80002dec:	0497e163          	bltu	a5,s1,80002e2e <argraw+0x58>
    80002df0:	048a                	sll	s1,s1,0x2
    80002df2:	00005717          	auipc	a4,0x5
    80002df6:	64670713          	add	a4,a4,1606 # 80008438 <states.0+0x170>
    80002dfa:	94ba                	add	s1,s1,a4
    80002dfc:	409c                	lw	a5,0(s1)
    80002dfe:	97ba                	add	a5,a5,a4
    80002e00:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e02:	6d3c                	ld	a5,88(a0)
    80002e04:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e06:	60e2                	ld	ra,24(sp)
    80002e08:	6442                	ld	s0,16(sp)
    80002e0a:	64a2                	ld	s1,8(sp)
    80002e0c:	6105                	add	sp,sp,32
    80002e0e:	8082                	ret
    return p->trapframe->a1;
    80002e10:	6d3c                	ld	a5,88(a0)
    80002e12:	7fa8                	ld	a0,120(a5)
    80002e14:	bfcd                	j	80002e06 <argraw+0x30>
    return p->trapframe->a2;
    80002e16:	6d3c                	ld	a5,88(a0)
    80002e18:	63c8                	ld	a0,128(a5)
    80002e1a:	b7f5                	j	80002e06 <argraw+0x30>
    return p->trapframe->a3;
    80002e1c:	6d3c                	ld	a5,88(a0)
    80002e1e:	67c8                	ld	a0,136(a5)
    80002e20:	b7dd                	j	80002e06 <argraw+0x30>
    return p->trapframe->a4;
    80002e22:	6d3c                	ld	a5,88(a0)
    80002e24:	6bc8                	ld	a0,144(a5)
    80002e26:	b7c5                	j	80002e06 <argraw+0x30>
    return p->trapframe->a5;
    80002e28:	6d3c                	ld	a5,88(a0)
    80002e2a:	6fc8                	ld	a0,152(a5)
    80002e2c:	bfe9                	j	80002e06 <argraw+0x30>
  panic("argraw");
    80002e2e:	00005517          	auipc	a0,0x5
    80002e32:	5e250513          	add	a0,a0,1506 # 80008410 <states.0+0x148>
    80002e36:	ffffd097          	auipc	ra,0xffffd
    80002e3a:	706080e7          	jalr	1798(ra) # 8000053c <panic>

0000000080002e3e <fetchaddr>:
{
    80002e3e:	1101                	add	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	add	s0,sp,32
    80002e4a:	84aa                	mv	s1,a0
    80002e4c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	cb2080e7          	jalr	-846(ra) # 80001b00 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e56:	653c                	ld	a5,72(a0)
    80002e58:	02f4f863          	bgeu	s1,a5,80002e88 <fetchaddr+0x4a>
    80002e5c:	00848713          	add	a4,s1,8
    80002e60:	02e7e663          	bltu	a5,a4,80002e8c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e64:	46a1                	li	a3,8
    80002e66:	8626                	mv	a2,s1
    80002e68:	85ca                	mv	a1,s2
    80002e6a:	6928                	ld	a0,80(a0)
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	9e0080e7          	jalr	-1568(ra) # 8000184c <copyin>
    80002e74:	00a03533          	snez	a0,a0
    80002e78:	40a00533          	neg	a0,a0
}
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6902                	ld	s2,0(sp)
    80002e84:	6105                	add	sp,sp,32
    80002e86:	8082                	ret
    return -1;
    80002e88:	557d                	li	a0,-1
    80002e8a:	bfcd                	j	80002e7c <fetchaddr+0x3e>
    80002e8c:	557d                	li	a0,-1
    80002e8e:	b7fd                	j	80002e7c <fetchaddr+0x3e>

0000000080002e90 <fetchstr>:
{
    80002e90:	7179                	add	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	1800                	add	s0,sp,48
    80002e9e:	892a                	mv	s2,a0
    80002ea0:	84ae                	mv	s1,a1
    80002ea2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	c5c080e7          	jalr	-932(ra) # 80001b00 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002eac:	86ce                	mv	a3,s3
    80002eae:	864a                	mv	a2,s2
    80002eb0:	85a6                	mv	a1,s1
    80002eb2:	6928                	ld	a0,80(a0)
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	a26080e7          	jalr	-1498(ra) # 800018da <copyinstr>
    80002ebc:	00054e63          	bltz	a0,80002ed8 <fetchstr+0x48>
  return strlen(buf);
    80002ec0:	8526                	mv	a0,s1
    80002ec2:	ffffe097          	auipc	ra,0xffffe
    80002ec6:	004080e7          	jalr	4(ra) # 80000ec6 <strlen>
}
    80002eca:	70a2                	ld	ra,40(sp)
    80002ecc:	7402                	ld	s0,32(sp)
    80002ece:	64e2                	ld	s1,24(sp)
    80002ed0:	6942                	ld	s2,16(sp)
    80002ed2:	69a2                	ld	s3,8(sp)
    80002ed4:	6145                	add	sp,sp,48
    80002ed6:	8082                	ret
    return -1;
    80002ed8:	557d                	li	a0,-1
    80002eda:	bfc5                	j	80002eca <fetchstr+0x3a>

0000000080002edc <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002edc:	1101                	add	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	1000                	add	s0,sp,32
    80002ee6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	eee080e7          	jalr	-274(ra) # 80002dd6 <argraw>
    80002ef0:	c088                	sw	a0,0(s1)
}
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	64a2                	ld	s1,8(sp)
    80002ef8:	6105                	add	sp,sp,32
    80002efa:	8082                	ret

0000000080002efc <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002efc:	1101                	add	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	add	s0,sp,32
    80002f06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	ece080e7          	jalr	-306(ra) # 80002dd6 <argraw>
    80002f10:	e088                	sd	a0,0(s1)
}
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	64a2                	ld	s1,8(sp)
    80002f18:	6105                	add	sp,sp,32
    80002f1a:	8082                	ret

0000000080002f1c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f1c:	7179                	add	sp,sp,-48
    80002f1e:	f406                	sd	ra,40(sp)
    80002f20:	f022                	sd	s0,32(sp)
    80002f22:	ec26                	sd	s1,24(sp)
    80002f24:	e84a                	sd	s2,16(sp)
    80002f26:	1800                	add	s0,sp,48
    80002f28:	84ae                	mv	s1,a1
    80002f2a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f2c:	fd840593          	add	a1,s0,-40
    80002f30:	00000097          	auipc	ra,0x0
    80002f34:	fcc080e7          	jalr	-52(ra) # 80002efc <argaddr>
  return fetchstr(addr, buf, max);
    80002f38:	864a                	mv	a2,s2
    80002f3a:	85a6                	mv	a1,s1
    80002f3c:	fd843503          	ld	a0,-40(s0)
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	f50080e7          	jalr	-176(ra) # 80002e90 <fetchstr>
}
    80002f48:	70a2                	ld	ra,40(sp)
    80002f4a:	7402                	ld	s0,32(sp)
    80002f4c:	64e2                	ld	s1,24(sp)
    80002f4e:	6942                	ld	s2,16(sp)
    80002f50:	6145                	add	sp,sp,48
    80002f52:	8082                	ret

0000000080002f54 <syscall>:
[SYS_setpriority] sys_setpriority,
};

void
syscall(void)
{
    80002f54:	1101                	add	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	e426                	sd	s1,8(sp)
    80002f5c:	e04a                	sd	s2,0(sp)
    80002f5e:	1000                	add	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	ba0080e7          	jalr	-1120(ra) # 80001b00 <myproc>
    80002f68:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f6a:	05853903          	ld	s2,88(a0)
    80002f6e:	0a893783          	ld	a5,168(s2)
    80002f72:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f76:	37fd                	addw	a5,a5,-1
    80002f78:	475d                	li	a4,23
    80002f7a:	00f76f63          	bltu	a4,a5,80002f98 <syscall+0x44>
    80002f7e:	00369713          	sll	a4,a3,0x3
    80002f82:	00005797          	auipc	a5,0x5
    80002f86:	4ce78793          	add	a5,a5,1230 # 80008450 <syscalls>
    80002f8a:	97ba                	add	a5,a5,a4
    80002f8c:	639c                	ld	a5,0(a5)
    80002f8e:	c789                	beqz	a5,80002f98 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f90:	9782                	jalr	a5
    80002f92:	06a93823          	sd	a0,112(s2)
    80002f96:	a839                	j	80002fb4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f98:	15848613          	add	a2,s1,344
    80002f9c:	588c                	lw	a1,48(s1)
    80002f9e:	00005517          	auipc	a0,0x5
    80002fa2:	47a50513          	add	a0,a0,1146 # 80008418 <states.0+0x150>
    80002fa6:	ffffd097          	auipc	ra,0xffffd
    80002faa:	5e0080e7          	jalr	1504(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fae:	6cbc                	ld	a5,88(s1)
    80002fb0:	577d                	li	a4,-1
    80002fb2:	fbb8                	sd	a4,112(a5)
  }
}
    80002fb4:	60e2                	ld	ra,24(sp)
    80002fb6:	6442                	ld	s0,16(sp)
    80002fb8:	64a2                	ld	s1,8(sp)
    80002fba:	6902                	ld	s2,0(sp)
    80002fbc:	6105                	add	sp,sp,32
    80002fbe:	8082                	ret

0000000080002fc0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fc0:	1101                	add	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	1000                	add	s0,sp,32
  int n;
  argint(0, &n);
    80002fc8:	fec40593          	add	a1,s0,-20
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	f0e080e7          	jalr	-242(ra) # 80002edc <argint>
  exit(n);
    80002fd6:	fec42503          	lw	a0,-20(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	326080e7          	jalr	806(ra) # 80002300 <exit>
  return 0; // not reached
}
    80002fe2:	4501                	li	a0,0
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	6105                	add	sp,sp,32
    80002fea:	8082                	ret

0000000080002fec <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fec:	1141                	add	sp,sp,-16
    80002fee:	e406                	sd	ra,8(sp)
    80002ff0:	e022                	sd	s0,0(sp)
    80002ff2:	0800                	add	s0,sp,16
  return myproc()->pid;
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	b0c080e7          	jalr	-1268(ra) # 80001b00 <myproc>
}
    80002ffc:	5908                	lw	a0,48(a0)
    80002ffe:	60a2                	ld	ra,8(sp)
    80003000:	6402                	ld	s0,0(sp)
    80003002:	0141                	add	sp,sp,16
    80003004:	8082                	ret

0000000080003006 <sys_fork>:

uint64
sys_fork(void)
{
    80003006:	1141                	add	sp,sp,-16
    80003008:	e406                	sd	ra,8(sp)
    8000300a:	e022                	sd	s0,0(sp)
    8000300c:	0800                	add	s0,sp,16
  return fork();
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	ecc080e7          	jalr	-308(ra) # 80001eda <fork>
}
    80003016:	60a2                	ld	ra,8(sp)
    80003018:	6402                	ld	s0,0(sp)
    8000301a:	0141                	add	sp,sp,16
    8000301c:	8082                	ret

000000008000301e <sys_wait>:

uint64
sys_wait(void)
{
    8000301e:	1101                	add	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	1000                	add	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003026:	fe840593          	add	a1,s0,-24
    8000302a:	4501                	li	a0,0
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	ed0080e7          	jalr	-304(ra) # 80002efc <argaddr>
  return wait(p);
    80003034:	fe843503          	ld	a0,-24(s0)
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	47a080e7          	jalr	1146(ra) # 800024b2 <wait>
}
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	6105                	add	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003048:	7179                	add	sp,sp,-48
    8000304a:	f406                	sd	ra,40(sp)
    8000304c:	f022                	sd	s0,32(sp)
    8000304e:	ec26                	sd	s1,24(sp)
    80003050:	1800                	add	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003052:	fdc40593          	add	a1,s0,-36
    80003056:	4501                	li	a0,0
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	e84080e7          	jalr	-380(ra) # 80002edc <argint>
  addr = myproc()->sz;
    80003060:	fffff097          	auipc	ra,0xfffff
    80003064:	aa0080e7          	jalr	-1376(ra) # 80001b00 <myproc>
    80003068:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000306a:	fdc42503          	lw	a0,-36(s0)
    8000306e:	fffff097          	auipc	ra,0xfffff
    80003072:	e10080e7          	jalr	-496(ra) # 80001e7e <growproc>
    80003076:	00054863          	bltz	a0,80003086 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000307a:	8526                	mv	a0,s1
    8000307c:	70a2                	ld	ra,40(sp)
    8000307e:	7402                	ld	s0,32(sp)
    80003080:	64e2                	ld	s1,24(sp)
    80003082:	6145                	add	sp,sp,48
    80003084:	8082                	ret
    return -1;
    80003086:	54fd                	li	s1,-1
    80003088:	bfcd                	j	8000307a <sys_sbrk+0x32>

000000008000308a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000308a:	7139                	add	sp,sp,-64
    8000308c:	fc06                	sd	ra,56(sp)
    8000308e:	f822                	sd	s0,48(sp)
    80003090:	f426                	sd	s1,40(sp)
    80003092:	f04a                	sd	s2,32(sp)
    80003094:	ec4e                	sd	s3,24(sp)
    80003096:	0080                	add	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003098:	fcc40593          	add	a1,s0,-52
    8000309c:	4501                	li	a0,0
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	e3e080e7          	jalr	-450(ra) # 80002edc <argint>
  acquire(&tickslock);
    800030a6:	00234517          	auipc	a0,0x234
    800030aa:	ef250513          	add	a0,a0,-270 # 80236f98 <tickslock>
    800030ae:	ffffe097          	auipc	ra,0xffffe
    800030b2:	ba2080e7          	jalr	-1118(ra) # 80000c50 <acquire>
  ticks0 = ticks;
    800030b6:	00006917          	auipc	s2,0x6
    800030ba:	82a92903          	lw	s2,-2006(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    800030be:	fcc42783          	lw	a5,-52(s0)
    800030c2:	cf9d                	beqz	a5,80003100 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030c4:	00234997          	auipc	s3,0x234
    800030c8:	ed498993          	add	s3,s3,-300 # 80236f98 <tickslock>
    800030cc:	00006497          	auipc	s1,0x6
    800030d0:	81448493          	add	s1,s1,-2028 # 800088e0 <ticks>
    if (killed(myproc()))
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	a2c080e7          	jalr	-1492(ra) # 80001b00 <myproc>
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	3a4080e7          	jalr	932(ra) # 80002480 <killed>
    800030e4:	ed15                	bnez	a0,80003120 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800030e6:	85ce                	mv	a1,s3
    800030e8:	8526                	mv	a0,s1
    800030ea:	fffff097          	auipc	ra,0xfffff
    800030ee:	0e2080e7          	jalr	226(ra) # 800021cc <sleep>
  while (ticks - ticks0 < n)
    800030f2:	409c                	lw	a5,0(s1)
    800030f4:	412787bb          	subw	a5,a5,s2
    800030f8:	fcc42703          	lw	a4,-52(s0)
    800030fc:	fce7ece3          	bltu	a5,a4,800030d4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003100:	00234517          	auipc	a0,0x234
    80003104:	e9850513          	add	a0,a0,-360 # 80236f98 <tickslock>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	bfc080e7          	jalr	-1028(ra) # 80000d04 <release>
  return 0;
    80003110:	4501                	li	a0,0
}
    80003112:	70e2                	ld	ra,56(sp)
    80003114:	7442                	ld	s0,48(sp)
    80003116:	74a2                	ld	s1,40(sp)
    80003118:	7902                	ld	s2,32(sp)
    8000311a:	69e2                	ld	s3,24(sp)
    8000311c:	6121                	add	sp,sp,64
    8000311e:	8082                	ret
      release(&tickslock);
    80003120:	00234517          	auipc	a0,0x234
    80003124:	e7850513          	add	a0,a0,-392 # 80236f98 <tickslock>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	bdc080e7          	jalr	-1060(ra) # 80000d04 <release>
      return -1;
    80003130:	557d                	li	a0,-1
    80003132:	b7c5                	j	80003112 <sys_sleep+0x88>

0000000080003134 <sys_kill>:

uint64
sys_kill(void)
{
    80003134:	1101                	add	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	1000                	add	s0,sp,32
  int pid;

  argint(0, &pid);
    8000313c:	fec40593          	add	a1,s0,-20
    80003140:	4501                	li	a0,0
    80003142:	00000097          	auipc	ra,0x0
    80003146:	d9a080e7          	jalr	-614(ra) # 80002edc <argint>
  return kill(pid);
    8000314a:	fec42503          	lw	a0,-20(s0)
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	294080e7          	jalr	660(ra) # 800023e2 <kill>
}
    80003156:	60e2                	ld	ra,24(sp)
    80003158:	6442                	ld	s0,16(sp)
    8000315a:	6105                	add	sp,sp,32
    8000315c:	8082                	ret

000000008000315e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000315e:	1101                	add	sp,sp,-32
    80003160:	ec06                	sd	ra,24(sp)
    80003162:	e822                	sd	s0,16(sp)
    80003164:	e426                	sd	s1,8(sp)
    80003166:	1000                	add	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003168:	00234517          	auipc	a0,0x234
    8000316c:	e3050513          	add	a0,a0,-464 # 80236f98 <tickslock>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	ae0080e7          	jalr	-1312(ra) # 80000c50 <acquire>
  xticks = ticks;
    80003178:	00005497          	auipc	s1,0x5
    8000317c:	7684a483          	lw	s1,1896(s1) # 800088e0 <ticks>
  release(&tickslock);
    80003180:	00234517          	auipc	a0,0x234
    80003184:	e1850513          	add	a0,a0,-488 # 80236f98 <tickslock>
    80003188:	ffffe097          	auipc	ra,0xffffe
    8000318c:	b7c080e7          	jalr	-1156(ra) # 80000d04 <release>
  return xticks;
}
    80003190:	02049513          	sll	a0,s1,0x20
    80003194:	9101                	srl	a0,a0,0x20
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	add	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <sys_waitx>:

uint64
sys_waitx(void)
{
    800031a0:	7139                	add	sp,sp,-64
    800031a2:	fc06                	sd	ra,56(sp)
    800031a4:	f822                	sd	s0,48(sp)
    800031a6:	f426                	sd	s1,40(sp)
    800031a8:	f04a                	sd	s2,32(sp)
    800031aa:	0080                	add	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800031ac:	fd840593          	add	a1,s0,-40
    800031b0:	4501                	li	a0,0
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	d4a080e7          	jalr	-694(ra) # 80002efc <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800031ba:	fd040593          	add	a1,s0,-48
    800031be:	4505                	li	a0,1
    800031c0:	00000097          	auipc	ra,0x0
    800031c4:	d3c080e7          	jalr	-708(ra) # 80002efc <argaddr>
  argaddr(2, &addr2);
    800031c8:	fc840593          	add	a1,s0,-56
    800031cc:	4509                	li	a0,2
    800031ce:	00000097          	auipc	ra,0x0
    800031d2:	d2e080e7          	jalr	-722(ra) # 80002efc <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800031d6:	fc040613          	add	a2,s0,-64
    800031da:	fc440593          	add	a1,s0,-60
    800031de:	fd843503          	ld	a0,-40(s0)
    800031e2:	fffff097          	auipc	ra,0xfffff
    800031e6:	55a080e7          	jalr	1370(ra) # 8000273c <waitx>
    800031ea:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	914080e7          	jalr	-1772(ra) # 80001b00 <myproc>
    800031f4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800031f6:	4691                	li	a3,4
    800031f8:	fc440613          	add	a2,s0,-60
    800031fc:	fd043583          	ld	a1,-48(s0)
    80003200:	6928                	ld	a0,80(a0)
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	52c080e7          	jalr	1324(ra) # 8000172e <copyout>
    return -1;
    8000320a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000320c:	00054f63          	bltz	a0,8000322a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003210:	4691                	li	a3,4
    80003212:	fc040613          	add	a2,s0,-64
    80003216:	fc843583          	ld	a1,-56(s0)
    8000321a:	68a8                	ld	a0,80(s1)
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	512080e7          	jalr	1298(ra) # 8000172e <copyout>
    80003224:	00054a63          	bltz	a0,80003238 <sys_waitx+0x98>
    return -1;
  return ret;
    80003228:	87ca                	mv	a5,s2
}
    8000322a:	853e                	mv	a0,a5
    8000322c:	70e2                	ld	ra,56(sp)
    8000322e:	7442                	ld	s0,48(sp)
    80003230:	74a2                	ld	s1,40(sp)
    80003232:	7902                	ld	s2,32(sp)
    80003234:	6121                	add	sp,sp,64
    80003236:	8082                	ret
    return -1;
    80003238:	57fd                	li	a5,-1
    8000323a:	bfc5                	j	8000322a <sys_waitx+0x8a>

000000008000323c <sys_setpriority>:

uint64
sys_setpriority(void)
{
    8000323c:	7179                	add	sp,sp,-48
    8000323e:	f406                	sd	ra,40(sp)
    80003240:	f022                	sd	s0,32(sp)
    80003242:	ec26                	sd	s1,24(sp)
    80003244:	e84a                	sd	s2,16(sp)
    80003246:	1800                	add	s0,sp,48
     int pid, priority;
    argint(0, &pid);
    80003248:	fdc40593          	add	a1,s0,-36
    8000324c:	4501                	li	a0,0
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	c8e080e7          	jalr	-882(ra) # 80002edc <argint>
    argint(1, &priority);
    80003256:	fd840593          	add	a1,s0,-40
    8000325a:	4505                	li	a0,1
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	c80080e7          	jalr	-896(ra) # 80002edc <argint>

    if (priority < 0 || priority >= 100)
    80003264:	fd842703          	lw	a4,-40(s0)
    80003268:	06300793          	li	a5,99
        return -1;
    8000326c:	557d                	li	a0,-1
    if (priority < 0 || priority >= 100)
    8000326e:	04e7e963          	bltu	a5,a4,800032c0 <sys_setpriority+0x84>

    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
    80003272:	0022e497          	auipc	s1,0x22e
    80003276:	d2648493          	add	s1,s1,-730 # 80230f98 <proc>
    8000327a:	00234917          	auipc	s2,0x234
    8000327e:	d1e90913          	add	s2,s2,-738 # 80236f98 <tickslock>
        acquire(&p->lock);
    80003282:	8526                	mv	a0,s1
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	9cc080e7          	jalr	-1588(ra) # 80000c50 <acquire>
        if (p->pid == pid) {
    8000328c:	5898                	lw	a4,48(s1)
    8000328e:	fdc42783          	lw	a5,-36(s0)
    80003292:	00f70d63          	beq	a4,a5,800032ac <sys_setpriority+0x70>
            p->priority = priority;
            release(&p->lock);
            return 0; // Success
        }
        release(&p->lock);
    80003296:	8526                	mv	a0,s1
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	a6c080e7          	jalr	-1428(ra) # 80000d04 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800032a0:	18048493          	add	s1,s1,384
    800032a4:	fd249fe3          	bne	s1,s2,80003282 <sys_setpriority+0x46>
    }

    return -1; // Process with the given PID not found
    800032a8:	557d                	li	a0,-1
    800032aa:	a819                	j	800032c0 <sys_setpriority+0x84>
            p->priority = priority;
    800032ac:	fd842783          	lw	a5,-40(s0)
    800032b0:	16f4ae23          	sw	a5,380(s1)
            release(&p->lock);
    800032b4:	8526                	mv	a0,s1
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	a4e080e7          	jalr	-1458(ra) # 80000d04 <release>
            return 0; // Success
    800032be:	4501                	li	a0,0
    800032c0:	70a2                	ld	ra,40(sp)
    800032c2:	7402                	ld	s0,32(sp)
    800032c4:	64e2                	ld	s1,24(sp)
    800032c6:	6942                	ld	s2,16(sp)
    800032c8:	6145                	add	sp,sp,48
    800032ca:	8082                	ret

00000000800032cc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032cc:	7179                	add	sp,sp,-48
    800032ce:	f406                	sd	ra,40(sp)
    800032d0:	f022                	sd	s0,32(sp)
    800032d2:	ec26                	sd	s1,24(sp)
    800032d4:	e84a                	sd	s2,16(sp)
    800032d6:	e44e                	sd	s3,8(sp)
    800032d8:	e052                	sd	s4,0(sp)
    800032da:	1800                	add	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032dc:	00005597          	auipc	a1,0x5
    800032e0:	23c58593          	add	a1,a1,572 # 80008518 <syscalls+0xc8>
    800032e4:	00234517          	auipc	a0,0x234
    800032e8:	ccc50513          	add	a0,a0,-820 # 80236fb0 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8d4080e7          	jalr	-1836(ra) # 80000bc0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032f4:	0023c797          	auipc	a5,0x23c
    800032f8:	cbc78793          	add	a5,a5,-836 # 8023efb0 <bcache+0x8000>
    800032fc:	0023c717          	auipc	a4,0x23c
    80003300:	f1c70713          	add	a4,a4,-228 # 8023f218 <bcache+0x8268>
    80003304:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003308:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000330c:	00234497          	auipc	s1,0x234
    80003310:	cbc48493          	add	s1,s1,-836 # 80236fc8 <bcache+0x18>
    b->next = bcache.head.next;
    80003314:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003316:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003318:	00005a17          	auipc	s4,0x5
    8000331c:	208a0a13          	add	s4,s4,520 # 80008520 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003320:	2b893783          	ld	a5,696(s2)
    80003324:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003326:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000332a:	85d2                	mv	a1,s4
    8000332c:	01048513          	add	a0,s1,16
    80003330:	00001097          	auipc	ra,0x1
    80003334:	496080e7          	jalr	1174(ra) # 800047c6 <initsleeplock>
    bcache.head.next->prev = b;
    80003338:	2b893783          	ld	a5,696(s2)
    8000333c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000333e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003342:	45848493          	add	s1,s1,1112
    80003346:	fd349de3          	bne	s1,s3,80003320 <binit+0x54>
  }
}
    8000334a:	70a2                	ld	ra,40(sp)
    8000334c:	7402                	ld	s0,32(sp)
    8000334e:	64e2                	ld	s1,24(sp)
    80003350:	6942                	ld	s2,16(sp)
    80003352:	69a2                	ld	s3,8(sp)
    80003354:	6a02                	ld	s4,0(sp)
    80003356:	6145                	add	sp,sp,48
    80003358:	8082                	ret

000000008000335a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000335a:	7179                	add	sp,sp,-48
    8000335c:	f406                	sd	ra,40(sp)
    8000335e:	f022                	sd	s0,32(sp)
    80003360:	ec26                	sd	s1,24(sp)
    80003362:	e84a                	sd	s2,16(sp)
    80003364:	e44e                	sd	s3,8(sp)
    80003366:	1800                	add	s0,sp,48
    80003368:	892a                	mv	s2,a0
    8000336a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000336c:	00234517          	auipc	a0,0x234
    80003370:	c4450513          	add	a0,a0,-956 # 80236fb0 <bcache>
    80003374:	ffffe097          	auipc	ra,0xffffe
    80003378:	8dc080e7          	jalr	-1828(ra) # 80000c50 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000337c:	0023c497          	auipc	s1,0x23c
    80003380:	eec4b483          	ld	s1,-276(s1) # 8023f268 <bcache+0x82b8>
    80003384:	0023c797          	auipc	a5,0x23c
    80003388:	e9478793          	add	a5,a5,-364 # 8023f218 <bcache+0x8268>
    8000338c:	02f48f63          	beq	s1,a5,800033ca <bread+0x70>
    80003390:	873e                	mv	a4,a5
    80003392:	a021                	j	8000339a <bread+0x40>
    80003394:	68a4                	ld	s1,80(s1)
    80003396:	02e48a63          	beq	s1,a4,800033ca <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000339a:	449c                	lw	a5,8(s1)
    8000339c:	ff279ce3          	bne	a5,s2,80003394 <bread+0x3a>
    800033a0:	44dc                	lw	a5,12(s1)
    800033a2:	ff3799e3          	bne	a5,s3,80003394 <bread+0x3a>
      b->refcnt++;
    800033a6:	40bc                	lw	a5,64(s1)
    800033a8:	2785                	addw	a5,a5,1
    800033aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033ac:	00234517          	auipc	a0,0x234
    800033b0:	c0450513          	add	a0,a0,-1020 # 80236fb0 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	950080e7          	jalr	-1712(ra) # 80000d04 <release>
      acquiresleep(&b->lock);
    800033bc:	01048513          	add	a0,s1,16
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	440080e7          	jalr	1088(ra) # 80004800 <acquiresleep>
      return b;
    800033c8:	a8b9                	j	80003426 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ca:	0023c497          	auipc	s1,0x23c
    800033ce:	e964b483          	ld	s1,-362(s1) # 8023f260 <bcache+0x82b0>
    800033d2:	0023c797          	auipc	a5,0x23c
    800033d6:	e4678793          	add	a5,a5,-442 # 8023f218 <bcache+0x8268>
    800033da:	00f48863          	beq	s1,a5,800033ea <bread+0x90>
    800033de:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033e0:	40bc                	lw	a5,64(s1)
    800033e2:	cf81                	beqz	a5,800033fa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033e4:	64a4                	ld	s1,72(s1)
    800033e6:	fee49de3          	bne	s1,a4,800033e0 <bread+0x86>
  panic("bget: no buffers");
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	13e50513          	add	a0,a0,318 # 80008528 <syscalls+0xd8>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	14a080e7          	jalr	330(ra) # 8000053c <panic>
      b->dev = dev;
    800033fa:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033fe:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003402:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003406:	4785                	li	a5,1
    80003408:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000340a:	00234517          	auipc	a0,0x234
    8000340e:	ba650513          	add	a0,a0,-1114 # 80236fb0 <bcache>
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	8f2080e7          	jalr	-1806(ra) # 80000d04 <release>
      acquiresleep(&b->lock);
    8000341a:	01048513          	add	a0,s1,16
    8000341e:	00001097          	auipc	ra,0x1
    80003422:	3e2080e7          	jalr	994(ra) # 80004800 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003426:	409c                	lw	a5,0(s1)
    80003428:	cb89                	beqz	a5,8000343a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000342a:	8526                	mv	a0,s1
    8000342c:	70a2                	ld	ra,40(sp)
    8000342e:	7402                	ld	s0,32(sp)
    80003430:	64e2                	ld	s1,24(sp)
    80003432:	6942                	ld	s2,16(sp)
    80003434:	69a2                	ld	s3,8(sp)
    80003436:	6145                	add	sp,sp,48
    80003438:	8082                	ret
    virtio_disk_rw(b, 0);
    8000343a:	4581                	li	a1,0
    8000343c:	8526                	mv	a0,s1
    8000343e:	00003097          	auipc	ra,0x3
    80003442:	fa4080e7          	jalr	-92(ra) # 800063e2 <virtio_disk_rw>
    b->valid = 1;
    80003446:	4785                	li	a5,1
    80003448:	c09c                	sw	a5,0(s1)
  return b;
    8000344a:	b7c5                	j	8000342a <bread+0xd0>

000000008000344c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000344c:	1101                	add	sp,sp,-32
    8000344e:	ec06                	sd	ra,24(sp)
    80003450:	e822                	sd	s0,16(sp)
    80003452:	e426                	sd	s1,8(sp)
    80003454:	1000                	add	s0,sp,32
    80003456:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003458:	0541                	add	a0,a0,16
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	440080e7          	jalr	1088(ra) # 8000489a <holdingsleep>
    80003462:	cd01                	beqz	a0,8000347a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003464:	4585                	li	a1,1
    80003466:	8526                	mv	a0,s1
    80003468:	00003097          	auipc	ra,0x3
    8000346c:	f7a080e7          	jalr	-134(ra) # 800063e2 <virtio_disk_rw>
}
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	add	sp,sp,32
    80003478:	8082                	ret
    panic("bwrite");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	0c650513          	add	a0,a0,198 # 80008540 <syscalls+0xf0>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0ba080e7          	jalr	186(ra) # 8000053c <panic>

000000008000348a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000348a:	1101                	add	sp,sp,-32
    8000348c:	ec06                	sd	ra,24(sp)
    8000348e:	e822                	sd	s0,16(sp)
    80003490:	e426                	sd	s1,8(sp)
    80003492:	e04a                	sd	s2,0(sp)
    80003494:	1000                	add	s0,sp,32
    80003496:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003498:	01050913          	add	s2,a0,16
    8000349c:	854a                	mv	a0,s2
    8000349e:	00001097          	auipc	ra,0x1
    800034a2:	3fc080e7          	jalr	1020(ra) # 8000489a <holdingsleep>
    800034a6:	c925                	beqz	a0,80003516 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800034a8:	854a                	mv	a0,s2
    800034aa:	00001097          	auipc	ra,0x1
    800034ae:	3ac080e7          	jalr	940(ra) # 80004856 <releasesleep>

  acquire(&bcache.lock);
    800034b2:	00234517          	auipc	a0,0x234
    800034b6:	afe50513          	add	a0,a0,-1282 # 80236fb0 <bcache>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	796080e7          	jalr	1942(ra) # 80000c50 <acquire>
  b->refcnt--;
    800034c2:	40bc                	lw	a5,64(s1)
    800034c4:	37fd                	addw	a5,a5,-1
    800034c6:	0007871b          	sext.w	a4,a5
    800034ca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034cc:	e71d                	bnez	a4,800034fa <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034ce:	68b8                	ld	a4,80(s1)
    800034d0:	64bc                	ld	a5,72(s1)
    800034d2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800034d4:	68b8                	ld	a4,80(s1)
    800034d6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034d8:	0023c797          	auipc	a5,0x23c
    800034dc:	ad878793          	add	a5,a5,-1320 # 8023efb0 <bcache+0x8000>
    800034e0:	2b87b703          	ld	a4,696(a5)
    800034e4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034e6:	0023c717          	auipc	a4,0x23c
    800034ea:	d3270713          	add	a4,a4,-718 # 8023f218 <bcache+0x8268>
    800034ee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034f0:	2b87b703          	ld	a4,696(a5)
    800034f4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034f6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034fa:	00234517          	auipc	a0,0x234
    800034fe:	ab650513          	add	a0,a0,-1354 # 80236fb0 <bcache>
    80003502:	ffffe097          	auipc	ra,0xffffe
    80003506:	802080e7          	jalr	-2046(ra) # 80000d04 <release>
}
    8000350a:	60e2                	ld	ra,24(sp)
    8000350c:	6442                	ld	s0,16(sp)
    8000350e:	64a2                	ld	s1,8(sp)
    80003510:	6902                	ld	s2,0(sp)
    80003512:	6105                	add	sp,sp,32
    80003514:	8082                	ret
    panic("brelse");
    80003516:	00005517          	auipc	a0,0x5
    8000351a:	03250513          	add	a0,a0,50 # 80008548 <syscalls+0xf8>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	01e080e7          	jalr	30(ra) # 8000053c <panic>

0000000080003526 <bpin>:

void
bpin(struct buf *b) {
    80003526:	1101                	add	sp,sp,-32
    80003528:	ec06                	sd	ra,24(sp)
    8000352a:	e822                	sd	s0,16(sp)
    8000352c:	e426                	sd	s1,8(sp)
    8000352e:	1000                	add	s0,sp,32
    80003530:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003532:	00234517          	auipc	a0,0x234
    80003536:	a7e50513          	add	a0,a0,-1410 # 80236fb0 <bcache>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	716080e7          	jalr	1814(ra) # 80000c50 <acquire>
  b->refcnt++;
    80003542:	40bc                	lw	a5,64(s1)
    80003544:	2785                	addw	a5,a5,1
    80003546:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003548:	00234517          	auipc	a0,0x234
    8000354c:	a6850513          	add	a0,a0,-1432 # 80236fb0 <bcache>
    80003550:	ffffd097          	auipc	ra,0xffffd
    80003554:	7b4080e7          	jalr	1972(ra) # 80000d04 <release>
}
    80003558:	60e2                	ld	ra,24(sp)
    8000355a:	6442                	ld	s0,16(sp)
    8000355c:	64a2                	ld	s1,8(sp)
    8000355e:	6105                	add	sp,sp,32
    80003560:	8082                	ret

0000000080003562 <bunpin>:

void
bunpin(struct buf *b) {
    80003562:	1101                	add	sp,sp,-32
    80003564:	ec06                	sd	ra,24(sp)
    80003566:	e822                	sd	s0,16(sp)
    80003568:	e426                	sd	s1,8(sp)
    8000356a:	1000                	add	s0,sp,32
    8000356c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000356e:	00234517          	auipc	a0,0x234
    80003572:	a4250513          	add	a0,a0,-1470 # 80236fb0 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	6da080e7          	jalr	1754(ra) # 80000c50 <acquire>
  b->refcnt--;
    8000357e:	40bc                	lw	a5,64(s1)
    80003580:	37fd                	addw	a5,a5,-1
    80003582:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003584:	00234517          	auipc	a0,0x234
    80003588:	a2c50513          	add	a0,a0,-1492 # 80236fb0 <bcache>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	778080e7          	jalr	1912(ra) # 80000d04 <release>
}
    80003594:	60e2                	ld	ra,24(sp)
    80003596:	6442                	ld	s0,16(sp)
    80003598:	64a2                	ld	s1,8(sp)
    8000359a:	6105                	add	sp,sp,32
    8000359c:	8082                	ret

000000008000359e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000359e:	1101                	add	sp,sp,-32
    800035a0:	ec06                	sd	ra,24(sp)
    800035a2:	e822                	sd	s0,16(sp)
    800035a4:	e426                	sd	s1,8(sp)
    800035a6:	e04a                	sd	s2,0(sp)
    800035a8:	1000                	add	s0,sp,32
    800035aa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035ac:	00d5d59b          	srlw	a1,a1,0xd
    800035b0:	0023c797          	auipc	a5,0x23c
    800035b4:	0dc7a783          	lw	a5,220(a5) # 8023f68c <sb+0x1c>
    800035b8:	9dbd                	addw	a1,a1,a5
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	da0080e7          	jalr	-608(ra) # 8000335a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035c2:	0074f713          	and	a4,s1,7
    800035c6:	4785                	li	a5,1
    800035c8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035cc:	14ce                	sll	s1,s1,0x33
    800035ce:	90d9                	srl	s1,s1,0x36
    800035d0:	00950733          	add	a4,a0,s1
    800035d4:	05874703          	lbu	a4,88(a4)
    800035d8:	00e7f6b3          	and	a3,a5,a4
    800035dc:	c69d                	beqz	a3,8000360a <bfree+0x6c>
    800035de:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035e0:	94aa                	add	s1,s1,a0
    800035e2:	fff7c793          	not	a5,a5
    800035e6:	8f7d                	and	a4,a4,a5
    800035e8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	0f6080e7          	jalr	246(ra) # 800046e2 <log_write>
  brelse(bp);
    800035f4:	854a                	mv	a0,s2
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	e94080e7          	jalr	-364(ra) # 8000348a <brelse>
}
    800035fe:	60e2                	ld	ra,24(sp)
    80003600:	6442                	ld	s0,16(sp)
    80003602:	64a2                	ld	s1,8(sp)
    80003604:	6902                	ld	s2,0(sp)
    80003606:	6105                	add	sp,sp,32
    80003608:	8082                	ret
    panic("freeing free block");
    8000360a:	00005517          	auipc	a0,0x5
    8000360e:	f4650513          	add	a0,a0,-186 # 80008550 <syscalls+0x100>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	f2a080e7          	jalr	-214(ra) # 8000053c <panic>

000000008000361a <balloc>:
{
    8000361a:	711d                	add	sp,sp,-96
    8000361c:	ec86                	sd	ra,88(sp)
    8000361e:	e8a2                	sd	s0,80(sp)
    80003620:	e4a6                	sd	s1,72(sp)
    80003622:	e0ca                	sd	s2,64(sp)
    80003624:	fc4e                	sd	s3,56(sp)
    80003626:	f852                	sd	s4,48(sp)
    80003628:	f456                	sd	s5,40(sp)
    8000362a:	f05a                	sd	s6,32(sp)
    8000362c:	ec5e                	sd	s7,24(sp)
    8000362e:	e862                	sd	s8,16(sp)
    80003630:	e466                	sd	s9,8(sp)
    80003632:	1080                	add	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003634:	0023c797          	auipc	a5,0x23c
    80003638:	0407a783          	lw	a5,64(a5) # 8023f674 <sb+0x4>
    8000363c:	cff5                	beqz	a5,80003738 <balloc+0x11e>
    8000363e:	8baa                	mv	s7,a0
    80003640:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003642:	0023cb17          	auipc	s6,0x23c
    80003646:	02eb0b13          	add	s6,s6,46 # 8023f670 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000364a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000364c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000364e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003650:	6c89                	lui	s9,0x2
    80003652:	a061                	j	800036da <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003654:	97ca                	add	a5,a5,s2
    80003656:	8e55                	or	a2,a2,a3
    80003658:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000365c:	854a                	mv	a0,s2
    8000365e:	00001097          	auipc	ra,0x1
    80003662:	084080e7          	jalr	132(ra) # 800046e2 <log_write>
        brelse(bp);
    80003666:	854a                	mv	a0,s2
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	e22080e7          	jalr	-478(ra) # 8000348a <brelse>
  bp = bread(dev, bno);
    80003670:	85a6                	mv	a1,s1
    80003672:	855e                	mv	a0,s7
    80003674:	00000097          	auipc	ra,0x0
    80003678:	ce6080e7          	jalr	-794(ra) # 8000335a <bread>
    8000367c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000367e:	40000613          	li	a2,1024
    80003682:	4581                	li	a1,0
    80003684:	05850513          	add	a0,a0,88
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	6c4080e7          	jalr	1732(ra) # 80000d4c <memset>
  log_write(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00001097          	auipc	ra,0x1
    80003696:	050080e7          	jalr	80(ra) # 800046e2 <log_write>
  brelse(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	dee080e7          	jalr	-530(ra) # 8000348a <brelse>
}
    800036a4:	8526                	mv	a0,s1
    800036a6:	60e6                	ld	ra,88(sp)
    800036a8:	6446                	ld	s0,80(sp)
    800036aa:	64a6                	ld	s1,72(sp)
    800036ac:	6906                	ld	s2,64(sp)
    800036ae:	79e2                	ld	s3,56(sp)
    800036b0:	7a42                	ld	s4,48(sp)
    800036b2:	7aa2                	ld	s5,40(sp)
    800036b4:	7b02                	ld	s6,32(sp)
    800036b6:	6be2                	ld	s7,24(sp)
    800036b8:	6c42                	ld	s8,16(sp)
    800036ba:	6ca2                	ld	s9,8(sp)
    800036bc:	6125                	add	sp,sp,96
    800036be:	8082                	ret
    brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	dc8080e7          	jalr	-568(ra) # 8000348a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036ca:	015c87bb          	addw	a5,s9,s5
    800036ce:	00078a9b          	sext.w	s5,a5
    800036d2:	004b2703          	lw	a4,4(s6)
    800036d6:	06eaf163          	bgeu	s5,a4,80003738 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800036da:	41fad79b          	sraw	a5,s5,0x1f
    800036de:	0137d79b          	srlw	a5,a5,0x13
    800036e2:	015787bb          	addw	a5,a5,s5
    800036e6:	40d7d79b          	sraw	a5,a5,0xd
    800036ea:	01cb2583          	lw	a1,28(s6)
    800036ee:	9dbd                	addw	a1,a1,a5
    800036f0:	855e                	mv	a0,s7
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	c68080e7          	jalr	-920(ra) # 8000335a <bread>
    800036fa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fc:	004b2503          	lw	a0,4(s6)
    80003700:	000a849b          	sext.w	s1,s5
    80003704:	8762                	mv	a4,s8
    80003706:	faa4fde3          	bgeu	s1,a0,800036c0 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000370a:	00777693          	and	a3,a4,7
    8000370e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003712:	41f7579b          	sraw	a5,a4,0x1f
    80003716:	01d7d79b          	srlw	a5,a5,0x1d
    8000371a:	9fb9                	addw	a5,a5,a4
    8000371c:	4037d79b          	sraw	a5,a5,0x3
    80003720:	00f90633          	add	a2,s2,a5
    80003724:	05864603          	lbu	a2,88(a2)
    80003728:	00c6f5b3          	and	a1,a3,a2
    8000372c:	d585                	beqz	a1,80003654 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372e:	2705                	addw	a4,a4,1
    80003730:	2485                	addw	s1,s1,1
    80003732:	fd471ae3          	bne	a4,s4,80003706 <balloc+0xec>
    80003736:	b769                	j	800036c0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003738:	00005517          	auipc	a0,0x5
    8000373c:	e3050513          	add	a0,a0,-464 # 80008568 <syscalls+0x118>
    80003740:	ffffd097          	auipc	ra,0xffffd
    80003744:	e46080e7          	jalr	-442(ra) # 80000586 <printf>
  return 0;
    80003748:	4481                	li	s1,0
    8000374a:	bfa9                	j	800036a4 <balloc+0x8a>

000000008000374c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000374c:	7179                	add	sp,sp,-48
    8000374e:	f406                	sd	ra,40(sp)
    80003750:	f022                	sd	s0,32(sp)
    80003752:	ec26                	sd	s1,24(sp)
    80003754:	e84a                	sd	s2,16(sp)
    80003756:	e44e                	sd	s3,8(sp)
    80003758:	e052                	sd	s4,0(sp)
    8000375a:	1800                	add	s0,sp,48
    8000375c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000375e:	47ad                	li	a5,11
    80003760:	02b7e863          	bltu	a5,a1,80003790 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003764:	02059793          	sll	a5,a1,0x20
    80003768:	01e7d593          	srl	a1,a5,0x1e
    8000376c:	00b504b3          	add	s1,a0,a1
    80003770:	0504a903          	lw	s2,80(s1)
    80003774:	06091e63          	bnez	s2,800037f0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003778:	4108                	lw	a0,0(a0)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	ea0080e7          	jalr	-352(ra) # 8000361a <balloc>
    80003782:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003786:	06090563          	beqz	s2,800037f0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000378a:	0524a823          	sw	s2,80(s1)
    8000378e:	a08d                	j	800037f0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003790:	ff45849b          	addw	s1,a1,-12
    80003794:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003798:	0ff00793          	li	a5,255
    8000379c:	08e7e563          	bltu	a5,a4,80003826 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800037a0:	08052903          	lw	s2,128(a0)
    800037a4:	00091d63          	bnez	s2,800037be <bmap+0x72>
      addr = balloc(ip->dev);
    800037a8:	4108                	lw	a0,0(a0)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	e70080e7          	jalr	-400(ra) # 8000361a <balloc>
    800037b2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800037b6:	02090d63          	beqz	s2,800037f0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800037ba:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800037be:	85ca                	mv	a1,s2
    800037c0:	0009a503          	lw	a0,0(s3)
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	b96080e7          	jalr	-1130(ra) # 8000335a <bread>
    800037cc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ce:	05850793          	add	a5,a0,88
    if((addr = a[bn]) == 0){
    800037d2:	02049713          	sll	a4,s1,0x20
    800037d6:	01e75593          	srl	a1,a4,0x1e
    800037da:	00b784b3          	add	s1,a5,a1
    800037de:	0004a903          	lw	s2,0(s1)
    800037e2:	02090063          	beqz	s2,80003802 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800037e6:	8552                	mv	a0,s4
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	ca2080e7          	jalr	-862(ra) # 8000348a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037f0:	854a                	mv	a0,s2
    800037f2:	70a2                	ld	ra,40(sp)
    800037f4:	7402                	ld	s0,32(sp)
    800037f6:	64e2                	ld	s1,24(sp)
    800037f8:	6942                	ld	s2,16(sp)
    800037fa:	69a2                	ld	s3,8(sp)
    800037fc:	6a02                	ld	s4,0(sp)
    800037fe:	6145                	add	sp,sp,48
    80003800:	8082                	ret
      addr = balloc(ip->dev);
    80003802:	0009a503          	lw	a0,0(s3)
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	e14080e7          	jalr	-492(ra) # 8000361a <balloc>
    8000380e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003812:	fc090ae3          	beqz	s2,800037e6 <bmap+0x9a>
        a[bn] = addr;
    80003816:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000381a:	8552                	mv	a0,s4
    8000381c:	00001097          	auipc	ra,0x1
    80003820:	ec6080e7          	jalr	-314(ra) # 800046e2 <log_write>
    80003824:	b7c9                	j	800037e6 <bmap+0x9a>
  panic("bmap: out of range");
    80003826:	00005517          	auipc	a0,0x5
    8000382a:	d5a50513          	add	a0,a0,-678 # 80008580 <syscalls+0x130>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	d0e080e7          	jalr	-754(ra) # 8000053c <panic>

0000000080003836 <iget>:
{
    80003836:	7179                	add	sp,sp,-48
    80003838:	f406                	sd	ra,40(sp)
    8000383a:	f022                	sd	s0,32(sp)
    8000383c:	ec26                	sd	s1,24(sp)
    8000383e:	e84a                	sd	s2,16(sp)
    80003840:	e44e                	sd	s3,8(sp)
    80003842:	e052                	sd	s4,0(sp)
    80003844:	1800                	add	s0,sp,48
    80003846:	89aa                	mv	s3,a0
    80003848:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000384a:	0023c517          	auipc	a0,0x23c
    8000384e:	e4650513          	add	a0,a0,-442 # 8023f690 <itable>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	3fe080e7          	jalr	1022(ra) # 80000c50 <acquire>
  empty = 0;
    8000385a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000385c:	0023c497          	auipc	s1,0x23c
    80003860:	e4c48493          	add	s1,s1,-436 # 8023f6a8 <itable+0x18>
    80003864:	0023e697          	auipc	a3,0x23e
    80003868:	8d468693          	add	a3,a3,-1836 # 80241138 <log>
    8000386c:	a039                	j	8000387a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000386e:	02090b63          	beqz	s2,800038a4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003872:	08848493          	add	s1,s1,136
    80003876:	02d48a63          	beq	s1,a3,800038aa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000387a:	449c                	lw	a5,8(s1)
    8000387c:	fef059e3          	blez	a5,8000386e <iget+0x38>
    80003880:	4098                	lw	a4,0(s1)
    80003882:	ff3716e3          	bne	a4,s3,8000386e <iget+0x38>
    80003886:	40d8                	lw	a4,4(s1)
    80003888:	ff4713e3          	bne	a4,s4,8000386e <iget+0x38>
      ip->ref++;
    8000388c:	2785                	addw	a5,a5,1
    8000388e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003890:	0023c517          	auipc	a0,0x23c
    80003894:	e0050513          	add	a0,a0,-512 # 8023f690 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	46c080e7          	jalr	1132(ra) # 80000d04 <release>
      return ip;
    800038a0:	8926                	mv	s2,s1
    800038a2:	a03d                	j	800038d0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038a4:	f7f9                	bnez	a5,80003872 <iget+0x3c>
    800038a6:	8926                	mv	s2,s1
    800038a8:	b7e9                	j	80003872 <iget+0x3c>
  if(empty == 0)
    800038aa:	02090c63          	beqz	s2,800038e2 <iget+0xac>
  ip->dev = dev;
    800038ae:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038b2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038b6:	4785                	li	a5,1
    800038b8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038bc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038c0:	0023c517          	auipc	a0,0x23c
    800038c4:	dd050513          	add	a0,a0,-560 # 8023f690 <itable>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	43c080e7          	jalr	1084(ra) # 80000d04 <release>
}
    800038d0:	854a                	mv	a0,s2
    800038d2:	70a2                	ld	ra,40(sp)
    800038d4:	7402                	ld	s0,32(sp)
    800038d6:	64e2                	ld	s1,24(sp)
    800038d8:	6942                	ld	s2,16(sp)
    800038da:	69a2                	ld	s3,8(sp)
    800038dc:	6a02                	ld	s4,0(sp)
    800038de:	6145                	add	sp,sp,48
    800038e0:	8082                	ret
    panic("iget: no inodes");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	cb650513          	add	a0,a0,-842 # 80008598 <syscalls+0x148>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c52080e7          	jalr	-942(ra) # 8000053c <panic>

00000000800038f2 <fsinit>:
fsinit(int dev) {
    800038f2:	7179                	add	sp,sp,-48
    800038f4:	f406                	sd	ra,40(sp)
    800038f6:	f022                	sd	s0,32(sp)
    800038f8:	ec26                	sd	s1,24(sp)
    800038fa:	e84a                	sd	s2,16(sp)
    800038fc:	e44e                	sd	s3,8(sp)
    800038fe:	1800                	add	s0,sp,48
    80003900:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003902:	4585                	li	a1,1
    80003904:	00000097          	auipc	ra,0x0
    80003908:	a56080e7          	jalr	-1450(ra) # 8000335a <bread>
    8000390c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000390e:	0023c997          	auipc	s3,0x23c
    80003912:	d6298993          	add	s3,s3,-670 # 8023f670 <sb>
    80003916:	02000613          	li	a2,32
    8000391a:	05850593          	add	a1,a0,88
    8000391e:	854e                	mv	a0,s3
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	488080e7          	jalr	1160(ra) # 80000da8 <memmove>
  brelse(bp);
    80003928:	8526                	mv	a0,s1
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	b60080e7          	jalr	-1184(ra) # 8000348a <brelse>
  if(sb.magic != FSMAGIC)
    80003932:	0009a703          	lw	a4,0(s3)
    80003936:	102037b7          	lui	a5,0x10203
    8000393a:	04078793          	add	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000393e:	02f71263          	bne	a4,a5,80003962 <fsinit+0x70>
  initlog(dev, &sb);
    80003942:	0023c597          	auipc	a1,0x23c
    80003946:	d2e58593          	add	a1,a1,-722 # 8023f670 <sb>
    8000394a:	854a                	mv	a0,s2
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	b2c080e7          	jalr	-1236(ra) # 80004478 <initlog>
}
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6145                	add	sp,sp,48
    80003960:	8082                	ret
    panic("invalid file system");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	c4650513          	add	a0,a0,-954 # 800085a8 <syscalls+0x158>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	bd2080e7          	jalr	-1070(ra) # 8000053c <panic>

0000000080003972 <iinit>:
{
    80003972:	7179                	add	sp,sp,-48
    80003974:	f406                	sd	ra,40(sp)
    80003976:	f022                	sd	s0,32(sp)
    80003978:	ec26                	sd	s1,24(sp)
    8000397a:	e84a                	sd	s2,16(sp)
    8000397c:	e44e                	sd	s3,8(sp)
    8000397e:	1800                	add	s0,sp,48
  initlock(&itable.lock, "itable");
    80003980:	00005597          	auipc	a1,0x5
    80003984:	c4058593          	add	a1,a1,-960 # 800085c0 <syscalls+0x170>
    80003988:	0023c517          	auipc	a0,0x23c
    8000398c:	d0850513          	add	a0,a0,-760 # 8023f690 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	230080e7          	jalr	560(ra) # 80000bc0 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003998:	0023c497          	auipc	s1,0x23c
    8000399c:	d2048493          	add	s1,s1,-736 # 8023f6b8 <itable+0x28>
    800039a0:	0023d997          	auipc	s3,0x23d
    800039a4:	7a898993          	add	s3,s3,1960 # 80241148 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039a8:	00005917          	auipc	s2,0x5
    800039ac:	c2090913          	add	s2,s2,-992 # 800085c8 <syscalls+0x178>
    800039b0:	85ca                	mv	a1,s2
    800039b2:	8526                	mv	a0,s1
    800039b4:	00001097          	auipc	ra,0x1
    800039b8:	e12080e7          	jalr	-494(ra) # 800047c6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039bc:	08848493          	add	s1,s1,136
    800039c0:	ff3498e3          	bne	s1,s3,800039b0 <iinit+0x3e>
}
    800039c4:	70a2                	ld	ra,40(sp)
    800039c6:	7402                	ld	s0,32(sp)
    800039c8:	64e2                	ld	s1,24(sp)
    800039ca:	6942                	ld	s2,16(sp)
    800039cc:	69a2                	ld	s3,8(sp)
    800039ce:	6145                	add	sp,sp,48
    800039d0:	8082                	ret

00000000800039d2 <ialloc>:
{
    800039d2:	7139                	add	sp,sp,-64
    800039d4:	fc06                	sd	ra,56(sp)
    800039d6:	f822                	sd	s0,48(sp)
    800039d8:	f426                	sd	s1,40(sp)
    800039da:	f04a                	sd	s2,32(sp)
    800039dc:	ec4e                	sd	s3,24(sp)
    800039de:	e852                	sd	s4,16(sp)
    800039e0:	e456                	sd	s5,8(sp)
    800039e2:	e05a                	sd	s6,0(sp)
    800039e4:	0080                	add	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800039e6:	0023c717          	auipc	a4,0x23c
    800039ea:	c9672703          	lw	a4,-874(a4) # 8023f67c <sb+0xc>
    800039ee:	4785                	li	a5,1
    800039f0:	04e7f863          	bgeu	a5,a4,80003a40 <ialloc+0x6e>
    800039f4:	8aaa                	mv	s5,a0
    800039f6:	8b2e                	mv	s6,a1
    800039f8:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039fa:	0023ca17          	auipc	s4,0x23c
    800039fe:	c76a0a13          	add	s4,s4,-906 # 8023f670 <sb>
    80003a02:	00495593          	srl	a1,s2,0x4
    80003a06:	018a2783          	lw	a5,24(s4)
    80003a0a:	9dbd                	addw	a1,a1,a5
    80003a0c:	8556                	mv	a0,s5
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	94c080e7          	jalr	-1716(ra) # 8000335a <bread>
    80003a16:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a18:	05850993          	add	s3,a0,88
    80003a1c:	00f97793          	and	a5,s2,15
    80003a20:	079a                	sll	a5,a5,0x6
    80003a22:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a24:	00099783          	lh	a5,0(s3)
    80003a28:	cf9d                	beqz	a5,80003a66 <ialloc+0x94>
    brelse(bp);
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	a60080e7          	jalr	-1440(ra) # 8000348a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a32:	0905                	add	s2,s2,1
    80003a34:	00ca2703          	lw	a4,12(s4)
    80003a38:	0009079b          	sext.w	a5,s2
    80003a3c:	fce7e3e3          	bltu	a5,a4,80003a02 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003a40:	00005517          	auipc	a0,0x5
    80003a44:	b9050513          	add	a0,a0,-1136 # 800085d0 <syscalls+0x180>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	b3e080e7          	jalr	-1218(ra) # 80000586 <printf>
  return 0;
    80003a50:	4501                	li	a0,0
}
    80003a52:	70e2                	ld	ra,56(sp)
    80003a54:	7442                	ld	s0,48(sp)
    80003a56:	74a2                	ld	s1,40(sp)
    80003a58:	7902                	ld	s2,32(sp)
    80003a5a:	69e2                	ld	s3,24(sp)
    80003a5c:	6a42                	ld	s4,16(sp)
    80003a5e:	6aa2                	ld	s5,8(sp)
    80003a60:	6b02                	ld	s6,0(sp)
    80003a62:	6121                	add	sp,sp,64
    80003a64:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003a66:	04000613          	li	a2,64
    80003a6a:	4581                	li	a1,0
    80003a6c:	854e                	mv	a0,s3
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	2de080e7          	jalr	734(ra) # 80000d4c <memset>
      dip->type = type;
    80003a76:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a7a:	8526                	mv	a0,s1
    80003a7c:	00001097          	auipc	ra,0x1
    80003a80:	c66080e7          	jalr	-922(ra) # 800046e2 <log_write>
      brelse(bp);
    80003a84:	8526                	mv	a0,s1
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	a04080e7          	jalr	-1532(ra) # 8000348a <brelse>
      return iget(dev, inum);
    80003a8e:	0009059b          	sext.w	a1,s2
    80003a92:	8556                	mv	a0,s5
    80003a94:	00000097          	auipc	ra,0x0
    80003a98:	da2080e7          	jalr	-606(ra) # 80003836 <iget>
    80003a9c:	bf5d                	j	80003a52 <ialloc+0x80>

0000000080003a9e <iupdate>:
{
    80003a9e:	1101                	add	sp,sp,-32
    80003aa0:	ec06                	sd	ra,24(sp)
    80003aa2:	e822                	sd	s0,16(sp)
    80003aa4:	e426                	sd	s1,8(sp)
    80003aa6:	e04a                	sd	s2,0(sp)
    80003aa8:	1000                	add	s0,sp,32
    80003aaa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aac:	415c                	lw	a5,4(a0)
    80003aae:	0047d79b          	srlw	a5,a5,0x4
    80003ab2:	0023c597          	auipc	a1,0x23c
    80003ab6:	bd65a583          	lw	a1,-1066(a1) # 8023f688 <sb+0x18>
    80003aba:	9dbd                	addw	a1,a1,a5
    80003abc:	4108                	lw	a0,0(a0)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	89c080e7          	jalr	-1892(ra) # 8000335a <bread>
    80003ac6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ac8:	05850793          	add	a5,a0,88
    80003acc:	40d8                	lw	a4,4(s1)
    80003ace:	8b3d                	and	a4,a4,15
    80003ad0:	071a                	sll	a4,a4,0x6
    80003ad2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003ad4:	04449703          	lh	a4,68(s1)
    80003ad8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003adc:	04649703          	lh	a4,70(s1)
    80003ae0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003ae4:	04849703          	lh	a4,72(s1)
    80003ae8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003aec:	04a49703          	lh	a4,74(s1)
    80003af0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003af4:	44f8                	lw	a4,76(s1)
    80003af6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003af8:	03400613          	li	a2,52
    80003afc:	05048593          	add	a1,s1,80
    80003b00:	00c78513          	add	a0,a5,12
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	2a4080e7          	jalr	676(ra) # 80000da8 <memmove>
  log_write(bp);
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	00001097          	auipc	ra,0x1
    80003b12:	bd4080e7          	jalr	-1068(ra) # 800046e2 <log_write>
  brelse(bp);
    80003b16:	854a                	mv	a0,s2
    80003b18:	00000097          	auipc	ra,0x0
    80003b1c:	972080e7          	jalr	-1678(ra) # 8000348a <brelse>
}
    80003b20:	60e2                	ld	ra,24(sp)
    80003b22:	6442                	ld	s0,16(sp)
    80003b24:	64a2                	ld	s1,8(sp)
    80003b26:	6902                	ld	s2,0(sp)
    80003b28:	6105                	add	sp,sp,32
    80003b2a:	8082                	ret

0000000080003b2c <idup>:
{
    80003b2c:	1101                	add	sp,sp,-32
    80003b2e:	ec06                	sd	ra,24(sp)
    80003b30:	e822                	sd	s0,16(sp)
    80003b32:	e426                	sd	s1,8(sp)
    80003b34:	1000                	add	s0,sp,32
    80003b36:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b38:	0023c517          	auipc	a0,0x23c
    80003b3c:	b5850513          	add	a0,a0,-1192 # 8023f690 <itable>
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	110080e7          	jalr	272(ra) # 80000c50 <acquire>
  ip->ref++;
    80003b48:	449c                	lw	a5,8(s1)
    80003b4a:	2785                	addw	a5,a5,1
    80003b4c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b4e:	0023c517          	auipc	a0,0x23c
    80003b52:	b4250513          	add	a0,a0,-1214 # 8023f690 <itable>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	1ae080e7          	jalr	430(ra) # 80000d04 <release>
}
    80003b5e:	8526                	mv	a0,s1
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6105                	add	sp,sp,32
    80003b68:	8082                	ret

0000000080003b6a <ilock>:
{
    80003b6a:	1101                	add	sp,sp,-32
    80003b6c:	ec06                	sd	ra,24(sp)
    80003b6e:	e822                	sd	s0,16(sp)
    80003b70:	e426                	sd	s1,8(sp)
    80003b72:	e04a                	sd	s2,0(sp)
    80003b74:	1000                	add	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b76:	c115                	beqz	a0,80003b9a <ilock+0x30>
    80003b78:	84aa                	mv	s1,a0
    80003b7a:	451c                	lw	a5,8(a0)
    80003b7c:	00f05f63          	blez	a5,80003b9a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b80:	0541                	add	a0,a0,16
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	c7e080e7          	jalr	-898(ra) # 80004800 <acquiresleep>
  if(ip->valid == 0){
    80003b8a:	40bc                	lw	a5,64(s1)
    80003b8c:	cf99                	beqz	a5,80003baa <ilock+0x40>
}
    80003b8e:	60e2                	ld	ra,24(sp)
    80003b90:	6442                	ld	s0,16(sp)
    80003b92:	64a2                	ld	s1,8(sp)
    80003b94:	6902                	ld	s2,0(sp)
    80003b96:	6105                	add	sp,sp,32
    80003b98:	8082                	ret
    panic("ilock");
    80003b9a:	00005517          	auipc	a0,0x5
    80003b9e:	a4e50513          	add	a0,a0,-1458 # 800085e8 <syscalls+0x198>
    80003ba2:	ffffd097          	auipc	ra,0xffffd
    80003ba6:	99a080e7          	jalr	-1638(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003baa:	40dc                	lw	a5,4(s1)
    80003bac:	0047d79b          	srlw	a5,a5,0x4
    80003bb0:	0023c597          	auipc	a1,0x23c
    80003bb4:	ad85a583          	lw	a1,-1320(a1) # 8023f688 <sb+0x18>
    80003bb8:	9dbd                	addw	a1,a1,a5
    80003bba:	4088                	lw	a0,0(s1)
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	79e080e7          	jalr	1950(ra) # 8000335a <bread>
    80003bc4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bc6:	05850593          	add	a1,a0,88
    80003bca:	40dc                	lw	a5,4(s1)
    80003bcc:	8bbd                	and	a5,a5,15
    80003bce:	079a                	sll	a5,a5,0x6
    80003bd0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bd2:	00059783          	lh	a5,0(a1)
    80003bd6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bda:	00259783          	lh	a5,2(a1)
    80003bde:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003be2:	00459783          	lh	a5,4(a1)
    80003be6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bea:	00659783          	lh	a5,6(a1)
    80003bee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bf2:	459c                	lw	a5,8(a1)
    80003bf4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bf6:	03400613          	li	a2,52
    80003bfa:	05b1                	add	a1,a1,12
    80003bfc:	05048513          	add	a0,s1,80
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	1a8080e7          	jalr	424(ra) # 80000da8 <memmove>
    brelse(bp);
    80003c08:	854a                	mv	a0,s2
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	880080e7          	jalr	-1920(ra) # 8000348a <brelse>
    ip->valid = 1;
    80003c12:	4785                	li	a5,1
    80003c14:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c16:	04449783          	lh	a5,68(s1)
    80003c1a:	fbb5                	bnez	a5,80003b8e <ilock+0x24>
      panic("ilock: no type");
    80003c1c:	00005517          	auipc	a0,0x5
    80003c20:	9d450513          	add	a0,a0,-1580 # 800085f0 <syscalls+0x1a0>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	918080e7          	jalr	-1768(ra) # 8000053c <panic>

0000000080003c2c <iunlock>:
{
    80003c2c:	1101                	add	sp,sp,-32
    80003c2e:	ec06                	sd	ra,24(sp)
    80003c30:	e822                	sd	s0,16(sp)
    80003c32:	e426                	sd	s1,8(sp)
    80003c34:	e04a                	sd	s2,0(sp)
    80003c36:	1000                	add	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c38:	c905                	beqz	a0,80003c68 <iunlock+0x3c>
    80003c3a:	84aa                	mv	s1,a0
    80003c3c:	01050913          	add	s2,a0,16
    80003c40:	854a                	mv	a0,s2
    80003c42:	00001097          	auipc	ra,0x1
    80003c46:	c58080e7          	jalr	-936(ra) # 8000489a <holdingsleep>
    80003c4a:	cd19                	beqz	a0,80003c68 <iunlock+0x3c>
    80003c4c:	449c                	lw	a5,8(s1)
    80003c4e:	00f05d63          	blez	a5,80003c68 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	c02080e7          	jalr	-1022(ra) # 80004856 <releasesleep>
}
    80003c5c:	60e2                	ld	ra,24(sp)
    80003c5e:	6442                	ld	s0,16(sp)
    80003c60:	64a2                	ld	s1,8(sp)
    80003c62:	6902                	ld	s2,0(sp)
    80003c64:	6105                	add	sp,sp,32
    80003c66:	8082                	ret
    panic("iunlock");
    80003c68:	00005517          	auipc	a0,0x5
    80003c6c:	99850513          	add	a0,a0,-1640 # 80008600 <syscalls+0x1b0>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	8cc080e7          	jalr	-1844(ra) # 8000053c <panic>

0000000080003c78 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c78:	7179                	add	sp,sp,-48
    80003c7a:	f406                	sd	ra,40(sp)
    80003c7c:	f022                	sd	s0,32(sp)
    80003c7e:	ec26                	sd	s1,24(sp)
    80003c80:	e84a                	sd	s2,16(sp)
    80003c82:	e44e                	sd	s3,8(sp)
    80003c84:	e052                	sd	s4,0(sp)
    80003c86:	1800                	add	s0,sp,48
    80003c88:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c8a:	05050493          	add	s1,a0,80
    80003c8e:	08050913          	add	s2,a0,128
    80003c92:	a021                	j	80003c9a <itrunc+0x22>
    80003c94:	0491                	add	s1,s1,4
    80003c96:	01248d63          	beq	s1,s2,80003cb0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c9a:	408c                	lw	a1,0(s1)
    80003c9c:	dde5                	beqz	a1,80003c94 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c9e:	0009a503          	lw	a0,0(s3)
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	8fc080e7          	jalr	-1796(ra) # 8000359e <bfree>
      ip->addrs[i] = 0;
    80003caa:	0004a023          	sw	zero,0(s1)
    80003cae:	b7dd                	j	80003c94 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cb0:	0809a583          	lw	a1,128(s3)
    80003cb4:	e185                	bnez	a1,80003cd4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cb6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cba:	854e                	mv	a0,s3
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	de2080e7          	jalr	-542(ra) # 80003a9e <iupdate>
}
    80003cc4:	70a2                	ld	ra,40(sp)
    80003cc6:	7402                	ld	s0,32(sp)
    80003cc8:	64e2                	ld	s1,24(sp)
    80003cca:	6942                	ld	s2,16(sp)
    80003ccc:	69a2                	ld	s3,8(sp)
    80003cce:	6a02                	ld	s4,0(sp)
    80003cd0:	6145                	add	sp,sp,48
    80003cd2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cd4:	0009a503          	lw	a0,0(s3)
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	682080e7          	jalr	1666(ra) # 8000335a <bread>
    80003ce0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ce2:	05850493          	add	s1,a0,88
    80003ce6:	45850913          	add	s2,a0,1112
    80003cea:	a021                	j	80003cf2 <itrunc+0x7a>
    80003cec:	0491                	add	s1,s1,4
    80003cee:	01248b63          	beq	s1,s2,80003d04 <itrunc+0x8c>
      if(a[j])
    80003cf2:	408c                	lw	a1,0(s1)
    80003cf4:	dde5                	beqz	a1,80003cec <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cf6:	0009a503          	lw	a0,0(s3)
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	8a4080e7          	jalr	-1884(ra) # 8000359e <bfree>
    80003d02:	b7ed                	j	80003cec <itrunc+0x74>
    brelse(bp);
    80003d04:	8552                	mv	a0,s4
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	784080e7          	jalr	1924(ra) # 8000348a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d0e:	0809a583          	lw	a1,128(s3)
    80003d12:	0009a503          	lw	a0,0(s3)
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	888080e7          	jalr	-1912(ra) # 8000359e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d1e:	0809a023          	sw	zero,128(s3)
    80003d22:	bf51                	j	80003cb6 <itrunc+0x3e>

0000000080003d24 <iput>:
{
    80003d24:	1101                	add	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	e04a                	sd	s2,0(sp)
    80003d2e:	1000                	add	s0,sp,32
    80003d30:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d32:	0023c517          	auipc	a0,0x23c
    80003d36:	95e50513          	add	a0,a0,-1698 # 8023f690 <itable>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	f16080e7          	jalr	-234(ra) # 80000c50 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d42:	4498                	lw	a4,8(s1)
    80003d44:	4785                	li	a5,1
    80003d46:	02f70363          	beq	a4,a5,80003d6c <iput+0x48>
  ip->ref--;
    80003d4a:	449c                	lw	a5,8(s1)
    80003d4c:	37fd                	addw	a5,a5,-1
    80003d4e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d50:	0023c517          	auipc	a0,0x23c
    80003d54:	94050513          	add	a0,a0,-1728 # 8023f690 <itable>
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	fac080e7          	jalr	-84(ra) # 80000d04 <release>
}
    80003d60:	60e2                	ld	ra,24(sp)
    80003d62:	6442                	ld	s0,16(sp)
    80003d64:	64a2                	ld	s1,8(sp)
    80003d66:	6902                	ld	s2,0(sp)
    80003d68:	6105                	add	sp,sp,32
    80003d6a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d6c:	40bc                	lw	a5,64(s1)
    80003d6e:	dff1                	beqz	a5,80003d4a <iput+0x26>
    80003d70:	04a49783          	lh	a5,74(s1)
    80003d74:	fbf9                	bnez	a5,80003d4a <iput+0x26>
    acquiresleep(&ip->lock);
    80003d76:	01048913          	add	s2,s1,16
    80003d7a:	854a                	mv	a0,s2
    80003d7c:	00001097          	auipc	ra,0x1
    80003d80:	a84080e7          	jalr	-1404(ra) # 80004800 <acquiresleep>
    release(&itable.lock);
    80003d84:	0023c517          	auipc	a0,0x23c
    80003d88:	90c50513          	add	a0,a0,-1780 # 8023f690 <itable>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	f78080e7          	jalr	-136(ra) # 80000d04 <release>
    itrunc(ip);
    80003d94:	8526                	mv	a0,s1
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	ee2080e7          	jalr	-286(ra) # 80003c78 <itrunc>
    ip->type = 0;
    80003d9e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003da2:	8526                	mv	a0,s1
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	cfa080e7          	jalr	-774(ra) # 80003a9e <iupdate>
    ip->valid = 0;
    80003dac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003db0:	854a                	mv	a0,s2
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	aa4080e7          	jalr	-1372(ra) # 80004856 <releasesleep>
    acquire(&itable.lock);
    80003dba:	0023c517          	auipc	a0,0x23c
    80003dbe:	8d650513          	add	a0,a0,-1834 # 8023f690 <itable>
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	e8e080e7          	jalr	-370(ra) # 80000c50 <acquire>
    80003dca:	b741                	j	80003d4a <iput+0x26>

0000000080003dcc <iunlockput>:
{
    80003dcc:	1101                	add	sp,sp,-32
    80003dce:	ec06                	sd	ra,24(sp)
    80003dd0:	e822                	sd	s0,16(sp)
    80003dd2:	e426                	sd	s1,8(sp)
    80003dd4:	1000                	add	s0,sp,32
    80003dd6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	e54080e7          	jalr	-428(ra) # 80003c2c <iunlock>
  iput(ip);
    80003de0:	8526                	mv	a0,s1
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	f42080e7          	jalr	-190(ra) # 80003d24 <iput>
}
    80003dea:	60e2                	ld	ra,24(sp)
    80003dec:	6442                	ld	s0,16(sp)
    80003dee:	64a2                	ld	s1,8(sp)
    80003df0:	6105                	add	sp,sp,32
    80003df2:	8082                	ret

0000000080003df4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003df4:	1141                	add	sp,sp,-16
    80003df6:	e422                	sd	s0,8(sp)
    80003df8:	0800                	add	s0,sp,16
  st->dev = ip->dev;
    80003dfa:	411c                	lw	a5,0(a0)
    80003dfc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dfe:	415c                	lw	a5,4(a0)
    80003e00:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e02:	04451783          	lh	a5,68(a0)
    80003e06:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e0a:	04a51783          	lh	a5,74(a0)
    80003e0e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e12:	04c56783          	lwu	a5,76(a0)
    80003e16:	e99c                	sd	a5,16(a1)
}
    80003e18:	6422                	ld	s0,8(sp)
    80003e1a:	0141                	add	sp,sp,16
    80003e1c:	8082                	ret

0000000080003e1e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e1e:	457c                	lw	a5,76(a0)
    80003e20:	0ed7e963          	bltu	a5,a3,80003f12 <readi+0xf4>
{
    80003e24:	7159                	add	sp,sp,-112
    80003e26:	f486                	sd	ra,104(sp)
    80003e28:	f0a2                	sd	s0,96(sp)
    80003e2a:	eca6                	sd	s1,88(sp)
    80003e2c:	e8ca                	sd	s2,80(sp)
    80003e2e:	e4ce                	sd	s3,72(sp)
    80003e30:	e0d2                	sd	s4,64(sp)
    80003e32:	fc56                	sd	s5,56(sp)
    80003e34:	f85a                	sd	s6,48(sp)
    80003e36:	f45e                	sd	s7,40(sp)
    80003e38:	f062                	sd	s8,32(sp)
    80003e3a:	ec66                	sd	s9,24(sp)
    80003e3c:	e86a                	sd	s10,16(sp)
    80003e3e:	e46e                	sd	s11,8(sp)
    80003e40:	1880                	add	s0,sp,112
    80003e42:	8b2a                	mv	s6,a0
    80003e44:	8bae                	mv	s7,a1
    80003e46:	8a32                	mv	s4,a2
    80003e48:	84b6                	mv	s1,a3
    80003e4a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003e4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003e4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e50:	0ad76063          	bltu	a4,a3,80003ef0 <readi+0xd2>
  if(off + n > ip->size)
    80003e54:	00e7f463          	bgeu	a5,a4,80003e5c <readi+0x3e>
    n = ip->size - off;
    80003e58:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e5c:	0a0a8963          	beqz	s5,80003f0e <readi+0xf0>
    80003e60:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e62:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e66:	5c7d                	li	s8,-1
    80003e68:	a82d                	j	80003ea2 <readi+0x84>
    80003e6a:	020d1d93          	sll	s11,s10,0x20
    80003e6e:	020ddd93          	srl	s11,s11,0x20
    80003e72:	05890613          	add	a2,s2,88
    80003e76:	86ee                	mv	a3,s11
    80003e78:	963a                	add	a2,a2,a4
    80003e7a:	85d2                	mv	a1,s4
    80003e7c:	855e                	mv	a0,s7
    80003e7e:	ffffe097          	auipc	ra,0xffffe
    80003e82:	762080e7          	jalr	1890(ra) # 800025e0 <either_copyout>
    80003e86:	05850d63          	beq	a0,s8,80003ee0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	5fe080e7          	jalr	1534(ra) # 8000348a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e94:	013d09bb          	addw	s3,s10,s3
    80003e98:	009d04bb          	addw	s1,s10,s1
    80003e9c:	9a6e                	add	s4,s4,s11
    80003e9e:	0559f763          	bgeu	s3,s5,80003eec <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ea2:	00a4d59b          	srlw	a1,s1,0xa
    80003ea6:	855a                	mv	a0,s6
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	8a4080e7          	jalr	-1884(ra) # 8000374c <bmap>
    80003eb0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003eb4:	cd85                	beqz	a1,80003eec <readi+0xce>
    bp = bread(ip->dev, addr);
    80003eb6:	000b2503          	lw	a0,0(s6)
    80003eba:	fffff097          	auipc	ra,0xfffff
    80003ebe:	4a0080e7          	jalr	1184(ra) # 8000335a <bread>
    80003ec2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec4:	3ff4f713          	and	a4,s1,1023
    80003ec8:	40ec87bb          	subw	a5,s9,a4
    80003ecc:	413a86bb          	subw	a3,s5,s3
    80003ed0:	8d3e                	mv	s10,a5
    80003ed2:	2781                	sext.w	a5,a5
    80003ed4:	0006861b          	sext.w	a2,a3
    80003ed8:	f8f679e3          	bgeu	a2,a5,80003e6a <readi+0x4c>
    80003edc:	8d36                	mv	s10,a3
    80003ede:	b771                	j	80003e6a <readi+0x4c>
      brelse(bp);
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	5a8080e7          	jalr	1448(ra) # 8000348a <brelse>
      tot = -1;
    80003eea:	59fd                	li	s3,-1
  }
  return tot;
    80003eec:	0009851b          	sext.w	a0,s3
}
    80003ef0:	70a6                	ld	ra,104(sp)
    80003ef2:	7406                	ld	s0,96(sp)
    80003ef4:	64e6                	ld	s1,88(sp)
    80003ef6:	6946                	ld	s2,80(sp)
    80003ef8:	69a6                	ld	s3,72(sp)
    80003efa:	6a06                	ld	s4,64(sp)
    80003efc:	7ae2                	ld	s5,56(sp)
    80003efe:	7b42                	ld	s6,48(sp)
    80003f00:	7ba2                	ld	s7,40(sp)
    80003f02:	7c02                	ld	s8,32(sp)
    80003f04:	6ce2                	ld	s9,24(sp)
    80003f06:	6d42                	ld	s10,16(sp)
    80003f08:	6da2                	ld	s11,8(sp)
    80003f0a:	6165                	add	sp,sp,112
    80003f0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0e:	89d6                	mv	s3,s5
    80003f10:	bff1                	j	80003eec <readi+0xce>
    return 0;
    80003f12:	4501                	li	a0,0
}
    80003f14:	8082                	ret

0000000080003f16 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f16:	457c                	lw	a5,76(a0)
    80003f18:	10d7e863          	bltu	a5,a3,80004028 <writei+0x112>
{
    80003f1c:	7159                	add	sp,sp,-112
    80003f1e:	f486                	sd	ra,104(sp)
    80003f20:	f0a2                	sd	s0,96(sp)
    80003f22:	eca6                	sd	s1,88(sp)
    80003f24:	e8ca                	sd	s2,80(sp)
    80003f26:	e4ce                	sd	s3,72(sp)
    80003f28:	e0d2                	sd	s4,64(sp)
    80003f2a:	fc56                	sd	s5,56(sp)
    80003f2c:	f85a                	sd	s6,48(sp)
    80003f2e:	f45e                	sd	s7,40(sp)
    80003f30:	f062                	sd	s8,32(sp)
    80003f32:	ec66                	sd	s9,24(sp)
    80003f34:	e86a                	sd	s10,16(sp)
    80003f36:	e46e                	sd	s11,8(sp)
    80003f38:	1880                	add	s0,sp,112
    80003f3a:	8aaa                	mv	s5,a0
    80003f3c:	8bae                	mv	s7,a1
    80003f3e:	8a32                	mv	s4,a2
    80003f40:	8936                	mv	s2,a3
    80003f42:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f44:	00e687bb          	addw	a5,a3,a4
    80003f48:	0ed7e263          	bltu	a5,a3,8000402c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f4c:	00043737          	lui	a4,0x43
    80003f50:	0ef76063          	bltu	a4,a5,80004030 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f54:	0c0b0863          	beqz	s6,80004024 <writei+0x10e>
    80003f58:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f5a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f5e:	5c7d                	li	s8,-1
    80003f60:	a091                	j	80003fa4 <writei+0x8e>
    80003f62:	020d1d93          	sll	s11,s10,0x20
    80003f66:	020ddd93          	srl	s11,s11,0x20
    80003f6a:	05848513          	add	a0,s1,88
    80003f6e:	86ee                	mv	a3,s11
    80003f70:	8652                	mv	a2,s4
    80003f72:	85de                	mv	a1,s7
    80003f74:	953a                	add	a0,a0,a4
    80003f76:	ffffe097          	auipc	ra,0xffffe
    80003f7a:	6c0080e7          	jalr	1728(ra) # 80002636 <either_copyin>
    80003f7e:	07850263          	beq	a0,s8,80003fe2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f82:	8526                	mv	a0,s1
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	75e080e7          	jalr	1886(ra) # 800046e2 <log_write>
    brelse(bp);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	4fc080e7          	jalr	1276(ra) # 8000348a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f96:	013d09bb          	addw	s3,s10,s3
    80003f9a:	012d093b          	addw	s2,s10,s2
    80003f9e:	9a6e                	add	s4,s4,s11
    80003fa0:	0569f663          	bgeu	s3,s6,80003fec <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003fa4:	00a9559b          	srlw	a1,s2,0xa
    80003fa8:	8556                	mv	a0,s5
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	7a2080e7          	jalr	1954(ra) # 8000374c <bmap>
    80003fb2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fb6:	c99d                	beqz	a1,80003fec <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003fb8:	000aa503          	lw	a0,0(s5)
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	39e080e7          	jalr	926(ra) # 8000335a <bread>
    80003fc4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc6:	3ff97713          	and	a4,s2,1023
    80003fca:	40ec87bb          	subw	a5,s9,a4
    80003fce:	413b06bb          	subw	a3,s6,s3
    80003fd2:	8d3e                	mv	s10,a5
    80003fd4:	2781                	sext.w	a5,a5
    80003fd6:	0006861b          	sext.w	a2,a3
    80003fda:	f8f674e3          	bgeu	a2,a5,80003f62 <writei+0x4c>
    80003fde:	8d36                	mv	s10,a3
    80003fe0:	b749                	j	80003f62 <writei+0x4c>
      brelse(bp);
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	4a6080e7          	jalr	1190(ra) # 8000348a <brelse>
  }

  if(off > ip->size)
    80003fec:	04caa783          	lw	a5,76(s5)
    80003ff0:	0127f463          	bgeu	a5,s2,80003ff8 <writei+0xe2>
    ip->size = off;
    80003ff4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ff8:	8556                	mv	a0,s5
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	aa4080e7          	jalr	-1372(ra) # 80003a9e <iupdate>

  return tot;
    80004002:	0009851b          	sext.w	a0,s3
}
    80004006:	70a6                	ld	ra,104(sp)
    80004008:	7406                	ld	s0,96(sp)
    8000400a:	64e6                	ld	s1,88(sp)
    8000400c:	6946                	ld	s2,80(sp)
    8000400e:	69a6                	ld	s3,72(sp)
    80004010:	6a06                	ld	s4,64(sp)
    80004012:	7ae2                	ld	s5,56(sp)
    80004014:	7b42                	ld	s6,48(sp)
    80004016:	7ba2                	ld	s7,40(sp)
    80004018:	7c02                	ld	s8,32(sp)
    8000401a:	6ce2                	ld	s9,24(sp)
    8000401c:	6d42                	ld	s10,16(sp)
    8000401e:	6da2                	ld	s11,8(sp)
    80004020:	6165                	add	sp,sp,112
    80004022:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004024:	89da                	mv	s3,s6
    80004026:	bfc9                	j	80003ff8 <writei+0xe2>
    return -1;
    80004028:	557d                	li	a0,-1
}
    8000402a:	8082                	ret
    return -1;
    8000402c:	557d                	li	a0,-1
    8000402e:	bfe1                	j	80004006 <writei+0xf0>
    return -1;
    80004030:	557d                	li	a0,-1
    80004032:	bfd1                	j	80004006 <writei+0xf0>

0000000080004034 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004034:	1141                	add	sp,sp,-16
    80004036:	e406                	sd	ra,8(sp)
    80004038:	e022                	sd	s0,0(sp)
    8000403a:	0800                	add	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000403c:	4639                	li	a2,14
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	dde080e7          	jalr	-546(ra) # 80000e1c <strncmp>
}
    80004046:	60a2                	ld	ra,8(sp)
    80004048:	6402                	ld	s0,0(sp)
    8000404a:	0141                	add	sp,sp,16
    8000404c:	8082                	ret

000000008000404e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000404e:	7139                	add	sp,sp,-64
    80004050:	fc06                	sd	ra,56(sp)
    80004052:	f822                	sd	s0,48(sp)
    80004054:	f426                	sd	s1,40(sp)
    80004056:	f04a                	sd	s2,32(sp)
    80004058:	ec4e                	sd	s3,24(sp)
    8000405a:	e852                	sd	s4,16(sp)
    8000405c:	0080                	add	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000405e:	04451703          	lh	a4,68(a0)
    80004062:	4785                	li	a5,1
    80004064:	00f71a63          	bne	a4,a5,80004078 <dirlookup+0x2a>
    80004068:	892a                	mv	s2,a0
    8000406a:	89ae                	mv	s3,a1
    8000406c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406e:	457c                	lw	a5,76(a0)
    80004070:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004072:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004074:	e79d                	bnez	a5,800040a2 <dirlookup+0x54>
    80004076:	a8a5                	j	800040ee <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004078:	00004517          	auipc	a0,0x4
    8000407c:	59050513          	add	a0,a0,1424 # 80008608 <syscalls+0x1b8>
    80004080:	ffffc097          	auipc	ra,0xffffc
    80004084:	4bc080e7          	jalr	1212(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004088:	00004517          	auipc	a0,0x4
    8000408c:	59850513          	add	a0,a0,1432 # 80008620 <syscalls+0x1d0>
    80004090:	ffffc097          	auipc	ra,0xffffc
    80004094:	4ac080e7          	jalr	1196(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004098:	24c1                	addw	s1,s1,16
    8000409a:	04c92783          	lw	a5,76(s2)
    8000409e:	04f4f763          	bgeu	s1,a5,800040ec <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040a2:	4741                	li	a4,16
    800040a4:	86a6                	mv	a3,s1
    800040a6:	fc040613          	add	a2,s0,-64
    800040aa:	4581                	li	a1,0
    800040ac:	854a                	mv	a0,s2
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	d70080e7          	jalr	-656(ra) # 80003e1e <readi>
    800040b6:	47c1                	li	a5,16
    800040b8:	fcf518e3          	bne	a0,a5,80004088 <dirlookup+0x3a>
    if(de.inum == 0)
    800040bc:	fc045783          	lhu	a5,-64(s0)
    800040c0:	dfe1                	beqz	a5,80004098 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040c2:	fc240593          	add	a1,s0,-62
    800040c6:	854e                	mv	a0,s3
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	f6c080e7          	jalr	-148(ra) # 80004034 <namecmp>
    800040d0:	f561                	bnez	a0,80004098 <dirlookup+0x4a>
      if(poff)
    800040d2:	000a0463          	beqz	s4,800040da <dirlookup+0x8c>
        *poff = off;
    800040d6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040da:	fc045583          	lhu	a1,-64(s0)
    800040de:	00092503          	lw	a0,0(s2)
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	754080e7          	jalr	1876(ra) # 80003836 <iget>
    800040ea:	a011                	j	800040ee <dirlookup+0xa0>
  return 0;
    800040ec:	4501                	li	a0,0
}
    800040ee:	70e2                	ld	ra,56(sp)
    800040f0:	7442                	ld	s0,48(sp)
    800040f2:	74a2                	ld	s1,40(sp)
    800040f4:	7902                	ld	s2,32(sp)
    800040f6:	69e2                	ld	s3,24(sp)
    800040f8:	6a42                	ld	s4,16(sp)
    800040fa:	6121                	add	sp,sp,64
    800040fc:	8082                	ret

00000000800040fe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040fe:	711d                	add	sp,sp,-96
    80004100:	ec86                	sd	ra,88(sp)
    80004102:	e8a2                	sd	s0,80(sp)
    80004104:	e4a6                	sd	s1,72(sp)
    80004106:	e0ca                	sd	s2,64(sp)
    80004108:	fc4e                	sd	s3,56(sp)
    8000410a:	f852                	sd	s4,48(sp)
    8000410c:	f456                	sd	s5,40(sp)
    8000410e:	f05a                	sd	s6,32(sp)
    80004110:	ec5e                	sd	s7,24(sp)
    80004112:	e862                	sd	s8,16(sp)
    80004114:	e466                	sd	s9,8(sp)
    80004116:	1080                	add	s0,sp,96
    80004118:	84aa                	mv	s1,a0
    8000411a:	8b2e                	mv	s6,a1
    8000411c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000411e:	00054703          	lbu	a4,0(a0)
    80004122:	02f00793          	li	a5,47
    80004126:	02f70263          	beq	a4,a5,8000414a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000412a:	ffffe097          	auipc	ra,0xffffe
    8000412e:	9d6080e7          	jalr	-1578(ra) # 80001b00 <myproc>
    80004132:	15053503          	ld	a0,336(a0)
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	9f6080e7          	jalr	-1546(ra) # 80003b2c <idup>
    8000413e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004140:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004144:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004146:	4b85                	li	s7,1
    80004148:	a875                	j	80004204 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000414a:	4585                	li	a1,1
    8000414c:	4505                	li	a0,1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	6e8080e7          	jalr	1768(ra) # 80003836 <iget>
    80004156:	8a2a                	mv	s4,a0
    80004158:	b7e5                	j	80004140 <namex+0x42>
      iunlockput(ip);
    8000415a:	8552                	mv	a0,s4
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	c70080e7          	jalr	-912(ra) # 80003dcc <iunlockput>
      return 0;
    80004164:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004166:	8552                	mv	a0,s4
    80004168:	60e6                	ld	ra,88(sp)
    8000416a:	6446                	ld	s0,80(sp)
    8000416c:	64a6                	ld	s1,72(sp)
    8000416e:	6906                	ld	s2,64(sp)
    80004170:	79e2                	ld	s3,56(sp)
    80004172:	7a42                	ld	s4,48(sp)
    80004174:	7aa2                	ld	s5,40(sp)
    80004176:	7b02                	ld	s6,32(sp)
    80004178:	6be2                	ld	s7,24(sp)
    8000417a:	6c42                	ld	s8,16(sp)
    8000417c:	6ca2                	ld	s9,8(sp)
    8000417e:	6125                	add	sp,sp,96
    80004180:	8082                	ret
      iunlock(ip);
    80004182:	8552                	mv	a0,s4
    80004184:	00000097          	auipc	ra,0x0
    80004188:	aa8080e7          	jalr	-1368(ra) # 80003c2c <iunlock>
      return ip;
    8000418c:	bfe9                	j	80004166 <namex+0x68>
      iunlockput(ip);
    8000418e:	8552                	mv	a0,s4
    80004190:	00000097          	auipc	ra,0x0
    80004194:	c3c080e7          	jalr	-964(ra) # 80003dcc <iunlockput>
      return 0;
    80004198:	8a4e                	mv	s4,s3
    8000419a:	b7f1                	j	80004166 <namex+0x68>
  len = path - s;
    8000419c:	40998633          	sub	a2,s3,s1
    800041a0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041a4:	099c5863          	bge	s8,s9,80004234 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800041a8:	4639                	li	a2,14
    800041aa:	85a6                	mv	a1,s1
    800041ac:	8556                	mv	a0,s5
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	bfa080e7          	jalr	-1030(ra) # 80000da8 <memmove>
    800041b6:	84ce                	mv	s1,s3
  while(*path == '/')
    800041b8:	0004c783          	lbu	a5,0(s1)
    800041bc:	01279763          	bne	a5,s2,800041ca <namex+0xcc>
    path++;
    800041c0:	0485                	add	s1,s1,1
  while(*path == '/')
    800041c2:	0004c783          	lbu	a5,0(s1)
    800041c6:	ff278de3          	beq	a5,s2,800041c0 <namex+0xc2>
    ilock(ip);
    800041ca:	8552                	mv	a0,s4
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	99e080e7          	jalr	-1634(ra) # 80003b6a <ilock>
    if(ip->type != T_DIR){
    800041d4:	044a1783          	lh	a5,68(s4)
    800041d8:	f97791e3          	bne	a5,s7,8000415a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    800041dc:	000b0563          	beqz	s6,800041e6 <namex+0xe8>
    800041e0:	0004c783          	lbu	a5,0(s1)
    800041e4:	dfd9                	beqz	a5,80004182 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041e6:	4601                	li	a2,0
    800041e8:	85d6                	mv	a1,s5
    800041ea:	8552                	mv	a0,s4
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	e62080e7          	jalr	-414(ra) # 8000404e <dirlookup>
    800041f4:	89aa                	mv	s3,a0
    800041f6:	dd41                	beqz	a0,8000418e <namex+0x90>
    iunlockput(ip);
    800041f8:	8552                	mv	a0,s4
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	bd2080e7          	jalr	-1070(ra) # 80003dcc <iunlockput>
    ip = next;
    80004202:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004204:	0004c783          	lbu	a5,0(s1)
    80004208:	01279763          	bne	a5,s2,80004216 <namex+0x118>
    path++;
    8000420c:	0485                	add	s1,s1,1
  while(*path == '/')
    8000420e:	0004c783          	lbu	a5,0(s1)
    80004212:	ff278de3          	beq	a5,s2,8000420c <namex+0x10e>
  if(*path == 0)
    80004216:	cb9d                	beqz	a5,8000424c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004218:	0004c783          	lbu	a5,0(s1)
    8000421c:	89a6                	mv	s3,s1
  len = path - s;
    8000421e:	4c81                	li	s9,0
    80004220:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004222:	01278963          	beq	a5,s2,80004234 <namex+0x136>
    80004226:	dbbd                	beqz	a5,8000419c <namex+0x9e>
    path++;
    80004228:	0985                	add	s3,s3,1
  while(*path != '/' && *path != 0)
    8000422a:	0009c783          	lbu	a5,0(s3)
    8000422e:	ff279ce3          	bne	a5,s2,80004226 <namex+0x128>
    80004232:	b7ad                	j	8000419c <namex+0x9e>
    memmove(name, s, len);
    80004234:	2601                	sext.w	a2,a2
    80004236:	85a6                	mv	a1,s1
    80004238:	8556                	mv	a0,s5
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	b6e080e7          	jalr	-1170(ra) # 80000da8 <memmove>
    name[len] = 0;
    80004242:	9cd6                	add	s9,s9,s5
    80004244:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004248:	84ce                	mv	s1,s3
    8000424a:	b7bd                	j	800041b8 <namex+0xba>
  if(nameiparent){
    8000424c:	f00b0de3          	beqz	s6,80004166 <namex+0x68>
    iput(ip);
    80004250:	8552                	mv	a0,s4
    80004252:	00000097          	auipc	ra,0x0
    80004256:	ad2080e7          	jalr	-1326(ra) # 80003d24 <iput>
    return 0;
    8000425a:	4a01                	li	s4,0
    8000425c:	b729                	j	80004166 <namex+0x68>

000000008000425e <dirlink>:
{
    8000425e:	7139                	add	sp,sp,-64
    80004260:	fc06                	sd	ra,56(sp)
    80004262:	f822                	sd	s0,48(sp)
    80004264:	f426                	sd	s1,40(sp)
    80004266:	f04a                	sd	s2,32(sp)
    80004268:	ec4e                	sd	s3,24(sp)
    8000426a:	e852                	sd	s4,16(sp)
    8000426c:	0080                	add	s0,sp,64
    8000426e:	892a                	mv	s2,a0
    80004270:	8a2e                	mv	s4,a1
    80004272:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004274:	4601                	li	a2,0
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	dd8080e7          	jalr	-552(ra) # 8000404e <dirlookup>
    8000427e:	e93d                	bnez	a0,800042f4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004280:	04c92483          	lw	s1,76(s2)
    80004284:	c49d                	beqz	s1,800042b2 <dirlink+0x54>
    80004286:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004288:	4741                	li	a4,16
    8000428a:	86a6                	mv	a3,s1
    8000428c:	fc040613          	add	a2,s0,-64
    80004290:	4581                	li	a1,0
    80004292:	854a                	mv	a0,s2
    80004294:	00000097          	auipc	ra,0x0
    80004298:	b8a080e7          	jalr	-1142(ra) # 80003e1e <readi>
    8000429c:	47c1                	li	a5,16
    8000429e:	06f51163          	bne	a0,a5,80004300 <dirlink+0xa2>
    if(de.inum == 0)
    800042a2:	fc045783          	lhu	a5,-64(s0)
    800042a6:	c791                	beqz	a5,800042b2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a8:	24c1                	addw	s1,s1,16
    800042aa:	04c92783          	lw	a5,76(s2)
    800042ae:	fcf4ede3          	bltu	s1,a5,80004288 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042b2:	4639                	li	a2,14
    800042b4:	85d2                	mv	a1,s4
    800042b6:	fc240513          	add	a0,s0,-62
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	b9e080e7          	jalr	-1122(ra) # 80000e58 <strncpy>
  de.inum = inum;
    800042c2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c6:	4741                	li	a4,16
    800042c8:	86a6                	mv	a3,s1
    800042ca:	fc040613          	add	a2,s0,-64
    800042ce:	4581                	li	a1,0
    800042d0:	854a                	mv	a0,s2
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	c44080e7          	jalr	-956(ra) # 80003f16 <writei>
    800042da:	1541                	add	a0,a0,-16
    800042dc:	00a03533          	snez	a0,a0
    800042e0:	40a00533          	neg	a0,a0
}
    800042e4:	70e2                	ld	ra,56(sp)
    800042e6:	7442                	ld	s0,48(sp)
    800042e8:	74a2                	ld	s1,40(sp)
    800042ea:	7902                	ld	s2,32(sp)
    800042ec:	69e2                	ld	s3,24(sp)
    800042ee:	6a42                	ld	s4,16(sp)
    800042f0:	6121                	add	sp,sp,64
    800042f2:	8082                	ret
    iput(ip);
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	a30080e7          	jalr	-1488(ra) # 80003d24 <iput>
    return -1;
    800042fc:	557d                	li	a0,-1
    800042fe:	b7dd                	j	800042e4 <dirlink+0x86>
      panic("dirlink read");
    80004300:	00004517          	auipc	a0,0x4
    80004304:	33050513          	add	a0,a0,816 # 80008630 <syscalls+0x1e0>
    80004308:	ffffc097          	auipc	ra,0xffffc
    8000430c:	234080e7          	jalr	564(ra) # 8000053c <panic>

0000000080004310 <namei>:

struct inode*
namei(char *path)
{
    80004310:	1101                	add	sp,sp,-32
    80004312:	ec06                	sd	ra,24(sp)
    80004314:	e822                	sd	s0,16(sp)
    80004316:	1000                	add	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004318:	fe040613          	add	a2,s0,-32
    8000431c:	4581                	li	a1,0
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	de0080e7          	jalr	-544(ra) # 800040fe <namex>
}
    80004326:	60e2                	ld	ra,24(sp)
    80004328:	6442                	ld	s0,16(sp)
    8000432a:	6105                	add	sp,sp,32
    8000432c:	8082                	ret

000000008000432e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000432e:	1141                	add	sp,sp,-16
    80004330:	e406                	sd	ra,8(sp)
    80004332:	e022                	sd	s0,0(sp)
    80004334:	0800                	add	s0,sp,16
    80004336:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004338:	4585                	li	a1,1
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	dc4080e7          	jalr	-572(ra) # 800040fe <namex>
}
    80004342:	60a2                	ld	ra,8(sp)
    80004344:	6402                	ld	s0,0(sp)
    80004346:	0141                	add	sp,sp,16
    80004348:	8082                	ret

000000008000434a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000434a:	1101                	add	sp,sp,-32
    8000434c:	ec06                	sd	ra,24(sp)
    8000434e:	e822                	sd	s0,16(sp)
    80004350:	e426                	sd	s1,8(sp)
    80004352:	e04a                	sd	s2,0(sp)
    80004354:	1000                	add	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004356:	0023d917          	auipc	s2,0x23d
    8000435a:	de290913          	add	s2,s2,-542 # 80241138 <log>
    8000435e:	01892583          	lw	a1,24(s2)
    80004362:	02892503          	lw	a0,40(s2)
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	ff4080e7          	jalr	-12(ra) # 8000335a <bread>
    8000436e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004370:	02c92603          	lw	a2,44(s2)
    80004374:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004376:	00c05f63          	blez	a2,80004394 <write_head+0x4a>
    8000437a:	0023d717          	auipc	a4,0x23d
    8000437e:	dee70713          	add	a4,a4,-530 # 80241168 <log+0x30>
    80004382:	87aa                	mv	a5,a0
    80004384:	060a                	sll	a2,a2,0x2
    80004386:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004388:	4314                	lw	a3,0(a4)
    8000438a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000438c:	0711                	add	a4,a4,4
    8000438e:	0791                	add	a5,a5,4
    80004390:	fec79ce3          	bne	a5,a2,80004388 <write_head+0x3e>
  }
  bwrite(buf);
    80004394:	8526                	mv	a0,s1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	0b6080e7          	jalr	182(ra) # 8000344c <bwrite>
  brelse(buf);
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	0ea080e7          	jalr	234(ra) # 8000348a <brelse>
}
    800043a8:	60e2                	ld	ra,24(sp)
    800043aa:	6442                	ld	s0,16(sp)
    800043ac:	64a2                	ld	s1,8(sp)
    800043ae:	6902                	ld	s2,0(sp)
    800043b0:	6105                	add	sp,sp,32
    800043b2:	8082                	ret

00000000800043b4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b4:	0023d797          	auipc	a5,0x23d
    800043b8:	db07a783          	lw	a5,-592(a5) # 80241164 <log+0x2c>
    800043bc:	0af05d63          	blez	a5,80004476 <install_trans+0xc2>
{
    800043c0:	7139                	add	sp,sp,-64
    800043c2:	fc06                	sd	ra,56(sp)
    800043c4:	f822                	sd	s0,48(sp)
    800043c6:	f426                	sd	s1,40(sp)
    800043c8:	f04a                	sd	s2,32(sp)
    800043ca:	ec4e                	sd	s3,24(sp)
    800043cc:	e852                	sd	s4,16(sp)
    800043ce:	e456                	sd	s5,8(sp)
    800043d0:	e05a                	sd	s6,0(sp)
    800043d2:	0080                	add	s0,sp,64
    800043d4:	8b2a                	mv	s6,a0
    800043d6:	0023da97          	auipc	s5,0x23d
    800043da:	d92a8a93          	add	s5,s5,-622 # 80241168 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043de:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043e0:	0023d997          	auipc	s3,0x23d
    800043e4:	d5898993          	add	s3,s3,-680 # 80241138 <log>
    800043e8:	a00d                	j	8000440a <install_trans+0x56>
    brelse(lbuf);
    800043ea:	854a                	mv	a0,s2
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	09e080e7          	jalr	158(ra) # 8000348a <brelse>
    brelse(dbuf);
    800043f4:	8526                	mv	a0,s1
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	094080e7          	jalr	148(ra) # 8000348a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fe:	2a05                	addw	s4,s4,1
    80004400:	0a91                	add	s5,s5,4
    80004402:	02c9a783          	lw	a5,44(s3)
    80004406:	04fa5e63          	bge	s4,a5,80004462 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000440a:	0189a583          	lw	a1,24(s3)
    8000440e:	014585bb          	addw	a1,a1,s4
    80004412:	2585                	addw	a1,a1,1
    80004414:	0289a503          	lw	a0,40(s3)
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	f42080e7          	jalr	-190(ra) # 8000335a <bread>
    80004420:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004422:	000aa583          	lw	a1,0(s5)
    80004426:	0289a503          	lw	a0,40(s3)
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	f30080e7          	jalr	-208(ra) # 8000335a <bread>
    80004432:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004434:	40000613          	li	a2,1024
    80004438:	05890593          	add	a1,s2,88
    8000443c:	05850513          	add	a0,a0,88
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	968080e7          	jalr	-1688(ra) # 80000da8 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	002080e7          	jalr	2(ra) # 8000344c <bwrite>
    if(recovering == 0)
    80004452:	f80b1ce3          	bnez	s6,800043ea <install_trans+0x36>
      bunpin(dbuf);
    80004456:	8526                	mv	a0,s1
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	10a080e7          	jalr	266(ra) # 80003562 <bunpin>
    80004460:	b769                	j	800043ea <install_trans+0x36>
}
    80004462:	70e2                	ld	ra,56(sp)
    80004464:	7442                	ld	s0,48(sp)
    80004466:	74a2                	ld	s1,40(sp)
    80004468:	7902                	ld	s2,32(sp)
    8000446a:	69e2                	ld	s3,24(sp)
    8000446c:	6a42                	ld	s4,16(sp)
    8000446e:	6aa2                	ld	s5,8(sp)
    80004470:	6b02                	ld	s6,0(sp)
    80004472:	6121                	add	sp,sp,64
    80004474:	8082                	ret
    80004476:	8082                	ret

0000000080004478 <initlog>:
{
    80004478:	7179                	add	sp,sp,-48
    8000447a:	f406                	sd	ra,40(sp)
    8000447c:	f022                	sd	s0,32(sp)
    8000447e:	ec26                	sd	s1,24(sp)
    80004480:	e84a                	sd	s2,16(sp)
    80004482:	e44e                	sd	s3,8(sp)
    80004484:	1800                	add	s0,sp,48
    80004486:	892a                	mv	s2,a0
    80004488:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000448a:	0023d497          	auipc	s1,0x23d
    8000448e:	cae48493          	add	s1,s1,-850 # 80241138 <log>
    80004492:	00004597          	auipc	a1,0x4
    80004496:	1ae58593          	add	a1,a1,430 # 80008640 <syscalls+0x1f0>
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	724080e7          	jalr	1828(ra) # 80000bc0 <initlock>
  log.start = sb->logstart;
    800044a4:	0149a583          	lw	a1,20(s3)
    800044a8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044aa:	0109a783          	lw	a5,16(s3)
    800044ae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044b0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044b4:	854a                	mv	a0,s2
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	ea4080e7          	jalr	-348(ra) # 8000335a <bread>
  log.lh.n = lh->n;
    800044be:	4d30                	lw	a2,88(a0)
    800044c0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044c2:	00c05f63          	blez	a2,800044e0 <initlog+0x68>
    800044c6:	87aa                	mv	a5,a0
    800044c8:	0023d717          	auipc	a4,0x23d
    800044cc:	ca070713          	add	a4,a4,-864 # 80241168 <log+0x30>
    800044d0:	060a                	sll	a2,a2,0x2
    800044d2:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800044d4:	4ff4                	lw	a3,92(a5)
    800044d6:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044d8:	0791                	add	a5,a5,4
    800044da:	0711                	add	a4,a4,4
    800044dc:	fec79ce3          	bne	a5,a2,800044d4 <initlog+0x5c>
  brelse(buf);
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	faa080e7          	jalr	-86(ra) # 8000348a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044e8:	4505                	li	a0,1
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	eca080e7          	jalr	-310(ra) # 800043b4 <install_trans>
  log.lh.n = 0;
    800044f2:	0023d797          	auipc	a5,0x23d
    800044f6:	c607a923          	sw	zero,-910(a5) # 80241164 <log+0x2c>
  write_head(); // clear the log
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	e50080e7          	jalr	-432(ra) # 8000434a <write_head>
}
    80004502:	70a2                	ld	ra,40(sp)
    80004504:	7402                	ld	s0,32(sp)
    80004506:	64e2                	ld	s1,24(sp)
    80004508:	6942                	ld	s2,16(sp)
    8000450a:	69a2                	ld	s3,8(sp)
    8000450c:	6145                	add	sp,sp,48
    8000450e:	8082                	ret

0000000080004510 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004510:	1101                	add	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	add	s0,sp,32
  acquire(&log.lock);
    8000451c:	0023d517          	auipc	a0,0x23d
    80004520:	c1c50513          	add	a0,a0,-996 # 80241138 <log>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	72c080e7          	jalr	1836(ra) # 80000c50 <acquire>
  while(1){
    if(log.committing){
    8000452c:	0023d497          	auipc	s1,0x23d
    80004530:	c0c48493          	add	s1,s1,-1012 # 80241138 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004534:	4979                	li	s2,30
    80004536:	a039                	j	80004544 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004538:	85a6                	mv	a1,s1
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffe097          	auipc	ra,0xffffe
    80004540:	c90080e7          	jalr	-880(ra) # 800021cc <sleep>
    if(log.committing){
    80004544:	50dc                	lw	a5,36(s1)
    80004546:	fbed                	bnez	a5,80004538 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004548:	5098                	lw	a4,32(s1)
    8000454a:	2705                	addw	a4,a4,1
    8000454c:	0027179b          	sllw	a5,a4,0x2
    80004550:	9fb9                	addw	a5,a5,a4
    80004552:	0017979b          	sllw	a5,a5,0x1
    80004556:	54d4                	lw	a3,44(s1)
    80004558:	9fb5                	addw	a5,a5,a3
    8000455a:	00f95963          	bge	s2,a5,8000456c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000455e:	85a6                	mv	a1,s1
    80004560:	8526                	mv	a0,s1
    80004562:	ffffe097          	auipc	ra,0xffffe
    80004566:	c6a080e7          	jalr	-918(ra) # 800021cc <sleep>
    8000456a:	bfe9                	j	80004544 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000456c:	0023d517          	auipc	a0,0x23d
    80004570:	bcc50513          	add	a0,a0,-1076 # 80241138 <log>
    80004574:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	78e080e7          	jalr	1934(ra) # 80000d04 <release>
      break;
    }
  }
}
    8000457e:	60e2                	ld	ra,24(sp)
    80004580:	6442                	ld	s0,16(sp)
    80004582:	64a2                	ld	s1,8(sp)
    80004584:	6902                	ld	s2,0(sp)
    80004586:	6105                	add	sp,sp,32
    80004588:	8082                	ret

000000008000458a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000458a:	7139                	add	sp,sp,-64
    8000458c:	fc06                	sd	ra,56(sp)
    8000458e:	f822                	sd	s0,48(sp)
    80004590:	f426                	sd	s1,40(sp)
    80004592:	f04a                	sd	s2,32(sp)
    80004594:	ec4e                	sd	s3,24(sp)
    80004596:	e852                	sd	s4,16(sp)
    80004598:	e456                	sd	s5,8(sp)
    8000459a:	0080                	add	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000459c:	0023d497          	auipc	s1,0x23d
    800045a0:	b9c48493          	add	s1,s1,-1124 # 80241138 <log>
    800045a4:	8526                	mv	a0,s1
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	6aa080e7          	jalr	1706(ra) # 80000c50 <acquire>
  log.outstanding -= 1;
    800045ae:	509c                	lw	a5,32(s1)
    800045b0:	37fd                	addw	a5,a5,-1
    800045b2:	0007891b          	sext.w	s2,a5
    800045b6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045b8:	50dc                	lw	a5,36(s1)
    800045ba:	e7b9                	bnez	a5,80004608 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045bc:	04091e63          	bnez	s2,80004618 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045c0:	0023d497          	auipc	s1,0x23d
    800045c4:	b7848493          	add	s1,s1,-1160 # 80241138 <log>
    800045c8:	4785                	li	a5,1
    800045ca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	736080e7          	jalr	1846(ra) # 80000d04 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045d6:	54dc                	lw	a5,44(s1)
    800045d8:	06f04763          	bgtz	a5,80004646 <end_op+0xbc>
    acquire(&log.lock);
    800045dc:	0023d497          	auipc	s1,0x23d
    800045e0:	b5c48493          	add	s1,s1,-1188 # 80241138 <log>
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	66a080e7          	jalr	1642(ra) # 80000c50 <acquire>
    log.committing = 0;
    800045ee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045f2:	8526                	mv	a0,s1
    800045f4:	ffffe097          	auipc	ra,0xffffe
    800045f8:	c3c080e7          	jalr	-964(ra) # 80002230 <wakeup>
    release(&log.lock);
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	706080e7          	jalr	1798(ra) # 80000d04 <release>
}
    80004606:	a03d                	j	80004634 <end_op+0xaa>
    panic("log.committing");
    80004608:	00004517          	auipc	a0,0x4
    8000460c:	04050513          	add	a0,a0,64 # 80008648 <syscalls+0x1f8>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
    wakeup(&log);
    80004618:	0023d497          	auipc	s1,0x23d
    8000461c:	b2048493          	add	s1,s1,-1248 # 80241138 <log>
    80004620:	8526                	mv	a0,s1
    80004622:	ffffe097          	auipc	ra,0xffffe
    80004626:	c0e080e7          	jalr	-1010(ra) # 80002230 <wakeup>
  release(&log.lock);
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	6d8080e7          	jalr	1752(ra) # 80000d04 <release>
}
    80004634:	70e2                	ld	ra,56(sp)
    80004636:	7442                	ld	s0,48(sp)
    80004638:	74a2                	ld	s1,40(sp)
    8000463a:	7902                	ld	s2,32(sp)
    8000463c:	69e2                	ld	s3,24(sp)
    8000463e:	6a42                	ld	s4,16(sp)
    80004640:	6aa2                	ld	s5,8(sp)
    80004642:	6121                	add	sp,sp,64
    80004644:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004646:	0023da97          	auipc	s5,0x23d
    8000464a:	b22a8a93          	add	s5,s5,-1246 # 80241168 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000464e:	0023da17          	auipc	s4,0x23d
    80004652:	aeaa0a13          	add	s4,s4,-1302 # 80241138 <log>
    80004656:	018a2583          	lw	a1,24(s4)
    8000465a:	012585bb          	addw	a1,a1,s2
    8000465e:	2585                	addw	a1,a1,1
    80004660:	028a2503          	lw	a0,40(s4)
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	cf6080e7          	jalr	-778(ra) # 8000335a <bread>
    8000466c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000466e:	000aa583          	lw	a1,0(s5)
    80004672:	028a2503          	lw	a0,40(s4)
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	ce4080e7          	jalr	-796(ra) # 8000335a <bread>
    8000467e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004680:	40000613          	li	a2,1024
    80004684:	05850593          	add	a1,a0,88
    80004688:	05848513          	add	a0,s1,88
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	71c080e7          	jalr	1820(ra) # 80000da8 <memmove>
    bwrite(to);  // write the log
    80004694:	8526                	mv	a0,s1
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	db6080e7          	jalr	-586(ra) # 8000344c <bwrite>
    brelse(from);
    8000469e:	854e                	mv	a0,s3
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	dea080e7          	jalr	-534(ra) # 8000348a <brelse>
    brelse(to);
    800046a8:	8526                	mv	a0,s1
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	de0080e7          	jalr	-544(ra) # 8000348a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b2:	2905                	addw	s2,s2,1
    800046b4:	0a91                	add	s5,s5,4
    800046b6:	02ca2783          	lw	a5,44(s4)
    800046ba:	f8f94ee3          	blt	s2,a5,80004656 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046be:	00000097          	auipc	ra,0x0
    800046c2:	c8c080e7          	jalr	-884(ra) # 8000434a <write_head>
    install_trans(0); // Now install writes to home locations
    800046c6:	4501                	li	a0,0
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	cec080e7          	jalr	-788(ra) # 800043b4 <install_trans>
    log.lh.n = 0;
    800046d0:	0023d797          	auipc	a5,0x23d
    800046d4:	a807aa23          	sw	zero,-1388(a5) # 80241164 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	c72080e7          	jalr	-910(ra) # 8000434a <write_head>
    800046e0:	bdf5                	j	800045dc <end_op+0x52>

00000000800046e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046e2:	1101                	add	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	e426                	sd	s1,8(sp)
    800046ea:	e04a                	sd	s2,0(sp)
    800046ec:	1000                	add	s0,sp,32
    800046ee:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046f0:	0023d917          	auipc	s2,0x23d
    800046f4:	a4890913          	add	s2,s2,-1464 # 80241138 <log>
    800046f8:	854a                	mv	a0,s2
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	556080e7          	jalr	1366(ra) # 80000c50 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004702:	02c92603          	lw	a2,44(s2)
    80004706:	47f5                	li	a5,29
    80004708:	06c7c563          	blt	a5,a2,80004772 <log_write+0x90>
    8000470c:	0023d797          	auipc	a5,0x23d
    80004710:	a487a783          	lw	a5,-1464(a5) # 80241154 <log+0x1c>
    80004714:	37fd                	addw	a5,a5,-1
    80004716:	04f65e63          	bge	a2,a5,80004772 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000471a:	0023d797          	auipc	a5,0x23d
    8000471e:	a3e7a783          	lw	a5,-1474(a5) # 80241158 <log+0x20>
    80004722:	06f05063          	blez	a5,80004782 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004726:	4781                	li	a5,0
    80004728:	06c05563          	blez	a2,80004792 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000472c:	44cc                	lw	a1,12(s1)
    8000472e:	0023d717          	auipc	a4,0x23d
    80004732:	a3a70713          	add	a4,a4,-1478 # 80241168 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004736:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004738:	4314                	lw	a3,0(a4)
    8000473a:	04b68c63          	beq	a3,a1,80004792 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000473e:	2785                	addw	a5,a5,1
    80004740:	0711                	add	a4,a4,4
    80004742:	fef61be3          	bne	a2,a5,80004738 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004746:	0621                	add	a2,a2,8
    80004748:	060a                	sll	a2,a2,0x2
    8000474a:	0023d797          	auipc	a5,0x23d
    8000474e:	9ee78793          	add	a5,a5,-1554 # 80241138 <log>
    80004752:	97b2                	add	a5,a5,a2
    80004754:	44d8                	lw	a4,12(s1)
    80004756:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004758:	8526                	mv	a0,s1
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	dcc080e7          	jalr	-564(ra) # 80003526 <bpin>
    log.lh.n++;
    80004762:	0023d717          	auipc	a4,0x23d
    80004766:	9d670713          	add	a4,a4,-1578 # 80241138 <log>
    8000476a:	575c                	lw	a5,44(a4)
    8000476c:	2785                	addw	a5,a5,1
    8000476e:	d75c                	sw	a5,44(a4)
    80004770:	a82d                	j	800047aa <log_write+0xc8>
    panic("too big a transaction");
    80004772:	00004517          	auipc	a0,0x4
    80004776:	ee650513          	add	a0,a0,-282 # 80008658 <syscalls+0x208>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	dc2080e7          	jalr	-574(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004782:	00004517          	auipc	a0,0x4
    80004786:	eee50513          	add	a0,a0,-274 # 80008670 <syscalls+0x220>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	db2080e7          	jalr	-590(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004792:	00878693          	add	a3,a5,8
    80004796:	068a                	sll	a3,a3,0x2
    80004798:	0023d717          	auipc	a4,0x23d
    8000479c:	9a070713          	add	a4,a4,-1632 # 80241138 <log>
    800047a0:	9736                	add	a4,a4,a3
    800047a2:	44d4                	lw	a3,12(s1)
    800047a4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047a6:	faf609e3          	beq	a2,a5,80004758 <log_write+0x76>
  }
  release(&log.lock);
    800047aa:	0023d517          	auipc	a0,0x23d
    800047ae:	98e50513          	add	a0,a0,-1650 # 80241138 <log>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	552080e7          	jalr	1362(ra) # 80000d04 <release>
}
    800047ba:	60e2                	ld	ra,24(sp)
    800047bc:	6442                	ld	s0,16(sp)
    800047be:	64a2                	ld	s1,8(sp)
    800047c0:	6902                	ld	s2,0(sp)
    800047c2:	6105                	add	sp,sp,32
    800047c4:	8082                	ret

00000000800047c6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047c6:	1101                	add	sp,sp,-32
    800047c8:	ec06                	sd	ra,24(sp)
    800047ca:	e822                	sd	s0,16(sp)
    800047cc:	e426                	sd	s1,8(sp)
    800047ce:	e04a                	sd	s2,0(sp)
    800047d0:	1000                	add	s0,sp,32
    800047d2:	84aa                	mv	s1,a0
    800047d4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047d6:	00004597          	auipc	a1,0x4
    800047da:	eba58593          	add	a1,a1,-326 # 80008690 <syscalls+0x240>
    800047de:	0521                	add	a0,a0,8
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	3e0080e7          	jalr	992(ra) # 80000bc0 <initlock>
  lk->name = name;
    800047e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f0:	0204a423          	sw	zero,40(s1)
}
    800047f4:	60e2                	ld	ra,24(sp)
    800047f6:	6442                	ld	s0,16(sp)
    800047f8:	64a2                	ld	s1,8(sp)
    800047fa:	6902                	ld	s2,0(sp)
    800047fc:	6105                	add	sp,sp,32
    800047fe:	8082                	ret

0000000080004800 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004800:	1101                	add	sp,sp,-32
    80004802:	ec06                	sd	ra,24(sp)
    80004804:	e822                	sd	s0,16(sp)
    80004806:	e426                	sd	s1,8(sp)
    80004808:	e04a                	sd	s2,0(sp)
    8000480a:	1000                	add	s0,sp,32
    8000480c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000480e:	00850913          	add	s2,a0,8
    80004812:	854a                	mv	a0,s2
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	43c080e7          	jalr	1084(ra) # 80000c50 <acquire>
  while (lk->locked) {
    8000481c:	409c                	lw	a5,0(s1)
    8000481e:	cb89                	beqz	a5,80004830 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004820:	85ca                	mv	a1,s2
    80004822:	8526                	mv	a0,s1
    80004824:	ffffe097          	auipc	ra,0xffffe
    80004828:	9a8080e7          	jalr	-1624(ra) # 800021cc <sleep>
  while (lk->locked) {
    8000482c:	409c                	lw	a5,0(s1)
    8000482e:	fbed                	bnez	a5,80004820 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004830:	4785                	li	a5,1
    80004832:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004834:	ffffd097          	auipc	ra,0xffffd
    80004838:	2cc080e7          	jalr	716(ra) # 80001b00 <myproc>
    8000483c:	591c                	lw	a5,48(a0)
    8000483e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004840:	854a                	mv	a0,s2
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	4c2080e7          	jalr	1218(ra) # 80000d04 <release>
}
    8000484a:	60e2                	ld	ra,24(sp)
    8000484c:	6442                	ld	s0,16(sp)
    8000484e:	64a2                	ld	s1,8(sp)
    80004850:	6902                	ld	s2,0(sp)
    80004852:	6105                	add	sp,sp,32
    80004854:	8082                	ret

0000000080004856 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004856:	1101                	add	sp,sp,-32
    80004858:	ec06                	sd	ra,24(sp)
    8000485a:	e822                	sd	s0,16(sp)
    8000485c:	e426                	sd	s1,8(sp)
    8000485e:	e04a                	sd	s2,0(sp)
    80004860:	1000                	add	s0,sp,32
    80004862:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004864:	00850913          	add	s2,a0,8
    80004868:	854a                	mv	a0,s2
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	3e6080e7          	jalr	998(ra) # 80000c50 <acquire>
  lk->locked = 0;
    80004872:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004876:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000487a:	8526                	mv	a0,s1
    8000487c:	ffffe097          	auipc	ra,0xffffe
    80004880:	9b4080e7          	jalr	-1612(ra) # 80002230 <wakeup>
  release(&lk->lk);
    80004884:	854a                	mv	a0,s2
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	47e080e7          	jalr	1150(ra) # 80000d04 <release>
}
    8000488e:	60e2                	ld	ra,24(sp)
    80004890:	6442                	ld	s0,16(sp)
    80004892:	64a2                	ld	s1,8(sp)
    80004894:	6902                	ld	s2,0(sp)
    80004896:	6105                	add	sp,sp,32
    80004898:	8082                	ret

000000008000489a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000489a:	7179                	add	sp,sp,-48
    8000489c:	f406                	sd	ra,40(sp)
    8000489e:	f022                	sd	s0,32(sp)
    800048a0:	ec26                	sd	s1,24(sp)
    800048a2:	e84a                	sd	s2,16(sp)
    800048a4:	e44e                	sd	s3,8(sp)
    800048a6:	1800                	add	s0,sp,48
    800048a8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048aa:	00850913          	add	s2,a0,8
    800048ae:	854a                	mv	a0,s2
    800048b0:	ffffc097          	auipc	ra,0xffffc
    800048b4:	3a0080e7          	jalr	928(ra) # 80000c50 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048b8:	409c                	lw	a5,0(s1)
    800048ba:	ef99                	bnez	a5,800048d8 <holdingsleep+0x3e>
    800048bc:	4481                	li	s1,0
  release(&lk->lk);
    800048be:	854a                	mv	a0,s2
    800048c0:	ffffc097          	auipc	ra,0xffffc
    800048c4:	444080e7          	jalr	1092(ra) # 80000d04 <release>
  return r;
}
    800048c8:	8526                	mv	a0,s1
    800048ca:	70a2                	ld	ra,40(sp)
    800048cc:	7402                	ld	s0,32(sp)
    800048ce:	64e2                	ld	s1,24(sp)
    800048d0:	6942                	ld	s2,16(sp)
    800048d2:	69a2                	ld	s3,8(sp)
    800048d4:	6145                	add	sp,sp,48
    800048d6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048d8:	0284a983          	lw	s3,40(s1)
    800048dc:	ffffd097          	auipc	ra,0xffffd
    800048e0:	224080e7          	jalr	548(ra) # 80001b00 <myproc>
    800048e4:	5904                	lw	s1,48(a0)
    800048e6:	413484b3          	sub	s1,s1,s3
    800048ea:	0014b493          	seqz	s1,s1
    800048ee:	bfc1                	j	800048be <holdingsleep+0x24>

00000000800048f0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048f0:	1141                	add	sp,sp,-16
    800048f2:	e406                	sd	ra,8(sp)
    800048f4:	e022                	sd	s0,0(sp)
    800048f6:	0800                	add	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048f8:	00004597          	auipc	a1,0x4
    800048fc:	da858593          	add	a1,a1,-600 # 800086a0 <syscalls+0x250>
    80004900:	0023d517          	auipc	a0,0x23d
    80004904:	98050513          	add	a0,a0,-1664 # 80241280 <ftable>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	2b8080e7          	jalr	696(ra) # 80000bc0 <initlock>
}
    80004910:	60a2                	ld	ra,8(sp)
    80004912:	6402                	ld	s0,0(sp)
    80004914:	0141                	add	sp,sp,16
    80004916:	8082                	ret

0000000080004918 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004918:	1101                	add	sp,sp,-32
    8000491a:	ec06                	sd	ra,24(sp)
    8000491c:	e822                	sd	s0,16(sp)
    8000491e:	e426                	sd	s1,8(sp)
    80004920:	1000                	add	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004922:	0023d517          	auipc	a0,0x23d
    80004926:	95e50513          	add	a0,a0,-1698 # 80241280 <ftable>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	326080e7          	jalr	806(ra) # 80000c50 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004932:	0023d497          	auipc	s1,0x23d
    80004936:	96648493          	add	s1,s1,-1690 # 80241298 <ftable+0x18>
    8000493a:	0023e717          	auipc	a4,0x23e
    8000493e:	8fe70713          	add	a4,a4,-1794 # 80242238 <disk>
    if(f->ref == 0){
    80004942:	40dc                	lw	a5,4(s1)
    80004944:	cf99                	beqz	a5,80004962 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004946:	02848493          	add	s1,s1,40
    8000494a:	fee49ce3          	bne	s1,a4,80004942 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000494e:	0023d517          	auipc	a0,0x23d
    80004952:	93250513          	add	a0,a0,-1742 # 80241280 <ftable>
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	3ae080e7          	jalr	942(ra) # 80000d04 <release>
  return 0;
    8000495e:	4481                	li	s1,0
    80004960:	a819                	j	80004976 <filealloc+0x5e>
      f->ref = 1;
    80004962:	4785                	li	a5,1
    80004964:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004966:	0023d517          	auipc	a0,0x23d
    8000496a:	91a50513          	add	a0,a0,-1766 # 80241280 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	396080e7          	jalr	918(ra) # 80000d04 <release>
}
    80004976:	8526                	mv	a0,s1
    80004978:	60e2                	ld	ra,24(sp)
    8000497a:	6442                	ld	s0,16(sp)
    8000497c:	64a2                	ld	s1,8(sp)
    8000497e:	6105                	add	sp,sp,32
    80004980:	8082                	ret

0000000080004982 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004982:	1101                	add	sp,sp,-32
    80004984:	ec06                	sd	ra,24(sp)
    80004986:	e822                	sd	s0,16(sp)
    80004988:	e426                	sd	s1,8(sp)
    8000498a:	1000                	add	s0,sp,32
    8000498c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000498e:	0023d517          	auipc	a0,0x23d
    80004992:	8f250513          	add	a0,a0,-1806 # 80241280 <ftable>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	2ba080e7          	jalr	698(ra) # 80000c50 <acquire>
  if(f->ref < 1)
    8000499e:	40dc                	lw	a5,4(s1)
    800049a0:	02f05263          	blez	a5,800049c4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049a4:	2785                	addw	a5,a5,1
    800049a6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049a8:	0023d517          	auipc	a0,0x23d
    800049ac:	8d850513          	add	a0,a0,-1832 # 80241280 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	354080e7          	jalr	852(ra) # 80000d04 <release>
  return f;
}
    800049b8:	8526                	mv	a0,s1
    800049ba:	60e2                	ld	ra,24(sp)
    800049bc:	6442                	ld	s0,16(sp)
    800049be:	64a2                	ld	s1,8(sp)
    800049c0:	6105                	add	sp,sp,32
    800049c2:	8082                	ret
    panic("filedup");
    800049c4:	00004517          	auipc	a0,0x4
    800049c8:	ce450513          	add	a0,a0,-796 # 800086a8 <syscalls+0x258>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	b70080e7          	jalr	-1168(ra) # 8000053c <panic>

00000000800049d4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049d4:	7139                	add	sp,sp,-64
    800049d6:	fc06                	sd	ra,56(sp)
    800049d8:	f822                	sd	s0,48(sp)
    800049da:	f426                	sd	s1,40(sp)
    800049dc:	f04a                	sd	s2,32(sp)
    800049de:	ec4e                	sd	s3,24(sp)
    800049e0:	e852                	sd	s4,16(sp)
    800049e2:	e456                	sd	s5,8(sp)
    800049e4:	0080                	add	s0,sp,64
    800049e6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049e8:	0023d517          	auipc	a0,0x23d
    800049ec:	89850513          	add	a0,a0,-1896 # 80241280 <ftable>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	260080e7          	jalr	608(ra) # 80000c50 <acquire>
  if(f->ref < 1)
    800049f8:	40dc                	lw	a5,4(s1)
    800049fa:	06f05163          	blez	a5,80004a5c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049fe:	37fd                	addw	a5,a5,-1
    80004a00:	0007871b          	sext.w	a4,a5
    80004a04:	c0dc                	sw	a5,4(s1)
    80004a06:	06e04363          	bgtz	a4,80004a6c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a0a:	0004a903          	lw	s2,0(s1)
    80004a0e:	0094ca83          	lbu	s5,9(s1)
    80004a12:	0104ba03          	ld	s4,16(s1)
    80004a16:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a1a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a1e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a22:	0023d517          	auipc	a0,0x23d
    80004a26:	85e50513          	add	a0,a0,-1954 # 80241280 <ftable>
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	2da080e7          	jalr	730(ra) # 80000d04 <release>

  if(ff.type == FD_PIPE){
    80004a32:	4785                	li	a5,1
    80004a34:	04f90d63          	beq	s2,a5,80004a8e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a38:	3979                	addw	s2,s2,-2
    80004a3a:	4785                	li	a5,1
    80004a3c:	0527e063          	bltu	a5,s2,80004a7c <fileclose+0xa8>
    begin_op();
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	ad0080e7          	jalr	-1328(ra) # 80004510 <begin_op>
    iput(ff.ip);
    80004a48:	854e                	mv	a0,s3
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	2da080e7          	jalr	730(ra) # 80003d24 <iput>
    end_op();
    80004a52:	00000097          	auipc	ra,0x0
    80004a56:	b38080e7          	jalr	-1224(ra) # 8000458a <end_op>
    80004a5a:	a00d                	j	80004a7c <fileclose+0xa8>
    panic("fileclose");
    80004a5c:	00004517          	auipc	a0,0x4
    80004a60:	c5450513          	add	a0,a0,-940 # 800086b0 <syscalls+0x260>
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	ad8080e7          	jalr	-1320(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004a6c:	0023d517          	auipc	a0,0x23d
    80004a70:	81450513          	add	a0,a0,-2028 # 80241280 <ftable>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	290080e7          	jalr	656(ra) # 80000d04 <release>
  }
}
    80004a7c:	70e2                	ld	ra,56(sp)
    80004a7e:	7442                	ld	s0,48(sp)
    80004a80:	74a2                	ld	s1,40(sp)
    80004a82:	7902                	ld	s2,32(sp)
    80004a84:	69e2                	ld	s3,24(sp)
    80004a86:	6a42                	ld	s4,16(sp)
    80004a88:	6aa2                	ld	s5,8(sp)
    80004a8a:	6121                	add	sp,sp,64
    80004a8c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a8e:	85d6                	mv	a1,s5
    80004a90:	8552                	mv	a0,s4
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	348080e7          	jalr	840(ra) # 80004dda <pipeclose>
    80004a9a:	b7cd                	j	80004a7c <fileclose+0xa8>

0000000080004a9c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a9c:	715d                	add	sp,sp,-80
    80004a9e:	e486                	sd	ra,72(sp)
    80004aa0:	e0a2                	sd	s0,64(sp)
    80004aa2:	fc26                	sd	s1,56(sp)
    80004aa4:	f84a                	sd	s2,48(sp)
    80004aa6:	f44e                	sd	s3,40(sp)
    80004aa8:	0880                	add	s0,sp,80
    80004aaa:	84aa                	mv	s1,a0
    80004aac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	052080e7          	jalr	82(ra) # 80001b00 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ab6:	409c                	lw	a5,0(s1)
    80004ab8:	37f9                	addw	a5,a5,-2
    80004aba:	4705                	li	a4,1
    80004abc:	04f76763          	bltu	a4,a5,80004b0a <filestat+0x6e>
    80004ac0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ac2:	6c88                	ld	a0,24(s1)
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	0a6080e7          	jalr	166(ra) # 80003b6a <ilock>
    stati(f->ip, &st);
    80004acc:	fb840593          	add	a1,s0,-72
    80004ad0:	6c88                	ld	a0,24(s1)
    80004ad2:	fffff097          	auipc	ra,0xfffff
    80004ad6:	322080e7          	jalr	802(ra) # 80003df4 <stati>
    iunlock(f->ip);
    80004ada:	6c88                	ld	a0,24(s1)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	150080e7          	jalr	336(ra) # 80003c2c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ae4:	46e1                	li	a3,24
    80004ae6:	fb840613          	add	a2,s0,-72
    80004aea:	85ce                	mv	a1,s3
    80004aec:	05093503          	ld	a0,80(s2)
    80004af0:	ffffd097          	auipc	ra,0xffffd
    80004af4:	c3e080e7          	jalr	-962(ra) # 8000172e <copyout>
    80004af8:	41f5551b          	sraw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004afc:	60a6                	ld	ra,72(sp)
    80004afe:	6406                	ld	s0,64(sp)
    80004b00:	74e2                	ld	s1,56(sp)
    80004b02:	7942                	ld	s2,48(sp)
    80004b04:	79a2                	ld	s3,40(sp)
    80004b06:	6161                	add	sp,sp,80
    80004b08:	8082                	ret
  return -1;
    80004b0a:	557d                	li	a0,-1
    80004b0c:	bfc5                	j	80004afc <filestat+0x60>

0000000080004b0e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b0e:	7179                	add	sp,sp,-48
    80004b10:	f406                	sd	ra,40(sp)
    80004b12:	f022                	sd	s0,32(sp)
    80004b14:	ec26                	sd	s1,24(sp)
    80004b16:	e84a                	sd	s2,16(sp)
    80004b18:	e44e                	sd	s3,8(sp)
    80004b1a:	1800                	add	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b1c:	00854783          	lbu	a5,8(a0)
    80004b20:	c3d5                	beqz	a5,80004bc4 <fileread+0xb6>
    80004b22:	84aa                	mv	s1,a0
    80004b24:	89ae                	mv	s3,a1
    80004b26:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b28:	411c                	lw	a5,0(a0)
    80004b2a:	4705                	li	a4,1
    80004b2c:	04e78963          	beq	a5,a4,80004b7e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b30:	470d                	li	a4,3
    80004b32:	04e78d63          	beq	a5,a4,80004b8c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b36:	4709                	li	a4,2
    80004b38:	06e79e63          	bne	a5,a4,80004bb4 <fileread+0xa6>
    ilock(f->ip);
    80004b3c:	6d08                	ld	a0,24(a0)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	02c080e7          	jalr	44(ra) # 80003b6a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b46:	874a                	mv	a4,s2
    80004b48:	5094                	lw	a3,32(s1)
    80004b4a:	864e                	mv	a2,s3
    80004b4c:	4585                	li	a1,1
    80004b4e:	6c88                	ld	a0,24(s1)
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	2ce080e7          	jalr	718(ra) # 80003e1e <readi>
    80004b58:	892a                	mv	s2,a0
    80004b5a:	00a05563          	blez	a0,80004b64 <fileread+0x56>
      f->off += r;
    80004b5e:	509c                	lw	a5,32(s1)
    80004b60:	9fa9                	addw	a5,a5,a0
    80004b62:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b64:	6c88                	ld	a0,24(s1)
    80004b66:	fffff097          	auipc	ra,0xfffff
    80004b6a:	0c6080e7          	jalr	198(ra) # 80003c2c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b6e:	854a                	mv	a0,s2
    80004b70:	70a2                	ld	ra,40(sp)
    80004b72:	7402                	ld	s0,32(sp)
    80004b74:	64e2                	ld	s1,24(sp)
    80004b76:	6942                	ld	s2,16(sp)
    80004b78:	69a2                	ld	s3,8(sp)
    80004b7a:	6145                	add	sp,sp,48
    80004b7c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b7e:	6908                	ld	a0,16(a0)
    80004b80:	00000097          	auipc	ra,0x0
    80004b84:	3c2080e7          	jalr	962(ra) # 80004f42 <piperead>
    80004b88:	892a                	mv	s2,a0
    80004b8a:	b7d5                	j	80004b6e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b8c:	02451783          	lh	a5,36(a0)
    80004b90:	03079693          	sll	a3,a5,0x30
    80004b94:	92c1                	srl	a3,a3,0x30
    80004b96:	4725                	li	a4,9
    80004b98:	02d76863          	bltu	a4,a3,80004bc8 <fileread+0xba>
    80004b9c:	0792                	sll	a5,a5,0x4
    80004b9e:	0023c717          	auipc	a4,0x23c
    80004ba2:	64270713          	add	a4,a4,1602 # 802411e0 <devsw>
    80004ba6:	97ba                	add	a5,a5,a4
    80004ba8:	639c                	ld	a5,0(a5)
    80004baa:	c38d                	beqz	a5,80004bcc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bac:	4505                	li	a0,1
    80004bae:	9782                	jalr	a5
    80004bb0:	892a                	mv	s2,a0
    80004bb2:	bf75                	j	80004b6e <fileread+0x60>
    panic("fileread");
    80004bb4:	00004517          	auipc	a0,0x4
    80004bb8:	b0c50513          	add	a0,a0,-1268 # 800086c0 <syscalls+0x270>
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	980080e7          	jalr	-1664(ra) # 8000053c <panic>
    return -1;
    80004bc4:	597d                	li	s2,-1
    80004bc6:	b765                	j	80004b6e <fileread+0x60>
      return -1;
    80004bc8:	597d                	li	s2,-1
    80004bca:	b755                	j	80004b6e <fileread+0x60>
    80004bcc:	597d                	li	s2,-1
    80004bce:	b745                	j	80004b6e <fileread+0x60>

0000000080004bd0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004bd0:	00954783          	lbu	a5,9(a0)
    80004bd4:	10078e63          	beqz	a5,80004cf0 <filewrite+0x120>
{
    80004bd8:	715d                	add	sp,sp,-80
    80004bda:	e486                	sd	ra,72(sp)
    80004bdc:	e0a2                	sd	s0,64(sp)
    80004bde:	fc26                	sd	s1,56(sp)
    80004be0:	f84a                	sd	s2,48(sp)
    80004be2:	f44e                	sd	s3,40(sp)
    80004be4:	f052                	sd	s4,32(sp)
    80004be6:	ec56                	sd	s5,24(sp)
    80004be8:	e85a                	sd	s6,16(sp)
    80004bea:	e45e                	sd	s7,8(sp)
    80004bec:	e062                	sd	s8,0(sp)
    80004bee:	0880                	add	s0,sp,80
    80004bf0:	892a                	mv	s2,a0
    80004bf2:	8b2e                	mv	s6,a1
    80004bf4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bf6:	411c                	lw	a5,0(a0)
    80004bf8:	4705                	li	a4,1
    80004bfa:	02e78263          	beq	a5,a4,80004c1e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bfe:	470d                	li	a4,3
    80004c00:	02e78563          	beq	a5,a4,80004c2a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c04:	4709                	li	a4,2
    80004c06:	0ce79d63          	bne	a5,a4,80004ce0 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c0a:	0ac05b63          	blez	a2,80004cc0 <filewrite+0xf0>
    int i = 0;
    80004c0e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004c10:	6b85                	lui	s7,0x1
    80004c12:	c00b8b93          	add	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004c16:	6c05                	lui	s8,0x1
    80004c18:	c00c0c1b          	addw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004c1c:	a851                	j	80004cb0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c1e:	6908                	ld	a0,16(a0)
    80004c20:	00000097          	auipc	ra,0x0
    80004c24:	22a080e7          	jalr	554(ra) # 80004e4a <pipewrite>
    80004c28:	a045                	j	80004cc8 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c2a:	02451783          	lh	a5,36(a0)
    80004c2e:	03079693          	sll	a3,a5,0x30
    80004c32:	92c1                	srl	a3,a3,0x30
    80004c34:	4725                	li	a4,9
    80004c36:	0ad76f63          	bltu	a4,a3,80004cf4 <filewrite+0x124>
    80004c3a:	0792                	sll	a5,a5,0x4
    80004c3c:	0023c717          	auipc	a4,0x23c
    80004c40:	5a470713          	add	a4,a4,1444 # 802411e0 <devsw>
    80004c44:	97ba                	add	a5,a5,a4
    80004c46:	679c                	ld	a5,8(a5)
    80004c48:	cbc5                	beqz	a5,80004cf8 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004c4a:	4505                	li	a0,1
    80004c4c:	9782                	jalr	a5
    80004c4e:	a8ad                	j	80004cc8 <filewrite+0xf8>
      if(n1 > max)
    80004c50:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004c54:	00000097          	auipc	ra,0x0
    80004c58:	8bc080e7          	jalr	-1860(ra) # 80004510 <begin_op>
      ilock(f->ip);
    80004c5c:	01893503          	ld	a0,24(s2)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	f0a080e7          	jalr	-246(ra) # 80003b6a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c68:	8756                	mv	a4,s5
    80004c6a:	02092683          	lw	a3,32(s2)
    80004c6e:	01698633          	add	a2,s3,s6
    80004c72:	4585                	li	a1,1
    80004c74:	01893503          	ld	a0,24(s2)
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	29e080e7          	jalr	670(ra) # 80003f16 <writei>
    80004c80:	84aa                	mv	s1,a0
    80004c82:	00a05763          	blez	a0,80004c90 <filewrite+0xc0>
        f->off += r;
    80004c86:	02092783          	lw	a5,32(s2)
    80004c8a:	9fa9                	addw	a5,a5,a0
    80004c8c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c90:	01893503          	ld	a0,24(s2)
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	f98080e7          	jalr	-104(ra) # 80003c2c <iunlock>
      end_op();
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	8ee080e7          	jalr	-1810(ra) # 8000458a <end_op>

      if(r != n1){
    80004ca4:	009a9f63          	bne	s5,s1,80004cc2 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004ca8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cac:	0149db63          	bge	s3,s4,80004cc2 <filewrite+0xf2>
      int n1 = n - i;
    80004cb0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004cb4:	0004879b          	sext.w	a5,s1
    80004cb8:	f8fbdce3          	bge	s7,a5,80004c50 <filewrite+0x80>
    80004cbc:	84e2                	mv	s1,s8
    80004cbe:	bf49                	j	80004c50 <filewrite+0x80>
    int i = 0;
    80004cc0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cc2:	033a1d63          	bne	s4,s3,80004cfc <filewrite+0x12c>
    80004cc6:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cc8:	60a6                	ld	ra,72(sp)
    80004cca:	6406                	ld	s0,64(sp)
    80004ccc:	74e2                	ld	s1,56(sp)
    80004cce:	7942                	ld	s2,48(sp)
    80004cd0:	79a2                	ld	s3,40(sp)
    80004cd2:	7a02                	ld	s4,32(sp)
    80004cd4:	6ae2                	ld	s5,24(sp)
    80004cd6:	6b42                	ld	s6,16(sp)
    80004cd8:	6ba2                	ld	s7,8(sp)
    80004cda:	6c02                	ld	s8,0(sp)
    80004cdc:	6161                	add	sp,sp,80
    80004cde:	8082                	ret
    panic("filewrite");
    80004ce0:	00004517          	auipc	a0,0x4
    80004ce4:	9f050513          	add	a0,a0,-1552 # 800086d0 <syscalls+0x280>
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	854080e7          	jalr	-1964(ra) # 8000053c <panic>
    return -1;
    80004cf0:	557d                	li	a0,-1
}
    80004cf2:	8082                	ret
      return -1;
    80004cf4:	557d                	li	a0,-1
    80004cf6:	bfc9                	j	80004cc8 <filewrite+0xf8>
    80004cf8:	557d                	li	a0,-1
    80004cfa:	b7f9                	j	80004cc8 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004cfc:	557d                	li	a0,-1
    80004cfe:	b7e9                	j	80004cc8 <filewrite+0xf8>

0000000080004d00 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d00:	7179                	add	sp,sp,-48
    80004d02:	f406                	sd	ra,40(sp)
    80004d04:	f022                	sd	s0,32(sp)
    80004d06:	ec26                	sd	s1,24(sp)
    80004d08:	e84a                	sd	s2,16(sp)
    80004d0a:	e44e                	sd	s3,8(sp)
    80004d0c:	e052                	sd	s4,0(sp)
    80004d0e:	1800                	add	s0,sp,48
    80004d10:	84aa                	mv	s1,a0
    80004d12:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d14:	0005b023          	sd	zero,0(a1)
    80004d18:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d1c:	00000097          	auipc	ra,0x0
    80004d20:	bfc080e7          	jalr	-1028(ra) # 80004918 <filealloc>
    80004d24:	e088                	sd	a0,0(s1)
    80004d26:	c551                	beqz	a0,80004db2 <pipealloc+0xb2>
    80004d28:	00000097          	auipc	ra,0x0
    80004d2c:	bf0080e7          	jalr	-1040(ra) # 80004918 <filealloc>
    80004d30:	00aa3023          	sd	a0,0(s4)
    80004d34:	c92d                	beqz	a0,80004da6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	df0080e7          	jalr	-528(ra) # 80000b26 <kalloc>
    80004d3e:	892a                	mv	s2,a0
    80004d40:	c125                	beqz	a0,80004da0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d42:	4985                	li	s3,1
    80004d44:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d48:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d4c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d50:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d54:	00004597          	auipc	a1,0x4
    80004d58:	98c58593          	add	a1,a1,-1652 # 800086e0 <syscalls+0x290>
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	e64080e7          	jalr	-412(ra) # 80000bc0 <initlock>
  (*f0)->type = FD_PIPE;
    80004d64:	609c                	ld	a5,0(s1)
    80004d66:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d6a:	609c                	ld	a5,0(s1)
    80004d6c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d70:	609c                	ld	a5,0(s1)
    80004d72:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d76:	609c                	ld	a5,0(s1)
    80004d78:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d7c:	000a3783          	ld	a5,0(s4)
    80004d80:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d84:	000a3783          	ld	a5,0(s4)
    80004d88:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d8c:	000a3783          	ld	a5,0(s4)
    80004d90:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d94:	000a3783          	ld	a5,0(s4)
    80004d98:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d9c:	4501                	li	a0,0
    80004d9e:	a025                	j	80004dc6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004da0:	6088                	ld	a0,0(s1)
    80004da2:	e501                	bnez	a0,80004daa <pipealloc+0xaa>
    80004da4:	a039                	j	80004db2 <pipealloc+0xb2>
    80004da6:	6088                	ld	a0,0(s1)
    80004da8:	c51d                	beqz	a0,80004dd6 <pipealloc+0xd6>
    fileclose(*f0);
    80004daa:	00000097          	auipc	ra,0x0
    80004dae:	c2a080e7          	jalr	-982(ra) # 800049d4 <fileclose>
  if(*f1)
    80004db2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004db6:	557d                	li	a0,-1
  if(*f1)
    80004db8:	c799                	beqz	a5,80004dc6 <pipealloc+0xc6>
    fileclose(*f1);
    80004dba:	853e                	mv	a0,a5
    80004dbc:	00000097          	auipc	ra,0x0
    80004dc0:	c18080e7          	jalr	-1000(ra) # 800049d4 <fileclose>
  return -1;
    80004dc4:	557d                	li	a0,-1
}
    80004dc6:	70a2                	ld	ra,40(sp)
    80004dc8:	7402                	ld	s0,32(sp)
    80004dca:	64e2                	ld	s1,24(sp)
    80004dcc:	6942                	ld	s2,16(sp)
    80004dce:	69a2                	ld	s3,8(sp)
    80004dd0:	6a02                	ld	s4,0(sp)
    80004dd2:	6145                	add	sp,sp,48
    80004dd4:	8082                	ret
  return -1;
    80004dd6:	557d                	li	a0,-1
    80004dd8:	b7fd                	j	80004dc6 <pipealloc+0xc6>

0000000080004dda <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004dda:	1101                	add	sp,sp,-32
    80004ddc:	ec06                	sd	ra,24(sp)
    80004dde:	e822                	sd	s0,16(sp)
    80004de0:	e426                	sd	s1,8(sp)
    80004de2:	e04a                	sd	s2,0(sp)
    80004de4:	1000                	add	s0,sp,32
    80004de6:	84aa                	mv	s1,a0
    80004de8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	e66080e7          	jalr	-410(ra) # 80000c50 <acquire>
  if(writable){
    80004df2:	02090d63          	beqz	s2,80004e2c <pipeclose+0x52>
    pi->writeopen = 0;
    80004df6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dfa:	21848513          	add	a0,s1,536
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	432080e7          	jalr	1074(ra) # 80002230 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e06:	2204b783          	ld	a5,544(s1)
    80004e0a:	eb95                	bnez	a5,80004e3e <pipeclose+0x64>
    release(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	ef6080e7          	jalr	-266(ra) # 80000d04 <release>
    kfree((char*)pi);
    80004e16:	8526                	mv	a0,s1
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	bcc080e7          	jalr	-1076(ra) # 800009e4 <kfree>
  } else
    release(&pi->lock);
}
    80004e20:	60e2                	ld	ra,24(sp)
    80004e22:	6442                	ld	s0,16(sp)
    80004e24:	64a2                	ld	s1,8(sp)
    80004e26:	6902                	ld	s2,0(sp)
    80004e28:	6105                	add	sp,sp,32
    80004e2a:	8082                	ret
    pi->readopen = 0;
    80004e2c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e30:	21c48513          	add	a0,s1,540
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	3fc080e7          	jalr	1020(ra) # 80002230 <wakeup>
    80004e3c:	b7e9                	j	80004e06 <pipeclose+0x2c>
    release(&pi->lock);
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	ec4080e7          	jalr	-316(ra) # 80000d04 <release>
}
    80004e48:	bfe1                	j	80004e20 <pipeclose+0x46>

0000000080004e4a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e4a:	711d                	add	sp,sp,-96
    80004e4c:	ec86                	sd	ra,88(sp)
    80004e4e:	e8a2                	sd	s0,80(sp)
    80004e50:	e4a6                	sd	s1,72(sp)
    80004e52:	e0ca                	sd	s2,64(sp)
    80004e54:	fc4e                	sd	s3,56(sp)
    80004e56:	f852                	sd	s4,48(sp)
    80004e58:	f456                	sd	s5,40(sp)
    80004e5a:	f05a                	sd	s6,32(sp)
    80004e5c:	ec5e                	sd	s7,24(sp)
    80004e5e:	e862                	sd	s8,16(sp)
    80004e60:	1080                	add	s0,sp,96
    80004e62:	84aa                	mv	s1,a0
    80004e64:	8aae                	mv	s5,a1
    80004e66:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	c98080e7          	jalr	-872(ra) # 80001b00 <myproc>
    80004e70:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e72:	8526                	mv	a0,s1
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	ddc080e7          	jalr	-548(ra) # 80000c50 <acquire>
  while(i < n){
    80004e7c:	0b405663          	blez	s4,80004f28 <pipewrite+0xde>
  int i = 0;
    80004e80:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e82:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e84:	21848c13          	add	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e88:	21c48b93          	add	s7,s1,540
    80004e8c:	a089                	j	80004ece <pipewrite+0x84>
      release(&pi->lock);
    80004e8e:	8526                	mv	a0,s1
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	e74080e7          	jalr	-396(ra) # 80000d04 <release>
      return -1;
    80004e98:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e9a:	854a                	mv	a0,s2
    80004e9c:	60e6                	ld	ra,88(sp)
    80004e9e:	6446                	ld	s0,80(sp)
    80004ea0:	64a6                	ld	s1,72(sp)
    80004ea2:	6906                	ld	s2,64(sp)
    80004ea4:	79e2                	ld	s3,56(sp)
    80004ea6:	7a42                	ld	s4,48(sp)
    80004ea8:	7aa2                	ld	s5,40(sp)
    80004eaa:	7b02                	ld	s6,32(sp)
    80004eac:	6be2                	ld	s7,24(sp)
    80004eae:	6c42                	ld	s8,16(sp)
    80004eb0:	6125                	add	sp,sp,96
    80004eb2:	8082                	ret
      wakeup(&pi->nread);
    80004eb4:	8562                	mv	a0,s8
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	37a080e7          	jalr	890(ra) # 80002230 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ebe:	85a6                	mv	a1,s1
    80004ec0:	855e                	mv	a0,s7
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	30a080e7          	jalr	778(ra) # 800021cc <sleep>
  while(i < n){
    80004eca:	07495063          	bge	s2,s4,80004f2a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ece:	2204a783          	lw	a5,544(s1)
    80004ed2:	dfd5                	beqz	a5,80004e8e <pipewrite+0x44>
    80004ed4:	854e                	mv	a0,s3
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	5aa080e7          	jalr	1450(ra) # 80002480 <killed>
    80004ede:	f945                	bnez	a0,80004e8e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee0:	2184a783          	lw	a5,536(s1)
    80004ee4:	21c4a703          	lw	a4,540(s1)
    80004ee8:	2007879b          	addw	a5,a5,512
    80004eec:	fcf704e3          	beq	a4,a5,80004eb4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef0:	4685                	li	a3,1
    80004ef2:	01590633          	add	a2,s2,s5
    80004ef6:	faf40593          	add	a1,s0,-81
    80004efa:	0509b503          	ld	a0,80(s3)
    80004efe:	ffffd097          	auipc	ra,0xffffd
    80004f02:	94e080e7          	jalr	-1714(ra) # 8000184c <copyin>
    80004f06:	03650263          	beq	a0,s6,80004f2a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f0a:	21c4a783          	lw	a5,540(s1)
    80004f0e:	0017871b          	addw	a4,a5,1
    80004f12:	20e4ae23          	sw	a4,540(s1)
    80004f16:	1ff7f793          	and	a5,a5,511
    80004f1a:	97a6                	add	a5,a5,s1
    80004f1c:	faf44703          	lbu	a4,-81(s0)
    80004f20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f24:	2905                	addw	s2,s2,1
    80004f26:	b755                	j	80004eca <pipewrite+0x80>
  int i = 0;
    80004f28:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f2a:	21848513          	add	a0,s1,536
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	302080e7          	jalr	770(ra) # 80002230 <wakeup>
  release(&pi->lock);
    80004f36:	8526                	mv	a0,s1
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	dcc080e7          	jalr	-564(ra) # 80000d04 <release>
  return i;
    80004f40:	bfa9                	j	80004e9a <pipewrite+0x50>

0000000080004f42 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f42:	715d                	add	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	f052                	sd	s4,32(sp)
    80004f50:	ec56                	sd	s5,24(sp)
    80004f52:	e85a                	sd	s6,16(sp)
    80004f54:	0880                	add	s0,sp,80
    80004f56:	84aa                	mv	s1,a0
    80004f58:	892e                	mv	s2,a1
    80004f5a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	ba4080e7          	jalr	-1116(ra) # 80001b00 <myproc>
    80004f64:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f66:	8526                	mv	a0,s1
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	ce8080e7          	jalr	-792(ra) # 80000c50 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f70:	2184a703          	lw	a4,536(s1)
    80004f74:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f78:	21848993          	add	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f7c:	02f71763          	bne	a4,a5,80004faa <piperead+0x68>
    80004f80:	2244a783          	lw	a5,548(s1)
    80004f84:	c39d                	beqz	a5,80004faa <piperead+0x68>
    if(killed(pr)){
    80004f86:	8552                	mv	a0,s4
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	4f8080e7          	jalr	1272(ra) # 80002480 <killed>
    80004f90:	e949                	bnez	a0,80005022 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f92:	85a6                	mv	a1,s1
    80004f94:	854e                	mv	a0,s3
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	236080e7          	jalr	566(ra) # 800021cc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f9e:	2184a703          	lw	a4,536(s1)
    80004fa2:	21c4a783          	lw	a5,540(s1)
    80004fa6:	fcf70de3          	beq	a4,a5,80004f80 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004faa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fae:	05505463          	blez	s5,80004ff6 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004fb2:	2184a783          	lw	a5,536(s1)
    80004fb6:	21c4a703          	lw	a4,540(s1)
    80004fba:	02f70e63          	beq	a4,a5,80004ff6 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fbe:	0017871b          	addw	a4,a5,1
    80004fc2:	20e4ac23          	sw	a4,536(s1)
    80004fc6:	1ff7f793          	and	a5,a5,511
    80004fca:	97a6                	add	a5,a5,s1
    80004fcc:	0187c783          	lbu	a5,24(a5)
    80004fd0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fd4:	4685                	li	a3,1
    80004fd6:	fbf40613          	add	a2,s0,-65
    80004fda:	85ca                	mv	a1,s2
    80004fdc:	050a3503          	ld	a0,80(s4)
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	74e080e7          	jalr	1870(ra) # 8000172e <copyout>
    80004fe8:	01650763          	beq	a0,s6,80004ff6 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fec:	2985                	addw	s3,s3,1
    80004fee:	0905                	add	s2,s2,1
    80004ff0:	fd3a91e3          	bne	s5,s3,80004fb2 <piperead+0x70>
    80004ff4:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ff6:	21c48513          	add	a0,s1,540
    80004ffa:	ffffd097          	auipc	ra,0xffffd
    80004ffe:	236080e7          	jalr	566(ra) # 80002230 <wakeup>
  release(&pi->lock);
    80005002:	8526                	mv	a0,s1
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	d00080e7          	jalr	-768(ra) # 80000d04 <release>
  return i;
}
    8000500c:	854e                	mv	a0,s3
    8000500e:	60a6                	ld	ra,72(sp)
    80005010:	6406                	ld	s0,64(sp)
    80005012:	74e2                	ld	s1,56(sp)
    80005014:	7942                	ld	s2,48(sp)
    80005016:	79a2                	ld	s3,40(sp)
    80005018:	7a02                	ld	s4,32(sp)
    8000501a:	6ae2                	ld	s5,24(sp)
    8000501c:	6b42                	ld	s6,16(sp)
    8000501e:	6161                	add	sp,sp,80
    80005020:	8082                	ret
      release(&pi->lock);
    80005022:	8526                	mv	a0,s1
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	ce0080e7          	jalr	-800(ra) # 80000d04 <release>
      return -1;
    8000502c:	59fd                	li	s3,-1
    8000502e:	bff9                	j	8000500c <piperead+0xca>

0000000080005030 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005030:	1141                	add	sp,sp,-16
    80005032:	e422                	sd	s0,8(sp)
    80005034:	0800                	add	s0,sp,16
    80005036:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005038:	8905                	and	a0,a0,1
    8000503a:	050e                	sll	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000503c:	8b89                	and	a5,a5,2
    8000503e:	c399                	beqz	a5,80005044 <flags2perm+0x14>
      perm |= PTE_W;
    80005040:	00456513          	or	a0,a0,4
    return perm;
}
    80005044:	6422                	ld	s0,8(sp)
    80005046:	0141                	add	sp,sp,16
    80005048:	8082                	ret

000000008000504a <exec>:

int
exec(char *path, char **argv)
{
    8000504a:	df010113          	add	sp,sp,-528
    8000504e:	20113423          	sd	ra,520(sp)
    80005052:	20813023          	sd	s0,512(sp)
    80005056:	ffa6                	sd	s1,504(sp)
    80005058:	fbca                	sd	s2,496(sp)
    8000505a:	f7ce                	sd	s3,488(sp)
    8000505c:	f3d2                	sd	s4,480(sp)
    8000505e:	efd6                	sd	s5,472(sp)
    80005060:	ebda                	sd	s6,464(sp)
    80005062:	e7de                	sd	s7,456(sp)
    80005064:	e3e2                	sd	s8,448(sp)
    80005066:	ff66                	sd	s9,440(sp)
    80005068:	fb6a                	sd	s10,432(sp)
    8000506a:	f76e                	sd	s11,424(sp)
    8000506c:	0c00                	add	s0,sp,528
    8000506e:	892a                	mv	s2,a0
    80005070:	dea43c23          	sd	a0,-520(s0)
    80005074:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	a88080e7          	jalr	-1400(ra) # 80001b00 <myproc>
    80005080:	84aa                	mv	s1,a0

  begin_op();
    80005082:	fffff097          	auipc	ra,0xfffff
    80005086:	48e080e7          	jalr	1166(ra) # 80004510 <begin_op>

  if((ip = namei(path)) == 0){
    8000508a:	854a                	mv	a0,s2
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	284080e7          	jalr	644(ra) # 80004310 <namei>
    80005094:	c92d                	beqz	a0,80005106 <exec+0xbc>
    80005096:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	ad2080e7          	jalr	-1326(ra) # 80003b6a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050a0:	04000713          	li	a4,64
    800050a4:	4681                	li	a3,0
    800050a6:	e5040613          	add	a2,s0,-432
    800050aa:	4581                	li	a1,0
    800050ac:	8552                	mv	a0,s4
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	d70080e7          	jalr	-656(ra) # 80003e1e <readi>
    800050b6:	04000793          	li	a5,64
    800050ba:	00f51a63          	bne	a0,a5,800050ce <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800050be:	e5042703          	lw	a4,-432(s0)
    800050c2:	464c47b7          	lui	a5,0x464c4
    800050c6:	57f78793          	add	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050ca:	04f70463          	beq	a4,a5,80005112 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050ce:	8552                	mv	a0,s4
    800050d0:	fffff097          	auipc	ra,0xfffff
    800050d4:	cfc080e7          	jalr	-772(ra) # 80003dcc <iunlockput>
    end_op();
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	4b2080e7          	jalr	1202(ra) # 8000458a <end_op>
  }
  return -1;
    800050e0:	557d                	li	a0,-1
}
    800050e2:	20813083          	ld	ra,520(sp)
    800050e6:	20013403          	ld	s0,512(sp)
    800050ea:	74fe                	ld	s1,504(sp)
    800050ec:	795e                	ld	s2,496(sp)
    800050ee:	79be                	ld	s3,488(sp)
    800050f0:	7a1e                	ld	s4,480(sp)
    800050f2:	6afe                	ld	s5,472(sp)
    800050f4:	6b5e                	ld	s6,464(sp)
    800050f6:	6bbe                	ld	s7,456(sp)
    800050f8:	6c1e                	ld	s8,448(sp)
    800050fa:	7cfa                	ld	s9,440(sp)
    800050fc:	7d5a                	ld	s10,432(sp)
    800050fe:	7dba                	ld	s11,424(sp)
    80005100:	21010113          	add	sp,sp,528
    80005104:	8082                	ret
    end_op();
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	484080e7          	jalr	1156(ra) # 8000458a <end_op>
    return -1;
    8000510e:	557d                	li	a0,-1
    80005110:	bfc9                	j	800050e2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005112:	8526                	mv	a0,s1
    80005114:	ffffd097          	auipc	ra,0xffffd
    80005118:	ab0080e7          	jalr	-1360(ra) # 80001bc4 <proc_pagetable>
    8000511c:	8b2a                	mv	s6,a0
    8000511e:	d945                	beqz	a0,800050ce <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005120:	e7042d03          	lw	s10,-400(s0)
    80005124:	e8845783          	lhu	a5,-376(s0)
    80005128:	10078463          	beqz	a5,80005230 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000512c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005130:	6c85                	lui	s9,0x1
    80005132:	fffc8793          	add	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005136:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000513a:	6a85                	lui	s5,0x1
    8000513c:	a0b5                	j	800051a8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000513e:	00003517          	auipc	a0,0x3
    80005142:	5aa50513          	add	a0,a0,1450 # 800086e8 <syscalls+0x298>
    80005146:	ffffb097          	auipc	ra,0xffffb
    8000514a:	3f6080e7          	jalr	1014(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000514e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005150:	8726                	mv	a4,s1
    80005152:	012c06bb          	addw	a3,s8,s2
    80005156:	4581                	li	a1,0
    80005158:	8552                	mv	a0,s4
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	cc4080e7          	jalr	-828(ra) # 80003e1e <readi>
    80005162:	2501                	sext.w	a0,a0
    80005164:	24a49863          	bne	s1,a0,800053b4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005168:	012a893b          	addw	s2,s5,s2
    8000516c:	03397563          	bgeu	s2,s3,80005196 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80005170:	02091593          	sll	a1,s2,0x20
    80005174:	9181                	srl	a1,a1,0x20
    80005176:	95de                	add	a1,a1,s7
    80005178:	855a                	mv	a0,s6
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	f5a080e7          	jalr	-166(ra) # 800010d4 <walkaddr>
    80005182:	862a                	mv	a2,a0
    if(pa == 0)
    80005184:	dd4d                	beqz	a0,8000513e <exec+0xf4>
    if(sz - i < PGSIZE)
    80005186:	412984bb          	subw	s1,s3,s2
    8000518a:	0004879b          	sext.w	a5,s1
    8000518e:	fcfcf0e3          	bgeu	s9,a5,8000514e <exec+0x104>
    80005192:	84d6                	mv	s1,s5
    80005194:	bf6d                	j	8000514e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005196:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000519a:	2d85                	addw	s11,s11,1
    8000519c:	038d0d1b          	addw	s10,s10,56
    800051a0:	e8845783          	lhu	a5,-376(s0)
    800051a4:	08fdd763          	bge	s11,a5,80005232 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051a8:	2d01                	sext.w	s10,s10
    800051aa:	03800713          	li	a4,56
    800051ae:	86ea                	mv	a3,s10
    800051b0:	e1840613          	add	a2,s0,-488
    800051b4:	4581                	li	a1,0
    800051b6:	8552                	mv	a0,s4
    800051b8:	fffff097          	auipc	ra,0xfffff
    800051bc:	c66080e7          	jalr	-922(ra) # 80003e1e <readi>
    800051c0:	03800793          	li	a5,56
    800051c4:	1ef51663          	bne	a0,a5,800053b0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800051c8:	e1842783          	lw	a5,-488(s0)
    800051cc:	4705                	li	a4,1
    800051ce:	fce796e3          	bne	a5,a4,8000519a <exec+0x150>
    if(ph.memsz < ph.filesz)
    800051d2:	e4043483          	ld	s1,-448(s0)
    800051d6:	e3843783          	ld	a5,-456(s0)
    800051da:	1ef4e863          	bltu	s1,a5,800053ca <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051de:	e2843783          	ld	a5,-472(s0)
    800051e2:	94be                	add	s1,s1,a5
    800051e4:	1ef4e663          	bltu	s1,a5,800053d0 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    800051e8:	df043703          	ld	a4,-528(s0)
    800051ec:	8ff9                	and	a5,a5,a4
    800051ee:	1e079463          	bnez	a5,800053d6 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051f2:	e1c42503          	lw	a0,-484(s0)
    800051f6:	00000097          	auipc	ra,0x0
    800051fa:	e3a080e7          	jalr	-454(ra) # 80005030 <flags2perm>
    800051fe:	86aa                	mv	a3,a0
    80005200:	8626                	mv	a2,s1
    80005202:	85ca                	mv	a1,s2
    80005204:	855a                	mv	a0,s6
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	282080e7          	jalr	642(ra) # 80001488 <uvmalloc>
    8000520e:	e0a43423          	sd	a0,-504(s0)
    80005212:	1c050563          	beqz	a0,800053dc <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005216:	e2843b83          	ld	s7,-472(s0)
    8000521a:	e2042c03          	lw	s8,-480(s0)
    8000521e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005222:	00098463          	beqz	s3,8000522a <exec+0x1e0>
    80005226:	4901                	li	s2,0
    80005228:	b7a1                	j	80005170 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000522a:	e0843903          	ld	s2,-504(s0)
    8000522e:	b7b5                	j	8000519a <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005230:	4901                	li	s2,0
  iunlockput(ip);
    80005232:	8552                	mv	a0,s4
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	b98080e7          	jalr	-1128(ra) # 80003dcc <iunlockput>
  end_op();
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	34e080e7          	jalr	846(ra) # 8000458a <end_op>
  p = myproc();
    80005244:	ffffd097          	auipc	ra,0xffffd
    80005248:	8bc080e7          	jalr	-1860(ra) # 80001b00 <myproc>
    8000524c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000524e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005252:	6985                	lui	s3,0x1
    80005254:	19fd                	add	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005256:	99ca                	add	s3,s3,s2
    80005258:	77fd                	lui	a5,0xfffff
    8000525a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000525e:	4691                	li	a3,4
    80005260:	6609                	lui	a2,0x2
    80005262:	964e                	add	a2,a2,s3
    80005264:	85ce                	mv	a1,s3
    80005266:	855a                	mv	a0,s6
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	220080e7          	jalr	544(ra) # 80001488 <uvmalloc>
    80005270:	892a                	mv	s2,a0
    80005272:	e0a43423          	sd	a0,-504(s0)
    80005276:	e509                	bnez	a0,80005280 <exec+0x236>
  if(pagetable)
    80005278:	e1343423          	sd	s3,-504(s0)
    8000527c:	4a01                	li	s4,0
    8000527e:	aa1d                	j	800053b4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005280:	75f9                	lui	a1,0xffffe
    80005282:	95aa                	add	a1,a1,a0
    80005284:	855a                	mv	a0,s6
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	452080e7          	jalr	1106(ra) # 800016d8 <uvmclear>
  stackbase = sp - PGSIZE;
    8000528e:	7bfd                	lui	s7,0xfffff
    80005290:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005292:	e0043783          	ld	a5,-512(s0)
    80005296:	6388                	ld	a0,0(a5)
    80005298:	c52d                	beqz	a0,80005302 <exec+0x2b8>
    8000529a:	e9040993          	add	s3,s0,-368
    8000529e:	f9040c13          	add	s8,s0,-112
    800052a2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	c22080e7          	jalr	-990(ra) # 80000ec6 <strlen>
    800052ac:	0015079b          	addw	a5,a0,1
    800052b0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052b4:	ff07f913          	and	s2,a5,-16
    if(sp < stackbase)
    800052b8:	13796563          	bltu	s2,s7,800053e2 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052bc:	e0043d03          	ld	s10,-512(s0)
    800052c0:	000d3a03          	ld	s4,0(s10)
    800052c4:	8552                	mv	a0,s4
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	c00080e7          	jalr	-1024(ra) # 80000ec6 <strlen>
    800052ce:	0015069b          	addw	a3,a0,1
    800052d2:	8652                	mv	a2,s4
    800052d4:	85ca                	mv	a1,s2
    800052d6:	855a                	mv	a0,s6
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	456080e7          	jalr	1110(ra) # 8000172e <copyout>
    800052e0:	10054363          	bltz	a0,800053e6 <exec+0x39c>
    ustack[argc] = sp;
    800052e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052e8:	0485                	add	s1,s1,1
    800052ea:	008d0793          	add	a5,s10,8
    800052ee:	e0f43023          	sd	a5,-512(s0)
    800052f2:	008d3503          	ld	a0,8(s10)
    800052f6:	c909                	beqz	a0,80005308 <exec+0x2be>
    if(argc >= MAXARG)
    800052f8:	09a1                	add	s3,s3,8
    800052fa:	fb8995e3          	bne	s3,s8,800052a4 <exec+0x25a>
  ip = 0;
    800052fe:	4a01                	li	s4,0
    80005300:	a855                	j	800053b4 <exec+0x36a>
  sp = sz;
    80005302:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005306:	4481                	li	s1,0
  ustack[argc] = 0;
    80005308:	00349793          	sll	a5,s1,0x3
    8000530c:	f9078793          	add	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbcc18>
    80005310:	97a2                	add	a5,a5,s0
    80005312:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005316:	00148693          	add	a3,s1,1
    8000531a:	068e                	sll	a3,a3,0x3
    8000531c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005320:	ff097913          	and	s2,s2,-16
  sz = sz1;
    80005324:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005328:	f57968e3          	bltu	s2,s7,80005278 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000532c:	e9040613          	add	a2,s0,-368
    80005330:	85ca                	mv	a1,s2
    80005332:	855a                	mv	a0,s6
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	3fa080e7          	jalr	1018(ra) # 8000172e <copyout>
    8000533c:	0a054763          	bltz	a0,800053ea <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005340:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005344:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005348:	df843783          	ld	a5,-520(s0)
    8000534c:	0007c703          	lbu	a4,0(a5)
    80005350:	cf11                	beqz	a4,8000536c <exec+0x322>
    80005352:	0785                	add	a5,a5,1
    if(*s == '/')
    80005354:	02f00693          	li	a3,47
    80005358:	a039                	j	80005366 <exec+0x31c>
      last = s+1;
    8000535a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000535e:	0785                	add	a5,a5,1
    80005360:	fff7c703          	lbu	a4,-1(a5)
    80005364:	c701                	beqz	a4,8000536c <exec+0x322>
    if(*s == '/')
    80005366:	fed71ce3          	bne	a4,a3,8000535e <exec+0x314>
    8000536a:	bfc5                	j	8000535a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000536c:	4641                	li	a2,16
    8000536e:	df843583          	ld	a1,-520(s0)
    80005372:	158a8513          	add	a0,s5,344
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	b1e080e7          	jalr	-1250(ra) # 80000e94 <safestrcpy>
  oldpagetable = p->pagetable;
    8000537e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005382:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005386:	e0843783          	ld	a5,-504(s0)
    8000538a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000538e:	058ab783          	ld	a5,88(s5)
    80005392:	e6843703          	ld	a4,-408(s0)
    80005396:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005398:	058ab783          	ld	a5,88(s5)
    8000539c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053a0:	85e6                	mv	a1,s9
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	8be080e7          	jalr	-1858(ra) # 80001c60 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053aa:	0004851b          	sext.w	a0,s1
    800053ae:	bb15                	j	800050e2 <exec+0x98>
    800053b0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053b4:	e0843583          	ld	a1,-504(s0)
    800053b8:	855a                	mv	a0,s6
    800053ba:	ffffd097          	auipc	ra,0xffffd
    800053be:	8a6080e7          	jalr	-1882(ra) # 80001c60 <proc_freepagetable>
  return -1;
    800053c2:	557d                	li	a0,-1
  if(ip){
    800053c4:	d00a0fe3          	beqz	s4,800050e2 <exec+0x98>
    800053c8:	b319                	j	800050ce <exec+0x84>
    800053ca:	e1243423          	sd	s2,-504(s0)
    800053ce:	b7dd                	j	800053b4 <exec+0x36a>
    800053d0:	e1243423          	sd	s2,-504(s0)
    800053d4:	b7c5                	j	800053b4 <exec+0x36a>
    800053d6:	e1243423          	sd	s2,-504(s0)
    800053da:	bfe9                	j	800053b4 <exec+0x36a>
    800053dc:	e1243423          	sd	s2,-504(s0)
    800053e0:	bfd1                	j	800053b4 <exec+0x36a>
  ip = 0;
    800053e2:	4a01                	li	s4,0
    800053e4:	bfc1                	j	800053b4 <exec+0x36a>
    800053e6:	4a01                	li	s4,0
  if(pagetable)
    800053e8:	b7f1                	j	800053b4 <exec+0x36a>
  sz = sz1;
    800053ea:	e0843983          	ld	s3,-504(s0)
    800053ee:	b569                	j	80005278 <exec+0x22e>

00000000800053f0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053f0:	7179                	add	sp,sp,-48
    800053f2:	f406                	sd	ra,40(sp)
    800053f4:	f022                	sd	s0,32(sp)
    800053f6:	ec26                	sd	s1,24(sp)
    800053f8:	e84a                	sd	s2,16(sp)
    800053fa:	1800                	add	s0,sp,48
    800053fc:	892e                	mv	s2,a1
    800053fe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005400:	fdc40593          	add	a1,s0,-36
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	ad8080e7          	jalr	-1320(ra) # 80002edc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000540c:	fdc42703          	lw	a4,-36(s0)
    80005410:	47bd                	li	a5,15
    80005412:	02e7eb63          	bltu	a5,a4,80005448 <argfd+0x58>
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	6ea080e7          	jalr	1770(ra) # 80001b00 <myproc>
    8000541e:	fdc42703          	lw	a4,-36(s0)
    80005422:	01a70793          	add	a5,a4,26
    80005426:	078e                	sll	a5,a5,0x3
    80005428:	953e                	add	a0,a0,a5
    8000542a:	611c                	ld	a5,0(a0)
    8000542c:	c385                	beqz	a5,8000544c <argfd+0x5c>
    return -1;
  if(pfd)
    8000542e:	00090463          	beqz	s2,80005436 <argfd+0x46>
    *pfd = fd;
    80005432:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005436:	4501                	li	a0,0
  if(pf)
    80005438:	c091                	beqz	s1,8000543c <argfd+0x4c>
    *pf = f;
    8000543a:	e09c                	sd	a5,0(s1)
}
    8000543c:	70a2                	ld	ra,40(sp)
    8000543e:	7402                	ld	s0,32(sp)
    80005440:	64e2                	ld	s1,24(sp)
    80005442:	6942                	ld	s2,16(sp)
    80005444:	6145                	add	sp,sp,48
    80005446:	8082                	ret
    return -1;
    80005448:	557d                	li	a0,-1
    8000544a:	bfcd                	j	8000543c <argfd+0x4c>
    8000544c:	557d                	li	a0,-1
    8000544e:	b7fd                	j	8000543c <argfd+0x4c>

0000000080005450 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005450:	1101                	add	sp,sp,-32
    80005452:	ec06                	sd	ra,24(sp)
    80005454:	e822                	sd	s0,16(sp)
    80005456:	e426                	sd	s1,8(sp)
    80005458:	1000                	add	s0,sp,32
    8000545a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	6a4080e7          	jalr	1700(ra) # 80001b00 <myproc>
    80005464:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005466:	0d050793          	add	a5,a0,208
    8000546a:	4501                	li	a0,0
    8000546c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000546e:	6398                	ld	a4,0(a5)
    80005470:	cb19                	beqz	a4,80005486 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005472:	2505                	addw	a0,a0,1
    80005474:	07a1                	add	a5,a5,8
    80005476:	fed51ce3          	bne	a0,a3,8000546e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000547a:	557d                	li	a0,-1
}
    8000547c:	60e2                	ld	ra,24(sp)
    8000547e:	6442                	ld	s0,16(sp)
    80005480:	64a2                	ld	s1,8(sp)
    80005482:	6105                	add	sp,sp,32
    80005484:	8082                	ret
      p->ofile[fd] = f;
    80005486:	01a50793          	add	a5,a0,26
    8000548a:	078e                	sll	a5,a5,0x3
    8000548c:	963e                	add	a2,a2,a5
    8000548e:	e204                	sd	s1,0(a2)
      return fd;
    80005490:	b7f5                	j	8000547c <fdalloc+0x2c>

0000000080005492 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005492:	715d                	add	sp,sp,-80
    80005494:	e486                	sd	ra,72(sp)
    80005496:	e0a2                	sd	s0,64(sp)
    80005498:	fc26                	sd	s1,56(sp)
    8000549a:	f84a                	sd	s2,48(sp)
    8000549c:	f44e                	sd	s3,40(sp)
    8000549e:	f052                	sd	s4,32(sp)
    800054a0:	ec56                	sd	s5,24(sp)
    800054a2:	e85a                	sd	s6,16(sp)
    800054a4:	0880                	add	s0,sp,80
    800054a6:	8b2e                	mv	s6,a1
    800054a8:	89b2                	mv	s3,a2
    800054aa:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ac:	fb040593          	add	a1,s0,-80
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	e7e080e7          	jalr	-386(ra) # 8000432e <nameiparent>
    800054b8:	84aa                	mv	s1,a0
    800054ba:	14050b63          	beqz	a0,80005610 <create+0x17e>
    return 0;

  ilock(dp);
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	6ac080e7          	jalr	1708(ra) # 80003b6a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054c6:	4601                	li	a2,0
    800054c8:	fb040593          	add	a1,s0,-80
    800054cc:	8526                	mv	a0,s1
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	b80080e7          	jalr	-1152(ra) # 8000404e <dirlookup>
    800054d6:	8aaa                	mv	s5,a0
    800054d8:	c921                	beqz	a0,80005528 <create+0x96>
    iunlockput(dp);
    800054da:	8526                	mv	a0,s1
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	8f0080e7          	jalr	-1808(ra) # 80003dcc <iunlockput>
    ilock(ip);
    800054e4:	8556                	mv	a0,s5
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	684080e7          	jalr	1668(ra) # 80003b6a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054ee:	4789                	li	a5,2
    800054f0:	02fb1563          	bne	s6,a5,8000551a <create+0x88>
    800054f4:	044ad783          	lhu	a5,68(s5)
    800054f8:	37f9                	addw	a5,a5,-2
    800054fa:	17c2                	sll	a5,a5,0x30
    800054fc:	93c1                	srl	a5,a5,0x30
    800054fe:	4705                	li	a4,1
    80005500:	00f76d63          	bltu	a4,a5,8000551a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005504:	8556                	mv	a0,s5
    80005506:	60a6                	ld	ra,72(sp)
    80005508:	6406                	ld	s0,64(sp)
    8000550a:	74e2                	ld	s1,56(sp)
    8000550c:	7942                	ld	s2,48(sp)
    8000550e:	79a2                	ld	s3,40(sp)
    80005510:	7a02                	ld	s4,32(sp)
    80005512:	6ae2                	ld	s5,24(sp)
    80005514:	6b42                	ld	s6,16(sp)
    80005516:	6161                	add	sp,sp,80
    80005518:	8082                	ret
    iunlockput(ip);
    8000551a:	8556                	mv	a0,s5
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	8b0080e7          	jalr	-1872(ra) # 80003dcc <iunlockput>
    return 0;
    80005524:	4a81                	li	s5,0
    80005526:	bff9                	j	80005504 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005528:	85da                	mv	a1,s6
    8000552a:	4088                	lw	a0,0(s1)
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	4a6080e7          	jalr	1190(ra) # 800039d2 <ialloc>
    80005534:	8a2a                	mv	s4,a0
    80005536:	c529                	beqz	a0,80005580 <create+0xee>
  ilock(ip);
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	632080e7          	jalr	1586(ra) # 80003b6a <ilock>
  ip->major = major;
    80005540:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005544:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005548:	4905                	li	s2,1
    8000554a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000554e:	8552                	mv	a0,s4
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	54e080e7          	jalr	1358(ra) # 80003a9e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005558:	032b0b63          	beq	s6,s2,8000558e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000555c:	004a2603          	lw	a2,4(s4)
    80005560:	fb040593          	add	a1,s0,-80
    80005564:	8526                	mv	a0,s1
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	cf8080e7          	jalr	-776(ra) # 8000425e <dirlink>
    8000556e:	06054f63          	bltz	a0,800055ec <create+0x15a>
  iunlockput(dp);
    80005572:	8526                	mv	a0,s1
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	858080e7          	jalr	-1960(ra) # 80003dcc <iunlockput>
  return ip;
    8000557c:	8ad2                	mv	s5,s4
    8000557e:	b759                	j	80005504 <create+0x72>
    iunlockput(dp);
    80005580:	8526                	mv	a0,s1
    80005582:	fffff097          	auipc	ra,0xfffff
    80005586:	84a080e7          	jalr	-1974(ra) # 80003dcc <iunlockput>
    return 0;
    8000558a:	8ad2                	mv	s5,s4
    8000558c:	bfa5                	j	80005504 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000558e:	004a2603          	lw	a2,4(s4)
    80005592:	00003597          	auipc	a1,0x3
    80005596:	17658593          	add	a1,a1,374 # 80008708 <syscalls+0x2b8>
    8000559a:	8552                	mv	a0,s4
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	cc2080e7          	jalr	-830(ra) # 8000425e <dirlink>
    800055a4:	04054463          	bltz	a0,800055ec <create+0x15a>
    800055a8:	40d0                	lw	a2,4(s1)
    800055aa:	00003597          	auipc	a1,0x3
    800055ae:	16658593          	add	a1,a1,358 # 80008710 <syscalls+0x2c0>
    800055b2:	8552                	mv	a0,s4
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	caa080e7          	jalr	-854(ra) # 8000425e <dirlink>
    800055bc:	02054863          	bltz	a0,800055ec <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800055c0:	004a2603          	lw	a2,4(s4)
    800055c4:	fb040593          	add	a1,s0,-80
    800055c8:	8526                	mv	a0,s1
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	c94080e7          	jalr	-876(ra) # 8000425e <dirlink>
    800055d2:	00054d63          	bltz	a0,800055ec <create+0x15a>
    dp->nlink++;  // for ".."
    800055d6:	04a4d783          	lhu	a5,74(s1)
    800055da:	2785                	addw	a5,a5,1
    800055dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	4bc080e7          	jalr	1212(ra) # 80003a9e <iupdate>
    800055ea:	b761                	j	80005572 <create+0xe0>
  ip->nlink = 0;
    800055ec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055f0:	8552                	mv	a0,s4
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	4ac080e7          	jalr	1196(ra) # 80003a9e <iupdate>
  iunlockput(ip);
    800055fa:	8552                	mv	a0,s4
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	7d0080e7          	jalr	2000(ra) # 80003dcc <iunlockput>
  iunlockput(dp);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	7c6080e7          	jalr	1990(ra) # 80003dcc <iunlockput>
  return 0;
    8000560e:	bddd                	j	80005504 <create+0x72>
    return 0;
    80005610:	8aaa                	mv	s5,a0
    80005612:	bdcd                	j	80005504 <create+0x72>

0000000080005614 <sys_dup>:
{
    80005614:	7179                	add	sp,sp,-48
    80005616:	f406                	sd	ra,40(sp)
    80005618:	f022                	sd	s0,32(sp)
    8000561a:	ec26                	sd	s1,24(sp)
    8000561c:	e84a                	sd	s2,16(sp)
    8000561e:	1800                	add	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005620:	fd840613          	add	a2,s0,-40
    80005624:	4581                	li	a1,0
    80005626:	4501                	li	a0,0
    80005628:	00000097          	auipc	ra,0x0
    8000562c:	dc8080e7          	jalr	-568(ra) # 800053f0 <argfd>
    return -1;
    80005630:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005632:	02054363          	bltz	a0,80005658 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005636:	fd843903          	ld	s2,-40(s0)
    8000563a:	854a                	mv	a0,s2
    8000563c:	00000097          	auipc	ra,0x0
    80005640:	e14080e7          	jalr	-492(ra) # 80005450 <fdalloc>
    80005644:	84aa                	mv	s1,a0
    return -1;
    80005646:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005648:	00054863          	bltz	a0,80005658 <sys_dup+0x44>
  filedup(f);
    8000564c:	854a                	mv	a0,s2
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	334080e7          	jalr	820(ra) # 80004982 <filedup>
  return fd;
    80005656:	87a6                	mv	a5,s1
}
    80005658:	853e                	mv	a0,a5
    8000565a:	70a2                	ld	ra,40(sp)
    8000565c:	7402                	ld	s0,32(sp)
    8000565e:	64e2                	ld	s1,24(sp)
    80005660:	6942                	ld	s2,16(sp)
    80005662:	6145                	add	sp,sp,48
    80005664:	8082                	ret

0000000080005666 <sys_getreadcount>:
{
    80005666:	1141                	add	sp,sp,-16
    80005668:	e422                	sd	s0,8(sp)
    8000566a:	0800                	add	s0,sp,16
}
    8000566c:	00003517          	auipc	a0,0x3
    80005670:	27852503          	lw	a0,632(a0) # 800088e4 <readCount>
    80005674:	6422                	ld	s0,8(sp)
    80005676:	0141                	add	sp,sp,16
    80005678:	8082                	ret

000000008000567a <sys_read>:
{
    8000567a:	7179                	add	sp,sp,-48
    8000567c:	f406                	sd	ra,40(sp)
    8000567e:	f022                	sd	s0,32(sp)
    80005680:	1800                	add	s0,sp,48
  readCount++;
    80005682:	00003717          	auipc	a4,0x3
    80005686:	26270713          	add	a4,a4,610 # 800088e4 <readCount>
    8000568a:	431c                	lw	a5,0(a4)
    8000568c:	2785                	addw	a5,a5,1
    8000568e:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005690:	fd840593          	add	a1,s0,-40
    80005694:	4505                	li	a0,1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	866080e7          	jalr	-1946(ra) # 80002efc <argaddr>
  argint(2, &n);
    8000569e:	fe440593          	add	a1,s0,-28
    800056a2:	4509                	li	a0,2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	838080e7          	jalr	-1992(ra) # 80002edc <argint>
  if(argfd(0, 0, &f) < 0)
    800056ac:	fe840613          	add	a2,s0,-24
    800056b0:	4581                	li	a1,0
    800056b2:	4501                	li	a0,0
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	d3c080e7          	jalr	-708(ra) # 800053f0 <argfd>
    800056bc:	87aa                	mv	a5,a0
    return -1;
    800056be:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056c0:	0007cc63          	bltz	a5,800056d8 <sys_read+0x5e>
  return fileread(f, p, n);
    800056c4:	fe442603          	lw	a2,-28(s0)
    800056c8:	fd843583          	ld	a1,-40(s0)
    800056cc:	fe843503          	ld	a0,-24(s0)
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	43e080e7          	jalr	1086(ra) # 80004b0e <fileread>
}
    800056d8:	70a2                	ld	ra,40(sp)
    800056da:	7402                	ld	s0,32(sp)
    800056dc:	6145                	add	sp,sp,48
    800056de:	8082                	ret

00000000800056e0 <sys_write>:
{
    800056e0:	7179                	add	sp,sp,-48
    800056e2:	f406                	sd	ra,40(sp)
    800056e4:	f022                	sd	s0,32(sp)
    800056e6:	1800                	add	s0,sp,48
  argaddr(1, &p);
    800056e8:	fd840593          	add	a1,s0,-40
    800056ec:	4505                	li	a0,1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	80e080e7          	jalr	-2034(ra) # 80002efc <argaddr>
  argint(2, &n);
    800056f6:	fe440593          	add	a1,s0,-28
    800056fa:	4509                	li	a0,2
    800056fc:	ffffd097          	auipc	ra,0xffffd
    80005700:	7e0080e7          	jalr	2016(ra) # 80002edc <argint>
  if(argfd(0, 0, &f) < 0)
    80005704:	fe840613          	add	a2,s0,-24
    80005708:	4581                	li	a1,0
    8000570a:	4501                	li	a0,0
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	ce4080e7          	jalr	-796(ra) # 800053f0 <argfd>
    80005714:	87aa                	mv	a5,a0
    return -1;
    80005716:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005718:	0007cc63          	bltz	a5,80005730 <sys_write+0x50>
  return filewrite(f, p, n);
    8000571c:	fe442603          	lw	a2,-28(s0)
    80005720:	fd843583          	ld	a1,-40(s0)
    80005724:	fe843503          	ld	a0,-24(s0)
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	4a8080e7          	jalr	1192(ra) # 80004bd0 <filewrite>
}
    80005730:	70a2                	ld	ra,40(sp)
    80005732:	7402                	ld	s0,32(sp)
    80005734:	6145                	add	sp,sp,48
    80005736:	8082                	ret

0000000080005738 <sys_close>:
{
    80005738:	1101                	add	sp,sp,-32
    8000573a:	ec06                	sd	ra,24(sp)
    8000573c:	e822                	sd	s0,16(sp)
    8000573e:	1000                	add	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005740:	fe040613          	add	a2,s0,-32
    80005744:	fec40593          	add	a1,s0,-20
    80005748:	4501                	li	a0,0
    8000574a:	00000097          	auipc	ra,0x0
    8000574e:	ca6080e7          	jalr	-858(ra) # 800053f0 <argfd>
    return -1;
    80005752:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005754:	02054463          	bltz	a0,8000577c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005758:	ffffc097          	auipc	ra,0xffffc
    8000575c:	3a8080e7          	jalr	936(ra) # 80001b00 <myproc>
    80005760:	fec42783          	lw	a5,-20(s0)
    80005764:	07e9                	add	a5,a5,26
    80005766:	078e                	sll	a5,a5,0x3
    80005768:	953e                	add	a0,a0,a5
    8000576a:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000576e:	fe043503          	ld	a0,-32(s0)
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	262080e7          	jalr	610(ra) # 800049d4 <fileclose>
  return 0;
    8000577a:	4781                	li	a5,0
}
    8000577c:	853e                	mv	a0,a5
    8000577e:	60e2                	ld	ra,24(sp)
    80005780:	6442                	ld	s0,16(sp)
    80005782:	6105                	add	sp,sp,32
    80005784:	8082                	ret

0000000080005786 <sys_fstat>:
{
    80005786:	1101                	add	sp,sp,-32
    80005788:	ec06                	sd	ra,24(sp)
    8000578a:	e822                	sd	s0,16(sp)
    8000578c:	1000                	add	s0,sp,32
  argaddr(1, &st);
    8000578e:	fe040593          	add	a1,s0,-32
    80005792:	4505                	li	a0,1
    80005794:	ffffd097          	auipc	ra,0xffffd
    80005798:	768080e7          	jalr	1896(ra) # 80002efc <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000579c:	fe840613          	add	a2,s0,-24
    800057a0:	4581                	li	a1,0
    800057a2:	4501                	li	a0,0
    800057a4:	00000097          	auipc	ra,0x0
    800057a8:	c4c080e7          	jalr	-948(ra) # 800053f0 <argfd>
    800057ac:	87aa                	mv	a5,a0
    return -1;
    800057ae:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057b0:	0007ca63          	bltz	a5,800057c4 <sys_fstat+0x3e>
  return filestat(f, st);
    800057b4:	fe043583          	ld	a1,-32(s0)
    800057b8:	fe843503          	ld	a0,-24(s0)
    800057bc:	fffff097          	auipc	ra,0xfffff
    800057c0:	2e0080e7          	jalr	736(ra) # 80004a9c <filestat>
}
    800057c4:	60e2                	ld	ra,24(sp)
    800057c6:	6442                	ld	s0,16(sp)
    800057c8:	6105                	add	sp,sp,32
    800057ca:	8082                	ret

00000000800057cc <sys_link>:
{
    800057cc:	7169                	add	sp,sp,-304
    800057ce:	f606                	sd	ra,296(sp)
    800057d0:	f222                	sd	s0,288(sp)
    800057d2:	ee26                	sd	s1,280(sp)
    800057d4:	ea4a                	sd	s2,272(sp)
    800057d6:	1a00                	add	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	08000613          	li	a2,128
    800057dc:	ed040593          	add	a1,s0,-304
    800057e0:	4501                	li	a0,0
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	73a080e7          	jalr	1850(ra) # 80002f1c <argstr>
    return -1;
    800057ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ec:	10054e63          	bltz	a0,80005908 <sys_link+0x13c>
    800057f0:	08000613          	li	a2,128
    800057f4:	f5040593          	add	a1,s0,-176
    800057f8:	4505                	li	a0,1
    800057fa:	ffffd097          	auipc	ra,0xffffd
    800057fe:	722080e7          	jalr	1826(ra) # 80002f1c <argstr>
    return -1;
    80005802:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005804:	10054263          	bltz	a0,80005908 <sys_link+0x13c>
  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	d08080e7          	jalr	-760(ra) # 80004510 <begin_op>
  if((ip = namei(old)) == 0){
    80005810:	ed040513          	add	a0,s0,-304
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	afc080e7          	jalr	-1284(ra) # 80004310 <namei>
    8000581c:	84aa                	mv	s1,a0
    8000581e:	c551                	beqz	a0,800058aa <sys_link+0xde>
  ilock(ip);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	34a080e7          	jalr	842(ra) # 80003b6a <ilock>
  if(ip->type == T_DIR){
    80005828:	04449703          	lh	a4,68(s1)
    8000582c:	4785                	li	a5,1
    8000582e:	08f70463          	beq	a4,a5,800058b6 <sys_link+0xea>
  ip->nlink++;
    80005832:	04a4d783          	lhu	a5,74(s1)
    80005836:	2785                	addw	a5,a5,1
    80005838:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	260080e7          	jalr	608(ra) # 80003a9e <iupdate>
  iunlock(ip);
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	3e4080e7          	jalr	996(ra) # 80003c2c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005850:	fd040593          	add	a1,s0,-48
    80005854:	f5040513          	add	a0,s0,-176
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	ad6080e7          	jalr	-1322(ra) # 8000432e <nameiparent>
    80005860:	892a                	mv	s2,a0
    80005862:	c935                	beqz	a0,800058d6 <sys_link+0x10a>
  ilock(dp);
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	306080e7          	jalr	774(ra) # 80003b6a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000586c:	00092703          	lw	a4,0(s2)
    80005870:	409c                	lw	a5,0(s1)
    80005872:	04f71d63          	bne	a4,a5,800058cc <sys_link+0x100>
    80005876:	40d0                	lw	a2,4(s1)
    80005878:	fd040593          	add	a1,s0,-48
    8000587c:	854a                	mv	a0,s2
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	9e0080e7          	jalr	-1568(ra) # 8000425e <dirlink>
    80005886:	04054363          	bltz	a0,800058cc <sys_link+0x100>
  iunlockput(dp);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	540080e7          	jalr	1344(ra) # 80003dcc <iunlockput>
  iput(ip);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	48e080e7          	jalr	1166(ra) # 80003d24 <iput>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	cec080e7          	jalr	-788(ra) # 8000458a <end_op>
  return 0;
    800058a6:	4781                	li	a5,0
    800058a8:	a085                	j	80005908 <sys_link+0x13c>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	ce0080e7          	jalr	-800(ra) # 8000458a <end_op>
    return -1;
    800058b2:	57fd                	li	a5,-1
    800058b4:	a891                	j	80005908 <sys_link+0x13c>
    iunlockput(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	514080e7          	jalr	1300(ra) # 80003dcc <iunlockput>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	cca080e7          	jalr	-822(ra) # 8000458a <end_op>
    return -1;
    800058c8:	57fd                	li	a5,-1
    800058ca:	a83d                	j	80005908 <sys_link+0x13c>
    iunlockput(dp);
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	4fe080e7          	jalr	1278(ra) # 80003dcc <iunlockput>
  ilock(ip);
    800058d6:	8526                	mv	a0,s1
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	292080e7          	jalr	658(ra) # 80003b6a <ilock>
  ip->nlink--;
    800058e0:	04a4d783          	lhu	a5,74(s1)
    800058e4:	37fd                	addw	a5,a5,-1
    800058e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	1b2080e7          	jalr	434(ra) # 80003a9e <iupdate>
  iunlockput(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	4d6080e7          	jalr	1238(ra) # 80003dcc <iunlockput>
  end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	c8c080e7          	jalr	-884(ra) # 8000458a <end_op>
  return -1;
    80005906:	57fd                	li	a5,-1
}
    80005908:	853e                	mv	a0,a5
    8000590a:	70b2                	ld	ra,296(sp)
    8000590c:	7412                	ld	s0,288(sp)
    8000590e:	64f2                	ld	s1,280(sp)
    80005910:	6952                	ld	s2,272(sp)
    80005912:	6155                	add	sp,sp,304
    80005914:	8082                	ret

0000000080005916 <sys_unlink>:
{
    80005916:	7151                	add	sp,sp,-240
    80005918:	f586                	sd	ra,232(sp)
    8000591a:	f1a2                	sd	s0,224(sp)
    8000591c:	eda6                	sd	s1,216(sp)
    8000591e:	e9ca                	sd	s2,208(sp)
    80005920:	e5ce                	sd	s3,200(sp)
    80005922:	1980                	add	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005924:	08000613          	li	a2,128
    80005928:	f3040593          	add	a1,s0,-208
    8000592c:	4501                	li	a0,0
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	5ee080e7          	jalr	1518(ra) # 80002f1c <argstr>
    80005936:	18054163          	bltz	a0,80005ab8 <sys_unlink+0x1a2>
  begin_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	bd6080e7          	jalr	-1066(ra) # 80004510 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005942:	fb040593          	add	a1,s0,-80
    80005946:	f3040513          	add	a0,s0,-208
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	9e4080e7          	jalr	-1564(ra) # 8000432e <nameiparent>
    80005952:	84aa                	mv	s1,a0
    80005954:	c979                	beqz	a0,80005a2a <sys_unlink+0x114>
  ilock(dp);
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	214080e7          	jalr	532(ra) # 80003b6a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000595e:	00003597          	auipc	a1,0x3
    80005962:	daa58593          	add	a1,a1,-598 # 80008708 <syscalls+0x2b8>
    80005966:	fb040513          	add	a0,s0,-80
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	6ca080e7          	jalr	1738(ra) # 80004034 <namecmp>
    80005972:	14050a63          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
    80005976:	00003597          	auipc	a1,0x3
    8000597a:	d9a58593          	add	a1,a1,-614 # 80008710 <syscalls+0x2c0>
    8000597e:	fb040513          	add	a0,s0,-80
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	6b2080e7          	jalr	1714(ra) # 80004034 <namecmp>
    8000598a:	12050e63          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000598e:	f2c40613          	add	a2,s0,-212
    80005992:	fb040593          	add	a1,s0,-80
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	6b6080e7          	jalr	1718(ra) # 8000404e <dirlookup>
    800059a0:	892a                	mv	s2,a0
    800059a2:	12050263          	beqz	a0,80005ac6 <sys_unlink+0x1b0>
  ilock(ip);
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	1c4080e7          	jalr	452(ra) # 80003b6a <ilock>
  if(ip->nlink < 1)
    800059ae:	04a91783          	lh	a5,74(s2)
    800059b2:	08f05263          	blez	a5,80005a36 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059b6:	04491703          	lh	a4,68(s2)
    800059ba:	4785                	li	a5,1
    800059bc:	08f70563          	beq	a4,a5,80005a46 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059c0:	4641                	li	a2,16
    800059c2:	4581                	li	a1,0
    800059c4:	fc040513          	add	a0,s0,-64
    800059c8:	ffffb097          	auipc	ra,0xffffb
    800059cc:	384080e7          	jalr	900(ra) # 80000d4c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d0:	4741                	li	a4,16
    800059d2:	f2c42683          	lw	a3,-212(s0)
    800059d6:	fc040613          	add	a2,s0,-64
    800059da:	4581                	li	a1,0
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	538080e7          	jalr	1336(ra) # 80003f16 <writei>
    800059e6:	47c1                	li	a5,16
    800059e8:	0af51563          	bne	a0,a5,80005a92 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059ec:	04491703          	lh	a4,68(s2)
    800059f0:	4785                	li	a5,1
    800059f2:	0af70863          	beq	a4,a5,80005aa2 <sys_unlink+0x18c>
  iunlockput(dp);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	3d4080e7          	jalr	980(ra) # 80003dcc <iunlockput>
  ip->nlink--;
    80005a00:	04a95783          	lhu	a5,74(s2)
    80005a04:	37fd                	addw	a5,a5,-1
    80005a06:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a0a:	854a                	mv	a0,s2
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	092080e7          	jalr	146(ra) # 80003a9e <iupdate>
  iunlockput(ip);
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	3b6080e7          	jalr	950(ra) # 80003dcc <iunlockput>
  end_op();
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	b6c080e7          	jalr	-1172(ra) # 8000458a <end_op>
  return 0;
    80005a26:	4501                	li	a0,0
    80005a28:	a84d                	j	80005ada <sys_unlink+0x1c4>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	b60080e7          	jalr	-1184(ra) # 8000458a <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
    80005a34:	a05d                	j	80005ada <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a36:	00003517          	auipc	a0,0x3
    80005a3a:	ce250513          	add	a0,a0,-798 # 80008718 <syscalls+0x2c8>
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	afe080e7          	jalr	-1282(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a46:	04c92703          	lw	a4,76(s2)
    80005a4a:	02000793          	li	a5,32
    80005a4e:	f6e7f9e3          	bgeu	a5,a4,800059c0 <sys_unlink+0xaa>
    80005a52:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a56:	4741                	li	a4,16
    80005a58:	86ce                	mv	a3,s3
    80005a5a:	f1840613          	add	a2,s0,-232
    80005a5e:	4581                	li	a1,0
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	3bc080e7          	jalr	956(ra) # 80003e1e <readi>
    80005a6a:	47c1                	li	a5,16
    80005a6c:	00f51b63          	bne	a0,a5,80005a82 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a70:	f1845783          	lhu	a5,-232(s0)
    80005a74:	e7a1                	bnez	a5,80005abc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a76:	29c1                	addw	s3,s3,16
    80005a78:	04c92783          	lw	a5,76(s2)
    80005a7c:	fcf9ede3          	bltu	s3,a5,80005a56 <sys_unlink+0x140>
    80005a80:	b781                	j	800059c0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a82:	00003517          	auipc	a0,0x3
    80005a86:	cae50513          	add	a0,a0,-850 # 80008730 <syscalls+0x2e0>
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	ab2080e7          	jalr	-1358(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005a92:	00003517          	auipc	a0,0x3
    80005a96:	cb650513          	add	a0,a0,-842 # 80008748 <syscalls+0x2f8>
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	aa2080e7          	jalr	-1374(ra) # 8000053c <panic>
    dp->nlink--;
    80005aa2:	04a4d783          	lhu	a5,74(s1)
    80005aa6:	37fd                	addw	a5,a5,-1
    80005aa8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	ff0080e7          	jalr	-16(ra) # 80003a9e <iupdate>
    80005ab6:	b781                	j	800059f6 <sys_unlink+0xe0>
    return -1;
    80005ab8:	557d                	li	a0,-1
    80005aba:	a005                	j	80005ada <sys_unlink+0x1c4>
    iunlockput(ip);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	30e080e7          	jalr	782(ra) # 80003dcc <iunlockput>
  iunlockput(dp);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	304080e7          	jalr	772(ra) # 80003dcc <iunlockput>
  end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	aba080e7          	jalr	-1350(ra) # 8000458a <end_op>
  return -1;
    80005ad8:	557d                	li	a0,-1
}
    80005ada:	70ae                	ld	ra,232(sp)
    80005adc:	740e                	ld	s0,224(sp)
    80005ade:	64ee                	ld	s1,216(sp)
    80005ae0:	694e                	ld	s2,208(sp)
    80005ae2:	69ae                	ld	s3,200(sp)
    80005ae4:	616d                	add	sp,sp,240
    80005ae6:	8082                	ret

0000000080005ae8 <sys_open>:

uint64
sys_open(void)
{
    80005ae8:	7131                	add	sp,sp,-192
    80005aea:	fd06                	sd	ra,184(sp)
    80005aec:	f922                	sd	s0,176(sp)
    80005aee:	f526                	sd	s1,168(sp)
    80005af0:	f14a                	sd	s2,160(sp)
    80005af2:	ed4e                	sd	s3,152(sp)
    80005af4:	0180                	add	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005af6:	f4c40593          	add	a1,s0,-180
    80005afa:	4505                	li	a0,1
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	3e0080e7          	jalr	992(ra) # 80002edc <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b04:	08000613          	li	a2,128
    80005b08:	f5040593          	add	a1,s0,-176
    80005b0c:	4501                	li	a0,0
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	40e080e7          	jalr	1038(ra) # 80002f1c <argstr>
    80005b16:	87aa                	mv	a5,a0
    return -1;
    80005b18:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005b1a:	0a07c863          	bltz	a5,80005bca <sys_open+0xe2>

  begin_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	9f2080e7          	jalr	-1550(ra) # 80004510 <begin_op>

  if(omode & O_CREATE){
    80005b26:	f4c42783          	lw	a5,-180(s0)
    80005b2a:	2007f793          	and	a5,a5,512
    80005b2e:	cbdd                	beqz	a5,80005be4 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005b30:	4681                	li	a3,0
    80005b32:	4601                	li	a2,0
    80005b34:	4589                	li	a1,2
    80005b36:	f5040513          	add	a0,s0,-176
    80005b3a:	00000097          	auipc	ra,0x0
    80005b3e:	958080e7          	jalr	-1704(ra) # 80005492 <create>
    80005b42:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b44:	c951                	beqz	a0,80005bd8 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b46:	04449703          	lh	a4,68(s1)
    80005b4a:	478d                	li	a5,3
    80005b4c:	00f71763          	bne	a4,a5,80005b5a <sys_open+0x72>
    80005b50:	0464d703          	lhu	a4,70(s1)
    80005b54:	47a5                	li	a5,9
    80005b56:	0ce7ec63          	bltu	a5,a4,80005c2e <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	dbe080e7          	jalr	-578(ra) # 80004918 <filealloc>
    80005b62:	892a                	mv	s2,a0
    80005b64:	c56d                	beqz	a0,80005c4e <sys_open+0x166>
    80005b66:	00000097          	auipc	ra,0x0
    80005b6a:	8ea080e7          	jalr	-1814(ra) # 80005450 <fdalloc>
    80005b6e:	89aa                	mv	s3,a0
    80005b70:	0c054a63          	bltz	a0,80005c44 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b74:	04449703          	lh	a4,68(s1)
    80005b78:	478d                	li	a5,3
    80005b7a:	0ef70563          	beq	a4,a5,80005c64 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b7e:	4789                	li	a5,2
    80005b80:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005b84:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005b88:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005b8c:	f4c42783          	lw	a5,-180(s0)
    80005b90:	0017c713          	xor	a4,a5,1
    80005b94:	8b05                	and	a4,a4,1
    80005b96:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b9a:	0037f713          	and	a4,a5,3
    80005b9e:	00e03733          	snez	a4,a4
    80005ba2:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ba6:	4007f793          	and	a5,a5,1024
    80005baa:	c791                	beqz	a5,80005bb6 <sys_open+0xce>
    80005bac:	04449703          	lh	a4,68(s1)
    80005bb0:	4789                	li	a5,2
    80005bb2:	0cf70063          	beq	a4,a5,80005c72 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005bb6:	8526                	mv	a0,s1
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	074080e7          	jalr	116(ra) # 80003c2c <iunlock>
  end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	9ca080e7          	jalr	-1590(ra) # 8000458a <end_op>

  return fd;
    80005bc8:	854e                	mv	a0,s3
}
    80005bca:	70ea                	ld	ra,184(sp)
    80005bcc:	744a                	ld	s0,176(sp)
    80005bce:	74aa                	ld	s1,168(sp)
    80005bd0:	790a                	ld	s2,160(sp)
    80005bd2:	69ea                	ld	s3,152(sp)
    80005bd4:	6129                	add	sp,sp,192
    80005bd6:	8082                	ret
      end_op();
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	9b2080e7          	jalr	-1614(ra) # 8000458a <end_op>
      return -1;
    80005be0:	557d                	li	a0,-1
    80005be2:	b7e5                	j	80005bca <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005be4:	f5040513          	add	a0,s0,-176
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	728080e7          	jalr	1832(ra) # 80004310 <namei>
    80005bf0:	84aa                	mv	s1,a0
    80005bf2:	c905                	beqz	a0,80005c22 <sys_open+0x13a>
    ilock(ip);
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	f76080e7          	jalr	-138(ra) # 80003b6a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bfc:	04449703          	lh	a4,68(s1)
    80005c00:	4785                	li	a5,1
    80005c02:	f4f712e3          	bne	a4,a5,80005b46 <sys_open+0x5e>
    80005c06:	f4c42783          	lw	a5,-180(s0)
    80005c0a:	dba1                	beqz	a5,80005b5a <sys_open+0x72>
      iunlockput(ip);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	1be080e7          	jalr	446(ra) # 80003dcc <iunlockput>
      end_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	974080e7          	jalr	-1676(ra) # 8000458a <end_op>
      return -1;
    80005c1e:	557d                	li	a0,-1
    80005c20:	b76d                	j	80005bca <sys_open+0xe2>
      end_op();
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	968080e7          	jalr	-1688(ra) # 8000458a <end_op>
      return -1;
    80005c2a:	557d                	li	a0,-1
    80005c2c:	bf79                	j	80005bca <sys_open+0xe2>
    iunlockput(ip);
    80005c2e:	8526                	mv	a0,s1
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	19c080e7          	jalr	412(ra) # 80003dcc <iunlockput>
    end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	952080e7          	jalr	-1710(ra) # 8000458a <end_op>
    return -1;
    80005c40:	557d                	li	a0,-1
    80005c42:	b761                	j	80005bca <sys_open+0xe2>
      fileclose(f);
    80005c44:	854a                	mv	a0,s2
    80005c46:	fffff097          	auipc	ra,0xfffff
    80005c4a:	d8e080e7          	jalr	-626(ra) # 800049d4 <fileclose>
    iunlockput(ip);
    80005c4e:	8526                	mv	a0,s1
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	17c080e7          	jalr	380(ra) # 80003dcc <iunlockput>
    end_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	932080e7          	jalr	-1742(ra) # 8000458a <end_op>
    return -1;
    80005c60:	557d                	li	a0,-1
    80005c62:	b7a5                	j	80005bca <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005c64:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005c68:	04649783          	lh	a5,70(s1)
    80005c6c:	02f91223          	sh	a5,36(s2)
    80005c70:	bf21                	j	80005b88 <sys_open+0xa0>
    itrunc(ip);
    80005c72:	8526                	mv	a0,s1
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	004080e7          	jalr	4(ra) # 80003c78 <itrunc>
    80005c7c:	bf2d                	j	80005bb6 <sys_open+0xce>

0000000080005c7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c7e:	7175                	add	sp,sp,-144
    80005c80:	e506                	sd	ra,136(sp)
    80005c82:	e122                	sd	s0,128(sp)
    80005c84:	0900                	add	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	88a080e7          	jalr	-1910(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c8e:	08000613          	li	a2,128
    80005c92:	f7040593          	add	a1,s0,-144
    80005c96:	4501                	li	a0,0
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	284080e7          	jalr	644(ra) # 80002f1c <argstr>
    80005ca0:	02054963          	bltz	a0,80005cd2 <sys_mkdir+0x54>
    80005ca4:	4681                	li	a3,0
    80005ca6:	4601                	li	a2,0
    80005ca8:	4585                	li	a1,1
    80005caa:	f7040513          	add	a0,s0,-144
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	7e4080e7          	jalr	2020(ra) # 80005492 <create>
    80005cb6:	cd11                	beqz	a0,80005cd2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	114080e7          	jalr	276(ra) # 80003dcc <iunlockput>
  end_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	8ca080e7          	jalr	-1846(ra) # 8000458a <end_op>
  return 0;
    80005cc8:	4501                	li	a0,0
}
    80005cca:	60aa                	ld	ra,136(sp)
    80005ccc:	640a                	ld	s0,128(sp)
    80005cce:	6149                	add	sp,sp,144
    80005cd0:	8082                	ret
    end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	8b8080e7          	jalr	-1864(ra) # 8000458a <end_op>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	b7fd                	j	80005cca <sys_mkdir+0x4c>

0000000080005cde <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cde:	7135                	add	sp,sp,-160
    80005ce0:	ed06                	sd	ra,152(sp)
    80005ce2:	e922                	sd	s0,144(sp)
    80005ce4:	1100                	add	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	82a080e7          	jalr	-2006(ra) # 80004510 <begin_op>
  argint(1, &major);
    80005cee:	f6c40593          	add	a1,s0,-148
    80005cf2:	4505                	li	a0,1
    80005cf4:	ffffd097          	auipc	ra,0xffffd
    80005cf8:	1e8080e7          	jalr	488(ra) # 80002edc <argint>
  argint(2, &minor);
    80005cfc:	f6840593          	add	a1,s0,-152
    80005d00:	4509                	li	a0,2
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	1da080e7          	jalr	474(ra) # 80002edc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d0a:	08000613          	li	a2,128
    80005d0e:	f7040593          	add	a1,s0,-144
    80005d12:	4501                	li	a0,0
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	208080e7          	jalr	520(ra) # 80002f1c <argstr>
    80005d1c:	02054b63          	bltz	a0,80005d52 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d20:	f6841683          	lh	a3,-152(s0)
    80005d24:	f6c41603          	lh	a2,-148(s0)
    80005d28:	458d                	li	a1,3
    80005d2a:	f7040513          	add	a0,s0,-144
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	764080e7          	jalr	1892(ra) # 80005492 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d36:	cd11                	beqz	a0,80005d52 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	094080e7          	jalr	148(ra) # 80003dcc <iunlockput>
  end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	84a080e7          	jalr	-1974(ra) # 8000458a <end_op>
  return 0;
    80005d48:	4501                	li	a0,0
}
    80005d4a:	60ea                	ld	ra,152(sp)
    80005d4c:	644a                	ld	s0,144(sp)
    80005d4e:	610d                	add	sp,sp,160
    80005d50:	8082                	ret
    end_op();
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	838080e7          	jalr	-1992(ra) # 8000458a <end_op>
    return -1;
    80005d5a:	557d                	li	a0,-1
    80005d5c:	b7fd                	j	80005d4a <sys_mknod+0x6c>

0000000080005d5e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d5e:	7135                	add	sp,sp,-160
    80005d60:	ed06                	sd	ra,152(sp)
    80005d62:	e922                	sd	s0,144(sp)
    80005d64:	e526                	sd	s1,136(sp)
    80005d66:	e14a                	sd	s2,128(sp)
    80005d68:	1100                	add	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d6a:	ffffc097          	auipc	ra,0xffffc
    80005d6e:	d96080e7          	jalr	-618(ra) # 80001b00 <myproc>
    80005d72:	892a                	mv	s2,a0
  
  begin_op();
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	79c080e7          	jalr	1948(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d7c:	08000613          	li	a2,128
    80005d80:	f6040593          	add	a1,s0,-160
    80005d84:	4501                	li	a0,0
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	196080e7          	jalr	406(ra) # 80002f1c <argstr>
    80005d8e:	04054b63          	bltz	a0,80005de4 <sys_chdir+0x86>
    80005d92:	f6040513          	add	a0,s0,-160
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	57a080e7          	jalr	1402(ra) # 80004310 <namei>
    80005d9e:	84aa                	mv	s1,a0
    80005da0:	c131                	beqz	a0,80005de4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	dc8080e7          	jalr	-568(ra) # 80003b6a <ilock>
  if(ip->type != T_DIR){
    80005daa:	04449703          	lh	a4,68(s1)
    80005dae:	4785                	li	a5,1
    80005db0:	04f71063          	bne	a4,a5,80005df0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005db4:	8526                	mv	a0,s1
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	e76080e7          	jalr	-394(ra) # 80003c2c <iunlock>
  iput(p->cwd);
    80005dbe:	15093503          	ld	a0,336(s2)
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	f62080e7          	jalr	-158(ra) # 80003d24 <iput>
  end_op();
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	7c0080e7          	jalr	1984(ra) # 8000458a <end_op>
  p->cwd = ip;
    80005dd2:	14993823          	sd	s1,336(s2)
  return 0;
    80005dd6:	4501                	li	a0,0
}
    80005dd8:	60ea                	ld	ra,152(sp)
    80005dda:	644a                	ld	s0,144(sp)
    80005ddc:	64aa                	ld	s1,136(sp)
    80005dde:	690a                	ld	s2,128(sp)
    80005de0:	610d                	add	sp,sp,160
    80005de2:	8082                	ret
    end_op();
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	7a6080e7          	jalr	1958(ra) # 8000458a <end_op>
    return -1;
    80005dec:	557d                	li	a0,-1
    80005dee:	b7ed                	j	80005dd8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005df0:	8526                	mv	a0,s1
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	fda080e7          	jalr	-38(ra) # 80003dcc <iunlockput>
    end_op();
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	790080e7          	jalr	1936(ra) # 8000458a <end_op>
    return -1;
    80005e02:	557d                	li	a0,-1
    80005e04:	bfd1                	j	80005dd8 <sys_chdir+0x7a>

0000000080005e06 <sys_exec>:

uint64
sys_exec(void)
{
    80005e06:	7121                	add	sp,sp,-448
    80005e08:	ff06                	sd	ra,440(sp)
    80005e0a:	fb22                	sd	s0,432(sp)
    80005e0c:	f726                	sd	s1,424(sp)
    80005e0e:	f34a                	sd	s2,416(sp)
    80005e10:	ef4e                	sd	s3,408(sp)
    80005e12:	eb52                	sd	s4,400(sp)
    80005e14:	0380                	add	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005e16:	e4840593          	add	a1,s0,-440
    80005e1a:	4505                	li	a0,1
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	0e0080e7          	jalr	224(ra) # 80002efc <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e24:	08000613          	li	a2,128
    80005e28:	f5040593          	add	a1,s0,-176
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	0ee080e7          	jalr	238(ra) # 80002f1c <argstr>
    80005e36:	87aa                	mv	a5,a0
    return -1;
    80005e38:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e3a:	0c07c263          	bltz	a5,80005efe <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005e3e:	10000613          	li	a2,256
    80005e42:	4581                	li	a1,0
    80005e44:	e5040513          	add	a0,s0,-432
    80005e48:	ffffb097          	auipc	ra,0xffffb
    80005e4c:	f04080e7          	jalr	-252(ra) # 80000d4c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e50:	e5040493          	add	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005e54:	89a6                	mv	s3,s1
    80005e56:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e58:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e5c:	00391513          	sll	a0,s2,0x3
    80005e60:	e4040593          	add	a1,s0,-448
    80005e64:	e4843783          	ld	a5,-440(s0)
    80005e68:	953e                	add	a0,a0,a5
    80005e6a:	ffffd097          	auipc	ra,0xffffd
    80005e6e:	fd4080e7          	jalr	-44(ra) # 80002e3e <fetchaddr>
    80005e72:	02054a63          	bltz	a0,80005ea6 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005e76:	e4043783          	ld	a5,-448(s0)
    80005e7a:	c3b9                	beqz	a5,80005ec0 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	caa080e7          	jalr	-854(ra) # 80000b26 <kalloc>
    80005e84:	85aa                	mv	a1,a0
    80005e86:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e8a:	cd11                	beqz	a0,80005ea6 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e8c:	6605                	lui	a2,0x1
    80005e8e:	e4043503          	ld	a0,-448(s0)
    80005e92:	ffffd097          	auipc	ra,0xffffd
    80005e96:	ffe080e7          	jalr	-2(ra) # 80002e90 <fetchstr>
    80005e9a:	00054663          	bltz	a0,80005ea6 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005e9e:	0905                	add	s2,s2,1
    80005ea0:	09a1                	add	s3,s3,8
    80005ea2:	fb491de3          	bne	s2,s4,80005e5c <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ea6:	f5040913          	add	s2,s0,-176
    80005eaa:	6088                	ld	a0,0(s1)
    80005eac:	c921                	beqz	a0,80005efc <sys_exec+0xf6>
    kfree(argv[i]);
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	b36080e7          	jalr	-1226(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb6:	04a1                	add	s1,s1,8
    80005eb8:	ff2499e3          	bne	s1,s2,80005eaa <sys_exec+0xa4>
  return -1;
    80005ebc:	557d                	li	a0,-1
    80005ebe:	a081                	j	80005efe <sys_exec+0xf8>
      argv[i] = 0;
    80005ec0:	0009079b          	sext.w	a5,s2
    80005ec4:	078e                	sll	a5,a5,0x3
    80005ec6:	fd078793          	add	a5,a5,-48
    80005eca:	97a2                	add	a5,a5,s0
    80005ecc:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005ed0:	e5040593          	add	a1,s0,-432
    80005ed4:	f5040513          	add	a0,s0,-176
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	172080e7          	jalr	370(ra) # 8000504a <exec>
    80005ee0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee2:	f5040993          	add	s3,s0,-176
    80005ee6:	6088                	ld	a0,0(s1)
    80005ee8:	c901                	beqz	a0,80005ef8 <sys_exec+0xf2>
    kfree(argv[i]);
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	afa080e7          	jalr	-1286(ra) # 800009e4 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef2:	04a1                	add	s1,s1,8
    80005ef4:	ff3499e3          	bne	s1,s3,80005ee6 <sys_exec+0xe0>
  return ret;
    80005ef8:	854a                	mv	a0,s2
    80005efa:	a011                	j	80005efe <sys_exec+0xf8>
  return -1;
    80005efc:	557d                	li	a0,-1
}
    80005efe:	70fa                	ld	ra,440(sp)
    80005f00:	745a                	ld	s0,432(sp)
    80005f02:	74ba                	ld	s1,424(sp)
    80005f04:	791a                	ld	s2,416(sp)
    80005f06:	69fa                	ld	s3,408(sp)
    80005f08:	6a5a                	ld	s4,400(sp)
    80005f0a:	6139                	add	sp,sp,448
    80005f0c:	8082                	ret

0000000080005f0e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f0e:	7139                	add	sp,sp,-64
    80005f10:	fc06                	sd	ra,56(sp)
    80005f12:	f822                	sd	s0,48(sp)
    80005f14:	f426                	sd	s1,40(sp)
    80005f16:	0080                	add	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	be8080e7          	jalr	-1048(ra) # 80001b00 <myproc>
    80005f20:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f22:	fd840593          	add	a1,s0,-40
    80005f26:	4501                	li	a0,0
    80005f28:	ffffd097          	auipc	ra,0xffffd
    80005f2c:	fd4080e7          	jalr	-44(ra) # 80002efc <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f30:	fc840593          	add	a1,s0,-56
    80005f34:	fd040513          	add	a0,s0,-48
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	dc8080e7          	jalr	-568(ra) # 80004d00 <pipealloc>
    return -1;
    80005f40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f42:	0c054463          	bltz	a0,8000600a <sys_pipe+0xfc>
  fd0 = -1;
    80005f46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f4a:	fd043503          	ld	a0,-48(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	502080e7          	jalr	1282(ra) # 80005450 <fdalloc>
    80005f56:	fca42223          	sw	a0,-60(s0)
    80005f5a:	08054b63          	bltz	a0,80005ff0 <sys_pipe+0xe2>
    80005f5e:	fc843503          	ld	a0,-56(s0)
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	4ee080e7          	jalr	1262(ra) # 80005450 <fdalloc>
    80005f6a:	fca42023          	sw	a0,-64(s0)
    80005f6e:	06054863          	bltz	a0,80005fde <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f72:	4691                	li	a3,4
    80005f74:	fc440613          	add	a2,s0,-60
    80005f78:	fd843583          	ld	a1,-40(s0)
    80005f7c:	68a8                	ld	a0,80(s1)
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	7b0080e7          	jalr	1968(ra) # 8000172e <copyout>
    80005f86:	02054063          	bltz	a0,80005fa6 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f8a:	4691                	li	a3,4
    80005f8c:	fc040613          	add	a2,s0,-64
    80005f90:	fd843583          	ld	a1,-40(s0)
    80005f94:	0591                	add	a1,a1,4
    80005f96:	68a8                	ld	a0,80(s1)
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	796080e7          	jalr	1942(ra) # 8000172e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fa0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa2:	06055463          	bgez	a0,8000600a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005fa6:	fc442783          	lw	a5,-60(s0)
    80005faa:	07e9                	add	a5,a5,26
    80005fac:	078e                	sll	a5,a5,0x3
    80005fae:	97a6                	add	a5,a5,s1
    80005fb0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fb4:	fc042783          	lw	a5,-64(s0)
    80005fb8:	07e9                	add	a5,a5,26
    80005fba:	078e                	sll	a5,a5,0x3
    80005fbc:	94be                	add	s1,s1,a5
    80005fbe:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fc2:	fd043503          	ld	a0,-48(s0)
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	a0e080e7          	jalr	-1522(ra) # 800049d4 <fileclose>
    fileclose(wf);
    80005fce:	fc843503          	ld	a0,-56(s0)
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	a02080e7          	jalr	-1534(ra) # 800049d4 <fileclose>
    return -1;
    80005fda:	57fd                	li	a5,-1
    80005fdc:	a03d                	j	8000600a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fde:	fc442783          	lw	a5,-60(s0)
    80005fe2:	0007c763          	bltz	a5,80005ff0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fe6:	07e9                	add	a5,a5,26
    80005fe8:	078e                	sll	a5,a5,0x3
    80005fea:	97a6                	add	a5,a5,s1
    80005fec:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ff0:	fd043503          	ld	a0,-48(s0)
    80005ff4:	fffff097          	auipc	ra,0xfffff
    80005ff8:	9e0080e7          	jalr	-1568(ra) # 800049d4 <fileclose>
    fileclose(wf);
    80005ffc:	fc843503          	ld	a0,-56(s0)
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	9d4080e7          	jalr	-1580(ra) # 800049d4 <fileclose>
    return -1;
    80006008:	57fd                	li	a5,-1
}
    8000600a:	853e                	mv	a0,a5
    8000600c:	70e2                	ld	ra,56(sp)
    8000600e:	7442                	ld	s0,48(sp)
    80006010:	74a2                	ld	s1,40(sp)
    80006012:	6121                	add	sp,sp,64
    80006014:	8082                	ret
	...

0000000080006020 <kernelvec>:
    80006020:	7111                	add	sp,sp,-256
    80006022:	e006                	sd	ra,0(sp)
    80006024:	e40a                	sd	sp,8(sp)
    80006026:	e80e                	sd	gp,16(sp)
    80006028:	ec12                	sd	tp,24(sp)
    8000602a:	f016                	sd	t0,32(sp)
    8000602c:	f41a                	sd	t1,40(sp)
    8000602e:	f81e                	sd	t2,48(sp)
    80006030:	fc22                	sd	s0,56(sp)
    80006032:	e0a6                	sd	s1,64(sp)
    80006034:	e4aa                	sd	a0,72(sp)
    80006036:	e8ae                	sd	a1,80(sp)
    80006038:	ecb2                	sd	a2,88(sp)
    8000603a:	f0b6                	sd	a3,96(sp)
    8000603c:	f4ba                	sd	a4,104(sp)
    8000603e:	f8be                	sd	a5,112(sp)
    80006040:	fcc2                	sd	a6,120(sp)
    80006042:	e146                	sd	a7,128(sp)
    80006044:	e54a                	sd	s2,136(sp)
    80006046:	e94e                	sd	s3,144(sp)
    80006048:	ed52                	sd	s4,152(sp)
    8000604a:	f156                	sd	s5,160(sp)
    8000604c:	f55a                	sd	s6,168(sp)
    8000604e:	f95e                	sd	s7,176(sp)
    80006050:	fd62                	sd	s8,184(sp)
    80006052:	e1e6                	sd	s9,192(sp)
    80006054:	e5ea                	sd	s10,200(sp)
    80006056:	e9ee                	sd	s11,208(sp)
    80006058:	edf2                	sd	t3,216(sp)
    8000605a:	f1f6                	sd	t4,224(sp)
    8000605c:	f5fa                	sd	t5,232(sp)
    8000605e:	f9fe                	sd	t6,240(sp)
    80006060:	cabfc0ef          	jal	80002d0a <kerneltrap>
    80006064:	6082                	ld	ra,0(sp)
    80006066:	6122                	ld	sp,8(sp)
    80006068:	61c2                	ld	gp,16(sp)
    8000606a:	7282                	ld	t0,32(sp)
    8000606c:	7322                	ld	t1,40(sp)
    8000606e:	73c2                	ld	t2,48(sp)
    80006070:	7462                	ld	s0,56(sp)
    80006072:	6486                	ld	s1,64(sp)
    80006074:	6526                	ld	a0,72(sp)
    80006076:	65c6                	ld	a1,80(sp)
    80006078:	6666                	ld	a2,88(sp)
    8000607a:	7686                	ld	a3,96(sp)
    8000607c:	7726                	ld	a4,104(sp)
    8000607e:	77c6                	ld	a5,112(sp)
    80006080:	7866                	ld	a6,120(sp)
    80006082:	688a                	ld	a7,128(sp)
    80006084:	692a                	ld	s2,136(sp)
    80006086:	69ca                	ld	s3,144(sp)
    80006088:	6a6a                	ld	s4,152(sp)
    8000608a:	7a8a                	ld	s5,160(sp)
    8000608c:	7b2a                	ld	s6,168(sp)
    8000608e:	7bca                	ld	s7,176(sp)
    80006090:	7c6a                	ld	s8,184(sp)
    80006092:	6c8e                	ld	s9,192(sp)
    80006094:	6d2e                	ld	s10,200(sp)
    80006096:	6dce                	ld	s11,208(sp)
    80006098:	6e6e                	ld	t3,216(sp)
    8000609a:	7e8e                	ld	t4,224(sp)
    8000609c:	7f2e                	ld	t5,232(sp)
    8000609e:	7fce                	ld	t6,240(sp)
    800060a0:	6111                	add	sp,sp,256
    800060a2:	10200073          	sret
    800060a6:	00000013          	nop
    800060aa:	00000013          	nop
    800060ae:	0001                	nop

00000000800060b0 <timervec>:
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	e10c                	sd	a1,0(a0)
    800060b6:	e510                	sd	a2,8(a0)
    800060b8:	e914                	sd	a3,16(a0)
    800060ba:	6d0c                	ld	a1,24(a0)
    800060bc:	7110                	ld	a2,32(a0)
    800060be:	6194                	ld	a3,0(a1)
    800060c0:	96b2                	add	a3,a3,a2
    800060c2:	e194                	sd	a3,0(a1)
    800060c4:	4589                	li	a1,2
    800060c6:	14459073          	csrw	sip,a1
    800060ca:	6914                	ld	a3,16(a0)
    800060cc:	6510                	ld	a2,8(a0)
    800060ce:	610c                	ld	a1,0(a0)
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	30200073          	mret
	...

00000000800060da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060da:	1141                	add	sp,sp,-16
    800060dc:	e422                	sd	s0,8(sp)
    800060de:	0800                	add	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060e0:	0c0007b7          	lui	a5,0xc000
    800060e4:	4705                	li	a4,1
    800060e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060e8:	c3d8                	sw	a4,4(a5)
}
    800060ea:	6422                	ld	s0,8(sp)
    800060ec:	0141                	add	sp,sp,16
    800060ee:	8082                	ret

00000000800060f0 <plicinithart>:

void
plicinithart(void)
{
    800060f0:	1141                	add	sp,sp,-16
    800060f2:	e406                	sd	ra,8(sp)
    800060f4:	e022                	sd	s0,0(sp)
    800060f6:	0800                	add	s0,sp,16
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	9dc080e7          	jalr	-1572(ra) # 80001ad4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006100:	0085171b          	sllw	a4,a0,0x8
    80006104:	0c0027b7          	lui	a5,0xc002
    80006108:	97ba                	add	a5,a5,a4
    8000610a:	40200713          	li	a4,1026
    8000610e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006112:	00d5151b          	sllw	a0,a0,0xd
    80006116:	0c2017b7          	lui	a5,0xc201
    8000611a:	97aa                	add	a5,a5,a0
    8000611c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006120:	60a2                	ld	ra,8(sp)
    80006122:	6402                	ld	s0,0(sp)
    80006124:	0141                	add	sp,sp,16
    80006126:	8082                	ret

0000000080006128 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006128:	1141                	add	sp,sp,-16
    8000612a:	e406                	sd	ra,8(sp)
    8000612c:	e022                	sd	s0,0(sp)
    8000612e:	0800                	add	s0,sp,16
  int hart = cpuid();
    80006130:	ffffc097          	auipc	ra,0xffffc
    80006134:	9a4080e7          	jalr	-1628(ra) # 80001ad4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006138:	00d5151b          	sllw	a0,a0,0xd
    8000613c:	0c2017b7          	lui	a5,0xc201
    80006140:	97aa                	add	a5,a5,a0
  return irq;
}
    80006142:	43c8                	lw	a0,4(a5)
    80006144:	60a2                	ld	ra,8(sp)
    80006146:	6402                	ld	s0,0(sp)
    80006148:	0141                	add	sp,sp,16
    8000614a:	8082                	ret

000000008000614c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000614c:	1101                	add	sp,sp,-32
    8000614e:	ec06                	sd	ra,24(sp)
    80006150:	e822                	sd	s0,16(sp)
    80006152:	e426                	sd	s1,8(sp)
    80006154:	1000                	add	s0,sp,32
    80006156:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	97c080e7          	jalr	-1668(ra) # 80001ad4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006160:	00d5151b          	sllw	a0,a0,0xd
    80006164:	0c2017b7          	lui	a5,0xc201
    80006168:	97aa                	add	a5,a5,a0
    8000616a:	c3c4                	sw	s1,4(a5)
}
    8000616c:	60e2                	ld	ra,24(sp)
    8000616e:	6442                	ld	s0,16(sp)
    80006170:	64a2                	ld	s1,8(sp)
    80006172:	6105                	add	sp,sp,32
    80006174:	8082                	ret

0000000080006176 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006176:	1141                	add	sp,sp,-16
    80006178:	e406                	sd	ra,8(sp)
    8000617a:	e022                	sd	s0,0(sp)
    8000617c:	0800                	add	s0,sp,16
  if(i >= NUM)
    8000617e:	479d                	li	a5,7
    80006180:	04a7cc63          	blt	a5,a0,800061d8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006184:	0023c797          	auipc	a5,0x23c
    80006188:	0b478793          	add	a5,a5,180 # 80242238 <disk>
    8000618c:	97aa                	add	a5,a5,a0
    8000618e:	0187c783          	lbu	a5,24(a5)
    80006192:	ebb9                	bnez	a5,800061e8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006194:	00451693          	sll	a3,a0,0x4
    80006198:	0023c797          	auipc	a5,0x23c
    8000619c:	0a078793          	add	a5,a5,160 # 80242238 <disk>
    800061a0:	6398                	ld	a4,0(a5)
    800061a2:	9736                	add	a4,a4,a3
    800061a4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800061a8:	6398                	ld	a4,0(a5)
    800061aa:	9736                	add	a4,a4,a3
    800061ac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800061b0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800061b4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800061b8:	97aa                	add	a5,a5,a0
    800061ba:	4705                	li	a4,1
    800061bc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800061c0:	0023c517          	auipc	a0,0x23c
    800061c4:	09050513          	add	a0,a0,144 # 80242250 <disk+0x18>
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	068080e7          	jalr	104(ra) # 80002230 <wakeup>
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	add	sp,sp,16
    800061d6:	8082                	ret
    panic("free_desc 1");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	58050513          	add	a0,a0,1408 # 80008758 <syscalls+0x308>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	35c080e7          	jalr	860(ra) # 8000053c <panic>
    panic("free_desc 2");
    800061e8:	00002517          	auipc	a0,0x2
    800061ec:	58050513          	add	a0,a0,1408 # 80008768 <syscalls+0x318>
    800061f0:	ffffa097          	auipc	ra,0xffffa
    800061f4:	34c080e7          	jalr	844(ra) # 8000053c <panic>

00000000800061f8 <virtio_disk_init>:
{
    800061f8:	1101                	add	sp,sp,-32
    800061fa:	ec06                	sd	ra,24(sp)
    800061fc:	e822                	sd	s0,16(sp)
    800061fe:	e426                	sd	s1,8(sp)
    80006200:	e04a                	sd	s2,0(sp)
    80006202:	1000                	add	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006204:	00002597          	auipc	a1,0x2
    80006208:	57458593          	add	a1,a1,1396 # 80008778 <syscalls+0x328>
    8000620c:	0023c517          	auipc	a0,0x23c
    80006210:	15450513          	add	a0,a0,340 # 80242360 <disk+0x128>
    80006214:	ffffb097          	auipc	ra,0xffffb
    80006218:	9ac080e7          	jalr	-1620(ra) # 80000bc0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000621c:	100017b7          	lui	a5,0x10001
    80006220:	4398                	lw	a4,0(a5)
    80006222:	2701                	sext.w	a4,a4
    80006224:	747277b7          	lui	a5,0x74727
    80006228:	97678793          	add	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000622c:	14f71b63          	bne	a4,a5,80006382 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006230:	100017b7          	lui	a5,0x10001
    80006234:	43dc                	lw	a5,4(a5)
    80006236:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006238:	4709                	li	a4,2
    8000623a:	14e79463          	bne	a5,a4,80006382 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000623e:	100017b7          	lui	a5,0x10001
    80006242:	479c                	lw	a5,8(a5)
    80006244:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006246:	12e79e63          	bne	a5,a4,80006382 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000624a:	100017b7          	lui	a5,0x10001
    8000624e:	47d8                	lw	a4,12(a5)
    80006250:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006252:	554d47b7          	lui	a5,0x554d4
    80006256:	55178793          	add	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000625a:	12f71463          	bne	a4,a5,80006382 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000625e:	100017b7          	lui	a5,0x10001
    80006262:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006266:	4705                	li	a4,1
    80006268:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000626a:	470d                	li	a4,3
    8000626c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000626e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006270:	c7ffe6b7          	lui	a3,0xc7ffe
    80006274:	75f68693          	add	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc3e7>
    80006278:	8f75                	and	a4,a4,a3
    8000627a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627c:	472d                	li	a4,11
    8000627e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006280:	5bbc                	lw	a5,112(a5)
    80006282:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006286:	8ba1                	and	a5,a5,8
    80006288:	10078563          	beqz	a5,80006392 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000628c:	100017b7          	lui	a5,0x10001
    80006290:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006294:	43fc                	lw	a5,68(a5)
    80006296:	2781                	sext.w	a5,a5
    80006298:	10079563          	bnez	a5,800063a2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000629c:	100017b7          	lui	a5,0x10001
    800062a0:	5bdc                	lw	a5,52(a5)
    800062a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062a4:	10078763          	beqz	a5,800063b2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800062a8:	471d                	li	a4,7
    800062aa:	10f77c63          	bgeu	a4,a5,800063c2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800062ae:	ffffb097          	auipc	ra,0xffffb
    800062b2:	878080e7          	jalr	-1928(ra) # 80000b26 <kalloc>
    800062b6:	0023c497          	auipc	s1,0x23c
    800062ba:	f8248493          	add	s1,s1,-126 # 80242238 <disk>
    800062be:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	866080e7          	jalr	-1946(ra) # 80000b26 <kalloc>
    800062c8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062ca:	ffffb097          	auipc	ra,0xffffb
    800062ce:	85c080e7          	jalr	-1956(ra) # 80000b26 <kalloc>
    800062d2:	87aa                	mv	a5,a0
    800062d4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062d6:	6088                	ld	a0,0(s1)
    800062d8:	cd6d                	beqz	a0,800063d2 <virtio_disk_init+0x1da>
    800062da:	0023c717          	auipc	a4,0x23c
    800062de:	f6673703          	ld	a4,-154(a4) # 80242240 <disk+0x8>
    800062e2:	cb65                	beqz	a4,800063d2 <virtio_disk_init+0x1da>
    800062e4:	c7fd                	beqz	a5,800063d2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062e6:	6605                	lui	a2,0x1
    800062e8:	4581                	li	a1,0
    800062ea:	ffffb097          	auipc	ra,0xffffb
    800062ee:	a62080e7          	jalr	-1438(ra) # 80000d4c <memset>
  memset(disk.avail, 0, PGSIZE);
    800062f2:	0023c497          	auipc	s1,0x23c
    800062f6:	f4648493          	add	s1,s1,-186 # 80242238 <disk>
    800062fa:	6605                	lui	a2,0x1
    800062fc:	4581                	li	a1,0
    800062fe:	6488                	ld	a0,8(s1)
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	a4c080e7          	jalr	-1460(ra) # 80000d4c <memset>
  memset(disk.used, 0, PGSIZE);
    80006308:	6605                	lui	a2,0x1
    8000630a:	4581                	li	a1,0
    8000630c:	6888                	ld	a0,16(s1)
    8000630e:	ffffb097          	auipc	ra,0xffffb
    80006312:	a3e080e7          	jalr	-1474(ra) # 80000d4c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006316:	100017b7          	lui	a5,0x10001
    8000631a:	4721                	li	a4,8
    8000631c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000631e:	4098                	lw	a4,0(s1)
    80006320:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006324:	40d8                	lw	a4,4(s1)
    80006326:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000632a:	6498                	ld	a4,8(s1)
    8000632c:	0007069b          	sext.w	a3,a4
    80006330:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006334:	9701                	sra	a4,a4,0x20
    80006336:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000633a:	6898                	ld	a4,16(s1)
    8000633c:	0007069b          	sext.w	a3,a4
    80006340:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006344:	9701                	sra	a4,a4,0x20
    80006346:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000634a:	4705                	li	a4,1
    8000634c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000634e:	00e48c23          	sb	a4,24(s1)
    80006352:	00e48ca3          	sb	a4,25(s1)
    80006356:	00e48d23          	sb	a4,26(s1)
    8000635a:	00e48da3          	sb	a4,27(s1)
    8000635e:	00e48e23          	sb	a4,28(s1)
    80006362:	00e48ea3          	sb	a4,29(s1)
    80006366:	00e48f23          	sb	a4,30(s1)
    8000636a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000636e:	00496913          	or	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006372:	0727a823          	sw	s2,112(a5)
}
    80006376:	60e2                	ld	ra,24(sp)
    80006378:	6442                	ld	s0,16(sp)
    8000637a:	64a2                	ld	s1,8(sp)
    8000637c:	6902                	ld	s2,0(sp)
    8000637e:	6105                	add	sp,sp,32
    80006380:	8082                	ret
    panic("could not find virtio disk");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	40650513          	add	a0,a0,1030 # 80008788 <syscalls+0x338>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b2080e7          	jalr	434(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	41650513          	add	a0,a0,1046 # 800087a8 <syscalls+0x358>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a2080e7          	jalr	418(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	42650513          	add	a0,a0,1062 # 800087c8 <syscalls+0x378>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	192080e7          	jalr	402(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	43650513          	add	a0,a0,1078 # 800087e8 <syscalls+0x398>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	182080e7          	jalr	386(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	44650513          	add	a0,a0,1094 # 80008808 <syscalls+0x3b8>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	172080e7          	jalr	370(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	45650513          	add	a0,a0,1110 # 80008828 <syscalls+0x3d8>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	162080e7          	jalr	354(ra) # 8000053c <panic>

00000000800063e2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063e2:	7159                	add	sp,sp,-112
    800063e4:	f486                	sd	ra,104(sp)
    800063e6:	f0a2                	sd	s0,96(sp)
    800063e8:	eca6                	sd	s1,88(sp)
    800063ea:	e8ca                	sd	s2,80(sp)
    800063ec:	e4ce                	sd	s3,72(sp)
    800063ee:	e0d2                	sd	s4,64(sp)
    800063f0:	fc56                	sd	s5,56(sp)
    800063f2:	f85a                	sd	s6,48(sp)
    800063f4:	f45e                	sd	s7,40(sp)
    800063f6:	f062                	sd	s8,32(sp)
    800063f8:	ec66                	sd	s9,24(sp)
    800063fa:	e86a                	sd	s10,16(sp)
    800063fc:	1880                	add	s0,sp,112
    800063fe:	8a2a                	mv	s4,a0
    80006400:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006402:	00c52c83          	lw	s9,12(a0)
    80006406:	001c9c9b          	sllw	s9,s9,0x1
    8000640a:	1c82                	sll	s9,s9,0x20
    8000640c:	020cdc93          	srl	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006410:	0023c517          	auipc	a0,0x23c
    80006414:	f5050513          	add	a0,a0,-176 # 80242360 <disk+0x128>
    80006418:	ffffb097          	auipc	ra,0xffffb
    8000641c:	838080e7          	jalr	-1992(ra) # 80000c50 <acquire>
  for(int i = 0; i < 3; i++){
    80006420:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006422:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006424:	0023cb17          	auipc	s6,0x23c
    80006428:	e14b0b13          	add	s6,s6,-492 # 80242238 <disk>
  for(int i = 0; i < 3; i++){
    8000642c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000642e:	0023cc17          	auipc	s8,0x23c
    80006432:	f32c0c13          	add	s8,s8,-206 # 80242360 <disk+0x128>
    80006436:	a095                	j	8000649a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006438:	00fb0733          	add	a4,s6,a5
    8000643c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006440:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006442:	0207c563          	bltz	a5,8000646c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006446:	2605                	addw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006448:	0591                	add	a1,a1,4
    8000644a:	05560d63          	beq	a2,s5,800064a4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000644e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006450:	0023c717          	auipc	a4,0x23c
    80006454:	de870713          	add	a4,a4,-536 # 80242238 <disk>
    80006458:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000645a:	01874683          	lbu	a3,24(a4)
    8000645e:	fee9                	bnez	a3,80006438 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006460:	2785                	addw	a5,a5,1
    80006462:	0705                	add	a4,a4,1
    80006464:	fe979be3          	bne	a5,s1,8000645a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006468:	57fd                	li	a5,-1
    8000646a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000646c:	00c05e63          	blez	a2,80006488 <virtio_disk_rw+0xa6>
    80006470:	060a                	sll	a2,a2,0x2
    80006472:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006476:	0009a503          	lw	a0,0(s3)
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	cfc080e7          	jalr	-772(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    80006482:	0991                	add	s3,s3,4
    80006484:	ffa999e3          	bne	s3,s10,80006476 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006488:	85e2                	mv	a1,s8
    8000648a:	0023c517          	auipc	a0,0x23c
    8000648e:	dc650513          	add	a0,a0,-570 # 80242250 <disk+0x18>
    80006492:	ffffc097          	auipc	ra,0xffffc
    80006496:	d3a080e7          	jalr	-710(ra) # 800021cc <sleep>
  for(int i = 0; i < 3; i++){
    8000649a:	f9040993          	add	s3,s0,-112
{
    8000649e:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800064a0:	864a                	mv	a2,s2
    800064a2:	b775                	j	8000644e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064a4:	f9042503          	lw	a0,-112(s0)
    800064a8:	00a50713          	add	a4,a0,10
    800064ac:	0712                	sll	a4,a4,0x4

  if(write)
    800064ae:	0023c797          	auipc	a5,0x23c
    800064b2:	d8a78793          	add	a5,a5,-630 # 80242238 <disk>
    800064b6:	00e786b3          	add	a3,a5,a4
    800064ba:	01703633          	snez	a2,s7
    800064be:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064c0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800064c4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064c8:	f6070613          	add	a2,a4,-160
    800064cc:	6394                	ld	a3,0(a5)
    800064ce:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064d0:	00870593          	add	a1,a4,8
    800064d4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064d6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064d8:	0007b803          	ld	a6,0(a5)
    800064dc:	9642                	add	a2,a2,a6
    800064de:	46c1                	li	a3,16
    800064e0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064e2:	4585                	li	a1,1
    800064e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064e8:	f9442683          	lw	a3,-108(s0)
    800064ec:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064f0:	0692                	sll	a3,a3,0x4
    800064f2:	9836                	add	a6,a6,a3
    800064f4:	058a0613          	add	a2,s4,88
    800064f8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064fc:	0007b803          	ld	a6,0(a5)
    80006500:	96c2                	add	a3,a3,a6
    80006502:	40000613          	li	a2,1024
    80006506:	c690                	sw	a2,8(a3)
  if(write)
    80006508:	001bb613          	seqz	a2,s7
    8000650c:	0016161b          	sllw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006510:	00166613          	or	a2,a2,1
    80006514:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006518:	f9842603          	lw	a2,-104(s0)
    8000651c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006520:	00250693          	add	a3,a0,2
    80006524:	0692                	sll	a3,a3,0x4
    80006526:	96be                	add	a3,a3,a5
    80006528:	58fd                	li	a7,-1
    8000652a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000652e:	0612                	sll	a2,a2,0x4
    80006530:	9832                	add	a6,a6,a2
    80006532:	f9070713          	add	a4,a4,-112
    80006536:	973e                	add	a4,a4,a5
    80006538:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000653c:	6398                	ld	a4,0(a5)
    8000653e:	9732                	add	a4,a4,a2
    80006540:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006542:	4609                	li	a2,2
    80006544:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006548:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000654c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006550:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006554:	6794                	ld	a3,8(a5)
    80006556:	0026d703          	lhu	a4,2(a3)
    8000655a:	8b1d                	and	a4,a4,7
    8000655c:	0706                	sll	a4,a4,0x1
    8000655e:	96ba                	add	a3,a3,a4
    80006560:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006564:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006568:	6798                	ld	a4,8(a5)
    8000656a:	00275783          	lhu	a5,2(a4)
    8000656e:	2785                	addw	a5,a5,1
    80006570:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006574:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006578:	100017b7          	lui	a5,0x10001
    8000657c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006580:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006584:	0023c917          	auipc	s2,0x23c
    80006588:	ddc90913          	add	s2,s2,-548 # 80242360 <disk+0x128>
  while(b->disk == 1) {
    8000658c:	4485                	li	s1,1
    8000658e:	00b79c63          	bne	a5,a1,800065a6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006592:	85ca                	mv	a1,s2
    80006594:	8552                	mv	a0,s4
    80006596:	ffffc097          	auipc	ra,0xffffc
    8000659a:	c36080e7          	jalr	-970(ra) # 800021cc <sleep>
  while(b->disk == 1) {
    8000659e:	004a2783          	lw	a5,4(s4)
    800065a2:	fe9788e3          	beq	a5,s1,80006592 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800065a6:	f9042903          	lw	s2,-112(s0)
    800065aa:	00290713          	add	a4,s2,2
    800065ae:	0712                	sll	a4,a4,0x4
    800065b0:	0023c797          	auipc	a5,0x23c
    800065b4:	c8878793          	add	a5,a5,-888 # 80242238 <disk>
    800065b8:	97ba                	add	a5,a5,a4
    800065ba:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800065be:	0023c997          	auipc	s3,0x23c
    800065c2:	c7a98993          	add	s3,s3,-902 # 80242238 <disk>
    800065c6:	00491713          	sll	a4,s2,0x4
    800065ca:	0009b783          	ld	a5,0(s3)
    800065ce:	97ba                	add	a5,a5,a4
    800065d0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065d4:	854a                	mv	a0,s2
    800065d6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065da:	00000097          	auipc	ra,0x0
    800065de:	b9c080e7          	jalr	-1124(ra) # 80006176 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065e2:	8885                	and	s1,s1,1
    800065e4:	f0ed                	bnez	s1,800065c6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065e6:	0023c517          	auipc	a0,0x23c
    800065ea:	d7a50513          	add	a0,a0,-646 # 80242360 <disk+0x128>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	716080e7          	jalr	1814(ra) # 80000d04 <release>
}
    800065f6:	70a6                	ld	ra,104(sp)
    800065f8:	7406                	ld	s0,96(sp)
    800065fa:	64e6                	ld	s1,88(sp)
    800065fc:	6946                	ld	s2,80(sp)
    800065fe:	69a6                	ld	s3,72(sp)
    80006600:	6a06                	ld	s4,64(sp)
    80006602:	7ae2                	ld	s5,56(sp)
    80006604:	7b42                	ld	s6,48(sp)
    80006606:	7ba2                	ld	s7,40(sp)
    80006608:	7c02                	ld	s8,32(sp)
    8000660a:	6ce2                	ld	s9,24(sp)
    8000660c:	6d42                	ld	s10,16(sp)
    8000660e:	6165                	add	sp,sp,112
    80006610:	8082                	ret

0000000080006612 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006612:	1101                	add	sp,sp,-32
    80006614:	ec06                	sd	ra,24(sp)
    80006616:	e822                	sd	s0,16(sp)
    80006618:	e426                	sd	s1,8(sp)
    8000661a:	1000                	add	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000661c:	0023c497          	auipc	s1,0x23c
    80006620:	c1c48493          	add	s1,s1,-996 # 80242238 <disk>
    80006624:	0023c517          	auipc	a0,0x23c
    80006628:	d3c50513          	add	a0,a0,-708 # 80242360 <disk+0x128>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	624080e7          	jalr	1572(ra) # 80000c50 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006634:	10001737          	lui	a4,0x10001
    80006638:	533c                	lw	a5,96(a4)
    8000663a:	8b8d                	and	a5,a5,3
    8000663c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000663e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006642:	689c                	ld	a5,16(s1)
    80006644:	0204d703          	lhu	a4,32(s1)
    80006648:	0027d783          	lhu	a5,2(a5)
    8000664c:	04f70863          	beq	a4,a5,8000669c <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006650:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006654:	6898                	ld	a4,16(s1)
    80006656:	0204d783          	lhu	a5,32(s1)
    8000665a:	8b9d                	and	a5,a5,7
    8000665c:	078e                	sll	a5,a5,0x3
    8000665e:	97ba                	add	a5,a5,a4
    80006660:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006662:	00278713          	add	a4,a5,2
    80006666:	0712                	sll	a4,a4,0x4
    80006668:	9726                	add	a4,a4,s1
    8000666a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000666e:	e721                	bnez	a4,800066b6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006670:	0789                	add	a5,a5,2
    80006672:	0792                	sll	a5,a5,0x4
    80006674:	97a6                	add	a5,a5,s1
    80006676:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006678:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000667c:	ffffc097          	auipc	ra,0xffffc
    80006680:	bb4080e7          	jalr	-1100(ra) # 80002230 <wakeup>

    disk.used_idx += 1;
    80006684:	0204d783          	lhu	a5,32(s1)
    80006688:	2785                	addw	a5,a5,1
    8000668a:	17c2                	sll	a5,a5,0x30
    8000668c:	93c1                	srl	a5,a5,0x30
    8000668e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006692:	6898                	ld	a4,16(s1)
    80006694:	00275703          	lhu	a4,2(a4)
    80006698:	faf71ce3          	bne	a4,a5,80006650 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000669c:	0023c517          	auipc	a0,0x23c
    800066a0:	cc450513          	add	a0,a0,-828 # 80242360 <disk+0x128>
    800066a4:	ffffa097          	auipc	ra,0xffffa
    800066a8:	660080e7          	jalr	1632(ra) # 80000d04 <release>
}
    800066ac:	60e2                	ld	ra,24(sp)
    800066ae:	6442                	ld	s0,16(sp)
    800066b0:	64a2                	ld	s1,8(sp)
    800066b2:	6105                	add	sp,sp,32
    800066b4:	8082                	ret
      panic("virtio_disk_intr status");
    800066b6:	00002517          	auipc	a0,0x2
    800066ba:	18a50513          	add	a0,a0,394 # 80008840 <syscalls+0x3f0>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	e7e080e7          	jalr	-386(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	sll	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	sll	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
