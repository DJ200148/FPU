module lab6
(
	input 		          		MAX10_CLK1_50,
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,
	output		     [9:0]		LEDR,
	input 		     [1:0]		KEY,
	input 		     [9:0]		SW
);

// OPERATIONS
// 00 - ADD
// 01 - MULTI
// 10 - SUB

//=======================================================
//  REG/WIRE declarations
//=======================================================
// Globals
wire [31:0] A, B;
reg [31:0] C, oldC;

// 32 bit to hex Converter
reg off;

// State info
reg [1:0] state;
parameter S0 = 2'b00;
parameter S1 = 2'b01;
parameter S2 = 2'b10;
parameter S3 = 2'b11;

// Ram
reg next;

//Your variable declarations
//reg [28:0] timer_limit = 29'd480000000; // about 10 seconds
reg [28:0] timer_limit = 29'd120000000; // about 2 seconds
// reg [28:0] timer_limit = 29'd2; // For waveforms
reg [33:0] timer_count = 0; //See note A

// FPUS
// 32 bit float
parameter BIAS32 = 127;
parameter EXPONENT32 = 30;
parameter FRACTION32 = 22;
wire [EXPONENT32+1:0] C32M;
wire [EXPONENT32+1:0] C32A;
wire [EXPONENT32+1:0] C32S;

fpum #(EXPONENT32, FRACTION32, BIAS32) FPU0(
	.A(A),
	.B(B),
	.C(C32M)
);

fpua #(EXPONENT32, FRACTION32) FPU1(
	.A(A),
	.B(B),
	.addsub(1),
	.C(C32A)
);

fpua #(EXPONENT32, FRACTION32) FPU2(
	.A(A),
	.B(B),
	.addsub(0),
	.C(C32S)
);


// 16 bit float
parameter BIAS16 = 127;
parameter EXPONENT16 = 14;
parameter FRACTION16 = 6;
wire [EXPONENT16+1:0] C16M;
wire [EXPONENT16+1:0] C16A;
wire [EXPONENT16+1:0] C16S;

fpum #(EXPONENT16, FRACTION16, BIAS16) FPU3(
	.A(A[15:0]),
	.B(B[15:0]),
	.C(C16M)
);

fpua #(EXPONENT16, FRACTION16) FPU4(
	.A(A[15:0]),
	.B(B[15:0]),
	.addsub(1),
	.C(C16A)
);

fpua #(EXPONENT16, FRACTION16) FPU5(
	.A(A[15:0]),
	.B(B[15:0]),
	.addsub(0),
	.C(C16S)
);


// E4M3 float
parameter E4M3BIAS8 = 7;
parameter E4M3EXPONENT8 = 6;
parameter E4M3FRACTION8 = 2;
wire [E4M3EXPONENT8+1:0] E4M3C8M;
wire [E4M3EXPONENT8+1:0] E4M3C8A;
wire [E4M3EXPONENT8+1:0] E4M3C8S;

fpum #(E4M3EXPONENT8, E4M3FRACTION8, E4M3BIAS8) FPU6(
	.A(A),
	.B(B),
	.C(E4M3C8M)
);

fpua #(E4M3EXPONENT8, E4M3FRACTION8) FPU7(
	.A(A),
	.B(B),
	.addsub(1),
	.C(E4M3C8A)
);

fpua #(E4M3EXPONENT8, E4M3FRACTION8) FPU8(
	.A(A),
	.B(B),
	.addsub(0),
	.C(E4M3C8S)
);

// E5M2 float
parameter E5M2BIAS8 = 15;
parameter E5M2EXPONENT8 = 6;
parameter E5M2FRACTION8 = 1;
wire [E5M2EXPONENT8+1:0] E5M2C8M;
wire [E5M2EXPONENT8+1:0] E5M2C8A;
wire [E5M2EXPONENT8+1:0] E5M2C8S;

fpum #(E5M2EXPONENT8, E5M2FRACTION8, E5M2BIAS8) FPU9(
	.A(A),
	.B(B),
	.C(E5M2C8M)
);

fpua #(E5M2EXPONENT8, E5M2FRACTION8) FPU10(
	.A(A),
	.B(B),
	.addsub(1),
	.C(E5M2C8A)
);

fpua #(E5M2EXPONENT8, E5M2FRACTION8) FPU11(
	.A(A),
	.B(B),
	.addsub(0),
	.C(E5M2C8S)
);


// Utilities
bin32ToHex converter(
	.bin(C),
	.lower(SW[5]),
	.off(off),
	.size(SW[1:0]),
	.hexout({HEX5, HEX4, HEX3, HEX2, HEX1, HEX0}),
	.clk(MAX10_CLK1_50)
);

ramBlock RAM(
	.next(next),
	.reset(SW[9]),
	.A(A),
	.B(B),
	.clk(MAX10_CLK1_50)
);

//=======================================================
//  Structural coding
//=======================================================
	initial begin
		C = {32{1'b0}};
		state <= S1;
	end
	
	always @(posedge MAX10_CLK1_50) begin
		if (SW[9]) begin
			state <= S1;
			next <= 0;
		end
		case(state)
			S1: begin // Reset state
				off <= 1'b1;
				next <= 1'b0;
				if(~SW[9]) begin
					state <= S2;
				end
			end
			S2: begin // Load state
				if (SW[9]) begin
					state <= S1;
				end else begin
					if (SW[1:0] == 2'b00) begin // 32 bit
						if (SW[7:6] == 00) C = C32A; // 00 - ADD
						else if (SW[7:6] == 01) C = C32M; // 01 - MULTI
						else if (SW[7:6] == 'b10) C = C32S; // 10 - SUB
						$display("%b%b%b", A, B, C);
					end else if (SW[1:0] == 2'b01) begin // 16 bit
						if (SW[7:6] == 00) C = {{16{1'b0}}, C16A}; // 00 - ADD
						else if (SW[7:6] == 01) C = {{16{1'b0}}, C16M}; // 01 - MULTI
						else if (SW[7:6] == 'b10) C = {{16{1'b0}}, C16S}; // 10 - SUB
						$display("%b%b%b", A[15:0], B[15:0], C[15:0]);
					end else if (SW[1:0] == 2'b10) begin // E4M3
						if (SW[7:6] == 00) C = {{24{1'b0}}, E4M3C8A}; // 00 - ADD
						else if (SW[7:6] == 01) C = {{24{1'b0}}, E4M3C8M}; // 01 - MULTI
						else if (SW[7:6] == 'b10) C = {{24{1'b0}}, E4M3C8S}; // 10 - SUB
						$display("%b%b%b", A[7:0], B[7:0], C[7:0]);
					end else if (SW[1:0] == 2'b11) begin // E5M2
						if (SW[7:6] == 00) C = {{24{1'b0}}, E5M2C8A}; // 00 - ADD
						else if (SW[7:6] == 01) C = {{24{1'b0}}, E5M2C8M}; // 01 - MULTI
						else if (SW[7:6] == 'b10) C = {{24{1'b0}}, E5M2C8S}; // 10 - SUB
						$display("%b%b%b", A[7:0], B[7:0], C[7:0]);
					end
					next <= 1;
					state <= S3;
					timer_count <= 0;
					off <= 1'b0;
				end
			end
			S3: begin // Wait state
				timer_count = timer_count + 1;
				// Timer
				if (timer_count >= timer_limit) begin
					next <= 0;
					state <= S2;
				end
			end
		endcase
	end
endmodule