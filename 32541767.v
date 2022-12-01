// Name: Alexander Whitfield
// ID: 32541767

module assign2022(CLOCK_50, KEY, SW, LEDR, LEDG, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
	input CLOCK_50;
	input [3:0] KEY;
	input [17:0] SW;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	output [17:0] LEDR;
	output [7:0] LEDG;

	assign LEDG[3:0] = ~KEY[3:0]; 
	assign LEDR[17:0] = SW[17:0];

    // Part 1
    //This sets up hex displays 6 & 7 to display the last 2 digits of my ID (67)
    Hexdisplay ID1(.iBinary4bit(4'd6), .oHex(HEX7));
    Hexdisplay ID2(.iBinary4bit(4'd7), .oHex(HEX6));

    // Call Part 1
    MyPart1 q1(.iClk(CLOCK_50), .iRst(~KEY[0]), .iErrorCodes(SW[17:16]), .iEnableDisplay(SW[15]), .iFreezeDisplay(SW[14]), .oHEX0(HEX0), .oHEX1(HEX1), .oHEX2(HEX2), .oHEX3(HEX3));

    //Part 2
    // I have created a wire as in the OctNumbersGenerationDisplay outputs 6 bits for the oDualOctGenerated when it is run
    wire [5:0] generator;
    OctNumbersGenerationDisplay q2(.iClk(~KEY[1]), .iRst(~KEY[0]), .iBlankDisplay(1'b0), .iNewOctNumsReq(SW[0]), .iChooseRandID(SW[5]), .oDualOctGenerated(generator), .oHEXA(HEX5), .oHEXB(HEX4));

   //Part 3
    CognitionTimer q3(.iClk(CLOCK_50), .iRst(~KEY[0]), .iChooseRandID(SW[16]), .iUser4bitSW(SW[3:0]), .iSubmitSW(SW[17]), .oHEX0(HEX0), .oHEX1(HEX1), .oHEX2(HEX2), .oHEX3(HEX3), .oHEX4(HEX4), .oHEX5(HEX5), .oHEX6(HEX6), .oHEX7(HEX7));
   
endmodule


module MyPart1(iClk, iRst, iErrorCodes, iEnableDisplay, iFreezeDisplay, oHEX0, oHEX1, oHEX2, oHEX3);
    input iClk, iRst, iEnableDisplay, iFreezeDisplay;
    input [1:0] iErrorCodes;
    output [6:0] oHEX0, oHEX1, oHEX2, oHEX3;

    // I am creating a variable that allows the counter to stop at 16.7 seconds (last 2 digits of my ID is 67)
    // This happens when oTime_100msec16 reaches MAX_COUNT in the Timer module
    parameter MAX_COUNT = 8'd167;

    // This is what will actually reset the timer when oTime_100msec16 reaches the MAX_COUNT
    wire timer_reset;

    // This is the display time for DisplayTimerError
    // 16 bits
    wire [15:0] display_time;

    // When display_time is equal to MAX_COUNT the timer_reset will equal 1 and the timer will restart
    // Since I can't assign MAX_COUNT twice I need to assign everything in 1 line.
    assign timer_reset = (display_time == MAX_COUNT);

    Timer m1(.iClk(iClk), .iRst(iRst), .iRstCE(timer_reset), .oTime_100msec16(display_time));

    DisplayTimerError m2(.iClk(iClk), .iSWEntryError(iErrorCodes), .iEnable(iEnableDisplay), .iFreezeDisplayTimer(iFreezeDisplay), .iTimer_100msec(display_time), .oHEX0(oHEX0), .oHEX1(oHEX1), .oHEX2(oHEX2), .oHEX3(oHEX3));

endmodule


//**********************************************************************************************************
//   MODULE:  NextIDdualOctal
//   DESCRIPTION: Generates a 6 bit number based on a student ID number using multiplication by 11 and truncation.  
//              After iRst=1, and the first iNext=1 request, the first ID digit is used to generate the oIDdualOctal.
//              The next in the sequence is obtained when iNext=1 on a iClk 0->1 edge.
//              Refer to the assignment question for more information.
//**********************************************************************************************************
module NextIDdualOctal(iClk, iRst, iNext, oIDdualOctal);
    input iClk,         // System clock
          iNext,        // Next value to be produced on 0->1 clock edge when ClockEnable=1
          iRst;         // Resets to starting state.

    output reg [5:0] oIDdualOctal; // The student ID value being produced


    // Create a counter to go through my ID
    // 3 bit counter as that is what is required
    reg [2:0] counter;

    always@(*) begin
        case (counter)

            3'b000: oIDdualOctal <= 6'b100001;  //3 = 33 == 7'b0100001 == 6'b100001 == 4 & 1
            3'b001: oIDdualOctal <= 6'b010100;  //2 = 22 == 7'b0010100 == 6'b010100 == 2 & 4
            3'b010: oIDdualOctal <= 6'b110111;  //5 = 55 == 7'b0110111 == 6'b110111 == 6 & 7
            3'b011: oIDdualOctal <= 6'b101100;  //4 = 44 == 7'b0101100 == 6'b101100 == 5 & 4
            3'b100: oIDdualOctal <= 6'b001011;  //1 = 11 == 7'b0001011 == 6'b001011 == 1 & 3
            3'b101: oIDdualOctal <= 6'b001101;  //7 = 77 == 7'b1001101 == 6'b001101 == 1 & 5
            3'b110: oIDdualOctal <= 6'b000010;  //6 = 66 == 7'b1000010 == 6'b000010 == 0 & 2
            3'b111: oIDdualOctal <= 6'b001101;  //7 = 77 == 7'b1001101 == 6'b001101 == 1 & 5

            default: oIDdualOctal <= 6'b100001; //Setting a default
            // 4 & 1 will be on the display when the program is run

        endcase
    end

    // Setting up the clock to go through my ID number
    always@(posedge iClk) begin
        // If reset with iRst then start back at the first number on ID
        if (iRst)
            counter <= 3'b000; // 4 & 1 are displayed again

        // Cases for iNext
        else
            case (iNext)
            // If iNext is 0 then nothing happens and the counter remains the same
            0: counter <= counter;
            // If iNext == 1 & counter == 3'b111 then the counter must reset and we go back to 3'b000 (4 & 1)
            1: if (counter == 3'b111)
                counter <= 3'b000;
                // Although if iNext == 1 and the counter != 3b'111 then the counter will increase by 1 until reaching 3'b111
                else
                    counter <= counter + 1'b1;
            endcase
    end

endmodule
	
	
//**********************************************************************************************************
//   MODULE:  FSM
//   DESCRIPTION: Finite state machine to control the whole circuit.  Note this is a Moore FSM since the outputs
//                      are a combinational function of the state only (and not directly the inputs).  Inputs are used
//                      to determine the next state.  Some outputs are active for just one clock cycle.  All outputs
//                should be given a default value that is inactive so that states only specify active outputs.
//                The operation is summarised here but is described fully in the assignment notes.  
//                      1. Initially the display is blank for a fixed time.  
//                      2. New dual octal numbers are requested by the FSM and displayed, prompting the user
//                          to respond by setting appropriate switches in SW[3:0] and then changing the submit switch SW[17].
//                      3. The time from display to correct switches(Cognition delay) and change in submit switch is displayed
//                          in 100 milliseconds units using the iTimer16 input.
//                      4. If the user sets a switch incorrectly (error 1) or does not respond within 8 seconds (error 2)
//                          an error is displayed instead of the Cognition delay.
//                      5. Go back to step 1.
//**********************************************************************************************************
module FSM(iClk, iRst, iUser4bitSW, iSubmitSW, iTimer16, iDualOctGenerated, oResetTimer, oUser4bitNumError, oFreezeDisplayTimer, oBlankOctNumsDisplay, oShowTimerErrorDisplay, oNewOctNumsReq, oState);

    input iClk, iRst, iSubmitSW;  // iSubmitSW is the user operated submit switch - a change indicates new 4 bit number is available from user
    input [3:0] iUser4bitSW;    // 4 bit number on switches from the user
    input [15:0] iTimer16;          // time since oResetTimer becoming 0 in milliseconds
    input [5:0] iDualOctGenerated; // 4 bit number expected from user
    output reg  oResetTimer,                // zero timer value.
                oFreezeDisplayTimer,    // capture timer value for display if oShowTimerErrorDisplay=1.
                oBlankOctNumsDisplay,   // blank the octal numbers display.
                oNewOctNumsReq,         // a new 4 bit number will be generated on the next clock edge
                oShowTimerErrorDisplay; // Show the captured time or error
    output reg [1:0] oUser4bitNumError;     // 0 for no error, 1 wrong switch pressed, 2 timeout reached with no switches 1.

    output [3:0] oState;    // state available only for debugging.

    assign oState = state;

    // Use parameters for allocating sensible state names to state integers, eg RESET_STATE=0.  
    // The number state bits needs to be sufficient to store the largest state value.
    parameter RESET_STATE = 0, DUAL_OCT_STATE = 1, WAITING_SUBMIT = 2, CORRECT_SUBMIT = 3, ERROR1 = 4, ERROR2 = 5, RESET_TIMER = 6;
   
    reg [3:0] state, next_state;

    // This is will be set to make sure that the users input and the numbers that are generated are equal
    wire equal_input;

    // This is for the numbers that are generated
    wire [3:0] gen_numbers_sum;

    // Two 3-bit numbers are generated so gen_numbers_sum is the sum of both numbers generated by iDualOctGenerated
    assign gen_numbers_sum = iDualOctGenerated[5:3] + iDualOctGenerated[2:0];

    // This used to check that the sum of the numbers generated equals the users input
    assign equal_input = (gen_numbers_sum == iUser4bitSW);



    always@(state, iTimer16, iUser4bitSW, iDualOctGenerated, iSubmitSW) begin
        //default control actions are no action
            oFreezeDisplayTimer = 0;    // Capture timer value for display if oShowTimerErrorDisplay=1.
            oUser4bitNumError = 2'b0;   // Set to 0 as there are no errors to begin with
            oResetTimer = 0;            // Zero timer value.
            oBlankOctNumsDisplay = 1;   // Blank the octal numbers display.
            oNewOctNumsReq = 0;         // A new 4 bit number will be generated on the next clock edge
            oShowTimerErrorDisplay = 0; // Show the captured time or error
       
        case(state)
            RESET_STATE:
            // This state is where we wait 2 seconds, while this is happening all displays are blank
            // Then after the 2 seconds we move to the DUAL_OCT_STATE.
            // Is the reset button is pressed then the timer starts again from 0
                begin
                    // if iTimer16 == 2 second then go to DUAL_OCT_STATE
                    if (iTimer16 == 8'd20)
                        next_state = DUAL_OCT_STATE;

                    else
                        next_state = state;
                        oShowTimerErrorDisplay = 0;
                        oUser4bitNumError = 2'b0;
                end

            DUAL_OCT_STATE:
            // In this state the octal numbers are generated as oNewOctNumsReq is set to 1 and they are displayed on HEX4 & HEX5.
            // The timer is also reset as the time taken for the user to input there values starts in this state and move into the next state.
            // This state will always go to waiting state it us here is generate the octal numbers  
                begin
                    oBlankOctNumsDisplay = 0; // is this required like what does it really do
                    oNewOctNumsReq = 1;
                    oResetTimer = 1;
                    next_state = WAITING_SUBMIT;
                end

            WAITING_SUBMIT:
            // In this state the FSM is waiting for the user to input their value.
            // The HEX displays showing the octal numbers are the only displays on.
            // If the user takes longer than 8 seconds then the FSM will go state ERROR2.
            // If the user submits their value before 8 seconds and it is equal then we go to the CORRECT_SUBMIT state.
            // If the user submits their value before 8 seconds and it isn't equal then the FSM goes to the ERROR1 state.
            // If the reset button is pressed then the FSM goes back to the RESET_STATE and the displays go blank.
                begin
                    if (iTimer16 == 8'd80)
                        next_state = ERROR2;

                    else if (iSubmitSW == 1 & equal_input)
                        next_state = CORRECT_SUBMIT;

                    else if (iSubmitSW ==1 & !equal_input)
                        next_state = ERROR1;

                    else
                        next_state = state;
                        oBlankOctNumsDisplay = 0;
                end

            CORRECT_SUBMIT:
            // FSM only goes to this state if the user submits the CORRECT_SUBMIT input within 8 seconds of the numbers being shown.
            // If the user flips the submit switch then the FSM goes to the REST_TIMER state where the timer is reset.
            // If the user doesn't flip the submit switch then the HEX displays keep displaying the time taken to respond and
            // the octal numbers generated.
                begin
                    if (iSubmitSW == 0)
                        next_state = RESET_TIMER;

                    else
                        next_state = state;
                        oFreezeDisplayTimer = 1;
                        oBlankOctNumsDisplay = 0;
                        oShowTimerErrorDisplay = 1;
                end

            ERROR1:
            // The FSM will go to this state is the user submits the wrong value.
            // If the user flips the submit switch then the FSM goes to the REST_TIMER state where the timer is reset.
            // If the user doesn't flip the submit switch then the HEX displays 'error 1' and the octal numbers generated.
                begin
                    if (iSubmitSW == 0)
                        next_state = RESET_TIMER;

                    else
                        next_state = state;
                        oBlankOctNumsDisplay = 0;
                        oShowTimerErrorDisplay = 1;
                        oUser4bitNumError = 2'b1;
                        oResetTimer = 1;
                end

            ERROR2:
            // The FSM will go to this state is the user does not submit an answer.
            // If the user flips the submit switch then the FSM goes to the REST_TIMER state where the timer is reset.
            // If the user doesn't flip the submit switch then the HEX displays 'error 2' and the octal numbers generated.
                begin
                    if (iSubmitSW == 1)
                        next_state = RESET_TIMER;

                    else
                        next_state = state;
                        oBlankOctNumsDisplay = 0;
                        oShowTimerErrorDisplay = 1;
                        oUser4bitNumError = 2'd2;
                        oResetTimer = 1;
                end

            RESET_TIMER:
            // This state is used if the FSM want to reset and start from the beginning
            // It just resets the time and sets the next_state to go back to the RESET_STATE
                begin
                    oResetTimer = 1;
                    next_state = RESET_STATE;
                end
   
        endcase
    end

    always @(posedge iClk) begin  // Update state on iClk edge
        if (iRst) state <= RESET_STATE;
        else state <= next_state;
    end

endmodule