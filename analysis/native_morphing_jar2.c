//// FUNC 0058c490 FUN_0058c490

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

char FUN_0058c490(uint param_1)

{
  short *psVar1;
  ushort *puVar2;
  byte bVar3;
  ushort uVar4;
  ushort uVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  undefined4 uVar9;
  int iVar10;
  uint uVar11;
  uint uVar12;
  undefined4 unaff_EDI;
  uint *puVar13;
  uint uVar14;
  bool bVar15;
  
  iVar8 = param_1;
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return '\0';
  }
  switch(DAT_00a55c88._2_2_ & 0xff) {
  case 0x78:
    uVar12 = 0;
    do {
      uVar7 = DAT_00a577f8._2_1_ & 1 ^ uVar12;
      FUN_00576170(uVar7,*(undefined2 *)(param_1 + 10 + uVar7 * 2));
      uVar12 = uVar12 + 1;
    } while ((int)uVar12 < 2);
    FUN_00579890();
  default:
    return '\0';
  case 0x7c:
    FUN_00578bb0(DAT_00a55c88._2_2_ >> 8,1,DAT_00a55c88._2_2_ >> 8 != (*(byte *)(param_1 + 2) & 1));
  case 0x7b:
    if (*(short *)(param_1 + 6 + (uint)(DAT_00a55c88._2_2_ >> 8) * 2) == 0) {
      uVar5 = (DAT_00a55c88._2_2_ >> 8) * -0x100 + 0x100;
      DAT_00a55c88._2_2_ = uVar5 ^ DAT_00a55c88._2_2_ & 0xff;
      uVar4 = DAT_00a55c88._2_2_;
      DAT_00a55c88._3_1_ = (byte)(uVar5 >> 8);
      bVar15 = DAT_00a55c88._3_1_ != (DAT_00a577f8._2_1_ & 1);
      DAT_00a55c88._2_2_ = uVar4;
      return (-bVar15 & 6U) + 0x78;
    }
    return '~';
  case 0x7d:
    uVar12 = _DAT_00a55c90 >> 0xc & 1;
    uVar9 = FUN_00567a00(_DAT_00a55c90 & 0xfff,1,0,0xd,DAT_00a55c88._2_2_ >> 8);
    FUN_005ada20(uVar12,&DAT_00a55c90,uVar9);
    bVar3 = FUN_0056a030(uVar12);
    puVar2 = (ushort *)(param_1 + 10 + uVar12 * 2);
    *puVar2 = *puVar2 | (ushort)(1 << (bVar3 & 0x1f));
    break;
  case 0x7e:
    uVar12 = (uint)(DAT_00a55c88._2_2_ >> 8);
    if ((((&DAT_00a55d68)[(uVar12 & 1) * 0x6a2] & 0xff00) != 0) &&
       (*(short *)(param_1 + 6 + uVar12 * 2) != 0)) {
      uVar7 = uVar12 & 1;
      uVar14 = CONCAT22((short)((uint)unaff_EDI >> 0x10),
                        *(undefined2 *)(&DAT_00a56574 + uVar7 * 0x351)) & 0xffff0fff;
      uVar11 = (uint)(&DAT_00a56574)[uVar7 * 0x351] >> 0xc & 1;
      FUN_00578430(uVar12,uVar14);
      iVar8 = FUN_00570be0(uVar12,&DAT_00a56574 + uVar7 * 0x351);
      if (iVar8 == 0) {
        uVar9 = FUN_004022e0(uVar14,0xd,0);
        FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar12 != 0) >> 8) & 0x80,0x20),uVar9);
      }
      FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar12 != 0) >> 8) & 0x80,0xf1),0x1e,0,0);
      iVar8 = FUN_00402690(uVar14);
      if (iVar8 != 0) {
        psVar1 = (short *)(param_1 + 6 + uVar12 * 2);
        *psVar1 = *psVar1 + -1;
        uVar5 = FUN_004026c0(uVar14);
        if (((uVar5 < 5) && (iVar8 = FUN_00570b70(uVar12,uVar14), iVar8 != 0)) &&
           ((iVar8 = FUN_0056a000(uVar11), 0 < iVar8 && ((DAT_00a55c8c >> (sbyte)uVar11 & 1) != 0)))
           ) {
          FUN_005675c0(&DAT_00a55c90,&DAT_00a56574 + uVar7 * 0x351);
          return '}';
        }
      }
      return '|';
    }
    break;
  case 0x7f:
    DAT_00a55c88._2_2_ = CONCAT11(DAT_00a577f8._2_1_,DAT_00a55c88._2_1_) & 0x1ff;
    *(undefined2 *)(param_1 + 10) = 0;
    *(undefined2 *)(param_1 + 0xc) = 0;
    bVar3 = FUN_00570b40(0);
    uVar5 = FUN_00570b40(1);
    _DAT_00a55c8c =
         CONCAT22(_DAT_00a55c8e,
                  (ushort)(bVar3 ^ DAT_00a55c8c) ^ (ushort)_DAT_00a55c8c | (uVar5 & 0x7f) << 1);
    FUN_00579810();
    return '~';
  case 0x80:
    *(undefined2 *)(param_1 + 6) = 0;
    *(undefined2 *)(param_1 + 8) = 0;
    param_1 = 0;
    do {
      iVar10 = 5;
      puVar13 = &DAT_00a55d74 + (param_1 & 1) * 0x351;
      do {
        uVar5 = (ushort)*puVar13 & 0xfff;
        iVar6 = FUN_00402690(uVar5);
        if ((iVar6 != 0) &&
           (((uVar4 = FUN_004022e0(uVar5), uVar4 < 0x780 ||
             (uVar4 = FUN_004022e0(uVar5), 0x783 < uVar4)) &&
            (iVar6 = FUN_00567ad0(uVar5), iVar6 == 0)))) {
          psVar1 = (short *)(iVar8 + 6 + (*puVar13 >> 0xc & 1) * 2);
          *psVar1 = *psVar1 + 1;
        }
        puVar13 = puVar13 + 0x24;
        iVar10 = iVar10 + -1;
      } while (iVar10 != 0);
      param_1 = param_1 + 1;
    } while ((int)param_1 < 2);
    FUN_00577aa0(iVar8,0x1f001f);
    uVar12 = 0;
    do {
      uVar7 = DAT_00a577f8._2_1_ & 1 ^ uVar12;
      if (*(short *)(iVar8 + 6 + uVar7 * 2) != 0) {
        FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar7 != 0) >> 8) & 0x80,0x60),1,0,0);
      }
      uVar12 = uVar12 + 1;
    } while ((int)uVar12 < 2);
    return '\x7f';
  }
  return '{';
}



//// FUNC 00402690 FUN_00402690 size=45

undefined4 FUN_00402690(undefined4 param_1)

{
  short sVar1;
  ushort uVar2;
  
  sVar1 = FUN_004025d0(param_1);
  if (sVar1 != 0) {
    uVar2 = FUN_004025d0(param_1);
    if (uVar2 < 0x15) {
      return 1;
    }
  }
  return 0;
}



//// FUNC 004026c0 FUN_004026c0 size=62

uint FUN_004026c0(undefined4 param_1)

{
  ushort uVar1;
  uint uVar2;
  
  uVar1 = FUN_004025d0(param_1);
  if (0x14 < uVar1) {
    if (uVar1 < 0x18) {
      return 0;
    }
    if (uVar1 == 0x18) {
      return 10;
    }
  }
  uVar2 = FUN_004025f0(param_1);
  return uVar2 >> 0x19 & 0xf;
}



//// FUNC 00567ad0 FUN_00567ad0 size=46

undefined4 FUN_00567ad0(undefined4 param_1)

{
  ushort uVar1;
  short sVar2;
  
  uVar1 = FUN_004025d0(param_1);
  if (uVar1 < 0x15) {
    sVar2 = FUN_00402740(param_1);
    if (sVar2 == 2) {
      return 1;
    }
  }
  return 0;
}



//// FUNC 00577aa0 FUN_00577aa0 size=23

void FUN_00577aa0(undefined4 param_1,undefined4 param_2)

{
  FUN_00576960(param_1,param_2,0xd,0);
  return;
}



//// FUNC 00570b40 FUN_00570b40 size=38

undefined4 FUN_00570b40(undefined4 param_1)

{
  int iVar1;
  undefined4 uVar2;
  
  iVar1 = FUN_005699a0(param_1,0x592);
  if (iVar1 != 0) {
    return 0;
  }
  uVar2 = FUN_00570af0(param_1);
  return uVar2;
}



//// FUNC 00570b70 FUN_00570b70 size=59

undefined4 FUN_00570b70(undefined4 param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = FUN_00567a00(param_2);
  if (iVar1 == 0) {
    return 1;
  }
  iVar1 = FUN_005675f0(param_2);
  if ((iVar1 != 0) && (iVar1 = FUN_00569cb0(param_1), iVar1 != 0)) {
    return 1;
  }
  return 0;
}



//// FUNC 00578bb0 FUN_00578bb0 size=331

void FUN_00578bb0(uint param_1,uint param_2,int param_3)

{
  uint uVar1;
  uint uVar2;
  ushort uVar3;
  int iVar4;
  int iVar5;
  uint *puVar6;
  
  uVar2 = param_1;
  iVar5 = 0;
  if ((int)(uint)((ushort)(&DAT_00a55d68)[(param_1 & 1) * 0x6a2] >> 8) <= (int)param_2) {
    param_2 = (uint)((ushort)(&DAT_00a55d68)[(param_1 & 1) * 0x6a2] >> 8);
  }
  iVar4 = FUN_005699c0(0x453);
  if (iVar4 != 0) {
    FUN_00578b80(param_1,param_2);
    return;
  }
  FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x62,param_2,0,param_3);
  if (0 < (int)param_2) {
    puVar6 = &DAT_00a56574 + (param_1 & 1) * 0x351;
    param_1 = param_2;
    do {
      iVar5 = iVar5 + (*puVar6 >> 0xc & 1 ^ uVar2);
      uVar3 = FUN_004022e0((ushort)*puVar6 & 0xfff);
      if (uVar3 < 0x413) {
        if (uVar3 == 0x412) goto LAB_00578c85;
        if (uVar3 == 0xc6) {
          if (param_3 != 0) goto LAB_00578c85;
        }
        else if (uVar3 == 0x1de) goto LAB_00578c85;
      }
      else {
        if (uVar3 != 0x4da) goto LAB_00578cb7;
LAB_00578c85:
        uVar1 = *puVar6;
        FUN_005ba490(uVar1 & 0xfff | uVar2 << 0x1f | 0x3a4e0000,
                     (uVar1 >> 0xc & 1) + (uVar1 >> 0x18 & 0x7f) * 2,0);
      }
LAB_00578cb7:
      puVar6 = puVar6 + 1;
      param_1 = param_1 - 1;
    } while (param_1 != 0);
  }
  FUN_0059d6e0(uVar2,param_2 - iVar5);
  FUN_0059d6e0(1 - uVar2,iVar5);
  FUN_00598590(DAT_00a577f8._2_1_ & 1,0x1d,0);
  return;
}



//// FUNC 00579810 FUN_00579810 size=119

void FUN_00579810(void)

{
  byte bVar1;
  byte bVar2;
  undefined4 local_4;
  
  if ((DAT_00a55c94 & 0x8000) == 0) {
    if (((DAT_00a577f8._2_1_ & 0x10) != 0) && (((DAT_00a54e5c ^ DAT_00a577f8._2_1_) & 1) != 0)) {
      local_4 = 1;
      FUN_005bd090(0xf058,&local_4,2);
      return;
    }
    bVar1 = (byte)DAT_00a55c94;
    bVar2 = (byte)DAT_00a55c94 + 1 ^ (byte)DAT_00a55c94;
    DAT_00a55c94._0_2_ = (ushort)DAT_00a55c94 ^ bVar2;
    if (bVar1 == 0) {
      DAT_00a55c94 = CONCAT22(DAT_00a55c94._2_2_,(ushort)DAT_00a55c94) & 0xffff80ff;
      DAT_00a55ce8._0_2_ = (ushort)DAT_00a55ce8 & 0xdfff;
    }
  }
  return;
}



//// FUNC 00576170 FUN_00576170 size=139

void FUN_00576170(uint param_1,uint param_2)

{
  uint uVar1;
  int iVar2;
  ushort *puVar3;
  int iVar4;
  
  iVar4 = 0;
  uVar1 = _rand();
  iVar2 = 0;
  puVar3 = (ushort *)(&DAT_00a55d7a + (param_1 & 1) * 0xd44);
  do {
    if ((((*(uint *)(puVar3 + -3) & 0xfff) == 0) || ((*puVar3 & 2) != 0)) || ((*puVar3 & 1) == 0)) {
      param_2 = param_2 & ~(1 << ((byte)iVar2 & 0x1f));
    }
    else {
      iVar4 = iVar4 + 1;
    }
    iVar2 = iVar2 + 1;
    puVar3 = puVar3 + 0x48;
  } while (iVar2 < 5);
  if (1 < iVar4) {
    FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0xae,uVar1,uVar1 >> 0x10,param_2);
  }
  return;
}


