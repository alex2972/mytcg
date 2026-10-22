005a1580 FUN_005a1580 size=1132

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a1580(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  undefined4 uVar3;
  uint uVar4;
  int iVar5;
  uint uVar6;
  uint uVar7;
  byte bVar8;
  byte bVar9;
  int iVar10;
  
  uVar3 = DAT_00a57840;
  bVar9 = (byte)param_1;
  bVar8 = (bVar9 + 1) * -2 ^ (byte)DAT_00a57840;
  DAT_00a57840._0_2_ = (ushort)DAT_00a57840 ^ bVar8 & 2;
  uVar2 = (ushort)DAT_00a57840;
  uVar4 = DAT_00a57840;
  switch(_DAT_00a577fc & 0xff) {
  case 0:
    iVar5 = FUN_0056bf20(param_1,((ushort)DAT_00a57840 & 0x700) >> 8);
    if (iVar5 == 0) {
      iVar5 = FUN_0056c460(param_1,DAT_00a57840 >> 8 & 7);
      if (iVar5 == 0) {
        iVar10 = 1 - param_1;
        iVar5 = FUN_0056dcc0(iVar10,0x422);
        if (0 < iVar5) {
          FUN_005b9170(-(uint)(iVar10 != 0) & 0x8000 | 0x1e,0x422,0,0);
          iVar5 = FUN_0056dcc0(iVar10,0x422);
          if (iVar5 == 1) {
            uVar4 = 0;
            do {
              iVar5 = FUN_0056d740(iVar10,uVar4,0x422);
              if (iVar5 != 0) break;
              uVar4 = uVar4 + 1;
            } while ((int)uVar4 < 5);
            DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,
                                    (ushort)((uVar4 & 7) << 0xb) | (ushort)DAT_00a57840 & 0xc7ff);
            _DAT_00a577fc = _DAT_00a577fc & 0xffffff04 | 4;
            return 0;
          }
          goto LAB_005a16bc;
        }
      }
      iVar5 = FUN_0056bfd0(param_1,DAT_00a57840 >> 8 & 7);
      if (iVar5 == 0) {
LAB_005a16bc:
        _DAT_00a577fc = _DAT_00a577fc & 0xffffff02 | 2;
        return 0;
      }
      if (((DAT_00a54e5c >> 1 & 3) >> (bVar9 & 0x1f) & 1) == 0) {
        FUN_005bf800(0xdf);
        FUN_005bf9a0(1,0);
        _DAT_00a577fc = _DAT_00a577fc & 0xffffff01 | 1;
        return 0;
      }
    }
    DAT_00a57840 = DAT_00a57840 | 4;
    _DAT_00a577fc = _DAT_00a577fc & 0xffffff04 | 4;
    return 0;
  case 1:
    if (DAT_00a558b4 != 0) {
      DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,(ushort)DAT_00a57840) | 4;
      _DAT_00a577fc = _DAT_00a577fc & 0xffffff04 | 4;
      return 0;
    }
    goto LAB_005a18c6;
  case 2:
    if (((DAT_00a54e5c >> 1 & 3) >> (bVar9 & 0x1f) & 1) == 0) {
      FUN_00413b20();
      goto LAB_005a18c6;
    }
    iVar5 = FUN_005b1320(param_1,((ushort)DAT_00a57840 & 0x700) >> 8);
    uVar6 = DAT_00a57840;
    if (iVar5 == 0) {
      FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x35,DAT_00a57840 >> 8 & 7,1,0);
      _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
      DAT_00a577f8._2_2_ = CONCAT11(1,DAT_00a577f8._2_1_);
      return 0;
    }
    if ((_DAT_00a579a6 & 2) != 0) {
      DAT_00a57840 = DAT_00a57840 | 4;
      _DAT_00a577fc = _DAT_00a577fc & 0xffffff04 | 4;
      return 0;
    }
    uVar4 = (_DAT_00a579a6 & 0x380) << 4 | DAT_00a57840 & 0xc7ff;
    DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,(short)uVar4);
    uVar7 = uVar4 >> 8;
    uVar6 = (uVar6 & 2) >> 1;
    break;
  case 3:
    FUN_005929d0();
    iVar5 = FUN_005aa440(0xf00000);
    if (((iVar5 == 0) ||
        (iVar5 = FUN_0056bd80(param_1,DAT_00a57840 >> 8 & 7,DAT_00a55044,DAT_00a5504c), iVar5 == 0))
       || (iVar5 = FUN_005aa480(), iVar5 == 0)) {
      if ((DAT_00a54e54 & 0x102) != 0) {
        FUN_0044ef40(2);
        FUN_005bdbd0(param_1,0,DAT_00a57840 >> 8 & 7);
        _DAT_00a577fc = _DAT_00a577fc & 0xffffff00;
        DAT_00a577f8._2_2_ = CONCAT11(1,DAT_00a577f8._2_1_);
        if ((DAT_00a57840 & 0x80) != 0) {
          FUN_005b9170(DAT_00a57840 << 0xf | 0x35,DAT_00a57840 >> 8 & 7,1,0);
        }
      }
      return 0;
    }
    DAT_00a57840 = CONCAT22(DAT_00a57840._2_2_,
                            (ushort)((DAT_00a5504c & 7) << 0xb) | (ushort)DAT_00a57840 & 0xc7ff);
LAB_005a18c6:
    bVar9 = DAT_00a577fc + 1 ^ DAT_00a577fc;
    _DAT_00a577fc = _DAT_00a577fc ^ bVar9;
    return 0;
  case 4:
    uVar1 = (ushort)DAT_00a57840 & 4;
    DAT_00a57840._1_1_ = SUB41(uVar3,1);
    DAT_00a57840 = uVar4;
    if (uVar1 != 0) {
      bVar9 = DAT_00a57840._1_1_ & 7;
      FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x34,bVar9,1,0);
      DAT_00a57840 = DAT_00a57840 & 0xffffefff | 0x2800;
      return 1;
    }
    uVar6 = (byte)DAT_00a57840 >> 1 & 1;
    uVar7 = (uint)DAT_00a57840._1_1_;
    uVar4 = (uint)uVar2;
    break;
  default:
    goto switchD_005a15bf_default;
  }
  FUN_005b9170(-(uint)(param_1 != 0) & 0x8000 | 0x33,uVar7 & 7,(uVar4 & 0x3800) >> 0xb,uVar6 + 1);
switchD_005a15bf_default:
  return 1;
}

