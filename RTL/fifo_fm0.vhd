--! \file fifo_fm0.vhd
--!
--! \author NOMES!
--!
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--! \brief Descricao de uma linha da entitdade.
--!
--! Descricao mais completa, algumas linhas
--!
--!
--!
entity FIFO_FM0 is
    generic (
        data_width : natural := 26; --! explixar
        tari_width : natural := 16; --! explicar
        mask_width : natural := 6   --! explicar
    );

    port (
        -- flags
        clk : in std_logic;               --! clock input
        rst_fm0       : in std_logic;     --! reset high

        enable_fm0    : in std_logic;     --! enable high
		encoder_ended : out std_logic;    --! high indicates end of transmission

        -- fifo
        clear_fifo : in std_logic;
        fifo_write_req : in std_logic;
        is_fifo_full : out std_logic;
        usedw : out std_logic_vector(7 downto 0);

        -- config
        tari : in std_logic_vector(tari_width-1 downto 0);

        -- data
        data : in std_logic_vector(31 downto 0);

        -- output
        q : out std_logic
    );

end entity;


architecture arch of FIFO_FM0 is
    component fm0_encoder
        generic (
                -- defining size of data in and clock speed
                data_width : natural := data_width;
                tari_width : natural := tari_width;
                mask_width : natural := mask_width
        );
        port (
            -- flags 
            clk : in std_logic;
            rst : in std_logic;
            enable : in std_logic;
            finished_sending : out std_logic;

            -- config
            tari : in std_logic_vector(tari_width-1 downto 0);

            -- fifo data
            is_fifo_empty    : in std_logic;
            data_in          : in std_logic_vector((data_width + mask_width)-1 downto 0); -- format expected : ddddddddmmmm
            request_new_data : out std_logic;

            -- output
            data_out : out std_logic
        );
    end component;

    component fifo_32_32 IS
            port
                (
                    clock : in std_logic;
                    data  : in std_logic_vector (31 downto 0);
                    rdreq : in std_logic;
                    sclr  : in std_logic;
                    wrreq : in std_logic;
                    empty : out std_logic;
                    full  : out std_logic;
                    q     : out std_logic_vector (31 downto 0);
                    usedw : out std_logic_vector (7 downto 0)
                );
        end component;

    signal fifo_out : std_logic_vector(31 downto 0);
    signal is_fifo_empty, request_new_data, data_out, wrfull : std_logic := '0';
		
    begin
        fifo : fifo_32_32 port map (
			sclr    => clear_fifo,
			data    => data,
			clock   => clk,
			wrreq   => fifo_write_req,
			rdreq   => request_new_data,
            q       => fifo_out,
            empty   => is_fifo_empty,
            full    => wrfull,
            usedw   => usedw
        );

        fm0 : fm0_encoder port map (
            clk              => clk,
            rst              => rst_fm0,
            finished_sending => encoder_ended,
            enable           => enable_fm0,
            tari             => tari,
            data_out         => data_out,
            is_fifo_empty    => is_fifo_empty,
            data_in          => fifo_out((data_width+mask_width)-1 downto 0),
            request_new_data => request_new_data
        );

        q <= data_out;
        is_fifo_full <= wrfull;

end arch ; -- arch
