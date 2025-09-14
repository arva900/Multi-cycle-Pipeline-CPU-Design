LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

ENTITY top IS
	generic ( MEMwitdh : integer :=12);
	PORT(
		Mrst, Mclk,KEY1_IN,KEY2_IN,KEY3_IN				: IN 	STD_LOGIC; 
		PWMout_out					: OUT 	STD_LOGIC ;
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

COMPONENT PLL2 is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic        -- outclk0.clk
		);
end COMPONENT;
COMPONENT PLL8 is
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
			Mclk,divclk,rst			 : IN 	STD_LOGIC;	
			MemRead 			   : IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   : IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			SWch 					: IN STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			LEDR 					:OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0,HEX1 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2,HEX3 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4,HEX5 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			DivIFG				:OUT STD_LOGIC
			);
END COMPONENT;
COMPONENT BTIMER IS
	generic ( MEMwitdh : integer :=12);
	PORT( Mclk,Mclk2,Mclk4,Mclk8,Mrst 		: IN 	STD_LOGIC;
			MemRead 			: IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   	: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PWMout 				: OUT 	STD_LOGIC;	
			set_BTIFG 			: OUT 	STD_LOGIC
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
SIGNAL DivIFG,BTIFG		: STD_LOGIC;

--SIGNAL SW,LEDR		: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
--signal HEX0,HEX1,HEX2,HEX3,HEX4,HEX5 	: STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			


SIGNAL clock,clock4,clock8,reset,wrenBUS 	: STD_LOGIC;

begin
	
reset <=not Mrst;

PLLmap : PLL PORT MAP (
			refclk =>   Mclk, 
			rst   =>   reset, 
			outclk_0 => clock );
	
PLL2map : PLL2 PORT MAP (
			refclk =>   Mclk, 
			rst   =>   reset, 
			outclk_0 => clock4 );
PLL8map : PLL8 PORT MAP (
			refclk =>   Mclk, 
			rst   =>   reset, 
			outclk_0 => clock8 );
	
	
COREmap : MIPS generic map(MEMwitdh) PORT MAP (
         reset           => reset,
         clock           => CLOCK, --Mclk is for tb only
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
		
		
GPIOmap :  GPIO generic map( MEMwitdh)PORT map( 	
			rst		=> reset,
			divclk		=> 		Mclk,
			Mclk		=> 		CLOCK,--Mclk is for tb only
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
			HEX5 			=>	HEX5_out, 
			DivIFG		=>DivIFG		
			);


BTIMERmap: BTIMER generic map ( MEMwitdh)PORT MAP(	
			Mclk		=> Mclk,--50M
			Mclk2		=> clock,--25M
			Mclk4		=> clock4,--12.5M
			Mclk8		=> clock8,--6.25M
			Mrst		=> reset,
			MemRead 	=> MemRead,
         	MemWrite 	=> MemWrite,
			addressBUS	=> addressBUS,
			DATA_bus 	=> DATA_bus,
			PWMout 		=> PWMout_out,
			set_BTIFG 	=> BTIFG
			);



	
END top_arch;