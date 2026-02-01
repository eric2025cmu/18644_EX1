`default_nettype none
`default_nettype none

module RangeFinder
   #(parameter WIDTH=16)
    (input  logic [WIDTH-1:0] data_in,
     input  logic             clock, reset,
     input  logic             go, finish,
     output logic [WIDTH-1:0] range,
     output logic             error);

// Put your code here
  typedef enum logic [1:0] {IDLE, RUN, ERROR} state_t;
  state_t state, next_state;

  logic [WIDTH-1:0] min_reg, max_reg;
  logic [WIDTH-1:0] next_min, next_max;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state   <= IDLE;
      min_reg <= '0;
      max_reg <= '0;
    end else begin
      state   <= next_state;
      min_reg <= next_min;
      max_reg <= next_max;
    end
  end

  always_comb begin
    next_state = state;
    next_min   = min_reg;
    next_max   = max_reg;
    error      = (state == ERROR);
    range      = max_reg - min_reg;

    case (state)
      IDLE: begin
        if (go && finish) begin
          next_state = ERROR;
        end else if (finish) begin
          next_state = ERROR;
        end else if (go) begin
          next_state = RUN;
          next_min   = data_in;
          next_max   = data_in;
        end
      end

      RUN: begin
        if (go) begin
          next_state = ERROR;
        end else begin
          if (data_in < min_reg) next_min = data_in;
          if (data_in > max_reg) next_max = data_in;
          if (finish) next_state = IDLE;
        end
      end

      ERROR: begin
        if (go && !finish) begin
          next_state = RUN;
          next_min   = data_in;
          next_max   = data_in;
        end
      end
      
      default: next_state = IDLE;
    endcase
  end

endmodule: RangeFinder
