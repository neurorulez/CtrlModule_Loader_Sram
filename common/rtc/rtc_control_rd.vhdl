LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY rtc_control IS
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
	 tecla     : IN     STD_LOGIC;                    --active low reset
	 led       : OUT    STD_LOGIC;                    --active low reset
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
 signal sda_rd,sda_wr,scl_rd,scl_wr : STD_LOGIC; 
 
 begin

rtc_read : entity work.read
port map(
    clk => clk,              
    reset => '1',      
    sda => sda,              
    scl => scl,  
	 do  => open,
	 data_s(6 downto 0)  => rtc(6 downto 0),   --Segundos (El Bit 7 no se usa)
	 data_m(6 downto 0)  => rtc(14 downto 8),  --Minutos (El Bit 7 no se usa)
	 data_h(5 downto 0)  => rtc(21 downto 16), --Horas (Eñ bit 7 no se usa y 3l 6 indica si es modo 24 o 12)
	 data_dt(5 downto 0) => rtc(29 downto 24), --Dias (Bits 7 y 6 no se usan)
	 data_n(4 downto 0)  => rtc(36 downto 32), --Mes (Bits 7, 6 y 5 no se usan)
	 data_y(7 downto 0)  => rtc(47 downto 40),
	 data_d(2 downto 0)  => rtc(50 downto 48),
    l1 => led
);

--rtc_write : entity work.write
--port map(
--    clk => clk,              
--    reset => tecla,      
--    sda => sda,              
--    scl => scl,            
--    l1 => led
--);
 
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



end rtl;