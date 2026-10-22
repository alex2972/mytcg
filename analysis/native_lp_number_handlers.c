//// FUNC 0047c4b0 FUN_0047c4b0

undefined4 __fastcall FUN_0047c4b0(int param_1)

{
  if ((0xff < *(int *)(param_1 + 0x34)) &&
     ((*(char *)(param_1 + 0x30) != '\0' || (*(int *)(param_1 + 0x28) == 0)))) {
    return 0;
  }
  return 1;
}


//// FUNC 0047c560 FUN_0047c560

void __fastcall FUN_0047c560(int param_1)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  bool bVar4;
  undefined4 uVar5;
  
  uVar2 = *(uint *)(param_1 + 0x28);
  *(uint *)(param_1 + 0x38) = (*(int *)(param_1 + 0x3c) != 0) + 1 + *(int *)(param_1 + 0x38) & 0x7f;
  bVar4 = (int)uVar2 < 0;
  iVar3 = (uVar2 ^ (int)uVar2 >> 0x1f) - ((int)uVar2 >> 0x1f);
  if (*(int *)(param_1 + 0x34) < 0x100) {
    *(int *)(param_1 + 0x34) = *(int *)(param_1 + 0x34) + 8;
  }
  else if (*(char *)(param_1 + 0x30) == '\0') {
    if (iVar3 < 100) {
      if (iVar3 < 10) {
        if (iVar3 < 1) goto LAB_0047c612;
        iVar3 = iVar3 + -1;
        uVar5 = *(undefined4 *)(param_1 + 0x20);
        iVar1 = (-(uint)bVar4 & 0xfffffffe) + 1;
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar1;
      }
      else {
        iVar3 = iVar3 + -10;
        iVar1 = (-(uint)bVar4 & 0xffffffec) + 10;
        uVar5 = *(undefined4 *)(param_1 + 0x20);
        *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar1;
      }
    }
    else {
      iVar3 = iVar3 + -100;
      uVar5 = *(undefined4 *)(param_1 + 0x20);
      iVar1 = (-(uint)bVar4 & 0xffffff38) + 100;
      *(int *)(param_1 + 0x24) = *(int *)(param_1 + 0x24) + iVar1;
    }
    FUN_00573fb0(uVar5,iVar1);
  }
LAB_0047c612:
  uVar2 = (int)*(uint *)(param_1 + 0x28) >> 0x1f;
  if (iVar3 != (*(uint *)(param_1 + 0x28) ^ uVar2) - uVar2) {
    *(undefined4 *)(param_1 + 0x3c) = 0x1f;
  }
  if (bVar4) {
    iVar3 = -iVar3;
  }
  *(int *)(param_1 + 0x28) = iVar3;
  uVar2 = *(uint *)(param_1 + 0x24) & ((int)*(uint *)(param_1 + 0x24) < 0) - 1;
  *(uint *)(param_1 + 0x24) = uVar2;
  if (0xffff < (int)uVar2) {
    uVar2 = 0xffff;
  }
  *(uint *)(param_1 + 0x24) = uVar2;
  *(uint *)(param_1 + 0x3c) = *(int *)(param_1 + 0x3c) - (uint)(0 < *(int *)(param_1 + 0x3c));
  return;
}


//// FUNC 0047c660 FUN_0047c660

/* WARNING: Restarted to delay deadcode elimination for space: stack */

void __thiscall FUN_0047c660(int param_1,int *param_2)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  uint *puVar4;
  int iVar5;
  undefined4 uVar6;
  int *piVar7;
  uint uVar8;
  int unaff_EBX;
  undefined4 unaff_EBP;
  int *piVar9;
  int unaff_EDI;
  int iStack_94;
  undefined1 *puStack_90;
  int *piStack_8c;
  uint uStack_88;
  int iStack_84;
  int *piStack_80;
  uint *puStack_7c;
  int *apiStack_78 [2];
  int iStack_70;
  int iStack_6c;
  int iStack_68;
  uint uStack_64;
  int iStack_60;
  int iStack_5c;
  int *piStack_44;
  int *apiStack_40 [2];
  int iStack_38;
  int iStack_34;
  undefined8 uStack_28;
  undefined4 uStack_1c;
  
  iVar1 = *(int *)(param_1 + 0x10);
  uStack_64 = *(uint *)(param_1 + 0x20);
  piVar9 = (int *)(iVar1 + 0x80);
  uVar8 = (uint)(uStack_64 == ((byte)~DAT_00a54e5c & 1));
  if (*(int *)(param_1 + 0x28) != 0) {
    iStack_60 = *(int *)(param_1 + 0x2c);
    if (iStack_60 < 0) {
      iStack_5c = 2;
      iStack_60 = 5;
    }
    else {
      iStack_5c = 0;
    }
    iStack_68 = 0x47c6b0;
    uStack_28 = FUN_0045c140();
    iVar5 = (0 < *(int *)(param_1 + 0x28)) + 6;
    iStack_60 = 0x47c6db;
    iStack_5c = iVar5;
    uVar6 = FUN_00417f40();
    *(undefined4 *)(param_1 + 0x18) = uVar6;
    iVar5 = *(int *)(*(int *)(DAT_005f33ec + 8) + 4 + iVar5 * 8);
    *(int *)(param_1 + 0x1c) = iVar5;
    if (iVar5 == 0) {
      iVar5 = 10;
    }
    *(int *)(param_1 + 0x1c) = iVar5;
    uStack_64 = *(uint *)(param_1 + 0x28);
    iStack_5c = 0;
    iStack_60 = 1;
    iStack_68 = 0x47c70c;
    iVar5 = FUN_00480230();
    uStack_28._0_4_ = (int)uStack_28 + iVar5 / 2;
    iStack_5c = 0x47c722;
    iVar5 = FUN_004801e0();
    iStack_6c = uStack_28._4_4_ - iVar5 / 2;
    iStack_68 = *(undefined4 *)(param_1 + 0x28);
    iStack_5c = 0;
    iStack_60 = 1;
    uStack_64 = *(int *)(param_1 + 0x34) << 1;
    iStack_70 = (int)uStack_28;
    apiStack_78[1] = param_2;
    apiStack_78[0] = (int *)0x47c74d;
    FUN_004806f0();
  }
  iStack_5c = 0;
  iStack_60 = 0;
  uStack_64 = 0;
  iStack_6c = *(int *)(*(int *)(iVar1 + 0x88) + 4 + (uVar8 + 3) * 8);
  iVar5 = *param_2;
  iStack_68 = iStack_6c % 1000;
  iStack_6c = iStack_6c / 1000;
  iStack_70 = uVar8 + 3;
  apiStack_78[1] = (int *)0x47c793;
  iStack_70 = FUN_00417f40();
  apiStack_78[1] = (int *)0x47c799;
  (**(code **)(iVar5 + 0xc))();
  uVar8 = iStack_60 + 5;
  apiStack_78[0] = (int *)0x47c7a8;
  apiStack_78[1] = (int *)uVar8;
  piVar7 = (int *)FUN_00417f40();
  apiStack_78[1] = (int *)&stack0xffffffa8;
  apiStack_78[0] = (int *)&stack0xffffffac;
  puStack_7c = (uint *)0x47c7b9;
  (**(code **)(*piVar7 + 0x38))();
  iVar5 = *(int *)(param_1 + 0x24);
  if (8000 < iVar5) {
    iVar5 = 8000;
  }
  apiStack_40[0] = (int *)0x0;
  apiStack_40[1] = (int *)0x0;
  iStack_38 = (iVar5 * iStack_5c) / 8000;
  iStack_34 = iStack_60;
  uStack_1c = *(undefined4 *)(*(int *)(iVar1 + 0x88) + 4 + uVar8 * 8);
  puStack_7c = &uStack_64;
  piStack_80 = (int *)0x47c811;
  uStack_64 = uVar8;
  (**(code **)**(undefined4 **)(iVar1 + 0xd0))();
  piStack_80 = (int *)0xffffffff;
  iStack_84 = iStack_68;
  uStack_88 = 0x47c81f;
  (**(code **)(*piVar9 + 8))();
  uStack_88 = 0;
  puStack_90 = &stack0xffffffb4;
  piStack_8c = (int *)0x0;
  *(undefined4 *)(*(int *)(iVar1 + 0xa8) + iStack_70 * 4) = 0;
  iStack_94 = (int)uStack_28 % 1000;
  puVar4 = (uint *)((int)uStack_28 / 1000);
  uVar6 = *(undefined4 *)(*(int *)(iVar1 + 0xe0) + 4 + iStack_70 * 8);
  (**(code **)(*param_2 + 0xc))(uVar6);
  apiStack_40[0] = (int *)0x0;
  piVar7 = *(int **)(*(int *)(iVar1 + 0x88) + 4);
  piStack_80 = piVar7;
  (**(code **)**(undefined4 **)(iVar1 + 0xd0))();
  (**(code **)(*piVar9 + 8))(piStack_44,0xffffffff);
  *(undefined4 *)(*(int *)(iVar1 + 0xa8) + unaff_EBX * 4) = 0;
  uVar2 = *(undefined4 *)(*(int *)(iVar1 + 0xe0) + 4 + unaff_EBX * 8);
  *(undefined4 *)(param_1 + 0x1c) = 10;
  *(undefined4 *)(param_1 + 0x18) = uVar2;
  if (puVar4 != (uint *)0x0) {
    piVar7 = (int *)((int)piVar7 / 1000);
  }
  FUN_004803c0(param_2,(int)piStack_8c / 1000000,(int)piVar7 % 1000,*(undefined4 *)(param_1 + 0x24),
               0,0);
  iVar5 = FUN_0044b970();
  if (iVar5 != 0) {
    iStack_60 = 0;
    iVar5 = *(int *)(*(int *)(param_1 + 0x10) + 0x114);
    iVar3 = *(int *)(iVar5 + 4);
    puStack_7c = (uint *)(iVar3 / 1000000);
    apiStack_78[0] = (int *)(iVar3 % 1000);
    apiStack_78[1] = (int *)((iVar3 / 1000) % 1000);
    iVar5 = *(int *)(iVar5 + 0xc);
    iStack_5c = iVar5 / 10000;
    unaff_EDI = (iVar5 / 100) % 100;
    uStack_88 = (uint)DAT_005f325b;
    puStack_90 = (undefined1 *)0x0;
    piStack_80 = apiStack_78[(int)puVar4];
    piStack_8c = &iStack_5c;
    do {
      if ((int)puStack_90 < (int)uStack_88) {
        if (puStack_90 == (undefined1 *)(uStack_88 - 1)) {
          if (puStack_90[0x5f3258] == 0) {
            iStack_94 = (DAT_005f2fb4 >> 4 & 1) + 1;
          }
          else {
            iStack_94 = (int)puVar4 + (uint)(byte)puStack_90[0x5f3258] * 2 + 1;
          }
        }
        else {
          iStack_94 = (int)puVar4 + (uint)(byte)puStack_90[0x5f3258] * 2 + 1;
        }
      }
      else {
        iStack_94 = 0;
      }
      iVar5 = *(int *)(param_1 + 0x10);
      (**(code **)**(undefined4 **)(iVar5 + 0x15c))(&iStack_94);
      (**(code **)(*(int *)(iVar5 + 0x10c) + 8))(puVar4,0xffffffff);
      *(undefined4 *)(*(int *)(iVar5 + 0x134) + (int)apiStack_40 * 4) = 0;
      (**(code **)(**(int **)(*(int *)(iVar5 + 0x16c) + 4 + (int)apiStack_40 * 8) + 0x38))
                (&puStack_90,&iStack_84);
      iVar5 = *(int *)(param_1 + 0x10);
      piStack_80 = piStack_44;
      apiStack_78[0] = apiStack_40[0];
      iStack_84 = 0;
      puStack_7c = puVar4;
      (**(code **)**(undefined4 **)(iVar5 + 0x15c))(&iStack_60);
      (**(code **)(*(int *)(iVar5 + 0x10c) + 8))(uStack_64,0xffffffff);
      *(undefined4 *)(*(int *)(iVar5 + 0x134) + iStack_6c * 4) = 0;
      (**(code **)(*param_2 + 8))
                (*(undefined4 *)(*(int *)(iVar5 + 0x16c) + 4 + iStack_6c * 8),uVar6,
                 (int)apiStack_40 + (int)piStack_8c,&puStack_90,0,0);
      puStack_90 = puStack_90 + 1;
      piStack_8c = piStack_8c + 1;
    } while ((int)puStack_90 < 3);
  }
  iVar5 = *(int *)(*(int *)(iVar1 + 0x88) + 0xc + (int)puVar4 * 8);
  (**(code **)**(undefined4 **)(iVar1 + 0xd0))(&stack0xffffffb4);
  (**(code **)(*piVar9 + 8))(unaff_EBP,0xffffffff);
  *(undefined4 *)(*(int *)(iVar1 + 0xa8) + unaff_EDI * 4) = 0;
  (**(code **)(*param_2 + 0x4c))
            (*(undefined4 *)(*(int *)(iVar1 + 0xe0) + 4 + unaff_EDI * 8),iVar5 / 1000,iVar5 % 1000,0
             ,0,0);
  return;
}


//// FUNC 0047c520 null
//// FUNC 0047c4c0 FUN_0047c4c0

undefined4 __fastcall FUN_0047c4c0(int param_1)

{
  if (*(int *)(param_1 + 0x28) == 0) {
    return 0;
  }
  return 1;
}


//// FUNC 0044d960 FUN_0044d960

/* WARNING: Removing unreachable block (ram,0x0044dae7) */
/* WARNING: Removing unreachable block (ram,0x0044dafb) */
/* WARNING: Removing unreachable block (ram,0x0044db1b) */
/* WARNING: Removing unreachable block (ram,0x0044db2f) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_0044d960(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  undefined **ppuStack_1c;
  int iStack_18;
  undefined ***pppuStack_14;
  undefined ***pppuStack_10;
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_005d3766;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  FUN_005664f0();
  (**(code **)(*(int *)(*(int *)(param_1 + 0xc) + 0x248) + 0x18))();
  DAT_005f3280 = param_1;
  *(undefined4 *)(param_1 + 0x1314) = 1;
  DAT_005f3254 = 0;
  *(undefined4 *)(param_1 + 0x1320) = 0;
  *(int *)(param_1 + 0x34) = *(int *)(param_1 + 0xc) + 0x38c;
  if (DAT_005f3294 == 6) {
    (**(code **)(*(int *)(param_1 + 0x1338) + 4))();
    iVar1 = FUN_0054a1d0(0x238);
    uStack_4 = 0;
    if (iVar1 == 0) {
      uVar2 = 0;
    }
    else {
      uVar2 = FUN_0048d320();
    }
    uStack_4 = 0xffffffff;
    *(undefined4 *)(param_1 + 0x133c) = uVar2;
    *(int *)(param_1 + 0x1344) = param_1 + 0x1338;
    *(int *)(param_1 + 0x1340) = param_1 + 0x1338;
  }
  if (DAT_005f3294 == 3) {
    iVar1 = FUN_0054a1d0(0x1c0);
    uStack_4 = 1;
    if (iVar1 == 0) {
      iVar1 = 0;
    }
    else {
      iVar1 = FUN_0048d8f0();
    }
    iStack_18 = 0;
    ppuStack_1c = &PTR_FUN_005da438;
    pppuStack_10 = (undefined ***)0x0;
    pppuStack_14 = (undefined ***)0x0;
    uStack_4 = 2;
    (*(code *)PTR_FUN_005da43c)();
    if (iVar1 != 0) {
      pppuStack_10 = &ppuStack_1c;
      pppuStack_14 = &ppuStack_1c;
      iStack_18 = iVar1;
    }
    FUN_0040c570(*(undefined4 *)(param_1 + 0x1330),1,&ppuStack_1c);
    ppuStack_1c = &PTR_FUN_005da438;
    uStack_4 = 3;
    FUN_00443050();
    uStack_4 = 0xffffffff;
    ppuStack_1c = &PTR_LAB_005da448;
  }
  DAT_005f32c8 = 0;
  DAT_005f32cc = 0;
  DAT_005f32b0 = DAT_005f32ac;
  DAT_005f32c0 = DAT_005f32bc;
  _DAT_005f32dc = 0;
  _DAT_005f32d8 = 0;
  _DAT_005f32e4 = 0;
  _DAT_005f32e0 = 0;
  _DAT_005f32ec = 0;
  _DAT_005f32e8 = 0;
  FUN_0041e5d0();
  FUN_0044c320();
  ExceptionList = pvStack_c;
  return;
}


//// FUNC 0044db90 FUN_0044db90

void __fastcall FUN_0044db90(int param_1)

{
  FUN_005664f0();
  (**(code **)(*(int *)(*(int *)(param_1 + 0xc) + 0x248) + 0x18))();
  return;
}


