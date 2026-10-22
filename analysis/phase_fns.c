//// FUNC 005a1e50 FUN_005a1e50

undefined4 FUN_005a1e50(int param_1)

{
  uint uVar1;
  int iVar2;
  uint uVar3;
  
  uVar1 = DAT_00a57840;
  uVar3 = DAT_00a57840 >> 1 & 1;
  if ((DAT_00a57840 & 0x10) != 0) {
    return 1;
  }
  DAT_00a57840 = DAT_00a57840 | 0x10;
  iVar2 = FUN_0056c460(param_1,(uVar1 & 0x700) >> 8);
  if (iVar2 == 0) {
    iVar2 = FUN_005699a0(uVar3,0x427);
    if (0 < iVar2) {
      FUN_005b9170(-(uint)(uVar3 != 0) & 0x8000 | 0x1e,0x427,0,0);
      FUN_00578bb0(param_1,iVar2,1);
    }
    iVar2 = FUN_005699c0(0x42a);
    if (0 < iVar2) {
      FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x1e,0x42a,1,0);
      FUN_00578460(param_1,iVar2 * 500);
    }
  }
  return 1;
}


//// FUNC 005a1f30 FUN_005a1f30

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

bool FUN_005a1f30(uint param_1)

{
  uint uVar1;
  short sVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  byte bVar6;
  uint uVar7;
  uint uVar8;
  int iVar9;
  uint *puVar10;
  int iStack_4;
  
  uVar7 = DAT_00a57840 >> 1 & 1;
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    FUN_005a0e30();
    bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
    return false;
  case 1:
    iVar5 = FUN_005699c0(0x602);
    if (iVar5 != 0) {
      uVar3 = FUN_00402460(0x602,CONCAT31((uint3)(byte)((char)((uint)(&DAT_00a55d74)
                                                                     [(DAT_00a57840 >> 8 & 7) * 0x24
                                                                      + (param_1 & 1) * 0x351] >>
                                                              0x18) * '\x02' +
                                                       ((byte)((uint)(&DAT_00a55d74)
                                                                     [(DAT_00a57840 >> 8 & 7) * 0x24
                                                                      + (param_1 & 1) * 0x351] >>
                                                              0xc) & 1)),3));
      FUN_00579790(param_1,uVar3);
    }
    bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
    return false;
  case 2:
    uVar7 = 1 - param_1;
    iStack_4 = 5;
    iVar9 = 0x2d0;
    iVar5 = (uVar7 & 1) * 0xd44;
    do {
      sVar2 = FUN_004022e0(*(ushort *)((int)&DAT_00a55d74 + iVar5 + iVar9) & 0xfff);
      if (((sVar2 == 1099) &&
          (uVar8 = *(uint *)((int)&DAT_00a55e00 + iVar5 + iVar9),
          ((uint)((byte)(&DAT_00a55d7a)[iVar5 + iVar9] >> 1) & ~(uVar8 >> 5) & ~(uVar8 >> 1) & 1) !=
          0)) && (iVar4 = FUN_0056dc10(param_1,DAT_00a57840 >> 8 & 7,uVar7,iStack_4), iVar4 < 0)) {
        FUN_00578390(uVar7,*(ushort *)((int)&DAT_00a55d74 + iVar5 + iVar9) & 0xfff,iStack_4);
        FUN_005747e0(uVar7,CONCAT11((undefined1)iStack_4,(char)uVar7),
                     CONCAT11(DAT_00a57840._1_1_,(undefined1)param_1) & 0x7ff,6);
      }
      iVar9 = iVar9 + 0x90;
      iStack_4 = iStack_4 + 1;
    } while (iVar9 < 0x5a0);
    break;
  case 3:
    iVar5 = FUN_005a0f00(param_1);
    if (iVar5 != 0) {
      return false;
    }
    FUN_005798f0(1,1);
    iVar5 = FUN_005699a0(uVar7,0x590);
    if (iVar5 != 0) {
      uVar8 = 5;
      puVar10 = (uint *)(&DAT_00a56044 + uVar7 * 0x6a2);
      do {
        sVar2 = FUN_004022e0((ushort)*puVar10 & 0xfff);
        if ((sVar2 == 0x590) &&
           (((uint)(*(byte *)((int)puVar10 + 6) >> 1) & ~(puVar10[0x23] >> 5) &
             ~(puVar10[0x23] >> 1) & 1) != 0)) {
          uVar1 = *puVar10;
          FUN_005ba490((uVar8 & 0x1f | uVar7 << 0xf | 0x2420) << 0x10 | uVar1 & 0xfff,
                       (uVar1 >> 0xc & 1) + (uVar1 >> 0x18 & 0x7f) * 2,
                       (CONCAT11((char)(DAT_00a57840 >> 0xb),(char)uVar7) & 0xffff07ff) << 0x10 |
                       (uint)(ushort)(((byte)(DAT_00a57840 >> 8) & 7) << 8) | param_1 & 0xff);
        }
        uVar8 = uVar8 + 1;
        puVar10 = puVar10 + 0x24;
      } while ((int)uVar8 < 10);
    }
    FUN_00598590(DAT_00a577f8._2_1_ & 1,0x12,
                 (CONCAT11((char)(DAT_00a57840 >> 0xb),(char)uVar7) & 0xffff07ff) << 0x10 |
                 (uint)(ushort)(((byte)(DAT_00a57840 >> 8) & 7) << 8) | param_1 & 0xff);
    break;
  default:
    iVar5 = FUN_005a0f00(param_1);
    return iVar5 == 0;
  }
  bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
  _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
  return false;
}


//// FUNC 005a22c0 FUN_005a22c0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a22c0(void)

{
  uint uVar1;
  short sVar2;
  ushort uVar3;
  uint uVar4;
  int iVar5;
  uint uVar6;
  byte bVar7;
  uint uVar8;
  uint uVar9;
  uint uVar10;
  
  uVar1 = DAT_00a57840;
  bVar7 = (byte)((ushort)DAT_00a57840 >> 1);
  uVar8 = ((uint)(ushort)(((byte)(DAT_00a57840 >> 0xb) & 7) << 8) | bVar7 & 1) << 0x10 |
          (uint)(ushort)((DAT_00a57840._1_1_ & 7) << 8) | DAT_00a57840 & 1;
  uVar9 = DAT_00a57840 & 0xffff;
  uVar6 = (&DAT_00a55d74)[(uVar9 >> 8 & 7) * 0x24 + (DAT_00a57840 & 1) * 0x351];
  uVar4 = uVar9 >> 1 & 1;
  uVar10 = uVar9 >> 0xb & 7;
  uVar9 = (&DAT_00a55d74)[uVar4 * 0x351 + uVar10 * 0x24];
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    FUN_005798f0(0,1);
    FUN_005b9170(DAT_00a57840 << 0xf | 0x35,DAT_00a57840 >> 8 & 7,1,0);
    break;
  case 1:
    DAT_00a57840 = DAT_00a57840 & 0xffff;
    if (((uVar1 & 4) == 0) && (((&DAT_00a55d7a)[uVar10 * 0x90 + uVar4 * 0xd44] & 2) == 0)) {
      FUN_00574f70(uVar4,uVar10,0,0);
      uVar6 = (DAT_00a57840 & 0xffff) >> 1 & 1;
      FUN_00578430(uVar6,*(ushort *)
                          (&DAT_00a55d74 +
                          ((DAT_00a57840 & 0xffff) >> 0xb & 7) * 0x24 + uVar6 * 0x351) & 0xfff);
      DAT_00a57840 = CONCAT22(*(undefined2 *)
                               (&DAT_00a55d74 +
                               ((DAT_00a57840 & 0xffff) >> 0xb & 7) * 0x24 +
                               ((DAT_00a57840 & 0xffff) >> 1 & 1) * 0x351),(ushort)DAT_00a57840) &
                     0xfffffff;
    }
    break;
  case 2:
    iVar5 = FUN_0056b440(uVar6 & 0xfff,(uVar6 >> 0xc & 1) + (uVar6 >> 0x18 & 0x7f) * 2);
    if ((iVar5 == 0) && (sVar2 = FUN_004022e0(uVar6 & 0xfff), sVar2 == 0x540)) {
      FUN_005b9170(DAT_00a57840 << 0xf | 0x94,DAT_00a57840 >> 8 & 7,0,0);
    }
    if ((((DAT_00a57840 & 4) == 0) &&
        (iVar5 = FUN_0056b440(uVar9 & 0xfff,
                              ((uint)(&DAT_00a55d74)
                                     [((DAT_00a57840 & 0xffff) >> 0xb & 7) * 0x24 +
                                      ((DAT_00a57840 & 0xffff) >> 1 & 1) * 0x351] >> 0xc & 1) +
                              ((uint)(&DAT_00a55d74)
                                     [((DAT_00a57840 & 0xffff) >> 0xb & 7) * 0x24 +
                                      ((DAT_00a57840 & 0xffff) >> 1 & 1) * 0x351] >> 0x18 & 0x7f) *
                              2), iVar5 == 0)) &&
       (sVar2 = FUN_004022e0(uVar9 & 0xfff), sVar2 == 0x4b1)) {
      uVar9 = (DAT_00a57840 & 0xffff) >> 0xb & 7;
      uVar6 = (DAT_00a57840 & 0xffff) >> 1 & 1;
      if (((&DAT_00a55d7a)[uVar9 * 0x90 + uVar6 * 0xd44] & 1) != 0) {
        FUN_005747e0(uVar6,*(ushort *)(&DAT_00a55d74 + uVar6 * 0x351 + uVar9 * 0x24) & 0xfff,
                     CONCAT11((char)(DAT_00a57840 >> 0xb),(byte)DAT_00a57840 >> 1) & 0x701,3);
      }
    }
    if ((DAT_00a57840 & 0x40) != 0) {
      return 1;
    }
    bVar7 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar7;
    return 0;
  case 3:
    if (((DAT_00a57840 & 4) == 0) && (((bVar7 ^ (byte)DAT_00a57840) & 1) != 0)) {
      uVar3 = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar4 * 0x351 + uVar10 * 0x24) & 0xfff);
      if (uVar3 < 0x4dc) {
        if ((((uVar3 != 0x4db) && (uVar3 != 0x2df)) && (uVar3 != 0x492)) ||
           (DAT_00a57840._2_2_ == 0)) goto LAB_005a26e5;
      }
      else if (uVar3 != 0x5f2) goto LAB_005a26e5;
      uVar9 = (DAT_00a57840 & 0xffff) >> 0xb & 7;
      uVar6 = (&DAT_00a55d74)[uVar9 * 0x24 + ((DAT_00a57840 & 0xffff) >> 1 & 1) * 0x351];
      FUN_005ba490(((DAT_00a57840 & 0xfffe) << 0xe | uVar9 | 0x2620) << 0x10 | uVar6 & 0xfff,
                   (uVar6 >> 0xc & 1) + (uVar6 >> 0x18 & 0x7f) * 2,uVar8);
    }
LAB_005a26e5:
    FUN_00598590(DAT_00a577f8._2_1_ & 1,0x13,uVar8);
    bVar7 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar7;
    return 0;
  default:
    return 1;
  }
  bVar7 = DAT_00a577fc + 1 ^ DAT_00a577fc;
  _DAT_00a577fc = _DAT_00a577fc ^ bVar7;
  return 0;
}


//// FUNC 005a2740 FUN_005a2740

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a2740(int param_1)

{
  byte bVar1;
  undefined4 *puVar2;
  uint uVar3;
  uint uVar4;
  
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    FUN_005b9170(DAT_00a57840 << 0xf | 0x30,DAT_00a57846,DAT_00a57856,0);
    FUN_005b7c50(1);
    if ((DAT_00a57840 & 0x40) == 0) {
      puVar2 = &DAT_00a5785c;
      if (((&DAT_00a57854)[param_1 * -0x10] & 0x20) == 0) {
        puVar2 = &DAT_00a57858;
      }
      FUN_00598590(DAT_00a577f8._2_1_ & 1,0xd,
                   puVar2[param_1 * -4] << 0x10 | (&DAT_00a57848)[param_1 * 4] & 0xffff);
    }
    bVar1 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar1;
    return 0;
  case 1:
    FUN_005b8210(1);
    bVar1 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar1;
    return 0;
  case 2:
    uVar3 = 0xffff;
    if (DAT_00a57860 < 0x10000) {
      uVar3 = DAT_00a57860;
    }
    uVar4 = 0xffff;
    if (DAT_00a57850 < 0x10000) {
      uVar4 = DAT_00a57850;
    }
    FUN_005b9170(DAT_00a57840 << 0xf | 0x31,uVar4,uVar3,
                 CONCAT11(((((DAT_00a57854 >> 7) << 1 | DAT_00a57854 >> 6 & 1) << 1 |
                           DAT_00a57860 != 0) << 1 | DAT_00a57854 >> 4 & 1) << 1 |
                          DAT_00a57854 >> 5 & 1,
                          ((((DAT_00a57844 >> 7) << 1 | DAT_00a57844 >> 6 & 1) << 1 |
                           DAT_00a57850 != 0) << 1 | DAT_00a57844 >> 4 & 1) << 1 |
                          DAT_00a57844 >> 5 & 1));
    bVar1 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar1;
    return 0;
  case 3:
    if (((&DAT_00a57844)[(DAT_00a57840 & 1) * 0x10] & 0x10) != 0) {
      FUN_005b9170(DAT_00a57840 << 0xf | 0x3c,DAT_00a57840 >> 8 & 7,0,0);
    }
    if (((&DAT_00a57854)[(DAT_00a57840 & 1) * -0x10] & 0x10) != 0) {
      FUN_005b9170((DAT_00a57840 & 0xfffe) << 0xe | 0x3c,DAT_00a57840 >> 0xb & 7,1,0);
    }
  }
  return 1;
}


//// FUNC 005a2990 FUN_005a2990

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a2990(uint *param_1)

{
  byte *pbVar1;
  short sVar2;
  uint uVar3;
  int iVar4;
  uint uVar5;
  byte bVar6;
  byte *pbVar7;
  int iVar8;
  uint *puVar9;
  uint uVar10;
  int iStack_1c;
  ushort uStack_14;
  ushort uStack_12;
  short sStack_10;
  undefined2 uStack_e;
  undefined2 uStack_c;
  undefined4 uStack_a;
  undefined4 uStack_6;
  undefined2 uStack_2;
  
  uVar3 = (uint)param_1;
  pbVar1 = &DAT_00a57844 + (int)param_1 * 0x10;
  pbVar7 = &DAT_00a57854 + (int)param_1 * -0x10;
  uVar10 = DAT_00a57840 >> 1 & 1;
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    if ((((DAT_00a57840 & 0x40) == 0) && ((*pbVar7 >> 6 & 1 ^ uVar10) == 1U - (int)param_1)) &&
       ((&DAT_00a57860)[(int)param_1 * -4] != 0)) {
      iVar8 = 0;
      uVar3 = -(int)param_1 - 1U & 1;
      if (*(char *)(&DAT_00a55d68 + uVar3 * 0x6a2) != '\0') {
        puVar9 = &DAT_00a56434 + uVar3 * 0x351;
        do {
          sVar2 = FUN_004022e0((ushort)*puVar9 & 0xfff);
          if ((sVar2 == 0x39) || (sVar2 = FUN_004022e0((ushort)*puVar9 & 0xfff), sVar2 == 0x76d)) {
            uStack_14 = (ushort)*puVar9 & 0xfff;
            uStack_e = 0;
            uStack_c = 0;
            uStack_a = 0;
            uStack_6 = 0;
            uStack_2 = 0;
            sStack_10 = (((ushort)(*puVar9 >> 0xc) & 1) + ((byte)(*puVar9 >> 0x18) & 0x7f) * 2) *
                        0x20;
            uStack_12 = (byte)(-(char)param_1 - 1) & 1 | 0x356;
            iVar4 = FUN_0057eac0(&uStack_14,0);
            if (iVar4 != 0) {
              _DAT_00a577fc =
                   CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)(_DAT_00a577fc >> 8) & 0xff,10));
              return 0;
            }
          }
          iVar8 = iVar8 + 1;
          puVar9 = puVar9 + 1;
        } while (iVar8 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar3 * 0x6a2));
      }
    }
    break;
  case 1:
    FUN_00579810();
    FUN_00578540((*pbVar1 & 0x40) >> 6 ^ (uint)param_1,(&DAT_00a57850)[(int)param_1 * 4],pbVar7,
                 pbVar1);
    FUN_00578540((*pbVar7 & 0x40) >> 6 ^ uVar10,(&DAT_00a57860)[(int)param_1 * -4],pbVar1,pbVar7);
    FUN_00579890();
    bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
    return 0;
  case 2:
    FUN_0059d090();
    break;
  default:
    return 1;
  case 10:
    FUN_005bcf40(uVar10,0x39);
    bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
    return 0;
  case 0xb:
    if ((_DAT_00a57822 != 0) && (iStack_1c = 0, *(char *)(&DAT_00a55d68 + uVar10 * 0x6a2) != '\0'))
    {
      param_1 = &DAT_00a56434 + uVar10 * 0x351;
      do {
        uVar5 = *param_1 & 0xfff;
        sVar2 = FUN_004022e0(uVar5);
        if ((sVar2 == 0x39) || (sVar2 = FUN_004022e0(uVar5), sVar2 == 0x76d)) {
          FUN_005783c0(uVar10,0xb,uVar5,
                       ((uint)(&DAT_00a56434)[iStack_1c + uVar10 * 0x351] >> 0xc & 1) +
                       ((uint)(&DAT_00a56434)[iStack_1c + uVar10 * 0x351] >> 0x18 & 0x7f) * 2);
          (&DAT_00a57860)[uVar3 * -4] = 0;
          FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar10 != 0) >> 8) & 0x80,0xea),0,0,0);
          FUN_00575a10(uVar10,iStack_1c);
          FUN_0059d040(uVar10);
          break;
        }
        param_1 = param_1 + 1;
        iStack_1c = iStack_1c + 1;
      } while (iStack_1c < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar10 * 0x6a2));
    }
    _DAT_00a577fc = CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)(_DAT_00a577fc >> 8) & 0xff,1));
    return 0;
  }
  bVar6 = DAT_00a577fc + 1 ^ DAT_00a577fc;
  _DAT_00a577fc = _DAT_00a577fc ^ bVar6;
  return 0;
}


//// FUNC 005a2d60 FUN_005a2d60

undefined4 FUN_005a2d60(uint param_1)

{
  int iVar1;
  ushort uVar2;
  ushort uVar3;
  short sVar4;
  int iVar5;
  undefined1 uVar7;
  undefined4 uVar6;
  undefined2 extraout_var;
  uint uVar8;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  uint uVar9;
  ushort *puVar10;
  int iVar11;
  uint uVar12;
  
  iVar11 = param_1 * 0x10;
  uVar9 = DAT_00a57840 >> 1 & 1;
  iVar1 = param_1 * -0x10;
  puVar10 = (ushort *)(&DAT_00a57854 + iVar1);
  if ((DAT_00a57840 & 4) != 0) {
    return 1;
  }
  iVar5 = FUN_0056b440((&DAT_00a57846)[param_1 * 8],*(ushort *)(&DAT_00a57844 + iVar11) >> 8);
  if (iVar5 == 0) {
    uVar3 = (&DAT_00a57846)[param_1 * 8];
    uVar12 = DAT_00a57840 & 0x700;
    uVar2 = FUN_004022e0(uVar3);
    if (uVar2 < 399) {
      if (uVar2 == 0x18e) {
LAB_005a2e24:
        FUN_00578390(param_1,CONCAT22(extraout_var,(&DAT_00a57846)[param_1 * 8]),
                     DAT_00a57840 >> 8 & 7);
        FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar9 != 0) >> 8) & 0x80,0x97),DAT_00a57840 >> 0xb & 7
                     ,5,0);
      }
      else if (uVar2 == 0xff) {
        FUN_005ba490((uVar12 | param_1 << 0x17 | 0x282000) << 8 | (uint)uVar3,
                     (&DAT_00a57845)[iVar11],0);
      }
      else if (uVar2 == 0x188) goto LAB_005a2e24;
    }
    else if (((uVar2 == 0x5f3) && ((*puVar10 & 0x10) != 0)) &&
            (uVar12 = DAT_00a57840 >> 8 & 7,
            ((&DAT_00a55d74)[uVar12 * 0x24 + (param_1 & 1) * 0x351] & 0xfff) != 0)) {
      FUN_00578390(param_1,(&DAT_00a57846)[param_1 * 8],uVar12);
      uVar6 = FUN_00402460(0x5f3,CONCAT11(DAT_00a57840._1_1_,(undefined1)param_1) & 0x7ff,0xb);
      FUN_005747e0(param_1,uVar6);
    }
  }
  iVar5 = FUN_0056b440((&DAT_00a57856)[param_1 * -8],*puVar10 >> 8);
  if (iVar5 != 0) {
    return 1;
  }
  uVar12 = (DAT_00a57840 & 0x3800 | uVar9 << 0x1a | 0x1410000) << 5 |
           (uint)(ushort)(&DAT_00a57856)[param_1 * -8];
  uVar3 = FUN_004022e0((&DAT_00a57856)[param_1 * -8]);
  if (uVar3 < 0x262) {
    if (uVar3 == 0x261) {
      sVar4 = FUN_0056f6d0(param_1,DAT_00a57840 >> 8 & 7);
      if (sVar4 != 2) {
        FUN_00578390(uVar9,CONCAT22(extraout_var_01,(&DAT_00a57856)[param_1 * -8]),
                     DAT_00a57840 >> 0xb & 7);
        FUN_005747e0(DAT_00a57840 & 1,(&DAT_00a57856)[param_1 * -8],DAT_00a57840 & 0x701,0x23);
      }
      goto LAB_005a30e8;
    }
    if (uVar3 != 0xff) {
      if ((uVar3 == 0x189) && (sVar4 = FUN_0056f6d0(param_1,DAT_00a57840 >> 8 & 7), sVar4 != 7)) {
        FUN_00578390(uVar9,(&DAT_00a57856)[param_1 * -8],DAT_00a57840 >> 0xb & 7);
        FUN_005b9170(CONCAT31((uint3)(-(uint)(param_1 != 0) >> 8) & 0x80,0x97),DAT_00a57840 >> 8 & 7
                     ,3,0);
      }
      goto LAB_005a30e8;
    }
  }
  else if (uVar3 != 0x419) {
    if (((uVar3 == 0x5f3) && (((&DAT_00a57844)[iVar11] & 0x10) != 0)) &&
       (uVar8 = DAT_00a57840 >> 0xb & 7,
       ((&DAT_00a55d74)[uVar8 * 0x24 + uVar9 * 0x351] & 0xfff) != 0)) {
      FUN_00578390(uVar9,(&DAT_00a57856)[param_1 * -8],uVar8);
      uVar6 = FUN_00402460(0x5f3,CONCAT11((char)(DAT_00a57840 >> 0xb),(byte)uVar9) & 0x7ff,0xb);
      FUN_005747e0(uVar9,uVar6);
    }
    goto LAB_005a30e8;
  }
  FUN_005ba490(uVar12,*(undefined1 *)(iVar1 + 0xa57855),0);
LAB_005a30e8:
  if ((DAT_00a57840._2_2_ != 0) && (iVar11 = FUN_00567620(DAT_00a57840._2_2_,1), iVar11 != 0)) {
    uVar7 = (undefined1)(*puVar10 >> 8);
    uVar3 = CONCAT11((byte)*puVar10 & 0x2e | (byte)uVar9,uVar7) | 0x4000 | (ushort)param_1 & 0xc000;
    iVar11 = FUN_0057ee80(uVar12,uVar7,uVar3);
    if (iVar11 != 0) {
      uVar6 = FUN_004022e0(CONCAT22(extraout_var_00,DAT_00a57840._2_2_),1,0);
      FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar9 != 0) >> 8) & 0x80,0xad),uVar6);
      FUN_005ba490(uVar12,*(undefined1 *)(iVar1 + 0xa57855),uVar3);
    }
  }
  return 1;
}


//// FUNC 005a31a0 FUN_005a31a0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a31a0(uint param_1)

{
  bool bVar1;
  bool bVar2;
  ushort uVar3;
  short sVar4;
  undefined2 uVar5;
  ushort uVar6;
  int iVar7;
  int iVar8;
  undefined4 uVar9;
  uint uVar10;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  undefined2 extraout_var_02;
  undefined2 extraout_var_03;
  byte bVar11;
  undefined2 extraout_var_04;
  undefined2 extraout_var_05;
  undefined2 extraout_var_06;
  undefined2 extraout_var_07;
  char cVar12;
  uint uVar13;
  uint uVar14;
  ushort *puVar15;
  bool bVar16;
  bool bVar17;
  uint *puStack_14;
  uint *puStack_c;
  
  iVar7 = param_1 * 0x10;
  uVar6 = *(ushort *)(&DAT_00a57844 + iVar7);
  puVar15 = (ushort *)(&DAT_00a57854 + param_1 * -0x10);
  uVar13 = DAT_00a57840 >> 1 & 1;
  if ((uVar6 & 0x10) == 0) {
    puStack_14 = &DAT_00a55d74 + (uVar6 >> 1 & 7) * 0x24 + (param_1 & 1) * 0x351;
  }
  else {
    puStack_14 = &DAT_00a57864;
  }
  uVar3 = *puVar15;
  if ((uVar3 & 0x10) == 0) {
    puStack_c = &DAT_00a55d74 + (uVar3 >> 1 & 7) * 0x24 + uVar13 * 0x351;
  }
  else {
    puStack_c = &DAT_00a578f4;
  }
  if (((uVar6 & 0x10) == 0) || (bVar1 = true, (DAT_00a57864 & 0xfff) == 0)) {
    bVar1 = false;
  }
  if (((uVar3 & 0x10) == 0) || (bVar2 = true, (DAT_00a578f4 & 0xfff) == 0)) {
    bVar2 = false;
  }
  uVar14 = param_1 & 1;
  bVar16 = ((uint)(&DAT_00a55d74)[(uVar6 >> 1 & 7) * 0x24 + uVar14 * 0x351] >> 0xc & 1) +
           ((uint)(&DAT_00a55d74)[(uVar6 >> 1 & 7) * 0x24 + uVar14 * 0x351] >> 0x18 & 0x7f) * 2 ==
           (uint)(uVar6 >> 8);
  bVar17 = ((uint)(&DAT_00a55d74)[(uVar3 >> 1 & 7) * 0x24 + uVar13 * 0x351] >> 0xc & 1) +
           ((uint)(&DAT_00a55d74)[(uVar3 >> 1 & 7) * 0x24 + uVar13 * 0x351] >> 0x18 & 0x7f) * 2 ==
           (uint)(uVar3 >> 8);
  if ((DAT_00a57840 & 4) != 0) {
    return 1;
  }
  if ((_DAT_00a577fc & 0xff) == 0) {
    if (bVar1) {
      iVar8 = FUN_0056b440((&DAT_00a57846)[param_1 * 8],(uint)(uVar6 >> 8));
      cVar12 = (char)uVar13;
      if (iVar8 == 0) {
        uVar6 = FUN_004022e0(CONCAT22(extraout_var_00,(&DAT_00a57846)[param_1 * 8]));
        if (((0x4e5 < uVar6) && (uVar6 < 0x4e9)) && (bVar17)) {
          FUN_00578390(param_1,(&DAT_00a57846)[param_1 * 8],DAT_00a57840 >> 8 & 7);
          FUN_005747e0(param_1,CONCAT22(extraout_var_01,(&DAT_00a57846)[param_1 * 8]),
                       CONCAT11((char)(DAT_00a57840 >> 0xb),cVar12) & 0x7ff,0xb);
        }
      }
      iVar8 = FUN_0056b440((&DAT_00a57856)[param_1 * -8],*puVar15 >> 8);
      if (iVar8 == 0) {
        sVar4 = FUN_004022e0(CONCAT22(extraout_var_04,(&DAT_00a57856)[param_1 * -8]));
        if (sVar4 == 0x2f9) {
          if (bVar17) {
            FUN_005747e0(uVar13,(&DAT_00a57856)[param_1 * -8],
                         CONCAT11((char)(DAT_00a57840 >> 0xb),cVar12) & 0x7ff,3);
          }
        }
        else if (sVar4 == 0x52f) {
          if ((bVar17) &&
             (iVar8 = FUN_00402690(CONCAT22(extraout_var_02,(&DAT_00a57846)[param_1 * 8])),
             iVar8 != 0)) {
            uVar9 = FUN_00402460(0x52f,CONCAT11((char)(DAT_00a57840 >> 0xb),cVar12) & 0x7ff,
                                 CONCAT11((&DAT_00a57845)[iVar7],cVar12 << 4) | 0xb);
            FUN_005747e0(uVar13,uVar9);
          }
        }
        else if (sVar4 == 0x53c) {
          uVar9 = FUN_00402460(0x53c,(uint)(byte)((char)(*puStack_14 >> 0x18) * '\x02' +
                                                 ((byte)(*puStack_14 >> 0xc) & 1)) << 8 | 3);
          FUN_00579790(uVar13,uVar9);
        }
      }
    }
    if (bVar2) {
      iVar8 = FUN_0056b440((&DAT_00a57856)[param_1 * -8],*puVar15 >> 8);
      if (iVar8 == 0) {
        uVar6 = FUN_004022e0((&DAT_00a57856)[param_1 * -8]);
        if (((0x4e5 < uVar6) && (uVar6 < 0x4e9)) && (bVar16)) {
          FUN_00578390(uVar13,CONCAT22(extraout_var_05,(&DAT_00a57856)[param_1 * -8]),
                       DAT_00a57840 >> 0xb & 7);
          FUN_005747e0(uVar13,CONCAT22(extraout_var_06,(&DAT_00a57856)[param_1 * -8]),
                       CONCAT11(DAT_00a57840._1_1_,(char)param_1) & 0x7ff,0xb);
        }
      }
      iVar7 = FUN_0056b440((&DAT_00a57846)[param_1 * 8],*(ushort *)(&DAT_00a57844 + iVar7) >> 8);
      if (iVar7 == 0) {
        sVar4 = FUN_004022e0(CONCAT22(extraout_var_07,(&DAT_00a57846)[param_1 * 8]));
        if (sVar4 == 0x2f9) {
          if (!bVar16) goto LAB_005a39e3;
          uVar13 = 3;
          uVar10 = (uint)(ushort)(&DAT_00a57846)[param_1 * 8];
          uVar14 = (uint)(CONCAT11((char)(DAT_00a57840 >> 8),(char)param_1) & 0x7ff);
        }
        else {
          if (sVar4 != 0x52f) {
            if (sVar4 == 0x53c) {
              uVar9 = FUN_00402460(0x53c,(uint)(byte)((char)(*puStack_c >> 0x18) * '\x02' +
                                                     ((byte)(*puStack_c >> 0xc) & 1)) << 8 | 3);
              FUN_00579790(param_1,uVar9);
            }
            goto LAB_005a39e3;
          }
          if ((!bVar16) ||
             (iVar7 = FUN_00402690(CONCAT22(extraout_var_03,(&DAT_00a57856)[param_1 * -8])),
             iVar7 == 0)) goto LAB_005a39e3;
          uVar13 = CONCAT11(*(undefined1 *)(param_1 * -0x10 + 0xa57855),(char)param_1 << 4) | 0xb;
          uVar14 = CONCAT11(DAT_00a57840._1_1_,(char)param_1) & 0xffff07ff;
          uVar10 = FUN_00402460(0x52f,uVar14,uVar13);
        }
        FUN_005747e0(param_1,uVar10,uVar14,uVar13);
      }
    }
    goto LAB_005a39e3;
  }
  if ((_DAT_00a577fc & 0xff) != 1) {
    return 1;
  }
  FUN_00579810();
  uVar6 = *(ushort *)(&DAT_00a57844 + iVar7);
  if ((uVar6 & 0x10) != 0) {
    uVar3 = FUN_004022e0((&DAT_00a57846)[param_1 * 8]);
    if ((uVar3 < 0x780) || (uVar3 = FUN_004022e0((&DAT_00a57846)[param_1 * 8]), 0x783 < uVar3)) {
      iVar7 = FUN_005699c0(0x453);
      iVar8 = 0xe;
      if (0 < iVar7) goto LAB_005a3414;
    }
    else {
LAB_005a3414:
      iVar8 = 0xf;
    }
    FUN_00577cf0(uVar14,(uVar6 & 0xe) >> 1,puStack_14,param_1 != uVar13,
                 iVar8 << 0x12 |
                 (uVar13 << 9 | uVar6 & 0x2e | uVar14 | 0x1c0) << 8 | (uint)(uVar6 >> 8));
  }
  uVar6 = *puVar15;
  if ((uVar6 & 0x10) != 0) {
    uVar3 = FUN_004022e0(CONCAT22((short)((uint)puVar15 >> 0x10),(&DAT_00a57856)[param_1 * -8]));
    if ((uVar3 < 0x780) || (uVar3 = FUN_004022e0((&DAT_00a57856)[param_1 * -8]), 0x783 < uVar3)) {
      iVar7 = FUN_005699c0(0x453);
      iVar8 = 0xe;
      if (0 < iVar7) goto LAB_005a34ca;
    }
    else {
LAB_005a34ca:
      iVar8 = 0xf;
    }
    FUN_00577cf0(uVar13,(uVar6 & 0xe) >> 1,puStack_c,param_1 != uVar13,
                 iVar8 << 0x12 |
                 (uVar6 & 0x2e | uVar14 << 9 | uVar13 | 0x1c0) << 8 | (uint)(uVar6 >> 8));
  }
  iVar7 = FUN_0056db30(param_1,DAT_00a57840 >> 8 & 7,0x2da);
  if ((iVar7 != 0) && (sVar4 = FUN_0056d560(param_1,DAT_00a57840 >> 8 & 7), sVar4 != -1)) {
    FUN_00574eb0(param_1,DAT_00a57840 >> 8 & 7);
  }
  iVar7 = FUN_0056db30(uVar13,DAT_00a57840 >> 0xb & 7,0x2da);
  if ((iVar7 != 0) && (sVar4 = FUN_0056d560(uVar13,DAT_00a57840 >> 0xb & 7), sVar4 != -1)) {
    FUN_00574eb0(uVar13,DAT_00a57840 >> 0xb & 7);
  }
  iVar7 = FUN_0056db30(uVar13,DAT_00a57840 >> 0xb & 7,0x5ff);
  if ((iVar7 != 0) && (bVar16)) {
    uVar9 = FUN_00402460(0x5ff);
    FUN_00578400(uVar13,uVar9);
    uVar5 = FUN_00402460(0x5ff);
    FUN_00577840(param_1,DAT_00a57840 >> 8 & 7,1,uVar5);
  }
  iVar7 = FUN_0056db30(uVar13,DAT_00a57840 >> 0xb & 7,0x199);
  if ((iVar7 != 0) && (bVar17)) {
    FUN_00578390(param_1,CONCAT22(extraout_var,(&DAT_00a57846)[param_1 * 8]),DAT_00a57840 >> 8 & 7);
    FUN_00577840(uVar13,DAT_00a57840 >> 0xb & 7,1,(&DAT_00a57846)[param_1 * 8]);
  }
  FUN_00579890();
LAB_005a39e3:
  bVar11 = DAT_00a577fc + 1 ^ DAT_00a577fc;
  _DAT_00a577fc = _DAT_00a577fc ^ bVar11;
  return 0;
}


//// FUNC 005a3a10 FUN_005a3a10

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a3a10(int param_1)

{
  int iVar1;
  uint uVar2;
  uint uVar3;
  
  uVar3 = (DAT_00a57840 & 0xffff) >> 1 & 1;
  iVar1 = FUN_0056db30(uVar3,(DAT_00a57840 & 0xffff) >> 0xb & 7,0x4b1);
  if (iVar1 != 0) {
    FUN_00574900(uVar3,DAT_00a57840 >> 0xb & 7,0x4b1,0);
    uVar2 = DAT_00a57840 >> 0xb & 7;
    if (((&DAT_00a55d7a)[uVar3 * 0xd44 + uVar2 * 0x90] & 1) != 0) {
      FUN_00578390(uVar3,(&DAT_00a57856)[param_1 * -8],uVar2);
      FUN_00575190(uVar3,DAT_00a57840 >> 0xb & 7,0,0,0);
    }
  }
  FUN_005798f0(0,0);
  _DAT_00a577fc = _DAT_00a577fc & 0xff00;
  DAT_00a577f8._2_2_ = CONCAT11(1,DAT_00a577f8._2_1_);
  return 0;
}


//// FUNC 005a3af0 FUN_005a3af0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a3af0(int param_1)

{
  ushort uVar1;
  undefined1 uVar2;
  byte bVar3;
  undefined2 uVar4;
  short sVar5;
  ushort uVar6;
  undefined4 uVar7;
  int iVar8;
  int iVar9;
  uint uVar10;
  byte *pbVar11;
  uint *puVar12;
  uint uVar13;
  ushort *puVar14;
  uint uStack_14;
  uint uStack_10;
  int iStack_8;
  
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    FUN_00598590(DAT_00a577f8._2_1_ & 1,0x16,0);
    break;
  case 1:
    uVar13 = 0;
    do {
      param_1 = 0;
      uVar10 = DAT_00a577f8._2_1_ & 1 ^ uVar13;
      puVar14 = (ushort *)(&DAT_00a55d7a + (uVar10 & 1) * 0xd44);
      do {
        uVar1 = puVar14[-3];
        iVar9 = FUN_00569790(uVar10,param_1,0x540);
        if (((iVar9 != 0) && ((*puVar14 & 0x200) == 0)) && ((*puVar14 & 1) == 0)) {
          FUN_00578390(uVar10,uVar1 & 0xfff,param_1);
          FUN_00575190(uVar10,param_1,0,0,0);
          FUN_00574900(uVar10,param_1,0x540,1);
          FUN_005747e0(uVar10,uVar1 & 0xfff,CONCAT11((undefined1)param_1,(char)uVar10),0x2c);
        }
        puVar14 = puVar14 + 0x48;
        param_1 = param_1 + 1;
      } while (param_1 < 5);
      uVar13 = uVar13 + 1;
    } while ((int)uVar13 < 2);
    bVar3 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar3;
    return 0;
  case 2:
    uVar13 = 0;
    do {
      uVar10 = DAT_00a577f8._2_1_ & 1 ^ uVar13;
      iVar9 = 0;
      do {
        iVar8 = FUN_0056db30(uVar10,iVar9,0x49e);
        if (iVar8 != 0) {
          uVar7 = FUN_00402460(0x49e);
          FUN_00578400(uVar10,uVar7);
          uVar4 = FUN_00402460(0x49e);
          FUN_00577840(uVar10,iVar9,1,uVar4);
        }
        iVar9 = iVar9 + 1;
      } while (iVar9 < 5);
      uVar13 = uVar13 + 1;
    } while ((int)uVar13 < 2);
    break;
  case 3:
    uStack_14 = 0;
    do {
      param_1 = 0;
      iStack_8 = 0;
      pbVar11 = &DAT_00a55d7a + (uStack_14 & 1) * 0xd44;
      do {
        uVar1 = *(ushort *)(pbVar11 + -6);
        sVar5 = FUN_004022e0(uVar1 & 0xfff);
        if (((sVar5 == 0x52f) && ((*pbVar11 & 2) != 0)) &&
           (iVar9 = FUN_0056da10(uStack_14,param_1,0x52f), -1 < iVar9)) {
          uVar2 = (undefined1)
                  (*(ushort *)(&DAT_00a55dc0 + (iStack_8 + (uStack_14 & 1) * 0x6a2 + iVar9) * 2) >>
                  8);
          uVar6 = *(ushort *)(&DAT_00a55dc0 + (iStack_8 + (uStack_14 & 1) * 0x6a2 + iVar9) * 2) >> 4
                  & 0xf;
          iVar9 = FUN_0056a400(uVar6);
          uVar13 = FUN_005687d0(uVar2);
          if ((-1 < iVar9) && ((char)(uVar13 >> 8) == '\x0e')) {
            FUN_00578390(uStack_14,uVar1 & 0xfff,param_1);
            FUN_00576110(uVar13 & 0xff,0xe,uVar2,uVar6,iVar9,1,0);
            uStack_10._0_1_ = (undefined1)iVar9;
            FUN_005749b0(uVar6,CONCAT11((undefined1)uStack_10,(char)uVar6),
                         CONCAT11((undefined1)param_1,(undefined1)uStack_14),4);
            FUN_00574900(uStack_14,param_1,0x52f,0);
            return 0;
          }
        }
        iStack_8 = iStack_8 + 0x48;
        param_1 = param_1 + 1;
        pbVar11 = pbVar11 + 0x90;
      } while (iStack_8 < 0x168);
      uStack_14 = uStack_14 + 1;
    } while ((int)uStack_14 < 2);
    break;
  case 4:
    iVar9 = 0;
    do {
      iVar8 = FUN_005709d0(iVar9,0x53c);
      if (iVar8 != 0) {
        uVar13 = FUN_00402460(0x53c,0,0);
        iVar8 = FUN_005ba490(uVar13 & 0xffff | iVar9 << 0x1f | 0x5f0000);
        if (iVar8 != 0) {
          return 0;
        }
        FUN_005797c0(iVar9,0x53c,0);
        return 0;
      }
      iVar9 = iVar9 + 1;
    } while (iVar9 < 2);
    goto LAB_005a3f67;
  case 5:
    uVar13 = 0;
    do {
      iVar9 = 0;
      uVar10 = DAT_00a577f8._2_1_ & 1 ^ uVar13;
      puVar12 = &DAT_00a55d74 + (uVar10 & 1) * 0x351;
      do {
        if ((*puVar12 & 0xfff) != 0) {
          FUN_00574900(uVar10,iVar9,0x3de,1);
        }
        iVar9 = iVar9 + 1;
        puVar12 = puVar12 + 0x24;
      } while (iVar9 < 5);
      uVar13 = uVar13 + 1;
    } while ((int)uVar13 < 2);
    goto LAB_005a3f67;
  case 6:
    uVar13 = 0;
    uStack_10 = 0;
    do {
      iVar9 = 0;
      uVar10 = DAT_00a577f8._2_1_ & 1 ^ uVar13;
      puVar12 = &DAT_00a55d74 + (uVar10 & 1) * 0x351;
      do {
        if (((*puVar12 & 0xfff) != 0) && (iVar8 = FUN_0056db30(uVar10,iVar9,0x3b1), iVar8 != 0)) {
          uStack_10 = uStack_10 | 1 << ((char)(uVar10 << 4) + (char)iVar9 & 0x1fU);
        }
        iVar9 = iVar9 + 1;
        puVar12 = puVar12 + 0x24;
      } while (iVar9 < 5);
      uVar13 = uVar13 + 1;
    } while ((int)uVar13 < 2);
    FUN_005777f0(1 - param_1,0,uStack_10);
LAB_005a3f67:
    bVar3 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar3;
    return 0;
  default:
    FUN_005797c0(param_1,0x602,1);
    iVar9 = FUN_005709d0(param_1,0x246);
    if (iVar9 != 0) {
      FUN_005797c0(param_1,0x246,1);
      DAT_00a577f8._2_2_ = DAT_00a577f8._2_2_ & 0xff;
      _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
      return 0;
    }
    return 1;
  }
  bVar3 = DAT_00a577fc + 1 ^ DAT_00a577fc;
  _DAT_00a577fc = _DAT_00a577fc ^ bVar3;
  return 0;
}


//// FUNC 005a4010 FUN_005a4010

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


