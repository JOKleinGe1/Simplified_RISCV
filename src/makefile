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
MEM     = test.mem
MIF     = test.mif
MAP     = test.map
DUMP    = test.dump
VERILOG = picorv32.v  system_picorv32.v  tb_sys_picorv32.v ram1port8k_sim.v BCDto7seg.v RTClock.v

GENERATED = $(OBJS) $(ELF) $(BIN) $(MEM) $(MIF) $(MAP) $(DUMP) 

.PHONY: all clean 

all: $(BIN) $(DUMP) $(MEM) $(MIF) 

$(ELF): $(SRCS_S) $(SRCS_C)
	@echo "1️⃣  Compilation 2️⃣  Edition de lien (linker) .s .c -> .elf"
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(MAP) -o $@ $^ $(LDLIBS)

$(DUMP): $(ELF)
	@echo "3️⃣ -B  Déassemblage de l'exécutable .elf -> .dump"
	$(OBJDUMP) -D $(ELF) > $(DUMP)
	
$(BIN): $(ELF)
	@echo "3️⃣ -A  Transcription executable en Binaire .elf -> .bin"
	$(OBJCOPY) -O binary $< $@

$(MEM): $(BIN)
	@echo "3️⃣ -C  Transcription executable pour Verilog-readmemh 32-bit little-endian .bin -> .mem"
	hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%02s%02s%02s%02s\n", $$4, $$3, $$2, $$1)}' > $(MEM)

$(MIF): $(BIN)
	@echo "3️⃣ -D  Transcription executable pour Quartus .bin -> .mif"
	@echo "(Voir les commandes @echo du makefile pour l'entete du fichier > MIF)"
	@echo "-- MIF file generated from $(BIN)"             >  $(MIF)
	@echo "WIDTH=32;"                                    >> $(MIF)
	@echo "DEPTH=2048;"                                  >> $(MIF)
	@echo "ADDRESS_RADIX=HEX;"                           >> $(MIF)
	@echo "DATA_RADIX=HEX;"                              >> $(MIF)
	@echo "CONTENT BEGIN"                                >> $(MIF)
	@# Génère les mots little-endian (4 octets → 1 mot)
	hexdump -v -e '4/1 "%02x " "\n"' $(BIN) | \
	awk '{printf("%04X : %02s%02s%02s%02s;\n", NR-1, $$4, $$3, $$2, $$1)}' >> $(MIF)
	@# Calcule la dernière adresse utilisée et ajoute le remplissage à zéro
	@LAST_ADDR=$$(expr `wc -c < $(BIN)` / 4); \
	if [ $$LAST_ADDR -lt 2047 ]; then \
	  printf "[%04X .. %04X] : 00000000;\n" $$LAST_ADDR 2047 >> $(MIF); \
	  echo "printf \"[$$LAST_ADDR .. 07FF] : 00000000;\" >> $(MIF);"; \
	fi
	@echo "END;"                                         >> $(MIF)
	@echo "✅ Compilation logicielle OK."	


clean:
	@echo "🚮 Nettoyage des fichiers générés..."
	rm -f $(GENERATED) 
	
