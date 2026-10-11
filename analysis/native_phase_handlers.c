//// FUNC 005a1240 FUN_005a1240

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a1240(uint param_1)

{
  ushort uVar1;
  byte bVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 uVar6;
  int iVar7;
  
  bVar2 = (byte)DAT_00a57840 ^ (byte)param_1;
  DAT_00a57840._0_2_ = (ushort)DAT_00a57840 ^ bVar2 & 1;
  uVar1 = (ushort)DAT_00a57840;
  uVar3 = _DAT_00a577fc & 0xff;
  if (uVar3 == 0) {
    FUN_005798f0(0,0);
    FUN_005a0d60(&DAT_00a55d64,param_1,0,0);
    DAT_00a57840._0_2_ = (ushort)DAT_00a57840 & 0xff9b;
    uVar6 = extraout_var;
    if (param_1 == (_DAT_00a54e5c & 1)) {
      FUN_005bdbd0(param_1,0,0);
      uVar6 = extraout_var_00;
    }
    FUN_005b9170(0x56,CONCAT22(uVar6,*(undefined2 *)((int)&DAT_00a55d6c + (param_1 & 1) * 0xd44 + 2)
                              ),0,0);
    bVar2 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar2;
    return 0;
  }
  if (uVar3 == 1) {
    if (((DAT_00a54e5c >> 1 & 3) >> ((byte)param_1 & 0x1f) & 1) != 0) {
      iVar5 = FUN_005b1310(param_1);
      if (iVar5 == 0) {
        _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
        DAT_00a577f8._2_2_ = CONCAT11(0xc,DAT_00a577f8._2_1_);
        return 0;
      }
      DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,
                              (DAT_00a579a6 & 0x70) << 4 | (ushort)DAT_00a57840 & 0xf8e7);
      return 1;
    }
    iVar7 = 0;
    iVar5 = FUN_005a0cd0();
    if (iVar5 != 0) {
      return 0;
    }
    iVar5 = FUN_00481a10();
    if ((iVar5 < 1) || (iVar4 = FUN_005709d0(param_1,0x246), iVar4 == 0)) {
      if (iVar5 == 4) {
        FUN_0044ef40(1);
        DAT_00a558b4 = 0;
        _DAT_00a577fc =
             CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)(_DAT_00a577fc >> 8) & 0xff,10));
        return 0;
      }
      if (iVar5 == 5) {
        FUN_0044ef40(1);
        DAT_00a558b4 = 1;
        _DAT_00a577fc = _DAT_00a577fc & 0xffffff0a | 10;
        return 0;
      }
    }
    else {
      iVar7 = 2;
    }
    if ((DAT_00a54e54 & 0x102) != 0) {
      iVar7 = FUN_005709d0(param_1,0x246);
      iVar7 = iVar7 + 1;
    }
    if (iVar7 == 0) {
      return 0;
    }
    FUN_005bf800(0xdd - (uint)(iVar7 == 2));
    FUN_005bf9a0(3,2);
    _DAT_00a577fc = _DAT_00a577fc & 0xffffff0a | 10;
    return 0;
  }
  if (uVar3 != 10) {
    DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,(ushort)DAT_00a57840) & 0xffffff67;
    FUN_00413af0((uVar1 & 0x700) >> 8);
    return 1;
  }
  if (DAT_00a558b4 == 2) {
    _DAT_00a577fc = _DAT_00a577fc & 0xffffff01 | 1;
    return 0;
  }
  uVar3 = FUN_005709d0(param_1,0x246);
  iVar5 = DAT_00a558b4 - uVar3;
  if (iVar5 == -1) {
    _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
    DAT_00a57800._0_2_ = (ushort)DAT_00a57800 & 0x7fff;
    DAT_00a577f8._2_2_ = CONCAT11(0xc,DAT_00a577f8._2_1_);
    return 0;
  }
  if (DAT_00a558b4 != uVar3) {
    if (iVar5 != 1) {
      return 0;
    }
    _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
    DAT_00a57800._0_2_ = (ushort)DAT_00a57800 | 0x8000;
    DAT_00a577f8._2_2_ = CONCAT11(0xc,DAT_00a577f8._2_1_);
    return 0;
  }
  _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
  DAT_00a57800._0_2_ = (ushort)DAT_00a57800 & 0x7fff;
  DAT_00a577f8._2_2_ = CONCAT11(0xc,DAT_00a577f8._2_1_);
  FUN_005797c0(param_1,0x246,1);
  return 0;
}


//// FUNC 005a1a00 FUN_005a1a00

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

bool FUN_005a1a00(uint param_1)

{
  uint uVar1;
  ushort uVar2;
  int iVar3;
  undefined4 uVar4;
  byte bVar5;
  uint uVar6;
  
  uVar6 = DAT_00a57840 >> 8 & 7;
  uVar2 = *(ushort *)(&DAT_00a55d74 + uVar6 * 0x24 + (param_1 & 1) * 0x351);
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    if ((DAT_00a57840 & 8) == 0) {
      iVar3 = FUN_0056b730(param_1,uVar6,1);
      if (iVar3 == 0) {
        FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x35,DAT_00a57840 >> 8 & 7,1,0);
        DAT_00a577f8._2_2_ = CONCAT11(1,DAT_00a577f8._2_1_);
        return false;
      }
      FUN_005a0e30();
      DAT_00a57840 = DAT_00a57840 | 8;
      uVar2 = FUN_004022e0(uVar2 & 0xfff);
      bVar5 = (byte)param_1;
      if (uVar2 < 0x2e9) {
        if (uVar2 == 0x2e8) {
LAB_005a1baa:
          if (((DAT_00a54e5c >> 1 & 3) >> (bVar5 & 0x1f) & 1) == 0) {
            FUN_005bf800(0xe0);
            _DAT_00a577fc =
                 CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)(_DAT_00a577fc >> 8) & 0xff,100));
            return false;
          }
          uVar6 = FUN_005aed60(param_1,CONCAT11(DAT_00a57840._1_1_,bVar5) & 0x7ff,0);
          if (-1 < (int)uVar6) {
            FUN_00577b30(uVar6 & 0xff,uVar6 >> 8 & 0xff);
            return true;
          }
          FUN_005b9170(DAT_00a57840 << 0xf | 0x35,DAT_00a57840 >> 8 & 7,1,0);
          _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
          DAT_00a577f8._2_2_ = CONCAT11(1,DAT_00a577f8._2_1_);
          return false;
        }
        if (uVar2 < 0x227) {
          if (uVar2 == 0x226) {
            FUN_00578460(param_1,1000);
            return true;
          }
          if (uVar2 == 0x16e) {
            if (((DAT_00a54e5c >> 1 & 3) >> (bVar5 & 0x1f) & 1) == 0) {
              FUN_005bf800(0x38);
              FUN_005bf9a0(7,0);
            }
            else {
              DAT_00a558b4 = 0;
            }
            _DAT_00a577fc =
                 CONCAT22(_DAT_00a577fe,(short)CONCAT31((uint3)(_DAT_00a577fc >> 8) & 0xff,200));
            return false;
          }
        }
        else if (0x2d5 < uVar2) {
          if (0x2d8 < uVar2) {
            return true;
          }
          goto LAB_005a1b92;
        }
      }
      else {
        if (uVar2 == 0x2f9) goto LAB_005a1baa;
        if (uVar2 == 0x2fe) {
LAB_005a1b92:
          FUN_00578460(param_1,500);
          return true;
        }
      }
    }
    break;
  case 100:
    iVar3 = FUN_005aa440(0xf000f0);
    uVar6 = DAT_00a55044;
    if (iVar3 != 0) {
      uVar1 = DAT_00a5504c + DAT_00a55048;
      iVar3 = FUN_0056a140(param_1,DAT_00a55044,uVar1);
      if ((iVar3 != 0) &&
         (((uVar6 != param_1 || (uVar1 != (DAT_00a57840 >> 8 & 7))) &&
          (iVar3 = FUN_005aa480(), iVar3 != 0)))) {
        FUN_00577b30(uVar6,uVar1);
        bVar5 = DAT_00a577fc + 1 ^ DAT_00a577fc;
        _DAT_00a577fc = _DAT_00a577fc ^ bVar5;
      }
    }
    return false;
  case 0x65:
    iVar3 = FUN_005a0f00(param_1);
    return iVar3 == 0;
  case 200:
    uVar6 = FUN_005bddb0(2);
    FUN_005b9170(CONCAT31((uint3)(-(uint)(param_1 != 0) >> 8) & 0x80,0xe0),DAT_00a558b4,uVar6,
                 DAT_00a57840 >> 8 & 7);
    if (uVar6 != DAT_00a558b4) {
      uVar4 = FUN_005be070((&DAT_00a55d64)[(param_1 & 1) * 0x6a2]);
      FUN_00578460(param_1,uVar4);
    }
  }
  return true;
}


