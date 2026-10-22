//// FUNC 0044f370 FUN_0044f370

void __fastcall FUN_0044f370(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x10) + 0xc;
  *(int *)(param_1 + 0x10) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x101;
  return;
}


//// FUNC 0044f390 FUN_0044f390

void __fastcall FUN_0044f390(int param_1)

{
  int *piVar1;
  int iVar2;
  uint uVar3;
  int *piVar4;
  int **ppiVar5;
  int *piVar6;
  int iVar7;
  int *piStack_5c;
  int iStack_58;
  int iStack_54;
  uint *puStack_50;
  int *piStack_4c;
  int iStack_48;
  int iStack_44;
  int iStack_40;
  uint uStack_3c;
  undefined4 uStack_38;
  undefined4 uStack_34;
  undefined1 *puStack_30;
  undefined1 *puStack_2c;
  int iStack_18;
  int iStack_14;
  undefined1 auStack_10 [4];
  undefined1 auStack_c [4];
  int iStack_8;
  int *piStack_4;
  
  iVar7 = *(int *)(param_1 + 0x10);
  piStack_4 = (int *)((int)-(&DAT_00a52ee8)[iVar7 / 2 & 0x1ff] >> 8);
  if (iVar7 < 0x80) {
    iStack_8 = 0x10000;
  }
  else {
    iStack_8 = iVar7 << 9;
  }
  piVar4 = (int *)((&DAT_00a52ee8)[iVar7 - 0x80U & 0x1ff] * 0xb0 >> 0x10);
  puStack_2c = (undefined1 *)
               ((((*(ushort *)(param_1 + 0x1c) & 0x4000) >> 0xe) +
                ((byte)~DAT_00a54e5c & 1 ^ ~(uint)*(ushort *)(param_1 + 0x1c) & 1) * 2) * 0x5a);
  puStack_30 = (undefined1 *)0x44f426;
  piVar1 = (int *)FUN_0041f2e0();
  puStack_2c = auStack_10;
  puStack_30 = auStack_c;
  uStack_34 = 0x44f439;
  (**(code **)(*piVar1 + 0x38))();
  piVar6 = piStack_4;
  uStack_34 = 0;
  uStack_38 = 0;
  uStack_3c = 0;
  iStack_40 = (int)(&DAT_00a52ee8)[*(int *)(param_1 + 0x10) - 0x80U & 0x1ff] >> 9;
  iStack_44 = *(int *)(param_1 + 0x18) - iStack_18 / 2;
  iStack_48 = *(int *)(param_1 + 0x14) - iStack_14 / 2;
  puStack_50 = (uint *)0x44f486;
  piStack_4c = piVar1;
  (**(code **)(*piStack_4 + 0xac))();
  piVar1 = (int *)(param_1 + 0x20);
  puStack_50 = &uStack_3c;
  uStack_3c = (uint)(*(char *)(param_1 + 0x1e) == '\0');
  iStack_54 = 0x44f4a3;
  (**(code **)**(undefined4 **)(param_1 + 0x70))();
  iStack_54 = -1;
  iStack_58 = iStack_40;
  piStack_5c = (int *)0x44f4b1;
  (**(code **)(*piVar1 + 8))();
  *(undefined4 *)(*(int *)(param_1 + 0x48) + iStack_48 * 4) = 0;
  piStack_5c = piVar4;
  FUN_00422c00(piVar6,*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + iStack_48 * 8),
               *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),uStack_34,uStack_38,
               uStack_38);
  iStack_48 = 2;
  piStack_5c = &iStack_48;
  (**(code **)**(undefined4 **)(param_1 + 0x70))();
  iVar7 = -1;
  piVar6 = piStack_4c;
  (**(code **)(*piVar1 + 8))(piStack_4c,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x48) + iStack_54 * 4) = 0;
  ppiVar5 = &piStack_4c;
  (**(code **)(**(int **)(*(int *)(param_1 + 0x80) + 4 + iStack_54 * 8) + 0x38))(&iStack_48);
  iStack_58 = param_1 + 0x104;
  piStack_4c = (int *)0x0;
  do {
    iVar2 = *(int *)(param_1 + 0x10) - (int)piStack_4c;
    uVar3 = (int)(iVar2 + (iVar2 >> 0x1f & 7U)) >> 3;
    if (-1 < iVar2) {
      piStack_5c = (int *)((uVar3 & 1) + 2 + (uint)(*(char *)(param_1 + 0x1e) == '\0') * 2);
      (**(code **)**(undefined4 **)(param_1 + 0x70))(&piStack_5c);
      (**(code **)(*piVar1 + 8))(iVar7,0xffffffff);
      *(undefined4 *)(*(int *)(param_1 + 0x48) + (int)ppiVar5 * 4) = 0;
      iStack_54 = *piStack_4c;
      (**(code **)(iStack_54 + 0xb0))
                (*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + (int)ppiVar5 * 8),
                 *piVar6 - (int)piStack_5c / 2,
                 (piVar6[1] - ((int)(uVar3 * uVar3 + ((int)(uVar3 * uVar3) >> 0x1f & 0xfU)) >> 4)) -
                 iVar7 / 2,piVar4,0,0,0);
    }
    piStack_4c = piStack_4c + 4;
    iStack_58 = iStack_58 + 8;
  } while ((int)piStack_4c < 0x80);
  return;
}


