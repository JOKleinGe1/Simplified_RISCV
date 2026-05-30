module riscv_simple(
    input clk,
    input reset, 
    input [7:0] inport, 
    output reg [7:0] outport, 
    output [23:0] pc_dbg 
);

// =====================================================
// ETATS
// =====================================================
localparam FETCH      = 3'h0;
localparam DECODE     = 3'h1;
localparam EXECUTE    = 3'h2;
localparam MEM        = 3'h3;
localparam WB         = 3'h4;
localparam TRAP       = 3'h5;

reg [4:0] state;

// =====================================================
// CPU
// =====================================================
reg  [31:0] PC;
reg  [31:0] instruction;
reg  [31:0] imem[0:255];

// =====================================================
// REGISTERS
// =====================================================
reg [31:0] registers [0:31];

// =====================================================
// MEMOIRES SYNCHRONES
// =====================================================
reg [31:0] dmem [0:255];

// sorties enregistrées mémoire
reg [31:0] dmem_data;

// =====================================================
// DECODE
// =====================================================
wire [6:0] opcode = instruction[6:0];
wire [4:0] rd     = instruction[11:7];
wire [2:0] funct3 = instruction[14:12];
wire [4:0] rs1    = instruction[19:15];
wire [4:0] rs2    = instruction[24:20];
wire [6:0] funct7 = instruction[31:25];

reg [31:0] read_data1 ;
reg [31:0] read_data2 ;

// =====================================================
// IMMEDIATES
// =====================================================
wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};

wire [31:0] imm_s = {{20{instruction[31]}},
                     instruction[31:25],
                     instruction[11:7]};

wire [31:0] imm_b = {{19{instruction[31]}},
                     instruction[31],
                     instruction[7],
                     instruction[30:25],
                     instruction[11:8],
                     1'b0};

wire [31:0] imm =
    (opcode == 7'b1100011) ? imm_b :
    (opcode == 7'b0100011) ? imm_s :
                             imm_i;

// =====================================================
// CONTROLE
// =====================================================
wire reg_write = (opcode == 7'b0110011) ||
                 (opcode == 7'b0010011) ||
                 (opcode == 7'b0000011);

wire alu_src = (opcode == 7'b0010011) ||
               (opcode == 7'b0000011) ||
               (opcode == 7'b0100011);

wire branch     = (opcode == 7'b1100011);
wire mem_read   = (opcode == 7'b0000011);
wire mem_write  = (opcode == 7'b0100011);
wire mem_to_reg = (opcode == 7'b0000011);

// =====================================================
// ALU CONTROL
// =====================================================
reg [3:0] alu_ctrl;
assign pc_dbg = PC[23:0];

always @(*) begin
    case(opcode)

        // R TYPE
        7'b0110011: begin
    	case(funct3)	
          3'b000: begin
            if(funct7 == 7'b0100000)
                alu_ctrl = 4'b0100;   // SUB
            else
                alu_ctrl = 4'b0000;   // ADD
            end
          3'b111: alu_ctrl = 4'b0001;   // AND
          3'b110: alu_ctrl = 4'b0010;   // OR
          3'b100: alu_ctrl = 4'b0011;   // XOR
        default: alu_ctrl = 4'b0000;
    endcase
end

        // I TYPE
        7'b0010011: begin
            case(funct3)
                3'b000: alu_ctrl = 4'b0000; // ADDI
                3'b100: alu_ctrl = 4'b0011; // XORI
                default: alu_ctrl = 4'b0000;
            endcase
        end

        // LOAD STORE
        7'b0000011,
        7'b0100011:
            alu_ctrl = 4'b0000;

        default:
            alu_ctrl = 4'b0000;
    endcase
end

// =====================================================
// ALU
// =====================================================
wire [31:0] alu_in2 = (alu_src) ? imm : read_data2;

reg [31:0] alu_result;

always @(*) begin
    case(alu_ctrl)
        4'b0000: alu_result = read_data1 + alu_in2; // ADD
        4'b0001: alu_result = read_data1 & alu_in2; // AND
        4'b0010: alu_result = read_data1 | alu_in2; // OR
        4'b0011: alu_result = read_data1 ^ alu_in2; // XOR
        4'b0100: alu_result = read_data1 - alu_in2; // SUB
        default: alu_result = 32'b0;
    endcase
end

// =====================================================
// BRANCH
// =====================================================
wire zero = (read_data1 == read_data2);

// =====================================================
// MACHINE D'ETAT
// =====================================================
always @(posedge clk) begin

    if(!reset) begin
        PC <= 0;
        state <= FETCH;
    end

    else begin
        case(state)

        // =============================================
        // FETCH
        // =============================================
        FETCH: begin
            instruction <= imem[PC[9:2]];
            state <= DECODE;
        end
        
        // =============================================
        // DECODE
        // =============================================
        DECODE: begin
            read_data1 <= registers[rs1];
            read_data2 <= registers[rs2];
            state <= EXECUTE;
        end

        // =============================================
        // EXECUTE
        // =============================================
        EXECUTE: begin
	     state <= MEM;
        end
        
        // -----------------------------------------
        // MEM
        // -----------------------------------------
        MEM: begin
          if (alu_result[10] == 0) begin
             if(mem_read)
                dmem_data <= dmem[alu_result[9:2]];
             if(mem_write)
                dmem[alu_result[9:2]] <= read_data2;
          end
          // ACCESS TO GPIO (ADDRESS 100 
          if (alu_result[10] == 1) begin
             if(mem_read  & (alu_result[10:0] == 32'h400))
                dmem_data <= {24'h0 , inport};
             if(mem_write & (alu_result[10:0] == 32'h404))
                outport <= read_data2[7:0];
	  end
          state <= WB;
        end

	// -----------------------------------------
        // WRITEBACK
        // -----------------------------------------
       WB: begin
            if(reg_write && rd != 0) begin
                if(mem_to_reg)
                    registers[rd] <= dmem_data;
                else
                    registers[rd] <= alu_result;
            end
         // -----------------------------------------
         // PC UPDATE
         // -----------------------------------------
            if(branch && zero)
                PC <= PC + imm;
            else
                PC <= PC + 4;
            state <= FETCH;
        end

        endcase
    end
end

// =====================================================
// PROGRAMME DEMO
// =====================================================
	integer i; 
initial begin

	for(i = 0; i < 32; i = i + 1) registers[i] = 0;
	$readmemh("test.mem",imem);
end

endmodule
