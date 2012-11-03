/* Verilog for cell 'top{sch}' from library 'processor_sharing' */
/* Created on Thu Apr 05, 2012 21:57:53 */
/* Last revised on Wed May 09, 2012 21:21:52 */
/* Written on Wed May 09, 2012 21:26:06 by Electric VLSI Design System, version 9.00 */

module processor_sharing__buffer(clk, in, fillLevel, out);
  input clk;
  input [63:0] in;
  output [4:0] fillLevel;
  output [15:0] out;

  /* user-specified Verilog code */
  /*-------------
  * buffer
  *
  * every clock cycle, each 16bit section of input [15:0][31:16][47:32][63:48]
  * saves any non-zero data into the last slot and increments lastPtr
  *
  * then the output (a processor) is assigned the value of nextPtr
  * nextPtr is incremented and the fill level, measured by the difference between pointers,
  * is sent to the destinationController
  *-----------*/
  /**/ integer i;
  /**/ reg[15:0] mem[0:15];
  /**/ reg [4:0] fill;
  /**/ reg [15:0] out;
  /**/ reg [4:0] next;
  /**/ reg [4:0] last;
  /**/ assign fillLevel = fill;
  /**/  initial begin
  /**/    out = 0;
  /**/    next = 0;
  /**/    last = 0;
  /**/    fill = 0;
  //initialize memory to 0
  /**/    for(i=0; i<16; i= i+1) begin
  /**/      mem[i] = 0;
  /**/    end
  /**/  end
  /**
  /**/ always @(clk) begin
  /**/   //assume data can be queued in buffer almost simultaneously
  /**/#10 if(in[15:0] > 0) begin
  /**/     mem[last] = in[15:0];
  /**/     last = last + 1;
  /**/   end
  /**/   #1 if(in[31:16] > 0) begin
  /**/     mem[last] = in[31:16];
  /**/     last = last + 1;
  /**/   end
  /**/   #1 if(in[47:32] > 0) begin
  /**/     mem[last] = in[47:32];
  /**/     last = last + 1;
  /**/   end
  /**/   #1 if(in[63:48] > 0) begin
  /**/     mem[last] = in[63:48];
  /**/     last = last + 1;
  /**/   end
  /**/   //
  /**/   #10 if(mem[next] > 0) begin
  /**/     out = mem[next];
  /**/     mem[next] = 0;
  /**/     next = next +1;
  /**/   end
  /**/   else  out = 0; //NO INSTRUCTION OR DATA
  /**/ end
  /**/
  /**/ always begin
  /**/   #1 last = last%16;
  /**/   next = next%16;
  /**/   if(next > last) fill = last+16-next;
  /**/   else fill = last - next;
  /**/ end

endmodule   /* processor_sharing__buffer */

module processor_sharing__clk(out);
  output out;

  /* user-specified Verilog code */
  /*-------------
  * clk
  *     50% duty cycle
  *  clock generator.
  *--------------*/
  /**/      reg out;
  /**/      initial begin
  /**/          out = 0;
  /**/      end
  /**/      always begin
  /**/         #10 out = 1;
  /**/         #10 out = 0;
  /**/      end

endmodule   /* processor_sharing__clk */

module processor_sharing__destinationController(buffer0status, buffer1status, 
      out0, out1, out2, out3);
  input [4:0] buffer0status;
  input [4:0] buffer1status;
  output out0;
  output out1;
  output out2;
  output out3;

  wire net_32;

  /* user-specified Verilog code */
  /*-------------
  * destination controller
  *
  * compares the fill level of each buffer and
  * outputs the index of the least full buffer to each of the register gates
  * (only one of these gates will be enabled)
  *-----------*/
  /**/ reg leastFull;
  /**/ reg R0, R1, R2, R3;
  /**/ assign out0 = leastFull;
  /**/ assign out1 = leastFull;
  /**/ assign out2 = leastFull;
  /**/ assign out3 = leastFull;
  /**/ initial begin
  /**/   leastFull = 0;
  /**/   R0 = 0;
  /**/   R1 = 0;
  /**/   R2 = 1;
  /**/   R3 = 1;
  /**/ end
  /**/ always @(buffer0status or buffer1status) begin
  /**/   //find the least full buffer
  /**/   if(buffer0status > buffer1status) leastFull = 1'b1;
  /**/   else leastFull = 1'b0;
  /**/ end

endmodule   /* processor_sharing__destinationController */

module processor_sharing__loadController(clk, source0, source1, source2, 
      source3, heavy0, heavy1, heavy2, heavy3);
  input clk;
  input [15:0] source0;
  input [15:0] source1;
  input [15:0] source2;
  input [15:0] source3;
  output heavy0;
  output heavy1;
  output heavy2;
  output heavy3;

  wire net_52, net_56, net_60;

  /* user-specified Verilog code */
  /*-------------
  * load controller
  *
  * compares the load values of all sources and outputs that value as one of four sel wires
  *
  * every clock cycle, if the value is non-zero, increment the load value
  * otherwise, bitshift right
  *-----------*/
  /**/ reg[3:0] heaviestLoad;
  /**/ reg changed;
  /**/ reg [5:0] L0, L1, L2, L3; //max size 64? otherwise need logic for exceed size
  /**/ assign heavy0 = heaviestLoad[0];
  /**/ assign heavy1 = heaviestLoad[1];
  /**/ assign heavy2 = heaviestLoad[2];
  /**/ assign heavy3 = heaviestLoad[3];
  /**/ initial begin
  /**/   heaviestLoad = 4'b0000;
  /**/   changed = 0;
  /**/   L0 = 0;
  /**/   L1 = 0;
  /**/   L2 = 0;
  /**/   L3 = 0;
  /**/ end
  /**/ always @(clk) begin
  /**/   //on clk, increase non-zero source or bitshift right if NULL
  /**/   if(source0 > 0) L0 = L0+1;
  /**/   else L0 = L0 >> 1;
  /**/   if(source1 > 0) L1 = L1+1;
  /**/   else L1 = L1 >> 1;
  /**/   if(source2 > 0) L2 = L2+1;
  /**/   else L2 = L2 >> 1;
  /**/   if(source3 > 0) L3 = L3+1;
  /**/   else L3 = L3 >> 1;
  /**/   //calculate heaviest load
  /**/   if(L0 > L1) begin //L0 is bigger
  /**/     if(L2 > L3) begin //L2 is bigger than L3
  /**/       if(L0 > L2) heaviestLoad[3:0] = 4'b0001;
  /**/       else heaviestLoad = 4'b0100;
  /**/     end
  /**/     else begin //L3 is bigger than L2
  /**/       if(L0 > L3) heaviestLoad = 4'b0001;
  /**/       else heaviestLoad = 4'b1000;
  /**/     end
  /**/   end
  /**/   else begin //L1 is bigger
  /**/     if(L2 > L3) begin //L2 is bigger than L3
  /**/       if(L1 > L2) heaviestLoad = 4'b0010;
  /**/       else heaviestLoad = 4'b0100;
  /**/     end
  /**/     else begin //L3 is bigger than L2
  /**/       if(L1 > L3) heaviestLoad = 4'b0010;
  /**/       else heaviestLoad = 4'b1000;
  /**/     end
  /**/   end
  /**/ end

endmodule   /* processor_sharing__loadController */

module processor_sharing__regGate(en, in, out);
  input en;
  input in;
  output out;

  /* user-specified Verilog code */
  /*-------------
  * registerGate
  *
  * a simple gate to pass values from destinationController
  * to control switchers when enabled from loadController
  *-----------*/
  /**/ reg out;
  /**/ reg savedValue;
  /**/ initial begin
  /**/   savedValue = 0;
  /**/   out = 0;
  /**/  end
  /**/  always @(en) begin
  /**/    savedValue = in;
  /**/  end
  /**/ always begin
  /**/   #1 out = savedValue;
  /**/ end

endmodule   /* processor_sharing__regGate */

module processor_sharing__switcher(in, sel, out0, out1);
  input [15:0] in;
  input sel;
  output [15:0] out0;
  output [15:0] out1;

  /* user-specified Verilog code */
  /*-------------
  * switcher
  *
  * a demux that passes a 16bit signal to one of two buffers
  * it is controlled by a select switch linked to a destination register
  *--------------*/
  /**/ reg [15:0] out0;
  /**/ reg [15:0] out1;
  /**/ initial begin
  /**/    out0 = in;
  /**/    out1 = 16'h0000;
  /**/ end
  /**/ always begin
  //assume switching takes almost zero time
  #1 //$display("switcher: in[%h] sel[%b] 0[%h] 1[%h]",in,sel,out0,out1);
  /**/    case (sel)
  /**/        1'b0: begin
  /**/           out0 = in;
  /**/           out1 = 16'h0000;
  /**/        end
  /**/        1'b1: begin
  /**/           out0 = 16'h0000;
  /**/           out1 = in;
  /**/        end
  /**/        default: begin
  /**/           out0 = 16'h0000;
  /**/           out1 = 16'h0000;
  /**/        end
  /**/    endcase
  /**/ end

endmodule   /* processor_sharing__switcher */

module top();
  wire clk, net_168, net_171, net_174, net_191, net_192, net_227, net_229;
  wire net_257, net_260, net_265;
  wire [63:0] b0in;
  wire [63:0] b1in;
  wire [15:0] buffer_0_out;
  wire [15:0] buffer_1_out;
  wire [4:0] net_241;
  wire [4:0] net_246;
  wire [3:0] sel;
  wire [15:0] stream0;
  wire [15:0] stream1;
  wire [15:0] stream2;
  wire [15:0] stream3;

  /* user-specified Verilog code */
  /*-------------
  * 4x2 processor-sharing model
  *
  * This model was designed to explore the feasibility of creating a hardware design
  * to utilize multiple cores efficiently as part of Georgetown University's
  * COSC121 course taught by Richard Squier.
  * @author R. M. Keelan Downton rd328@georgetown.edu
  * @date 2012-05-09
  * @version 0.4
  *-------------/
  /**/ integer i;
  /**/ integer clkCount;
  /**/ reg[15:0] DATA0;
  /**/ reg[15:0] DATA1;
  /**/ reg[15:0] DATA2;
  /**/ reg[15:0] DATA3;
  /**/ assign stream0 = DATA0;
  /**/ assign stream1 = DATA1;
  /**/ assign stream2 = DATA2;
  /**/ assign stream3 = DATA3;
  /**/
  /**/ initial begin
  /**/   DATA0 = 16'h0000;
  /**/   DATA1 = 16'h0000;
  /**/   DATA2 = 16'h0000;
  /**/   DATA3 = 16'h0000;
  /**/   clkCount = 0;
  /**/  $display("\n\t\t===== STARTING SIMULATION =====\t\t\n");
  /**/  $display("This simulation demonstrates load sharing of four independent");
  /**/  $display("input streams between two processors in a balanced load");
  /**/  $display("using three arbitrary data patterns. Input is encoded for debugging:");
  /**/  $display("Top 4 bits indicate source {A,B,C,D} and lower 12 bits incidate clock cycle.");
  /**/ end
  /**/
  /**/ always @(clk) begin
  //------start dummy data------//
  /**/ if(clkCount < 5) begin //PATTERN 1
  /**/ $display("\n------------------- cycle [%h] pattern 1 -------------------",clkCount);
  /**/   DATA0 = 16'hA000 + clkCount;
  /**/   if(clkCount%5 == 0) DATA1 = 16'hB000 + clkCount;
  /**/   else DATA1 = 0;
  /**/   if(clkCount%2 == 0) DATA2 = 16'hC000 + clkCount;
  /**/   else DATA2 = 0;
  /**/   if(clkCount%3 == 0) DATA3 = 16'hD000 + clkCount;
  /**/   else DATA3 = 0;
  /**/ end
  /**/ else if(clkCount < 10) begin //PATTERN 2
  /**/ $display("\n------------------- cycle [%h] pattern 2 -------------------",clkCount);
  /**/   if(clkCount%3 == 0) DATA0 = 16'hA000 + clkCount;
  /**/   else DATA0 = 0;
  /**/   if(clkCount%5 == 0) DATA1 = 0;
  /**/   else DATA1 = 16'hB000 + clkCount;
  /**/   if(clkCount%2 == 0) DATA2 = 16'hC000 + clkCount;
  /**/   else DATA2 = 0;
  /**/   if((clkCount+1)%2 == 0) DATA3 = 16'hD000 + clkCount;
  /**/   else DATA3 = 0;
  /**/ end
  /**/ else if(clkCount > 9) begin //PATTERN 3
  /**/ $display("\n------------------- cycle [%h] pattern 3 -------------------",clkCount);
  /**/   if(clkCount%2 == 0) DATA0 = 16'hA000 + clkCount;
  /**/   else DATA0 = 0;
  /**/   DATA1 = 16'hB000 + clkCount;
  /**/   DATA2 = 16'hC000 + clkCount;
  /**/   if((clkCount+1)%2 == 0) DATA3 = 16'hD000 + clkCount;
  /**/   else DATA3 = 0;
  /**/ end
  //------end dummy data------//
  #10
  //----------show sources
  $display ("SA:[%H][L:%d] ==> BUFFER %b",stream0,loadControl.L0,regGate_0.out);
  $display ("SB:[%H][L:%d] ==> BUFFER %b",stream1,loadControl.L1,regGate_1.out);
  $display ("SC:[%H][L:%d] ==> BUFFER %b",stream2,loadControl.L2,regGate_2.out);
  $display ("SD:[%H][L:%d] ==> BUFFER %b",stream3,loadControl.L3,regGate_3.out);
  $display("BUFFER INPUTS: B0[%h][%h][%h][%h] B1[%h][%h][%h][%h]",buffer_0.in[15:0],buffer_0.in[31:16],buffer_0.in[47:32],buffer_0.in[63:48],buffer_1.in[15:0],buffer_1.in[31:16],buffer_1.in[47:32],buffer_1.in[63:48]);
  //----------show buffers
  /**/   $display("          --B0(%h)--\t--B1(%h)--",buffer_0.fill,buffer_1.fill);
  /**/   $display("          ptr %d->%d\tptr %d->%d",buffer_0.next,buffer_0.last,buffer_1.next,buffer_1.last);
  /**/   for(i=15; i>=0; i= i-1) $display("%d:[%h]\t[%h]",i,buffer_0.mem[i],buffer_1.mem[i]);
  /**/ #10 $display("*** PROC0 EXECUTES: %h\tPROC1 EXECUTES: %h *** ",buffer_0.out,buffer_1.out);
  //----------update clock
  /**/   clkCount = clkCount +1;
  /**/   if(clkCount > 20) $finish;
  /**/ end

  processor_sharing__buffer buffer_0(.clk(clk), .in(b0in[63:0]), 
      .fillLevel(net_241[4:0]), .out(buffer_0_out[15:0]));
  processor_sharing__buffer buffer_1(.clk(clk), .in(b1in[63:0]), 
      .fillLevel(net_246[4:0]), .out(buffer_1_out[15:0]));
  processor_sharing__clk clk_0(.out(clk));
  processor_sharing__destinationController 
      destControl(.buffer0status(net_241[4:0]), .buffer1status(net_246[4:0]), 
      .out0(net_168), .out1(net_171), .out2(net_265), .out3(net_174));
  processor_sharing__loadController loadControl(.clk(clk), 
      .source0(stream0[15:0]), .source1(stream1[15:0]), 
      .source2(stream2[15:0]), .source3(stream3[15:0]), .heavy0(sel[0]), 
      .heavy1(sel[1]), .heavy2(sel[2]), .heavy3(sel[3]));
  processor_sharing__regGate regGate_0(.en(sel[0]), .in(net_168), 
      .out(net_229));
  processor_sharing__regGate regGate_1(.en(sel[1]), .in(net_171), 
      .out(net_227));
  processor_sharing__regGate regGate_2(.en(sel[2]), .in(net_265), 
      .out(net_257));
  processor_sharing__regGate regGate_3(.en(sel[3]), .in(net_174), 
      .out(net_260));
  processor_sharing__switcher switcher_0(.in(stream0[15:0]), .sel(net_229), 
      .out0(b0in[15:0]), .out1(b1in[15:0]));
  processor_sharing__switcher switcher_1(.in(stream1[15:0]), .sel(net_227), 
      .out0(b0in[31:16]), .out1(b1in[31:16]));
  processor_sharing__switcher switcher_2(.in(stream2[15:0]), .sel(net_257), 
      .out0(b0in[47:32]), .out1(b1in[47:32]));
  processor_sharing__switcher switcher_3(.in(stream3[15:0]), .sel(net_260), 
      .out0(b0in[63:48]), .out1(b1in[63:48]));
endmodule   /* top */
