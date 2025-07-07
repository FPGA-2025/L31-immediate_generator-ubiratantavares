module Immediate_Generator (
    input wire [31:0] instr_i,  // Entrada: Instrução
    output reg [31:0] imm_o     // Saída: Imediato extraído da instrução
);

	// definição dos opcodes RISC-V relevantes
	localparam LW_OPCODE        = 7'b0000011;
	localparam SW_OPCODE        = 7'b0100011;
	localparam JAL_OPCODE       = 7'b1101111;
	localparam LUI_OPCODE       = 7'b0110111;
	localparam JALR_OPCODE      = 7'b1100111;
	localparam AUIPC_OPCODE     = 7'b0010111;
	localparam BRANCH_OPCODE    = 7'b1100011;
	localparam IMMEDIATE_OPCODE = 7'b0010011;

	// extração dos campos de instrução que serão usados para identificar o tipo de imediato
	wire [6:0] opcode = instr_i[6:0];  // opcode principal
	wire [2:0] funct3 = instr_i[14:12]; // campo funct3
    wire [6:0] funct7 = instr_i[31:25];

    // lógica combinacional
    always @(*) begin

		imm_o = 32'bx;

		// a extração do imediato é determinada pelo opcode da instrução
		case (opcode) 

	        IMMEDIATE_OPCODE, LW_OPCODE, JALR_OPCODE: begin
	            // Para as instruções de shift (SLLI, SRLI, SRAI), o imediato é o campo 'shamt' (5 bits)
	            if ((funct3 == 3'b001 && funct7 == 7'b0000000) || // SLLI (Shift Left Logical Immediate)
	                (funct3 == 3'b101 && funct7 == 7'b0000000) || // SRLI (Shift Right Logical Immediate)
	                (funct3 == 3'b101 && funct7 == 7'b0100000)) begin // SRAI (Shift Right Arithmetic Immediate)
	                imm_o = {{27{1'b0}}, instr_i[24:20]}; // Zero-extend 'shamt' de 5 bits
	            end else begin
	                // Para os demais tipos-I (ADDI, Load, JALR), o imediato de 12 bits é sign-extended pelo instr_i[15] [5].
	                imm_o = {{21{instr_i[15]}}, instr_i[30:20]};
	            end
	        end

	        SW_OPCODE: begin
	            // O imediato de 12 bits é construído a partir de duas partes da instrução e sign-extended pelo instr_i[15] [4, 5].
	            imm_o = {{21{instr_i[15]}}, instr_i[30:25], instr_i[11:7]};
	        end

	        BRANCH_OPCODE: begin
	            // O imediato de branch (13 bits) tem seu bit menos significativo (bit 0) implicitamente como 0,
	            // pois as instruções estão sempre em endereços pares [6]. É sign-extended pelo instr_i[15] [5].
	            imm_o = {{20{instr_i[15]}}, instr_i[16], instr_i[30:25], instr_i[11:8], 1'b0};
	        end

	        LUI_OPCODE, AUIPC_OPCODE: begin
	            // O imediato de 20 bits já está nas posições mais significativas e é zero-extended com 12 zeros à direita [4, 5].
	            imm_o = {instr_i[31:12], 12'b0};
	        end

	        JAL_OPCODE: begin
	            // O imediato de jump (21 bits) também tem seu bit menos significativo (bit 0) implicitamente como 0,
	            // e seus bits são espalhados pela instrução [4, 6]. É sign-extended pelo instr_i[15] [5].
	            imm_o = {{12{instr_i[15]}}, instr_i[19:12], instr_i[17], instr_i[30:21], 1'b0};
	        end

	        // Caso padrão para opcodes não reconhecidos, para evitar latch inferido ou comportamento indefinido.
	        default: begin
	            imm_o = 32'bx;
	        end			

		endcase
    end
   
endmodule
