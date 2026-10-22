005a4010 FUN_005a4010 size=115

undefined4 FUN_005a4010(undefined4 param_1)

{
  short sVar1;
  uint uVar2;
  int iVar3;
  ushort *puVar4;
  
  uVar2 = 0;
  do {
    iVar3 = 5;
    puVar4 = &DAT_00a56044 + (uVar2 & 1) * 0x6a2;
    do {
      sVar1 = FUN_004022e0(*puVar4 & 0xfff);
      if (sVar1 == 0x590) {
        FUN_00574b50(uVar2,iVar3);
      }
      iVar3 = iVar3 + 1;
      puVar4 = puVar4 + 0x48;
    } while (iVar3 < 10);
    uVar2 = uVar2 + 1;
  } while ((int)uVar2 < 2);
  FUN_00579930(param_1,0x12,1);
  return 1;
}

