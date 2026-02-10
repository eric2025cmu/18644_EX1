EX1: Introduction to Yosys
Guanting Chen

Task #0: Installation

Completed HW0


Task #1: Yosys Synthesis
1. Hierarchy
This pass performs the initial elaboration of the SystemVerilog source. It resolves parameters and creates a hierarchical RTL netlist. At this stage, the design is still represented by high-level symbolic blocks. 
Diagram:

2. Proc
This is the Procedural-to-Structural transformation. Yosys always identifies blocks and maps them to hardware primitives. Combinational processes are converted into networks of multiplexers, and sequential processes (the always_ff blocks) are mapped to abstract DFFs with identified clock and asynchronous reset signals.
Diagram: 
3. Alumacc 
This pass performs Resource Extraction by identifying patterns that can be mapped to specialized arithmetic cells. Instead of generic gate logic, Yosys extracts max - min operation into a dedicated sub and your threshold checks into comparators. 
Diagram:
4. FSM
The FSM pass performs state-space analysis on the control logic. It identifies the state register and the associated transition arcs. The tool optimizes the state encoding to minimize the combinational logic required for the next-state decoder and to improve the timing slack of the control path.
Diagram:
5. ABC
This is the final Logic Synthesis and Technology Mapping phase. The design is optimized using AIG and mapped onto the specific target primitives. Here, 4-input Look-Up Tables (LUT4). The structures are now completely decomposed into a gate-level netlist optimized for FPGA resource utilization.
Diagram:

Task #2: Fun with For-Loops
Part A: Priority Encoder

Verification with PriorityEncoder_test.sv:
PriorityEncoder.sv:8: sorry: constant selects in always_* processes are not fully supported (the process will be sensitive to all bits in 'request_vec[3:0]').
PriorityEncoder.sv:9: sorry: constant selects in always_* processes are not fully supported (the process will be sensitive to all bits in 'request_vec[3:0]').
PriorityEncoder.sv:10: sorry: constant selects in always_* processes are not fully supported (the process will be sensitive to all bits in 'request_vec[3:0]').
PriorityEncoder.sv:11: sorry: constant selects in always_* processes are not fully supported (the process will be sensitive to all bits in 'request_vec[3:0]').
Completed testbench with           0 error(s)
PriorityEncoder_test.sv:90: $finish called at 315 (1s)
Part B: For-Loop Scaling



1. We assure you your new encoder remains synthesizable. Why do you think that is the case?
The for loop is synthesizable because the loop boundary is controlled by the parameter W, which is a constant evaluated at elaboration time. Since the number of iterations is fixed and known before synthesis, the tool can statically unroll the loop into a pure combinational logic netlist.
2. What do you think your encoder looks like when synthesized?
Synthetically, the encoder will be mapped to a structured chain of priority logic, likely consisting of cascaded 2-to-1 multiplexers or a gate-level arbiter tree. Each input bit acts as a select signal that determines whether to pass its own encoded index or the result from a lower-priority stage to the output.
3. What do you think would make a for-loop unsynthesizable?
A loop becomes unsynthesizable if it has dynamic or data-dependent bounds—for example, if the loop termination depends on an input signal value that changes during runtime. Additionally, including non-synthesizable behavioral constructs like timing delays, wait statements, or file I/O operations inside the loop would prevent it from being mapped to hardware.

Part C: For-Loops Synthesized
W Value
Number of Cells
4
6
8
21
16
62
32
161
128
919


Screenshot for W=128:

1: What trend do you observe? Does it scale linearly?
I observe a roughly linear scaling trend. As the input bit-width W increases, the total number of cells required for synthesis grows proportionally. As W doubles, the total number of cells nearly triples its value.
2: Why do you think the number of cells scales the way it does?
This happens because of how the for loop is turned into hardware. To handle each extra bit in the request vector, the synthesizer has to add more "check" logic to see if that bit is high and decide which index gets priority. Since each new bit requires its own set of gates to be added to the chain, the total number of cells grows at a linear rate.

Task #3: Hierarchy and Optimizations
Part A: Flattened vs Non-flattened

NUM_MULS
Mode
Runtime (s)
Total LUTs
Normalized LUTs
1
Non-flattened
0.23
769
769
1
Flattened
0.24
769
769
10
Non-flattened
0.25
7690
769
10
Flattened
1.02
7690
769
20
Non-flattened
0.25
15380
769
20
Flattened
2.30
15380
769
40
Non-flattened
0.26
30760
769
40
Flattened
5.15
30760
769
50
Non-flattened
0.27
38450
769
50
Flattened
6.59
38450
769


1. What does the trend look like in terms of runtime for the flattened vs non-flattened runs as quantity increases?

The non-flattened runtime remains constant because the tool synthesizes the module once and replicates it. On the other hand, the flattened runtime shows linear-to-exponential growth as quantity increases. The synthesis tool must process the entire design as a single gate-level netlist, increasing computational complexity.

2. What does the trend look like in terms of normalized LUT utilization for flattened vs non-flattened runs as quantity increases?
The normalized LUT utilization remains constant at 769 for both flattened and non-flattened. This indicates that total area scales linearly with the quantity of multipliers.

3. Write a clear explanation of why you think those two trends go the way they do.

For the runtime difference, non-flattened synthesis uses metadata and pointers for identical instances, saving the time, whereas flattening forces The synthesis tool must process the entire design as a single gate-level netlist, increasing computational complexity.

For utilization: Because each multiplier is independent, there are no cross-boundary optimization opportunities. Since they all process different inputs, there are no duplicates that the tool can combine. 


4. Speculate as to why the normalized LUT utilization is not always necessarily an integer value.
Normalized utilization is an average of total utilization over quantity. In designs, it is often a non-integer because some instances may have unused bits or ports that are optimized away.

Part B: Tricking the Optimizer

NUM_MULS
Mode
Runtime (s)
Total LUTs
Normalized LUTs
1
Non-flattened
0.24
769
769
1
Flattened
0.19
191
191
10
Non-flattened
0.24
7690
769
10
Flattened
0.32
1910
191
20
Non-flattened
0.27
15380
769
20
Flattened
0.55
3820
191
40
Non-flattened
0.26
30760
769
40
Flattened
1.15
7640
191
50
Non-flattened
0.26
38450
769
50
Flattened
1.57
9550
191


1. What do the new trends look like in terms of utilization for the flattened vs non-flattened modes?

In non-flattened mode, the normalized LUT utilization remains constant at 769 LUTs per instance. In flattened mode, the utilization is also constant but significantly lower at 191 LUTs per instance. While both scale linearly with quantity, the flattened mode is much more area-efficient.

2. How do the values compare to the previous section? Why do you think this is the case? 

The flattened utilization in Part B is approximately only a quarter of in Part A. This is because Part B uses bit-slicing that ties the upper bits of the 64-bit inputs to constant zero. Flattening allows the optimizer to perform Constant Propagation, whereas non-flattened mode forces the tool to synthesize a full multiplier because it doesn’t know that the external inputs are restricted.

3. Using what you’ve learned, give one advantage of each of the synthesis modes, as well as what scenarios you might want to use one vs the other.

Non-flattened:
Advantage: Significant reduction in synthesis runtime and memory usage for large designs.
Scenario: Ideal for the active development phase, where rapid iteration and frequent recompilation are necessary.
Flattened:
Advantage: Maximum area optimization and better timing closure by optimizing across module boundaries.
Scenario: Final production build, where the goal is to fit the design into the smallest possible chip area or meet strict performance targets.


4. Let’s say you were building an entire CPU for a laptop, like the Apple M1. Would you want to run your synthesis (and placement/routing) algorithms in flattened, or hierarchical (non-flattened) mode? Explain the reasoning for your answer.
