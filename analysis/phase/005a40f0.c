005a40f0 FUN_005a40f0 size=203

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

bool FUN_005a40f0(undefined4 param_1,int param_2)

{
  uint uVar1;
  
  uVar1 = (DAT_00a57810 & 0xffff) >> 9;
  if (uVar1 == 0) {
    DAT_00a577f8._2_2_ = CONCAT11(6,DAT_00a577f8._2_1_);
    _DAT_00a577fc =
         CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)((uint)_DAT_00a577fc >> 8) & 0xff,1));
    FUN_005798f0(0,1);
    if (param_2 != 0) {
      FUN_005b9170(DAT_00a57840 << 0xf | 0x35,DAT_00a57840 >> 8 & 7,1,0);
    }
    DAT_00a57840 = DAT_00a57840 | 0x40;
    DAT_00a57810 = CONCAT22(DAT_00a57810._2_2_,
                            ((ushort)DAT_00a57810 & 0xfe00) + 0x200 ^ (ushort)DAT_00a57810 & 0x1ff);
  }
  else if (uVar1 == 1) {
    FUN_005a4090(param_1);
    return (DAT_00a577f8._2_2_ & 0xff00) == 0x900;
  }
  return false;
}

