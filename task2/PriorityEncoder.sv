module PriorityEncoder #(parameter W = 4) (
    input  logic [W-1:0]          request_vec,
    output logic                  error,
    output logic [$clog2(W)-1:0]  granted_idx);

    always_comb begin
        error = 1'b1;
        granted_idx = '0; 

        for (int i = 0; i < W; i = i + 1) begin
            if (request_vec[i]) begin
                granted_idx = i[$clog2(W)-1:0];
                error = 1'b0;
            end
        end
    end

endmodule
