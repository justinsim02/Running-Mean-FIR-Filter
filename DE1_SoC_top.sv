/*
Justin Sim
2/28/2024
*/
module part3 (CLOCK_50, CLOCK2_50, KEY, FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, 
		        AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT, SW);

	input CLOCK_50, CLOCK2_50;
	input [0:0] KEY;
	input logic [9:0] SW;
	// I2C Audio/Video config interface
	output FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	// Audio CODEC
	output AUD_XCK;
	input AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	
	// Local wires.
	wire read_ready, write_ready, read, write;
	wire [23:0] readdata_left, readdata_right;
	wire [23:0] writedata_left, writedata_right;
	logic reset;
	/////////////////////////////////
	FIR_Running_Mean_Filter left (.CLOCK_50(CLOCK_50), .reset(reset),
											.read_ready(read_ready),
											.write_ready(write_ready),
											.dataIn(dataIn_L),
//											.read(read_L), .write(write_L),
											.dataOut(dataOut_L));
											
	FIR_Running_Mean_Filter right (.CLOCK_50(CLOCK_50), .reset(reset),
											.read_ready(read_ready),
											.write_ready(write_ready),
											.dataIn(dataIn_R),
//											.read(read_R), .write(write_R),
											.dataOut(dataOut_R));
	
// reset will output non-filtered stereo	
	assign dataIn_R = readdata_right;
	assign dataIn_L = readdata_left;
	
	always_comb begin
		case(SW[9])
			1'b0: begin
				writedata_left = readdata_left;
				writedata_right = readdata_right;
			end
			1'b1: begin
				writedata_left = dataOut_L;
				writedata_right = dataOut_R;
			end
		endcase
	end
	
	assign reset = ~KEY[0];
	assign read = read_ready && write_ready;
	assign write = write_ready && read_ready;
	/////////////////////////////////
//	
//	assign writedata_left = readdata_left;
//	assign writedata_right = readdata_right;
//	assign read = read_ready && write_ready;
//	assign write = write_ready && read_ready;
	
	
	

		
/////////////////////////////////////////////////////////////////////////////////
// Audio CODEC interface. 
//
// The interface consists of the following wires:
// read_ready, write_ready - CODEC ready for read/write operation 
// readdata_left, readdata_right - left and right channel data from the CODEC
// read - send data from the CODEC (both channels)
// writedata_left, writedata_right - left and right channel data to the CODEC
// write - send data to the CODEC (both channels)
// AUD_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio CODEC
// I2C_* - should connect to top-level entity I/O of the same name.
//         These signals go directly to the Audio/Video Config module
/////////////////////////////////////////////////////////////////////////////////
	clock_generator my_clock_gen(
		// inputs
		CLOCK2_50,
		reset,

		// outputs
		AUD_XCK
	);

	audio_and_video_config cfg(
		// Inputs
		CLOCK_50,
		reset,

		// Bidirectionals
		FPGA_I2C_SDAT,
		FPGA_I2C_SCLK
	);

	audio_codec codec(
		// Inputs
		CLOCK_50,
		reset,

		read,	write,
		writedata_left, writedata_right,

		AUD_ADCDAT,

		// Bidirectionals
		AUD_BCLK,
		AUD_ADCLRCK,
		AUD_DACLRCK,

		// Outputs
		read_ready, write_ready,
		readdata_left, readdata_right,
		AUD_DACDAT
	);

endmodule

