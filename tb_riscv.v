`timescale 1ns/1ps

module tb_riscv;
localparam FETCH      = 3'h0;
localparam DECODE     = 3'h1;
localparam EXECUTE    = 3'h2;
localparam MEM        = 3'h3;
localparam WB         = 3'h4;
localparam TRAP       = 3'h5;
reg clk;
reg reset;
reg [7:0] inport = 8'hC8;
wire [7:0] outport ;
wire [23:0] pc_dbg;
// =========================
// Instanciation du DUT
// =========================
riscv_simple dut (
    .clk(clk),
    .reset(reset), 
    .inport(inport), 
    .outport(outport), 
    .pc_dbg(pc_dbg)
);

// =========================
// Horloge (10 ns)
// =========================
always #5 clk = ~clk;

// =========================
// Simulation
// =========================
integer i;

initial begin
    clk = 0;
    reset = 1'b0;

    // Dump GTKWave
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_riscv);

    for (i = 128; i < 128+ 6; i = i + 1) begin
      $dumpvars(0, dut.dmem[i]);
    end
    for (i = 0; i < 6; i = i + 1) begin
      $dumpvars(0, dut.registers[i]);
    end
    
    // Reset
    #20;
    reset <= 1'b1;

    // Laisser tourner assez longtemps pour la boucle
    #2500;
    inport <= 8'hA3;
    #500;

    // =========================
    // Affichage registres
    // =========================
    $display("==== REGISTERS ====");
    for (i = 0; i < 8; i = i + 1) begin
        $display("r%0d = 0x%08x", i, dut.registers[i]);
    end

    // =========================
    // Affichage mémoire
    // =========================
    $display("==== MEMORY ====");
    for (i = 512/4; i < 512/4+8; i = i + 1) begin
        $display("MEM[%0d] = 0x%08x", i, dut.dmem[i]);
    end

    // =========================
    // Vérification automatique
    // =========================
    if (dut.dmem[128] == 0 &&   
        dut.dmem[129] == 1 &&   
        dut.dmem[130] == 2 &&  
        dut.dmem[131] == 3 &&   
        dut.dmem[132] == 4)       
    begin
        $display("✅ TEST PASSED");
    end
    else begin
        $display("❌ TEST FAILED");
    end

    $finish;
end
always @(posedge clk) 
    if(!reset) $display("RESET");
    else if(dut.state==WB)begin 
    	case(dut.opcode)       		
        	7'b0110011: 
         	case(dut.alu_ctrl)       		
        		4'b0100: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) - r%0d(0x%08x) = 0x%08x",
        			dut.PC,dut.instruction, dut.rd, dut.rs1,dut.registers[dut.rs1],
        			dut.rs2,dut.registers[dut.rs2] ,dut.alu_result ); 
        		4'b0000: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) + r%0d(0x%08x) = 0x%08x",
        			dut.PC,dut.instruction, dut.rd, dut.rs1,dut.registers[dut.rs1],
        			dut.rs2,dut.registers[dut.rs2] ,dut.alu_result ); 
       	 		4'b0001: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) & r%0d(0x%08x) = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.rs2,dut.registers[dut.rs2] ,dut.alu_result ); 
        		4'b0010: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) | r%0d(0x%08x) = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.rs2,dut.registers[dut.rs2] ,dut.alu_result ); 
        		4'b0011: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) ^ r%0d(0x%08x) = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.rs2,dut.registers[dut.rs2] ,dut.alu_result ); 
        		default: $display ("0x%08x:0x%08x (R) r%0d = r%0d(0x%08x) ?? r%0d(0x%08x) = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.rs2,dut.registers[dut.rs2],dut.alu_result  ); 
    		endcase
      		7'b0010011: 
        	case(dut.alu_ctrl)       		
        		4'b0000: $display ("0x%08x:0x%08x (I) r%0d = r%0d(0x%08x) + 0x%08x = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.imm,dut.alu_result ); 
       	 		4'b0001: $display ("0x%08x:0x%08x (I) r%0d = r%0d(0x%08x) & 0x%08x = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.imm,dut.alu_result );  
        		4'b0010: $display ("0x%08x:0x%08x (I) r%0d = r%0d(0x%08x) | 0x%08x = 0x%08x",
        		dut.PC,dut.instruction, dut.rd,  dut.rs1,dut.registers[dut.rs1],
        		dut.imm,dut.alu_result );  
        		4'b0011: $display ("0x%08x:0x%08x (I) r%0d = r%0d(0x%08x) ^ 0x%08x = 0x%08x",
        		dut.PC,dut.instruction, dut.rd, dut.rs1,dut.registers[dut.rs1],
        		dut.imm,dut.alu_result ); 
        		default: $display ("0x%08x:0x%08x (I) r%0d = r%0d(0x%08x) ?? 0x%08x = 0x%08x",
        		dut.PC,dut.instruction, dut.rd, dut.rs1,dut.registers[dut.rs1],
        		dut.imm,dut.alu_result );   
        	endcase
     		7'b0000011:$display ("0x%08x:0x%08x (L) r%0d = mem[r%0d(0x%08x)+0x%08x] = 0x%08x ",
        		dut.PC,dut.instruction, dut.rd, 
        		dut.rs1,dut.registers[dut.rs1],dut.imm , dut.dmem_data);  
        		
        	7'b0100011: $display ("0x%08x:0x%08x (S) mem[r%0d(0x%08x)+0x%08x] = r%0d(0x%08x)",
        		dut.PC,dut.instruction, dut.rs1,dut.registers[dut.rs1],dut.imm ,dut.rs2,dut.read_data2);
        	7'b1100011:  $display ("0x%08x:0x%08x (B) PC = PC + (0x%08x) = 0x%08x ",
        		dut.PC,dut.instruction, dut.imm, dut.imm+dut.PC);
        	default: $display("	UNKNOW !");
    	endcase
	end
endmodule
