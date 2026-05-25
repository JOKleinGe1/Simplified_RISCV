.section 	.text
.global 	_start
_start: 
  addi x1, x0, 0
  addi x2, x0, 5
  addi x3, x0, 512 
  addi x5, x0, 0
loop:
   sw x1, 0(x3)
   lw x4, 0(x3)
   addi x1, x1, 1
   addi x3, x3, 4
   add x5, x5, x4
   beq x1, x2, end
   beq x0, x0, loop
 end:
   addi x3, x0, 1024 
   lw x4, 0(x3)
   xori x1, x4, 15
   sw x1, 4(x3)
   beq x0, x0, end
