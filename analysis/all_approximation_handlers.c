//// FUNC 00579c40 FUN_00579c40

bool FUN_00579c40(undefined2 *param_1,uint param_2)

{
  short sVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  
  uVar3 = param_2 >> 8 & 0xff;
  uVar4 = param_2 & 0xff;
  if ((*(byte *)(param_1 + 1) & 1) == uVar4) {
    return false;
  }
  if (4 < uVar3) {
    return false;
  }
  iVar2 = FUN_0056c510(uVar4,uVar3);
  if (iVar2 == 0) {
    return false;
  }
  sVar1 = FUN_004025d0(*param_1);
  if (sVar1 == 0x16) {
    iVar2 = FUN_0056c460(uVar4,uVar3);
    if (iVar2 != 0) {
      return false;
    }
  }
  return ((&DAT_00a55d74)[uVar3 * 0x24 + (param_2 & 1) * 0x351] & 0xfff) != 0;
}


//// FUNC 0057a470 FUN_0057a470

bool FUN_0057a470(undefined4 param_1,uint param_2)

{
  int iVar1;
  
  iVar1 = FUN_00579ce0(param_1,param_2);
  if (iVar1 == 0) {
    return false;
  }
  iVar1 = FUN_0056c510(param_2 & 0xff,param_2 >> 8 & 0xff);
  return iVar1 != 0;
}


//// FUNC 0057aa30 FUN_0057aa30

byte FUN_0057aa30(int param_1,uint param_2)

{
  uint uVar1;
  
  uVar1 = param_2 >> 8 & 0xff;
  if ((param_2 & 0xff) == (*(byte *)(param_1 + 2) & 1)) {
    return 0;
  }
  if (((&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar1 * 0x24] & 0xfff) == 0) {
    return 0;
  }
  return (byte)~(&DAT_00a55d7a)[uVar1 * 0x90 + (param_2 & 1) * 0xd44] >> 1 & 1;
}


//// FUNC 0057aec0 FUN_0057aec0

byte FUN_0057aec0(undefined4 param_1,uint param_2)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = param_2 >> 8 & 0xff;
  if (4 < uVar2) {
    return 0;
  }
  if (((&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar2 * 0x24] & 0xfff) == 0) {
    return 0;
  }
  iVar1 = FUN_0056c510(param_2 & 0xff,uVar2);
  if (iVar1 == 0) {
    return 0;
  }
  return (byte)(&DAT_00a55d7a)[uVar2 * 0x90 + (param_2 & 1) * 0xd44] >> 1 & 1;
}


//// FUNC 0057b0e0 FUN_0057b0e0

byte FUN_0057b0e0(int param_1,uint param_2)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = param_2 >> 8 & 0xff;
  if (4 < uVar2) {
    return 0;
  }
  if ((*(byte *)(param_1 + 2) & 1) == (param_2 & 0xff)) {
    return 0;
  }
  if (((&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar2 * 0x24] & 0xfff) == 0) {
    return 0;
  }
  iVar1 = FUN_0056c510(param_2 & 0xff,uVar2);
  if (iVar1 == 0) {
    return 0;
  }
  if ((short)param_2 == *(short *)(param_1 + 0x10)) {
    return 0;
  }
  return (byte)(&DAT_00a55d7a)[uVar2 * 0x90 + (param_2 & 1) * 0xd44] >> 1 & 1;
}


//// FUNC 0057b1f0 FUN_0057b1f0

byte FUN_0057b1f0(int param_1,uint param_2)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = param_2 >> 8 & 0xff;
  if (4 < uVar2) {
    return 0;
  }
  if ((*(byte *)(param_1 + 2) & 1) == (param_2 & 0xff)) {
    return 0;
  }
  if (((&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar2 * 0x24] & 0xfff) == 0) {
    return 0;
  }
  iVar1 = FUN_0056c510(param_2 & 0xff,uVar2);
  if (iVar1 == 0) {
    return 0;
  }
  return (byte)(&DAT_00a55d7a)[uVar2 * 0x90 + (param_2 & 1) * 0xd44] >> 1 & 1;
}


//// FUNC 0057b3b0 FUN_0057b3b0

bool FUN_0057b3b0(undefined4 param_1,uint param_2)

{
  ushort uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  int local_4;
  
  uVar4 = param_2 >> 8 & 0xff;
  uVar6 = param_2 & 0xff;
  if ((4 < uVar4) && (uVar4 < 0xb)) {
    if ((((&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar4 * 0x24] & 0xfff) != 0) &&
       (iVar2 = FUN_00598b50(uVar6,uVar4,
                             (&DAT_00a55d74)[(param_2 & 1) * 0x351 + uVar4 * 0x24] & 0xfff),
       iVar2 != 0)) {
      uVar1 = FUN_0056fb40(uVar6,uVar4);
      if (((*(byte *)(&DAT_00a55e00 + (param_2 & 1) * 0x351 + uVar4 * 0x24) & 2) != 0) &&
         (uVar1 == 0xffff)) {
        iVar2 = 0;
        param_2 = 0;
        do {
          iVar7 = 0;
          do {
            iVar3 = FUN_0056fc50(uVar6,uVar4,iVar2,iVar7);
            if (iVar3 != 0) {
              param_2 = param_2 + 1;
            }
            iVar7 = iVar7 + 1;
          } while (iVar7 < 5);
          iVar2 = iVar2 + 1;
        } while (iVar2 < 2);
        return 1 < (int)param_2;
      }
      local_4 = 0;
      do {
        uVar5 = 0;
        do {
          if ((uVar1 != (ushort)((ushort)((uVar5 & 0xff) << 8) | (ushort)local_4 & 0xff)) &&
             (iVar2 = FUN_0056fc50(uVar6,uVar4,local_4,uVar5), iVar2 != 0)) {
            return true;
          }
          uVar5 = uVar5 + 1;
        } while ((int)uVar5 < 5);
        local_4 = local_4 + 1;
      } while (local_4 < 2);
    }
  }
  return false;
}


//// FUNC 0057bbf0 FUN_0057bbf0

undefined4 FUN_0057bbf0(int param_1,uint param_2)

{
  ushort uVar1;
  ushort uVar2;
  int iVar3;
  uint uVar4;
  
  uVar4 = param_2 >> 8 & 0xff;
  uVar2 = *(ushort *)(&DAT_00a55d74 + uVar4 * 0x24 + (param_2 & 1) * 0x351) & 0xfff;
  iVar3 = FUN_0056c510(param_2 & 0xff,uVar4);
  if (iVar3 == 0) {
    return 0;
  }
  if ((param_2 & 0xff) != (*(byte *)(param_1 + 2) & 1)) {
    return 0;
  }
  if (4 < uVar4) {
    return 0;
  }
  if (uVar2 == 0) {
    return 0;
  }
  uVar1 = FUN_004022e0(uVar2);
  if (0x77f < uVar1) {
    uVar2 = FUN_004022e0(uVar2);
    if (uVar2 < 0x784) {
      return 0;
    }
  }
  return 1;
}


//// FUNC 0057bca0 FUN_0057bca0

undefined4 FUN_0057bca0(int param_1,uint param_2)

{
  int iVar1;
  undefined4 uVar2;
  uint uVar3;
  
  uVar3 = param_2 >> 8 & 0xff;
  if (4 < uVar3) {
    return 0;
  }
  if ((*(byte *)(param_1 + 2) & 1) != (param_2 & 0xff)) {
    return 0;
  }
  iVar1 = FUN_0056c510(param_2 & 0xff,uVar3);
  if (iVar1 == 0) {
    return 0;
  }
  if ((short)param_2 == *(short *)(param_1 + 0x12)) {
    return 0;
  }
  uVar2 = FUN_0056bd80(*(undefined1 *)(param_1 + 0x10),*(undefined1 *)(param_1 + 0x11),
                       *(undefined1 *)(param_1 + 0x12),
                       (char)((ushort)*(short *)(param_1 + 0x12) >> 8));
  return uVar2;
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


//// FUNC 0057be40 FUN_0057be40

undefined4 FUN_0057be40(int param_1,uint param_2)

{
  char cVar1;
  ushort uVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  ushort *puVar6;
  uint uVar7;
  
  uVar7 = param_2 & 0xff;
  uVar4 = param_2 >> 8 & 0xff;
  if (((((*(ushort *)(&DAT_00a55d74 + (param_2 & 1) * 0x351 + uVar4 * 0x24) & 0xfff) != 0) &&
       (uVar7 != (*(byte *)(param_1 + 2) & 1))) && (uVar4 < 5)) &&
     ((((*(ushort *)(&DAT_00a55d7a + uVar4 * 0x90 + (param_2 & 1) * 0xd44) & 2) == 0 &&
       ((*(ushort *)(&DAT_00a55d7a + uVar4 * 0x90 + (param_2 & 1) * 0xd44) & 1) != 0)) &&
      (iVar3 = FUN_0056c510(uVar7,uVar4), iVar3 != 0)))) {
    iVar3 = 0;
    uVar5 = DAT_00a55c94 >> 8 & 0x7f;
    if (uVar5 != 0) {
      puVar6 = (ushort *)&DAT_00a55ca8;
      do {
        cVar1 = *(char *)((int)&DAT_00a55c94 + iVar3 + 2);
        if (((cVar1 == '\b') || (cVar1 == '\a')) &&
           ((uVar2 = *puVar6, uVar7 == (uVar2 >> 8 & 1) &&
            (((uVar4 == (uVar2 >> 9 & 0xf) && ((uVar2 & 0x4000) == 0)) && ((uVar2 & 0x2000) != 0))))
           )) {
          return 1;
        }
        iVar3 = iVar3 + 1;
        puVar6 = puVar6 + 2;
      } while (iVar3 < (int)uVar5);
    }
  }
  return 0;
}


//// FUNC 0057c060 FUN_0057c060

undefined4 FUN_0057c060(int param_1,uint param_2)

{
  short sVar1;
  uint uVar2;
  uint uVar3;
  
  uVar3 = param_2 >> 8 & 0xff;
  if ((((4 < uVar3) && (uVar3 < 0xb)) &&
      (uVar2 = param_2 & 1, ((&DAT_00a55d74)[uVar2 * 0x351 + uVar3 * 0x24] & 0xfff) != 0)) &&
     (((&DAT_00a55d7a)[uVar3 * 0x90 + uVar2 * 0xd44] & 2) != 0)) {
    sVar1 = FUN_004025d0(*(ushort *)(&DAT_00a55d74 + uVar2 * 0x351 + uVar3 * 0x24) & 0xfff);
    if ((sVar1 != 0x15) &&
       (((param_2 & 0xff) != (*(ushort *)(param_1 + 2) & 1) ||
        (uVar3 != (*(ushort *)(param_1 + 2) >> 1 & 0x1f))))) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 0057c3b0 FUN_0057c3b0

bool FUN_0057c3b0(undefined4 param_1,uint param_2)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  ushort uVar5;
  
  uVar4 = param_2 >> 8 & 0xff;
  uVar5 = *(ushort *)(&DAT_00a55d74 + (param_2 & 1) * 0x351 + uVar4 * 0x24) & 0xfff;
  if (4 < uVar4) {
    return false;
  }
  if (uVar5 == 0) {
    return false;
  }
  if (((&DAT_00a55d7a)[uVar4 * 0x90 + (param_2 & 1) * 0xd44] & 2) == 0) {
    return false;
  }
  iVar3 = FUN_0056c510(param_2 & 0xff,uVar4);
  if (iVar3 == 0) {
    return false;
  }
  uVar1 = FUN_004025d0(uVar5);
  if (0x14 < uVar1) {
    return false;
  }
  sVar2 = FUN_00402740(uVar5);
  return sVar2 == 2;
}


//// FUNC 0057c5f0 FUN_0057c5f0

undefined4 FUN_0057c5f0(int param_1)

{
  uint uVar1;
  byte bVar2;
  undefined2 extraout_var;
  
  if ((*(ushort *)(param_1 + 2) & 0x3000) != 0x2000) {
    uVar1 = FUN_005687d0(*(undefined1 *)(param_1 + 0x10));
    bVar2 = (byte)*(undefined2 *)(param_1 + 2);
    if (((bVar2 & 1) == (byte)uVar1) && (bVar2 = bVar2 >> 1 & 0x1f, bVar2 == (byte)(uVar1 >> 8))) {
      FUN_005b9170(CONCAT22(extraout_var,*(undefined2 *)(param_1 + 2)) << 0xf | 0x94,bVar2,0,
                   uVar1 >> 0x10);
    }
  }
  return 1;
}


//// FUNC 0057cb50 FUN_0057cb50

undefined4 FUN_0057cb50(int param_1)

{
  FUN_00577b30(*(ushort *)(param_1 + 2) & 1,*(ushort *)(param_1 + 2) >> 1 & 0x1f);
  return 1;
}


//// FUNC 0057cd40 FUN_0057cd40

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int __thiscall FUN_0057cd40(undefined4 param_1,undefined2 *param_2)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  undefined1 auStack_100 [256];
  
  if (((param_2[1] & 0x3000) == 0x1000) &&
     (uVar3 = CONCAT22((short)((uint)param_1 >> 0x10),param_2[1]) & 0xffff0001,
     ((DAT_00a54e5c >> 1 & 3) >> (sbyte)uVar3 & 1) == 0)) {
    uVar1 = (_DAT_00a55c8c & 0xffff) >> 8;
    if (uVar1 == 0) {
      uVar2 = FUN_00402290(CONCAT22((short)(uVar3 >> 0x10),*param_2));
      FUN_005bdf40(auStack_100,0xfa,uVar2);
      FUN_005bf800(auStack_100);
      FUN_005bf9a0(1,0);
      _DAT_00a55c8c =
           CONCAT22(_DAT_00a55c8e,((ushort)_DAT_00a55c8c & 0xff00) + 0x100 ^ (ushort)DAT_00a55c8c);
      return 0;
    }
    if (uVar1 == 1) {
      return (-(uint)(DAT_00a558b4 != 0) & 2) - 1;
    }
  }
  return 1;
}


//// FUNC 0057dc10 FUN_0057dc10

undefined4 FUN_0057dc10(int param_1)

{
  if ((DAT_00a577f8._2_1_ & 0xe) != 10) {
    FUN_005bce00(*(byte *)(param_1 + 2) & 1,1,1,0);
  }
  return 1;
}


//// FUNC 0057f240 FUN_0057f240

undefined4 FUN_0057f240(int param_1,undefined4 param_2,int param_3)

{
  uint *puVar1;
  uint uVar2;
  int iVar3;
  
  if ((param_3 == 0) &&
     (uVar2 = *(ushort *)(param_1 + 2) & 1,
     ((&DAT_00a55d7b)[uVar2 * 0xd44 + (*(ushort *)(param_1 + 2) >> 1 & 0x1f) * 0x90] & 2) != 0)) {
    iVar3 = 0;
    puVar1 = &DAT_00a55d74 + (-uVar2 - 1 & 1) * 0x351;
    do {
      if ((*puVar1 & 0xfff) != 0) {
        return 1;
      }
      iVar3 = iVar3 + 1;
      puVar1 = puVar1 + 0x24;
    } while (iVar3 < 5);
  }
  return 0;
}


//// FUNC 0057f5c0 FUN_0057f5c0

byte FUN_0057f5c0(int param_1,undefined4 param_2,int param_3)

{
  if (param_3 != 0) {
    return 0;
  }
  return (byte)(&DAT_00a55d7a)
               [(*(ushort *)(param_1 + 2) & 1) * 0xd44 +
                (*(ushort *)(param_1 + 2) >> 1 & 0x1f) * 0x90] >> 1 & 1;
}


//// FUNC 0057f9f0 FUN_0057f9f0

ushort FUN_0057f9f0(int param_1,undefined4 param_2,int param_3)

{
  ushort uVar1;
  
  if (param_3 != 0) {
    return 0;
  }
  uVar1 = *(ushort *)(param_1 + 2);
  if ((((byte)uVar1 ^ DAT_00a577f8._2_1_) & 1) != 0) {
    return 0;
  }
  if ((DAT_00a577f8._2_1_ & 0xe) != 2) {
    return 0;
  }
  if ((*(ushort *)(&DAT_00a55d7a + (uVar1 & 1) * 0xd44 + (uVar1 >> 1 & 0x1f) * 0x90) & 2) == 0) {
    return 0;
  }
  return *(ushort *)(&DAT_00a55d7a + (uVar1 & 1) * 0xd44 + (uVar1 >> 1 & 0x1f) * 0x90) >> 9 & 1;
}


//// FUNC 0057ff50 FUN_0057ff50

uint FUN_0057ff50(int param_1,undefined4 param_2,int param_3)

{
  short sVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  
  uVar2 = *(ushort *)(param_1 + 2) >> 1 & 0x1f;
  uVar4 = *(ushort *)(param_1 + 2) & 1;
  if (param_3 != 0) {
    return 0;
  }
  sVar1 = FUN_0056d560(uVar4,uVar2);
  if (sVar1 != -1) {
    return 0;
  }
  iVar3 = FUN_0056a400(uVar4);
  if (iVar3 == -1) {
    return 0;
  }
  return (*(ushort *)(&DAT_00a55d7a + uVar4 * 0xd44 + uVar2 * 0x90) & 0x200) >> 9;
}


//// FUNC 00580050 FUN_00580050

ushort FUN_00580050(int param_1,undefined4 param_2,int param_3)

{
  if (param_3 != 0) {
    return 0;
  }
  return *(ushort *)
          (&DAT_00a55d7a +
          (*(ushort *)(param_1 + 2) & 1) * 0xd44 + (*(ushort *)(param_1 + 2) >> 1 & 0x1f) * 0x90) >>
         9 & 1;
}


//// FUNC 00580100 FUN_00580100

byte FUN_00580100(int param_1,undefined4 param_2,int param_3)

{
  ushort uVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  
  uVar1 = *(ushort *)(param_1 + 2);
  uVar3 = uVar1 & 1;
  uVar4 = uVar1 >> 0xe & 1 ^ uVar3;
  if (param_3 != 0) {
    return 0;
  }
  iVar2 = FUN_0056a140(uVar4,uVar3,(uVar1 & 0x3e) >> 1);
  if (iVar2 == 0) {
    return 0;
  }
  iVar2 = FUN_0056a000(uVar4);
  if (iVar2 < (int)((uVar4 != (*(byte *)(param_1 + 2) & 1)) + 2)) {
    return 0;
  }
  iVar2 = FUN_00570b40(uVar4);
  if (iVar2 == 0) {
    return 0;
  }
  iVar2 = FUN_0056cbd0(uVar4,0x2e1);
  if (iVar2 == 0) {
    return 0;
  }
  iVar2 = FUN_0056cbd0(uVar4,0x2f4);
  if (iVar2 == 0) {
    return 0;
  }
  iVar2 = FUN_0056cbd0(uVar4,800);
  return -(iVar2 != 0) & 2;
}


//// FUNC 00580360 FUN_00580360

undefined4 FUN_00580360(int param_1)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  
  iVar3 = FUN_0056a000(*(byte *)(param_1 + 2) & 1);
  if (iVar3 != 0) {
    iVar3 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
    if (iVar3 != 0) {
      iVar3 = FUN_005699c0(0x2e4);
      if (0 < iVar3) {
        iVar3 = 0;
        uVar4 = *(byte *)(param_1 + 2) & 1;
        if (*(char *)(&DAT_00a55d68 + uVar4 * 0x6a2) != '\0') {
          do {
            uVar1 = *(ushort *)(&DAT_00a56434 + iVar3 + uVar4 * 0x351);
            sVar2 = FUN_004025d0(uVar1 & 0xfff);
            if (sVar2 == 1) {
              iVar5 = FUN_00567a00(uVar1 & 0xfff);
              if (iVar5 == 0) {
                return 1;
              }
            }
            iVar3 = iVar3 + 1;
            uVar4 = *(byte *)(param_1 + 2) & 1;
          } while (iVar3 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar4 * 0x6a2));
        }
      }
    }
  }
  return 0;
}


//// FUNC 00580600 FUN_00580600

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00580600(int param_1)

{
  int iVar1;
  int iVar2;
  ushort *puVar3;
  uint uVar4;
  undefined1 local_8 [8];
  
  uVar4 = *(ushort *)(param_1 + 2) >> 0xe & 1 ^ *(ushort *)(param_1 + 2) & 1;
  iVar1 = FUN_00570b40(uVar4);
  if (iVar1 != 0) {
    if (uVar4 == (_DAT_00a54e5c & 1)) {
      FUN_0045e240(0xe);
    }
    iVar1 = 0;
    if (((&DAT_00a55d6a)[uVar4 * 0x6a2] & 0xff00) != 0) {
      puVar3 = (ushort *)(&DAT_00a566b4 + uVar4 * 0x351);
      do {
        iVar2 = FUN_00591d10(uVar4,*puVar3 & 0xfff,local_8);
        if (iVar2 != 0) {
          return 1;
        }
        iVar1 = iVar1 + 1;
        puVar3 = puVar3 + 2;
      } while (iVar1 < (int)(uint)((ushort)(&DAT_00a55d6a)[uVar4 * 0x6a2] >> 8));
    }
  }
  return 0;
}


//// FUNC 00580960 FUN_00580960

uint FUN_00580960(undefined2 *param_1,undefined2 *param_2,int param_3)

{
  ushort uVar1;
  short sVar2;
  undefined2 uVar3;
  uint uVar4;
  int iVar5;
  undefined2 extraout_var;
  
  if (param_3 != 0) {
    return 0;
  }
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  if (0x14 < ((byte)param_2[1] & 0x3e)) {
    return 0;
  }
  if ((param_2[1] & 0x3000) != 0) {
    return 0;
  }
  sVar2 = FUN_004022e0(*param_2);
  if (sVar2 == 0x603) {
    return 0;
  }
  uVar4 = FUN_004022e0(*param_1);
  uVar4 = uVar4 & 0xffff;
  if (uVar4 < 0x427) {
    if (uVar4 == 0x426) {
      if (((*(byte *)(param_1 + 1) ^ *(byte *)(param_2 + 1)) & 1) != 0) {
        sVar2 = FUN_004022e0(CONCAT22(extraout_var,*param_2));
        return (uint)(sVar2 == 0x29f);
      }
      return 0;
    }
    uVar3 = (undefined2)(uVar4 - 0x3fb >> 0x10);
    switch(uVar4) {
    case 0x3fb:
      if (((*(byte *)(param_1 + 1) ^ *(byte *)(param_2 + 1)) & 1) != 0) {
        sVar2 = FUN_004022e0(CONCAT22(uVar3,*param_2));
        return (uint)(sVar2 == 0x14f);
      }
      return 0;
    case 0x3fd:
      if (((*(byte *)(param_1 + 1) ^ *(byte *)(param_2 + 1)) & 1) != 0) {
        sVar2 = FUN_004022e0(CONCAT22(uVar3,*param_2));
        return (uint)(sVar2 == 0x3f0);
      }
      return 0;
    case 0x3fe:
      if (((*(byte *)(param_1 + 1) ^ *(byte *)(param_2 + 1)) & 1) != 0) {
        sVar2 = FUN_004022e0(CONCAT22(uVar3,*param_2));
        return (uint)(sVar2 == 0x150);
      }
      return 0;
    case 0x405:
      sVar2 = FUN_004025d0(CONCAT22(extraout_var,*param_2));
      if (sVar2 == 0x16) {
        iVar5 = FUN_0057f130(*(byte *)(param_1 + 1) & 1,1,0,0,0);
        return (uint)(iVar5 != 0);
      }
      return 0;
    case 0x406:
      sVar2 = FUN_004025d0(*param_2);
      if (sVar2 == 0x15) {
        return (uint)(1000 < (ushort)(&DAT_00a55d64)[(*(byte *)(param_1 + 1) & 1) * 0x6a2]);
      }
      return 0;
    }
  }
  else {
    if (0x5f5 < uVar4) {
      if (uVar4 != 0x5fb) {
        return 0;
      }
      sVar2 = FUN_004025d0(*param_2);
      if (sVar2 == 0x16) {
        iVar5 = func_0x00567c90(param_2);
        return (uint)(iVar5 != 0);
      }
      return 0;
    }
    if (uVar4 == 0x5f5) {
      uVar1 = param_1[1];
      if ((DAT_00a577f8._2_1_ & 1) != 1 - (uVar1 >> 0xe & 1 ^ uVar1 & 1)) {
        return 0;
      }
      if ((ushort)((ushort)param_2[1] >> 0xe & 1 ^ param_2[1] & 1) ==
          (ushort)((ushort)((uVar1 & 0x4000) >> 0xe) ^ uVar1 & 1)) {
        return 0;
      }
      sVar2 = FUN_004025d0(*param_2);
      if (sVar2 != 0x16) {
        return 0;
      }
      uVar4 = (uint)(ushort)param_1[1];
      uVar4 = FUN_0056a140((uVar4 & 0x4000) >> 0xe ^ uVar4 & 1,uVar4 & 1,(uVar4 & 0x3e) >> 1);
      return uVar4;
    }
    if (uVar4 != 0x4df) {
      if (uVar4 != 0x529) {
        return 0;
      }
      if (((*(byte *)(param_1 + 1) ^ *(byte *)(param_2 + 1)) & 1) != 0) {
        sVar2 = FUN_004025d0(*param_2);
        return (uint)(sVar2 == 0x16);
      }
      return 0;
    }
    iVar5 = func_0x00567f80(*param_2);
    if (iVar5 == 0) {
      return 0;
    }
    uVar3 = FUN_004022e0(*param_2);
    switch(uVar3) {
    case 0x3f6:
    case 0x42e:
    case 0x42f:
    case 0x435:
      uVar4 = (uint)*(byte *)(param_1 + 1);
      break;
    default:
      goto LAB_00580bdb;
    case 0x401:
      uVar4 = -(*(byte *)(param_1 + 1) & 1) - 1;
    }
    if (*(char *)(&DAT_00a55d68 + (uVar4 & 1) * 0x6a2) != '\0') {
LAB_00580bdb:
      return 1;
    }
  }
  return 0;
}


//// FUNC 00581000 FUN_00581000

bool FUN_00581000(int param_1)

{
  return *(char *)(&DAT_00a55d68 + (-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0x6a2) != '\0';
}


//// FUNC 00581040 FUN_00581040

undefined4 FUN_00581040(void)

{
  return 1;
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


//// FUNC 00581130 FUN_00581130

bool FUN_00581130(int param_1,undefined4 param_2,int param_3)

{
  int iVar1;
  
  if (param_3 != 0) {
    return false;
  }
  if ((((byte)*(ushort *)(param_1 + 2) ^ DAT_00a577f8._2_1_) & 1) == 0) {
    return false;
  }
  if ((DAT_00a577f8._2_1_ & 0xe) != 6) {
    return false;
  }
  iVar1 = FUN_0056a000(*(ushort *)(param_1 + 2) & 1);
  if (iVar1 < 2) {
    return false;
  }
  iVar1 = FUN_00599e30(*(byte *)(param_1 + 2) & 1,0x3b1,0);
  if (iVar1 < 2) {
    return false;
  }
  iVar1 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
  return iVar1 != 0;
}


//// FUNC 00581740 FUN_00581740

bool FUN_00581740(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_00569d90(1,1,0);
  iVar2 = FUN_00569d90(0,1,0);
  return iVar1 + iVar2 != 0;
}


//// FUNC 005818c0 FUN_005818c0

bool FUN_005818c0(undefined2 *param_1,undefined2 *param_2,int param_3)

{
  byte bVar1;
  ushort uVar2;
  short sVar3;
  ushort uVar4;
  uint uVar5;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined4 uVar6;
  undefined2 extraout_var_01;
  bool bVar7;
  
  bVar1 = *(byte *)(param_1 + 8);
  if (param_3 != 0) {
    return false;
  }
  uVar5 = FUN_004022e0(*param_1);
  switch(uVar5 & 0xffff) {
  case 0x470:
    return (param_1[1] & 0xfc0) == 0x680;
  case 0x471:
    if (((param_2 != (undefined2 *)0x0) && (sVar3 = FUN_004025d0(*param_2), sVar3 == 0x16)) &&
       (sVar3 = FUN_00402700(*param_2), sVar3 == 2)) {
      return true;
    }
    break;
  case 0x472:
    if (param_2 == (undefined2 *)0x0) {
      return false;
    }
    sVar3 = FUN_004025d0(CONCAT22(extraout_var,*param_2));
    if (sVar3 != 0x16) {
      return false;
    }
    uVar6 = CONCAT22(extraout_var_01,*param_2);
    goto LAB_00581987;
  case 0x473:
    if (param_2 == (undefined2 *)0x0) {
      return false;
    }
    sVar3 = FUN_004025d0(CONCAT22((short)((uVar5 & 0xffff) - 0x470 >> 0x10),*param_2));
    if (sVar3 != 0x15) {
      return false;
    }
    uVar6 = CONCAT22(extraout_var_00,*param_2);
LAB_00581987:
    sVar3 = FUN_00402700(uVar6);
    bVar7 = sVar3 == 4;
LAB_00581993:
    if (bVar7) {
      return true;
    }
    break;
  case 0x474:
  case 0x518:
    uVar2 = param_1[1];
    uVar4 = uVar2 >> 6 & 0x3f;
    if (uVar4 == 0xe) {
      bVar7 = (*(uint *)(param_1 + 8) >> 0x18 & 0xf) == (uVar2 & 1);
    }
    else {
      if (uVar4 != 0x10) {
        return false;
      }
      bVar7 = *(byte *)(param_1 + 9) == ((byte)uVar2 & 1);
    }
    goto LAB_00581993;
  case 0x475:
    if (((ushort)bVar1 != (param_1[1] & 1)) && ((DAT_00a577f8._2_1_ & 0xe) != 0)) {
      return (param_1[1] & 0xfc0) == 0x6c0;
    }
    break;
  case 0x476:
    if ((ushort)bVar1 == (param_1[1] & 1)) {
      return (param_1[1] & 0xfc0) == 0x780;
    }
  }
  return false;
}


//// FUNC 00581de0 FUN_00581de0

bool FUN_00581de0(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_00569d90(1,1,0);
  iVar2 = FUN_00569d90(0,1,0);
  return 1 < iVar1 + iVar2;
}


//// FUNC 00581ee0 FUN_00581ee0

undefined4 FUN_00581ee0(int param_1,undefined4 param_2,uint param_3)

{
  uint uVar1;
  
  uVar1 = *(byte *)(param_1 + 2) & 1;
  if ((*(char *)(&DAT_00a55d68 + (-uVar1 - 1 & 1) * 0x6a2) != '\0') &&
     (*(byte *)(&DAT_00a55d68 + uVar1 * 0x6a2) != param_3 &&
      -1 < (int)(*(byte *)(&DAT_00a55d68 + uVar1 * 0x6a2) - param_3))) {
    return 1;
  }
  return 0;
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


//// FUNC 00582200 FUN_00582200

undefined4 FUN_00582200(void)

{
  return 2;
}


//// FUNC 00582370 FUN_00582370

bool FUN_00582370(int param_1,undefined4 param_2,int param_3)

{
  ushort uVar1;
  uint uVar2;
  
  if (param_3 != 0) {
    return false;
  }
  uVar2 = *(byte *)(param_1 + 2) & 1;
  if (*(byte *)(&DAT_00a55d68 + (-uVar2 - 1 & 1) * 0x6a2) < 6) {
    return false;
  }
  uVar1 = (&DAT_00a55d68)[uVar2 * 0x6a2];
  if (2 < (byte)uVar1) {
    return false;
  }
  return (int)(5 - (uVar1 & 0xff)) <= (int)(uint)(uVar1 >> 8);
}


//// FUNC 00582590 FUN_00582590

undefined4 FUN_00582590(int param_1,undefined2 *param_2)

{
  byte bVar1;
  ushort uVar2;
  int iVar3;
  byte extraout_AH;
  int iVar4;
  
  if (param_2 != (undefined2 *)0x0) {
    iVar3 = func_0x00567c90(param_2);
    if ((iVar3 != 0) &&
       (((ushort)param_2[1] >> 0xe & 1 ^ param_2[1] & 1) != (*(byte *)(param_1 + 2) & 1))) {
      iVar3 = FUN_00402690(*param_2);
      if (iVar3 == 0) {
        bVar1 = FUN_00583440(param_2,0);
        if (bVar1 == (*(byte *)(param_1 + 2) & 1)) {
          FUN_00583440(param_2,0);
          if (extraout_AH < 5) {
            iVar3 = 0;
            do {
              iVar4 = FUN_0056c510(*(byte *)(param_1 + 2) & 1,iVar3);
              if (iVar4 != 0) {
                iVar4 = func_0x00582520(param_2,*(byte *)(param_1 + 2) & 1,iVar3);
                if (iVar4 != 0) {
                  return 2;
                }
              }
              iVar3 = iVar3 + 1;
            } while (iVar3 < 5);
          }
        }
      }
    }
  }
  if ((((*(ushort *)(param_1 + 2) & 0xfc0) == 0x480) &&
      (uVar2 = *(ushort *)(param_1 + 2) & 1, *(byte *)(param_1 + 0x10) != uVar2)) &&
     (*(byte *)(param_1 + 0x12) == uVar2)) {
    return 1;
  }
  return 0;
}


//// FUNC 005826b0 FUN_005826b0

bool FUN_005826b0(void)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_0056a000(1);
  iVar2 = FUN_0056a000(0);
  return 1 < iVar1 + iVar2;
}


//// FUNC 00582790 FUN_00582790

byte FUN_00582790(int param_1,undefined4 param_2,int param_3)

{
  ushort uVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  
  if (param_3 != 0) {
    return 0;
  }
  uVar1 = *(ushort *)(param_1 + 2) & 0xfc0;
  if ((uVar1 != 0x200) && (uVar1 != 0x1c0)) {
    return 0;
  }
  uVar1 = *(ushort *)(param_1 + 0x10);
  uVar4 = uVar1 >> 8 & 1;
  uVar2 = uVar1 >> 9 & 0xf;
  if ((uVar1 & 0x2000) == 0) {
    return 0;
  }
  if ((uVar1 & 0x4000) != 0) {
    return 0;
  }
  if (uVar4 == (*(ushort *)(param_1 + 2) & 1)) {
    return 0;
  }
  if (((&DAT_00a55d74)[uVar4 * 0x351 + uVar2 * 0x24] & 0xfff) == 0) {
    return 0;
  }
  if ((*(ushort *)(&DAT_00a55d7a + uVar2 * 0x90 + uVar4 * 0xd44) & 1) == 0) {
    return 0;
  }
  if ((*(ushort *)(&DAT_00a55d7a + uVar2 * 0x90 + uVar4 * 0xd44) & 2) != 0) {
    return 0;
  }
  iVar3 = FUN_0056c510(uVar4,uVar2);
  return -(iVar3 != 0) & 2;
}


//// FUNC 00582890 FUN_00582890

undefined4 FUN_00582890(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  ushort *puVar4;
  
  iVar1 = FUN_005709f0(*(byte *)(param_1 + 2) & 1,0x53c);
  iVar2 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
  if (((iVar2 != 0) && (iVar2 = FUN_0056a000(*(byte *)(param_1 + 2) & 1), iVar2 != 0)) &&
     (-1 < iVar1)) {
    uVar3 = FUN_005687d0((&DAT_00a563f1)[iVar1 * 2 + (*(byte *)(param_1 + 2) & 1) * 0xd44]);
    puVar4 = (ushort *)FUN_005700f0(uVar3 & 0xff,uVar3 >> 8 & 0xff,uVar3 >> 0x10);
    if ((((char)(uVar3 >> 8) == '\x0e') && (iVar1 = FUN_00402690(*puVar4 & 0xfff), iVar1 != 0)) &&
       (iVar1 = FUN_00568bd0(puVar4), iVar1 != 0)) {
      iVar1 = FUN_005675f0(*puVar4 & 0xfff);
      if ((iVar1 != 0) && (iVar1 = FUN_00569cb0(*(byte *)(param_1 + 2) & 1), iVar1 == 0)) {
        return 0;
      }
      return 1;
    }
  }
  return 0;
}


//// FUNC 005829d0 FUN_005829d0

bool FUN_005829d0(int param_1,undefined4 param_2,int param_3)

{
  ushort uVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  int local_4;
  
  iVar5 = 0;
  iVar4 = 0;
  local_4 = 0;
  iVar2 = FUN_0056a000(*(byte *)(param_1 + 2) & 1);
  if (iVar2 == 0) {
    return false;
  }
  iVar2 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
  if (iVar2 != 0) {
    uVar3 = *(byte *)(param_1 + 2) & 1;
    if (*(char *)(&DAT_00a55d68 + uVar3 * 0x6a2) != '\0') {
      do {
        uVar1 = *(ushort *)(&DAT_00a56434 + iVar5 + uVar3 * 0x351);
        iVar2 = FUN_00402690(uVar1 & 0xfff);
        if (iVar2 == 0) {
          iVar4 = iVar4 + 1;
        }
        else {
          iVar2 = FUN_00570b70(*(byte *)(param_1 + 2) & 1,uVar1 & 0xfff);
          if (iVar2 != 0) {
            local_4 = local_4 + 1;
          }
        }
        iVar5 = iVar5 + 1;
        uVar3 = *(byte *)(param_1 + 2) & 1;
      } while (iVar5 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar3 * 0x6a2));
    }
    if ((param_3 != 0) && (iVar4 != 0)) {
      iVar4 = iVar4 + -1;
    }
    if (local_4 != 0) {
      return 1 < iVar4;
    }
    return false;
  }
  return false;
}


//// FUNC 00582b60 FUN_00582b60

undefined4 FUN_00582b60(undefined2 *param_1,undefined4 param_2,int param_3)

{
  undefined2 uVar1;
  int iVar2;
  undefined4 uVar3;
  
  if ((DAT_00a577f8._2_1_ & 0xe) == 10) {
    uVar3 = FUN_004022e0(*param_1,0);
    iVar2 = FUN_00599e30(*(byte *)(param_1 + 1) & 1,uVar3);
    if (iVar2 == 0) {
      return 0;
    }
  }
  else {
    iVar2 = FUN_005699c0(0x453);
    if (0 < iVar2) {
      return 0;
    }
    if (param_3 == 0) {
      uVar1 = 0;
    }
    else {
      uVar1 = *param_1;
    }
    iVar2 = FUN_0057f130(*(byte *)(param_1 + 1) & 1,1,uVar1,1,0);
    if (iVar2 == 0) {
      return 0;
    }
  }
  return 1;
}


//// FUNC 00582bf0 FUN_00582bf0

bool FUN_00582bf0(int param_1)

{
  ushort uVar1;
  
  uVar1 = *(ushort *)(param_1 + 2);
  if ((uVar1 & 0x3000) != 0x1000) {
    return true;
  }
  if ((uVar1 & 0xfc0) != 0x480) {
    return false;
  }
  return *(byte *)(param_1 + 0x10) != ((byte)uVar1 & 1);
}


//// FUNC 00583050 FUN_00583050

bool FUN_00583050(int param_1)

{
  int iVar1;
  
  if ((*(ushort *)(param_1 + 2) & 0x3000) != 0x2000) {
    return false;
  }
  iVar1 = FUN_0056a400(*(ushort *)(param_1 + 2) & 1);
  if (iVar1 < 0) {
    return false;
  }
  iVar1 = FUN_00568ad0(*(byte *)(param_1 + 2) & 1,(*(ushort *)(param_1 + 4) & 0x1fe0) >> 5);
  return -1 < iVar1;
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


//// FUNC 005831f0 FUN_005831f0

bool FUN_005831f0(int param_1)

{
  int iVar1;
  
  if ((*(ushort *)(param_1 + 2) & 0xfc0) != 0x480) {
    return false;
  }
  if (*(byte *)(param_1 + 0x10) == ((byte)*(ushort *)(param_1 + 2) & 1)) {
    return false;
  }
  iVar1 = FUN_0056c510(*(byte *)(param_1 + 0x10),*(undefined1 *)(param_1 + 0x11));
  return iVar1 != 0;
}


//// FUNC 005833d0 FUN_005833d0

undefined4 FUN_005833d0(int param_1,undefined4 param_2,undefined4 param_3)

{
  undefined4 uVar1;
  
  if ((*(ushort *)(param_1 + 2) & 0x3000) == 0x1000) {
    uVar1 = FUN_00580600(param_1,param_2,param_3);
    return uVar1;
  }
  return 1;
}


//// FUNC 005835f0 FUN_005835f0

int FUN_005835f0(int param_1)

{
  ushort uVar1;
  undefined2 uVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  uint uVar7;
  ushort *puVar8;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  int iVar9;
  int iVar10;
  undefined1 auStack_200 [256];
  undefined1 auStack_100 [256];
  
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
switchD_00583629_caseD_62:
    return 0;
  }
  uVar2 = (undefined2)(DAT_00a55c88._2_1_ - 0x5f >> 0x10);
  switch(DAT_00a55c88._2_1_) {
  case 0x5f:
    puVar8 = (ushort *)FUN_0040cab0();
    uVar2 = FUN_004022e0(*puVar8 & 0xfff);
    iVar4 = FUN_00576050(*(byte *)(param_1 + 2) & 1,uVar2);
    if (iVar4 != 0) {
      FUN_005b9170(CONCAT22(extraout_var,*(ushort *)(param_1 + 2)) << 0xf | 0x1f,uVar2,
                   *(undefined1 *)(&DAT_00a55d68 + (*(ushort *)(param_1 + 2) & 1) * 0x6a2),0);
      FUN_005b9170(CONCAT22(extraout_var_00,*(short *)(param_1 + 2) << 0xf) | 0x60,0,0,0);
    }
    break;
  case 0x60:
    FUN_0040c940(*(byte *)(param_1 + 2) & 1,6,0x4b2,0);
    return 0x5f;
  case 0x61:
    iVar4 = FUN_00599e30(*(byte *)(param_1 + 2) & 1,0x4b2,0);
    if (0 < iVar4) {
      FUN_005bf800(0x3c);
      return 0x60;
    }
    break;
  default:
    goto switchD_00583629_caseD_62;
  case 99:
    iVar4 = FUN_0040cac0();
    if (iVar4 == 1) {
      uVar6 = FUN_0040cab0();
      uVar6 = FUN_0056d100(*(byte *)(param_1 + 2) & 1,uVar6);
      uVar6 = FUN_0040cab0(1,1,0xb,uVar6);
      FUN_005adb10(*(byte *)(param_1 + 2) & 1,uVar6);
      return 0x61;
    }
    iVar4 = FUN_0040cac0();
    if (iVar4 == 2) {
      uVar6 = FUN_0040cab0(1,1,0xd,*(byte *)(param_1 + 2) & 1);
      FUN_005adb10(*(byte *)(param_1 + 2) & 1,uVar6);
    }
    return 0x61;
  case 100:
    FUN_0040c940(*(byte *)(param_1 + 2) & 1,6,0xf,0);
    return 99;
  case 0x6d:
    iVar4 = FUN_005aa440(0xf000f0);
    uVar3 = DAT_00a55044;
    if (iVar4 != 0) {
      iVar4 = DAT_00a5504c + DAT_00a55048;
      uVar7 = DAT_00a55044 & 1;
      uVar1 = *(ushort *)(&DAT_00a55d74 + uVar7 * 0x351 + iVar4 * 0x24);
      iVar9 = FUN_0056a140(*(byte *)(param_1 + 2) & 1,DAT_00a55044,iVar4);
      if ((iVar9 != 0) &&
         ((uVar3 == (*(byte *)(param_1 + 2) & 1) ||
          (((&DAT_00a55d7a)[iVar4 * 0x90 + uVar7 * 0xd44] & 2) != 0)))) {
        uVar6 = FUN_00402460(0x22);
        iVar9 = FUN_005674e0(uVar1 & 0xfff,uVar6);
        if ((iVar9 != 0) && (iVar9 = FUN_005aa480(), iVar9 != 0)) {
          FUN_00577b30(uVar3,iVar4);
          return 100;
        }
      }
    }
    return (-(uint)((DAT_00a54e54 & 0x102) != 0) & 10) + 0x6d;
  case 0x77:
    if (DAT_00a558b4 != 0) {
      uVar6 = FUN_00402460(0x22);
      uVar6 = FUN_00402290(uVar6);
      FUN_005bdf40(auStack_200,0x13,uVar6);
      FUN_005bf800(auStack_200);
      return 0x6d;
    }
    break;
  case 0x78:
    if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
      DAT_00a558b4 = 0;
      return CONCAT22(uVar2,0x77);
    }
    uVar6 = FUN_00402460(0x22);
    uVar6 = FUN_00402290(uVar6);
    FUN_005bdf40(auStack_100,0x39,uVar6);
    uVar6 = FUN_00402460(0x4b2);
    uVar6 = FUN_00402290(uVar6);
    FUN_005bdf40(auStack_200,auStack_100,uVar6);
    FUN_005bf800(auStack_200);
    FUN_005bf9a0(1,0);
    return 0x77;
  case 0x7f:
    uVar3 = FUN_005bddb0(2);
    FUN_005b9170(CONCAT22((short)(uVar3 >> 0x10),*(undefined2 *)(param_1 + 2)) << 0xf | 0xe0,
                 CONCAT22(extraout_var_01,DAT_00a558b4),uVar3,
                 (byte)*(undefined2 *)(param_1 + 2) >> 1 & 0x1f);
    if (uVar3 == DAT_00a558b4) {
      FUN_00576940(param_1,0x1f << ((*(byte *)(param_1 + 2) & 1) * -0x10 + 0x10 & 0x1f));
      iVar4 = FUN_0056a000(*(byte *)(param_1 + 2) & 1);
      if (((((0 < iVar4) && (iVar4 = FUN_00599e30(*(byte *)(param_1 + 2) & 1,0xf,0), 0 < iVar4)) &&
           (iVar4 = FUN_00570b40(*(byte *)(param_1 + 2) & 1), iVar4 != 0)) &&
          (iVar4 = FUN_005699c0(0x58a), iVar4 == 0)) &&
         (((iVar4 = FUN_005699a0(*(byte *)(param_1 + 2) & 1,0x22), iVar4 != 0 ||
           (iVar4 = FUN_005699a0(*(byte *)(param_1 + 2) & 1,0x4ba), iVar4 != 0)) ||
          (iVar4 = FUN_005699a0(*(byte *)(param_1 + 2) & 1,0x7f2), iVar4 != 0)))) {
        return 0x78;
      }
    }
    else {
      iVar9 = 0;
      iVar4 = 0;
      iVar10 = 0;
      do {
        uVar3 = *(byte *)(param_1 + 2) & 1;
        if ((*(uint *)((int)&DAT_00a55d74 + uVar3 * 0xd44 + iVar10) & 0xfff) != 0) {
          iVar5 = FUN_0056f690(uVar3,iVar4);
          iVar9 = iVar9 + iVar5;
        }
        iVar10 = iVar10 + 0x90;
        iVar4 = iVar4 + 1;
      } while (iVar10 < 0x2d0);
      FUN_00576940(param_1,0x1f << ((*(byte *)(param_1 + 2) & 1) << 4));
      uVar6 = FUN_005be070(iVar9);
      FUN_005784e0(*(byte *)(param_1 + 2) & 1,uVar6);
    }
    return 10;
  case 0x80:
    FUN_005b9170(CONCAT22(uVar2,*(undefined2 *)(param_1 + 2)) << 0xf | 0x94,
                 (byte)*(undefined2 *)(param_1 + 2) >> 1 & 0x1f,0,0);
    if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
      DAT_00a558b4 = FUN_005bddb0(2);
      return 0x7f;
    }
    FUN_005bf800(0x38);
    FUN_005bf9a0(7,0);
    return 0x7f;
  }
  return 10;
}


//// FUNC 00583f30 FUN_00583f30

undefined2 FUN_00583f30(void)

{
  return 0;
}


//// FUNC 00584500 FUN_00584500

uint FUN_00584500(ushort *param_1)

{
  ushort uVar1;
  ushort *puVar2;
  byte bVar3;
  short sVar4;
  int iVar5;
  undefined4 uVar6;
  ushort uVar8;
  undefined2 extraout_var;
  uint uVar7;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  
  puVar2 = param_1;
  if (((ushort)(&DAT_00a55d74)[(param_1[1] >> 1 & 0x1f) * 0x24 + (param_1[1] & 1) * 0x351] & 0xfff)
      == *param_1) {
    iVar5 = FUN_00583470(param_1,0,&param_1);
    if ((iVar5 != 0) && (iVar5 = FUN_0057a470(puVar2,param_1), iVar5 != 0)) {
      uVar6 = FUN_004025d0(CONCAT22(extraout_var_01,*puVar2));
      if ((short)uVar6 == 0x15) {
        uVar1 = puVar2[2];
        uVar8 = (ushort)((uint)uVar6 >> 0x10);
        if ((uVar1 & 4) != 0) {
          puVar2[2] = (ushort)CONCAT31((int3)(CONCAT22(uVar8,uVar1) >> 8),(char)uVar1) | 8;
          return (uint)uVar8 << 0x10;
        }
      }
      bVar3 = (byte)puVar2[1];
      FUN_00574990(puVar2[1] & 1,CONCAT11(bVar3 >> 1,bVar3) & 0x1f01,param_1);
      sVar4 = FUN_004022e0(CONCAT22(extraout_var,*puVar2));
      if ((sVar4 != 0x3c2) && (sVar4 != 0x5a8)) {
        return 0;
      }
      uVar7 = FUN_005b9170((uint)puVar2[1] << 0xf | 0x88,(byte)puVar2[1] >> 1 & 0x1f,
                           CONCAT22(extraout_var_00,puVar2[4]),0);
      return uVar7 & 0xffff0000;
    }
    *(byte *)(puVar2 + 2) = (byte)puVar2[2] | 8;
  }
  return 0;
}


//// FUNC 00585540 FUN_00585540

undefined4 FUN_00585540(undefined2 *param_1)

{
  byte bVar1;
  int iVar2;
  uint uVar3;
  undefined2 extraout_var;
  
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == 0x7f) {
    uVar3 = FUN_005bddb0(2);
    FUN_005b9170(CONCAT22((short)(uVar3 >> 0x10),param_1[1]) << 0xf | 0xe0,
                 CONCAT22(extraout_var,DAT_00a558b4),uVar3,(byte)param_1[1] >> 1 & 0x1f);
    bVar1 = (byte)param_1[1];
    FUN_005747e0(param_1[1] & 1,*param_1,CONCAT11(bVar1 >> 1,bVar1) & 0x1f01,
                 (uint)(uVar3 == DAT_00a558b4) << 8 | 0xc);
    return 10;
  }
  iVar2 = DAT_00a55c88._2_1_ - 0x80;
  if (iVar2 != 0) {
    FUN_005b9170(CONCAT22((short)((uint)iVar2 >> 0x10),param_1[1]) << 0xf | 0x94,
                 (byte)param_1[1] >> 1 & 0x1f,0,0);
    return 0;
  }
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) != 0) {
    DAT_00a558b4 = FUN_005bddb0(2);
    return 0x7f;
  }
  FUN_005bf800(0x38);
  FUN_005bf9a0(7,0);
  return 0x7f;
}


//// FUNC 00585970 FUN_00585970

uint FUN_00585970(uint param_1)

{
  ushort uVar1;
  uint uVar2;
  
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    uVar1 = *(ushort *)(param_1 + 2);
    if ((uVar1 & 0x3000) != 0x2000) {
      uVar2 = FUN_005787f0(uVar1 & 1,3000);
      return uVar2 & 0xffff0000;
    }
    param_1 = func_0x005784a0(uVar1 & 1,5000);
  }
  return param_1 & 0xffff0000;
}


//// FUNC 00585c80 FUN_00585c80

uint FUN_00585c80(undefined2 *param_1)

{
  undefined2 *puVar1;
  short sVar2;
  uint in_EAX;
  int iVar3;
  uint uVar4;
  uint uVar5;
  
  puVar1 = param_1;
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    iVar3 = FUN_00583470(param_1,0,&param_1);
    in_EAX = 0;
    if (iVar3 != 0) {
      uVar4 = (uint)param_1 >> 8 & 0xff;
      uVar5 = (uint)param_1 & 0xff;
      in_EAX = 0;
      if ((*(ushort *)(&DAT_00a55d74 + uVar4 * 0x24 + ((uint)param_1 & 1) * 0x351) & 0xfff) != 0) {
        sVar2 = FUN_004022e0(*puVar1);
        if ((sVar2 == 0x3ff) || (sVar2 == 0x4bb)) {
          iVar3 = FUN_00583510(puVar1,uVar5,uVar4);
          in_EAX = 0;
          if (iVar3 == 0) goto LAB_00585d1c;
        }
        in_EAX = FUN_00577880(puVar1,uVar5,uVar4);
      }
    }
  }
LAB_00585d1c:
  return in_EAX & 0xffff0000;
}


//// FUNC 00585e70 FUN_00585e70

uint FUN_00585e70(uint param_1)

{
  ushort uVar1;
  undefined2 uVar2;
  uint uVar3;
  uint in_EAX;
  int iVar4;
  undefined2 extraout_var;
  uint uVar5;
  uint uVar6;
  uint uVar7;
  
  uVar3 = param_1;
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return in_EAX & 0xffff0000;
  }
  iVar4 = FUN_00583470(param_1,0,&param_1);
  uVar5 = 0;
  if (iVar4 != 0) {
    uVar6 = param_1 >> 8 & 0xff;
    uVar7 = param_1 & 0xff;
    uVar5 = uVar6 * 0x90 + (param_1 & 1) * 0xd44;
    uVar1 = *(ushort *)(&DAT_00a55d74 + (param_1 & 1) * 0x351 + uVar6 * 0x24);
    if ((((uVar1 & 0xfff) != 0) && (uVar7 != (*(byte *)(uVar3 + 2) & 1))) &&
       (((&DAT_00a55d7a)[uVar5] & 2) == 0)) {
      FUN_00575160(uVar7,uVar6,1);
      FUN_00578430(uVar7,uVar1 & 0xfff);
      FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar7 != 0) >> 8) & 0x80,0xf1),0xf,0,0);
      FUN_00575160(uVar7,uVar6,0);
      uVar2 = *(undefined2 *)(uVar3 + 2);
      uVar5 = FUN_005b9170(CONCAT22(extraout_var,uVar2) << 0xf | 0x94,(byte)uVar2 >> 1 & 0x1f,0,0);
    }
  }
  return uVar5 & 0xffff0000;
}


//// FUNC 00586fb0 FUN_00586fb0

uint FUN_00586fb0(uint param_1)

{
  byte bVar1;
  undefined4 in_EAX;
  ushort uVar6;
  int iVar2;
  uint uVar3;
  uint uVar4;
  uint uVar5;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  
  uVar5 = param_1;
  uVar6 = (ushort)((uint)in_EAX >> 0x10);
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return (uint)uVar6 << 0x10;
  }
  FUN_005b9170(CONCAT22(uVar6,*(undefined2 *)(param_1 + 2)) << 0xf | 0x94,
               (byte)*(undefined2 *)(param_1 + 2) >> 1 & 0x1f,0,0);
  iVar2 = FUN_00583470(uVar5,0,&param_1);
  uVar3 = 0;
  if (iVar2 != 0) {
    uVar7 = param_1 >> 8 & 0xff;
    uVar9 = param_1 & 0xff;
    uVar3 = FUN_0056a400(*(byte *)(uVar5 + 2) & 1);
    uVar4 = *(ushort *)(uVar5 + 2) & 1;
    uVar8 = *(ushort *)(uVar5 + 2) >> 1 & 0x1f;
    if (((((&DAT_00a55d74)[uVar4 * 0x351 + uVar8 * 0x24] & 0xfff) != 0) &&
        (((&DAT_00a55d7a)[uVar8 * 0x90 + uVar4 * 0xd44] & 2) != 0)) && (-1 < (int)uVar3)) {
      func_0x00577ca0(uVar5,uVar9,uVar7,1 - uVar9,uVar3);
      bVar1 = (byte)*(ushort *)(uVar5 + 2);
      uVar4 = CONCAT22((short)(uVar5 >> 0x10),(ushort)(bVar1 & 1));
      uVar5 = FUN_005749b0(*(ushort *)(uVar5 + 2) & 1,(uVar3 & 0xff) << 8 | uVar4,
                           (uint)(bVar1 >> 1 & 0x1f) << 8 | uVar4,5);
      return uVar5 & 0xffff0000;
    }
    uVar3 = FUN_00577c60(uVar5,uVar9,uVar7);
  }
  return uVar3 & 0xffff0000;
}


//// FUNC 005871a0 FUN_005871a0

uint FUN_005871a0(uint param_1)

{
  ushort uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 uVar5;
  int iVar6;
  uint uVar7;
  uint uStack_8;
  uint uStack_4;
  
  uVar7 = param_1;
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    iVar2 = FUN_00583470(param_1,0,&uStack_8);
    uVar7 = 0;
    if (iVar2 != 0) {
      uStack_4 = uStack_8 >> 8 & 0xff;
      uVar7 = 0;
      iVar2 = 0;
      iVar6 = 0;
      do {
        iVar3 = FUN_005bddb0(2);
        if (iVar3 == 0) {
          iVar2 = iVar2 + 1;
          uVar4 = 0;
        }
        else {
          uVar4 = 1 << ((byte)iVar6 & 0x1f);
          uVar7 = uVar7 | uVar4;
        }
        iVar6 = iVar6 + 1;
      } while (iVar6 < 3);
      FUN_005b9170(CONCAT22((short)(uVar4 >> 0x10),*(undefined2 *)(param_1 + 2)) << 0xf | 0xe1,0,
                   uVar7,(byte)*(undefined2 *)(param_1 + 2) >> 1 & 0x1f);
      uVar5 = extraout_var;
      if (1 < iVar2) {
        FUN_00577880(param_1,uStack_8 & 0xff,uStack_4);
        uVar5 = extraout_var_00;
      }
      uVar1 = *(ushort *)(param_1 + 2);
      uVar7 = (&DAT_00a55d74)[(uVar1 >> 1 & 0x1f) * 0x24 + (uVar1 & 1) * 0x351];
      if ((uVar7 & 0xfff) != 0) {
        uVar7 = FUN_005b9170(CONCAT22(uVar5,uVar1) << 0xf | 0x94,(byte)uVar1 >> 1 & 0x1f,0,0);
      }
    }
  }
  return uVar7 & 0xffff0000;
}


//// FUNC 005877e0 FUN_005877e0

uint FUN_005877e0(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  uint uVar3;
  int iVar4;
  undefined4 uVar5;
  ushort uVar6;
  
  uVar6 = *(ushort *)(param_1 + 2) >> 0xe & 1 ^ *(ushort *)(param_1 + 2) & 1;
  uVar3 = 0;
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    uVar3 = (uint)DAT_00a55c88._2_1_;
    if (uVar3 == 0x7e) {
      uVar3 = FUN_00579890();
    }
    else {
      if (uVar3 == 0x7f) {
LAB_005878af:
        uVar1 = DAT_00a55c88._2_2_ >> 8;
        if (uVar1 == 0) {
          iVar4 = 0x2e1;
        }
        else if (uVar1 == 1) {
          iVar4 = 0x2f4;
        }
        else {
          iVar4 = param_1;
          if (uVar1 == 2) {
            iVar4 = 800;
          }
        }
        uVar5 = FUN_00402460(iVar4,&param_1);
        iVar4 = FUN_0056cac0(uVar6,uVar5);
        if (iVar4 != 0) {
          FUN_005adb10(uVar6,&param_1,1,0x20,0xe,uVar6);
        }
        DAT_00a55c88._2_2_ = (DAT_00a55c88._2_2_ & 0xff00) + 0x100 ^ DAT_00a55c88._2_2_ & 0xff;
        return ((DAT_00a55c88._2_2_ & 0xff00) < 0x300) + 0x7e;
      }
      uVar3 = uVar3 - 0x80;
      if ((uVar3 == 0) && (uVar3 = FUN_0056a000(uVar6), 2 < (int)uVar3)) {
        iVar4 = FUN_00570b40(uVar6);
        uVar3 = 0;
        if (iVar4 != 0) {
          iVar4 = FUN_0056cbd0(uVar6,0x2e1);
          uVar3 = 0;
          if (iVar4 != 0) {
            iVar4 = FUN_0056cbd0(uVar6,0x2f4);
            uVar3 = 0;
            if (iVar4 != 0) {
              iVar4 = FUN_0056cbd0(uVar6,800);
              uVar1 = DAT_00a55c88._2_2_;
              uVar3 = 0;
              if (iVar4 != 0) {
                DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ & 0xff;
                uVar2 = DAT_00a55c88._2_2_;
                DAT_00a55c88._2_1_ = (byte)uVar1;
                DAT_00a55c88._2_2_ = uVar2 ^ (byte)(DAT_00a55c88._2_1_ - 1 ^ DAT_00a55c88._2_1_);
                FUN_00579810();
                goto LAB_005878af;
              }
            }
          }
        }
      }
    }
  }
  return uVar3 & 0xffff0000;
}


//// FUNC 00587a90 FUN_00587a90

undefined4 FUN_00587a90(undefined2 *param_1,undefined4 param_2)

{
  ushort uVar1;
  undefined2 *puVar2;
  undefined2 uVar3;
  undefined3 uVar4;
  undefined4 in_EAX;
  undefined4 uVar5;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  int iVar6;
  undefined2 extraout_var_01;
  uint uVar7;
  undefined4 unaff_EDI;
  int iVar8;
  
  puVar2 = param_1;
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    uVar3 = (undefined2)((uint)in_EAX >> 0x10);
    uVar7 = CONCAT22(uVar3,DAT_00a55c88._2_2_);
    iVar6 = (DAT_00a55c88._2_2_ & 0xff) - 0x78;
    switch(iVar6) {
    case 0:
      FUN_005b9170(param_1[1] << 0xf | 0x60,0,0,0);
      break;
    case 1:
      FUN_00576170(*(byte *)(param_1 + 1) & 1,
                   1 << (*(byte *)((int)param_1 + 0xb) & 0x1f) |
                   1 << (*(byte *)((int)param_1 + 9) & 0x1f) |
                   1 << (*(byte *)((int)param_1 + 7) & 0x1f));
      return 0x78;
    case 2:
      if ((DAT_00a55c88._2_2_ & 0xff00) < 0x200) {
        do {
          FUN_005747e0(*(byte *)(param_1 + 1) & 1,*param_1,
                       CONCAT22((short)(uVar7 >> 0x10),param_1[((uVar7 & 0xffff) >> 8) + 4]),3);
          uVar7 = (DAT_00a55c88._2_2_ & 0xff00) + 0x100 ^ (uint)DAT_00a55c88._2_1_;
          DAT_00a55c88._2_2_ = (ushort)uVar7;
        } while ((uVar7 & 0xff00) < 0x200);
      }
      return 0x79;
    case 3:
      if (0x1ff < (DAT_00a55c88._2_2_ & 0xff00)) {
        FUN_00579890();
        DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ & 0xff;
        return 0x7a;
      }
      uVar1 = DAT_00a55c88._2_2_ >> 8;
      uVar4 = FUN_0056a030(*(byte *)(param_1 + 1) & 1);
      uVar7 = CONCAT22(extraout_var_00,param_1[1]) & 0xffff0001;
      if (((DAT_00a54e5c >> 1 & 3) >> (sbyte)uVar7 & 1) == 0) {
        FUN_0040ccb0(uVar1 + 1);
      }
      else {
        FUN_005af5a0(param_1[1] & 1,CONCAT22((short)(uVar7 >> 0x10),*param_1),0);
      }
      FUN_005b9170(0xf1,10,0,0);
      uVar5 = FUN_0040cab0(0,1,0,0xd,*(byte *)(param_1 + 1) & 1);
      FUN_005ada20(*(byte *)(param_1 + 1) & 1,uVar5);
      param_1[uVar1 + 4] = (ushort)CONCAT31(uVar4,*(undefined1 *)(param_1 + 1)) & 0xff01;
      DAT_00a55c88._2_2_ = (DAT_00a55c88._2_2_ & 0xff00) + 0x100 ^ DAT_00a55c88._2_2_ & 0xff;
      return 0x7b;
    case 4:
      FUN_00579810();
      FUN_005754a0(*(undefined1 *)(param_1 + 3),*(undefined1 *)((int)param_1 + 7),*param_1);
      DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ & 0xff;
      return 0x7b;
    case 5:
      uVar3 = FUN_004022e0(CONCAT22((short)((uint)iVar6 >> 0x10),*param_1),0);
      FUN_0040c940(*(byte *)(param_1 + 1) & 1,8,uVar3);
      return 0x7c;
    case 6:
      FUN_005bf800(0x20);
      return 0x7d;
    case 7:
      if ((DAT_00a54e54 & 0x102) != 0) {
        return CONCAT22(uVar3,0x80);
      }
      iVar6 = FUN_005aa440(0xf0);
      uVar5 = DAT_00a55044;
      if (iVar6 != 0) {
        iVar6 = DAT_00a5504c + DAT_00a55048;
        iVar8 = FUN_0059dc50(param_1,DAT_00a55044,iVar6);
        if ((iVar8 != 0) && (iVar8 = FUN_005aa480(), iVar8 != 0)) {
          FUN_005b9170(CONCAT22(extraout_var,param_1[1] << 0xf) | 8,
                       CONCAT22(extraout_var_01,(undefined2)DAT_00a55044),
                       (DAT_00a5504c & 0xff) << 8 |
                       CONCAT22(extraout_var,(ushort)(byte)DAT_00a55048),0);
          param_1._0_1_ = (undefined1)iVar6;
          puVar2[3] = CONCAT11(param_1._0_1_,(char)uVar5);
          return 0x7e;
        }
      }
      return 0x7f;
    case 8:
      iVar6 = FUN_0059dd90(param_1,param_2,0);
      if (iVar6 != 0) {
        if (((DAT_00a54e5c >> 1 & 3) >> ((byte)param_1[1] & 1) & 1) == 0) {
          FUN_005bf800(0x7c);
          return 0x7f;
        }
        uVar7 = DAT_00a57840 >> 0xb & 7;
        iVar6 = FUN_0059dc50(param_1,param_1[1] & 1,uVar7);
        while (iVar6 == 0) {
          uVar7 = (int)(uVar7 + 1) % 5;
          iVar6 = FUN_0059dc50(param_1,*(byte *)(param_1 + 1) & 1,uVar7);
        }
        iVar8 = CONCAT22((short)((uint)unaff_EDI >> 0x10),(ushort)(byte)uVar7) << 8;
        FUN_005b9170(CONCAT22((short)((uint)iVar6 >> 0x10),param_1[1]) << 0xf | 8,
                     (byte)param_1[1] & 1,iVar8,0);
        param_1[3] = *(byte *)(param_1 + 1) & 1 | (ushort)iVar8;
        return 0x7c;
      }
    }
  }
  return 0;
}


//// FUNC 00587e80 FUN_00587e80

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00587e80(undefined2 *param_1)

{
  uint *puVar1;
  
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '\x7f') {
    puVar1 = (uint *)FUN_005700f0(1 - (*(byte *)(param_1 + 1) & 1),0xb,_DAT_00a57822);
    FUN_00579790(1 - ((ushort)param_1[1] & 1),*param_1,
                 CONCAT11((char)(*puVar1 >> 0x18) * '\x02' + ((byte)(*puVar1 >> 0xc) & 1),
                          (((~(byte)param_1[1] ^ DAT_00a577f8._2_1_) & 1) + 6) * '\x10') | 3);
    FUN_00575a80(1 - (*(byte *)(param_1 + 1) & 1),puVar1,0x81);
    return 0;
  }
  if (DAT_00a55c88._2_1_ != -0x80) {
    return 0;
  }
  if (*(char *)(&DAT_00a55d68 + (-(*(byte *)(param_1 + 1) & 1) - 1 & 1) * 0x6a2) == '\0') {
    return 0;
  }
  func_0x005bcea0(1 - (*(byte *)(param_1 + 1) & 1),0);
  return 0x7f;
}


//// FUNC 00587f90 FUN_00587f90

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

char FUN_00587f90(int param_1)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  byte bVar5;
  undefined1 auStack_100 [256];
  
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return '\0';
  }
  switch(ram0x00a55c8a & 0xff) {
  case 100:
    FUN_00579890();
  default:
    return '\0';
  case 0x7d:
    uVar4 = (ram0x00a55c8a & 0xff00) + 0x100 ^ ram0x00a55c8a & 0xff;
    ram0x00a55c8a = CONCAT22(_DAT_00a55c8c,(short)uVar4);
    return (-((uVar4 & 0xff00) < 0x200) & 0x1bU) + 100;
  case 0x7e:
    if (DAT_00a558b4 != 0) {
      if ((DAT_00a54e54 & 0x102) != 0) {
        return '\x7f';
      }
      iVar3 = FUN_005aa440(1);
      if (iVar3 == 0) {
        return '~';
      }
      uVar1 = *(ushort *)(&DAT_00a56434 + DAT_00a5504c + (*(byte *)(param_1 + 2) & 1) * 0x351);
      sVar2 = FUN_004025d0(uVar1 & 0xfff);
      if (sVar2 != 1) {
        return '~';
      }
      iVar3 = FUN_00567a00(uVar1 & 0xfff);
      if (iVar3 != 0) {
        return '~';
      }
      iVar3 = FUN_005aa480();
      if (iVar3 == 0) {
        return '~';
      }
      uVar4 = *(byte *)(param_1 + 2) & 1;
      FUN_005adb10(uVar4,&DAT_00a56434 + DAT_00a5504c + uVar4 * 0x351,1,0,0xb,DAT_00a5504c);
      return '}';
    }
    break;
  case 0x80:
    ram0x00a55c8a = ram0x00a55c8a & 0xffff00ff;
    bVar5 = DAT_00a55c88._2_1_ - 1 ^ DAT_00a55c88._2_1_;
    DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ ^ bVar5;
    FUN_00579810();
  case 0x7f:
    iVar3 = FUN_00580360(param_1,0,0);
    if (iVar3 != 0) {
      if ((char)(ram0x00a55c8a >> 8) != '\0') {
        FUN_005bf800(0x23);
        FUN_005bf9a0(1,0);
        return '~';
      }
      FUN_005bdf40(auStack_100,0x24,0x1f5);
      FUN_005bf800(auStack_100);
      DAT_00a558b4 = 1;
      return '~';
    }
  }
  return 'd';
}


//// FUNC 00588d90 FUN_00588d90

uint FUN_00588d90(ushort *param_1,undefined2 *param_2)

{
  char cVar1;
  byte bVar2;
  uint in_EAX;
  uint uVar3;
  undefined2 uVar4;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  
  if ((((param_1[2] & 4) != 0) || (param_2 == (undefined2 *)0x0)) || (DAT_00a55c88._2_1_ != -0x80))
  goto switchD_00588df6_caseD_3fc;
  uVar3 = FUN_004022e0(*param_1);
  uVar3 = uVar3 & 0xffff;
  if (uVar3 < 0x427) {
    if (uVar3 == 0x426) {
      in_EAX = FUN_004022e0(CONCAT22(extraout_var,*param_2));
      if (((short)in_EAX == 0x29f) && (((*(byte *)(param_2 + 1) ^ (byte)param_1[1]) & 1) != 0)) {
        param_2[2] = param_2[2] | 4;
        uVar3 = FUN_00576940(param_1,0x7e0 << (((byte)param_1[1] & 1) * -0x10 + 0x10 & 0x1f));
        return uVar3 & 0xffff0000;
      }
      goto switchD_00588df6_caseD_3fc;
    }
    in_EAX = uVar3 - 0x3fb;
    uVar4 = (undefined2)(in_EAX >> 0x10);
    switch(uVar3) {
    case 0x3fb:
      in_EAX = FUN_004022e0(CONCAT22(extraout_var_00,*param_2));
      if (((short)in_EAX == 0x14f) &&
         (bVar2 = *(byte *)(param_2 + 1) ^ (byte)param_1[1],
         in_EAX = CONCAT31((int3)(in_EAX >> 8),bVar2), (bVar2 & 1) != 0)) {
        param_2[2] = param_2[2] | 4;
        uVar3 = FUN_00576940(param_1,0x1f << (((byte)param_1[1] & 1) * -0x10 + 0x10 & 0x1f));
        return uVar3 & 0xffff0000;
      }
      break;
    case 0x3fd:
      in_EAX = FUN_004022e0(*param_2);
      if ((short)in_EAX == 0x3f0) {
        in_EAX = CONCAT22((short)(in_EAX >> 0x10),param_2[1]);
        bVar2 = (byte)param_2[1];
        if ((((byte)param_1[1] ^ bVar2) & 1) != 0) {
          param_2[2] = param_2[2] | 4;
          uVar3 = FUN_005b9170(in_EAX << 0xf | 0xb1,bVar2 >> 1 & 0x1f,1,0);
          return uVar3 & 0xffff0000;
        }
      }
      break;
    case 0x3fe:
      in_EAX = FUN_004022e0(CONCAT22(extraout_var_00,*param_2));
      if (((short)in_EAX == 0x150) &&
         (bVar2 = *(byte *)(param_2 + 1) ^ (byte)param_1[1],
         in_EAX = CONCAT31((int3)(in_EAX >> 8),bVar2), (bVar2 & 1) != 0)) {
        param_2[2] = param_2[2] | 4;
        cVar1 = (char)((param_1[1] & 1) << 4);
        uVar3 = FUN_00576940(param_1,1 << (((byte)(param_1[1] >> 1) & 0x1f) + cVar1 & 0x1f) |
                                     0x1f << (0x10U - cVar1 & 0x1f));
        return uVar3 & 0xffff0000;
      }
      break;
    case 0x405:
    case 0x406:
      goto switchD_00588df6_caseD_405;
    }
  }
  else {
    uVar4 = 0;
    if (uVar3 != 0x5f5) {
      if (uVar3 == 0x5fa) {
        in_EAX = param_1[1] & 1;
        if (((ushort)(&DAT_00a55d74)[(param_1[1] >> 1 & 0x1f) * 0x24 + in_EAX * 0x351] & 0xfff) ==
            *param_1) {
          uVar3 = FUN_00567620(*param_2,0xffffffff);
          in_EAX = 0;
          if (uVar3 != 0) {
            *(byte *)(param_2 + 2) = *(byte *)(param_2 + 2) | 0xe;
            return uVar3 & 0xffff0000;
          }
        }
        goto switchD_00588df6_caseD_3fc;
      }
      uVar4 = 0;
      if (uVar3 - 0x5fb != 0) {
        return uVar3 - 0x5fb & 0xffff0000;
      }
    }
switchD_00588df6_caseD_405:
    FUN_005b9170(CONCAT22(uVar4,param_2[1]) << 0xf | 0xb1,(byte)param_2[1] >> 1 & 0x1f,1,0);
    *(byte *)(param_2 + 2) = *(byte *)(param_2 + 2) | 0xe;
    in_EAX = FUN_005778b0(param_1,param_2[1] & 1,(ushort)param_2[1] >> 1 & 0x1f);
  }
switchD_00588df6_caseD_3fc:
  return in_EAX & 0xffff0000;
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


//// FUNC 00589c70 FUN_00589c70

uint FUN_00589c70(uint param_1,int param_2)

{
  uint uVar1;
  short sVar2;
  uint in_EAX;
  int iVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  uint uVar7;
  uint uStack_8;
  uint uStack_4;
  
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    iVar3 = FUN_00583470(param_1,0,&uStack_8);
    in_EAX = 0;
    if (iVar3 != 0) {
      iVar3 = FUN_00583470(param_1,1,&uStack_4);
      uVar1 = uStack_8;
      in_EAX = 0;
      if (iVar3 != 0) {
        uVar5 = uStack_8 >> 8 & 0xff;
        uVar4 = uStack_4 >> 8;
        uVar7 = uStack_8 & 0xff;
        uVar6 = uStack_4 & 0xff;
        iVar3 = FUN_0057b3b0(param_1,uStack_8);
        in_EAX = 0;
        if (iVar3 != 0) {
          iVar3 = FUN_0056fc50(uVar7,uVar5,uVar6,uVar4 & 0xff);
          in_EAX = 0;
          if (iVar3 != 0) {
            uVar4 = FUN_0056fb40(uVar7,uVar5);
            in_EAX = uVar4 & 0xffff;
            if (in_EAX != uStack_4) {
              if ((*(byte *)(&DAT_00a55e00 + uVar5 * 0x24 + (uVar1 & 1) * 0x351) & 2) != 0) {
                sVar2 = FUN_0056fb40(uVar7,uVar5);
                if (sVar2 == -1) {
                  in_EAX = (uint)*(ushort *)(param_2 + 2);
                  if ((uVar7 == (in_EAX & 1)) && (in_EAX = (in_EAX & 0x3e) >> 1, uVar5 == in_EAX)) {
                    *(undefined2 *)(param_2 + 6) = *(undefined2 *)(param_1 + 8);
                    return param_1 & 0xffff0000;
                  }
                  goto LAB_00589d9f;
                }
              }
              in_EAX = func_0x00574ac0(uStack_8,uStack_4);
            }
          }
        }
      }
    }
  }
LAB_00589d9f:
  return in_EAX & 0xffff0000;
}


//// FUNC 0058a250 FUN_0058a250

uint FUN_0058a250(ushort *param_1)

{
  uint in_EAX;
  undefined2 extraout_var;
  uint uVar1;
  
  if ((param_1[2] & 4) == 0) {
    uVar1 = param_1[1] & 1;
    in_EAX = param_1[1] >> 1 & 0x1f;
    if (((ushort)(&DAT_00a55d74)[in_EAX * 0x24 + uVar1 * 0x351] & 0xfff) == *param_1) {
      FUN_00579990(uVar1,in_EAX,1,0);
      in_EAX = FUN_005b9170(CONCAT22(extraout_var,param_1[1] << 0xf) | 0xf1,0x3c,0,0);
    }
  }
  return in_EAX & 0xffff0000;
}


//// FUNC 0058a660 FUN_0058a660

uint FUN_0058a660(uint param_1)

{
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    param_1 = FUN_00579930(*(byte *)(param_1 + 2) & 1,2,1);
  }
  return param_1 & 0xffff0000;
}


//// FUNC 0058a690 FUN_0058a690

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_0058a690(int param_1)

{
  undefined4 uVar1;
  uint uVar2;
  uint uVar3;
  byte bVar4;
  int iVar5;
  byte *pbVar6;
  uint uVar7;
  uint uStack_108;
  int iStack_104;
  undefined1 auStack_100 [256];
  
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    switch(DAT_00a55c88._2_1_) {
    case 0x7d:
      uVar7 = 1;
      uStack_108 = 0;
      if ((_DAT_00a57822 & 1) == 0) {
        bVar4 = 0;
        do {
          uVar7 = uVar7 + 1;
          bVar4 = bVar4 + 1;
        } while (((uint)_DAT_00a57822 & 1 << (bVar4 & 0x1f)) == 0);
      }
      iStack_104 = 0;
      do {
        if (iStack_104 == 0) {
          uVar2 = 1 - (*(byte *)(param_1 + 2) & 1);
        }
        else {
          uVar2 = *(byte *)(param_1 + 2) & 1;
        }
        iVar5 = 0;
        pbVar6 = &DAT_00a55d7a + (uVar2 & 1) * 0xd44;
        do {
          if ((((*(uint *)(pbVar6 + -6) & 0xfff) != 0) && ((*pbVar6 & 2) != 0)) &&
             (uVar3 = FUN_0056f9e0(uVar2,iVar5), (uVar3 & 0xffff) == uVar7)) {
            uStack_108 = uStack_108 | 1 << ((char)(uVar2 << 4) + (char)iVar5 & 0x1fU);
          }
          iVar5 = iVar5 + 1;
          pbVar6 = pbVar6 + 0x90;
        } while (iVar5 < 5);
        iStack_104 = iStack_104 + 1;
      } while (iStack_104 < 2);
      FUN_00576940(param_1,uStack_108);
      return 0;
    case 0x7e:
      if ((~(byte)((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1)) & 1) != 0) {
        iVar5 = 1;
        if ((_DAT_00a57822 & 1) == 0) {
          bVar4 = 0;
          do {
            iVar5 = iVar5 + 1;
            bVar4 = bVar4 + 1;
          } while (((uint)_DAT_00a57822 & 1 << (bVar4 & 0x1f)) == 0);
        }
        uVar1 = FUN_004025b0(iVar5);
        FUN_005bdf40(auStack_100,0x108,uVar1);
        FUN_005bf800(auStack_100);
      }
      return 0x7d;
    case 0x7f:
      FUN_005bcf80(1 - (*(byte *)(param_1 + 2) & 1),1,_DAT_00a57822);
      return 0x7e;
    case 0x80:
      FUN_005bcf80(*(byte *)(param_1 + 2) & 1,2,0xff);
      return 0x7f;
    }
  }
  return 0;
}


//// FUNC 0058a880 FUN_0058a880

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

char FUN_0058a880(int param_1)

{
  ushort *puVar1;
  byte bVar2;
  undefined2 uVar3;
  ushort uVar4;
  uint uVar5;
  int iVar6;
  undefined4 uVar7;
  uint uVar8;
  uint uVar9;
  undefined4 unaff_EDI;
  uint uVar10;
  
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return '\0';
  }
  uVar4 = _DAT_00a55c8c;
  switch(DAT_00a55c88._2_2_ & 0xff) {
  case 0x78:
    uVar9 = 0;
    do {
      uVar5 = DAT_00a577f8._2_1_ & 1 ^ uVar9;
      FUN_00576170(uVar5,*(undefined2 *)(param_1 + 6 + uVar5 * 2));
      uVar9 = uVar9 + 1;
    } while ((int)uVar9 < 2);
    uVar9 = 0;
    do {
      FUN_005797e0(DAT_00a577f8._2_1_ & 1 ^ uVar9);
      uVar9 = uVar9 + 1;
    } while ((int)uVar9 < 2);
    FUN_00579890();
  default:
    return '\0';
  case 0x7a:
    _DAT_00a55c8c = uVar4 ^ (byte)(DAT_00a55c8c - 1 ^ DAT_00a55c8c);
    if ((_DAT_00a55c8c & 0xff) == 0) {
      uVar4 = (DAT_00a55c88._2_2_ >> 8) * -0x100 + 0x100;
      _DAT_00a55c8c = CONCAT22(_DAT_00a55c8e,(short)CONCAT31((uint3)(_DAT_00a55c8c >> 8) & 0xff,5));
      DAT_00a55c88._2_2_ = uVar4 ^ DAT_00a55c88._2_2_ & 0xff;
      return (-(uVar4 >> 8 != (DAT_00a577f8._2_1_ & 1)) & 6U) + 0x78;
    }
    return '~';
  case 0x7c:
    FUN_005b9170(-(uint)((DAT_00a55c88._2_2_ & 0xff00) != 0) & 0x8000 | 0x61,1,1,0);
    break;
  case 0x7d:
    uVar9 = _DAT_00a55c90 >> 0xc & 1;
    FUN_005adb10(uVar9,&DAT_00a55c90,0,0,0xd,DAT_00a55c88._2_2_ >> 8);
    bVar2 = FUN_0056a030(uVar9);
    puVar1 = (ushort *)(param_1 + 6 + uVar9 * 2);
    *puVar1 = *puVar1 | (ushort)(1 << (bVar2 & 0x1f));
    return 'z';
  case 0x7e:
    uVar9 = (uint)(DAT_00a55c88._2_2_ >> 8);
    if (((&DAT_00a55d68)[(uVar9 & 1) * 0x6a2] & 0xff00) != 0) {
      uVar5 = uVar9 & 1;
      uVar10 = CONCAT22((short)((uint)unaff_EDI >> 0x10),
                        *(undefined2 *)(&DAT_00a56574 + uVar5 * 0x351)) & 0xffff0fff;
      uVar8 = (uint)(&DAT_00a56574)[uVar5 * 0x351] >> 0xc & 1;
      FUN_00578430(uVar9,uVar10);
      iVar6 = FUN_00570be0(uVar9,&DAT_00a56574 + uVar5 * 0x351);
      if (iVar6 == 0) {
        uVar7 = FUN_004022e0(uVar10,0xd,0);
        FUN_005b9170(-(uint)(uVar9 != 0) & 0x8000 | 0x20,uVar7);
      }
      FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar9 != 0) >> 8) & 0x80,0xf1),0x1e,0,0);
      iVar6 = FUN_00402690(uVar10);
      if (((iVar6 != 0) && (uVar4 = FUN_004026c0(uVar10), uVar4 < 5)) &&
         (iVar6 = FUN_00567a00(uVar10), iVar6 == 0)) {
        iVar6 = FUN_0056a000(uVar8);
        if ((0 < iVar6) && (*(short *)(param_1 + 10 + uVar8 * 2) != 0)) {
          FUN_005675c0(&DAT_00a55c90,&DAT_00a56574 + uVar5 * 0x351);
          return '}';
        }
        FUN_00578bb0(uVar9,1,0);
        return 'z';
      }
      return '|';
    }
    break;
  case 0x7f:
    DAT_00a55c88._2_2_ = CONCAT11(DAT_00a577f8._2_1_,DAT_00a55c88._2_1_) & 0x1ff;
    _DAT_00a55c8c = _DAT_00a55c8c & 0xffffff05 | 5;
    *(undefined2 *)(param_1 + 8) = 0;
    *(undefined2 *)(param_1 + 6) = 0;
    uVar3 = FUN_00570b40(0);
    *(undefined2 *)(param_1 + 10) = uVar3;
    uVar3 = FUN_00570b40(1);
    *(undefined2 *)(param_1 + 0xc) = uVar3;
    FUN_005b9170(CONCAT31((uint3)(-(uint)((DAT_00a55c88._2_2_ & 0xff00) != 0) >> 8) & 0x80,0xf1),
                 0x1e,0,0);
    FUN_00579810();
    return '~';
  case 0x80:
    FUN_00576940(param_1,0x1f001f);
    if ((*(ushort *)(param_1 + 2) & 0xfc0) == 0x500) {
      FUN_00578030(param_1,0);
      FUN_00578030(param_1,1);
    }
    return '\x7f';
  }
  return 'z';
}


//// FUNC 0058afe0 FUN_0058afe0

uint FUN_0058afe0(undefined2 *param_1)

{
  byte bVar1;
  uint in_EAX;
  undefined2 extraout_var;
  
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    bVar1 = (byte)param_1[1];
    FUN_005747e0(param_1[1] & 1,*param_1,CONCAT11(bVar1 >> 1,bVar1) & 0x1f01,0xc);
    in_EAX = FUN_005b9170(CONCAT22(extraout_var,param_1[1]) << 0xf | 0x94,
                          (byte)param_1[1] >> 1 & 0x1f,0,0);
  }
  return in_EAX & 0xffff0000;
}


//// FUNC 0058b3d0 FUN_0058b3d0

uint FUN_0058b3d0(uint param_1,undefined4 param_2)

{
  uint uVar1;
  
  if ((*(ushort *)(param_1 + 2) & 0x3000) != 0x2000) {
    return param_1 & 0xffff0000;
  }
  uVar1 = func_0x0058b400(param_1,param_2);
  return uVar1;
}


//// FUNC 0058b5e0 FUN_0058b5e0

uint FUN_0058b5e0(undefined2 *param_1)

{
  ushort uVar1;
  short sVar2;
  uint in_EAX;
  uint uVar3;
  undefined2 uVar4;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  uint uVar5;
  byte *pbVar6;
  uint uVar7;
  int iVar8;
  bool bVar9;
  int iStack_4;
  
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    if (DAT_00a55c88._2_1_ == 0x7f) {
      uVar5 = FUN_004022e0(*param_1);
      in_EAX = (uVar5 & 0xffff) - 0x470;
      uVar4 = (undefined2)(in_EAX >> 0x10);
      switch(in_EAX) {
      case 0:
        uVar5 = FUN_005b9170(CONCAT22(uVar4,param_1[1] << 0xf) | 0x15,1,0,0);
        return uVar5 & 0xffff0000;
      case 1:
        uVar5 = FUN_005b9170(CONCAT22(extraout_var,param_1[1] << 0xf) | 0x16,1,0,0);
        return uVar5 & 0xffff0000;
      case 2:
        uVar5 = FUN_005b9170(CONCAT22(extraout_var_00,param_1[1] << 0xf) | 0x18,1,0,0);
        return uVar5 & 0xffff0000;
      case 3:
        in_EAX = FUN_005b9170(CONCAT22(uVar4,param_1[1] << 0xf) | 0x17,1,0,0);
      }
    }
    else {
      in_EAX = DAT_00a55c88._2_1_ - 0x80;
      if (in_EAX == 0) {
        iStack_4 = 0;
        do {
          if (iStack_4 == 0) {
            uVar5 = 1 - (*(byte *)(param_1 + 1) & 1);
          }
          else {
            uVar5 = *(byte *)(param_1 + 1) & 1;
          }
          iVar8 = 5;
          pbVar6 = (byte *)(&DAT_00a5604a + (uVar5 & 1) * 0x6a2);
          do {
            uVar7 = *(uint *)(pbVar6 + -6) & 0xfff;
            if ((uVar7 == 0) || ((*pbVar6 & 2) == 0)) goto switchD_0058b68e_default;
            uVar3 = FUN_004022e0(*param_1);
            switch((uVar3 & 0xffff) - 0x470) {
            case 0:
              sVar2 = FUN_00402700(uVar7);
              if ((sVar2 != 3) && (uVar1 = FUN_004025d0(uVar7), 0x14 < uVar1)) break;
              goto LAB_0058b702;
            case 1:
              sVar2 = FUN_00402700(uVar7);
              bVar9 = sVar2 == 2;
              goto LAB_0058b6d1;
            case 2:
              sVar2 = FUN_00402700(uVar7);
              bVar9 = sVar2 == 4;
LAB_0058b6d1:
              if ((bVar9) && (sVar2 = FUN_004025d0(uVar7), sVar2 == 0x16)) {
LAB_0058b702:
                FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar5 != 0) >> 8) & 0x80,0xb1),iVar8,1,0);
              }
              break;
            case 3:
              sVar2 = FUN_00402700(uVar7);
              if ((sVar2 == 4) && (sVar2 = FUN_004025d0(uVar7), sVar2 == 0x15)) goto LAB_0058b702;
            }
switchD_0058b68e_default:
            iVar8 = iVar8 + 1;
            pbVar6 = pbVar6 + 0x90;
          } while (iVar8 < 0xb);
          iStack_4 = iStack_4 + 1;
          if (1 < iStack_4) {
            return CONCAT22((short)((uint)iStack_4 >> 0x10),0x7f);
          }
        } while( true );
      }
    }
  }
  return in_EAX & 0xffff0000;
}


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


//// FUNC 0058c950 FUN_0058c950

uint FUN_0058c950(int param_1)

{
  uint uVar1;
  uint uVar2;
  uint in_EAX;
  int iVar3;
  undefined4 uVar4;
  uint uVar5;
  uint uVar6;
  uint uStack_8;
  uint uStack_4;
  
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    iVar3 = FUN_00583470(param_1,0,&uStack_8);
    in_EAX = 0;
    if (iVar3 != 0) {
      iVar3 = FUN_00583470(param_1,1,&uStack_4);
      uVar2 = uStack_4;
      uVar6 = uStack_8;
      in_EAX = 0;
      if (iVar3 != 0) {
        uVar5 = uStack_8 >> 8 & 0xff;
        uVar1 = uStack_4 >> 8;
        uVar4 = FUN_0056f690(uStack_8 & 0xff,uVar5);
        iVar3 = FUN_005be050(uVar4);
        in_EAX = 0;
        if ((((&DAT_00a55d7a)[(uVar6 & 1) * 0xd44 + uVar5 * 0x90] & 2) != 0) &&
           (in_EAX = 0, ((&DAT_00a55d7a)[(uVar2 & 1) * 0xd44 + (uVar1 & 0xff) * 0x90] & 2) != 0)) {
          uVar6 = iVar3 / 5 | 0x4000;
          func_0x00574810(*(byte *)(param_1 + 2) & 1,uVar6,uStack_8,0xc);
          in_EAX = func_0x00574810(*(byte *)(param_1 + 2) & 1,uVar6,uStack_4,0x10c);
        }
      }
    }
  }
  return in_EAX & 0xffff0000;
}


//// FUNC 0058cb70 FUN_0058cb70

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 __fastcall FUN_0058cb70(undefined4 param_1,undefined4 param_2,int param_3)

{
  undefined2 uVar1;
  undefined2 uVar2;
  
  uVar1 = _DAT_00a57822;
  if ((*(byte *)(param_3 + 4) & 4) != 0) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '~') {
    uVar2 = (undefined2)((uint)param_2 >> 0x10);
    *(undefined2 *)(param_3 + 8) = _DAT_00a57822;
    FUN_005b9170(CONCAT22(uVar2,*(short *)(param_3 + 2) << 0xf) | 199,uVar1,
                 CONCAT22(uVar2,*(undefined2 *)(param_3 + 6)),0);
    return 100;
  }
  if (DAT_00a55c88._2_1_ == '\x7f') {
    *(undefined2 *)(param_3 + 6) = _DAT_00a57822;
    func_0x005bcec0(1 - (*(byte *)(param_3 + 2) & 1));
    return 0x7e;
  }
  if (DAT_00a55c88._2_1_ != -0x80) {
    return 0;
  }
  func_0x005bcec0(*(byte *)(param_3 + 2) & 1);
  return 0x7f;
}


//// FUNC 0058d5e0 FUN_0058d5e0

uint FUN_0058d5e0(undefined4 param_1)

{
  ushort uVar1;
  uint uVar2;
  uint uVar3;
  
  uVar1 = *(ushort *)(&DAT_00a57844 + (DAT_00a577f8._2_1_ & 1) * 0x10);
  uVar2 = CONCAT22((short)((uint)(&DAT_00a57844 + (DAT_00a577f8._2_1_ & 1) * 0x10) >> 0x10),uVar1);
  if ((uVar1 & 0x10) == 0) {
    uVar3 = uVar1 >> 1 & 7;
    uVar2 = (uint)(uVar1 >> 8);
    if (((uint)(&DAT_00a55d74)[uVar3 * 0x24 + (uVar1 & 1) * 0x351] >> 0xc & 1) +
        ((uint)(&DAT_00a55d74)[uVar3 * 0x24 + (uVar1 & 1) * 0x351] >> 0x18 & 0x7f) * 2 == uVar2) {
      uVar2 = func_0x00577990(param_1,uVar1 & 1,uVar3);
    }
  }
  return uVar2 & 0xffff0000;
}


//// FUNC 0058d860 FUN_0058d860

uint FUN_0058d860(ushort *param_1)

{
  ushort uVar1;
  ushort uVar2;
  byte bVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  
  uVar4 = (uint)(byte)param_1[8];
  uVar2 = param_1[8];
  uVar5 = 0;
  if ((param_1[2] & 4) == 0) {
    uVar1 = param_1[1];
    uVar5 = uVar1 & 1;
    uVar6 = uVar1 >> 1 & 0x1f;
    if (((((ushort)(&DAT_00a55d74)[uVar6 * 0x24 + uVar5 * 0x351] & 0xfff) == *param_1) &&
        (uVar4 != uVar5)) && ((uVar1 & 0xfc0) == 0x480)) {
      uVar5 = FUN_0056dc10(uVar4,*(undefined1 *)((int)param_1 + 0x11),uVar5,uVar6);
      if ((int)uVar5 < 0) {
        bVar3 = (byte)param_1[1];
        uVar5 = FUN_005747e0(param_1[1] & 1,CONCAT11(bVar3 >> 1,bVar3) & 0x1f01,uVar2,6);
      }
    }
  }
  return uVar5 & 0xffff0000;
}


//// FUNC 0058da00 FUN_0058da00

uint FUN_0058da00(int param_1)

{
  uint in_EAX;
  int iVar1;
  uint uVar2;
  uint uVar3;
  
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    iVar1 = FUN_00583470(param_1,0,0);
    in_EAX = 0;
    if (iVar1 != 0) {
      uVar2 = FUN_00583440(param_1,0);
      uVar3 = uVar2 >> 8 & 0xff;
      in_EAX = 0;
      if (((*(ushort *)(&DAT_00a55d7a + (uVar2 & 1) * 0xd44 + uVar3 * 0x90) & 1) != 0) &&
         ((*(ushort *)(&DAT_00a55d7a + (uVar2 & 1) * 0xd44 + uVar3 * 0x90) & 2) == 0)) {
        in_EAX = FUN_005751e0(param_1,uVar2 & 0xff,uVar3,1,0);
      }
    }
  }
  return in_EAX & 0xffff0000;
}


//// FUNC 0058da80 FUN_0058da80

undefined4 FUN_0058da80(ushort *param_1)

{
  byte bVar1;
  uint uVar2;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  
  if ((param_1[2] & 4) != 0) {
    return 0;
  }
  uVar2 = (uint)param_1[1];
  if (((ushort)(&DAT_00a55d74)[(param_1[1] >> 1 & 0x1f) * 0x24 + (uVar2 & 1) * 0x351] & 0xfff) !=
      *param_1) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '\x7f') {
    uVar2 = FUN_005bddb0(2);
    FUN_005b9170(CONCAT22((short)(uVar2 >> 0x10),param_1[1]) << 0xf | 0xe0,
                 CONCAT22(extraout_var_00,DAT_00a558b4),uVar2,(byte)param_1[1] >> 1 & 0x1f);
    if (uVar2 == DAT_00a558b4) {
      bVar1 = (byte)param_1[1];
      FUN_005747e0(param_1[1] & 1,CONCAT11(bVar1 >> 1,bVar1) & 0x1f01,
                   CONCAT22(extraout_var,param_1[8]),6);
    }
    return 10;
  }
  if (DAT_00a55c88._2_1_ != -0x80) {
    return 0;
  }
  if ((uVar2 & 0xfc0) != 0x480) {
    return 0;
  }
  if ((ushort)(byte)param_1[8] == (ushort)(uVar2 & 1)) {
    return 0;
  }
  if (((DAT_00a54e5c >> 1 & 3) >> (sbyte)(uVar2 & 1) & 1) != 0) {
    DAT_00a558b4 = FUN_005bddb0(2);
    return 0x7f;
  }
  FUN_005bf800(0x38);
  FUN_005bf9a0(7,0);
  return 0x7f;
}


//// FUNC 0058dcc0 FUN_0058dcc0

undefined4 FUN_0058dcc0(int param_1)

{
  byte bVar1;
  int iVar2;
  uint uVar3;
  uint uVar4;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 uVar5;
  undefined4 extraout_EDX;
  undefined4 extraout_EDX_00;
  undefined4 uVar6;
  uint uVar7;
  
  if (DAT_00a55c88._2_1_ == '\x7f') {
    func_0x005bd030(0);
  }
  else if ((DAT_00a55c88._2_1_ == -0x80) && ((*(byte *)(param_1 + 4) & 4) == 0)) {
    if ((((byte)DAT_00a577ec & 1) == 0) && (((byte)DAT_00a577ec & 2) != 0)) {
      iVar2 = FUN_00583470(param_1,0,0);
      if (iVar2 != 0) {
        uVar3 = FUN_00583440(param_1,0);
        uVar7 = uVar3 & 0xff;
        uVar4 = uVar3 >> 8 & 0xff;
        iVar2 = uVar4 * 0x90 + (uVar3 & 1) * 0xd44;
        if ((((&DAT_00a55d7a)[iVar2] & 2) != 0) &&
           (((&DAT_00a55d74)[(uVar3 & 1) * 0x351 + uVar4 * 0x24] & 0xfff) != 0)) {
          FUN_005b9170(CONCAT31((uint3)(-(uint)(*(char *)(param_1 + 0x10) != '\0') >> 8) & 0x80,0x35
                               ),*(undefined1 *)(param_1 + 0x11),1,0);
          FUN_005798f0(1,0);
          uVar6 = extraout_EDX;
          uVar5 = extraout_var;
          if (((&DAT_00a55d7a)[iVar2] & 1) != 0) {
            FUN_005751e0(param_1,uVar7,uVar4,0,0);
            uVar6 = extraout_EDX_00;
            uVar5 = extraout_var_00;
          }
          bVar1 = (byte)((ushort)*(undefined2 *)(param_1 + 0x12) >> 8);
          if (4 < bVar1) {
            FUN_005b9170(-(uint)(uVar7 != 0) & 0x8000 | 0x34,uVar4,1,0);
            return 0x7f;
          }
          FUN_005b9170(-(uint)(uVar7 != 0) & 0x8000 | 0x33,uVar4,
                       CONCAT31((int3)((uint)uVar6 >> 8),bVar1) & 0xffff00ff,
                       CONCAT22(uVar5,(ushort)*(byte *)(param_1 + 0x12)) + 1);
          return 0x7f;
        }
      }
    }
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


//// FUNC 0058e790 FUN_0058e790

uint FUN_0058e790(uint param_1)

{
  uint uVar1;
  byte bVar2;
  int iVar3;
  uint uVar4;
  uint uVar5;
  uint uVar6;
  
  uVar1 = param_1;
  iVar3 = FUN_00583470(param_1,0,&param_1);
  uVar5 = 0;
  if (iVar3 != 0) {
    uVar6 = param_1 >> 8 & 0xff;
    uVar4 = param_1 & 1;
    uVar5 = uVar6 * 0x90;
    if ((((&DAT_00a55d74)[uVar4 * 0x351 + uVar6 * 0x24] & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[uVar5 + uVar4 * 0xd44] & 2) != 0)) {
      bVar2 = (byte)*(ushort *)(uVar1 + 2);
      uVar5 = FUN_005747e0(*(ushort *)(uVar1 + 2) & 1,
                           *(ushort *)(&DAT_00a55d74 + uVar4 * 0x351 + uVar6 * 0x24) & 0xfff |
                           0x6000,CONCAT11(bVar2 >> 1,bVar2) & 0x1f01,0xb);
    }
  }
  return uVar5 & 0xffff0000;
}


//// FUNC 0058ed20 FUN_0058ed20

undefined4 FUN_0058ed20(undefined2 *param_1)

{
  uint uVar1;
  undefined2 extraout_var;
  
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '\x7f') {
    uVar1 = FUN_005bddb0(2);
    FUN_005b9170(CONCAT22((short)(uVar1 >> 0x10),param_1[1]) << 0xf | 0xe0,
                 CONCAT22(extraout_var,DAT_00a558b4),uVar1,(byte)param_1[1] >> 1 & 0x1f);
    if (uVar1 == DAT_00a558b4) {
      if ((byte)(&DAT_00a55d68)[(*(byte *)(param_1 + 1) & 1) * 0x6a2] < 5) {
        FUN_00578b60(*(byte *)(param_1 + 1) & 1,
                     5 - ((ushort)(&DAT_00a55d68)[(*(byte *)(param_1 + 1) & 1) * 0x6a2] & 0xff));
        return 10;
      }
    }
    else {
      FUN_00579790(*(byte *)(param_1 + 1) & 1,*param_1,0x23);
    }
    return 10;
  }
  if (DAT_00a55c88._2_1_ != -0x80) {
    return 0;
  }
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) != 0) {
    DAT_00a558b4 = FUN_005bddb0(2);
    return 0x7f;
  }
  FUN_005bf800(0x38);
  FUN_005bf9a0(7,0);
  return 0x7f;
}


//// FUNC 0058f140 FUN_0058f140

uint FUN_0058f140(int param_1,undefined4 param_2)

{
  uint in_EAX;
  uint uVar1;
  
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return in_EAX & 0xffff0000;
  }
  if (*(ushort *)(param_1 + 8) == 1) {
    uVar1 = func_0x00589c00(param_1,param_2);
    return uVar1;
  }
  uVar1 = *(ushort *)(param_1 + 8) - 2;
  if (uVar1 != 0) {
    return uVar1 & 0xffff0000;
  }
  if (((byte)DAT_00a577ec & 1) != 0) {
    return 0;
  }
  if (((byte)DAT_00a577ec & 2) == 0) {
    return 0;
  }
  uVar1 = func_0x0058d970(param_1,param_2);
  return uVar1;
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


//// FUNC 0058f3d0 FUN_0058f3d0

uint FUN_0058f3d0(short *param_1)

{
  short *psVar1;
  uint in_EAX;
  byte *pbVar2;
  
  psVar1 = param_1;
  if ((((param_1[2] & 4U) == 0) &&
      (in_EAX = (&DAT_00a55d74)
                [((ushort)param_1[1] >> 1 & 0x1f) * 0x24 + ((ushort)param_1[1] & 1) * 0x351] & 0xfff
      , (short)in_EAX == *param_1)) && ((param_1[2] & 0xe000U) == 0x4000)) {
    pbVar2 = (byte *)(param_1 + 3);
    param_1 = (short *)0x2;
    do {
      if (((&DAT_00a55d74)[(uint)pbVar2[1] * 0x24 + (*pbVar2 & 1) * 0x351] & 0xfff) == 0) {
        FUN_00579790(*pbVar2,CONCAT11(*(byte *)(psVar1 + 1) >> 1,(char)psVar1[1]) & 0x1f01,
                     (uint)pbVar2[1] << 8 | 2);
      }
      pbVar2 = pbVar2 + 2;
      param_1 = (short *)((int)param_1 + -1);
    } while (param_1 != (short *)0x0);
    in_EAX = 0;
  }
  return in_EAX & 0xffff0000;
}


//// FUNC 0058f9f0 FUN_0058f9f0

uint FUN_0058f9f0(int param_1)

{
  int iVar1;
  uint uVar2;
  
  iVar1 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
  uVar2 = 0;
  if (iVar1 != 0) {
    uVar2 = FUN_0056a000(*(byte *)(param_1 + 2) & 1);
    if ((uVar2 != 0) && ((*(ushort *)(param_1 + 4) & 0xe000) == 0x2000)) {
      uVar2 = FUN_005687d0(*(undefined2 *)(param_1 + 6));
      if ((char)(uVar2 >> 8) == '\x0e') {
        uVar2 = FUN_005adb10(*(byte *)(param_1 + 2) & 1,
                             &DAT_00a566f0 + (uVar2 & 1) * 0x351 + (uVar2 >> 0x10),1,0x20,0xe,
                             uVar2 & 0xff);
      }
    }
  }
  return uVar2 & 0xffff0000;
}


//// FUNC 0058fa90 FUN_0058fa90

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_0058fa90(undefined2 *param_1,undefined4 param_2)

{
  ushort uVar1;
  short extraout_AX;
  int iVar2;
  int iVar3;
  undefined2 extraout_var;
  undefined2 uVar6;
  undefined4 uVar4;
  ushort *puVar5;
  undefined2 *puVar7;
  uint uVar8;
  undefined1 auStack_100 [256];
  
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  switch(DAT_00a55c88._2_2_ & 0xff) {
  case 0x76:
    uVar6 = param_1[(DAT_00a55c88._2_2_ >> 8) + 3];
    puVar5 = (ushort *)FUN_005700f0(*(byte *)(param_1 + 1) & 1,0xb,uVar6);
    iVar2 = FUN_00402690(*puVar5 & 0xfff);
    if (iVar2 != 0) {
      FUN_005adb10(*(byte *)(param_1 + 1) & 1,puVar5,1,0,0xb,uVar6);
      return 0;
    }
    FUN_00575af0(*(byte *)(param_1 + 1) & 1,puVar5,0);
    break;
  case 0x77:
    uVar8 = 0;
    puVar5 = param_1 + 3;
    do {
      if (uVar8 != DAT_00a55c88._2_2_ >> 8) {
        uVar4 = FUN_005700f0(*(byte *)(param_1 + 1) & 1,0xb,*puVar5);
        FUN_00575af0(*(byte *)(param_1 + 1) & 1,uVar4,0);
        param_1[(DAT_00a55c88._2_2_ >> 8) + 3] =
             param_1[(DAT_00a55c88._2_2_ >> 8) + 3] -
             (ushort)(*puVar5 < (ushort)param_1[(DAT_00a55c88._2_2_ >> 8) + 3]);
      }
      uVar8 = uVar8 + 1;
      puVar5 = puVar5 + 1;
    } while ((int)uVar8 < 3);
    return 0x76;
  case 0x78:
    uVar4 = FUN_00570230(*(byte *)(param_1 + 1) & 1,0xb,param_1[(DAT_00a55c88._2_2_ >> 8) + 3]);
    uVar4 = FUN_00402290(uVar4);
    FUN_005bdf40(auStack_100,0x108,uVar4);
    FUN_005bf800(auStack_100);
    return 0x77;
  case 0x79:
    iVar2 = 0;
    puVar7 = param_1 + 3;
    do {
      FUN_00570230(*(byte *)(param_1 + 1) & 1,0xb,*puVar7);
      if (extraout_AX == _DAT_00a57822) {
        uVar6 = 0;
        DAT_00a55c88._2_2_ = CONCAT11((char)iVar2,DAT_00a55c88._2_1_);
        break;
      }
      iVar2 = iVar2 + 1;
      puVar7 = puVar7 + 1;
      uVar6 = extraout_var;
    } while (iVar2 < 3);
    FUN_005b9170(CONCAT22(uVar6,param_1[1]) << 0xf | 8,(byte)param_1[1] & 1,
                 (uint)*(byte *)(param_1 + (DAT_00a55c88._2_2_ >> 8) + 3) << 8 | 0xb,0);
    return 0x78;
  case 0x7a:
    iVar2 = 2;
    puVar7 = param_1 + 5;
    do {
      iVar3 = FUN_005bddb0(iVar2 + 1);
      uVar6 = param_1[iVar3 + 3];
      param_1[iVar3 + 3] = *puVar7;
      *puVar7 = uVar6;
      iVar2 = iVar2 + -1;
      puVar7 = puVar7 + -1;
    } while (0 < iVar2);
    FUN_005bcfe0(1 - (*(byte *)(param_1 + 1) & 1),*param_1,param_1 + 3,3);
    return 0x79;
  case 0x7b:
    iVar2 = FUN_005aa440(1);
    if (iVar2 == 0) {
      return 0x7b;
    }
    iVar2 = FUN_00402690(*(ushort *)
                          (&DAT_00a56434 + DAT_00a5504c + (*(byte *)(param_1 + 1) & 1) * 0x351) &
                         0xfff);
    if (iVar2 != 0) {
      return 0x7b;
    }
    if (DAT_00a5504c == (ushort)param_1[4]) {
      return 0x7b;
    }
    iVar2 = FUN_005aa480();
    if (iVar2 == 0) {
      return 0x7b;
    }
    FUN_005b9170(CONCAT22((short)((uint)iVar2 >> 0x10),param_1[1]) << 0xf | 8,(byte)param_1[1] & 1,
                 (DAT_00a5504c & 0xff) << 8 | 0xb,0);
    param_1[5] = (undefined2)DAT_00a5504c;
    return 0x7a;
  case 0x7d:
    if ((DAT_00a54e54 & 0x102) != 0) {
      return 0x7e;
    }
    iVar2 = FUN_005aa440(1);
    if (iVar2 == 0) {
      return 0x7d;
    }
    iVar2 = FUN_00402690(*(ushort *)
                          (&DAT_00a56434 + DAT_00a5504c + (*(byte *)(param_1 + 1) & 1) * 0x351) &
                         0xfff);
    if (iVar2 != 0) {
      return 0x7d;
    }
    iVar2 = FUN_005aa480();
    if (iVar2 != 0) {
      FUN_005b9170(CONCAT22((short)((uint)iVar2 >> 0x10),param_1[1]) << 0xf | 8,(byte)param_1[1] & 1
                   ,(DAT_00a5504c & 0xff) << 8 | 0xb,0);
      param_1[4] = (undefined2)DAT_00a5504c;
      return 0x7b;
    }
    return 0x7d;
  case 0x7e:
    FUN_005bdfc0(auStack_100,0x4b,2);
    FUN_005bf800(auStack_100);
    return 0x7d;
  case 0x7f:
    if ((DAT_00a54e54 & 0x102) != 0) {
      return 0x80;
    }
    iVar2 = FUN_005aa440(1);
    if (iVar2 != 0) {
      uVar1 = *(ushort *)(&DAT_00a56434 + DAT_00a5504c + (*(byte *)(param_1 + 1) & 1) * 0x351);
      iVar2 = FUN_00402690(uVar1 & 0xfff);
      if (((iVar2 != 0) &&
          (iVar2 = FUN_00570b70(*(byte *)(param_1 + 1) & 1,uVar1 & 0xfff), iVar2 != 0)) &&
         (iVar2 = FUN_005aa480(), iVar2 != 0)) {
        FUN_005b9170(CONCAT22((short)((uint)iVar2 >> 0x10),param_1[1]) << 0xf | 8,
                     (byte)param_1[1] & 1,(DAT_00a5504c & 0xff) << 8 | 0xb,0);
        param_1[3] = (undefined2)DAT_00a5504c;
        return 0x7e;
      }
    }
    return 0x7f;
  case 0x80:
    iVar2 = FUN_005829d0(param_1,param_2,0);
    if (iVar2 != 0) {
      FUN_005bf800(0x49);
      return 0x7f;
    }
  }
  return 0;
}


//// FUNC 0058ff70 FUN_0058ff70

uint FUN_0058ff70(ushort *param_1)

{
  byte bVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  
  uVar2 = param_1[1] & 1;
  if (((ushort)(&DAT_00a55d74)[(param_1[1] >> 1 & 0x1f) * 0x24 + uVar2 * 0x351] & 0xfff) == *param_1
     ) {
    iVar3 = FUN_00583470(param_1,0,0);
    uVar2 = 0;
    if (iVar3 != 0) {
      uVar4 = FUN_00583440(param_1,0);
      iVar3 = FUN_0057c060(param_1,uVar4 & 0xffff);
      uVar2 = 0;
      if (iVar3 != 0) {
        bVar1 = (byte)param_1[1];
        uVar2 = FUN_005747e0(param_1[1] & 1,CONCAT11(bVar1 >> 1,bVar1) & 0x1f01,uVar4,2);
      }
    }
  }
  return uVar2 & 0xffff0000;
}


//// FUNC 00590080 FUN_00590080

undefined4 FUN_00590080(undefined2 *param_1)

{
  undefined2 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined2 extraout_var;
  uint uVar4;
  
  if ((DAT_00a577f8._2_1_ & 0xe) != 10) {
    if ((*(byte *)(param_1 + 2) & 4) != 0) {
      return 0;
    }
    FUN_00579790(*(byte *)(param_1 + 1) & 1,*param_1,3);
    return 0;
  }
  if (DAT_00a55c88._2_1_ == '~') {
    uVar2 = FUN_0040cab0();
    FUN_00575d50(param_1,*(byte *)(param_1 + 1) & 1,uVar2);
    return 0x78;
  }
  if (DAT_00a55c88._2_1_ != '\x7f') {
    if (DAT_00a55c88._2_1_ != -0x80) {
      return 0;
    }
    uVar2 = FUN_004022e0(*param_1,0);
    iVar3 = FUN_00599e30(*(byte *)(param_1 + 1) & 1,uVar2);
    if (iVar3 == 0) {
      return 0;
    }
    uVar4 = CONCAT22(extraout_var,param_1[1]) & 0xffff0001;
    if (((DAT_00a54e5c >> 1 & 3) >> (sbyte)uVar4 & 1) != 0) {
      FUN_005af5a0(param_1[1] & 1,CONCAT22((short)(uVar4 >> 0x10),*param_1),0);
      return 0x7e;
    }
    FUN_005bf800(0x4d);
    return 0x7f;
  }
  uVar1 = FUN_004022e0(*param_1,0);
  FUN_0040c940(*(byte *)(param_1 + 1) & 1,6,uVar1);
  return 0x7e;
}


//// FUNC 005906b0 FUN_005906b0

uint FUN_005906b0(int param_1)

{
  uint uVar1;
  int iVar2;
  uint uVar3;
  undefined4 uVar4;
  byte bVar5;
  uint uVar6;
  uint uVar7;
  undefined1 uStack_4;
  
  uVar1 = FUN_00568ad0(*(byte *)(param_1 + 2) & 1,(*(ushort *)(param_1 + 4) & 0x1fe0) >> 5);
  if ((int)uVar1 < 0) {
    return uVar1 & 0xffff0000;
  }
  iVar2 = FUN_0056a400(*(byte *)(param_1 + 2) & 1);
  if (iVar2 == -1) {
    return 0xffff0000;
  }
  iVar2 = FUN_00583470(param_1,0,0);
  uVar1 = 0;
  if (iVar2 != 0) {
    uVar3 = FUN_00583440(param_1,0);
    uVar7 = uVar3 >> 8 & 0xff;
    uVar6 = *(byte *)(param_1 + 2) & 1;
    uVar1 = uVar3;
    if ((((uVar3 & 0xff) != uVar6) &&
        (uVar1 = uVar7 * 0x90 + (uVar3 & 1) * 0xd44,
        ((&DAT_00a55d74)[(uVar3 & 1) * 0x351 + uVar7 * 0x24] & 0xfff) != 0)) &&
       (((&DAT_00a55d7a)[uVar1] & 2) != 0)) {
      uVar4 = FUN_0056a400(uVar6);
      bVar5 = *(byte *)(param_1 + 2) & 1;
      FUN_00576110(bVar5,0xe,(*(ushort *)(param_1 + 4) & 0x1fe0) >> 5,bVar5,uVar4,1,0);
      uStack_4 = (undefined1)uVar4;
      uVar1 = FUN_00574990(*(byte *)(param_1 + 2) & 1,
                           CONCAT11(uStack_4,*(undefined1 *)(param_1 + 2)) & 0xff01,uVar3 & 0xffff);
    }
  }
  return uVar1 & 0xffff0000;
}


//// FUNC 005907d0 FUN_005907d0

uint FUN_005907d0(int param_1)

{
  uint in_EAX;
  int iVar1;
  uint uVar2;
  uint uVar3;
  uint uVar4;
  
  if ((*(byte *)(param_1 + 4) & 4) != 0) {
    return in_EAX & 0xffff0000;
  }
  iVar1 = FUN_00583470(param_1,0,0);
  uVar3 = 0;
  if (iVar1 != 0) {
    uVar2 = FUN_00583440(param_1,0);
    uVar4 = uVar2 >> 8 & 0xff;
    uVar3 = uVar4 * 0x90 + (uVar2 & 1) * 0xd44;
    if ((((&DAT_00a55d74)[(uVar2 & 1) * 0x351 + uVar4 * 0x24] & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[uVar3] & 2) != 0)) {
      FUN_00579990(uVar2 & 0xff,uVar4,0x11,1);
      uVar3 = FUN_005751e0(param_1,uVar2 & 0xff,uVar4,0,0);
    }
  }
  return uVar3 & 0xffff0000;
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


//// FUNC 005914a0 FUN_005914a0

byte FUN_005914a0(int param_1)

{
  ushort uVar1;
  byte bVar2;
  uint uVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  
  uVar3 = FUN_00583440(param_1,0);
  uVar4 = uVar3 >> 8 & 0xff;
  if ((*(byte *)(param_1 + 4) & 4) == 0) {
    switch(DAT_00a55c88._2_1_) {
    case 0x7c:
      FUN_00579890();
      break;
    case 0x7d:
      iVar5 = FUN_005919b0(*(undefined2 *)(param_1 + 8));
      bVar2 = *(byte *)(param_1 + 2) & 1;
      FUN_005adb10(bVar2,&DAT_00a582a4 + (uint)(DAT_00a55c88._2_2_ >> 8) * 2,1,0x20,0xe,bVar2);
      uVar1 = (DAT_00a55c88._2_2_ & 0xff00) + 0x100;
      DAT_00a55c88._2_2_ = uVar1 ^ DAT_00a55c88._2_2_ & 0xff;
      return ((int)(uint)(uVar1 >> 8) < iVar5) + 0x7c;
    case 0x7e:
      if (DAT_00a558b4 != 0) {
        DAT_00a55c88._2_2_ = DAT_00a55c88._2_2_ & 0xff;
        FUN_00579810();
        return 0x7d;
      }
      break;
    case 0x7f:
      iVar5 = FUN_005919b0(*(undefined2 *)(param_1 + 8));
      iVar6 = FUN_00570b40(*(byte *)(param_1 + 2) & 1);
      if (((iVar6 != 0) && (iVar6 = FUN_0056a000(*(byte *)(param_1 + 2) & 1), iVar5 <= iVar6)) &&
         (iVar6 = FUN_00599e30(*(byte *)(param_1 + 2) & 1,0x60a,*(undefined2 *)(param_1 + 8)),
         iVar6 == iVar5)) {
        if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) == 0) {
          FUN_005bf800(0x59);
          FUN_005bf9a0(1,0);
          return 0x7e;
        }
        DAT_00a558b4 = 1;
        return 0x7e;
      }
      break;
    case 0x80:
      iVar5 = FUN_00583470(param_1,0,0);
      if ((iVar5 != 0) && (iVar5 = FUN_0057c3b0(param_1,uVar3), iVar5 != 0)) {
        *(ushort *)(param_1 + 8) =
             *(ushort *)(&DAT_00a55d74 + uVar4 * 0x24 + (uVar3 & 1) * 0x351) & 0xfff;
        FUN_00577a60(param_1,uVar3 & 0xff,uVar4);
        if ((*(byte *)(param_1 + 2) & 1) ==
            ((uint)(&DAT_00a55d74)[uVar4 * 0x24 + (uVar3 & 1) * 0x351] >> 0xc & 1)) {
          iVar5 = FUN_00568bd0(&DAT_00a55d74 + uVar4 * 0x24 + (uVar3 & 1) * 0x351);
          return -(iVar5 != 0) & 0x7f;
        }
      }
    }
  }
  return 0;
}


//// FUNC 005916e0 FUN_005916e0

undefined4 FUN_005916e0(ushort *param_1,undefined4 param_2)

{
  ushort uVar1;
  undefined4 uVar2;
  
  uVar1 = param_1[1];
  if ((uVar1 & 0x3000) != 0x1000) {
    uVar2 = func_0x00584a90(param_1,param_2);
    return uVar2;
  }
  if (((ushort)(&DAT_00a55d74)[(uVar1 >> 1 & 0x1f) * 0x24 + (uVar1 & 1) * 0x351] & 0xfff) !=
      *param_1) {
    return 0;
  }
  uVar2 = func_0x005921c0(param_1,param_2);
  return uVar2;
}


//// FUNC 005921c0 FUN_005921c0

byte FUN_005921c0(undefined2 *param_1,undefined4 param_2)

{
  undefined2 uVar1;
  ushort uVar2;
  short sVar3;
  int iVar4;
  uint *puVar5;
  uint uVar6;
  uint uVar7;
  undefined2 extraout_var;
  uint uVar8;
  short *psVar9;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  uint uVar10;
  ushort uVar11;
  ushort *puVar12;
  bool bVar13;
  undefined4 uVar14;
  
  uVar10 = (ushort)param_1[1] >> 0xe & 1 ^ (ushort)param_1[1] & 1;
  if ((*(byte *)(param_1 + 2) & 4) != 0) {
    return 0;
  }
  switch(DAT_00a55c88._2_1_) {
  case 0x62:
  case 99:
    if ((DAT_00a55d3c & 0x3000000) == 0x3000000) {
      uVar6 = DAT_00a55d44 & 0xffff;
    }
    else {
      uVar6 = 0;
    }
    uVar7 = -(uint)(uVar10 != 0) & 0x8000;
    uVar14 = FUN_004022e0(uVar6);
    uVar14 = FUN_004022e0(CONCAT22(extraout_var_00,DAT_00a55d42),uVar14);
    uVar14 = FUN_004022e0(CONCAT22(extraout_var_01,DAT_00a55d40),uVar14);
    FUN_005b9170(CONCAT31((int3)(uVar7 >> 8),0xe8),uVar14);
    uVar14 = FUN_004022e0(DAT_00a55d3c >> 8,0,0);
    FUN_005b9170(uVar7 | 0xe9,uVar14);
    uVar14 = FUN_0040cab0(1,1,0xc,uVar10);
    FUN_005adb10(uVar10,uVar14);
    return 0x61;
  case 100:
    if ((DAT_00a55d3c >> 2 & 0x3000000) == (DAT_00a55d3c & 0x3000000)) {
      uVar6 = DAT_00a55d3c >> 0x18 & 3;
      if (-1 < (int)(uVar6 - 1)) {
        puVar12 = (ushort *)((int)&DAT_00a55d44 + (uVar6 - 1) * 2 + 2);
        do {
          FUN_005b9170(-(uint)(uVar10 != 0) & 0x8000 | 0x59,-((*puVar12 & 0x8000) != 0) & 0xb,
                       (char)*puVar12,0);
          puVar12 = puVar12 + -1;
          uVar6 = uVar6 - 1;
        } while (uVar6 != 0);
      }
    }
    if ((DAT_00a55d3c & 0xc000000) == 0) {
      return 99;
    }
    uVar6 = DAT_00a55d3c ^ ((DAT_00a55d3c & 0xfc000000) - 1 ^ DAT_00a55d3c) & 0xc000000;
    uVar7 = uVar6 >> 0x1a & 3;
    uVar11 = *(ushort *)((int)&DAT_00a55d44 + uVar7 * 2 + 2);
    DAT_00a55d3c = uVar6;
    if ((uVar11 & 0x8000) == 0) {
      if ((uVar11 & 0x4000) != 0) {
        uVar6 = uVar11 & 0xff;
        FUN_005b9170(-(uint)(uVar10 != 0) & 0x8000 | 0x5a,0,uVar6,0);
        (&DAT_00a55d40)[DAT_00a55d3c >> 0x1a & 3] =
             *(ushort *)(&DAT_00a55d74 + uVar6 * 0x24 + uVar10 * 0x351) & 0xfff;
        sVar3 = FUN_004022e0(*param_1);
        if (sVar3 != 0x60b) {
          FUN_00577b90(uVar10,uVar6);
          return 100;
        }
        FUN_00577950(param_1,uVar10,uVar6,0x10);
      }
      return 100;
    }
    uVar8 = uVar11 & 0xff;
    iVar4 = 0;
    if (uVar7 != 0) {
      puVar12 = (ushort *)((int)&DAT_00a55d44 + 2);
      do {
        uVar11 = *puVar12;
        if (((uVar11 & 0x8000) != 0) && (uVar8 < (uVar11 & 0xff))) {
          *puVar12 = uVar11 - 1;
          uVar6 = DAT_00a55d3c;
        }
        iVar4 = iVar4 + 1;
        puVar12 = puVar12 + 1;
      } while (iVar4 < (int)(uVar6 >> 0x1a & 3));
    }
    FUN_005b9170(-(uint)(uVar10 != 0) & 0x8000 | 0x5a,0xb,uVar8,0);
    FUN_0059d040(uVar10);
    (&DAT_00a55d40)[DAT_00a55d3c >> 0x1a & 3] =
         *(ushort *)(&DAT_00a56434 + uVar8 + uVar10 * 0x351) & 0xfff;
    sVar3 = FUN_004022e0(*param_1);
    if (sVar3 == 0x60b) {
      uVar14 = FUN_005700f0(uVar10,0xb,uVar8,0x10);
      FUN_00575a80(uVar10,uVar14);
      return 100;
    }
    uVar14 = FUN_005700f0(uVar10,0xb,uVar8,0x20);
    FUN_00575af0(uVar10,uVar14);
    return 100;
  default:
    return 0;
  case 0x7d:
    if ((DAT_00a54e54 & 0x102) != 0) {
      FUN_00486d20();
      return 0x7e;
    }
    iVar4 = FUN_005aa440(0xf1);
    if (iVar4 == 0) {
      return 0x7d;
    }
    if (DAT_00a55048 == 0) {
      uVar11 = *(ushort *)(&DAT_00a55d74 + DAT_00a5504c * 0x24 + uVar10 * 0x351);
      iVar4 = ((uint)(&DAT_00a55d74)[DAT_00a5504c * 0x24 + uVar10 * 0x351] >> 0xc & 1) +
              ((uint)(&DAT_00a55d74)[DAT_00a5504c * 0x24 + uVar10 * 0x351] >> 0x18 & 0x7f) * 2;
    }
    else {
      if (DAT_00a55048 != 0xb) {
        return 0x7d;
      }
      iVar4 = DAT_00a5504c + uVar10 * 0x351;
      uVar11 = *(ushort *)(&DAT_00a56434 + iVar4);
      iVar4 = ((uint)(&DAT_00a56434)[iVar4] >> 0xc & 1) +
              ((uint)(&DAT_00a56434)[iVar4] >> 0x18 & 0x7f) * 2;
    }
    uVar11 = uVar11 & 0xfff;
    iVar4 = FUN_0056b440(uVar11,iVar4);
    if (iVar4 != 0) {
      return 0x7d;
    }
    if (uVar11 == 0) {
      return 0x7d;
    }
    iVar4 = FUN_00592040(uVar11);
    bVar13 = iVar4 != 0;
    iVar4 = FUN_00568580(uVar11);
    if (iVar4 != 0) {
      bVar13 = (DAT_00a55d3c & 0xf0000000) == 0;
    }
    if (DAT_00a55048 == 0) {
      *(ushort *)((int)&DAT_00a55d44 + (DAT_00a55d3c >> 0x1a & 3) * 2 + 2) =
           (ushort)DAT_00a5504c | 0x4000;
    }
    else if (DAT_00a55048 == 0xb) {
      *(ushort *)((int)&DAT_00a55d44 + (DAT_00a55d3c >> 0x1a & 3) * 2 + 2) =
           (ushort)DAT_00a5504c | 0x8000;
    }
    uVar8 = DAT_00a55d3c >> 0x1a & 3;
    uVar6 = uVar8 + 1;
    uVar7 = DAT_00a55d3c >> 0x18 & 3;
    if (uVar6 < uVar7) {
      iVar4 = uVar7 - uVar6;
      psVar9 = (short *)((int)&DAT_00a55d44 + uVar6 * 2 + 2);
      do {
        if (*psVar9 == *(short *)((int)&DAT_00a55d44 + uVar8 * 2 + 2)) {
          bVar13 = false;
        }
        psVar9 = psVar9 + 1;
        iVar4 = iVar4 + -1;
      } while (iVar4 != 0);
    }
    iVar4 = FUN_0056a030(uVar10);
    if ((iVar4 < 0) && ((DAT_00a55d3c >> 0x1a & 3) == (DAT_00a55d3c >> 0x18 & 3) - 1)) {
      if (DAT_00a55048 != 0) {
        return 0x7d;
      }
      iVar4 = FUN_00569e10(DAT_00a55044,DAT_00a5504c);
      if (iVar4 == 0) {
        return 0x7d;
      }
    }
    if (!bVar13) {
      return 0x7d;
    }
    iVar4 = FUN_005aa480();
    if (iVar4 == 0) {
      return 0x7d;
    }
    FUN_005920d0(uVar11);
    iVar4 = FUN_00568580(uVar11);
    if (iVar4 != 0) {
      DAT_00a55d3c = (DAT_00a55d3c & 0xf0000000) + 0x10000000 ^ DAT_00a55d3c & 0xfffffff;
    }
    FUN_00486ce0(uVar10,DAT_00a55048,DAT_00a5504c);
    if ((DAT_00a55d3c & 0xc000000) == 0) {
      DAT_00a55d3c = (DAT_00a55d3c & 0x3000000) << 2 | DAT_00a55d3c & 0xf3ffffff;
      return 100;
    }
    goto LAB_00592652;
  case 0x7e:
    break;
  case 0x7f:
    uVar1 = FUN_004022e0(CONCAT22((short)(DAT_00a55c88._2_1_ - 0x62 >> 0x10),*param_1),0);
    FUN_0040c940(uVar10,6,uVar1);
    return 0x7e;
  case 0x80:
    iVar4 = FUN_00580600(param_1,param_2,0);
    if (iVar4 == 0) {
      return 0;
    }
    if (((DAT_00a54e5c >> 1 & 3) >> (sbyte)uVar10 & 1) == 0) {
      FUN_005bf800(0x5b);
      return 0x7f;
    }
    iVar4 = FUN_005af5a0(uVar10,CONCAT22(extraout_var,*param_1),0);
    return (iVar4 < 0) - 1U & 0x7e;
  }
  puVar5 = (uint *)FUN_0040cab0();
  DAT_00a55d3c = (*puVar5 & 0xfff) << 8 | DAT_00a55d3c & 0xff0000ff;
  iVar4 = FUN_00591d10(uVar10,DAT_00a55d3c >> 8,0xa55d46);
  if (iVar4 == 0) {
    return 0;
  }
  uVar6 = FUN_005919b0(DAT_00a55d3c >> 8);
  uVar6 = uVar6 & 3;
  DAT_00a55d3c = uVar6 << 0x1a | uVar6 << 0x18 | DAT_00a55d3c & 0xffffff;
  if (((DAT_00a54e5c >> 1 & 3) >> (sbyte)uVar10 & 1) != 0) {
    return 100;
  }
  if (uVar6 == 2) {
    uVar14 = 0x5c;
LAB_00592344:
    FUN_005bf800(uVar14);
  }
  else if (uVar6 == 3) {
    uVar14 = 0x5d;
    goto LAB_00592344;
  }
  iVar4 = 0;
  if ((DAT_00a55d3c >> 0x18 & 3) != 0) {
    puVar12 = (ushort *)((int)&DAT_00a55d44 + 2);
    do {
      uVar11 = *puVar12;
      uVar2 = 0;
      if ((uVar11 & 0x8000) != 0) {
        uVar2 = *(ushort *)(&DAT_00a56434 + uVar10 * 0x351 + (uVar11 & 0xff)) & 0xfff;
      }
      if ((uVar11 & 0x4000) != 0) {
        uVar2 = *(ushort *)(&DAT_00a55d74 + (uVar11 & 0xff) * 0x24 + uVar10 * 0x351) & 0xfff;
      }
      puVar12[-3] = uVar2;
      iVar4 = iVar4 + 1;
      puVar12 = puVar12 + 1;
    } while (iVar4 < (int)(DAT_00a55d3c >> 0x18 & 3));
  }
LAB_00592652:
  DAT_00a55d3c = DAT_00a55d3c ^ ((DAT_00a55d3c & 0xfc000000) - 1 ^ DAT_00a55d3c) & 0xc000000;
  return 0x7d;
}


//// FUNC 00593970 FUN_00593970

undefined4 FUN_00593970(undefined2 *param_1,undefined4 param_2)

{
  ushort uVar1;
  undefined4 uVar2;
  
  uVar1 = FUN_004022e0(*param_1);
  if (uVar1 < 0x535) {
    if (((uVar1 != 0x534) && (uVar1 != 0x15c)) && ((uVar1 < 0x2d9 || (0x2da < uVar1))))
    goto LAB_005939a4;
  }
  else if (uVar1 != 0x536) goto LAB_005939a4;
  if (((&DAT_00a55d74)[((ushort)param_1[1] >> 1 & 0x1f) * 0x24 + ((ushort)param_1[1] & 1) * 0x351] &
      0xfff) == 0) {
    return 1;
  }
LAB_005939a4:
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) != 0) {
    uVar2 = FUN_005b3fa0(param_1,param_2,0x5e);
    return uVar2;
  }
  uVar2 = FUN_00593440(param_1,param_2);
  return uVar2;
}


//// FUNC 00593a20 FUN_00593a20

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00593a20(undefined2 *param_1,undefined4 param_2)

{
  short sVar1;
  int iVar2;
  undefined4 uVar3;
  int iVar4;
  byte bVar5;
  undefined1 auStack_100 [256];
  
  if ((param_1[1] & 0x3000) == 0x2000) {
    return 1;
  }
  iVar2 = FUN_0059dca0(param_1);
  if (iVar2 == 0) {
    return 1;
  }
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) != 0) {
    uVar3 = FUN_005b3fa0(param_1,param_2,300);
    return uVar3;
  }
  if (DAT_00a55c8e == 0) {
    sVar1 = FUN_004022e0(*param_1);
    if (sVar1 == 0x4e9) {
      uVar3 = FUN_00402460(0x4ea);
      uVar3 = FUN_00402290(uVar3);
      FUN_005bdf40(auStack_100,0x43,uVar3);
      FUN_005bf800(auStack_100);
    }
    else {
      FUN_005bf800(0x65);
    }
    param_1[2] = param_1[2] & 0x1fff;
    bVar5 = DAT_00a55c8e + 1;
  }
  else {
    if ((DAT_00a54e54 & 0x102) == 0) {
      FUN_005929d0();
      iVar2 = FUN_005aa440(0xe000e0);
      uVar3 = DAT_00a55044;
      if (iVar2 == 0) {
        return 0;
      }
      iVar2 = DAT_00a55048 + DAT_00a5504c;
      iVar4 = FUN_0057a470(param_1,CONCAT11((char)iVar2,(char)DAT_00a55044));
      if (iVar4 == 0) {
        return 0;
      }
      iVar2 = FUN_00592b00(param_1,uVar3,iVar2);
      if (iVar2 == 0) {
        return 0;
      }
      return 1;
    }
    bVar5 = DAT_00a55c8e - 1;
  }
  _DAT_00a55c8e = _DAT_00a55c8e ^ (bVar5 ^ DAT_00a55c8e);
  return 0;
}


//// FUNC 005944d0 FUN_005944d0

void FUN_005944d0(int param_1,undefined4 param_2)

{
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
    FUN_005b3fa0(param_1,param_2,500);
    return;
  }
  FUN_00593440(param_1,param_2);
  return;
}


//// FUNC 00594860 FUN_00594860

void FUN_00594860(int param_1,undefined4 param_2)

{
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
    FUN_005b3fa0(param_1,param_2,0x4de);
    return;
  }
  FUN_00593440(param_1,param_2);
  return;
}


//// FUNC 00594a10 FUN_00594a10

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00594a10(int param_1,undefined4 param_2)

{
  int iVar1;
  uint uVar2;
  
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) == 0) {
    if (DAT_00a55c8e == '\0') {
      *(ushort *)(param_1 + 4) = *(ushort *)(param_1 + 4) & 0x1fff;
      iVar1 = FUN_0059dca0(param_1);
      if (iVar1 < 2) {
        FUN_00592a90(param_1,(*(ushort *)(param_1 + 0x10) & 0x100) >> 8,
                     *(ushort *)(param_1 + 0x10) >> 9 & 0xf);
        FUN_00592a50(param_1,*(ushort *)
                              (&DAT_00a55d74 +
                              ((*(ushort *)(param_1 + 0x10) & 0x1e00) >> 9) * 0x24 +
                              (*(ushort *)(param_1 + 0x10) >> 8 & 1) * 0x351) & 0xfff);
        return 1;
      }
      FUN_005bf800(0x10f);
      _DAT_00a55c8e = _DAT_00a55c8e ^ (byte)(DAT_00a55c8e + 1 ^ DAT_00a55c8e);
    }
    else {
      iVar1 = FUN_00593440(param_1,param_2);
      if (iVar1 != 0) {
        uVar2 = FUN_00583440(param_1,0);
        goto LAB_00594a82;
      }
    }
  }
  else {
    iVar1 = FUN_005b3fa0(param_1,param_2,0);
    if (iVar1 != 0) {
      uVar2 = FUN_00583440(param_1,0);
LAB_00594a82:
      FUN_00592a50(param_1,*(ushort *)
                            (&DAT_00a55d74 + (uVar2 >> 8 & 0xff) * 0x24 + (uVar2 & 1) * 0x351) &
                           0xfff);
      return 1;
    }
  }
  return 0;
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


//// FUNC 00595530 FUN_00595530

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00595530(int param_1,undefined4 param_2)

{
  bool bVar1;
  ushort uVar2;
  int iVar3;
  int iVar4;
  undefined4 uVar5;
  byte bVar6;
  
  if (DAT_00a55c8e != '\0') {
    if (DAT_00a55c8e == '\n') {
      if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) == 0) {
        FUN_005bf800(0x109);
        FUN_005bf9a0(1,0);
        bVar6 = DAT_00a55c8e;
      }
      else {
        DAT_00a558b4 = 2;
        bVar6 = 10;
      }
      _DAT_00a55c8e = _DAT_00a55c8e ^ (byte)(bVar6 + 1 ^ bVar6);
      return 0;
    }
    if (DAT_00a55c8e == '\v') {
      *(short *)(param_1 + 8) = DAT_00a558b4 + 1;
      _DAT_00a55c8e = _DAT_00a55c8e & 0xff00;
    }
    goto LAB_00595658;
  }
  iVar3 = FUN_00582590(param_1,param_2,0);
  if ((((*(ushort *)(param_1 + 2) & 0xfc0) == 0x480) &&
      (uVar2 = *(ushort *)(param_1 + 2) & 1, *(byte *)(param_1 + 0x10) != uVar2)) &&
     (*(byte *)(param_1 + 0x12) == uVar2)) {
    iVar4 = FUN_0059dca0(param_1);
    if (iVar4 == 0) goto LAB_00595627;
    bVar1 = true;
  }
  else {
LAB_00595627:
    bVar1 = false;
  }
  if (iVar3 == 2) {
    if (bVar1) {
      _DAT_00a55c8e = (short)CONCAT31((uint3)(byte)(_DAT_00a55c8e >> 8),10);
      return 0;
    }
    *(undefined2 *)(param_1 + 8) = 1;
  }
  else {
    *(undefined2 *)(param_1 + 8) = 2;
  }
LAB_00595658:
  if (*(short *)(param_1 + 8) == 1) {
    uVar5 = func_0x00595360(param_1,param_2);
    return uVar5;
  }
  if (*(short *)(param_1 + 8) != 2) {
    return 1;
  }
  uVar5 = func_0x00596910(param_1,param_2);
  return uVar5;
}


//// FUNC 00595780 FUN_00595780

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00595780(int param_1,undefined4 param_2)

{
  undefined1 extraout_AH;
  undefined2 uVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  byte bVar5;
  uint uVar6;
  uint unaff_ESI;
  uint uStack_104;
  undefined1 auStack_100 [256];
  
  switch(_DAT_00a55c8e & 0xff) {
  case 0:
    *(ushort *)(param_1 + 4) = *(ushort *)(param_1 + 4) & 0x1fff;
    iVar3 = FUN_0059dca0(param_1);
    if (iVar3 == 0) {
      return 0;
    }
    if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) == 0) {
      FUN_005bf800(0x8b);
    }
    else {
      iVar3 = FUN_005b3fa0(param_1,param_2,0);
      if (iVar3 != 0) {
        _DAT_00a55c8e = _DAT_00a55c8e & 0xffffff02 | 2;
        return 0;
      }
    }
    goto LAB_00595a55;
  case 1:
    FUN_005929d0();
    iVar3 = FUN_005aa440(0xff00ff);
    uVar2 = DAT_00a55044;
    if (iVar3 == 0) {
      return 0;
    }
    iVar3 = DAT_00a5504c + DAT_00a55048;
    iVar4 = FUN_0057b3b0(param_1,CONCAT11((char)iVar3,(char)DAT_00a55044));
    break;
  case 2:
    iVar3 = 0;
    uStack_104 = 0;
    do {
      unaff_ESI = CONCAT22((short)(unaff_ESI >> 0x10),(ushort)(byte)uStack_104);
      uVar6 = 0;
      do {
        iVar4 = FUN_00595690(param_1,param_2,(uVar6 & 0xff) << 8 | unaff_ESI);
        if (iVar4 != 0) {
          iVar3 = iVar3 + 1;
        }
        uVar6 = uVar6 + 1;
      } while ((int)uVar6 < 5);
      uStack_104 = uStack_104 + 1;
    } while ((int)uStack_104 < 2);
    if (iVar3 == 0) {
      return 1;
    }
    if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
      uStack_104 = FUN_00583440(param_1,0);
      uStack_104 = uStack_104 & 0xff;
      FUN_00583440(param_1,0);
      FUN_0056fb40(uStack_104,extraout_AH);
      iVar3 = 0;
      do {
        uStack_104 = uStack_104 ^ 1;
        uVar6 = 0;
        do {
          iVar4 = FUN_00595690(param_1,param_2,(uVar6 & 0xff) << 8 | uStack_104);
          if (iVar4 != 0) {
            FUN_00592a90(param_1,uStack_104,uVar6);
            return 1;
          }
          uVar6 = uVar6 + 1;
        } while ((int)uVar6 < 5);
        iVar3 = iVar3 + 1;
      } while (iVar3 < 2);
      return 1;
    }
    uVar1 = FUN_00583440(param_1,0);
    uVar2 = FUN_00402290(*(ushort *)
                          (&DAT_00a55d74 +
                          (uint)(byte)((ushort)uVar1 >> 8) * 0x24 + ((byte)uVar1 & 1) * 0x351) &
                         0xfff);
    FUN_005bdf40(auStack_100,0x8c,uVar2);
    FUN_005bf800(auStack_100);
    goto LAB_00595a55;
  case 3:
    FUN_005929d0();
    iVar3 = FUN_005aa440(0xe000e0);
    uVar2 = DAT_00a55044;
    if (iVar3 == 0) {
      return 0;
    }
    iVar3 = DAT_00a5504c + DAT_00a55048;
    iVar4 = FUN_00595690(param_1,param_2,CONCAT11((char)iVar3,(char)DAT_00a55044));
    break;
  default:
    return 1;
  }
  if (iVar4 == 0) {
    return 0;
  }
  iVar3 = FUN_00592b00(param_1,uVar2,iVar3);
  if (iVar3 == 0) {
    return 0;
  }
LAB_00595a55:
  bVar5 = DAT_00a55c8e + 1 ^ DAT_00a55c8e;
  _DAT_00a55c8e = _DAT_00a55c8e ^ bVar5;
  return 0;
}


//// FUNC 00595a90 FUN_00595a90

undefined4 FUN_00595a90(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  
  if ((*(ushort *)(param_1 + 2) & 0x3000) != 0x2000) {
    return 1;
  }
  uVar1 = func_0x00595ac0(param_1,param_2);
  return uVar1;
}


//// FUNC 00595ce0 FUN_00595ce0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00595ce0(undefined2 *param_1)

{
  if (DAT_00a55c8e == '\0') {
    param_1[2] = param_1[2] & 0x1fff;
    func_0x005bcfa0(*(byte *)(param_1 + 1) & 1,*param_1);
  }
  else {
    if (DAT_00a55c8e != '\x01') {
      return 1;
    }
    FUN_005b9170(CONCAT22((short)((uint)param_1 >> 0x10),param_1[1]) << 0xf | 0x88,
                 (byte)param_1[1] >> 1 & 0x1f,_DAT_00a57822 + 1,0);
  }
  _DAT_00a55c8e = _DAT_00a55c8e ^ (byte)(DAT_00a55c8e + 1 ^ DAT_00a55c8e);
  return 0;
}


//// FUNC 005961c0 FUN_005961c0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005961c0(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  byte bVar6;
  int iVar7;
  
  iVar3 = param_1;
  switch(_DAT_00a55c8e & 0xff) {
  case 0:
    iVar7 = 0;
    *(ushort *)(param_1 + 4) = *(ushort *)(param_1 + 4) & 0x1fff;
    iVar5 = FUN_00581de0(param_1,0,0);
    if (iVar5 == 0) {
      return 1;
    }
    bVar6 = (byte)*(undefined2 *)(param_1 + 2);
    if (((DAT_00a54e5c >> 1 & 3) >> (bVar6 & 1) & 1) != 0) {
      bVar6 = ~bVar6 & 1;
      param_1 = 0;
      do {
        iVar5 = 0;
        do {
          iVar2 = FUN_0059dc50(iVar3,bVar6,iVar5);
          if (iVar2 != 0) {
            FUN_00592a90(iVar3,bVar6,iVar5);
            iVar7 = iVar7 + 1;
            if (1 < iVar7) {
              return 1;
            }
          }
          iVar5 = iVar5 + 1;
        } while (iVar5 < 5);
        bVar6 = bVar6 ^ 1;
        param_1 = param_1 + 1;
      } while (param_1 < 2);
      return 1;
    }
    FUN_005bf800(0x92);
    bVar6 = DAT_00a55c8e + 1 ^ DAT_00a55c8e;
    _DAT_00a55c8e = _DAT_00a55c8e ^ bVar6;
    return 0;
  case 1:
    if ((DAT_00a54e54 & 0x102) == 0) {
      FUN_005929d0();
      iVar3 = FUN_005aa440(0xe000e0);
      uVar1 = DAT_00a55044;
      if (iVar3 == 0) {
        return 0;
      }
      iVar3 = DAT_00a5504c + DAT_00a55048;
      iVar5 = FUN_0059dc50(param_1,DAT_00a55044,iVar3);
      if (iVar5 == 0) {
        return 0;
      }
      iVar3 = FUN_00592b00(param_1,uVar1,iVar3);
      if (iVar3 == 0) {
        return 0;
      }
      bVar6 = DAT_00a55c8e + 1;
      goto LAB_00596340;
    }
    break;
  case 2:
    FUN_005bf800(0x93);
    bVar6 = DAT_00a55c8e + 1 ^ DAT_00a55c8e;
    _DAT_00a55c8e = _DAT_00a55c8e ^ bVar6;
    return 0;
  case 3:
    if ((DAT_00a54e54 & 0x102) == 0) {
      FUN_005929d0();
      iVar3 = FUN_005aa440(0xe000e0);
      uVar1 = DAT_00a55044;
      if (iVar3 != 0) {
        iVar3 = DAT_00a5504c + DAT_00a55048;
        uVar4 = FUN_00583440(param_1,0);
        if (((uVar4 != CONCAT11((char)iVar3,(char)uVar1)) &&
            (iVar5 = FUN_0059dc50(param_1,uVar1,iVar3), iVar5 != 0)) &&
           (iVar3 = FUN_00592b00(param_1,uVar1,iVar3), iVar3 != 0)) {
          return 1;
        }
      }
      return 0;
    }
    break;
  default:
    return 1;
  }
  bVar6 = DAT_00a55c8e - 1;
LAB_00596340:
  bVar6 = bVar6 ^ DAT_00a55c8e;
  _DAT_00a55c8e = _DAT_00a55c8e ^ bVar6;
  return 0;
}


//// FUNC 00596d70 FUN_00596d70

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_00596d70(int param_1)

{
  undefined4 uVar1;
  int iVar2;
  int iVar3;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined2 extraout_var;
  byte bVar4;
  uint unaff_ESI;
  undefined2 uVar6;
  uint uVar5;
  undefined4 unaff_EDI;
  uint uVar7;
  int iStack_108;
  int iStack_104;
  undefined1 auStack_100 [256];
  
  uVar6 = (undefined2)(unaff_ESI >> 0x10);
  switch(_DAT_00a55c8e & 0xff) {
  case 0:
    *(ushort *)(param_1 + 4) = *(ushort *)(param_1 + 4) & 0x1fff;
    if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) == 0) {
      FUN_005bdfc0(auStack_100,0x9b,2);
      FUN_005bf800(auStack_100);
      bVar4 = DAT_00a55c8e + 1 ^ DAT_00a55c8e;
      _DAT_00a55c8e = _DAT_00a55c8e ^ bVar4;
      return 0;
    }
    iVar2 = 0;
    iStack_108 = 0;
    do {
      iStack_104 = 0;
      bVar4 = *(byte *)(param_1 + 2) & 1 ^ iStack_108 == 0;
      do {
        iVar3 = FUN_00569f70(bVar4,iStack_104);
        if (iVar3 != 0) {
          unaff_ESI = CONCAT22((short)(unaff_ESI >> 0x10),(ushort)(byte)iStack_104) << 8;
          FUN_005b9170(CONCAT22((short)((uint)iVar3 >> 0x10),*(short *)(param_1 + 2) << 0xf) | 8,
                       bVar4,unaff_ESI,1);
          FUN_00592a50(param_1,CONCAT31((int3)((uint)extraout_ECX >> 8),bVar4) & 0xffff00ff |
                               unaff_ESI);
          iVar2 = iVar2 + 1;
          if (1 < iVar2) {
            return 1;
          }
        }
        iStack_104 = iStack_104 + 1;
      } while (iStack_104 < 5);
      iStack_108 = iStack_108 + 1;
    } while (iStack_108 < 2);
    return 1;
  case 1:
    if ((DAT_00a54e54 & 0x102) != 0) {
      bVar4 = DAT_00a55c8e - 1;
      goto LAB_00596ffb;
    }
    FUN_005929d0();
    uVar1 = DAT_00a55044;
    iVar2 = DAT_00a55048 + DAT_00a5504c;
    if (4 < iVar2) {
      return 0;
    }
    iVar3 = FUN_00569f70(DAT_00a55044,iVar2);
    if (iVar3 == 0) {
      return 0;
    }
    FUN_00449780(uVar1,iVar2);
    if ((DAT_00a54e54 & 0x201) == 0) {
      return 0;
    }
    iStack_108._0_1_ = (byte)iVar2;
    uVar7 = CONCAT22(uVar6,(ushort)(byte)iStack_108) << 8;
    FUN_005b9170(CONCAT22((short)(DAT_00a54e54 >> 0x10),*(short *)(param_1 + 2) << 0xf) | 8,uVar1,
                 uVar7,1);
    uVar7 = CONCAT31((int3)((uint)extraout_ECX_00 >> 8),(char)uVar1) & 0xffff00ff | uVar7;
    break;
  case 2:
    bVar4 = DAT_00a55c8e + 1 ^ DAT_00a55c8e;
    _DAT_00a55c8e = _DAT_00a55c8e ^ bVar4;
    return 0;
  case 3:
    if ((DAT_00a54e54 & 0x102) != 0) {
      return 0;
    }
    FUN_005929d0();
    uVar1 = DAT_00a55044;
    iVar2 = DAT_00a5504c + DAT_00a55048;
    if (4 < iVar2) {
      return 0;
    }
    iVar3 = FUN_00569f70(DAT_00a55044,iVar2);
    if (iVar3 == 0) {
      return 0;
    }
    uVar5 = CONCAT22(uVar6,(ushort)(byte)iVar2) << 8;
    uVar7 = CONCAT22((short)((uint)unaff_EDI >> 0x10),(ushort)(byte)uVar1) | uVar5;
    if ((short)uVar7 == *(short *)(param_1 + 6)) {
      return 0;
    }
    FUN_00449780(uVar1,iVar2);
    if ((DAT_00a54e54 & 0x201) == 0) {
      return 0;
    }
    FUN_005b9170(CONCAT22(extraout_var,*(short *)(param_1 + 2) << 0xf) | 8,uVar1,uVar5,1);
    break;
  default:
    return 1;
  }
  FUN_00592a50(param_1,uVar7);
  bVar4 = DAT_00a55c8e + 1;
LAB_00596ffb:
  bVar4 = bVar4 ^ DAT_00a55c8e;
  _DAT_00a55c8e = _DAT_00a55c8e ^ bVar4;
  return 0;
}


//// FUNC 00597030 FUN_00597030

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int FUN_00597030(undefined2 *param_1)

{
  undefined1 uVar1;
  undefined2 uVar2;
  int iVar3;
  uint uVar4;
  uint *puVar5;
  undefined2 extraout_var;
  undefined4 uVar6;
  undefined1 auStack_100 [256];
  
  if (DAT_00a55c8e == '\0') {
    param_1[2] = param_1[2] & 0x1fff;
    iVar3 = FUN_005709f0(*(byte *)(param_1 + 1) & 1,0x53c);
    if (-1 < iVar3) {
      uVar1 = (&DAT_00a563f1)[iVar3 * 2 + (*(byte *)(param_1 + 1) & 1) * 0xd44];
      uVar4 = FUN_005687d0(uVar1);
      puVar5 = (uint *)FUN_005700f0(uVar4 & 0xff,uVar4 >> 8 & 0xff,uVar4 >> 0x10);
      uVar4 = *puVar5;
      FUN_00592a50(param_1,uVar1);
      uVar2 = FUN_004022e0(CONCAT22(extraout_var,*param_1),0);
      FUN_005797c0(*(byte *)(param_1 + 1) & 1,uVar2);
      if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) == 0) {
        uVar6 = FUN_00402290(uVar4 & 0xfff);
        FUN_005bdf40(auStack_100,0xd,uVar6);
        FUN_005bf800(auStack_100);
        FUN_005bf9a0(1,0);
      }
      else {
        DAT_00a558b4 = 1;
      }
      _DAT_00a55c8e = _DAT_00a55c8e ^ (byte)(DAT_00a55c8e + 1 ^ DAT_00a55c8e);
      return 0;
    }
    return -1;
  }
  if (DAT_00a55c8e != '\x01') {
    return 1;
  }
  return (-(uint)(DAT_00a558b4 != 0) & 2) - 1;
}


//// FUNC 00597520 FUN_00597520

void FUN_00597520(int param_1,undefined4 param_2)

{
  if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 2) & 1) & 1) != 0) {
    FUN_005b3fa0(param_1,param_2,0x5f9);
    return;
  }
  FUN_00593440(param_1,param_2);
  return;
}


//// FUNC 00599850 FUN_00599850

bool FUN_00599850(undefined2 *param_1)

{
  uint *puVar1;
  ushort uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  undefined2 extraout_var;
  uint *puVar7;
  int iVar8;
  
  iVar3 = FUN_00570b40(*(byte *)(param_1 + 1) & 1);
  if (((iVar3 != 0) && (iVar3 = FUN_005699c0(0x58a), iVar3 == 0)) &&
     (iVar3 = 0, (DAT_005ed060 & 0x1fff) != 0)) {
    puVar7 = &DAT_005ed060;
    do {
      uVar2 = FUN_004022e0(*param_1);
      if (((ushort)(*puVar7 >> 0xd) & 0x1fff) == uVar2) {
        iVar4 = FUN_00598f30(*(byte *)(param_1 + 1) & 1,iVar3);
        if (iVar4 == 0) {
          return false;
        }
        iVar4 = FUN_0056a030(*(byte *)(param_1 + 1) & 1);
        if (iVar4 < 0) {
          iVar8 = 0;
          iVar4 = 0;
          do {
            if ((*(uint *)((int)&DAT_00a55d74 + (*(byte *)(param_1 + 1) & 1) * 0xd44 + iVar4) &
                0xfff) != 0) {
              DAT_00a55c8c = 0xff;
              DAT_00a55c88._2_2_ =
                   CONCAT11((byte)((&DAT_005ed060)[iVar3] >> 0x1a),DAT_00a55c88._2_1_);
              iVar5 = FUN_00599140(param_1,*(byte *)(param_1 + 1) & 1,0,iVar8);
              if ((iVar5 != 0) &&
                 (iVar5 = FUN_00569e10(*(byte *)(param_1 + 1) & 1,iVar8), iVar5 != 0)) {
                return true;
              }
            }
            iVar4 = iVar4 + 0x90;
            iVar8 = iVar8 + 1;
            if (0x2cf < iVar4) {
              return false;
            }
          } while( true );
        }
        uVar6 = FUN_00402460(CONCAT22(extraout_var,*(undefined2 *)(&DAT_005ed060 + iVar3)) &
                             0xffff1fff);
        iVar4 = FUN_00598ff0(*(byte *)(param_1 + 1) & 1,uVar6);
        iVar8 = FUN_005990a0(*(byte *)(param_1 + 1) & 1);
        return (int)((&DAT_005ed060)[iVar3] >> 0x1a) <= iVar4 + iVar8;
      }
      puVar1 = puVar7 + 1;
      puVar7 = puVar7 + 1;
      iVar3 = iVar3 + 1;
    } while ((*puVar1 & 0x1fff) != 0);
  }
  return false;
}


//// FUNC 005999d0 FUN_005999d0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005999d0(undefined2 *param_1)

{
  ushort uVar1;
  int iVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  undefined4 uVar6;
  uint uVar7;
  undefined2 extraout_var;
  
  if ((*(byte *)(param_1 + 2) & 4) == 0) {
    switch(DAT_00a55c88._2_1_) {
    case 99:
      FUN_005adb10(*(byte *)(param_1 + 1) & 1,&DAT_00a55c90,1,1,0xb,DAT_00a53750);
      return 0x62;
    case 100:
      iVar2 = 0;
      uVar4 = *(byte *)(param_1 + 1) & 1;
      if (*(char *)(&DAT_00a55d68 + uVar4 * 0x6a2) != '\0') {
        do {
          uVar1 = FUN_004022e0(*(ushort *)(&DAT_00a56434 + iVar2 + uVar4 * 0x351) & 0xfff);
          iVar3 = FUN_00598ed0(*param_1);
          if (uVar1 == ((ushort)(&DAT_005ed060)[iVar3] & 0x1fff)) {
            FUN_005675c0(&DAT_00a55c90,&DAT_00a56434 + iVar2 + (*(byte *)(param_1 + 1) & 1) * 0x351)
            ;
            DAT_00a53750 = iVar2;
            return 99;
          }
          iVar2 = iVar2 + 1;
          uVar4 = *(byte *)(param_1 + 1) & 1;
        } while (iVar2 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar4 * 0x6a2));
        return 0;
      }
      break;
    default:
      DAT_00a55c88._2_1_ = 0;
      break;
    case 0x78:
      if (DAT_00a55c88._3_1_ == 0) {
        return 100;
      }
      iVar2 = 0;
      uVar4 = *(byte *)(param_1 + 1) & 1;
      if (*(char *)(&DAT_00a55d68 + uVar4 * 0x6a2) != '\0') {
        do {
          uVar1 = *(ushort *)(&DAT_00a56434 + iVar2 + uVar4 * 0x351);
          if (((uVar1 & 0xfff) != 0) && (iVar3 = FUN_00599140(param_1,uVar4,0xb,iVar2), iVar3 != 0))
          {
            uVar4 = FUN_004026c0(uVar1 & 0xfff);
            uVar4 = uVar4 & 0xffff;
            DAT_00a55c88._3_1_ =
                 ((int)(DAT_00a55c88._3_1_ - uVar4) < 0) - 1U & (byte)(DAT_00a55c88._3_1_ - uVar4);
            uVar7 = CONCAT11(uRam00a55c8d,DAT_00a55c8c) & 0xff;
            if (uVar7 <= uVar4) {
              uVar4 = uVar7;
            }
            DAT_00a55c8c = (undefined1)uVar4;
            uVar6 = FUN_005700f0(*(byte *)(param_1 + 1) & 1,0xb,iVar2,0);
            FUN_00575af0(*(byte *)(param_1 + 1) & 1,uVar6);
            return 0x78;
          }
          iVar2 = iVar2 + 1;
          uVar4 = *(byte *)(param_1 + 1) & 1;
        } while (iVar2 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar4 * 0x6a2));
      }
      iVar3 = 0;
      iVar2 = 0;
      while( true ) {
        uVar1 = *(ushort *)((int)&DAT_00a55d74 + (*(byte *)(param_1 + 1) & 1) * 0xd44 + iVar2) &
                0xfff;
        if ((uVar1 != 0) &&
           (iVar5 = FUN_00599140(param_1,*(byte *)(param_1 + 1) & 1,0,iVar3), iVar5 != 0)) break;
        iVar2 = iVar2 + 0x90;
        iVar3 = iVar3 + 1;
        if (0x2cf < iVar2) {
          return 0x78;
        }
      }
      uVar4 = FUN_004026c0(uVar1);
      uVar4 = uVar4 & 0xffff;
      DAT_00a55c88._3_1_ =
           ((int)(DAT_00a55c88._3_1_ - uVar4) < 0) - 1U & (byte)(DAT_00a55c88._3_1_ - uVar4);
      uVar7 = CONCAT11(uRam00a55c8d,DAT_00a55c8c) & 0xff;
      if (uVar7 <= uVar4) {
        uVar4 = uVar7;
      }
      DAT_00a55c8c = (undefined1)uVar4;
      FUN_00577b30(*(byte *)(param_1 + 1) & 1,iVar3);
      return 0x78;
    case 0x80:
      DAT_00a55c88._3_1_ = 0;
      iVar2 = FUN_00599850(param_1,0,0);
      if (((iVar2 != 0) && (iVar2 = FUN_00598ed0(CONCAT22(extraout_var,*param_1)), -1 < iVar2)) &&
         (iVar3 = FUN_00598f30(*(byte *)(param_1 + 1) & 1,iVar2), iVar3 != 0)) {
        DAT_00a55c8c = 0xff;
        DAT_00a55c88._3_1_ = (byte)((uint)(&DAT_005ed060)[iVar2] >> 0x1a);
        if (((DAT_00a54e5c >> 1 & 3) >> (*(byte *)(param_1 + 1) & 1) & 1) != 0) {
          return 0x78;
        }
        FUN_005bf800(0xcf);
        FUN_005bf9a0(9,DAT_00a55c88._3_1_);
        return 100;
      }
    }
  }
  return 0;
}


