//// FUNC 00418b60 FUN_00418b60 size=688

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_00418b60(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  uint uVar7;
  undefined8 uVar8;
  int local_4;
  
  if (*(char *)(param_1 + 0x22) == '\0') {
    uVar1 = *(ushort *)(param_1 + 0x24);
    uVar8 = FUN_0045c140(uVar1 & 1,(uVar1 & 0x3e) >> 1,uVar1 >> 6 & 0xff);
    *(undefined8 *)(param_1 + 0x38) = uVar8;
  }
  if (*(int *)(param_1 + 0x14) == 0x100) {
    *(undefined4 *)(param_1 + 0x30) = *(undefined4 *)(param_1 + 0x38);
    uVar1 = *(ushort *)(param_1 + 0x24);
    *(undefined4 *)(param_1 + 0x34) = *(undefined4 *)(param_1 + 0x3c);
    *(ushort *)(param_1 + 0x26) = uVar1;
    if (*(char *)(param_1 + 0x21) == '\0') {
      iVar6 = ((uVar1 >> 0xe & 1) + ((byte)~DAT_00a54e5c & 1 ^ ~(uint)uVar1 & 1) * 2) * 0x80;
    }
    else {
      iVar6 = 0;
    }
    *(int *)(param_1 + 0x40) = iVar6;
    if (*(int *)(param_1 + 0x18) < 1) {
      return;
    }
    if (5 < *(int *)(param_1 + 0x18)) {
      return;
    }
    iVar6 = *(int *)(param_1 + 0x1c) + -0x10;
    *(int *)(param_1 + 0x1c) = iVar6;
    if (iVar6 != 0) {
      return;
    }
    *(undefined4 *)(param_1 + 0x18) = 0;
    *(undefined4 *)(param_1 + 0x1c) = 0;
    return;
  }
  iVar6 = *(int *)(param_1 + 0x14) + 0x20;
  *(int *)(param_1 + 0x14) = iVar6;
  uVar1 = *(ushort *)(param_1 + 0x26);
  local_4 = 0;
  iVar3 = (DAT_005f3008 << 0x10) / (DAT_005f3000 / 2);
  if ((uVar1 & 0x3e) == 0x16) {
LAB_00418c0f:
    if ((*(byte *)(param_1 + 0x24) & 0x3e) != 0x16) {
      iVar3 = (iVar3 + -0x10000) * iVar6;
      *(int *)(param_1 + 0x44) = ((int)(iVar3 + (iVar3 >> 0x1f & 0xffU)) >> 8) + 0x10000;
      goto LAB_00418c48;
    }
  }
  else {
    if ((*(byte *)(param_1 + 0x24) & 0x3e) == 0x16) {
      iVar4 = (0x10000 - iVar3) * iVar6;
      *(int *)(param_1 + 0x44) = ((int)(iVar4 + (iVar4 >> 0x1f & 0xffU)) >> 8) + iVar3;
      goto LAB_00418c48;
    }
    if ((uVar1 & 0x3e) == 0x16) goto LAB_00418c0f;
  }
  *(undefined4 *)(param_1 + 0x44) = 0x10000;
  local_4 = 1;
LAB_00418c48:
  uVar2 = *(ushort *)(param_1 + 0x24);
  uVar7 = ((uVar1 >> 0xe & 1) + ((~(uint)uVar1 ^ ~_DAT_00a54e5c & 0xffff) & 1) * 2) * 0x80;
  uVar5 = ((uVar2 >> 0xe & 1) + ((~(uint)uVar2 ^ ~_DAT_00a54e5c & 0xffff) & 1) * 2) * 0x80;
  if (*(char *)(param_1 + 0x21) != '\0') {
    uVar5 = 0;
    uVar7 = 0;
  }
  if ((uVar5 ^ uVar7) == 0) {
    *(uint *)(param_1 + 0x40) = uVar5;
    local_4 = local_4 + 1;
  }
  else if ((uVar5 ^ uVar7) == 0x100) {
    *(uint *)(param_1 + 0x40) = uVar7 + iVar6 & 0x1ff;
  }
  else if ((uVar5 - uVar7 & 0x1ff) < 0x101) {
    *(uint *)(param_1 + 0x40) = iVar6 / 2 + uVar7 & 0x1ff;
  }
  else {
    *(uint *)(param_1 + 0x40) = uVar7 - iVar6 / 2 & 0x1ff;
  }
  if (((uVar1 ^ *(ushort *)(param_1 + 0x24)) & 0x8000) == 0) {
    local_4 = local_4 + 1;
    *(uint *)(param_1 + 0x48) = (uint)(uVar2 >> 0xf) << 8;
  }
  else if ((*(ushort *)(param_1 + 0x24) & 0x8000) == 0) {
    *(int *)(param_1 + 0x48) = 0x100 - iVar6;
  }
  else {
    *(int *)(param_1 + 0x48) = iVar6;
  }
  iVar3 = *(int *)(param_1 + 0x28);
  iVar4 = *(int *)(param_1 + 0x38);
  if ((iVar3 == iVar4) && (*(int *)(param_1 + 0x2c) == *(int *)(param_1 + 0x3c))) {
    *(int *)(param_1 + 0x30) = iVar4;
    local_4 = local_4 + 1;
    *(undefined4 *)(param_1 + 0x34) = *(undefined4 *)(param_1 + 0x3c);
  }
  else {
    uVar5 = iVar6 / 2 - 0x80U & 0x1ff;
    *(int *)(param_1 + 0x30) = ((iVar4 - iVar3) * (&DAT_00a52ee8)[uVar5] >> 0x10) + iVar3;
    *(int *)(param_1 + 0x34) =
         ((*(int *)(param_1 + 0x3c) - *(int *)(param_1 + 0x2c)) * (&DAT_00a52ee8)[uVar5] >> 0x10) +
         *(int *)(param_1 + 0x2c);
  }
  if (local_4 != 4) {
    return;
  }
  *(undefined4 *)(param_1 + 0x14) = 0x100;
  return;
}



//// FUNC 00418ef0 FUN_00418ef0 size=1493

void __thiscall FUN_00418ef0(int *param_1,undefined4 param_2)

{
  ushort uVar1;
  byte bVar2;
  int *piVar3;
  int iVar4;
  int iVar5;
  uint uVar6;
  uint uVar7;
  uint *puVar8;
  int unaff_EBX;
  int unaff_EBP;
  int iVar9;
  undefined4 *unaff_ESI;
  int *piVar10;
  int iVar11;
  int **ppiStack_38;
  undefined4 *puStack_34;
  undefined4 local_20;
  int *local_1c;
  int *local_18;
  int iStack_14;
  int iStack_c;
  int *local_4;
  
  if ((char)param_1[8] != '\0') {
    local_4 = (int *)param_1[0xd];
    iVar9 = param_1[0xc];
    if (param_1[6] == 5) {
      if ((*(byte *)(param_1 + 9) & 0x3e) == 0x16) {
        puStack_34 = (undefined4 *)
                     (((int)(param_1[0x10] + (param_1[0x10] >> 0x1f & 0x7fU)) >> 7) * 0x5a);
        ppiStack_38 = (int **)0x418f52;
        piVar3 = (int *)FUN_0041f130();
      }
      else {
        puStack_34 = (undefined4 *)
                     (((int)(param_1[0x10] + (param_1[0x10] >> 0x1f & 0x7fU)) >> 7) * 0x5a);
        ppiStack_38 = (int **)0x418f84;
        piVar3 = (int *)FUN_0041f2e0();
      }
      puStack_34 = &local_20;
      ppiStack_38 = &local_1c;
      local_18 = piVar3;
      (**(code **)(*piVar3 + 0x38))();
      if (((byte)*(ushort *)(param_1 + 9) & 0x3e) != 0x16) {
        iVar4 = ((int)(&DAT_00a52ee8)[param_1[7] / 2 - 0x80U & 0x1ff] >> 1) + 0x10000;
        if ((int)(&DAT_00a52ee8)[param_1[7] & 0x1ff] < 0) {
          iStack_14 = 0;
        }
        else {
          iStack_14 = (int)(&DAT_00a52ee8)[param_1[7] & 0x1ff] >> 8;
        }
        iVar5 = iVar4 * unaff_EBP;
        iVar4 = iVar4 * unaff_EBX;
        local_18 = (int *)(iVar5 >> 0x10);
        local_1c = (int *)(iVar4 >> 0x10);
        (**(code **)(*local_4 + 0x18))
                  (piVar3,iVar9 - ((int)local_1c - (iVar4 >> 0x1f) >> 1),
                   iStack_c - ((int)local_18 - (iVar5 >> 0x1f) >> 1),iStack_14,0);
        return;
      }
      iStack_14 = (&DAT_00a52ee8)[param_1[7] / 2 - 0x80U & 0x1ff];
      (**(code **)(*local_4 + 0xc))
                (local_20,(((DAT_005db570 - iVar9) * iStack_14 * 2 >> 0x10) - unaff_EBX / 2) + iVar9
                 ,(((int)((((byte)~DAT_00a54e5c & 1 ^ ~(uint)*(ushort *)(param_1 + 9) & 1) * -2 + 1)
                          * iStack_14 * unaff_EBP) >> 0x10) - unaff_EBP / 2) + iStack_c,0);
      if (param_1[7] == 0x100) {
        (**(code **)(*param_1 + 0x10))
                  ((&DAT_00a56434)
                   [(*(ushort *)(param_1 + 9) & 1) * 0x351 + (*(ushort *)(param_1 + 9) >> 6 & 0xff)]
                   & 0xfff);
        return;
      }
    }
    else {
      if (param_1[5] != 0x100) {
        if (((*(byte *)((int)param_1 + 0x26) & 0x3e) == 0x16) ||
           ((*(byte *)(param_1 + 9) & 0x3e) == 0x16)) {
          puStack_34 = (undefined4 *)0x0;
          ppiStack_38 = (int **)0x41917d;
          piVar3 = (int *)FUN_0041f130();
        }
        else {
          puStack_34 = (undefined4 *)0x0;
          ppiStack_38 = (int **)0x419161;
          piVar3 = (int *)FUN_0041f2e0();
        }
        uVar7 = param_1[0x12];
        uVar6 = uVar7;
        if (0x80 < (int)uVar7) {
          uVar6 = 0x100 - uVar7;
        }
        ppiStack_38 = (int **)param_1[0x11];
        if (((ppiStack_38 == (int **)0x10000) && (param_1[0x10] == 0)) && ((char)uVar7 == '\0')) {
          puStack_34 = &local_20;
          ppiStack_38 = &local_1c;
          (**(code **)(*piVar3 + 0x38))();
          FUN_004ad9c0(piVar3,iVar9 - unaff_EBX / 2,iStack_c - unaff_EBP / 2,0);
          return;
        }
        puStack_34 = (undefined4 *)0x0;
        MulDiv((int)ppiStack_38,(&DAT_00a52ee8)[uVar6 & 0x1ff],0x10000);
        FUN_00422a20(param_2,piVar3,iVar9,local_4);
        return;
      }
      if (param_1[6] == 2) {
        iVar4 = param_1[7];
        uVar7 = (int)(iVar4 + (iVar4 >> 0x1f & 0xfU)) >> 4;
        if ((uVar7 & 1) != 0) {
          uVar7 = -((int)(iVar4 + (iVar4 >> 0x1f & 0xfU)) >> 4);
        }
        iVar9 = iVar9 + (int)uVar7 / 2;
      }
      if ((*(byte *)(param_1 + 9) & 0x3e) == 0x16) {
        puStack_34 = (undefined4 *)
                     (((int)(param_1[0x10] + (param_1[0x10] >> 0x1f & 0x7fU)) >> 7) * 0x5a);
        ppiStack_38 = (int **)0x419298;
        piVar3 = (int *)FUN_0041f130();
      }
      else {
        puStack_34 = (undefined4 *)
                     (((int)(param_1[0x10] + (param_1[0x10] >> 0x1f & 0x7fU)) >> 7) * 0x5a);
        ppiStack_38 = (int **)0x4192c4;
        piVar3 = (int *)FUN_0041f2e0();
      }
      puStack_34 = &local_20;
      ppiStack_38 = &local_1c;
      (**(code **)(*piVar3 + 0x38))();
      piVar10 = local_4;
      iVar11 = 0;
      iVar5 = 0;
      iVar4 = 0;
      FUN_004ad9c0(piVar3,iVar9 - unaff_EBX / 2,iStack_c - unaff_EBP / 2);
      if (param_1[6] == 1) {
        bVar2 = (byte)((int)(param_1[7] + (param_1[7] >> 0x1f & 0x1fU)) >> 5) & 1;
      }
      else {
        bVar2 = 0;
      }
      if ((DAT_005f2fdc == param_1) || (bVar2 != 0)) {
        if ((DAT_005f2fe0 != '\0') || (bVar2 != 0)) {
          (**(code **)(*piVar10 + 0xac))(piVar3,iVar9 - iVar11 / 2,unaff_EBX - iVar5 / 2,0x40,0,0,0)
          ;
        }
        uVar1 = *(ushort *)(param_1 + 9);
        uVar7 = ~(uint)uVar1 & 1 ^ (byte)~DAT_00a54e5c & 1;
        if ((((((byte)uVar1 ^ DAT_00a54e5c) & 1) == 0) || ((uVar1 & 0x8000) != 0)) &&
           (((byte)uVar1 & 0x3e) < 0x20)) {
          puVar8 = (uint *)FUN_005700f0(uVar1 & 1,uVar1 >> 1 & 0x1f,uVar1 >> 6 & 0xff);
          uVar7 = ~*puVar8 >> 0xc & 1 ^ (byte)~DAT_00a54e5c & 1;
        }
        piVar3 = DAT_005f2fd8;
        ppiStack_38 = (int **)((uint)((*(byte *)(param_1 + 9) & 0x3e) == 0x16) + uVar7 * 2);
        (*(code *)**(undefined4 **)DAT_005f2fd8[0x14])(&ppiStack_38);
        (**(code **)(*piVar3 + 8))(iVar11,0xffffffff);
        *(undefined4 *)(piVar3[10] + iVar4 * 4) = 0;
        piVar3 = *(int **)(piVar3[0x18] + 4 + iVar4 * 8);
        (**(code **)(*piVar3 + 0x38))(&ppiStack_38,&stack0xffffffc0);
        if ((*(byte *)((int)param_1 + 0x25) & 0x40) == 0) {
          FUN_004b1760(piVar3,iVar9 - (int)unaff_ESI / 2,unaff_EBX - (int)puStack_34 / 2,0,0,0);
          piVar10 = local_1c;
        }
        else {
          iVar4 = (int)puStack_34 / 2;
          puStack_34 = unaff_ESI;
          FUN_00422540(local_1c,piVar3,iVar9 - iVar4,unaff_EBX - (int)unaff_ESI / 2,0x5a,0x10000);
          piVar10 = local_1c;
        }
      }
      FUN_004194d0(piVar10);
    }
  }
  return;
}



//// FUNC 0045c140 FUN_0045c140 size=303

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int FUN_0045c140(uint param_1,undefined4 param_2,int param_3)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  
  uVar2 = (uint)(param_1 == ((byte)~(byte)_DAT_00a54e5c & 1));
  switch(param_2) {
  case 0xb:
    if (param_3 < (int)(&DAT_005f32c8)[param_1]) {
      return *(int *)((&DAT_005f32ac)[param_1 * 4] + param_3 * 8);
    }
    return *(int *)(&DAT_005db608 + uVar2 * 8);
  case 0xc:
    if (param_3 == 0) {
      iVar1 = FUN_0045c280(param_1,param_2,0);
      return iVar1;
    }
    iVar1 = *(int *)(&DAT_005db5d0 + uVar2 * 8);
    iVar3 = *(int *)(&DAT_005f32e8 + param_1 * 4);
    if (param_1 == (_DAT_00a54e5c & 1)) {
      return iVar1 - iVar3;
    }
    break;
  case 0xd:
    if (param_3 != 0) {
      iVar1 = FUN_0045c280(param_1,param_2,param_3);
      return iVar1;
    }
    iVar1 = *(int *)(&DAT_005db5b0 + uVar2 * 8);
    iVar3 = *(int *)(&DAT_005f32d8 + param_1 * 4);
    if (param_1 != (_DAT_00a54e5c & 1)) {
      return iVar1 - iVar3;
    }
    break;
  case 0xe:
    if (param_3 == 0) {
      iVar1 = FUN_0045c280(param_1,param_2,0);
      return iVar1;
    }
    iVar1 = *(int *)(&DAT_005db5c0 + uVar2 * 8);
    iVar3 = *(int *)(&DAT_005f32e0 + param_1 * 4);
    if (param_1 != (_DAT_00a54e5c & 1)) {
      iVar3 = -iVar3;
    }
    break;
  default:
    iVar1 = FUN_0045c280(param_1,param_2,param_3);
    return iVar1;
  }
  return iVar1 + iVar3;
}


