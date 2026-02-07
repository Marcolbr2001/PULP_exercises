----------------------------------------------------------------------------------
-- Engineer: Marco La Barbera
-- 
-- Create Date: 04.02.2026 21:47:13
-- Module Name: parity_checker - Behavioral
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

entity parity_checker is
  Generic(
    DATA_WIDTH : integer := DATA_WIDTH;
    PARITY_TYPE : string := PARITY_TYPE
  );
  Port (
    
    pop_data_o : in std_logic_vector(DATA_WIDTH+1 downto 0); -- Input Data to be checked
    
    pop_valid_o : in std_logic; -- Valid input
    pop_grant_i: out std_logic; -- Read Enable computed by this module
    grant_i : in std_logic;     -- Read enable from client
    valid_o : out std_logic     -- valid output
    
  
   );
end parity_checker;

architecture Behavioral of parity_checker is

signal error : std_logic := '0'; -- Parity error signal
signal tmp : std_logic_vector(pop_data_o'length-1 downto 0); -- temp XOR chain signal

begin

-- XOR chain --
tmp(0) <= pop_data_o(0);

gen: for i in 1 to pop_data_o'length-1 generate
    tmp(i) <= tmp(i-1) xor pop_data_o(i);
end generate;
----------------

error <= tmp(pop_data_o'length-1) when PARITY_TYPE = "EVEN" else    -- when PARITY_TYPE is set to EVEN, a valid packet is stated by error = 0
             not tmp(pop_data_o'length-1);                          -- when PARITY_TYPE is set to ODD, a valid packet is stated by error = 1  

valid_o <= pop_valid_o when error = '0' else '0'; -- Data valid is directly connected to FIFO valid signal if there is no parity error, 
                                                  -- Data is not valid if there is a parity error

pop_grant_i <= grant_i when error = '0' else '1'; -- Read Enable is directly connected to client read enable if there is no error, 
                                                  -- if instead there is error, Read Enable is high in order to drop non-valid data (oppure usare pop_valid_o)

end Behavioral;
