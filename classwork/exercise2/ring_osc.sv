module ring_osc (
    input logic EN,       //enable signal as per diagram provided 
    output logic OUT      //output signal 
);

    wire n1, n2;          //intermediate wire connections as described in diagram

    //step 1: AND gate - establish connections
    //feed in EN and OUT and pass to n1 depending on input values 
    nand u1 (n1, EN, OUT);

    //step 2: 2 Inverters - establish connection from n1
    //takes in n1 and inverted val is stored in n2 wire 
    not #(5) u2 (n2, n1);  //inverter with delay of 5 time units - as per homework brief
    //takes connection from last inverter (n2) and output is stored in out 
    not #(5) u3 (OUT, n2); //inverter with delay of 5 time units - as per homework brief

endmodule
