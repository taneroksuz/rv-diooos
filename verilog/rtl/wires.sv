package wires;
  timeunit 1ns; timeprecision 1ps;

  typedef struct packed {
    logic [0:0] bit_sh1add;
    logic [0:0] bit_sh2add;
    logic [0:0] bit_sh3add;
  } zba_op_type;

  parameter zba_op_type init_zba_op = '{bit_sh1add : 0, bit_sh2add : 0, bit_sh3add : 0};

  typedef struct packed {
    logic [0:0] bit_andn;
    logic [0:0] bit_orn;
    logic [0:0] bit_xnor;
    logic [0:0] bit_clz;
    logic [0:0] bit_cpop;
    logic [0:0] bit_ctz;
    logic [0:0] bit_max;
    logic [0:0] bit_maxu;
    logic [0:0] bit_min;
    logic [0:0] bit_minu;
    logic [0:0] bit_orcb;
    logic [0:0] bit_rev8;
    logic [0:0] bit_rol;
    logic [0:0] bit_ror;
    logic [0:0] bit_sextb;
    logic [0:0] bit_sexth;
    logic [0:0] bit_zexth;
  } zbb_op_type;

  parameter zbb_op_type init_zbb_op = '{
      bit_andn  : 0,
      bit_orn   : 0,
      bit_xnor  : 0,
      bit_clz   : 0,
      bit_cpop  : 0,
      bit_ctz   : 0,
      bit_max   : 0,
      bit_maxu  : 0,
      bit_min   : 0,
      bit_minu  : 0,
      bit_orcb  : 0,
      bit_rev8  : 0,
      bit_rol   : 0,
      bit_ror   : 0,
      bit_sextb : 0,
      bit_sexth : 0,
      bit_zexth : 0
  };

  typedef struct packed {
    logic [0:0] bit_clmul_;
    logic [0:0] bit_clmulh;
    logic [0:0] bit_clmulr;
  } zbc_op_type;

  parameter zbc_op_type init_zbc_op = '{bit_clmul_ : 0, bit_clmulh : 0, bit_clmulr : 0};

  typedef struct packed {
    logic [0:0] bit_bclr;
    logic [0:0] bit_bext;
    logic [0:0] bit_binv;
    logic [0:0] bit_bset;
  } zbs_op_type;

  parameter zbs_op_type init_zbs_op = '{bit_bclr : 0, bit_bext : 0, bit_binv : 0, bit_bset : 0};

  typedef struct packed {
    logic [0:0] bit_imm;
    logic [0:0] bit_alu_;
    logic [0:0] bit_clmul_;
    zba_op_type bit_zba;
    zbb_op_type bit_zbb;
    zbc_op_type bit_zbc;
    zbs_op_type bit_zbs;
  } bit_op_type;

  parameter bit_op_type init_bit_op = '{
      bit_imm    : 0,
      bit_alu_   : 0,
      bit_clmul_ : 0,
      bit_zba    : init_zba_op,
      bit_zbb    : init_zbb_op,
      bit_zbc    : init_zbc_op,
      bit_zbs    : init_zbs_op
  };

  typedef struct packed {
    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [31:0] imm;
    logic [0:0]  sel;
    bit_op_type  bit_op;
  } bit_alu_in_type;

  typedef struct packed {logic [31:0] result;} bit_alu_out_type;

  typedef struct packed {
    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [0:0]  enable;
    zbc_op_type  op;
  } bit_clmul_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [0:0]  ready;
  } bit_clmul_out_type;

  typedef struct packed {
    logic [1:0]  state;
    logic [4:0]  counter;
    logic [5:0]  index;
    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [31:0] swap;
    logic [31:0] result;
    logic [0:0]  ready;
    zbc_op_type  op;
  } bit_clmul_reg_type;

  parameter bit_clmul_reg_type init_bit_clmul_reg = '{
      state   : 0,
      counter : 0,
      index   : 0,
      rdata1  : 0,
      rdata2  : 0,
      swap    : 0,
      result  : 0,
      ready   : 0,
      op      : init_zbc_op
  };

  typedef struct packed {
    logic [0 : 0] alu_add;
    logic [0 : 0] alu_sub;
    logic [0 : 0] alu_sll;
    logic [0 : 0] alu_srl;
    logic [0 : 0] alu_sra;
    logic [0 : 0] alu_slt;
    logic [0 : 0] alu_sltu;
    logic [0 : 0] alu_and;
    logic [0 : 0] alu_or;
    logic [0 : 0] alu_xor;
  } alu_op_type;

  parameter alu_op_type init_alu_op = '{
      alu_add : 0,
      alu_sub : 0,
      alu_sll : 0,
      alu_srl : 0,
      alu_sra : 0,
      alu_slt : 0,
      alu_sltu : 0,
      alu_and : 0,
      alu_or : 0,
      alu_xor : 0
  };

  typedef struct packed {
    logic [0 : 0] divs;
    logic [0 : 0] divu;
    logic [0 : 0] rem;
    logic [0 : 0] remu;
  } div_op_type;

  parameter div_op_type init_div_op = '{divs : 0, divu : 0, rem : 0, remu : 0};

  typedef struct packed {
    logic [0 : 0] muls;
    logic [0 : 0] mulh;
    logic [0 : 0] mulhsu;
    logic [0 : 0] mulhu;
  } mul_op_type;

  parameter mul_op_type init_mul_op = '{muls : 0, mulh : 0, mulhsu : 0, mulhu : 0};

  typedef struct packed {
    logic [0 : 0] lsu_lb;
    logic [0 : 0] lsu_lbu;
    logic [0 : 0] lsu_lh;
    logic [0 : 0] lsu_lhu;
    logic [0 : 0] lsu_lw;
    logic [0 : 0] lsu_ld;
    logic [0 : 0] lsu_sb;
    logic [0 : 0] lsu_sh;
    logic [0 : 0] lsu_sw;
  } lsu_op_type;

  parameter lsu_op_type init_lsu_op = '{
      lsu_lb : 0,
      lsu_lbu : 0,
      lsu_lh : 0,
      lsu_lhu : 0,
      lsu_lw : 0,
      lsu_ld : 0,
      lsu_sb : 0,
      lsu_sh : 0,
      lsu_sw : 0
  };

  typedef struct packed {
    logic [0 : 0] bcu_beq;
    logic [0 : 0] bcu_bne;
    logic [0 : 0] bcu_blt;
    logic [0 : 0] bcu_bge;
    logic [0 : 0] bcu_bltu;
    logic [0 : 0] bcu_bgeu;
  } bcu_op_type;

  parameter bcu_op_type init_bcu_op = '{
      bcu_beq : 0,
      bcu_bne : 0,
      bcu_blt : 0,
      bcu_bge : 0,
      bcu_bltu : 0,
      bcu_bgeu : 0
  };

  typedef struct packed {
    logic [0 : 0] csrrw;
    logic [0 : 0] csrrs;
    logic [0 : 0] csrrc;
    logic [0 : 0] csrrwi;
    logic [0 : 0] csrrsi;
    logic [0 : 0] csrrci;
  } csr_op_type;

  parameter csr_op_type init_csr_op = '{
      csrrw : 0,
      csrrs : 0,
      csrrc : 0,
      csrrwi : 0,
      csrrsi : 0,
      csrrci : 0
  };

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
    logic [31 : 0] imm;
    logic [0 : 0] sel;
    alu_op_type alu_op;
  } alu_in_type;

  typedef struct packed {logic [31 : 0] result;} alu_out_type;

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
    logic [0 : 0] enable;
    div_op_type div_op;
  } div_in_type;

  typedef struct packed {
    logic [31 : 0] result;
    logic [0 : 0]  ready;
  } div_out_type;

  typedef struct packed {
    logic [31 : 0] data1;
    logic [31 : 0] data2;
    logic [31 : 0] op1;
    logic [31 : 0] op2;
    logic [0 : 0] op1_signed;
    logic [0 : 0] op2_signed;
    logic [0 : 0] op1_neg;
    logic [5 : 0] counter;
    logic [64 : 0] result;
    logic [0 : 0] division;
    logic [0 : 0] negativ;
    logic [0 : 0] divisionbyzero;
    logic [0 : 0] overflow;
    logic [0 : 0] ready;
    div_op_type div_op;
  } div_reg_type;

  parameter div_reg_type init_div_reg = '{
      data1 : 0,
      data2 : 0,
      op1 : 0,
      op2 : 0,
      op1_signed : 0,
      op2_signed : 0,
      op1_neg : 0,
      counter : 0,
      result : 0,
      division : 0,
      negativ : 0,
      divisionbyzero : 0,
      overflow : 0,
      ready : 0,
      div_op : init_div_op
  };

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
    mul_op_type mul_op;
  } mul_in_type;

  typedef struct packed {logic [31 : 0] result;} mul_out_type;

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
    logic [0 : 0] enable;
    bcu_op_type bcu_op;
  } bcu_in_type;

  typedef struct packed {logic [0 : 0] branch;} bcu_out_type;

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] imm;
    logic [31 : 0] pc;
    logic [0 : 0] auipc;
    logic [0 : 0] jal;
    logic [0 : 0] jalr;
    logic [0 : 0] branch;
    logic [0 : 0] load;
    logic [0 : 0] store;
    lsu_op_type lsu_op;
  } agu_in_type;

  typedef struct packed {
    logic [31 : 0] address;
    logic [3 : 0]  byteenable;
    logic [0 : 0]  exception;
    logic [7 : 0]  ecause;
    logic [31 : 0] etval;
  } agu_out_type;

  typedef struct packed {
    logic [31 : 0] ldata;
    logic [3 : 0] byteenable;
    lsu_op_type lsu_op;
  } lsu_in_type;

  typedef struct packed {logic [31 : 0] result;} lsu_out_type;

  typedef struct packed {
    logic [31 : 0] cdata;
    logic [31 : 0] rdata1;
    logic [31 : 0] imm;
    logic [0 : 0] sel;
    csr_op_type csr_op;
  } csr_alu_in_type;

  typedef struct packed {logic [31 : 0] cdata;} csr_alu_out_type;

  typedef struct packed {
    logic [0 : 0]  taken;
    logic [31 : 0] taddr;
    logic [1 : 0]  tsat;
  } prediction_type;

  parameter prediction_type init_prediction = '{taken : 0, taddr : 0, tsat : 0};

  typedef struct packed {
    logic [31 : 0]  get_pc0;
    logic [31 : 0]  get_pc1;
    logic [31 : 0]  upd_pc0;
    logic [31 : 0]  upd_pc1;
    logic [31 : 0]  upd_npc0;
    logic [31 : 0]  upd_npc1;
    logic [31 : 0]  upd_addr0;
    logic [31 : 0]  upd_addr1;
    logic [0 : 0]   upd_jal0;
    logic [0 : 0]   upd_jal1;
    logic [0 : 0]   upd_jalr0;
    logic [0 : 0]   upd_jalr1;
    logic [0 : 0]   upd_branch0;
    logic [0 : 0]   upd_branch1;
    logic [0 : 0]   upd_jump0;
    logic [0 : 0]   upd_jump1;
    prediction_type upd_pred0;
    prediction_type upd_pred1;
    logic [0 : 0]   stall;
    logic [0 : 0]   clear;
  } btac_in_type;

  typedef struct packed {
    prediction_type pred0;
    prediction_type pred1;
    logic [31 : 0]  pred_maddr;
    logic [0 : 0]   pred_miss;
    logic [0 : 0]   pred_hazard;
  } btac_out_type;

  typedef struct packed {
    logic [0 : 0] wren;
    logic [0 : 0] rden1;
    logic [0 : 0] rden2;
    logic [0 : 0] cwren;
    logic [0 : 0] crden;
    logic [0 : 0] alunit;
    logic [0 : 0] auipc;
    logic [0 : 0] lui;
    logic [0 : 0] jal;
    logic [0 : 0] jalr;
    logic [0 : 0] branch;
    logic [0 : 0] load;
    logic [0 : 0] store;
    logic [0 : 0] nop;
    logic [0 : 0] csreg;
    logic [0 : 0] division;
    logic [0 : 0] mult;
    logic [0 : 0] bitm;
    logic [0 : 0] bitc;
    logic [0 : 0] fence;
    logic [0 : 0] ecall;
    logic [0 : 0] ebreak;
    logic [0 : 0] mret;
    logic [0 : 0] wfi;
    logic [0 : 0] jump;
    logic [0 : 0] exception;
    logic [0 : 0] valid;
  } operation_type;

  parameter operation_type init_operation = '{
      wren : 0,
      rden1 : 0,
      rden2 : 0,
      cwren : 0,
      crden : 0,
      alunit : 0,
      auipc : 0,
      lui : 0,
      jal : 0,
      jalr : 0,
      branch : 0,
      load : 0,
      store : 0,
      nop : 0,
      csreg : 0,
      division : 0,
      mult : 0,
      bitm : 0,
      bitc : 0,
      fence : 0,
      ecall : 0,
      ebreak : 0,
      mret : 0,
      wfi : 0,
      jump : 0,
      exception : 0,
      valid : 0
  };

  typedef struct packed {
    logic [31 : 0] pc;
    logic [31 : 0] npc;
    logic [31 : 0] instr;
    logic [79 : 0] instr_str;
    logic [31 : 0] imm;
    logic [4 : 0] waddr;
    logic [4 : 0] raddr1;
    logic [4 : 0] raddr2;
    logic [4 : 0] raddr3;
    logic [11 : 0] caddr;
    logic [1 : 0] fmt;
    logic [2 : 0] rm;
    operation_type op;
    alu_op_type alu_op;
    bcu_op_type bcu_op;
    lsu_op_type lsu_op;
    csr_op_type csr_op;
    div_op_type div_op;
    mul_op_type mul_op;
    bit_op_type bit_op;
    prediction_type pred;
  } instruction_type;

  parameter instruction_type init_instruction = '{
      pc : 32'hFFFFFFFF,
      npc : 32'hFFFFFFFF,
      instr : 0,
      instr_str : "",
      imm : 0,
      waddr : 0,
      raddr1 : 0,
      raddr2 : 0,
      raddr3 : 0,
      caddr : 0,
      fmt : 0,
      rm : 0,
      op : init_operation,
      alu_op : init_alu_op,
      bcu_op : init_bcu_op,
      lsu_op : init_lsu_op,
      csr_op : init_csr_op,
      div_op : init_div_op,
      mul_op : init_mul_op,
      bit_op : init_bit_op,
      pred : init_prediction
  };

  typedef struct packed {
    logic [31 : 0] pc;
    logic [31 : 0] npc;
    logic [31 : 0] instr;
    logic [31 : 0] imm;
    logic [4 : 0] waddr;
    logic [4 : 0] raddr1;
    logic [4 : 0] raddr2;
    logic [4 : 0] raddr3;
    logic [11 : 0] caddr;
    logic [1 : 0] fmt;
    logic [2 : 0] rm;
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
    logic [31 : 0] crdata;
    logic [31 : 0] cwdata;
    logic [31 : 0] bdata;
    logic [31 : 0] mdata;
    logic [31 : 0] wdata;
    logic [31 : 0] ldata;
    logic [31 : 0] sdata;
    logic [31 : 0] ddata;
    logic [31 : 0] bcdata;
    logic [0 : 0] fready;
    logic [0 : 0] dready;
    logic [0 : 0] bcready;
    logic [31 : 0] address;
    logic [3 : 0] byteenable;
    logic [7 : 0] ecause;
    logic [31 : 0] etval;
    logic [4 : 0] flags;
    operation_type op;
    operation_type op_b;
    alu_op_type alu_op;
    bcu_op_type bcu_op;
    lsu_op_type lsu_op;
    csr_op_type csr_op;
    div_op_type div_op;
    mul_op_type mul_op;
    bit_op_type bit_op;
    prediction_type pred;
    prediction_type pred_b;
  } calculation_type;

  parameter calculation_type init_calculation = '{
      pc : 32'hFFFFFFFF,
      npc : 32'hFFFFFFFF,
      instr : 0,
      imm : 0,
      waddr : 0,
      raddr1 : 0,
      raddr2 : 0,
      raddr3 : 0,
      caddr : 0,
      fmt : 0,
      rm : 0,
      rdata1 : 0,
      rdata2 : 0,
      crdata : 0,
      cwdata : 0,
      bdata : 0,
      mdata : 0,
      wdata : 0,
      sdata : 0,
      ldata : 0,
      ddata : 0,
      bcdata : 0,
      fready : 0,
      dready : 0,
      bcready : 0,
      address : 0,
      byteenable : 0,
      ecause : 0,
      etval : 0,
      flags : 0,
      op : init_operation,
      op_b : init_operation,
      alu_op : init_alu_op,
      bcu_op : init_bcu_op,
      lsu_op : init_lsu_op,
      csr_op : init_csr_op,
      div_op : init_div_op,
      mul_op : init_mul_op,
      bit_op : init_bit_op,
      pred : init_prediction,
      pred_b : init_prediction
  };

  typedef struct packed {
    logic [31 : 0] pc0;
    logic [31 : 0] pc1;
    logic [63 : 0] rdata;
    logic [0 : 0]  ready;
    logic [0 : 0]  clear;
    logic [0 : 0]  stall;
  } buffer_in_type;

  typedef struct packed {
    logic [31 : 0] pc0;
    logic [31 : 0] pc1;
    logic [31 : 0] instr0;
    logic [31 : 0] instr1;
    logic [0 : 0]  ready0;
    logic [0 : 0]  ready1;
    logic [0 : 0]  stall;
  } buffer_out_type;

  typedef struct packed {logic [31 : 0] instr;} decoder_in_type;

  typedef struct packed {
    logic [79 : 0] instr_str;
    logic [31 : 0] imm;
    logic [0 : 0] wren;
    logic [0 : 0] rden1;
    logic [0 : 0] rden2;
    logic [0 : 0] cwren;
    logic [0 : 0] crden;
    logic [0 : 0] alunit;
    logic [0 : 0] auipc;
    logic [0 : 0] lui;
    logic [0 : 0] jal;
    logic [0 : 0] jalr;
    logic [0 : 0] branch;
    logic [0 : 0] load;
    logic [0 : 0] store;
    logic [0 : 0] nop;
    logic [0 : 0] csreg;
    logic [0 : 0] division;
    logic [0 : 0] mult;
    logic [0 : 0] bitm;
    logic [0 : 0] bitc;
    logic [0 : 0] fence;
    logic [0 : 0] ecall;
    logic [0 : 0] ebreak;
    logic [0 : 0] mret;
    logic [0 : 0] wfi;
    logic [0 : 0] valid;
    alu_op_type alu_op;
    bcu_op_type bcu_op;
    lsu_op_type lsu_op;
    csr_op_type csr_op;
    div_op_type div_op;
    mul_op_type mul_op;
    bit_op_type bit_op;
  } decoder_out_type;

  typedef struct packed {logic [31 : 0] instr;} compress_in_type;

  typedef struct packed {
    logic [79 : 0] instr_str;
    logic [31 : 0] imm;
    logic [4 : 0] waddr;
    logic [4 : 0] raddr1;
    logic [4 : 0] raddr2;
    logic [0 : 0] wren;
    logic [0 : 0] rden1;
    logic [0 : 0] rden2;
    logic [0 : 0] alunit;
    logic [0 : 0] lui;
    logic [0 : 0] jal;
    logic [0 : 0] jalr;
    logic [0 : 0] branch;
    logic [0 : 0] load;
    logic [0 : 0] store;
    logic [0 : 0] nop;
    logic [0 : 0] ebreak;
    logic [0 : 0] valid;
    alu_op_type alu_op;
    bcu_op_type bcu_op;
    lsu_op_type lsu_op;
  } compress_out_type;

  typedef struct packed {
    logic [0 : 0] rden1;
    logic [4 : 0] raddr1;
    logic [0 : 0] rden2;
    logic [4 : 0] raddr2;
  } register_read_in_type;

  typedef struct packed {
    logic [0 : 0]  wren;
    logic [4 : 0]  waddr;
    logic [31 : 0] wdata;
  } register_write_in_type;

  typedef struct packed {
    logic [31 : 0] rdata1;
    logic [31 : 0] rdata2;
  } register_out_type;

  typedef struct packed {
    logic [31 : 0] pc0;
    logic [31 : 0] pc1;
    logic [31 : 0] instr0;
    logic [31 : 0] instr1;
    logic [0 : 0]  ready0;
    logic [0 : 0]  ready1;
  } fetch_out_type;

  typedef struct packed {
    logic [31 : 0] ipc0;
    logic [31 : 0] ipc1;
    logic [31 : 0] irdata0;
    logic [31 : 0] irdata1;
    logic [0 : 0]  iready0;
    logic [0 : 0]  iready1;
    logic [63 : 0] rdata;
    logic [0 : 0]  ready;
    logic [31 : 0] pc0;
    logic [31 : 0] pc1;
    logic [31 : 0] instr0;
    logic [31 : 0] instr1;
    logic [0 : 0]  ready0;
    logic [0 : 0]  ready1;
    logic [0 : 0]  valid;
    logic [0 : 0]  fence;
    logic [0 : 0]  spec;
    logic [1 : 0]  state;
    logic [0 : 0]  stall;
  } fetch_reg_type;

  parameter fetch_reg_type init_fetch_reg = '{
      ipc0 : 0,
      ipc1 : 0,
      irdata0 : 0,
      irdata1 : 0,
      iready0 : 0,
      iready1 : 0,
      rdata : 0,
      ready : 0,
      pc0 : 0,
      pc1 : 0,
      instr0 : 0,
      instr1 : 0,
      ready0 : 0,
      ready1 : 0,
      valid : 0,
      fence : 0,
      spec : 0,
      state : 0,
      stall : 0
  };

  typedef struct packed {
    instruction_type instr0;
    instruction_type instr1;
    logic [0 : 0] stall;
  } decode_out_type;

  typedef struct packed {
    instruction_type instr0;
    instruction_type instr1;
    logic [0 : 0] stall;
  } decode_reg_type;

  parameter decode_reg_type init_decode_reg = '{
      instr0 : init_instruction,
      instr1 : init_instruction,
      stall : 0
  };

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] halt;
    logic [0 : 0] stall;
  } issue_out_type;

  typedef struct packed {
    instruction_type instr0;
    instruction_type instr1;
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] halt;
    logic [0 : 0] stall;
  } issue_reg_type;

  parameter issue_reg_type init_issue_reg = '{
      instr0 : init_instruction,
      instr1 : init_instruction,
      calc0 : init_calculation,
      calc1 : init_calculation,
      halt : 0,
      stall : 0
  };

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] stall;
  } execute_out_type;

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] enable;
    logic [0 : 0] stall;
  } execute_reg_type;

  parameter execute_reg_type init_execute_reg = '{
      calc0 : init_calculation,
      calc1 : init_calculation,
      enable : 0,
      stall : 0
  };

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] stall;
  } memory_out_type;

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] ready0;
    logic [0 : 0] ready1;
    logic [0 : 0] stall;
  } memory_reg_type;

  parameter memory_reg_type init_memory_reg = '{
      calc0 : init_calculation,
      calc1 : init_calculation,
      ready0 : 0,
      ready1 : 0,
      stall : 0
  };

  typedef struct packed {logic [0 : 0] stall;} writeback_out_type;

  typedef struct packed {
    calculation_type calc0;
    calculation_type calc1;
    logic [0 : 0] stall;
  } writeback_reg_type;

  parameter writeback_reg_type init_writeback_reg = '{
      calc0 : init_calculation,
      calc1 : init_calculation,
      stall : 0
  };

  typedef struct packed {
    logic [11:11] meip;
    logic [9:9]   seip;
    logic [8:8]   ueip;
    logic [7:7]   mtip;
    logic [5:5]   stip;
    logic [4:4]   utip;
    logic [3:3]   msip;
    logic [1:1]   ssip;
    logic [0:0]   usip;
  } csr_mip_reg_type;

  parameter csr_mip_reg_type init_csr_mip_reg = '{
      meip : 0,
      seip : 0,
      ueip : 0,
      mtip : 0,
      stip : 0,
      utip : 0,
      msip : 0,
      ssip : 0,
      usip : 0
  };

  typedef struct packed {
    logic [11:11] meie;
    logic [9:9]   seie;
    logic [8:8]   ueie;
    logic [7:7]   mtie;
    logic [5:5]   stie;
    logic [4:4]   utie;
    logic [3:3]   msie;
    logic [1:1]   ssie;
    logic [0:0]   usie;
  } csr_mie_reg_type;

  parameter csr_mie_reg_type init_csr_mie_reg = '{
      meie : 0,
      seie : 0,
      ueie : 0,
      mtie : 0,
      stie : 0,
      utie : 0,
      msie : 0,
      ssie : 0,
      usie : 0
  };

  typedef struct packed {
    logic [31:31] sd;
    logic [22:22] tsr;
    logic [21:21] tw;
    logic [20:20] tvm;
    logic [19:19] mxr;
    logic [18:18] summ;
    logic [17:17] mprv;
    logic [16:15] xs;
    logic [14:13] fs;
    logic [12:11] mpp;
    logic [8:8]   spp;
    logic [7:7]   mpie;
    logic [5:5]   spie;
    logic [4:4]   upie;
    logic [3:3]   mie;
    logic [1:1]   sie;
    logic [0:0]   uie;
  } csr_mstatus_reg_type;

  parameter csr_mstatus_reg_type init_csr_mstatus_reg = '{
      sd : 0,
      tsr : 0,
      tw : 0,
      tvm : 0,
      mxr : 0,
      summ : 0,
      mprv : 0,
      xs : 0,
      fs : 0,
      mpp : 0,
      spp : 0,
      mpie : 0,
      spie : 0,
      upie : 0,
      mie : 0,
      sie : 0,
      uie : 0
  };

  typedef struct packed {
    csr_mstatus_reg_type mstatus;
    logic [31 : 0] mtvec;
    logic [63 : 0] mcycle;
    logic [63 : 0] minstret;
    logic [31 : 0] mscratch;
    logic [31 : 0] mepc;
    logic [31 : 0] mcause;
    logic [31 : 0] mtval;
    csr_mip_reg_type mip;
    csr_mie_reg_type mie;
  } csr_machine_reg_type;

  parameter csr_machine_reg_type init_csr_machine_reg = '{
      mstatus : init_csr_mstatus_reg,
      mtvec : 0,
      mscratch : 0,
      mepc : 0,
      mcause : 0,
      mtval : 0,
      mcycle : 0,
      minstret : 0,
      mip : init_csr_mip_reg,
      mie : init_csr_mie_reg
  };

  typedef struct packed {
    logic [0 : 0]  crden;
    logic [11 : 0] craddr;
  } csr_read_in_type;

  typedef struct packed {
    logic [0 : 0]  cwren;
    logic [11 : 0] cwaddr;
    logic [31 : 0] cdata;
  } csr_write_in_type;

  typedef struct packed {
    logic [0 : 0]  valid0;
    logic [0 : 0]  valid1;
    logic [31 : 0] pc;
    logic [0 : 0]  mret;
    logic [0 : 0]  exception;
    logic [31 : 0] epc;
    logic [7 : 0]  ecause;
    logic [31 : 0] etval;
  } csr_exception_in_type;

  typedef struct packed {
    logic [0 : 0]  trap;
    logic [0 : 0]  mret;
    logic [31 : 0] mtvec;
    logic [31 : 0] mepc;
    logic [31 : 0] cdata;
    logic [1 : 0]  fs;
  } csr_out_type;

  typedef struct packed {
    logic [0 : 0]  cwren;
    logic [0 : 0]  crden;
    logic [11 : 0] cwaddr;
    logic [11 : 0] craddr;
    logic [31 : 0] cwdata;
    logic [1 : 0]  mode;
  } csr_pmp_in_type;

  typedef struct packed {
    logic [31 : 0] crdata;
    logic [0 : 0]  cready;
  } csr_pmp_out_type;

  typedef struct packed {
    fetch_out_type f;
    decode_out_type d;
    issue_out_type i;
    execute_out_type e;
    memory_out_type m;
    writeback_out_type w;
  } fetch_in_type;

  typedef struct packed {
    fetch_out_type f;
    decode_out_type d;
    issue_out_type i;
    execute_out_type e;
    memory_out_type m;
    writeback_out_type w;
  } decode_in_type;

  typedef struct packed {
    logic [0 : 0]  mem_valid;
    logic [0 : 0]  mem_instr;
    logic [1 : 0]  mem_mode;
    logic [31 : 0] mem_addr;
    logic [31 : 0] mem_wdata;
    logic [3 : 0]  mem_wstrb;
  } mem_in_type;

  localparam mem_in_type init_mem_in = 0;

  typedef struct packed {
    logic [0 : 0]  mem_ready;
    logic [0 : 0]  mem_error;
    logic [31 : 0] mem_rdata;
  } mem_out_type;

  localparam mem_out_type init_mem_out = 0;

  localparam PRF_ADDR_BITS = $clog2(PRF_DEPTH);
  localparam ROB_ADDR_BITS = $clog2(ROB_DEPTH);
  localparam RS_ADDR_BITS = $clog2(RS_INT_DEPTH);
  localparam FLIST_DEPTH = PRF_DEPTH - ARCH_REGS;
  localparam FL_CNT_BITS = $clog2(FLIST_DEPTH) + 1;
  localparam FL_IDX_BITS = $clog2(FLIST_DEPTH);

  typedef struct packed {
    logic [0:0]               valid;
    logic [0:0]               done;
    logic [0:0]               exception;
    logic [7:0]               ecause;
    logic [31:0]              etval;
    logic [31:0]              pc;
    logic [31:0]              npc;
    logic [31:0]              result;
    logic [PRF_ADDR_BITS-1:0] pdest;
    logic [PRF_ADDR_BITS-1:0] old_pdest;
    logic [4:0]               adest;
    logic [0:0]               wren;
    logic [0:0]               store;
    logic [0:0]               load;
    logic [31:0]              store_addr;
    logic [31:0]              store_data;
    logic [3:0]               store_strb;
    lsu_op_type               lsu_op;
    logic [0:0]               branch;
    logic [0:0]               jump;
    logic [0:0]               mret;
    logic [0:0]               fence;
    logic [0:0]               ecall;
    logic [0:0]               ebreak;
    logic [0:0]               wfi;
    logic [0:0]               csreg;
    logic [0:0]               cwren;
    logic [11:0]              caddr;
    logic [31:0]              cwdata;
  } rob_entry_type;

  localparam rob_entry_type init_rob_entry = '{
      valid      : 0,
      done       : 0,
      exception  : 0,
      ecause     : 0,
      etval      : 0,
      pc         : 32'hFFFFFFFF,
      npc : 32'hFFFFFFFF,
      result : 0,
      pdest      : 0,
      old_pdest  : 0,
      adest : 0,
      wren       : 0,
      store      : 0,
      load  : 0,
      store_addr : 0,
      store_data : 0,
      store_strb : 0,
      lsu_op     : init_lsu_op,
      branch     : 0,
      jump       : 0,
      mret  : 0,
      fence  : 0,
      ecall      : 0,
      ebreak     : 0,
      wfi   : 0,
      csreg  : 0,
      cwren      : 0,
      caddr      : 0,
      cwdata: 0
  };

  typedef struct packed {
    logic [0:0]               valid;
    logic [0:0]               src1_ready;
    logic [0:0]               src2_ready;
    logic [PRF_ADDR_BITS-1:0] psrc1;
    logic [PRF_ADDR_BITS-1:0] psrc2;
    logic [PRF_ADDR_BITS-1:0] pdest;
    logic [ROB_ADDR_BITS-1:0] rob_tag;
    logic [31:0]              rdata1;
    logic [31:0]              rdata2;
    logic [31:0]              imm;
    logic [31:0]              pc;
    logic [31:0]              npc;
    logic [11:0]              caddr;
    operation_type            op;
    alu_op_type               alu_op;
    bcu_op_type               bcu_op;
    lsu_op_type               lsu_op;
    csr_op_type               csr_op;
    div_op_type               div_op;
    mul_op_type               mul_op;
    bit_op_type               bit_op;
  } rs_entry_type;

  localparam rs_entry_type init_rs_entry = '{
      valid      : 0,
      src1_ready : 0,
      src2_ready : 0,
      psrc1      : 0,
      psrc2      : 0,
      pdest      : 0,
      rob_tag : 0,
      rdata1     : 0,
      rdata2     : 0,
      imm        : 0,
      pc         : 32'hFFFFFFFF,
      npc : 32'hFFFFFFFF,
      caddr : 0,
      op         : init_operation,
      alu_op : init_alu_op,
      bcu_op     : init_bcu_op,
      lsu_op : init_lsu_op,
      csr_op     : init_csr_op,
      div_op : init_div_op,
      mul_op     : init_mul_op,
      bit_op : init_bit_op
  };

  typedef struct packed {
    logic [0:0]               valid;
    logic [PRF_ADDR_BITS-1:0] tag;
  } rat_entry_type;

  typedef struct packed {
    logic [0:0]  flush;
    logic [31:0] flush_pc;
  } commit_type;

  localparam commit_type init_commit = '{flush: 0, flush_pc: 0};

  typedef struct packed {
    logic [0:0]               valid;
    logic [PRF_ADDR_BITS-1:0] tag;
    logic [31:0]              data;
  } cdb_type;

  localparam cdb_type init_cdb = '{valid: 0, tag: 0, data: 0};

  localparam PRF_SLOT_W = 33;
  localparam PRF_ARR_W = PRF_DEPTH * PRF_SLOT_W;
  typedef logic [PRF_ARR_W-1:0] prf_arr_type;

  localparam FL_ARR_W = FLIST_DEPTH * PRF_ADDR_BITS;
  typedef logic [FL_ARR_W-1:0] fl_arr_type;

  localparam RAT_SLOT_W = PRF_ADDR_BITS + 1;
  localparam RAT_ARR_W = ARCH_REGS * RAT_SLOT_W;
  typedef logic [RAT_ARR_W-1:0] rat_arr_type;

  localparam ROB_SLOT_W = $bits(rob_entry_type);
  localparam ROB_ARR_W = ROB_DEPTH * ROB_SLOT_W;
  typedef logic [ROB_ARR_W-1:0] rob_arr_type;

  localparam RS_SLOT_W = $bits(rs_entry_type);
  localparam RS_INT_ARR_W = RS_INT_DEPTH * RS_SLOT_W;
  localparam RS_MEM_ARR_W = RS_MEM_DEPTH * RS_SLOT_W;
  typedef logic [RS_INT_ARR_W-1:0] rs_int_arr_type;
  typedef logic [RS_MEM_ARR_W-1:0] rs_mem_arr_type;

  typedef struct packed {prf_arr_type array;} prf_reg_type;

  localparam prf_reg_type init_prf_reg = '{array: {PRF_DEPTH{1'b1, 32'h0}}};

  typedef struct packed {
    fl_arr_type             list;
    logic [FL_CNT_BITS-1:0] spec_head;
    logic [FL_CNT_BITS-1:0] comm_head;
    logic [FL_CNT_BITS-1:0] tail;
    logic [FL_CNT_BITS-1:0] spec_count;
    logic [FL_CNT_BITS-1:0] comm_count;
  } fl_reg_type;

  typedef struct packed {
    rat_arr_type spec;
    rat_arr_type comm;
  } rat_reg_type;

  typedef struct packed {
    rob_arr_type              array;
    logic [ROB_ADDR_BITS-1:0] head;
    logic [ROB_ADDR_BITS-1:0] tail;
    logic [ROB_ADDR_BITS:0]   count;
  } rob_reg_type;

  localparam rob_reg_type init_rob_reg = 0;

  typedef struct packed {
    rs_int_arr_type        array;
    logic [RS_ADDR_BITS:0] count;
  } rs_int_reg_type;

  localparam rs_int_reg_type init_rs_int_reg = 0;

  typedef struct packed {
    rs_mem_arr_type        array;
    logic [RS_ADDR_BITS:0] count;
  } rs_mem_reg_type;

  localparam rs_mem_reg_type init_rs_mem_reg = 0;

  typedef struct packed {
    logic [PRF_ADDR_BITS-1:0] raddr0;
    logic [PRF_ADDR_BITS-1:0] raddr1;
    logic [PRF_ADDR_BITS-1:0] raddr2;
    logic [PRF_ADDR_BITS-1:0] raddr3;
    logic [PRF_ADDR_BITS-1:0] waddr0;
    logic [31:0]              wdata0;
    logic [0:0]               wren0;
    logic [PRF_ADDR_BITS-1:0] waddr1;
    logic [31:0]              wdata1;
    logic [0:0]               wren1;
  } prf_in_type;

  typedef struct packed {
    logic [31:0] rdata0;
    logic [31:0] rdata1;
    logic [31:0] rdata2;
    logic [31:0] rdata3;
    logic [0:0]  rvalid0;
    logic [0:0]  rvalid1;
    logic [0:0]  rvalid2;
    logic [0:0]  rvalid3;
  } prf_out_type;

  localparam prf_in_type init_prf_in = 0;
  localparam prf_out_type init_prf_out = 0;

  typedef struct packed {
    logic [0:0]               alloc0;
    logic [0:0]               alloc1;
    logic [PRF_ADDR_BITS-1:0] free_tag0;
    logic [0:0]               free_en0;
    logic [PRF_ADDR_BITS-1:0] free_tag1;
    logic [0:0]               free_en1;
  } free_list_in_type;

  typedef struct packed {
    logic [PRF_ADDR_BITS-1:0] alloc_tag0;
    logic [PRF_ADDR_BITS-1:0] alloc_tag1;
    logic [0:0]               alloc_ok0;
    logic [0:0]               alloc_ok1;
    logic [0:0]               empty;
    logic [0:0]               has_two;
  } free_list_out_type;

  localparam free_list_in_type init_free_list_in = 0;
  localparam free_list_out_type init_free_list_out = 0;

  typedef struct packed {
    logic [4:0]               rsrc0_a;
    logic [4:0]               rsrc1_a;
    logic [4:0]               rsrc2_a;
    logic [4:0]               rsrc3_a;
    logic [4:0]               waddr0_a;
    logic [PRF_ADDR_BITS-1:0] waddr0_p;
    logic [0:0]               wren0;
    logic [4:0]               waddr1_a;
    logic [PRF_ADDR_BITS-1:0] waddr1_p;
    logic [0:0]               wren1;
    logic [4:0]               commit_addr0;
    logic [PRF_ADDR_BITS-1:0] commit_tag0;
    logic [0:0]               commit_en0;
    logic [4:0]               commit_addr1;
    logic [PRF_ADDR_BITS-1:0] commit_tag1;
    logic [0:0]               commit_en1;
  } rat_in_type;

  typedef struct packed {
    logic [PRF_ADDR_BITS-1:0] psrc0;
    logic [PRF_ADDR_BITS-1:0] psrc1;
    logic [PRF_ADDR_BITS-1:0] psrc2;
    logic [PRF_ADDR_BITS-1:0] psrc3;
    logic [0:0]               psrc0_valid;
    logic [0:0]               psrc1_valid;
    logic [0:0]               psrc2_valid;
    logic [0:0]               psrc3_valid;
    logic [PRF_ADDR_BITS-1:0] old_pdest0;
    logic [PRF_ADDR_BITS-1:0] old_pdest1;
  } rat_out_type;

  localparam rat_in_type init_rat_in = 0;
  localparam rat_out_type init_rat_out = 0;

  typedef struct packed {
    logic [0:0]               alloc0;
    logic [0:0]               alloc1;
    rob_entry_type            alloc_entry0;
    rob_entry_type            alloc_entry1;
    logic [ROB_ADDR_BITS-1:0] write_tag0;
    rob_entry_type            write_entry0;
    logic [0:0]               write_en0;
    logic [ROB_ADDR_BITS-1:0] write_tag1;
    rob_entry_type            write_entry1;
    logic [0:0]               write_en1;
    logic [ROB_ADDR_BITS-1:0] write_tag2;
    rob_entry_type            write_entry2;
    logic [0:0]               write_en2;
    cdb_type                  cdb0;
    cdb_type                  cdb1;
  } rob_in_type;

  typedef struct packed {
    rob_arr_type              array;
    logic [ROB_ADDR_BITS-1:0] head_ptr;
    logic [ROB_ADDR_BITS-1:0] tail_ptr;
    logic [ROB_ADDR_BITS-1:0] alloc_tag0;
    logic [ROB_ADDR_BITS-1:0] alloc_tag1;
    logic [0:0]               full;
    logic [0:0]               has_two_free;
    commit_type               commit_ctrl;
    rob_entry_type            entry0;
    rob_entry_type            entry1;
    logic [0:0]               commit0;
    logic [0:0]               commit1;
    logic [0:0]               stall;
  } rob_out_type;

  localparam rob_out_type init_rob_out = 0;

  typedef struct packed {
    rs_entry_type entry0;
    logic [0:0]   alloc0;
    rs_entry_type entry1;
    logic [0:0]   alloc1;
    cdb_type      cdb0;
    cdb_type      cdb1;
    cdb_type      cdb_load;
  } rs_int_in_type;

  typedef struct packed {
    rs_entry_type issue0;
    logic [0:0]   issue0_valid;
    rs_entry_type issue1;
    logic [0:0]   issue1_valid;
    logic [0:0]   full;
    logic [0:0]   has_two_free;
  } rs_int_out_type;

  typedef struct packed {
    rs_entry_type             entry0;
    logic [0:0]               alloc0;
    rs_entry_type             entry1;
    logic [0:0]               alloc1;
    cdb_type                  cdb0;
    cdb_type                  cdb1;
    cdb_type                  cdb_load;
    rob_arr_type              rob_array;
    logic [ROB_ADDR_BITS-1:0] rob_head;
  } rs_mem_in_type;

  typedef struct packed {
    rs_entry_type issue0;
    logic [0:0]   issue0_valid;
    logic [0:0]   full;
    logic [0:0]   has_two_free;
  } rs_mem_out_type;

  typedef struct packed {
    instruction_type          instr0;
    logic [0:0]               instr0_valid;
    instruction_type          instr1;
    logic [0:0]               instr1_valid;
    logic [ROB_ADDR_BITS-1:0] rob_tag0;
    logic [ROB_ADDR_BITS-1:0] rob_tag1;
    logic [0:0]               rob_full;
    logic [0:0]               rob_has_two;
    rat_out_type              rat;
    prf_out_type              prf;
    free_list_out_type        fl;
    logic [0:0]               rs_int_full;
    logic [0:0]               rs_int_has_two;
    logic [0:0]               rs_mem_full;
    logic [0:0]               rs_mem_has_two;
    cdb_type                  cdb0;
    cdb_type                  cdb1;
    cdb_type                  cdb_load;
  } rename_in_type;

  typedef struct packed {
    rs_entry_type  rs_int_entry0;
    logic [0:0]    rs_int_alloc0;
    rs_entry_type  rs_int_entry1;
    logic [0:0]    rs_int_alloc1;
    rs_entry_type  rs_mem_entry0;
    logic [0:0]    rs_mem_alloc0;
    rs_entry_type  rs_mem_entry1;
    logic [0:0]    rs_mem_alloc1;
    logic [0:0]    rob_alloc0;
    logic [0:0]    rob_alloc1;
    rob_entry_type rob_entry0;
    rob_entry_type rob_entry1;
    rat_in_type    rat;
    free_list_in_type fl;
    logic [0:0]    stall;
  } rename_out_type;

  typedef struct packed {
    rs_entry_type      int_issue0;
    logic [0:0]        int_issue0_valid;
    rs_entry_type      int_issue1;
    logic [0:0]        int_issue1_valid;
    rs_entry_type      mem_issue0;
    logic [0:0]        mem_issue0_valid;
    csr_out_type       csr;
    alu_out_type       alu0_out;
    alu_out_type       alu1_out;
    agu_out_type       agu0_out;
    agu_out_type       agu1_out;
    bcu_out_type       bcu0_out;
    bcu_out_type       bcu1_out;
    mul_out_type       mul_out;
    div_out_type       div_out;
    bit_alu_out_type   bit_alu0_out;
    bit_alu_out_type   bit_alu1_out;
    bit_clmul_out_type bit_clmul_out;
    csr_alu_out_type   csr_alu_out;
  } eu_in_type;

  typedef struct packed {
    alu_in_type               alu0_in;
    alu_in_type               alu1_in;
    agu_in_type               agu0_in;
    agu_in_type               agu1_in;
    bcu_in_type               bcu0_in;
    bcu_in_type               bcu1_in;
    mul_in_type               mul_in;
    div_in_type               div_in;
    bit_alu_in_type           bit_alu0_in;
    bit_alu_in_type           bit_alu1_in;
    bit_clmul_in_type         bit_clmul_in;
    csr_alu_in_type           csr_alu_in;
    cdb_type                  cdb0;
    cdb_type                  cdb1;
    logic [ROB_ADDR_BITS-1:0] rob_wtag0;
    rob_entry_type            rob_wentry0;
    logic [0:0]               rob_wen0;
    logic [ROB_ADDR_BITS-1:0] rob_wtag1;
    rob_entry_type            rob_wentry1;
    logic [0:0]               rob_wen1;
  } eu_out_type;

  typedef struct packed {
    rs_entry_type issue;
    logic [0:0]   issue_valid;
    lsu_out_type  lsu_out;
    mem_out_type  dmem_out;
  } load_in_type;

  typedef struct packed {
    cdb_type                  cdb;
    logic [ROB_ADDR_BITS-1:0] rob_wtag;
    rob_entry_type            rob_wentry;
    logic [0:0]               rob_wen;
    mem_in_type               dmem_in;
    lsu_in_type               lsu_in;
  } load_out_type;

  typedef struct packed {
    logic [0:0]    commit0;
    logic [0:0]    commit1;
    commit_type    commit_ctrl;
    rob_entry_type entry0;
    rob_entry_type entry1;
    csr_out_type   csr;
    lsu_out_type   lsu_out;
    mem_out_type   dmem_out;
  } commit_in_type;

  typedef struct packed {
    register_write_in_type register0_win;
    register_write_in_type register1_win;
    csr_write_in_type      csr_win;
    csr_exception_in_type  csr_ein;
    rat_in_type            rat;
    prf_in_type            prf;
    free_list_in_type      fl;
    mem_in_type            dmem_in;
    lsu_in_type            lsu_in;
    logic [0:0]            flush;
    logic [31:0]           flush_pc;
  } commit_out_type;

endpackage
