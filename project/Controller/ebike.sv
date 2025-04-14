module ebike (
    input clk,
    input rst_n,

    input tgglMd,   //from push button will cycle through the settings
    output [1:0] setting, //assist level setting. These bits drive LED'S on DE0 nano so rider can see chosen setting 

    output A2D_SS_n,    //Active low slave select to A2D SPI interface
    output A2D_SCLK,   //SPI bus clock (to A2D)
    output A2D_MOSI,  //Serial output data to SPI bus of A2D converter (Master Out Slave In)
    input A2D_MISO,     //Serial input data from SPI bus of A2D converter (Master In Slave Out)
    
    input hallGrn,hallYlw, hallBlu;     //Hall effect input from BLDC motor
    output highGrn, highYlw, highBlu, lowGrn, lowYlw, lowBlu; //Gate controls for power MOSFETs driving motor coils. “high” signals drive the upper FET to source current into coil, “low” signals drive the lower FET to sink current from coil.
   
    //interial sensor 
    output inertSS_n, //Active low slave select to inertial sensor SPI interface
    output inertSCLK, //SPI bus clock (to inertial sensor)
    output inertMOSI, //Serial output data to SPI bus of inertial sensor (Master Out Slave In)
    input intertMISO,

    //hall sensor signals (going to brushless)

    //output to A2D converter in DE0 Nano from A2D_intf 
    input cadence, //raw unfiltered cadence signal
    output TX //from telemetry module outouts info for optional display

);

  

    initial begin


        wire drv_mag; //connect this to brushless i think
        //PID instantiation
        PID PID(
            .clk(clk),
            .rst_n(rst_n),
            .error(/*not sure yet*/),
            .not_pedalling(/*not sure yet*/),
            .drv_mag(drv_mag)
        );


        wire PWM_synch;
        wire highGrn, lowGrn, highYlw, lowYlw, highBlu, lowBlu;
        wire [10:0] duty; 
        wire selBlu, selYlw, selGrn; //these are the 2 bit vectors that will be used to control the FET's in mtr_drv
        brushless brushless(
            .clk(clk),
            .rst_n(rst_n),
            .drv_mag(drv_mag),
            .hallGrn(/*not sure yet (comes from BLDC motor)*/),
            .hallYlw(/*not sure yet (comes from BLDC motor)*/),
            .hallBlu(/*not sure yet (comes from BLDC motor)*/),
            .brake_n(brake_n), //this signal will come from A2D_intf?
            //look back at the mtr_drv and brishless connection exercise for this one
            .PWM_synch(PWM_synch), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .duty(duty), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selGrn(selGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selYlw(selYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selBlu(selBlu) //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
        );

        //mtr_drv instantiation
        mtr_drv mtr_drv(
            .clk(clk),
            .rst_n(rst_n),
            .duty(duty), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selGrn(selGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selYlw(selYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .selBlu(selBlu), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .PWM_synch(PWM_synch), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highGrn(highGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowGrn(lowGrn), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highYlw(highYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowYlw(lowYlw), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .highBlu(highBlu), //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
            .lowBlu(lowBlu) //this signal will come from the PWM module -> remember how mtr_drv and brushless connected to eachother
        );

        




    end



endmodule 
