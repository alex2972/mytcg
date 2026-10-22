//// FUNC 00450fb0 FUN_00450fb0

void __fastcall FUN_00450fb0(int param_1)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x10) + 0x10;
  *(int *)(param_1 + 0x10) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x100;
  return;
}


//// FUNC 00450fd0 FUN_00450fd0

void __fastcall FUN_00450fd0(int param_1)

{
  ushort uVar1;
  uint uVar2;
  int *piVar3;
  int *piVar4;
  undefined4 unaff_EBX;
  int iVar5;
  undefined4 unaff_EBP;
  int unaff_ESI;
  int unaff_EDI;
  int iVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  int *piStack_14;
  int *piStack_10;
  
  piStack_14 = (int *)0x0;
  (**(code **)**(undefined4 **)(param_1 + 0x70))(&piStack_14);
  iVar7 = -1;
  (**(code **)(*(int *)(param_1 + 0x20) + 8))(unaff_EBX,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x48) + unaff_ESI * 4) = 0;
  piStack_14 = *(int **)(*(int *)(param_1 + 0x80) + 4 + unaff_ESI * 8);
  (**(code **)(*piStack_14 + 0x38))(&stack0xffffffe8,&stack0xffffffe4);
  iVar5 = (int)(*(int *)(param_1 + 0x10) + (*(int *)(param_1 + 0x10) >> 0x1f & 7U)) >> 3;
  iVar6 = 0;
  piVar4 = piStack_10;
  iVar8 = iVar5;
  do {
    piVar3 = piStack_10;
    uVar2 = iVar6 / 5;
    iVar9 = iVar8;
    (**(code **)(*piVar4 + 0xac))
              (unaff_EBP,
               (((&DAT_00a52ee8)[uVar2 & 0x1ff] * iVar8 >> 0x10) - unaff_ESI / 2) +
               *(int *)(param_1 + 0x14),
               (((&DAT_00a52ee8)[uVar2 - 0x80 & 0x1ff] * iVar5 >> 0x10) - unaff_EDI / 2) +
               *(int *)(param_1 + 0x18),CONCAT31((int3)(uVar2 >> 8),-1 - *(char *)(param_1 + 0x10)),
               0,0,0);
    iVar6 = iVar6 + 0x200;
    iVar5 = iVar8;
    piVar4 = piVar3;
    iVar8 = iVar9;
  } while (iVar6 < 0xa00);
  uVar1 = *(ushort *)(param_1 + 0x1c);
  if (((byte)uVar1 & 0x3e) == 0x16) {
    piVar4 = (int *)FUN_0041f130(((uVar1 >> 0xe & 1) + ((byte)~DAT_00a54e5c & 1 ^ ~uVar1 & 1) * 2) *
                                 0x5a);
  }
  else {
    piVar4 = (int *)FUN_0041f2e0(((uVar1 >> 0xe & 1) + ((byte)~DAT_00a54e5c & 1 ^ ~uVar1 & 1) * 2) *
                                 0x5a);
  }
  (**(code **)(*piVar4 + 0x38))(&stack0xffffffe0,&stack0xffffffdc);
  FUN_00558fb0(piVar3,piVar4,*(int *)(param_1 + 0x14) - iVar9 / 2,
               *(int *)(param_1 + 0x18) - iVar7 / 2,
               0x100 - ((int)(&DAT_00a52ee8)[*(int *)(param_1 + 0x10) / 2 - 0x80U & 0x1ff] >> 8),0,
               0xff,0);
  return;
}


