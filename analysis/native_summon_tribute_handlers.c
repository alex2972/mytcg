//// FUNC 0044f9f0 FUN_0044f9f0

void __fastcall FUN_0044f9f0(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x10) + 8;
  *(int *)(param_1 + 0x10) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x101;
  return;
}


//// FUNC 0044fa10 FUN_0044fa10

void __fastcall FUN_0044fa10(int param_1)

{
  int *piVar1;
  int iVar2;
  int unaff_EBX;
  int iVar3;
  int *piVar4;
  int unaff_EBP;
  int *piVar5;
  int unaff_ESI;
  int unaff_EDI;
  undefined1 *puVar6;
  undefined4 uVar7;
  undefined4 *puStack_48;
  undefined4 uStack_34;
  int iStack_30;
  int *piStack_2c;
  int iStack_28;
  undefined4 uStack_24;
  undefined4 uStack_20;
  int *piStack_1c;
  int iStack_18;
  undefined4 uStack_8;
  
  piVar1 = DAT_005f2ff8;
  iVar2 = *(int *)(param_1 + 0x10);
  iVar3 = (iVar2 + 0x40) * 0x100;
  piStack_2c = (int *)((((*(ushort *)(param_1 + 0x1c) & 0x4000) >> 0xe) +
                       ((byte)~DAT_00a54e5c & 1 ^ ~(uint)*(ushort *)(param_1 + 0x1c) & 1) * 2) *
                      0x80);
  if (iVar3 < 0x8001) {
    uStack_34 = *(undefined4 *)(param_1 + 0x20);
    puStack_48 = &uStack_34;
    iVar2 = (&DAT_00a52ee8)[iVar2 + 0x38U & 0x1ff];
    (*(code *)**(undefined4 **)DAT_005f2ff8[0x14])();
    (**(code **)(*piVar1 + 8))(unaff_EBX,0xffffffff);
    *(undefined4 *)(piVar1[10] + unaff_ESI * 4) = 0;
    FUN_00422c00(uStack_8,*(undefined4 *)(piVar1[0x18] + 4 + unaff_ESI * 8),
                 *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),unaff_EBX,iVar3,
                 iVar3,iVar2 >> 8);
    return;
  }
  piStack_2c = (int *)((&DAT_00a52ee8)[iVar2 - 0xa0U & 0x1ff] * 3 >> 10);
  if (0xff < (int)piStack_2c) {
    piStack_2c = (int *)0xff;
  }
  piVar1 = (int *)(param_1 + 0x28);
  uStack_34 = 0;
  puStack_48 = &uStack_34;
  (**(code **)**(undefined4 **)(param_1 + 0x78))();
  uVar7 = 0xffffffff;
  (**(code **)(*piVar1 + 8))(unaff_EBX,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x50) + unaff_ESI * 4) = 0;
  puVar6 = &stack0xffffffc4;
  (**(code **)(**(int **)(*(int *)(param_1 + 0x88) + 4 + unaff_ESI * 8) + 0x38))(&iStack_30);
  iVar2 = *(int *)(param_1 + 0x10) * 5;
  iVar2 = iVar2 + (iVar2 >> 0x1f & 7U);
  iStack_30 = (int)(CONCAT44(iVar2 >> 0x1f,iVar2 >> 3) % (longlong)unaff_EDI);
  piVar4 = DAT_005f3004;
  piVar5 = DAT_005f3008;
  if ((*(byte *)(param_1 + 0x1d) & 0x40) != 0) {
    piVar4 = DAT_005f3008;
    piVar5 = DAT_005f3004;
  }
  iStack_28 = (iStack_30 + (int)piVar5) % unaff_EDI;
  uStack_34 = 0;
  piStack_2c = piVar4;
  if (iStack_28 < iStack_30) {
    uStack_24 = 0;
    uStack_20 = 0;
    puStack_48 = (undefined4 *)0x0;
    piStack_1c = piVar4;
    iStack_18 = iStack_28;
    (**(code **)**(undefined4 **)(param_1 + 0x78))(&puStack_48);
    (**(code **)(*piVar1 + 8))(uVar7,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x50) + (int)puVar6 * 4) = 0;
    puStack_48 = (undefined4 *)*piStack_1c;
    (*(code *)puStack_48[6])
              (*(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + (int)puVar6 * 8),
               *(int *)(param_1 + 0x14) - (int)piVar4 / 2,
               ((*(int *)(param_1 + 0x18) - (int)piVar5 / 2) - unaff_EBP) + unaff_EBX,uVar7,
               &iStack_30,0,0);
    iStack_28 = unaff_EDI;
  }
  puStack_48 = (undefined4 *)0x0;
  (**(code **)**(undefined4 **)(param_1 + 0x78))(&puStack_48);
  (**(code **)(*piVar1 + 8))(uVar7,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x50) + (int)puVar6 * 4) = 0;
  piStack_1c = (int *)*piStack_1c;
  (**(code **)((int)piStack_1c + 0x18))
            (*(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + (int)puVar6 * 8),
             *(int *)(param_1 + 0x14) - (int)piVar4 / 2,*(int *)(param_1 + 0x18) - (int)piVar5 / 2,
             uVar7,&stack0xffffffc0,0,0);
  return;
}


//// FUNC 00487040 FUN_00487040

undefined4 __fastcall FUN_00487040(int param_1)

{
  if ((*(char *)(param_1 + 0x10) != '\0') && (*(int *)(param_1 + 0x14) < 0xf8)) {
    return 1;
  }
  return 0;
}


//// FUNC 00487060 FUN_00487060

void __fastcall FUN_00487060(int param_1)

{
  int iVar1;
  
  if ((*(char *)(param_1 + 0x10) == '\0') && (0x7f < *(int *)(param_1 + 0x14))) {
    iVar1 = 0;
  }
  else {
    iVar1 = 1;
  }
  iVar1 = *(int *)(param_1 + 0x14) + iVar1 * 8;
  *(int *)(param_1 + 0x14) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x181;
  if (iVar1 == 0x88) {
    FUN_005c03d0(0x1000000c,0);
  }
  return;
}


//// FUNC 004870b0 FUN_004870b0

void __thiscall FUN_004870b0(int param_1,undefined4 param_2)

{
  int *piVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int unaff_EBX;
  int iVar5;
  int *piVar6;
  int unaff_EBP;
  int iVar7;
  undefined4 unaff_ESI;
  int *unaff_EDI;
  undefined4 uVar8;
  undefined4 uVar9;
  undefined4 uVar10;
  int iStack_30;
  int *piStack_2c;
  undefined4 uStack_18;
  int iStack_14;
  int aiStack_10 [2];
  undefined4 uStack_8;
  
  iVar2 = *(int *)(param_1 + 0x14);
  iVar7 = iVar2 + -0x80;
  if (0 < iVar7) {
    iStack_14 = (int)(&DAT_00a52ee8)[iVar2 - 0x100U & 0x1ff] >> 8;
    if (0xff < iStack_14) {
      iStack_14 = 0xff;
    }
    iVar5 = iStack_14;
    if (iVar7 < 0x80) {
      iStack_14 = 0;
      piStack_2c = &iStack_14;
      iStack_30 = 0x487113;
      (**(code **)**(undefined4 **)(param_1 + 0x78))();
      iStack_30 = -1;
      (**(code **)(*(int *)(param_1 + 0x28) + 8))(uStack_18);
      iStack_30 = 0x10000;
      *(undefined4 *)(*(int *)(param_1 + 0x50) + iStack_14 * 4) = 0;
      uVar10 = *(undefined4 *)(param_1 + 0x20);
      uVar9 = *(undefined4 *)(param_1 + 0x1c);
      iVar3 = ((*(ushort *)(param_1 + 0x24) & 0x4000) >> 0xe) << 7;
      uVar8 = *(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + iStack_14 * 8);
      piStack_2c = (int *)iVar5;
    }
    else {
      iVar3 = (((*(ushort *)(param_1 + 0x24) & 0x4000) >> 0xe) - 3) * 0x80 + iVar7 * 3;
      aiStack_10[0] = 0;
      piStack_2c = aiStack_10;
      iStack_30 = 0x4871a1;
      (**(code **)**(undefined4 **)(param_1 + 0x78))();
      iStack_30 = -1;
      (**(code **)(*(int *)(param_1 + 0x28) + 8))(iStack_14);
      *(undefined4 *)(*(int *)(param_1 + 0x50) + unaff_EBX * 4) = 0;
      FUN_00422c00(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + unaff_EBX * 8),
                   *(undefined4 *)(param_1 + 0x1c),*(undefined4 *)(param_1 + 0x20),
                   iVar3 - (iVar2 + -0x100) / 2,unaff_ESI,unaff_ESI,unaff_EBP / 2);
      unaff_EBX = 0;
      (**(code **)**(undefined4 **)(param_1 + 0x78))(&stack0xffffffe4);
      (**(code **)(*(int *)(param_1 + 0x28) + 8))(unaff_EBP,0xffffffff);
      piStack_2c = (int *)iStack_14;
      *(undefined4 *)(*(int *)(param_1 + 0x50) + aiStack_10[0] * 4) = 0;
      uVar10 = *(undefined4 *)(param_1 + 0x20);
      uVar9 = *(undefined4 *)(param_1 + 0x1c);
      uVar8 = *(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + aiStack_10[0] * 8);
      iStack_30 = (0x180 - iVar7) * 0x100;
    }
    FUN_00422c00(param_2,uVar8,uVar9,uVar10,iVar3,iStack_30);
  }
  if (iVar7 < 0) {
    uVar4 = *(int *)(param_1 + 0x14) - 0x80U & 0x1ff;
    *(int *)(param_1 + 0x18) =
         *(int *)(param_1 + 0x18) + ((int)((&DAT_00a52ee8)[uVar4] << 2) >> 0x10);
    iVar5 = (&DAT_00a52ee8)[uVar4] << 7;
  }
  else {
    if (iVar7 == 0) {
      iVar5 = 0x80;
      *(int *)(param_1 + 0x18) = *(int *)(param_1 + 0x18) + 4;
      goto LAB_00487307;
    }
    *(int *)(param_1 + 0x18) =
         *(int *)(param_1 + 0x18) +
         ((int)((&DAT_00a52ee8)[iVar7 / 2 - 0x80U & 0x1ff] << 2) >> 0x10) + 4;
    iVar5 = (&DAT_00a52ee8)[iVar7 / 2 & 0x1ff] * 0xb0;
  }
  iVar5 = iVar5 >> 0x10;
LAB_00487307:
  piVar1 = (int *)(param_1 + 0x28);
  aiStack_10[0] = 1;
  piStack_2c = aiStack_10;
  iStack_30 = 0x48731e;
  (**(code **)**(undefined4 **)(param_1 + 0x78))();
  iStack_30 = -1;
  (**(code **)(*piVar1 + 8))(iStack_14);
  *(undefined4 *)(*(int *)(param_1 + 0x50) + unaff_EBX * 4) = 0;
  FUN_00422c00(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + unaff_EBX * 8),
               *(undefined4 *)(param_1 + 0x1c),*(undefined4 *)(param_1 + 0x20),
               -*(int *)(param_1 + 0x18),unaff_ESI,unaff_ESI,iVar5);
  if (0 < iVar7) {
    (**(code **)**(undefined4 **)(param_1 + 0x78))(&stack0xffffffe4);
    iVar5 = -1;
    (**(code **)(*piVar1 + 8))(unaff_EBP);
    *(undefined4 *)(*(int *)(param_1 + 0x50) + (int)unaff_EDI * 4) = 0;
    (**(code **)(**(int **)(*(int *)(param_1 + 0x88) + 4 + (int)unaff_EDI * 8) + 0x38))
              (&stack0xffffffe4,&stack0xffffffe0);
    iVar2 = (int)(&DAT_00a52ee8)[iVar2 - 0x100U & 0x1ff] >> 8;
    if (0xff < iVar2) {
      iVar2 = 0xff;
    }
    piVar6 = (int *)(param_1 + 0xb4);
    piStack_2c = (int *)0x8;
    do {
      uVar4 = (int)(iVar7 + (iVar7 >> 0x1f & 7U)) >> 3;
      if (-1 < iVar7) {
        iStack_30 = (uVar4 & 1) + 2;
        (**(code **)**(undefined4 **)(param_1 + 0x78))(&iStack_30);
        (**(code **)(*piVar1 + 8))(iVar2,0xffffffff);
        *(undefined4 *)(*(int *)(param_1 + 0x50) + iVar5 * 4) = 0;
        (**(code **)(*unaff_EDI + 0xb0))
                  (*(undefined4 *)(*(int *)(param_1 + 0x88) + 4 + iVar5 * 8),*piVar6 - iStack_30 / 2
                   ,(piVar6[1] - ((int)(uVar4 * uVar4 + ((int)(uVar4 * uVar4) >> 0x1f & 0xfU)) >> 4)
                    ) - iVar2 / 2,unaff_EBP,0,0,0);
      }
      iVar7 = iVar7 + -0x10;
      piVar6 = piVar6 + 2;
      piStack_2c = (int *)((int)piStack_2c + -1);
    } while (piStack_2c != (int *)0x0);
  }
  return;
}


