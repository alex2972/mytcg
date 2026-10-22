//// FUNC 00413f10 FUN_00413f10

undefined4 __fastcall FUN_00413f10(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x10);
  if (((iVar1 != 4) && (iVar1 != 6)) && (iVar1 != 7)) {
    return 0;
  }
  return 1;
}


//// FUNC 00413f20 FUN_00413f20

undefined4 FUN_00413f20(void)

{
  bool in_ZF;
  
  if (!in_ZF) {
    return 0;
  }
  return 1;
}


//// FUNC 00413a60 FUN_00413a60

void FUN_00413a60(void)

{
  if ((DAT_00a585a8 & 1) == 0) {
    DAT_00a585a8 = DAT_00a585a8 | 1;
  }
  FUN_005c387c(FUN_004481f0);
  return;
}


//// FUNC 0041cee0 FUN_0041cee0

int FUN_0041cee0(int param_1,int param_2,uint param_3)

{
  int iVar1;
  int iVar2;
  
  iVar2 = param_1 * 0x460 + DAT_005f300c;
  if (param_2 == 0xb) {
    iVar1 = *(int *)(iVar2 + 4);
    if (((iVar1 != 0) && (param_3 < (uint)(*(int *)(iVar2 + 8) - iVar1 >> 4))) &&
       (iVar2 = *(int *)(param_3 * 0x10 + 4 + iVar1), iVar2 != 0)) {
      return iVar2;
    }
  }
  else if (param_2 < 0xb) {
    iVar1 = param_2 + param_3;
    if ((10 < iVar1) && (iVar1 = param_2, 0xf < (int)param_3)) {
      return *(int *)((param_2 + 0x11) * 0x10 + iVar2 + 4);
    }
    return *(int *)((iVar1 + 1) * 0x10 + iVar2 + 4);
  }
  return 0;
}


//// FUNC 0047c4f0 FUN_0047c4f0

void __thiscall FUN_0047c4f0(int param_1,int param_2,undefined4 param_3,undefined1 param_4)

{
  if (*(char *)(param_1 + 0x30) != '\0') {
    FUN_0047c540();
    return;
  }
  *(undefined4 *)(param_1 + 0x2c) = param_3;
  *(undefined4 *)(param_1 + 0x34) = 0;
  *(int *)(param_1 + 0x28) = param_2;
  *(undefined1 *)(param_1 + 0x30) = param_4;
  FUN_005c03d0(((-1 < param_2) - 1 & 0xffffffea) + 0x1000001f,0);
  return;
}


//// FUNC 005b88d0 FUN_005b88d0

undefined4 FUN_005b88d0(void)

{
  if (((DAT_00a55064 == DAT_00a5504c) && (DAT_00a5505c == DAT_00a55044)) &&
     (DAT_00a55060 == DAT_00a55048)) {
    return 0;
  }
  return 1;
}


