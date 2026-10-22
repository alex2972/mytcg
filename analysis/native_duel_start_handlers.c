//// FUNC 00451950 FUN_00451950

void __fastcall FUN_00451950(int param_1)

{
  if (*(int *)(param_1 + 0x10) == 0) {
    FUN_005c03d0(0x10000004,0);
  }
  *(int *)(param_1 + 0x10) = *(int *)(param_1 + 0x10) + 8;
  return;
}


//// FUNC 00451980 FUN_00451980

void __thiscall FUN_00451980(int param_1,int *param_2)

{
  int iVar1;
  undefined4 unaff_EBX;
  int iVar2;
  int unaff_ESI;
  undefined4 *puStack_40;
  int iStack_3c;
  undefined4 uStack_38;
  int iStack_34;
  int iStack_30;
  undefined4 uStack_2c;
  undefined4 uStack_28;
  undefined4 auStack_14 [2];
  int iStack_c;
  
  iVar2 = DAT_005f2fb8;
  iStack_c = param_1;
  if (*(int *)(DAT_005f2fb8 + 0x3b4) == 0) {
    uStack_28 = 0x4519a4;
    iVar1 = FUN_0054d760();
    uStack_28 = 0x4519b1;
    (**(code **)(*(int *)(iVar2 + 0x3b0) + 4))();
    if (iVar1 != 0) {
      *(int *)(iVar2 + 0x3b4) = iVar1;
      *(int *)(iVar2 + 0x3bc) = iVar2 + 0x3b0;
      *(int *)(iVar2 + 0x3b8) = iVar2 + 0x3b0;
    }
    uStack_28 = 0;
    uStack_2c = 600;
    iStack_30 = 800;
    iStack_34 = 0x4519d2;
    (**(code **)(**(int **)(iVar2 + 0x3b4) + 0x68))();
    *(undefined1 *)(*(int *)(iVar2 + 0x3b4) + 0x7a) = 1;
  }
  iStack_3c = *(int *)(iVar2 + 0x3b4);
  uStack_28 = 0;
  uStack_2c = 0;
  iStack_30 = 0;
  iStack_34 = 0;
  uStack_38 = 0;
  puStack_40 = (undefined4 *)0x4519f2;
  (**(code **)(*param_2 + 0xc))();
  iVar2 = *(int *)(param_1 + 0x10);
  if (iVar2 < 0x40) {
    iVar1 = (&DAT_00a52ee8)[iVar2 * 2 & 0x1ff] +
            ((int)(&DAT_00a52ee8)[iVar2 * 2 & 0x1ff] >> 0x1f & 0xffU);
    iVar1 = ((iVar1 >> 8) - (iVar1 >> 0x1f) >> 1) + 0x100;
    iVar2 = (int)(&DAT_00a52ee8)[iVar2 * 2 - 0x80U & 0x1ff] >> 8;
  }
  else {
    iVar1 = 0x100;
    if (iVar2 < 0x101) {
      iVar2 = 0x100;
    }
    else {
      iVar2 = (int)(&DAT_00a52ee8)[iVar2 * 2 & 0x1ff] >> 8;
    }
  }
  auStack_14[0] = 0;
  puStack_40 = auStack_14;
  (**(code **)**(undefined4 **)(param_1 + 100))();
  (**(code **)(*(int *)(param_1 + 0x14) + 8))(unaff_EBX,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x3c) + unaff_ESI * 4) = 0;
  (**(code **)(**(int **)(*(int *)(param_1 + 0x74) + 4 + unaff_ESI * 8) + 0x38))
            (&uStack_38,&iStack_34);
  uStack_28 = 0;
  iStack_34 = (int)((int)puStack_40 * iVar1 + ((int)puStack_40 * iVar1 >> 0x1f & 0xffU)) >> 8;
  iStack_30 = (int)(iStack_3c * iVar1 + (iStack_3c * iVar1 >> 0x1f & 0xffU)) >> 8;
  (**(code **)**(undefined4 **)(param_1 + 100))(&uStack_28);
  (**(code **)(*(int *)(param_1 + 0x14) + 8))(uStack_2c,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x3c) + iStack_34 * 4) = 0;
  (**(code **)(*param_2 + 0x48))
            (*(undefined4 *)(*(int *)(param_1 + 0x74) + 4 + iStack_34 * 8),400 - (int)puStack_40 / 2
             ,300 - iStack_3c / 2,iVar2,0,&puStack_40);
  if ((0x13f < iRam00000010) && (uRam00000004 = 0, DAT_005f3400 != 0)) {
    *(undefined1 *)(DAT_005f3400 + 5) = 0;
  }
  return;
}


//// FUNC 00451d00 FUN_00451d00

undefined4 __thiscall FUN_00451d00(undefined4 param_1,byte param_2)

{
  FUN_00451d20();
  if ((param_2 & 1) != 0) {
    FUN_0054a2d0(param_1);
  }
  return param_1;
}


