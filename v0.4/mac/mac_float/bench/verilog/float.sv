//------------------------------------------------------------------------------
// Copyright (c) 2019-2021 by Ando Ki.
// All right reserved.
//
// andoki@gmail.com
//------------------------------------------------------------------------------
// float.sv
//------------------------------------------------------------------------------
// VERSION = 2021.09.06.
//------------------------------------------------------------------------------
// Macros
//------------------------------------------------------------------------------
// Note:
// Note that 'type' 'real' is 64-bit width, but not 64-bit bit represention.
//
// $realtobits converts a real number to a 64-bit representation,
//             so that a real number can be passed through the port of a module.
// $bitstoreal converts the bit value to a real number.
// $rtoi converts a real number to an integer.
//       It truncates the real number to form the integer.
// $itor converts an integer to a real value.
//
// $shortrealtobits converts a shortreal number to a 32-bit representation,
//             so that a real number can be passed through the port of a module.
// $bitstoshortreal converts the bit value to a shortreal number.
//------------------------------------------------------------------------------
// Half to float:
// float f = ((h&0x8000)<<16) | (((h&0x7c00)+0x1C000)<<13) | ((h&0x03FF)<<13);

// Float to half:
// uint32_t x = *((uint32_t*)&f);
// uint16_t h = ((x>>16)&0x8000)|((((x&0x7f800000)-0x38000000)>>13)&0x7c00)|((x>>13)&0x03ff);
//
// ignores any kind of overflow, underflow, denormalized values, or infinite values
//------------------------------------------------------------------------------
// IEEE 754 Double Precision Floating-Point Number
//   63 62           52 51                  0
//  +--+---------------+---------------------+
//  |S | Exponent (E)  | Mantissa (M)        |
//  +-1+-------------11+-------------------52+
//   |
//   +-- Sign: 0 (positive)/1 (negative)
//
// IF E==2047: (0x7FF)
//    IF M==0: Value = Signed infinity
//    IF M!=0: Value = NaN
//              M[51] determines Quiet or Signalling:
//                    0: Quiet NaN
//                    1: Signalling NaN
// IF 0<E<2047:
//    Value = (-1)^S x 2^(E-1023) x (1 + (2^(-52) x M))
// IF E==0:
//    IF M==0: Value = Signed zero
//    IF M!=0: Value = (-1)^S x 2^(-1022) x (0 + (2^(-52) x M))
//
//------------------------------------------------------------------------------
// IEEE 754 Single Precision Floating-Point Number
//   31 30           23 22                  0
//  +--+---------------+---------------------+
//  |S | Exponent (E)  | Mantissa (M)        |
//  +-1+--------------8+-------------------23+
//   |
//   +-- Sign: 0 (positive)/1 (negative)
//
// IF E==255: (0xFF)
//    IF M==0: Value = Signed infinity depending S, +/-Infinity
//    IF M!=0: Value = NaN (Not a Number)
//              M[22] determines Quiet or Signalling:
//                    0: Quiet NaN
//                    1: Signalling NaN
// IF 0<E<255: to get normalized mantisa (1.M)
//    Value = (-1)^S x 2^(E-127) x (1 + (2^(-23) x M))
// IF E==0: to get de-normalized mantisa (0.M)
//    IF M==0: Value = Signed zero depending S, +/-0
//    IF M!=0: Value = (-1)^S x 2^(-126) x (0 + (2^(-23) x M))
//
// When (E)>0
//  Power = (E) - 127
//  Base  = 1.(M)  <-- Normailzed mantisa
//
// When (E)=0
//  Power = -127
//  Base  = 0.(M)  <-- De-Normailzed mantisa
//
// Zero: (E)=0 & (M)=0
//
// Not A Number (NAN): (E)=FF
//
// 0 00000000 00000000000000000000001 (0x0000_0001) ~ 1.4012984643×10−45 (smallest positive subnormal number)
// 0 00000000 11111111111111111111111 (0x007f_ffff) ~ 1.1754942107×10−38 (largest subnormal number)
// 0 00000001 00000000000000000000000 (0x0080_0000) ~ 1.1754943508 × 10−38 (smallest positive normal number)
// 0 11111110 11111111111111111111111 (0x7f7f ffff) ~ 3.4028234664 × 1038 (largest normal number)
// 1 10000000 00000000000000000000000 (0xc000_0000) = −2
// 0 00000000 00000000000000000000000 (0x0000_0000) = 0
// 1 00000000 00000000000000000000000 (0x8000_0000) = −0
// 0 11111111 00000000000000000000000 (0x7f80_0000) = infinity
// 1 11111111 00000000000000000000000 (0xff80_0000) = −infinity
// 0 10000000 10010010000111111011011 (0x4049_0fdb) ~ 3.14159274101257324 ~ π ( pi )
// 0 01111101 01010101010101010101011 (0x3eaa_aaab) ~ 0.333333343267440796 ~ 1/3
// x 11111111 10000000000000000000001 (0xffc0_0001) = qNaN (on x86 and ARM processors)
// x 11111111 00000000000000000000001 (0xff80_0001) = sNaN (on x86 and ARM processors)
//------------------------------------------------------------------------------
// IEEE 754 Half Precision Floating-Point Number (binary 16)
//   15 14           10 9                   0
//  +--+---------------+---------------------+
//  |S | Exponent (E)  | Mantissa (M)        |
//  +-1+--------------5+-------------------10+
//   |
//   +-- Sign: 0 (positive)/1 (negative)
//
// IF E==31: (0x1F)
//    IF M==0: Value = Signed infinity
//    IF M!=0: Value = NaN
//              M[9] determines Quiet or Signalling:
//                   0: Quiet NaN
//                   1: Signalling NaN
// IF 0<E<31:
//    Value = (-1)^S x 2^(E-15) x (1 + (2^(-10) x M))
// IF E==0: to get subnormalized number
//    IF M==0: Value = Signed zero
//    IF M!=0: Value = (-1)^S x 2^(-14) x (0 + (2^(-10) x M))
//
//  0 00000 0000000001 (0x0001) ~ 0.000000059604645 (smallest positive subnormal number)
//  0 00000 1111111111 (0x03FF) ~ 0.000060975552 (largetst subnoarmal number)
//  0 00001 0000000000 (0x0400) ~ 0.00006103515625 (smallest positive normal number)
//  0 11110 1111111111 (0x7bff) = 65504 (largest normal number)
//  0 01110 1111111111 (0x3bff) ~ 0.99951172 (largest number less than one)
//  0 01111 0000000000 (0x3c00) = 1 (one)
//  0 01111 0000000001 (0x3c01) ~ 1.00097656 (smallest number larger than one)
//  0 01101 0101010101 (0x3555) ~ 0.33325195 (the rounding of 1/3 to nearest)
//  1 10000 0000000000 (0xc000) = −2
//  0 00000 0000000000 (0x0000) = 0
//  1 00000 0000000000 (0x8000) = −0
//  0 11111 0000000000 (0x7c00) = infinity
//  1 11111 0000000000 (0xfc00) = −infinity
//  0 11111 1000000001 (0x7e01) = qNaN (on x86 and ARM processors)
//  1 11111 1000000001 (0xfe01) = qNaN (on x86 and ARM processors)
//  0 11111 0000000001 (0x7c01) = sNaN (on x86 and ARM processors)
//  1 11111 0000000001 (0xfc01) = sNaN (on x86 and ARM processors)
//
//------------------------------------------------------------------------------
// It converts 16-bit floating-point bits to 32-bit shortreal.
// ref: https://gist.github.com/rygorous/2156668
function shortreal hbitstoshortreal;
  input [15:0] hbits;
  reg        sign;
  reg [ 4:0] exp;
  reg [ 9:0] man;
  shortreal  sr;
begin
//$display("%m A hbits=0x%04H", hbits);
  sign = hbits[15];
  exp  = hbits[14:10];
  man  = hbits[ 9: 0];
  if (exp==~0) begin
      if (man==0) begin
          // make signed infinity
          hbitstoshortreal = $bitstoshortreal({sign,8'hFF,23'h0});
      end else begin
          // make NaN
          hbitstoshortreal = $bitstoshortreal({sign,8'hFF,man[9],13'h0,man[8:0]});
      end
//$display("%m B hbits=0x%04H %f", hbits, hbitstoshortreal);
  end else if (exp==0) begin
      if (man==0) begin
          // make signed zero
          hbitstoshortreal = $bitstoshortreal({sign,8'h00,23'h0});
//$display("%m C hbits=0x%04H %f", hbits, hbitstoshortreal);
      end else begin
          // make subnormal
          sr = (1.0/$itor(1<<14))*(man/$itor(1<<10));
          hbitstoshortreal = (sign) ? -1.0*sr : sr;
//$display("%m D hbits=0x%04H %f %f", hbits, hbitstoshortreal, sr);
      end
  end else begin
      if (exp>=15) sr = ($itor(1<<(exp-15)))*((1.0 + $itor(man)/$itor(1<<10)));
      else         sr = (1.0/$itor(1<<(15-exp)))*((1.0 + $itor(man)/$itor(1<<10)));
      hbitstoshortreal = (sign==1'b1) ? -1.0 * sr : sr;
//$display("%m E hbits=0x%04H %f %f", hbits, hbitstoshortreal, sr);
  end
end
endfunction
//------------------------------------------------------------------------------
// It converts 32-bit floating-point to 16-bit halfreal bits.
// refer to $bitstoreal(bit_number);
function [15:0] shortrealtohbits;
  input shortreal svalue;
  reg [31:0] sbits;
  reg        sign;
  reg [ 7:0] exp;
  reg [22:0] man;
  reg [23:0] fman;
  shortreal sub, subbits;
  integer sexp;
begin
  sbits = $shortrealtobits(svalue);
//$display("%m A svalue=%f sbits=0x%08H", svalue, sbits);
  sign  = sbits[31];
  exp   = sbits[30:23];
  man   = sbits[22: 0];
  if (exp==~0) begin
      if (man==0) begin
          // make signed infinity
          shortrealtohbits = {sign,5'h1F,10'h0};
//$display("%m B svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end else begin
          // make NaN
          shortrealtohbits = {sign,5'h1F,man[22],man[8:0]};
//$display("%m C svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end
  end else if (exp==0) begin
      if (man==0) begin
          // make signed zero
          shortrealtohbits = {sign,5'h0,10'h0};
//$display("%m D svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end else begin
          // make subnormal
          shortrealtohbits = {sign,5'h0,10'h0};
//$display("%m E svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end
  end else begin
      sexp  = exp - 127 + 15;
      if (sexp>=31) begin // overflow, make signed infinity
          shortrealtohbits = {sign,5'h1F,10'h0};
//$display("%m F svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end else if (sexp<=0) begin // underflow
          if ((14-sexp)<=24) begin
              fman = man | 23'h80_0000; // make 1.nn
              fman = fman>>(14-sexp);
              shortrealtohbits = {sign,5'h0,fman[9:0]};
//$display("%m G svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
          end else begin
              shortrealtohbits = {sign,5'h0,10'h0};
//$display("%m H svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
          end
      end else begin
          // it uses truncation by not check man[12].
          shortrealtohbits = {sign,sexp[4:0],man[22:13]};
//$display("%m I svalue=%f sbits=0x%08H shortrealtohbits=0x%04X", svalue, sbits, shortrealtohbits);
      end
  end
end
endfunction
////------------------------------------------------------------------------------
//// It converts 32-bit floating-point bits to 64-bit real.
//// refer to $bitstoreal(bit_number);
//function real fbitstoreal;
//  input [31:0] fvalue;
//  reg        sign;
//  reg [ 7:0] exp;
//  reg [22:0] man;
//  reg [23:0] frac;
//  real       sr;
//begin
//  if (fvalue==32'h0) begin
//      fbitstoreal = $itor(0);
//  end else begin
//      sign = fvalue[31];
//      exp  = fvalue[30:23];
//      man  = fvalue[22:0];
//      frac = {1'b1,man};
//      sr   = 1.0*$itor(frac);
//      sr   = sr/$itor(24'h80_0000); // sr/8388608.0; 
//      if (exp>=8'h7F) begin
//          exp = exp - 8'h7F; // -127
//          sr  = sr * $itor(1<<exp);
//      end else begin
//          exp = 8'h7F - exp; // -127
//          sr  = sr / $itor(1<<exp);
//      end
//      fbitstoreal = (sign==1'b1) ? -1.0 * sr : sr;
//  end
//end
//endfunction
//
////------------------------------------------------------------------------------
//// IEEE 754 Half Precision Floating-Point Number (binary 16)
////   15 14           10 9                   0
////  +--+---------------+---------------------+
////  |S | Exponent (E)  | Mantissa (M)        |
////  +-1+--------------5+-------------------10+
////   |
////   |
////   +-- Sign: 0 (positive)
////             1 (negative)
////
//// IF E==15: (0xF)
////    IF M==0: Value = Signed infinity
////    IF M!=0: Value = NaN
////              M[9] determines Quiet or Signalling:
////                   0: Quiet NaN
////                   1: Signalling NaN
//// IF 0<E<15:
////    Value = (-1)^S x 2^(E-15) x (1 + (2^(-10) x M))
//// IF E==0:
////    IF M==0: Value = Signed zero
////    IF M!=0: Value = (-1)^S x 2^(-14) x (0 + (2^(-10) x M))
////
//// When (E)>0
////  Power = (E) - 15
////  Base  = 1.(M)  <-- Normailzed mantisa
////
//// When (E)=0
////  Power = -15
////  Base  = 0.(M)  <-- De-Normailzed mantisa
////
//// Zero: (E)=0 & (M)=0
////
//// Not A Number (NAN): (E)=1F
////
//// It converts 16-bit floating-point bits to 64-bit real.
//// refer to $bitstoreal(bit_number);
//function real hbitstoreal;
//  input [15:0] hvalue;
//  reg        sign;
//  reg [ 4:0] exp;
//  reg [ 9:0] man;
//  reg [10:0] frac;
//  real       sr;
//begin
//  if (hvalue==32'h0) begin
//      hbitstoreal = $itor(0);
//  end else begin
//      sign = hvalue[15];
//      exp  = hvalue[14:10];
//      man  = hvalue[ 9: 0];
//      frac = {1'b1,man};
//      sr   = 1.0*$itor(frac);
//      sr   = sr/$itor(11'h400); // sr/1024.0; 
//      if (exp>=5'h1F) begin
//          exp = exp - 5'hF; // -15
//          sr  = sr * $itor(1<<exp);
//      end else begin
//          exp = 5'hF - exp; // -15
//          sr  = sr / $itor(1<<exp);
//      end
//      hbitstoreal = (sign==1'b1) ? -1.0 * sr : sr;
//  end
//end
//endfunction
//
//
////------------------------------------------------------------------------------
//// IEEE 754 Double Precision Floating-Point Number
////   63 62           52 51                  0
////  +--+---------------+---------------------+
////  |S | Exponent (E)  | Mantissa (M)        |
////  +-1+-------------11+-------------------52+
////   |
////   |
////   +-- Sign: 0 (positive)
////             1 (negative)
////
//// IF E==1023: (0x3FF)
////    IF M==0: Value = Signed infinity
////    IF M!=0: Value = NaN
////              M[51] determines Quiet or Signalling:
////                    0: Quiet NaN
////                    1: Signalling NaN
//// IF 0<E<1023:
////    Value = (-1)^S x 2^(E-1023) x (1 + (2^(-52) x M))
//// IF E==0:
////    IF M==0: Value = Signed zero
////    IF M!=0: Value = (-1)^S x 2^(-1022) x (0 + (2^(-52) x M))
////
//// IEEE 754 Single Precision Floating-Point Number
////   31 30           23 22                  0
////  +--+---------------+---------------------+
////  |S | Exponent (E)  | Mantissa (M)        |
////  +-1+--------------8+-------------------23+
////
//// It converts double-precision floating-point to 32-bit single-precision floating-point bits.
//// refer to $realtobits(real_number);
//function [31:0] realtofbits;
//  input real rvalue;
//  reg [63:0] rbits;
//  reg        rsign;
//  reg [10:0] rexp;
//  reg [51:0] rman;
//  integer    texp, texp_abs;
//
//  reg        fsign;
//  reg [ 7:0] fexp;
//  reg [22:0] fman;
//begin
//  rbits = $realtobits(rvalue);
//  rsign = rbits[63];
//  rexp  = rbits[62:52];
//  rman  = rbits[51:0];
//
//  texp     = rexp-11'h3FF; // rexp-1023
//  if (texp>=0) begin
//      texp_abs = texp;
//      if (texp>127) begin
//          $display("%m ERROR exponent overflow: %d:%d", texp, rexp);
//          texp_abs = 127;
//      end
//  end else begin
//      texp_abs = -texp;
//      if (texp<-126) begin
//          $display("%m ERROR exponent overflow: %d:%d", texp, rexp);
//          texp_abs = 126;
//      end
//  end
//  if (rman[28:0]>0) $display("%m INFO mantisa underflow: 0x%X", rman);
//
//  fsign  = rsign;
//  if (texp>=0) fexp   = texp_abs[7:0]+8'h7F;
//  else         fexp   = 8'h7F - texp_abs[7:0];
//  fman   = rman[51:29];
//
////$display("%m rvalue=%f rbits=0x%016X texp=%d texp_abs=%d fexp=%d", rvalue, rbits, texp, texp_abs, fexp);
//
//  realtofbits = {fsign,fexp,fman};
//end
//endfunction
//
//// IEEE 754 Double Precision Floating-Point Number
////   63 62           52 51                  0
////  +--+---------------+---------------------+
////  |S | Exponent (E)  | Mantissa (M)        |
////  +-1+-------------11+-------------------52+
////   |
////   |
////   +-- Sign: 0 (positive)
////             1 (negative)
////
////   15 14           10 9                   0
////  +--+---------------+---------------------+
////  |S | Exponent (E)  | Mantissa (M)        |
////  +-1+--------------5+-------------------10+
////   |
////   |
////   +-- Sign: 0 (positive)
////             1 (negative)
////
//// It converts double-precision floating-point to 16-bit half-precision floating-point bits.
//// refer to $realtobits(real_number);
//function [15:0] realtohbits;
//  input real rvalue;
//  reg [63:0] rbits;
//  reg        rsign;
//  reg [10:0] rexp;
//  reg [51:0] rman;
//  integer    texp, texp_abs;
//
//  reg        hsign;
//  reg [ 4:0] hexp;
//  reg [ 9:0] hman;
//begin
//  rbits = $realtobits(rvalue);
//  rsign = rbits[63];
//  rexp  = rbits[62:52];
//  rman  = rbits[51:0];
//
//  texp     = rexp-11'h3FF; // rexp-1023
//  if (texp>=0) begin
//      texp_abs = texp;
//      if (texp>15) begin
//          $display("%m ERROR exponent overflow: %d:%d", texp, rexp);
//          texp_abs = 31;
//      end
//  end else begin
//      texp_abs = -texp;
//      if (texp<-15) begin
//          $display("%m ERROR exponent overflow: %d:%d", texp, rexp);
//          texp_abs = 30;
//      end
//  end
//  if (rman[41:0]>0) $display("%m INFO mantisa underflow: 0x%X", rman);
//
//  hsign  = rsign;
//  if (texp>=0) hexp   = texp_abs[4:0] + 5'hF;
//  else         hexp   = 5'hF - texp_abs[4:0];
//  hman   = rman[51:42];
//
////$display("%m rvalue=%f rbits=0x%016X texp=%d texp_abs=%d fexp=%d", rvalue, rbits, texp, texp_abs, fexp);
//
//  realtohbits = {hsign,hexp,hman};
//end
//endfunction
//------------------------------------------------------------------------------
// Revision History
//
// 2021.09.06: hbitstoreal(), realtohbits() added.
// 2019.11.04: Start by Ando Ki (adki@gmail.com)
//------------------------------------------------------------------------------
