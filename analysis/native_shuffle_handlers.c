//// FUNC 00453540 FUN_00453540

void __fastcall FUN_00453540(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x14) + 8;
  *(int *)(param_1 + 0x14) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x144;
  return;
}


//// FUNC 00453560 FUN_00453560

void __fastcall FUN_00453560(int param_1)

{
  int *piVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  int unaff_EBX;
  int *unaff_EBP;
  int unaff_ESI;
  bool bVar9;
  undefined8 uVar10;
  undefined4 ***pppuVar11;
  undefined1 *puVar12;
  undefined4 **ppuStack_50;
  undefined4 *puStack_4c;
  undefined1 *puStack_48;
  int iStack_44;
  undefined4 uStack_40;
  undefined4 *puStack_3c;
  undefined4 auStack_28 [8];
  int iStack_8;
  
  iVar2 = DAT_005db570;
  auStack_28[0] = 0;
  piVar1 = (int *)(param_1 + 0x18);
  puStack_3c = auStack_28;
  iStack_8 = DAT_005db570;
  uStack_40 = 0x45358f;
  (**(code **)**(undefined4 **)(param_1 + 0x68))();
  uStack_40 = 0xffffffff;
  puStack_48 = (undefined1 *)0x45359d;
  iStack_44 = unaff_EBX;
  (**(code **)(*piVar1 + 8))();
  *(undefined4 *)(*(int *)(param_1 + 0x40) + unaff_ESI * 4) = 0;
  puStack_48 = &stack0xffffffd4;
  puStack_4c = auStack_28;
  ppuStack_50 = (undefined4 **)0x4535c5;
  (**(code **)(**(int **)(*(int *)(param_1 + 0x78) + 4 + unaff_ESI * 8) + 0x38))();
  iVar3 = *(int *)(param_1 + 0x14) + (*(int *)(param_1 + 0x14) >> 0x1f & 7U);
  ppuStack_50 = &puStack_3c;
  puStack_3c = (undefined4 *)((int)(CONCAT44(iVar3 >> 0x1f,iVar3 >> 3) % 5) + 1);
  (**(code **)**(undefined4 **)(param_1 + 0x68))();
  iVar3 = -1;
  (**(code **)(*piVar1 + 8))(uStack_40,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x40) + (int)puStack_48 * 4) = 0;
  puVar12 = &stack0xffffffc8;
  (**(code **)(**(int **)(*(int *)(param_1 + 0x78) + 4 + (int)puStack_48 * 8) + 0x38))(puVar12);
  uVar4 = *(uint *)(param_1 + 0x14);
  if ((0x3f < (int)uVar4) && ((int)uVar4 < 0x101)) {
    uVar4 = uVar4 & 0x8000003f;
    bVar9 = uVar4 == 0;
    if ((int)uVar4 < 0) {
      bVar9 = (uVar4 - 1 | 0xffffffc0) == 0xffffffff;
    }
    if (bVar9) {
      FUN_005c03d0(0x1000000f,0);
    }
    ppuStack_50 = (undefined4 **)0x0;
    pppuVar11 = &ppuStack_50;
    (**(code **)**(undefined4 **)(param_1 + 0x68))(pppuVar11);
    iVar5 = iVar3;
    (**(code **)(*piVar1 + 8))(iVar3,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x40) + (int)&stack0xffffffd4 * 4) = 0;
    (**(code **)(*unaff_EBP + 0x4c))
              (*(undefined4 *)(*(int *)(param_1 + 0x78) + 4 + (int)&stack0xffffffd4 * 8),
               iVar2 - (int)ppuStack_50 / 2,300 - iVar5 / 2,0,0,0);
    (**(code **)(*unaff_EBP + 0x4c))(puVar12,iVar2 - (int)pppuVar11 / 2,0x146 - iVar3 / 2,0,0,0);
    return;
  }
  uVar10 = FUN_0045c140(*(undefined4 *)(param_1 + 0x10),0xd,0);
  puStack_4c = (undefined4 *)((ulonglong)uVar10 >> 0x20);
  iVar5 = *(int *)(param_1 + 0x14);
  if (0x100 < iVar5) {
    iVar5 = 0x140 - iVar5;
  }
  puStack_3c = (undefined4 *)(iVar5 * -4 + 0x100);
  iVar6 = ((int)uVar10 - iVar2) * (int)puStack_3c;
  ppuStack_50 = (undefined4 **)0x0;
  iVar7 = ((int)puStack_4c + -300) * (int)puStack_3c;
  iVar8 = ((iVar5 * 4) / 2 + 0x80) * iStack_44;
  (**(code **)**(undefined4 **)(param_1 + 0x68))(&ppuStack_50);
  (**(code **)(*piVar1 + 8))(iVar3,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x40) + (int)&stack0xffffffd4 * 4) = 0;
  (**(code **)(*(int *)((int)(iVar8 + (iVar8 >> 0x1f & 0xffU)) >> 8) + 0x48))
            (*(undefined4 *)(*(int *)(param_1 + 0x78) + 4 + (int)&stack0xffffffd4 * 8),
             (((int)(iVar6 + (iVar6 >> 0x1f & 0xffU)) >> 8) + iVar2) - (int)puStack_3c / 2,
             (((int)(iVar7 + (iVar7 >> 0x1f & 0xffU)) >> 8) + 300) - (iVar5 * 4) / 2,iStack_44,0,
             &puStack_3c,0);
  return;
}


