----------------------------------------------------------------------------------
-- Engineer: Marco La Barbera
-- 
-- Create Date: 04.02.2026 21:47:13
-- Module Name: top - Behavioral
-- Project Name: Fault Tolerances Project
--
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- local project libraries --
library work;                  
use work.constant_pkg.all;
-----------------------------

entity top is
Generic(
  DATA_WIDTH : integer := DATA_WIDTH;
  FIFO_DEPTH : integer := FIFO_DEPTH 
  );
  Port ( 
    clk : in std_logic;
    rst_n :in  std_logic;
    
    data_i : in std_logic_vector(DATA_WIDTH+1 downto 0);    -- Input Data
    valid_i : in std_logic;                                 -- Write Enable
    grant_i: in std_logic;                                  -- Read Enable
    
    grant_o : out std_logic;                                -- Not Full
    data_o : out std_logic_vector(DATA_WIDTH+1 downto 0);   -- Data Out
    valid_o : out std_logic                                 -- Data Out Valid
     
  );
end top;

architecture Behavioral of top is

component my_FIFO is
  Generic(
  DATA_WIDTH : integer := 8;
  FIFO_DEPTH : integer := 16 
  );
  Port (
    
    clk : in std_logic;
    rst_n :in  std_logic;
    
    -- write port
    push_data_i : in std_logic_vector(DATA_WIDTH+1 downto 0); -- Input data to FIFO
    push_valid_i : in std_logic; -- valid input (this signal is sent by the source, the data source is valid)
    push_grant_o: out std_logic; -- Not Full (FIFO informs source that it is not full, source can send data)

    -- read port
    pop_data_o : out std_logic_vector(DATA_WIDTH+1 downto 0); -- Output Data from FIFO
    pop_valid_o: out std_logic; -- Not Empty (FIFO informs client [parity] that it is not empty, so outputed data is valid)
    pop_grant_i: in std_logic   -- Read enable (Parity informs FIFO that it is ready to accept data)
    

   );
end component;

component parity_checker is
  Generic(
    DATA_WIDTH : integer := 8
  );
  Port (
    
    pop_data_o : in std_logic_vector(DATA_WIDTH+1 downto 0);
    
    pop_valid_o : in std_logic;
    pop_grant_i: out std_logic;
    grant_i : in std_logic;
    valid_o : out std_logic
    
  
   );
end component;

signal    pop_valid_o:  std_logic;      -- Not Empty Signal (FIFO informs client [parity] that it is not empty, so outputed data is valid)
signal    pop_grant_i:  std_logic:='0'; -- Read enable SIgnal (Parity informs FIFO that it is ready to accept data)

signal data_o_sign : std_logic_vector(DATA_WIDTH+1 downto 0); -- Data Out Signal

begin

FIFO: my_FIFO 
  Generic map(
  DATA_WIDTH =>DATA_WIDTH,
  FIFO_DEPTH =>FIFO_DEPTH
  )
  Port Map (
    
    clk =>clk,
    rst_n =>rst_n,
    
    -- write port
    push_data_i  =>data_i,
    push_valid_i =>valid_i, -- write enable (parity che invia segnale di ready alla fifo)
    push_grant_o=>grant_o, -- not full (che la fifo invia al parity)

    -- read port
    pop_data_o =>data_o_sign,
    pop_valid_o=>pop_valid_o, --not empty (fifo invia segnale al parity)
    pop_grant_i =>pop_grant_i --read enable (parity che invia segnale di ready alla fifo)
    
   );

PC: parity_checker 
  Generic map(
    DATA_WIDTH =>DATA_WIDTH
  )
  Port map(
    
    pop_data_o =>data_o_sign,
    
    pop_valid_o => pop_valid_o,
    pop_grant_i => pop_grant_i,
    grant_i => grant_i,
    valid_o => valid_o
   );
   
   data_o <= data_o_sign; -- COnnects FIFO data out to top data out
   
end Behavioral;
