`default_nettype none

module PriorityEncoder_test;

    logic [3:0] request_vec;
    logic       error;
    logic [1:0] granted_idx;

    parameter W = 4;

    // Internal TB clock
    logic clock;
    int num_errors;

    PriorityEncoder #(.W(W)) priority_encoder (.*);


    // Clock
    initial begin
        clock = 1'b0;
        forever #5 clock = ~clock;
    end

    // Force Timeout
    initial begin
        #10000000000000;
        $display("%m @%0t: Testbench issued timeout", $time);
        $finish;
    end


    initial begin
        num_errors = 0;
        request_vec = '0;
        @(posedge clock)
        
        // First check out error case
        assert (error == '1) else begin
            $error("Error was not asserted for request vector of 0");
            num_errors += 1;
        end

        assert (granted_idx == '0) else begin
            $error("Granted index should be zero for invalid request vector");
            num_errors += 1;
        end

        // Second check out special case of request vector == 1
        @(posedge clock);
        request_vec = '0;
        request_vec[0] = 1'b1;
        @(posedge clock);
        assert (granted_idx == 1'b0) else begin
            $error("Expected index of %d for request vector %b, got %d instead", 1'b0, request_vec, granted_idx);
            num_errors += 1;
        end
        assert (error == '0) else begin
            $error("Error output should be deasserted for valid request vector %b", request_vec);
            num_errors += 1;
        end
        @(posedge clock);

        // Then check out all other cases
        for (int i = 1; i < W; i++) begin

            request_vec = '0;
            request_vec[i] = 1'b1;

            for (int j = 0; j < (1 << i); j++) begin

                @(posedge clock);
                request_vec = '0;
                request_vec = j;
                request_vec[i] = 1'b1;
                @(posedge clock);

                assert (granted_idx == i) else begin
                    $error("Expected index of %d for request vector %b, got %d instead", i, request_vec, granted_idx);
                    num_errors += 1;
                end
                assert (error == '0) else begin
                    $error("Error output should be deasserted for valid request vector %b", request_vec);
                    num_errors += 1;
                end
            end
        end

        // Print stats
        $display("Completed testbench with %d error(s)", num_errors);
        $finish; 
    end

endmodule: PriorityEncoder_test
