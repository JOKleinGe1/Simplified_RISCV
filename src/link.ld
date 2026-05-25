/* OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv") */
OUTPUT_ARCH(riscv)

ENTRY (_start)

stack = 0xFC ;

MEMORY
{
    ram (rwx) : ORIGIN = 0x0, LENGTH = 256
}

SECTIONS
{
    .text : ALIGN(4)
    {
	*(.text._start)
        *(.text)
        *(.text.*)
	_etext =  . ;
    } > ram

    .rodata :  ALIGN(4)
    {	
	_srodata = . ;
        *(.rodata)
        *(.rodata.*)
	_erodata = . ;
    } > ram

    .data :  ALIGN(4)
    {
	_sdata = . ;
        *(.data)
        *(.data*)
	_edata = . ;
    } > ram

    .bss :  ALIGN(4)
    {
  	_sbss = . ;
      *(.bss)
  	_ebss = . ;
    } > ram
    
/DISCARD/ : {
    *(.eh_frame)
    *(.comment)
    *(.note*)
    *(.riscv.attributes)
    *(.gnu.build.attributes)
    *(.debug*)
  }

}
