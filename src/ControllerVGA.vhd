----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: ControllerVGA - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--pin K17 of Xilinx Zybo Z7-10 is 125 MHz CLK

--VGA pixel CLK standard to be 40 MHz for 800x600 (using 5 MHz, 40/8 = 5, to generate 100x75 res)
entity ControllerVGA is
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
end entity;

architecture arch of ControllerVGA is
    
    component FlipFlop is
        port(
            CLK, RESET_L, D : IN std_logic;
            Q, Q_INV : OUT std_logic
        );
    end component;
    
    signal h_count, h_inv_bus : std_logic_vector(7 downto 0) := (others=>'0');
    signal v_count, v_inv_bus : std_logic_vector(9 downto 0) := (others=>'0');
    signal h_clear, v_clear : std_logic := '1';
    
    signal h_stage_bus, v_stage_bus : std_logic_vector(3 downto 0) := "1000";
    
    signal FRAME_CLK : std_logic := '0';
    
    signal red, blue, green : std_logic := '0';
    
begin

    H_COUNTER <= h_count;
    V_COUNTER <= v_count;
    
    --chop off last 3 bits of y location to show same pixel 8 times, same ratio as the slowed 5MHz clock is showing same pixel 8 times
    ADDRESS <= v_count(9 downto 3) & h_count(6 downto 0);
    
    --HORIZONTAL ASYNC COUNTER
    --8 bits required to count to 132
    uHSC0 : FlipFlop port map(CLK=>PIXEL_CLK, 
                              RESET_L=>h_clear, 
                              D=>h_inv_bus(0), 
                              Q=>h_count(0), 
                              Q_INV=>h_inv_bus(0));
    H_ASYNC_COUNTER : for i in 1 to 7 generate
        uHSCX : FlipFlop port map(CLK=>h_inv_bus(i-1), 
                                  RESET_L=>h_clear, 
                                  D=>h_inv_bus(i), 
                                  Q=>h_count(i), 
                                  Q_INV=>h_inv_bus(i));
    end generate H_ASYNC_COUNTER;
    
    h_clear <= '0' when (h_count = 132) else --reset at 132 (132*8 = 1056)
               '1';
               
    h_stage_bus  <= "0100" when (h_count = 100) else --set front porch at 100
                    "0010" when (h_count = 105) else --set sync pulse at 105
                    "0001" when (h_count = 121) else --set back porch at 121
                    "1000" when (h_count = 0); --set visible area at 0
                    
     H_SYNC <= not h_stage_bus(1); --horizontal sync pulse
         
     
     FRAME_CLK <= '1' when (h_count = 132) else --alternate frame clk when at 132 to trigger vertical counter
                  '0';
     
    --VERTICAL ASYNC COUNTER
    --10 bits required to count to 628
    uVSC0 : FlipFlop port map(CLK=>FRAME_CLK, 
                              RESET_L=>v_clear, 
                              D=>v_inv_bus(0), 
                              Q=>v_count(0), 
                              Q_INV=>v_inv_bus(0));
    V_ASYNC_COUNTER : for i in 1 to 9 generate
        uVSCX : FlipFlop port map(CLK=>v_inv_bus(i-1), 
                                  RESET_L=>v_clear, 
                                  D=>v_inv_bus(i), 
                                  Q=>v_count(i), 
                                  Q_INV=>v_inv_bus(i));
    end generate V_ASYNC_COUNTER;
    
     v_clear <= '0' when (v_count = 628) else --reset at 628
                '1';
               
     v_stage_bus <= "0100" when (v_count = 600) else --set front porch at 600
                    "0010" when (v_count = 601) else --set sync pulse at 601
                    "0001" when (v_count = 605) else --set back porch at 605
                    "1000" when (v_count = 0); --set visible area at 0
                    
    V_SYNC <= not v_stage_bus(1); --vertical sync counter
    
    red <= R_BIT when (h_count < 100 and v_count < 600) else
           '0';
    green <= G_BIT when (h_count < 100 and v_count < 600) else
             '0';
    blue <= B_BIT when (h_count < 100 and v_count < 600) else
            '0';
    
    DISPLAY_VIEW <= v_stage_bus(3); --signal display_view OFF when in blanking interval for vertical and horizontal...will signal for processing to occur
    
    R0 <= red;
    R1 <= red;
    R2 <= red;
    R3 <= red;
    
    G0 <= green;
    G1 <= green;
    G2 <= green;
    G3 <= green;
    
    B0 <= blue;
    B1 <= blue;
    B2 <= blue;
    B3 <= blue;
                  
end architecture;
