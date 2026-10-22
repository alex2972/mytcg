005a4090 FUN_005a4090 size=92

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a4090(undefined4 param_1)

{
  int iVar1;
  
  if ((code *)(&PTR_FUN_005efa68)[DAT_00a577f8._2_2_ >> 8] != (code *)0x0) {
    iVar1 = (*(code *)(&PTR_FUN_005efa68)[DAT_00a577f8._2_2_ >> 8])(param_1);
    if (iVar1 != 0) {
      _DAT_00a577fc = _DAT_00a577fc & 0xff00;
      DAT_00a577f8._2_2_ = (DAT_00a577f8._2_2_ & 0xff00) + 0x100 ^ DAT_00a577f8._2_2_ & 0xff;
    }
    return 0;
  }
  return 1;
}

