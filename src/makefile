CROSS_COMPILE ?= riscv32-linux-gnu-
CC      = $(CROSS_COMPILE)gcc
AS      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump

 CFLAGS  = -march=rv32i -mabi=ilp32 -ffreestanding -fno-common 
 LDFLAGS = -T link.ld -nostdlib -O2 -nostartfiles 
 LDLIBS  = -lgcc
SRCS_C  = 
SRCS_S  = start.S
OBJS    = $(SRCS_S:.S=.o) $(SRCS_C:.c=.o) 

ELF     = test.elf
BIN     = test.bin
DUMP    = test.dump
BINVHD  = imem_initial.vhd

VERILOG = picorv32.v  system_picorv32.v  tb_sys_picorv32.v ram1port8k_sim.v BCDto7seg.v RTClock.v

GENERATED = $(OBJS) $(ELF) $(BIN) $(DUMP) $(BINVHD)

.PHONY: all clean 

all: $(BIN) $(DUMP) $(BINVHD)

$(ELF): $(SRCS_S) $(SRCS_C)
	@echo "1️⃣  Compilation 2️⃣  Edition de lien (linker) .s .c -> .elf"
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(MAP) -o $@ $^ $(LDLIBS)

$(DUMP): $(ELF)
	@echo "3️⃣ -B  Déassemblage de l'exécutable .elf -> .dump"
	$(OBJDUMP) -D $(ELF) > $(DUMP)
	
$(BIN): $(ELF)
	@echo "3️⃣ -A  Transcription executable en Binaire .elf -> .bin"
	$(OBJCOPY) -O binary $< $@

$(BINVHD): $(BIN)
	@echo "4️⃣ Binary VHDL initialization code for instruction memory .bin -> .vhd" 	
	@echo "-- Binary VHDL initialization code for instruction memory"  >  $(BINVHD)
	@echo -- Date: `date`  >>  $(BINVHD)
	@echo "signal imem : imem_t := ("  >>  $(BINVHD)
	hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("X\"%02s%02s%02s%02s\",\n", $$4, $$3, $$2, $$1)}' >> $(BINVHD)
	@echo  "others => X\"00000000\" );" >> $(BINVHD);
	@echo "✅ File  $(BINVHD) is updated.  "	
	
clean:
	@echo "🚮 Nettoyage des fichiers générés..."
	rm -f $(GENERATED) 
	
