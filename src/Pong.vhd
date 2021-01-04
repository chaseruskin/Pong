----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: Pong - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Pong is
    port(
        CLK, RESET_L : IN std_logic;
        READY_BTN : IN std_logic; --on-board button to serve the ball
        P1_UP, P1_DOWN, P2_UP, P2_DOWN : IN std_logic; --player control buttons
        A, B, C, D, E, F, G : OUT std_logic; --seven segment display outputs
        DIGIT_P1_1, DIGIT_P1_0, DIGIT_P2_1, DIGIT_P2_0 : OUT std_logic; --which digit to display
        led : OUT std_logic_vector(3 downto 0); --LEDs to show player input working
        R0, R1, R2, R3 : OUT std_logic; --VGA outputs
        G0, G1, G2, G3 : OUT std_logic;
        B0, B1, B2, B3 : OUT std_logic;
        H_SYNC, V_SYNC : OUT std_logic
    );
end Pong;

architecture arch of Pong is

    component Scoreboard is
        port(
            CLK : IN std_logic;
            P1_SCORE, P2_SCORE : IN std_logic_vector(3 downto 0); --stored in regular hex fashion
            SEG : OUT std_logic_vector(6 downto 0);
            DIGIT_P1_1, DIGIT_P1_0, DIGIT_P2_1, DIGIT_P2_0 : OUT std_logic
        );
    end component;
    
    component Datapath is
        port(
            CLK, RESET_L : IN std_logic;
            P1_INPUT, P2_INPUT : IN std_logic_vector(1 downto 0);
            IN_SERVE, IN_WAIT, IN_MOVE_P1, IN_MOVE_P2, IN_MOVE_BALL, IN_UPDATE_SCORE : IN std_logic;
            DONE, P1_BOUNCE, P2_BOUNCE : IN std_logic;
            POINT_SCORED : OUT std_logic;
            O_BALL_ADDR, O_P1_ADDR, O_P2_ADDR : OUT std_logic_vector(13 downto 0);
            O_P1_SCORE, O_P2_SCORE : OUT std_logic_vector(3 downto 0)
        );
    end component;
    
    component GraphicsCard is
        port(
        ADDRESS : IN std_logic_vector(13 downto 0);
        DIS_ENA : IN std_logic;
        P1_BOUNCE, P2_BOUNCE : OUT std_logic;
        BALL_ADDR, P1_ADDR, P2_ADDR : IN std_logic_vector(13 downto 0);
        R_BIT, G_BIT, B_BIT : OUT std_logic
        );
    end component;
    
    component FSM is
        port(
            BEGIN_CYCLE, CLK, RESET_L : IN std_logic;  
            READY_BTN, POINT_SCORED : IN std_logic;
            DONE : OUT std_logic;
            IN_SERVE, IN_WAIT, IN_MOVE_P1, IN_MOVE_P2, IN_MOVE_BALL, IN_UPDATE_SCORE : OUT std_logic
        );
    end component;
    
    component ControllerVGA is
        port(
            PIXEL_CLK : IN std_logic;
            ADDRESS : OUT std_logic_vector(13 downto 0);
            R_BIT, G_BIT, B_BIT : IN std_logic;
            DISPLAY_VIEW : OUT std_logic;
            H_COUNTER : OUT std_logic_vector(7 downto 0);
            V_COUNTER : OUT std_logic_vector(9 downto 0);
            R0, R1, R2, R3 : OUT std_logic;
            G0, G1, G2, G3 : OUT std_logic;
            B0, B1, B2, B3 : OUT std_logic;
            H_SYNC, V_SYNC : OUT std_logic
        );
    end component;
    
    component ClockDivider is
    port(
        CLK : IN std_logic;
        MAX_COUNT : IN std_logic_vector(7 downto 0);
        SLOW_CLK : OUT std_logic
    );
    end component;
    
    constant vga_delay : std_logic_vector(7 downto 0) := "00011001"; --25 (125M/25 = 5MHz)
    constant sb_delay : std_logic_vector(7 downto 0) := "11111010"; --250 (125M/250 = 500kHz)
    signal vga_clk, score_clk : std_logic;
    signal w_r_bit, w_g_bit, w_b_bit : std_logic;
    signal g_address : std_logic_vector(13 downto 0);
    signal display_enabled, process_enabled : std_logic;
    
    signal h_count : std_logic_vector(7 downto 0);
    signal v_count : std_logic_vector(9 downto 0);
    
    signal seg_display : std_logic_vector(6 downto 0);
    
    signal w_ball_addr, w_p1_addr, w_p2_addr : std_logic_vector(13 downto 0);
    signal w_p1_score, w_p2_score : std_logic_vector(3 downto 0);
    signal w_in_wait, w_in_serve, w_in_move_p1, w_in_move_p2, w_in_move_ball, w_in_update_score, w_done, w_point_scored : std_logic;
    signal w_p1_bounce, w_p2_bounce : std_logic;
    
    signal p1_move, p2_move : std_logic_vector(1 downto 0);
    
begin
    --flip incoming bits from player's buttons because configured in pull-up format
    p1_move <= not P1_UP & not P1_DOWN;
    p2_move <= not P2_UP & not P2_DOWN;
    
    --FSM transitions between states required for the game to operate
    uFSM : FSM port map(BEGIN_CYCLE=>process_enabled, --begin the transitions when not displaying (only when processing)
                        CLK=>v_count(0), --CLK tied to LSB of VGA's vertical counter
                        RESET_L=>RESET_L,
                        READY_BTN=>READY_BTN,
                        DONE=>w_done,
                        IN_WAIT=>w_in_wait,
                        IN_SERVE=>w_in_serve,
                        IN_MOVE_P1=>w_in_move_p1,
                        POINT_SCORED=>w_point_scored,
                        IN_MOVE_P2=>w_in_move_p2,
                        IN_MOVE_BALL=>w_in_move_ball,
                        IN_UPDATE_SCORE=>w_in_update_score);
    
    --Datapath performs all game-related computations and stores important game values in registers
    uDP : Datapath port map(CLK=>v_count(0), --CLK tied to LSB of VGA's vertical counter
                            RESET_L=>RESET_L,
                            DONE=>w_done,
                            IN_WAIT=>w_in_wait,
                            IN_SERVE=>w_in_serve,
                            IN_UPDATE_SCORE=>w_in_update_score,
                            IN_MOVE_P1=>w_in_move_p1,
                            IN_MOVE_P2=>w_in_move_p2,
                            IN_MOVE_BALL=>w_in_move_ball,
                            P1_INPUT=>p1_move,
                            P2_INPUT=>p2_move,
                            P1_BOUNCE=>w_p1_bounce,
                            P2_BOUNCE=>w_p2_bounce,
                            POINT_SCORED=>w_point_scored, --send to FSM to indicate if need to transition to update score
                            O_BALL_ADDR=>w_ball_addr,
                            O_P1_ADDR=>w_p1_addr,
                            O_P2_ADDR=>w_p2_addr,
                            O_P1_SCORE=>w_p1_score,
                            O_P2_SCORE=>w_p2_score);
                            
    --GraphicsCard determines which bits to appear ON on the monitor and send valuable collision information to Datapath
    uGC : GraphicsCard port map(ADDRESS=>g_address,
                                DIS_ENA=>display_enabled,
                                BALL_ADDR=>w_ball_addr, --obtain address of where the ball is (stored in register in Datapath)
                                P1_ADDR=>w_p1_addr, --obtain address of where the paddle 1 is (stored in register in Datapath)
                                P2_ADDR=>w_p2_addr, --obtain address of where the paddle 2 is (stored in register in Datapath)
                                P1_BOUNCE=>w_p1_bounce, --send to Datapath to communicate if a collision occurred
                                P2_BOUNCE=>w_p2_bounce, --send to Datapath to communicate if a collision occurred
                                R_BIT=>w_r_bit,
                                G_BIT=>w_g_bit,
                                B_BIT=>w_b_bit);
    
    --inputs both scores and outputs which digit to display between the four seven segment components
    uSB : Scoreboard port map(CLK=>score_clk,
                              P1_SCORE=>w_p1_score,
                              P2_SCORE=>w_p2_score,
                              SEG=>seg_display, --the seven segment signals to currently output
                              DIGIT_P1_1=>DIGIT_P1_1,
                              DIGIT_P1_0=>DIGIT_P1_0,
                              DIGIT_P2_1=>DIGIT_P2_1,
                              DIGIT_P2_0=>DIGIT_P2_0);  
    
    --slower clock to generate proper standard for VGA timing
    uVGACD : ClockDivider port map(CLK=>CLK, 
                                   MAX_COUNT=>vga_delay, 
                                   SLOW_CLK=>vga_clk);
    
    --slower clock used for alternating the seven segment signals for each digit
    uSBCD : ClockDivider port map(CLK=>CLK,
                                  MAX_COUNT=>sb_delay,
                                  SLOW_CLK=>score_clk);                                   
    
    --VGA controller to output signals to a monitor
    uCVGA : ControllerVGA port map(PIXEL_CLK=>vga_clk,
                                   R_BIT=>w_r_bit,
                                   G_BIT=>w_g_bit,
                                   B_BIT=>w_b_bit,
                                   ADDRESS=>g_address,
                                   DISPLAY_VIEW=>display_enabled,
                                   H_COUNTER=>h_count,
                                   V_COUNTER=>v_count,
                                   R0=>R0, R1=>R1, R2=>R2, R3=>R3, 
                                   G0=>G0, G1=>G1, G2=>G2, G3=>G3, 
                                   B0=>B0, B1=>B1, B2=>B2, B3=>B3,
                                   H_SYNC=>H_SYNC, V_SYNC=>V_SYNC);
                                   
    process_enabled <= not display_enabled; --process is enabled ('1') when display is no longer enabled

    --output the signals for the seven segment
    A <= seg_display(6);
    B <= seg_display(5);
    C <= seg_display(4);
    D <= seg_display(3);
    E <= seg_display(2);
    F <= seg_display(1);
    G <= seg_display(0);
    
    --configure LEDs to the player inputs
    led(3) <= P1_UP;
    led(2) <= P1_DOWN;
    led(1) <= P2_UP;
    led(0) <= P2_DOWN;

end architecture;
