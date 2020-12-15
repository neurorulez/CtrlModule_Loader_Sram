LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY rtc_control IS
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
	 tecla     : IN     STD_LOGIC;                    --active low reset
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC;                    --serial clock output of i2c bus
	 rtc       : OUT    STD_LOGIC_VECTOR(63 DOWNTO 0) --DAto del RTC Para el amiga
  );
END rtc_control;

architecture RTL of rtc_control is

 signal   i2c_ena       : STD_LOGIC;                    --latch in command
 signal   i2c_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
 signal   i2c_rw        : STD_LOGIC;                    --'0' is write, '1' is read
 signal   i2c_data_wr   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
 signal   i2c_busy      : STD_LOGIC;                    --indicates transaction in progress
 signal   i2c_data_rd   : STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
 signal   i2c_ack_error : STD_LOGIC;                    --flag if improper acknowledge from slave
 
 signal   busy_prev : STD_LOGIC; 
 signal   busy_cnt : INTEGER;
 signal   contador  : STD_LOGIC_VECTOR(15 DOWNTO 0);
 signal   clk_i2c   : STD_LOGIC; 
 signal   leido     : STD_LOGIC; 
 signal   data_to_write_0 : STD_LOGIC_VECTOR(7 DOWNTO 0);
 signal   data_to_write_1 : STD_LOGIC_VECTOR(7 DOWNTO 0);
 signal   slave_addr      : STD_LOGIC_VECTOR(6 DOWNTO 0);
 type states is (home, get_data);
 signal state : states := home;

 
 begin


--	   uint8_t date[7]; //year,month,date,hour,min,sec,day
--		//iprintf("Sending time of day %u:%02u:%02u %u.%u.%u\n",
--		//  date[3], date[4], date[5], date[2], date[1], 1900 + date[0]);
--    //%u decimal integer unsigned
--		spi_uio_cmd_cont(UIO_SET_RTC);
--		spi8(bin2bcd(date[5])); // sec
--		spi8(bin2bcd(date[4])); // min
--		spi8(bin2bcd(date[3])); // hour
--		spi8(bin2bcd(date[2])); // date
--		spi8(bin2bcd(date[1])); // month
--		spi8(bin2bcd(date[0]-100)); // year
--		spi8(bin2bcd(date[6])-1); //day 1-7 -> 0-6
--		spi8(0x40); // flag
--
--unsigned char bin2bcd(unsigned char in) {
--  return 16*(in/10) + (in % 10);
--}
--
--unsigned char bcd2bin(unsigned char in) {
--  return 10*(in >> 4) + (in & 0x0f);
--}
--
--    8'h22: if (abyte_cnt < 9) rtc[(abyte_cnt-1)<<3 +:8] <= spi_byte_in;
--    Para abyte_cnt 1, seria 0111 osea de  7:0
--    Para abyte_cnt 2, seria 1111 osea de 15:8
--    y asi hasta el 8, 63:56
--That syntax is called an indexed part-select. 
--The first term is the bit offset and the second term is the width.
-- It allows you to specify a variable for the offset, but the width must be constant.
--
--rtc <= X"40" & X"00" & X"72" & X"01" & X"0F" & X"12" & X"12" & X"10"; --9/4/95 11:57
--rtc <= X"40" & X"BB" & X"BB" & X"BB" & X"BB" & X"BB" & X"BB" & X"BB";
--
--rtc <= X"4012345678901234";-- X"40" & X"01" & X"01" & X"01" & X"01" & X"01" & X"01" & X"01";

i2c : entity work.i2c_master
port map(
    clk => clk,              --system clock
    reset_n => reset_n,      --active low reset
    ena => i2c_ena,              --latch in command
    addr => i2c_addr,            --address of target slave
    rw => i2c_rw,                --'0' is write, '1' is read
    data_wr => i2c_data_wr,      --data to write to slave
    busy => i2c_busy,            --OUT --indicates transaction in progress
    data_rd => i2c_data_rd,      --data read from slave
    ack_error => i2c_ack_error,  --BUFFER --flag if improper acknowledge from slave
    sda => sda,              --serial data output of i2c bus
    scl => scl               --serial clock output of i2c bus
);


process(clk)
begin


data_to_write_0 <= X"12";
data_to_write_1 <= X"34";
slave_addr <= "101" & X"0";

CASE state IS
WHEN home =>
IF(leido = '1') then state <= get_data; END IF;
WHEN get_data => 
busy_prev <= i2c_busy;                              --state forconducting thistransaction                                                  --capture the value of the previous i2c busy signal
IF(busy_prev = '0'AND i2c_busy = '1') THEN  --i2c busy just went high
busy_cnt <= busy_cnt + 1;                    --counts the times busy has gone from low to high during transaction
END IF;
WHEN OTHERS => NULL;
END CASE;

CASE busy_cnt IS                             --busy_cnt keeps track of which command we are on
WHEN 0=>                                  --no command latched in yet
i2c_ena <= '1';                            --initiate the transaction
i2c_addr <= slave_addr;                    --set the address of the slave
i2c_rw <= '0';                             --command 1is a write
i2c_data_wr <= data_to_write_0;              --data to be written
WHEN 1=>                                  --1st busy high: command 1latched, okay to issue command 2
i2c_rw <= '1';                             --command 2is a read (addr stays the same)
WHEN 2=>                                  --2nd busy high: command 2latched, okay to issue command 3
i2c_rw <= '0';                             --command 3is a write
i2c_data_wr <= data_to_write_1;           --data to be written
IF(i2c_busy = '0') THEN                    --indicates data read in command 2is ready
rtc(15 DOWNTO 8) <= i2c_data_rd;          --retrieve data from command 2
END IF;
WHEN 3=>                                  --3rd busy high: command 3latched, okay to issue command 4
i2c_rw <= '1';                             --command 4is read (addr stays the same)
WHEN 4=>                                  --4th busy high: command 4latched, ready to stop
i2c_ena <= '0';                            --deassert enable to stop transaction after command 4
IF(i2c_busy = '0') THEN                    --indicates data read in command 4is ready
rtc(7 DOWNTO 0) <= i2c_data_rd;           --retrieve data from command 4
busy_cnt <= 0;                             --reset busy_cnt fornext transaction
state <= home;                             --transaction complete, go to next state in design
END IF;
WHEN OTHERS => NULL;
END CASE;
end process;


--process(clk,reset_n)
--begin
--	if rising_edge(clk) then
--		if contador =  "1111111111111111" or reset_n = '0' then
--			contador <= "0000000000000000";
--		else
--			contador  <= contador + '1';			
--		end if;
--	end if;
--end process;

--clk_i2c <= contador(1);

end rtl;