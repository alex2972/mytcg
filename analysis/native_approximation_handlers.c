//// FUNC 0058bb10 FUN_0058bb10

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

char FUN_0058bb10(undefined2 *param_1)

{
  byte bVar1;
  ushort uVar2;
  ushort uVar3;
  int iVar4;
  uint uVar5;
  undefined4 uVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  uint uVar10;
  uint uStack_8;
  ushort *puStack_4;
  
  uVar7 = DAT_00a577f8._2_1_ & 1 ^ (uint)(DAT_00a55c88._2_2_ >> 8);
  switch(DAT_00a55c88._2_2_ & 0xff) {
  case 0x77:
    uVar7 = 0;
    do {
      uVar10 = DAT_00a577f8._2_1_ & 1 ^ uVar7;
      FUN_00576170(uVar10,param_1[uVar10 + 5]);
      uVar7 = uVar7 + 1;
    } while ((int)uVar7 < 2);
    FUN_00579890();
    break;
  case 0x78:
    uVar6 = FUN_0056d3f0(uVar7);
    FUN_00579930(uVar7,3,uVar6);
    DAT_00a55c88._2_2_ = (DAT_00a55c88._2_2_ & 0xff00) + 0x100 ^ DAT_00a55c88._2_2_ & 0xff;
    return (-((DAT_00a55c88._2_2_ & 0xff00) < 0x200) & 7U) + 0x77;
  case 0x7b:
    FUN_005ada20(uVar7,&DAT_00a56434 + (uint)_DAT_00a57822 + (uVar7 & 1) * 0x351,0,1,0,0xb,
                 (uint)_DAT_00a57822);
    bVar1 = FUN_0056a030(uVar7);
    param_1[uVar7 + 5] = param_1[uVar7 + 5] | (ushort)(1 << (bVar1 & 0x1f));
    param_1[uVar7 + 3] = param_1[uVar7 + 3] + -1;
    return (-(param_1[uVar7 + 3] != 0) & 4U) + 0x78;
  case 0x7c:
    FUN_005bcee0(uVar7,*param_1);
    return '{';
  case 0x7d:
    FUN_005bcf40(uVar7,0x47d);
    return '|';
  case 0x7e:
    if (param_1[uVar7 + 3] != 0) {
      uVar5 = uVar7 & 1;
      iVar8 = 0;
      uStack_8 = 0;
      uVar10 = 0;
      if (*(char *)(&DAT_00a55d68 + uVar5 * 0x6a2) != '\0') {
        puStack_4 = (ushort *)(&DAT_00a56434 + uVar5 * 0x351);
        do {
          uVar2 = *puStack_4 & 0xfff;
          iVar9 = FUN_00402690(uVar2);
          if (((iVar9 != 0) && (uVar3 = FUN_004026c0(uVar2), uVar3 < 5)) &&
             (((DAT_00a55c8c >> ((byte)uVar7 & 0x1f) & 1) != 0 &&
              (iVar9 = FUN_00567a00(uVar2), iVar9 == 0)))) {
            uStack_8 = uStack_8 + 1;
          }
          iVar8 = iVar8 + 1;
          puStack_4 = puStack_4 + 2;
          uVar10 = uStack_8;
        } while (iVar8 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar5 * 0x6a2));
      }
      iVar8 = FUN_0056a000(uVar7);
      if (iVar8 <= (int)uVar10) {
        uVar10 = FUN_0056a000(uVar7);
      }
      FUN_00579930(uVar7,3,1);
      FUN_00579930(uVar7,4,1);
      if (((DAT_00a54e5c >> 1 & 3) >> ((byte)uVar7 & 0x1f) & 1) != 0) {
        FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar7 != 0) >> 8) & 0x80,0xf1),0x3c,0,0);
      }
      uVar5 = (uint)(ushort)param_1[uVar7 + 3];
      if ((int)uVar10 < (int)(uint)(ushort)param_1[uVar7 + 3]) {
        uVar5 = uVar10;
      }
      param_1[uVar7 + 3] = (short)uVar5;
      if ((short)uVar5 != 0) {
        return '}';
      }
    }
    return 'x';
  case 0x7f:
    DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ & 0xff;
    bVar1 = FUN_00570b40(0);
    uVar2 = FUN_00570b40(1);
    _DAT_00a55c8c =
         CONCAT22(_DAT_00a55c8e,
                  (ushort)(bVar1 ^ DAT_00a55c8c) ^ (ushort)_DAT_00a55c8c | (uVar2 & 0x7f) << 1);
    FUN_00579810();
    return '~';
  case 0x80:
    if ((*(byte *)(param_1 + 2) & 4) == 0) {
      param_1[4] = 0;
      param_1[3] = 0;
      param_1[6] = 0;
      param_1[5] = 0;
      uVar7 = FUN_00577a40(param_1,0x1f001f);
      uStack_8 = 0;
      do {
        iVar8 = 0;
        iVar9 = uStack_8 << 4;
        do {
          if ((uVar7 & 1 << ((byte)iVar9 & 0x1f)) != 0) {
            uVar10 = *(uint *)((int)&DAT_00a55d74 + (uStack_8 & 1) * 0xd44 + iVar8) & 0xfff;
            iVar4 = FUN_00402690(uVar10);
            if ((iVar4 != 0) &&
               (((uVar2 = FUN_004022e0(uVar10), uVar2 < 0x780 ||
                 (uVar2 = FUN_004022e0(uVar10), 0x783 < uVar2)) &&
                (iVar4 = FUN_00567ad0(uVar10), iVar4 == 0)))) {
              param_1[(*(uint *)((int)&DAT_00a55d74 + (uStack_8 & 1) * 0xd44 + iVar8) >> 0xc & 1) +
                      3] = param_1[(*(uint *)((int)&DAT_00a55d74 + (uStack_8 & 1) * 0xd44 + iVar8)
                                    >> 0xc & 1) + 3] + 1;
            }
          }
          iVar8 = iVar8 + 0x90;
          iVar9 = iVar9 + 1;
        } while (iVar8 < 0x2d0);
        uStack_8 = uStack_8 + 1;
      } while ((int)uStack_8 < 2);
      return '\x7f';
    }
  }
  return '\0';
}


//// FUNC 00581790 FUN_00581790

undefined4 FUN_00581790(undefined2 *param_1,undefined4 param_2,int param_3)

{
  uint uVar1;
  short sVar2;
  uint uVar3;
  undefined4 uVar4;
  int iVar5;
  
  uVar1 = *(uint *)(param_1 + 8);
  if (param_3 != 0) {
    return 0;
  }
  if ((param_1[1] & 0xfc0) != 0x700) {
    return 0;
  }
  uVar3 = (ushort)param_1[1] & 1;
  if ((uVar1 >> 0x11 & 1) == uVar3) {
    return 0;
  }
  if ((uVar1 >> 8 & 1) != uVar3) {
    return 0;
  }
  uVar4 = FUN_00568b90(uVar1 & 0xff);
  sVar2 = FUN_004022e0(*param_1);
  if (sVar2 == 0x46e) {
    if ((uVar1 & 0x1e00) < 0xa00) {
      return 0;
    }
    sVar2 = FUN_004025d0(uVar4);
    if (sVar2 == 0x15) {
      return 0;
    }
  }
  else {
    if (sVar2 != 0x46f) {
      if (sVar2 != 0x47d) {
        return 0;
      }
      if (0x9ff < (uVar1 & 0x1e00)) {
        return 0;
      }
      iVar5 = FUN_00402690(uVar4);
      if (iVar5 == 0) {
        return 0;
      }
      if ((uVar1 & 0x3c0000) != 0x2c0000) {
        return 0;
      }
      return 1;
    }
    if ((uVar1 & 0x1e00) < 0xa00) {
      return 0;
    }
    sVar2 = FUN_004025d0(uVar4);
    if (sVar2 != 0x15) {
      return 0;
    }
  }
  if (((uVar1 & 0x400000) == 0) && ((uVar1 & 0x3c0000) == 0x380000)) {
    return 1;
  }
  return 0;
}


//// FUNC 0058e670 FUN_0058e670

uint FUN_0058e670(uint param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  
  iVar1 = param_1;
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    switch(DAT_00a55c88._2_1_) {
    case 0x7c:
      FUN_00579890();
      break;
    case 0x80:
      uVar3 = FUN_0056a000(*(byte *)(param_1 + 2) & 1);
      if ((int)uVar3 < 4) goto LAB_0058e776;
      iVar2 = FUN_00570b40(*(byte *)(iVar1 + 2) & 1);
      uVar3 = 0;
      if ((iVar2 == 0) ||
         (uVar3 = *(byte *)(iVar1 + 2) & 1,
         (*(uint *)(&DAT_00a56430 + uVar3 * 0xd44) & 0x10000) != 0)) goto LAB_0058e776;
      FUN_00579810();
    case 0x7d:
    case 0x7e:
    case 0x7f:
      iVar2 = FUN_0056a000(*(byte *)(iVar1 + 2) & 1);
      if (iVar2 != 0) {
        uVar3 = FUN_00402460(0x782);
        uVar4 = *(byte *)(iVar1 + 2) & 1;
        param_1 = uVar4 << 0xc | uVar3 & 0xfff;
        FUN_005ada20(uVar4,&param_1,1,1,1,0,0);
        return DAT_00a55c88._2_1_ - 1;
      }
    }
  }
  FUN_00579930(*(byte *)(iVar1 + 2) & 1,0x14,1);
  uVar3 = FUN_00579930(*(byte *)(iVar1 + 2) & 1,0x15,1);
LAB_0058e776:
  return uVar3 & 0xffff0000;
}


//// FUNC 005821a0 FUN_005821a0

bool FUN_005821a0(int param_1)

{
  uint uVar1;
  int iVar2;
  
  uVar1 = *(byte *)(param_1 + 2) & 1;
  if ((*(uint *)(&DAT_00a56430 + uVar1 * 0xd44) & 0x10000) != 0) {
    return false;
  }
  iVar2 = FUN_0056a000(uVar1);
  if (iVar2 < 4) {
    return false;
  }
  iVar2 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
  return iVar2 != 0;
}


//// FUNC 0058a660 FUN_0058a660

uint FUN_0058a660(uint param_1)

{
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    param_1 = FUN_00579930(*(byte *)(param_1 + 2) & 1,2,1);
  }
  return param_1 & 0xffff0000;
}


//// FUNC 00589610 FUN_00589610

undefined4 FUN_00589610(undefined2 *param_1)

{
  ushort uVar1;
  undefined2 uVar2;
  undefined4 in_EAX;
  int iVar3;
  undefined4 uVar4;
  undefined2 extraout_var;
  
  uVar1 = param_1[1];
  uVar2 = (undefined2)((uint)in_EAX >> 0x10);
  if ((uVar1 & 0x3000) == 0x2000) {
    switch(DAT_00a55c88._2_1_) {
    case 0x7c:
      FUN_005b9170(CONCAT22(uVar2,uVar1) << 0xf | 0x60,0,0,0);
      break;
    case 0x7e:
      uVar4 = FUN_0040cab0(1,0,0xd,uVar1 & 1);
      FUN_005adb10(*(byte *)(param_1 + 1) & 1,uVar4);
      return 0x7d;
    case 0x7f:
      uVar2 = FUN_004022e0(CONCAT22(uVar2,*param_1),0);
      FUN_0040c940(*(byte *)(param_1 + 1) & 1,6,uVar2);
      return 0x7e;
    case 0x80:
      iVar3 = FUN_00570b40(uVar1 & 1);
      if ((iVar3 != 0) && (iVar3 = FUN_0056a000(*(byte *)(param_1 + 1) & 1), iVar3 != 0)) {
        uVar4 = FUN_004022e0(*param_1,0);
        iVar3 = FUN_00599e30(*(byte *)(param_1 + 1) & 1,uVar4);
        if (iVar3 != 0) {
          uVar2 = FUN_004022e0(CONCAT22(extraout_var,*param_1),0);
          FUN_005797c0(*(byte *)(param_1 + 1) & 1,uVar2);
          if ((~(byte)((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1)) & 1) != 0) {
            FUN_005bf800(0x30);
          }
          return 0x7f;
        }
      }
    }
  }
  else {
    FUN_00579790(uVar1 & 1,*param_1,3);
    if ((~(byte)((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1)) & 1) != 0) {
      FUN_005bf800(0xa2);
      return 0;
    }
  }
  return 0;
}


//// FUNC 00581050 FUN_00581050

undefined4 FUN_00581050(undefined2 *param_1,int param_2)

{
  ushort uVar1;
  int iVar2;
  undefined4 uVar3;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  
  uVar1 = param_1[1];
  if ((uVar1 & 0x3000) == 0x2000) {
    if (param_2 != 0) {
      return 0;
    }
    if ((((byte)uVar1 ^ DAT_00a577f8._2_1_) & 1) != 0) {
      return 0;
    }
    if (((byte)DAT_00a577ec & 1) != 0) {
      return 0;
    }
    iVar2 = FUN_00570b40(uVar1 & 1);
    if (iVar2 == 0) {
      return 0;
    }
    iVar2 = FUN_0056a000(*(byte *)(param_1 + 1) & 1);
    if (iVar2 == 0) {
      return 0;
    }
    if ((*(uint *)(&DAT_00a56430 + (*(byte *)(param_1 + 1) & 1) * 0xd44) & 0x1000000) == 0) {
      return 0;
    }
    uVar3 = FUN_004022e0(CONCAT22(extraout_var_00,*param_1));
    iVar2 = FUN_005709d0(*(byte *)(param_1 + 1) & 1,uVar3);
    if (iVar2 == 0) {
      return 0;
    }
    uVar3 = FUN_004022e0(CONCAT22(extraout_var,*param_1),0);
    iVar2 = FUN_00599e30(*(byte *)(param_1 + 1) & 1,uVar3);
    if (iVar2 == 0) {
      return 0;
    }
  }
  return 1;
}


//// FUNC 0058f2d0 FUN_0058f2d0

uint FUN_0058f2d0(undefined2 *param_1)

{
  ushort uVar1;
  uint in_EAX;
  int iVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    iVar2 = FUN_00583470(param_1,0,0);
    in_EAX = 0;
    if (iVar2 != 0) {
      uVar3 = FUN_00583440(param_1,0);
      uVar5 = uVar3 >> 8 & 0xff;
      iVar2 = FUN_00583510(param_1,uVar3 & 0xff,uVar5);
      in_EAX = 0;
      if (iVar2 != 0) {
        in_EAX = (&DAT_00a55d74)[uVar5 * 0x24 + (uVar3 & 1) * 0x351];
        if ((in_EAX & 0xfff) != 0) {
          uVar6 = in_EAX >> 0x18;
          uVar4 = in_EAX >> 0xc;
          iVar2 = FUN_00577950(param_1,uVar3 & 0xff,uVar5,0x40);
          in_EAX = 0;
          if (iVar2 != 0) {
            uVar1 = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar5 * 0x24 + (uVar3 & 1) * 0x351) &
                                 0xfff);
            if (0x77f < uVar1) {
              in_EAX = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar5 * 0x24 + (uVar3 & 1) * 0x351)
                                    & 0xfff);
              if ((ushort)in_EAX < 0x784) goto LAB_0058f3c8;
            }
            in_EAX = FUN_00579790(*(byte *)(param_1 + 1) & 1,*param_1,
                                  ((uVar4 & 1) + (uVar6 & 0x7f) * 2) * 0x100 | 0x23);
          }
        }
      }
    }
  }
LAB_0058f3c8:
  return in_EAX & 0xffff0000;
}


//// FUNC 0057bd90 FUN_0057bd90

bool FUN_0057bd90(undefined2 *param_1,uint param_2)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  undefined2 extraout_var;
  uint uVar5;
  
  uVar5 = param_2 & 0xff;
  uVar4 = param_2 >> 8 & 0xff;
  uVar1 = *(ushort *)(&DAT_00a55d74 + uVar4 * 0x24 + (param_2 & 1) * 0x351);
  iVar3 = FUN_0056c510(uVar5,uVar4);
  if (iVar3 == 0) {
    return false;
  }
  sVar2 = FUN_004025d0(CONCAT22(extraout_var,*param_1));
  if (sVar2 == 0x16) {
    iVar3 = FUN_0056c460(uVar5,uVar4);
    if (iVar3 != 0) {
      return false;
    }
  }
  if (uVar5 != (*(byte *)(param_1 + 1) & 1)) {
    return false;
  }
  if (4 < uVar4) {
    return false;
  }
  return (uVar1 & 0xfff) != 0;
}


//// FUNC 00594b70 FUN_00594b70

void FUN_00594b70(int param_1,undefined4 param_2)

{
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
    FUN_005b3fa0(param_1,param_2,0);
    return;
  }
  FUN_00593440(param_1,param_2);
  return;
}


//// FUNC 00590870 FUN_00590870

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00590870(undefined2 *param_1)

{
  byte *pbVar1;
  undefined2 *puVar2;
  int iVar3;
  
  puVar2 = param_1;
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '~') {
    pbVar1 = (byte *)(param_1 + 1);
    param_1 = (undefined2 *)(_DAT_00a57824 << 0x10 | (uint)_DAT_00a57822);
    iVar3 = 1 - (*pbVar1 & 1);
    FUN_005adb10(iVar3,&param_1,1,0x20,0xe,iVar3);
    return 0x7d;
  }
  if (DAT_00a55c88._2_1_ == '\x7f') {
    if (_DAT_00a57822 != 0) {
      FUN_005bcfc0(1 - (*(byte *)(param_1 + 1) & 1),*param_1,0);
      return 0x7e;
    }
  }
  else if (DAT_00a55c88._2_1_ == -0x80) {
    iVar3 = FUN_00599e30(1 - (*(byte *)(param_1 + 1) & 1),0x5f0,0);
    if (iVar3 == 0) {
      return 0;
    }
    iVar3 = FUN_0056a000(1 - (*(byte *)(puVar2 + 1) & 1));
    if (iVar3 == 0) {
      return 0;
    }
    iVar3 = FUN_00570b40(1 - (*(byte *)(puVar2 + 1) & 1));
    if (iVar3 == 0) {
      return 0;
    }
    FUN_005bcf40(1 - (*(byte *)(puVar2 + 1) & 1),0x5f0);
    return 0x7f;
  }
  return 0;
}


//// FUNC 005830b0 FUN_005830b0

undefined4 FUN_005830b0(undefined2 *param_1)

{
  undefined4 uVar1;
  int iVar2;
  
  uVar1 = FUN_004022e0(*param_1,0);
  iVar2 = FUN_00599e30(1 - (*(byte *)(param_1 + 1) & 1),uVar1);
  if (iVar2 != 0) {
    iVar2 = FUN_0056a000(1 - (*(byte *)(param_1 + 1) & 1));
    if (0 < iVar2) {
      iVar2 = FUN_00570b40(1 - (*(byte *)(param_1 + 1) & 1));
      if (iVar2 != 0) {
        return 1;
      }
    }
  }
  return 0;
}


//// FUNC 00590d80 FUN_00590d80

uint FUN_00590d80(ushort *param_1)

{
  ushort uVar1;
  ushort uVar2;
  short sVar3;
  uint uVar4;
  undefined4 uVar5;
  uint uVar6;
  int iVar7;
  uint uVar8;
  undefined3 uVar9;
  uint uVar10;
  uint uVar11;
  ushort *puStack_10;
  
  uVar1 = param_1[1];
  uVar11 = uVar1 & 1;
  uVar4 = uVar1 >> 1 & 0x1f;
  uVar5 = FUN_0056a400(uVar11);
  uVar8 = ((byte)(&DAT_00a55d7a)[uVar11 * 0xd44 + uVar4 * 0x90] & 0x3c) >> 2;
  uVar6 = 0;
  if ((param_1[2] & 4) == 0) {
    uVar2 = param_1[1];
    uVar6 = uVar2 & 1;
    if (((ushort)(&DAT_00a55d74)[(uVar2 >> 1 & 0x1f) * 0x24 + (uVar2 & 1) * 0x351] & 0xfff) ==
        *param_1) {
      if ((uVar2 & 0x3000) == 0) {
        uVar6 = FUN_005b9170((uint)uVar2 << 0xf | 0xe5,0,(uVar2 & 0x3e) >> 1,0);
        return uVar6 & 0xffff0000;
      }
      uVar6 = (uint)uVar2;
      switch(uVar8) {
      case 0:
        sVar3 = 0x605;
        break;
      case 1:
        sVar3 = 0x606;
        break;
      case 2:
        sVar3 = 0x607;
        break;
      case 3:
        sVar3 = 0x608;
        break;
      default:
        goto LAB_0059101a;
      }
      iVar7 = FUN_00569300(uVar11,sVar3);
      if (iVar7 != 0) {
        uVar6 = -(uint)((uVar1 & 1) != 0) & 0x8000;
        uVar9 = (undefined3)(uVar6 >> 8);
        FUN_005b9170(CONCAT31(uVar9,0x8b),uVar4,1,0);
        FUN_005791d0(uVar11,sVar3,uVar5);
        FUN_005b9170(CONCAT31(uVar9,0xe5),uVar8 + 1,uVar5,0);
        uVar6 = FUN_005b9170(uVar6 | 0x60,0,0,0);
        return uVar6 & 0xffff0000;
      }
      iVar7 = 0;
      uVar6 = 0;
      if (*(char *)(&DAT_00a55d68 + uVar11 * 0x6a2) != '\0') {
        puStack_10 = (ushort *)(&DAT_00a56434 + uVar11 * 0x351);
        while (uVar6 = FUN_004022e0(*puStack_10 & 0xfff), (short)uVar6 != sVar3) {
          iVar7 = iVar7 + 1;
          puStack_10 = puStack_10 + 2;
          if ((int)(uint)*(byte *)(&DAT_00a55d68 + uVar11 * 0x6a2) <= iVar7) {
            return uVar6 & 0xffff0000;
          }
        }
        uVar10 = -(uint)((uVar1 & 1) != 0) & 0x8000;
        FUN_005b9170(CONCAT31((int3)(uVar10 >> 8),0x8b),uVar4,1,0);
        uVar6 = (&DAT_00a56434)[iVar7 + uVar11 * 0x351];
        FUN_00576110(uVar11,0xb,(uVar6 >> 0xc & 1) + (uVar6 >> 0x18 & 0x7f) * 2,uVar11,uVar5,1,0);
        FUN_005b9170(uVar10 | 0xe5,uVar8 + 1,uVar5,0);
        uVar6 = (&DAT_00a56434)[iVar7 + uVar11 * 0x351];
        iVar7 = FUN_00570c70(uVar11,(uVar6 >> 0xc & 1) + (uVar6 >> 0x18 & 0x7f) * 2);
        uVar6 = 0;
        if (iVar7 != 0) {
          uVar5 = FUN_00402460(0x443);
          FUN_00578400(uVar11,uVar5);
          uVar6 = FUN_005784e0(uVar11,2000);
        }
      }
    }
  }
LAB_0059101a:
  return uVar6 & 0xffff0000;
}


