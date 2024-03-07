module FIR_Running_Mean_Filter(
    input logic CLOCK_50, reset, read_ready, write_ready, 
    input logic [23:0] dataIn,
    output logic [23:0] dataOut
);
    parameter N = 4; // Number of elements in the buffer

    bit push = 0, find_mean = 0; // Flags for buffer pushing and mean calculation
    logic [31:0] spit = 32'b0, mean = 32'b0; // Temporary variables for shifting and mean calculation
    logic [23:0] buffer [0:N-1] = '{default: 24'b0}; // Circular buffer for storing input data
    logic [23:0] shifted [0:N-1] = '{default: 24'b0}; // Temporary buffer for shifting

    enum {S0, S1} ps, ns; // State enumeration

    // Finite State Machine (FSM)
    always_ff @(posedge CLOCK_50) begin 
        case(ps)
            S0: if (read_ready) begin // Transition from S0 to S1 if read_ready is high
                    find_mean = 0;
                    push = 1;
                    ns = S1;
                end else begin
                    find_mean = 0;
                    push = 0;
                    ns = S0;
                end
            S1: if (write_ready) begin // Transition from S1 to S0 if write_ready is high
                    push = 0;
                    find_mean = 1;
                    ns = S0;
                end else begin
                    push = 0;
                    find_mean = 0;
                    ns = S1;
                end
        endcase
    end

    // DFF For FSM
    always_ff @(posedge CLOCK_50)
        if (reset) ps <= S0;
        else ps <= ns;

    // FIFO Behavior
    always_ff @(posedge CLOCK_50) begin
        if (push) begin
            spit <= buffer[0]; // Store the rightmost element of the buffer in 'spit'
            for (int i = N-1; i > 0; i--)
                buffer[i] <= buffer[i-1]; // Shift each element of the buffer to the right
            buffer[0] <= dataIn; // Store the new input data in the leftmost address of the buffer
            $display("Shift occurred");
        end
    end

    // Find Mean DFF
    always_ff @(posedge CLOCK_50)
        if (find_mean) begin
            mean = 0; // Reset mean to 0 before summing
            $display("Mean found");
            for (int n = 0; n < N; n++) begin
                mean = mean + buffer[n]; // Sum all the values in the buffer
            end
        end else
            mean = mean;

    // Calculate the output data by dividing the summed signals by N
    assign dataOut = (mean >> $clog2(N));

endmodule

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

module FIR_Running_Mean_Filter_tb();
    logic CLOCK_50, reset, read_ready, write_ready; 
    logic [23:0] dataIn;
//    logic read, write;
    logic [23:0] dataOut;
    
    FIR_Running_Mean_Filter dut(.*); // Instantiate the DUT (Design Under Test)

    // Initialize Clock
    initial begin
        CLOCK_50 <= 0;
        forever #(50) CLOCK_50 <= ~CLOCK_50; // Toggle clock every 50 time units
    end

    // Full Reset Sequence
    task fullrst; begin
        reset <= 1; @(posedge CLOCK_50);
        reset <= 0; @(posedge CLOCK_50); 
    end endtask

    // Clock Tick
    task tick; begin @(posedge CLOCK_50); end endtask

    // Wait for 10 clock cycles
    task tickten; begin
        repeat(10) @(posedge CLOCK_50); 
    end endtask

    // Send Test Vector DataIn
    task trythis; input [23:0] data; begin
        dataIn <= data; tick;
        read_ready <= 1; tick; read_ready <= 0;
        write_ready <= 1; tick; write_ready <= 0;
        tick;
        tick;
    end endtask

    // Send Testbench Vectors
    initial begin
        fullrst; // Perform full reset
        trythis(100);
        trythis(200);
        trythis(300);
        trythis(400);
        trythis(0);
        $stop; // Stop simulation
    end

endmodule
