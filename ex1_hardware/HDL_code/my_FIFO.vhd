----------------------------------------------------------------------------------
-- Engineer: Marco La Barbera
-- 
-- Create Date: 04.02.2026 21:47:13
-- Module Name: my_FIFO - Behavioral
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

entity my_FIFO is
  Generic(
  DATA_WIDTH : integer := DATA_WIDTH;
  FIFO_DEPTH : integer := FIFO_DEPTH 
  );
  Port (
    
    clk : in std_logic;
    rst_n :in  std_logic;
    
    -- write port --
    push_data_i : in std_logic_vector(DATA_WIDTH+1 downto 0); -- Input Data
    push_valid_i : in std_logic; -- Valid input (this signal is sent by the source, the data source is valid)
    push_grant_o: out std_logic; -- Not full (FIFO informs source that it is not full, source can send data)
    
    -- read port --
    pop_data_o : out std_logic_vector(DATA_WIDTH+1 downto 0); -- Output Data
    pop_valid_o: out std_logic; -- Not Empty (FIFO informs client [parity] that it is not empty, so outputed data is valid)
    pop_grant_i: in std_logic   -- Read enable (Parity informs FIFO that it is ready to accept data)
    ---------------

   );
end my_FIFO;

architecture Behavioral of my_FIFO is

----- FSM write ----- 
type write_state is (IDLE, WRITE, FULL);
signal current_state_wr, next_state_wr :  write_state := IDLE;
---------------------

----- FSM read ------ 
type read_state is (IDLE, READ, EMPTY);
signal current_state_rd, next_state_rd :  read_state := IDLE;
---------------------

---- FIFO signal ----
type fifo_data_type is array(0 to FIFO_DEPTH-1) of std_logic_vector(push_data_i'range);
signal fifo_data : fifo_data_type := (others => (others => '0'));

signal fifo_count : integer range 0 to FIFO_DEPTH := 0;     -- Keeps track how many data stored into fifo
signal write_index  : integer range 0 to FIFO_DEPTH-1 := 0; -- Keeps track of write position
signal read_index   : integer range 0 to FIFO_DEPTH-1 := 0; -- Keeps track of read position
---------------------

signal push_grant_o_int : std_logic;    -- Not Full internal Signal
signal pop_valid_o_int : std_logic;     -- Not Empty internal SIgnal    


begin

---- FIFO manager process ----
fifo_indexes : process(rst_n, clk) is
		variable is_writing	: std_logic;
		variable is_reading	: std_logic;
begin

       if rst_n = '0' then
       				
       		fifo_count     <= 0;
       		write_index    <= 0;
       		read_index     <= 0;

       elsif rising_edge(clk) then
       
            -- These variables are usefull to save clarity inside the code
            is_writing	:= push_valid_i and push_grant_o_int;
            is_reading	:= pop_grant_i and pop_valid_o_int;
       
            -- Keeps track of the total number of the words inside the FIFO
            if is_writing = '1' and is_reading = '0' then
                fifo_count <= fifo_count + 1;
            elsif is_writing = '0' and is_reading = '1' then
                fifo_count <= fifo_count - 1;
            elsif is_writing = '1' and is_reading = '1' then
                fifo_count <= fifo_count;
            end if;
            
            -- Keeps track of the write index (and controls roll-over)
            if is_writing = '1' then
                fifo_data(write_index) <=push_data_i;
                if write_index = FIFO_DEPTH-1 then
                    write_index <= 0;
                else
                    write_index <= write_index + 1;
                end if;
            end if;

            -- Keeps track of the read index (and controls roll-over)
            if is_reading = '1' then
                if read_index = FIFO_DEPTH-1 then
                    read_index <= 0;
                else
                    read_index <= read_index + 1;
                end if;
            end if;
       
       end if;
       
end process;
------------------------------

------- FIFO write FSM -------
FSM_write: process(rst_n, clk)
begin

    if rst_n = '0' then 
        
            current_state_wr <= IDLE;
            
    elsif rising_edge(clk) then
    
        case(current_state_wr) is
        
        when IDLE =>
        
            if push_valid_i = '1' then -- If the inut signal is valid, prepare to write it inside the FIFO
            
               current_state_wr <= WRITE;

            end if;
               
        when WRITE =>
        
            if push_valid_i = '0' then -- If the input signal is no more valid, don't go to WRITE state
            
               current_state_wr <= IDLE;
               
            elsif fifo_count = FIFO_DEPTH-1 then -- If the counter is saturated, inform source that FIFO is cannot accept more data
            
               current_state_wr <= FULL;

            else
            
               current_state_wr <= WRITE;   -- If FIFO is not Full, it is possible to continue writing into it

            end if;
        
        when FULL =>
            
            if fifo_count = FIFO_DEPTH then -- If the FIFO is still full, remain in FULL state
            
               current_state_wr <= FULL;
               
            elsif push_valid_i = '0' then -- If the FIFO is not full, but data is not valid, go to IDLE state
            
               current_state_wr <= IDLE;
               
            elsif  push_valid_i = '1' then -- If the FIFO is not full, and data is valid, go to WRITE state
            
               current_state_wr <= WRITE;

            end if;
            
        end case;
        
    end if;
end process;
------------------------------


------- FIFO read FSM --------
FSM_read: process(rst_n, clk)
begin

    if rst_n = '0' then 
        
            current_state_rd <= IDLE;
            
    elsif rising_edge(clk) then
    
        case(current_state_rd) is
        
        when IDLE =>
        
            if pop_grant_i = '1' then -- If the receiver is ready to accept data, it is possible to go to READ state
            
               current_state_rd <= READ;

            end if;
               
        when READ =>
        
            if pop_grant_i = '0' then -- If there are no more read requests, go back to IDLE state
            
               current_state_rd <= IDLE;
               
            elsif fifo_count = 1 then -- If the FIFO is empty, inform receiver FIFO has no data to output
            
               current_state_rd <= EMPTY;

            else
            
               current_state_rd <= READ; -- If there are read request, and FIFO is not empty, continue reading
                
            end if;
        
        when EMPTY=> 
            
            if fifo_count = 0 then -- If the FIFO is still empty, remain in EMPTY state
            
               current_state_rd <= EMPTY;
               
            elsif pop_grant_i = '0' then -- If the FIFO is no more empty but there are no read request, go to IDLE state
            
               current_state_rd <= IDLE;
               
            elsif  pop_grant_i = '1' then -- If the FIFO is not empty and there is a read request, go to READ state
            
               current_state_rd <= READ;

            end if;
            
        end case;
        
    end if;
  
end process;
------------------------------

pop_data_o  <=  fifo_data(read_index); -- FIFO keeps in output always its last data, wheter is valid or not

push_grant_o_int    <= '0' when current_state_wr = FULL else '1';   -- Accept data only if FIFO is not in FULL state 
pop_valid_o_int     <= '0' when current_state_rd = EMPTY else '1';  -- Output data are valid only if FIFO is not empty

push_grant_o    <= push_grant_o_int;
pop_valid_o     <= pop_valid_o_int;

end Behavioral;
