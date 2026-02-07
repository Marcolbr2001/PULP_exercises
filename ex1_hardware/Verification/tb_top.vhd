----------------------------------------------------------------------------------
-- Engineer: Marco La Barbera
-- 
-- Create Date: 05.02.2026 21:29:27
-- Module Name: tb_top - Behavioral
--
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- local project libraries --
library work;                  
use work.constant_pkg.all;
-----------------------------

entity tb_top is
--  Port ( );
end tb_top;


architecture Behavioral of tb_top is

component top is
Generic(
  DATA_WIDTH : integer := DATA_WIDTH;
  FIFO_DEPTH : integer := FIFO_DEPTH 
  );
  Port ( 
  clk : in std_logic;
  rst_n :in  std_logic;
  
   data_i : in std_logic_vector(DATA_WIDTH+1 downto 0);
   valid_i : in std_logic;
   grant_i: in std_logic;
    
   grant_o : out std_logic;
   data_o : out std_logic_vector(DATA_WIDTH+1 downto 0);
   valid_o : out std_logic
     
  );
end component;

signal    clk : std_logic:='0';
signal    rst_n : std_logic:='0';

signal    data_i :  std_logic_vector(DATA_WIDTH+1 downto 0):=(Others=>'0');
signal    valid_i :  std_logic:='0'; -- write enable (parity che invia segnale di ready alla fifo)
signal    grant_i:  std_logic:='0'; -- not full (che la fifo invia al parity)

signal    data_o :  std_logic_vector(DATA_WIDTH+1 downto 0):=(Others=>'0');
signal    valid_o:  std_logic; --not empty (fifo invia segnale al parity)
signal    grant_o:  std_logic:='0'; --read enable (parity che invia segnale di ready alla fifo)

signal pkg_received, pkg_sent, pkg_dropped : integer:=0;

begin

tb_top: top 
Generic map(
  DATA_WIDTH => DATA_WIDTH,
  FIFO_DEPTH => FIFO_DEPTH
  )
  Port map( 
  clk =>clk,
  rst_n =>rst_n,
  
   data_i =>data_i,
   valid_i =>valid_i,
   grant_i=>grant_i,
    
   grant_o =>grant_o,
   data_o =>data_o,
   valid_o =>valid_o
  );


clk<= not clk after 5ns;

-------- Grant in generator -------- 
grant_i_pr:process
begin
grant_i <= '0';
wait for 105ns;
grant_i <= '1';
wait for 50ns;
-- grant with 50% duty cycle
for i in 0 to 10 loop
    grant_i <= '1';
    wait for 50 ns;
    grant_i <= '0';
    wait for 50 ns;
end loop;

-- grant always high
grant_i <= '1';

wait;
end process;
------------------------------------

--------- Traffic Generator --------
 traffic_generator: process
 begin
 valid_i<='0';
 wait for 5ns;
 data_i<=std_logic_vector(to_unsigned(1,DATA_WIDTH+2));
 wait for 20 ns;
 rst_n<='1';
 valid_i<='1';

 -- Only writing, FIlling the entire FIFO
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(3,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(6,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(7,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(10,DATA_WIDTH+2));
 
 
 -- Only reading, emptying the entire FIFO
 wait for 10 ns;
 valid_i<='0';
 wait for 100ns;
 valid_i<='1';
 
 -- Random traffic
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(11,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(12,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(13,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(14,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(15,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(16,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(17,DATA_WIDTH+2));
 wait for 10 ns;
 data_i<=std_logic_vector(to_unsigned(18,DATA_WIDTH+2));
 wait;
 
 end process;
 ------------------------------------

 
 ------- checker ------- 
 checker: process(clk)
 begin
  
    if rising_edge(clk) then
        
            -- Package has been sent succesfully when valid_i and grant_o are '1'
            if valid_i = '1' and grant_o = '1' then
                pkg_sent <= pkg_sent + 1;
            end if;
            
            -- Package has been succesfully received by client when valid_o and grant_i are '1'
            if valid_o = '1' and grant_i = '1' then
                pkg_received <= pkg_received + 1;
            end if;
        end if;
 end process;
 
 pkg_dropped <= pkg_sent - pkg_received; -- This computes the all dropped packages
 ------------------------
end Behavioral;
