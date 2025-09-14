LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

ENTITY top IS
	generic ( MEMwitdh : integer :=12);
	PORT(
		Mrst, Mclk					: IN 	STD_LOGIC; 
		addressBUS_out			: OUT 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
		PC_out						: OUT  STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
		ALU_result_out, read_data_1_out, read_data_2_out, writeback_data_out,	
     	Instruction_out	,Data_bus_out				: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Branch_out,Jump_out, 
		Memwrite_out,MemRead_out, Regwrite_out					: OUT 	STD_LOGIC ;
		wrenBUS_out					: OUT 	STD_LOGIC ;
		
			SWch_IN 					:IN STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			LEDR_out 					:OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0_out,HEX1_out 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2_out,HEX3_out 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4_out,HEX5_out 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 )
	  );
END top;


ARCHITECTURE top_arch OF top IS

COMPONENT PLL is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic        -- outclk0.clk
		);
	end COMPONENT;

 COMPONENT MIPS
    generic ( MEMwitdh : integer :=12);
   PORT (
      reset, clock    : IN     STD_LOGIC;
		Branch_out,JUMP_out : OUT    STD_LOGIC;
		Regwrite_out    : OUT    STD_LOGIC;
		Memwrite_out    : OUT    STD_LOGIC;
		Memread_out    : OUT    STD_LOGIC;
      PC              : OUT    STD_LOGIC_VECTOR ( MEMwitdh-1 DOWNTO 0 );
		ALU_result_out  : OUT    STD_LOGIC_VECTOR ( 31 DOWNTO 0 );
      read_data_1_out : OUT    STD_LOGIC_VECTOR ( 31 DOWNTO 0 );
      read_data_2_out : OUT    STD_LOGIC_VECTOR ( 31 DOWNTO 0 );
      writeback_data_out  : OUT    STD_LOGIC_VECTOR ( 31 DOWNTO 0 );
		Instruction_out : OUT    STD_LOGIC_VECTOR ( 31 DOWNTO 0 );
		wrenBUS_out	       : OUT    STD_LOGIC;
		addressBUS		 : OUT 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
		DATA_bus 		 : INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 )
   );
   END COMPONENT;
	
COMPONENT GPIO IS
	generic ( MEMwitdh : integer :=12);
	PORT( 
			MemRead 			   : IN 	STD_LOGIC;
         MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   : IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			SWch 					: IN STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			LEDR 					:OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0,HEX1 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2,HEX3 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4,HEX5 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 )
			);
END COMPONENT;

signal DATA_bus : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
signal addressBUS,PC : STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );

SIGNAL read_data_1 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL read_data_2 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL ALU_result 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL Instruction		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL writeback_data		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );

SIGNAL Branch,Jump 			: STD_LOGIC;
SIGNAL MemWrite 		: STD_LOGIC;
SIGNAL MemRead 			: STD_LOGIC;
SIGNAL Regwrite 		: STD_LOGIC;

--SIGNAL SW,LEDR		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
--signal HEX0,HEX1,HEX2,HEX3,HEX4,HEX5 	: STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			


SIGNAL clock,reset,wrenBUS 			: STD_LOGIC;

begin
	PC_out<=PC;
	Instruction_out 	<= Instruction;
   ALU_result_out 	<= ALU_result;
   read_data_1_out 	<= read_data_1;
   read_data_2_out 	<= read_data_2;
   writeback_data_out  	<= writeback_data;
   Branch_out 		<= Branch;
   Jump_out		<= Jump; 				
   RegWrite_out 	<= RegWrite;
   MemWrite_out 	<= MemWrite;
	MemRead_out 	<= MemRead;
	
	reset <= Mrst;
	
	wrenBUS_out <= wrenBUS;
	addressBUS_out <= addressBUS;
Data_bus_out<=DATA_bus;
	


	
	
	
PLLmap : PLL PORT MAP (
			refclk =>   Mclk, 
			rst   =>   reset, 
			outclk_0 => clock );
	
	
COREmap : MIPS generic map(MEMwitdh)
      PORT MAP (
         reset           => reset,
         clock           => Mclk, --Mclk is for tb only
         PC              => PC,
         ALU_result_out  => ALU_result,
         read_data_1_out => read_data_1,
         read_data_2_out => read_data_2,
         writeback_data_out=> writeback_data,
         Instruction_out => Instruction,
         Branch_out      => Branch,
			Jump_out			 => Jump,
         Memwrite_out    => Memwrite,
			Memread_out     => Memread,
         Regwrite_out    => Regwrite,
			wrenBUS_out         => wrenBUS,
			addressBUS		 => addressBUS,
			DATA_bus 		 => DATA_bus 
      );
		
		
GPIOmap :  GPIO generic map( MEMwitdh)
	PORT map( 
			MemRead 		=>	MemRead,
         MemWrite 	=>	MemWrite,	
			addressBUS	=> addressBUS,
			DATA_bus 	=>	DATA_bus,
			SWch 			=>	SWch_IN,
			LEDR 			=>	LEDR_out,
			HEX0			=> HEX0_out,
			HEX1 			=>	HEX1_out,
			HEX2			=> HEX2_out,
			HEX3 			=>	HEX3_out,
			HEX4			=> HEX4_out,
			HEX5 			=>	HEX5_out 		
			);

	
END top_arch;