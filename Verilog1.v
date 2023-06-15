
module ramBlock(
	input next,
	input reset,
	output reg [31:0] A, B,
	input clk
);

	// Ram
	parameter DATA_WIDTH = 64;
	parameter ADDR_WIDTH = 5;
	
	reg [ADDR_WIDTH-1:0] addr;
	wire [63:0] ramout;
	
	
	ram #(DATA_WIDTH, ADDR_WIDTH) RAM0(
		.addr(addr),
		.q(ramout),
		.clk(clk)
	);
	
	initial addr = {ADDR_WIDTH{1'b1}};
	
	always @(posedge next, posedge reset) begin
		if (reset) begin 
			addr = 0;
			B = ramout[31:0];
			A = ramout[63:32];
		end else begin
			B = ramout[31:0];
			A = ramout[63:32];
			addr = addr + 1;
		end
	end
	
endmodule

module ram #(parameter DATA_WIDTH = 4, ADDR_WIDTH = 4)(
	input [(ADDR_WIDTH-1):0] addr,
	output reg [(DATA_WIDTH-1):0] q,
	input clk
);
	
	//(* ramstyle = "logic" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	(* ramstyle = "M9K" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	initial begin
		$readmemh("../ram_content.hex", ram);
	end
	
	always @(clk) begin
		q <= ram[addr];
	end

endmodule


// Multiplier
module fpum #(parameter EXPONENT = 30, FRACTION = 22, BIAS = 127) (
    input [(EXPONENT+1):0] A, B,
    output reg [(EXPONENT+1):0] C
);

	parameter mulSize = ((FRACTION+2)*2)-1;
	reg [EXPONENT-FRACTION-1:0] exp;
	reg [(FRACTION+1):0] f1, f2;
	reg [mulSize:0] new_f;

	// ALU Procesdures
	always @(*) begin
		$display("mulSize = %d", mulSize);
		if (A[EXPONENT:0] == 0 || B[EXPONENT:0] == 0) begin
			C[EXPONENT:0] = {EXPONENT+1{1'b0}};
		end else begin
			f1 = {1'b1, A[FRACTION:0]};
			f2 = {1'b1, B[FRACTION:0]};
			new_f = f1 * f2;
			$display("new_f = %b", new_f);
			exp = ((A[EXPONENT:(FRACTION+1)] + B[EXPONENT:(FRACTION+1)]) - BIAS);
			$display("exp = %d", exp);
			if (new_f[mulSize:mulSize-1] > 2'b01) begin
				exp = exp + 1;
				new_f = new_f >> 1;
			end
			C[FRACTION:0] = new_f[mulSize-2:FRACTION+1];
			C[EXPONENT:FRACTION+1] = exp;
		end
		C[EXPONENT+1] = A[EXPONENT + 1] ^ B[EXPONENT + 1];
	end
endmodule



module fpua #(parameter EXPONENT = 30, FRACTION = 22) (
    input [(EXPONENT+1):0] A, B,
    input addsub,
    output reg [(EXPONENT+1):0] C
);

reg [(EXPONENT-FRACTION-1):0] exp1, exp2;
reg [FRACTION+1:0] f1, f2;
reg [(FRACTION+2):0] new_f;
reg A_sign, B_sign;
reg [8:0] loop;

always @(*) begin
    A_sign = A[EXPONENT+1];
    B_sign = B[EXPONENT+1];
    f1 = {1'b1, A[(FRACTION):0]};
    f2 = {1'b1, B[(FRACTION):0]};
    exp1 = A[EXPONENT:FRACTION+1];
    exp2 = B[EXPONENT:FRACTION+1];

   //Alignment
    if (~addsub) B_sign = ~B_sign;

    if (exp1 < exp2) begin 
        f1 = f1 >> (exp2 - exp1);
        exp1 = exp1 + (exp2 - exp1);
    end else if (exp2 < exp1) begin
        f2 = f2 >> (exp1 - exp2);
        exp2 = exp2 + (exp1 - exp2);
    end

    //Checking the fraction and sign
    if (f1 < f2) begin
        if (~addsub && (A_sign != B_sign)) begin
            A_sign = ~A_sign;
            f1 = ~f1 + 1;
        end
        C[EXPONENT+1] = B_sign;
    end
    else if (f2 < f1) begin
        if (~addsub && (A_sign != B_sign)) begin
            B_sign = ~B_sign;
            f2 = ~f2 + 1;
        end
        C[EXPONENT+1] = A_sign;
    end
    else begin 
        C[EXPONENT+1] = B_sign;
    end

    //Addition of the mantissa
    new_f = f1 + f2;
    if (~addsub) new_f[FRACTION+2] = 1'b0;

    //Normalize
	loop = 0;
    while ((new_f[FRACTION+2:FRACTION+1] > 2'b01 || new_f[FRACTION+2:FRACTION+1] == 2'b00) && loop <= 'd32) begin
        if (new_f[FRACTION+2:FRACTION+1] > 2'b01) begin
            new_f = new_f >> 1;
            exp1 = exp1 + 1;
        end else if(new_f[FRACTION+2:FRACTION+1] == 2'b00) begin
            new_f = new_f << 1;
            exp1 = exp1 - 1;
        end
		loop = loop +1;
    end
    C[FRACTION:0] = new_f[FRACTION:0];
    C[EXPONENT:FRACTION+1] = exp1;
end

endmodule






module bin32ToHex(
	input [31:0] bin,
	input lower,
	input off,
	input [1:0] size,
	output reg [47:0] hexout,
	input clk
	);
	
	reg [23:0] into;
	wire [47:0] hex;
	
	binToDisplay hex0(.bin(into[3:0]), .hex(hex[7:0]));
	binToDisplay hex1(.bin(into[7:4]), .hex(hex[15:8]));
	binToDisplay hex2(.bin(into[11:8]), .hex(hex[23:16]));
	binToDisplay hex3(.bin(into[15:12]), .hex(hex[31:24]));
	binToDisplay hex4(.bin(into[19:16]), .hex(hex[39:32]));
	binToDisplay hex5(.bin(into[23:20]), .hex(hex[47:40]));
	
	always @(posedge clk) begin
		if (off) begin
			hexout = {48{1'b1}};
		end else if (size[1:0] == 2'b00) begin // 32 bit
			into = lower ? {{16{1'b0}}, bin[7:0]} : bin[31:8];
			hexout = lower ? {{32{1'b1}}, hex[15:0]} : hex[47:0];
		end else if (size[1:0] == 2'b01) begin // 16 bit
			into = lower ? {{32{1'b0}}} : {{16{1'b0}}, bin[15:0]};
			hexout = lower ? {48{1'b1}} : {{16{1'b1}}, hex[31:0]};
		end else if (size[1:0] == 2'b10) begin // E4M3
			into = lower ? {{32{1'b0}}} : {{24{1'b0}}, bin[7:0]};
			hexout = lower ? {48{1'b1}} : {{32{1'b1}}, hex[15:0]};
		end else if (size[1:0] == 2'b11) begin // E5M2
			into = lower ? {{32{1'b0}}} : {{24{1'b0}}, bin[7:0]};
			hexout = lower ? {48{1'b1}} : {{32{1'b1}}, hex[15:0]};
		end
	end
endmodule


module binToDisplay (
	input [3:0] bin,
	output reg[7:0] hex
	);
	always @(*) begin
	case(bin[3:0]) // HEX#
			4'b0000: hex = 8'b11000000; // 0
			4'b0001: hex = 8'b11111001; // 1
			4'b0010: hex = 8'b10100100; // 2
			4'b0011: hex = 8'b10110000; // 3
			4'b0100: hex = 8'b10011001; // 4
			4'b0101: hex = 8'b10010010; // 5
			4'b0110: hex = 8'b10000010; // 6
			4'b0111: hex = 8'b11111000; // 7
			4'b1000: hex = 8'b10000000; // 8
			4'b1001: hex = 8'b10010000; // 9
			4'b1010: hex = 8'b10001000; // A
			4'b1011: hex = 8'b10000011; // b
			4'b1100: hex = 8'b11000110; // C
			4'b1101: hex = 8'b10100001; // d
			4'b1110: hex = 8'b10000110; // E
			4'b1111: hex = 8'b10001110; // F
			4'bxxxx: hex = 8'b11111111; // Displays nothing
			default: hex = 8'b11111111; // Displays nothing
		endcase
	end
endmodule



// 32 bit test bench
module tb_lab6;
	
	reg [31:0] A, B;
	reg [8:0] count;

	// 16 bit float multiplier
	parameter BIAS16 = 127;
	parameter EXPONENT16 = 14;
	parameter FRACTION16 = 6;
	wire [EXPONENT16+1:0] C16M;

	fpum #(EXPONENT16, FRACTION16, BIAS16) FPU1(
		.A(A[15:0]),
		.B(B[15:0]),
		.C(C16M)
	);

	// 32 bit float multiplier
	parameter BIAS32 = 127;
	parameter EXPONENT32 = 30;
	parameter FRACTION32 = 22;
	wire [EXPONENT32+1:0] C32M;

	// fpum #(EXPONENT32, FRACTION32, BIAS32) FPU0(
	// 	.A(A),
	// 	.B(B),
	// 	.C(C32M)
	// ); 
	

//=======================================================
//  Structural coding
//=======================================================

	initial begin
		for (count = 0; count < 32; count = count + 1) begin
			// Seed the random number generator
			$random;
			A = $urandom;
			B = $urandom;
			#20;
			// Mulitplers
			$display("%b%b%b", A[15:0], B[15:0], C16M);
			// $display("%b%b%b", A, B, C32M);

			// Adders

			// Subtractors
		end

		// A = {32{1'b0}};
		// B = {32{1'b0}};
		// B[15] = 1'b1;
		A = 16'b0000111101110010;
		B = 16'b1111001100101110;
		#20;     
		$display("%b%b%b", A[15:0], B[15:0], C16M);
		// $display("%b%b%b", A, B, C32M);
	end
endmodule

module tb_lab6resetdebug;

	reg clk;
	reg [9:0] SW;

	lab6 lab6_0(
		.MAX10_CLK1_50(clk),
		.SW(SW[9:0])
	);

	initial clk = 1'b0;
	always #5 clk = ~clk;

	initial begin
		// 32 bit
		$display("32 bit");
		$display("32 bit mul");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0001000000; // mul
		#1000;
		$display("32 bit add");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0000000000; // add
		#1000;
		$display("32 bit sub");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0010000000; // sub
		#1000;

		// 16 bit
		$display("16 bit");
		$display("16 bit mul");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0001000001; // mul
		#1000;
		$display("16 bit add");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0000000001; // add
		#1000;
		$display("16 bit sub");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0010000001; // sub
		#1000;

		// E4M3 bit
		$display("E4M3 bit");
		$display("8 bit mul");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0001000010; // mul
		#1000;
		$display("8 bit add");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0000000010; // add
		#1000;
		$display("8 bit sub");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0010000010; // sub
		#1000;

		// E5M2 bit
		$display("E5M2 bit");
		$display("8 bit mul");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0001000011; // mul
		#1000;
		$display("8 bit add");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0000000011; // add
		#1000;
		$display("8 bit sub");
		SW = 10'b1000000000; // sub
		#10;
		SW = 10'b0010000011; // sub
		#1000;
		
		// reset
		$display("reset");
		SW = 10'b1000000000; // sub
	end 

	
endmodule