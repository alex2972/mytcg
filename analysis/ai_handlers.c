//// FUNC 00581040 FUN_00581040

undefined4 FUN_00581040(void)

{
  return 1;
}


//// FUNC 00581eb0 FUN_00581eb0

bool FUN_00581eb0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_00569d90(1 - (*(byte *)(param_1 + 2) & 1),1,0);
  return 0 < iVar1;
}


//// FUNC 005b1b50 FUN_005b1b50

ushort FUN_005b1b50(int param_1)

{
  return (*(ushort *)(param_1 + 2) ^ DAT_00a577f8._2_2_) & 1;
}


//// FUNC 005b1b70 FUN_005b1b70

bool FUN_005b1b70(int param_1)

{
  if ((ushort)(&DAT_00a55d64)[(-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0x6a2] <=
      *(ushort *)(param_1 + 0x12)) {
    return true;
  }
  return *(ushort *)(param_1 + 0x12) <= *(ushort *)(param_1 + 0x10);
}


//// FUNC 005b1bb0 FUN_005b1bb0

undefined4 FUN_005b1bb0(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  
  iVar4 = 5;
  iVar5 = 0x2d0;
  do {
    iVar2 = -(*(byte *)(param_1 + 2) & 1);
    iVar1 = iVar5 + (iVar2 - 1U & 1) * 0xd44;
    uVar3 = *(uint *)((int)&DAT_00a55d74 + iVar1) & 0xfff;
    if ((uVar3 != 0) && (((&DAT_00a55d7a)[iVar1] & 2) != 0)) {
      iVar1 = FUN_00598b50(iVar2 + 1,iVar4,uVar3);
      if (iVar1 != 0) {
        return 1;
      }
    }
    iVar5 = iVar5 + 0x90;
    iVar4 = iVar4 + 1;
  } while (iVar5 < 0x5a0);
  return 0;
}


//// FUNC 005b1c30 FUN_005b1c30

undefined4 FUN_005b1c30(int param_1)

{
  ushort uVar1;
  short sVar2;
  uint uVar3;
  uint *puVar4;
  int iVar5;
  uint *puVar6;
  
  iVar5 = 0;
  if ((DAT_00a55c94 & 0x7f00) != 0) {
    puVar6 = &DAT_00a55ca8;
    do {
      if ((*(char *)((int)&DAT_00a55c94 + iVar5 + 2) == '\x15') &&
         (uVar3 = FUN_005687d0(*puVar6 & 0xff), uVar3 != 0x1000)) {
        puVar4 = (uint *)FUN_005700f0(uVar3 & 0xff,uVar3 >> 8 & 0xff,uVar3 >> 0x10);
        if (((*puVar6 >> 8 & 1) == (*(byte *)(param_1 + 2) & 1)) &&
           (uVar1 = FUN_004026c0((ushort)*puVar4 & 0xfff), 4 < uVar1)) {
          return 1;
        }
        sVar2 = FUN_004022e0((ushort)*puVar4 & 0xfff);
        if (((sVar2 == 0x2f) || (sVar2 == 0x23d)) &&
           ((*puVar4 >> 0xc & 1) == (*(byte *)(param_1 + 2) & 1))) {
          return 1;
        }
      }
      iVar5 = iVar5 + 1;
      puVar6 = puVar6 + 1;
    } while (iVar5 < (int)(DAT_00a55c94 >> 8 & 0x7f));
  }
  return 0;
}


//// FUNC 005b1d30 FUN_005b1d30

bool FUN_005b1d30(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  return 0 < iVar1;
}


//// FUNC 005b1d60 FUN_005b1d60

undefined4 FUN_005b1d60(int param_1)

{
  int iVar1;
  short sVar2;
  ushort uVar3;
  short sVar4;
  uint uVar5;
  int iVar6;
  
  sVar4 = 0;
  iVar6 = 0;
  do {
    iVar1 = iVar6 + (-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0xd44;
    uVar5 = *(uint *)((int)&DAT_00a55d74 + iVar1) & 0xfff;
    if ((uVar5 != 0) && (((&DAT_00a55d7a)[iVar1] & 2) != 0)) {
      sVar2 = FUN_00402650(uVar5);
      if (sVar2 != sVar4) {
        uVar3 = FUN_00402650(uVar5);
        if (uVar3 < 7) {
          if (sVar4 != 0) {
            return 1;
          }
          sVar4 = FUN_00402650(uVar5);
        }
      }
    }
    iVar6 = iVar6 + 0x90;
  } while (iVar6 < 0x241);
  return 0;
}


//// FUNC 005b1e00 FUN_005b1e00

undefined4 FUN_005b1e00(int param_1)

{
  int iVar1;
  
  iVar1 = func_0x005aef10(*(byte *)(param_1 + 2) & 1);
  if (((iVar1 < 2) && (1000 < (ushort)(&DAT_00a55d64)[(*(byte *)(param_1 + 2) & 1) * 0x6a2])) &&
     (*(ushort *)(param_1 + 0x10) < 0x5dc)) {
    return 0;
  }
  return 1;
}


//// FUNC 005b1e50 FUN_005b1e50

undefined4 FUN_005b1e50(int param_1)

{
  uint uVar1;
  int iVar2;
  
  uVar1 = *(byte *)(param_1 + 2) & 1;
  if (((DAT_00a577f8._2_1_ & 1) == 1 - uVar1) && ((DAT_00a577f8._2_1_ & 0xe) == 0)) {
    iVar2 = FUN_005afe90(uVar1);
    if (iVar2 < 1) {
      iVar2 = FUN_00569d90(1 - (*(byte *)(param_1 + 2) & 1),1,1);
      if (iVar2 != 0) {
        return 1;
      }
    }
  }
  return 0;
}


//// FUNC 005b1eb0 FUN_005b1eb0

bool FUN_005b1eb0(int param_1)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  iVar2 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
  return iVar2 < iVar1;
}


//// FUNC 005b1ef0 FUN_005b1ef0

void FUN_005b1ef0(int param_1)

{
  FUN_0056ce40(1 - (*(byte *)(param_1 + 2) & 1),1);
  return;
}


//// FUNC 005b1f10 FUN_005b1f10

undefined4 FUN_005b1f10(int param_1)

{
  undefined2 *puVar1;
  int iVar2;
  
  if ((DAT_00a577f8._2_1_ & 0xe) == 10) {
    iVar2 = 5;
    puVar1 = &DAT_00a5604a + (-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0x6a2;
    do {
      if (((*(uint *)(puVar1 + -3) & 0xfff) != 0) && ((*(byte *)((int)puVar1 + 1) & 4) == 0)) {
        return 1;
      }
      iVar2 = iVar2 + 1;
      puVar1 = puVar1 + 0x48;
    } while (iVar2 < 0xb);
  }
  return 0;
}


//// FUNC 005b1f70 FUN_005b1f70

undefined4 FUN_005b1f70(int param_1)

{
  int iVar1;
  uint uVar2;
  undefined1 auStack_4 [4];
  
  iVar1 = param_1;
  FUN_005aff10(1 - (*(byte *)(param_1 + 2) & 1),&param_1,auStack_4,1);
  if (-1 < param_1) {
    uVar2 = *(byte *)(iVar1 + 2) & 1;
    if (param_1 < (int)(uint)(ushort)(&DAT_00a55d64)[uVar2 * 0x6a2]) {
      if ((int)(uint)(ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] <= param_1) {
        return 1;
      }
      if ((0x5db < param_1) &&
         ((int)((uint)(ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] - param_1) <
          (int)(uint)(ushort)(&DAT_00a55d64)[uVar2 * 0x6a2])) {
        return 1;
      }
    }
  }
  FUN_005aff10(*(byte *)(iVar1 + 2) & 1,&param_1,auStack_4,1);
  if ((-1 < param_1) &&
     ((uVar2 = *(byte *)(iVar1 + 2) & 1, param_1 < (int)(uint)(ushort)(&DAT_00a55d64)[uVar2 * 0x6a2]
      && ((int)(uint)(ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] <= param_1)))) {
    return 1;
  }
  return 0;
}


//// FUNC 005b2090 FUN_005b2090

bool FUN_005b2090(int param_1)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = *(byte *)(param_1 + 2) & 1;
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  if ((int)(uint)(ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] <= iVar1 * 500) {
    return true;
  }
  iVar1 = FUN_00569d50(1 - uVar2);
  return 1 < iVar1;
}


//// FUNC 005b2110 FUN_005b2110

undefined4 FUN_005b2110(int param_1)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  
  iVar1 = FUN_00569d90(1 - (*(byte *)(param_1 + 2) & 1),0,0);
  iVar2 = FUN_00569d90(*(byte *)(param_1 + 2) & 1,0,0);
  if (2 < iVar1 + iVar2) {
    uVar3 = func_0x005aef10(*(byte *)(param_1 + 2) & 1);
    return uVar3;
  }
  return 0;
}


//// FUNC 005b2160 FUN_005b2160

bool FUN_005b2160(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  uint *puVar4;
  int iVar5;
  
  iVar2 = 0;
  uVar3 = 0;
  do {
    iVar5 = 5;
    puVar4 = &DAT_00a55d74 + (uVar3 & 1) * 0x351;
    do {
      if ((*puVar4 & 0xfff) != 0) {
        iVar1 = FUN_00567990(*puVar4 & 0xfff);
        if (iVar1 != 0) {
          iVar2 = iVar2 + 1;
        }
      }
      puVar4 = puVar4 + 0x24;
      iVar5 = iVar5 + -1;
    } while (iVar5 != 0);
    uVar3 = uVar3 + 1;
  } while ((int)uVar3 < 2);
  if ((int)(uint)(ushort)(&DAT_00a55d64)[(-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0x6a2] <=
      iVar2 * 500) {
    return true;
  }
  iVar2 = 0;
  iVar5 = 0;
  do {
    uVar3 = *(byte *)(param_1 + 2) & 1;
    iVar1 = iVar5 + (-uVar3 - 1 & 1) * 0xd44;
    if (((*(uint *)((int)&DAT_00a55d74 + iVar1) & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[iVar1] & 2) == 0)) {
      iVar2 = iVar2 + 1;
    }
    iVar1 = iVar5 + uVar3 * 0xd44;
    if (((*(uint *)((int)&DAT_00a55d74 + iVar1) & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[iVar1] & 2) == 0)) {
      iVar1 = FUN_00567620(*(ushort *)((int)&DAT_00a55d74 + iVar1) & 0xfff,0xffffffff);
      if (iVar1 != 0) {
        return false;
      }
    }
    iVar5 = iVar5 + 0x90;
  } while (iVar5 < 0x2d0);
  return 0 < iVar2;
}


//// FUNC 005b22a0 FUN_005b22a0

undefined4 FUN_005b22a0(int param_1)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  
  iVar4 = 0;
  iVar3 = 0;
  do {
    uVar1 = *(byte *)(param_1 + 2) & 1;
    iVar2 = iVar3 + uVar1 * 0xd44;
    if (((*(uint *)((int)&DAT_00a55d74 + iVar2) & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[iVar2] & 2) != 0)) {
      iVar2 = FUN_0056aa70(uVar1,iVar4);
      if (0 < iVar2) {
        return 1;
      }
    }
    iVar3 = iVar3 + 0x90;
    iVar4 = iVar4 + 1;
  } while (iVar3 < 0x2d0);
  return 0;
}


//// FUNC 005b2310 FUN_005b2310

undefined4 FUN_005b2310(int param_1)

{
  byte bVar1;
  ushort uVar2;
  uint uVar3;
  int iVar4;
  undefined4 uVar5;
  uint uVar6;
  ushort *puVar7;
  int iVar8;
  
  iVar8 = 0;
  if ((DAT_00a55c94 & 0x7f00) != 0) {
    puVar7 = (ushort *)&DAT_00a55ca8;
    do {
      bVar1 = *(byte *)((int)&DAT_00a55c94 + iVar8 + 2);
      if (((4 < bVar1) && (bVar1 < 8)) &&
         (uVar2 = *puVar7, (uVar2 >> 8 & 1) != (*(byte *)(param_1 + 2) & 1))) {
        uVar3 = uVar2 >> 8 & 1;
        uVar6 = uVar2 >> 9 & 0xf;
        if (((&DAT_00a55d7a)[uVar3 * 0xd44 + uVar6 * 0x90] & 2) != 0) {
          iVar4 = FUN_0056c510(uVar3,uVar6);
          if (iVar4 != 0) {
            iVar4 = FUN_0056f690((*puVar7 & 0x100) >> 8,*puVar7 >> 9 & 0xf);
            if (iVar4 < 0x7d1) {
              uVar5 = FUN_004022e0(*(ushort *)
                                    (&DAT_00a55d74 +
                                    ((*puVar7 & 0x1e00) >> 9) * 0x24 + (*puVar7 >> 8 & 1) * 0x351) &
                                   0xfff);
              iVar4 = FUN_00569300((*puVar7 & 0x100) >> 8,uVar5);
              if (iVar4 != 0) {
                return 1;
              }
            }
          }
        }
      }
      iVar8 = iVar8 + 1;
      puVar7 = puVar7 + 2;
    } while (iVar8 < (int)(DAT_00a55c94 >> 8 & 0x7f));
  }
  return 0;
}


//// FUNC 005b2450 FUN_005b2450

bool FUN_005b2450(int param_1)

{
  byte bVar1;
  int iVar2;
  uint uVar3;
  undefined4 *puVar4;
  
  iVar2 = 0;
  uVar3 = DAT_00a55c94 >> 8 & 0x7f;
  if (uVar3 != 0) {
    puVar4 = &DAT_00a55ca8;
    do {
      bVar1 = *(byte *)((int)&DAT_00a55c94 + iVar2 + 2);
      if (((4 < bVar1) && (bVar1 < 8)) &&
         ((*(byte *)(param_1 + 2) & 1) == (*(byte *)((int)puVar4 + 1) & 1))) {
        return false;
      }
      iVar2 = iVar2 + 1;
      puVar4 = puVar4 + 1;
    } while (iVar2 < (int)uVar3);
  }
  iVar2 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  return iVar2 < 0;
}


//// FUNC 005b24c0 FUN_005b24c0

undefined4 FUN_005b24c0(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  
  iVar3 = 0;
  iVar4 = 0;
  do {
    iVar1 = FUN_0056f690(*(byte *)(param_1 + 2) & 1,iVar4);
    if (iVar3 <= iVar1) {
      iVar3 = FUN_0056f690(*(byte *)(param_1 + 2) & 1,iVar4);
    }
    iVar1 = FUN_0056f6b0(*(byte *)(param_1 + 2) & 1,iVar4);
    if (iVar3 <= iVar1) {
      iVar3 = FUN_0056f6b0(*(byte *)(param_1 + 2) & 1,iVar4);
    }
    iVar4 = iVar4 + 1;
  } while (iVar4 < 5);
  iVar4 = 0;
  iVar1 = 0;
  do {
    iVar2 = -(*(byte *)(param_1 + 2) & 1);
    if (((&DAT_00a55d7a)[(iVar2 - 1U & 1) * 0xd44 + iVar1] & 2) != 0) {
      iVar2 = FUN_0056f690(iVar2 + 1,iVar4);
      if (iVar3 < iVar2) {
        return 1;
      }
    }
    iVar1 = iVar1 + 0x90;
    iVar4 = iVar4 + 1;
  } while (iVar1 < 0x2d0);
  return 0;
}


//// FUNC 005b2580 FUN_005b2580

undefined4 FUN_005b2580(int param_1)

{
  int iVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  ushort uVar5;
  int iVar6;
  
  iVar3 = FUN_0056cdc0(*(byte *)(param_1 + 2) & 1);
  if (iVar3 != 0) {
    iVar6 = 0;
    do {
      iVar1 = iVar6 + (-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0xd44;
      uVar5 = *(ushort *)((int)&DAT_00a55d74 + iVar1) & 0xfff;
      if ((((&DAT_00a55d7a)[iVar1] & 2) != 0) && (uVar5 != 0)) {
        sVar2 = FUN_004026c0(uVar5);
        if (sVar2 != 0) {
          uVar4 = FUN_004026c0(uVar5);
          if ((int)(uVar4 & 0xffff) <= iVar3) {
            return 1;
          }
        }
      }
      iVar6 = iVar6 + 0x90;
    } while (iVar6 < 0x2d0);
  }
  return 0;
}


//// FUNC 005b2620 FUN_005b2620

ushort FUN_005b2620(int param_1)

{
  return ~*(ushort *)(param_1 + 2) & 1 ^ DAT_00a577f8._2_1_ & 1;
}


//// FUNC 005b2640 FUN_005b2640

bool FUN_005b2640(undefined2 *param_1)

{
  bool bVar1;
  ushort uVar2;
  uint uVar3;
  undefined2 *puVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  uint uVar8;
  uint uVar9;
  int iStack_8;
  uint uStack_4;
  
  if (((ushort)param_1[1] & 0xfc0) != 0x480) {
    return false;
  }
  uVar8 = (ushort)param_1[1] & 1;
  uVar3 = DAT_00a57840 & 0xffff;
  uVar9 = DAT_00a57840 & 1;
  uStack_4 = uVar3 >> 0xb & 7;
  uVar7 = uVar3 >> 8 & 7;
  uVar3 = uVar3 >> 1 & 1;
  bVar1 = 4 < uStack_4;
  puVar4 = (undefined2 *)FUN_0056f690(uVar9,uVar7);
  if (bVar1) {
    iStack_8 = 0;
  }
  else if (((&DAT_00a55d7a)[uVar3 * 0xd44 + uStack_4 * 0x90] & 1) == 0) {
    iStack_8 = FUN_0056f690(uVar3,uStack_4);
  }
  else {
    iStack_8 = FUN_0056f6b0(uVar3,uStack_4);
  }
  uVar2 = FUN_004022e0(*param_1);
  if (uVar2 < 1099) {
    if (uVar2 == 0x44a) {
      iVar5 = func_0x005aef10(uVar8);
      if (iVar5 == 0) {
        return false;
      }
    }
    else {
      if (0x3c0 < uVar2) {
        switch(uVar2) {
        case 0x3de:
          goto LAB_005b28d9;
        default:
          return false;
        case 0x41f:
        case 0x420:
          goto LAB_005b2c45;
        case 0x447:
          goto LAB_005b2b69;
        }
      }
      if (uVar2 == 0x3c0) {
        if (uVar9 != 1 - uVar8) {
          return false;
        }
        if (bVar1) {
          if ((int)(uint)(ushort)(&DAT_00a55d64)[uVar8 * 0x6a2] <= (int)puVar4) {
            return true;
          }
        }
        else if (iStack_8 <= (int)puVar4) {
          return true;
        }
        if ((int)puVar4 < 0x5dc) {
          return false;
        }
        return true;
      }
      if (0x2ad < uVar2) {
        if (uVar2 != 0x3b1) {
          return false;
        }
        if (uVar9 != 1 - uVar8) {
          return false;
        }
        if (bVar1) {
          return false;
        }
        iVar6 = uStack_4 * 0x90;
        iVar5 = FUN_00567620((&DAT_00a55d74)[uVar3 * 0x351 + uStack_4 * 0x24] & 0xfff,0xffffffff);
        if (iVar5 == 0) {
          if ((int)puVar4 < iStack_8) {
            return false;
          }
          if (iStack_8 < 0x708) {
            return false;
          }
          return true;
        }
        return (bool)((byte)(&DAT_00a55d7a)[iVar6 + uVar3 * 0xd44] >> 1 & 1);
      }
      if (uVar2 == 0x2ad) {
LAB_005b28d9:
        return uVar9 == 1 - (*(byte *)(param_1 + 1) & 1);
      }
      if (uVar2 != 0x15c) {
        if (uVar2 != 0x28a) {
          return false;
        }
        if (uVar9 != 1 - uVar8) {
          return false;
        }
        if (bVar1) {
          return false;
        }
        if ((int)puVar4 < iStack_8) {
          return false;
        }
        iVar5 = FUN_00569d90(uVar8,1,0);
        if (iVar5 == 0) {
          return false;
        }
        return true;
      }
    }
    if (uVar9 != 1 - uVar8) {
      return false;
    }
    iVar5 = FUN_005699a0(uVar8,0x15c);
    if (iVar5 != 0) {
      return true;
    }
    if (!bVar1) {
      FUN_005aff10(1 - uVar8,&param_1,&uStack_4,1);
      if (puVar4 != param_1) {
        return false;
      }
      return true;
    }
    if ((int)puVar4 < (int)(uint)(ushort)(&DAT_00a55d64)[uVar8 * 0x6a2]) {
      return false;
    }
    return true;
  }
  if (uVar2 < 0x52c) {
    if (uVar2 == 0x52b) {
      if (uVar9 != 1 - uVar8) {
        return false;
      }
      uVar2 = FUN_004026c0(*(ushort *)(&DAT_00a55d74 + uVar7 * 0x24 + uVar9 * 0x351) & 0xfff);
      return 3 < uVar2;
    }
    switch(uVar2) {
    case 1099:
      goto LAB_005b2c45;
    case 0x4be:
      if (uVar9 == 1 - uVar8) {
        if ((int)(uint)(ushort)(&DAT_00a55d64)[(-uVar8 - 1 & 1) * 0x6a2] <= (int)puVar4) {
          return true;
        }
        if (0x5db < (int)puVar4) {
          return true;
        }
        if (bVar1) {
          if ((int)(uint)(ushort)(&DAT_00a55d64)[uVar8 * 0x6a2] <= (int)puVar4) {
            return true;
          }
        }
        else if (iStack_8 <= (int)puVar4) {
          return true;
        }
      }
      break;
    case 0x4dd:
LAB_005b2b69:
      if (uVar9 != 1 - uVar8) {
        return false;
      }
      if (!bVar1) {
        return false;
      }
      iVar5 = FUN_00569d50(*(byte *)(param_1 + 1) & 1);
      if (iVar5 != 0) {
        return false;
      }
      return true;
    case 0x525:
      if (((uVar9 == 1 - uVar8) && (!bVar1)) && (iStack_8 <= (int)puVar4)) {
        uVar3 = 0;
        iVar5 = 0;
        do {
          if (((uVar3 != uStack_4) &&
              (iVar6 = iVar5 + uVar8 * 0xd44, (*(uint *)((int)&DAT_00a55d74 + iVar6) & 0xfff) != 0))
             && ((((&DAT_00a55d7a)[iVar6] & 1) == 0 &&
                 (iVar6 = FUN_0056f690(uVar8,uVar3), (int)puVar4 < iVar6)))) {
            return true;
          }
          iVar5 = iVar5 + 0x90;
          uVar3 = uVar3 + 1;
        } while (iVar5 < 0x2d0);
      }
    }
  }
  else {
    if (uVar2 != 0x590) {
      if (uVar2 == 0x5f9) {
        param_1 = (undefined2 *)(1 - uVar8);
        if ((undefined2 *)uVar9 != param_1) {
          return false;
        }
        if (bVar1) {
          return false;
        }
        if ((int)puVar4 < iStack_8) {
          return false;
        }
        uVar3 = 0;
        iVar5 = 0;
        while ((((uVar3 == uVar7 ||
                 (iVar6 = iVar5 + (-uVar8 - 1 & 1) * 0xd44,
                 (*(uint *)((int)&DAT_00a55d74 + iVar6) & 0xfff) == 0)) ||
                (((&DAT_00a55d7a)[iVar6] & 2) == 0)) ||
               (iVar6 = FUN_0056f690(param_1,uVar3), iStack_8 <= iVar6))) {
          iVar5 = iVar5 + 0x90;
          uVar3 = uVar3 + 1;
          if (0x2cf < iVar5) {
            return false;
          }
        }
        return true;
      }
      if (uVar2 != 0x76e) {
        return false;
      }
      goto LAB_005b2b69;
    }
LAB_005b2c45:
    if (uVar9 == 1 - uVar8) {
      if (bVar1) {
        if ((int)(uint)(ushort)(&DAT_00a55d64)[uVar8 * 0x6a2] <= (int)puVar4) {
          return true;
        }
        if ((int)puVar4 < 0x5dc) {
          FUN_00569d90(1 - uVar8,1,1);
          return true;
        }
        return true;
      }
      if (iStack_8 <= (int)puVar4) {
        return true;
      }
      iVar5 = FUN_005b3d30(uVar8);
      if (iVar5 != 0) {
        return true;
      }
    }
  }
  return false;
}


//// FUNC 005b2e60 FUN_005b2e60

bool FUN_005b2e60(undefined2 *param_1)

{
  byte bVar1;
  ushort uVar2;
  short sVar3;
  uint uVar4;
  uint uVar5;
  int iVar6;
  uint uVar7;
  undefined2 extraout_var;
  undefined2 extraout_var_00;
  undefined2 extraout_var_01;
  undefined2 uVar8;
  undefined2 extraout_var_02;
  uint uVar9;
  uint uVar10;
  int iVar11;
  uint uVar12;
  int iVar13;
  uint uStack_10;
  
  if (((ushort)param_1[1] & 0xfc0) == 0x4c0) {
    uVar10 = (ushort)param_1[1] & 1;
    uVar4 = DAT_00a57840 & 0xffff;
    uVar7 = DAT_00a57840 & 1;
    uVar5 = uVar4 >> 0xb & 7;
    uVar12 = uVar4 >> 8 & 7;
    uVar4 = uVar4 >> 1 & 1;
    FUN_0056f690(uVar7,uVar12);
    uVar8 = extraout_var;
    if (uVar5 < 5) {
      if (((&DAT_00a55d7a)[uVar4 * 0xd44 + uVar5 * 0x90] & 1) == 0) {
        FUN_0056f690(uVar4,uVar5);
        uVar8 = extraout_var_01;
      }
      else {
        FUN_0056f6b0();
        uVar8 = extraout_var_00;
      }
    }
    uVar9 = 0;
    uStack_10 = 0;
    uVar2 = FUN_004022e0(CONCAT22(uVar8,*param_1));
    if (uVar2 < 0x43b) {
      if (uVar2 == 0x43a) {
        uStack_10 = 0xfffffe0c;
      }
      else {
        switch(uVar2) {
        case 0x3f7:
          uVar9 = 500;
          break;
        case 0x3f8:
          uStack_10 = 500;
          break;
        case 0x433:
          uVar9 = 700;
          break;
        case 0x434:
          uStack_10 = 700;
        }
      }
    }
    else if (uVar2 < 0x588) {
      if (uVar2 == 0x587) {
        uVar9 = 0xfffffd44;
      }
      else if (uVar2 == 0x4b3) {
        uVar9 = 400;
        uStack_10 = 400;
      }
      else if (uVar2 == 0x4b4) {
        uVar9 = 0xfffffe70;
        uStack_10 = 0xfffffe70;
      }
    }
    else if (uVar2 == 0x5fe) {
      uVar9 = FUN_0056cdc0(uVar10);
    }
    if (uVar5 < 5) {
      if ((uVar7 != uVar4) && (uStack_10 != 0 || uVar9 != 0)) {
        if (uVar10 == uVar4) {
          bVar1 = (&DAT_00a55d7a)[uVar10 * 0xd44 + uVar5 * 0x90];
          iVar11 = FUN_0056f690(1 - uVar10,uVar12);
          if ((bVar1 & 1) == 0) {
            iVar13 = FUN_0056f690(uVar10,uVar5);
            uVar4 = -uVar9 & ((int)-uVar9 < 0) - 1;
            uStack_10 = ((int)uVar9 < 0) - 1 & uVar9;
          }
          else {
            iVar13 = FUN_0056f6b0();
            uVar4 = ((int)-uVar9 < 0) - 1 & -uVar9;
            uStack_10 = ((int)uStack_10 < 0) - 1 & uStack_10;
          }
          if ((iVar13 < iVar11) && (iVar11 <= (int)(uVar4 + uStack_10 + iVar13))) {
            return true;
          }
        }
        else {
          bVar1 = (&DAT_00a55d7a)[(-uVar10 - 1 & 1) * 0xd44 + uVar5 * 0x90];
          iVar11 = FUN_0056f690(uVar10,uVar12);
          if ((bVar1 & 1) == 0) {
            iVar13 = FUN_0056f690(1 - uVar10,uVar5);
            uStack_10 = uVar9;
          }
          else {
            iVar13 = FUN_0056f6b0(1 - uVar10);
          }
          if ((iVar11 <= iVar13) &&
             ((int)((-uStack_10 & ((int)-uStack_10 < 0) - 1) + (((int)uVar9 < 0) - 1 & uVar9) +
                   iVar13) < iVar11)) {
            return true;
          }
        }
      }
    }
    else {
      iVar13 = 0;
      iVar11 = 0;
      do {
        iVar6 = FUN_0056b730(uVar7,iVar11,1);
        iVar13 = iVar13 + iVar6;
        iVar11 = iVar11 + 1;
      } while (iVar11 < 5);
      if (1 < iVar13) {
        sVar3 = FUN_004022e0(CONCAT22(extraout_var_02,*param_1));
        if (sVar3 == 0x4b3) {
          return (*(byte *)(param_1 + 1) & 1) == uVar7;
        }
        if (sVar3 == 0x4b4) {
          return (*(byte *)(param_1 + 1) & 1) == uVar4;
        }
      }
    }
  }
  return false;
}


//// FUNC 005b3210 FUN_005b3210

undefined4 FUN_005b3210(int param_1,undefined2 *param_2)

{
  ushort uVar1;
  
  if ((param_2 != (undefined2 *)0x0) &&
     (((*(byte *)(param_1 + 2) ^ *(byte *)(param_2 + 1)) & 1) != 0)) {
    uVar1 = FUN_00402700(*param_2);
    if ((1 < uVar1) && (uVar1 < 5)) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b3250 FUN_005b3250

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b3250(int param_1,undefined2 *param_2)

{
  short sVar1;
  
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  if (((*(byte *)(param_1 + 2) ^ *(byte *)(param_2 + 1)) & 1) == 0) {
    return 0;
  }
  sVar1 = FUN_004022e0(*param_2);
  if (sVar1 != 0x1ab) {
    return 0;
  }
  _DAT_00a579a4 = param_2[3] & 0xfff;
  return 1;
}


//// FUNC 005b32a0 FUN_005b32a0

undefined4 FUN_005b32a0(int param_1,undefined2 *param_2)

{
  ushort uVar1;
  undefined2 uVar2;
  short sVar3;
  
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  if (((*(byte *)(param_2 + 1) ^ *(byte *)(param_1 + 2)) & 1) == 0) {
    return 0;
  }
  uVar1 = FUN_004022e0(*param_2);
  if (0x40f < uVar1) {
    if (uVar1 < 0x470) {
      if (((uVar1 < 0x46e) && (uVar1 != 0x437)) && (uVar1 != 0x446)) {
        return 1;
      }
    }
    else if ((uVar1 != 0x486) && (uVar1 != 0x609)) {
      return 1;
    }
    goto LAB_005b338c;
  }
  if (uVar1 != 0x40f) {
    if (uVar1 < 0x3ef) {
      if (uVar1 == 0x3ee) {
        return 0;
      }
      if (0x15a < uVar1) {
        if (uVar1 != 0x3ec) {
          return 1;
        }
LAB_005b338c:
        uVar2 = FUN_00583440(param_2,0);
        sVar3 = FUN_004022e0(*(ushort *)
                              (&DAT_00a55d74 +
                              (uint)(byte)((ushort)uVar2 >> 8) * 0x24 + ((byte)uVar2 & 1) * 0x351) &
                             0xfff);
        if (sVar3 == 0x136) {
          return 0;
        }
        if (sVar3 == 0x405) {
          return 0;
        }
        return 1;
      }
      if (uVar1 < 0x156) {
        if (uVar1 < 0x151) {
          return 1;
        }
        if (0x155 < uVar1) {
          return 1;
        }
        return 0;
      }
    }
    else if (uVar1 != 0x3ef) {
      if (uVar1 != 0x3f1) {
        return 1;
      }
      goto LAB_005b338c;
    }
  }
  if (1000 < (ushort)(&DAT_00a55d64)[(*(byte *)(param_1 + 2) & 1) * 0x6a2]) {
    return 0;
  }
  return 1;
}


//// FUNC 005b3400 FUN_005b3400

undefined4 FUN_005b3400(undefined4 param_1,undefined2 *param_2)

{
  short sVar1;
  undefined4 uVar2;
  
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  sVar1 = FUN_004025d0(*param_2);
  if (sVar1 != 0x16) {
    return 0;
  }
  uVar2 = FUN_005b32a0(param_1,param_2);
  return uVar2;
}


//// FUNC 005b3440 FUN_005b3440

undefined4 FUN_005b3440(undefined4 param_1,undefined2 *param_2)

{
  short sVar1;
  undefined4 uVar2;
  
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  sVar1 = FUN_004025d0(*param_2);
  if (sVar1 != 0x15) {
    return 0;
  }
  uVar2 = FUN_005b32a0(param_1,param_2);
  return uVar2;
}


//// FUNC 005b3480 FUN_005b3480

undefined4 FUN_005b3480(int param_1,undefined2 *param_2)

{
  ushort uVar1;
  undefined2 uVar2;
  int iVar3;
  bool bVar4;
  
  if (param_2 == (undefined2 *)0x0) {
    return 0;
  }
  uVar1 = FUN_004022e0(*param_2);
  if (uVar1 < 0x427) {
    if (0x424 < uVar1) {
      return 1;
    }
    if (uVar1 < 0x24a) {
      if (uVar1 == 0x249) {
        iVar3 = 0;
        while( true ) {
          uVar2 = FUN_00583440(param_2,iVar3);
          if (((byte)uVar2 == ((byte)*(ushort *)(param_1 + 2) & 1)) &&
             ((byte)((ushort)uVar2 >> 8) == ((byte)(*(ushort *)(param_1 + 2) >> 1) & 0x1f))) break;
          iVar3 = iVar3 + 1;
          if (1 < iVar3) {
            return 0;
          }
        }
        return 1;
      }
      if ((uVar1 == 0x53) || (uVar1 == 0xdf)) goto LAB_005b3565;
      bVar4 = uVar1 == 0x1d4;
    }
    else {
      if (uVar1 == 0x29f) {
        return 1;
      }
      if (uVar1 == 0x3ec) goto LAB_005b3565;
      bVar4 = uVar1 == 0x3f1;
    }
    if (!bVar4) {
      return 0;
    }
  }
  else if (uVar1 < 0x470) {
    if (uVar1 < 0x46e) {
      if (uVar1 == 0x42b) {
        return 1;
      }
      if ((uVar1 != 0x437) && (uVar1 != 0x446)) {
        return 0;
      }
    }
  }
  else if ((uVar1 != 0x486) && (uVar1 != 0x609)) {
    return 0;
  }
LAB_005b3565:
  uVar2 = FUN_00583440(param_2,0);
  if (((byte)uVar2 == ((byte)*(ushort *)(param_1 + 2) & 1)) &&
     ((byte)((ushort)uVar2 >> 8) == ((byte)(*(ushort *)(param_1 + 2) >> 1) & 0x1f))) {
    return 1;
  }
  return 0;
}


//// FUNC 005b35a0 FUN_005b35a0

undefined4 FUN_005b35a0(int param_1,int param_2)

{
  int iVar1;
  undefined4 uVar2;
  
  if (param_2 == 0) {
    return 0;
  }
  iVar1 = FUN_0059dd20(param_1,*(byte *)(param_1 + 2) & 1);
  if (iVar1 == 0) {
    return 0;
  }
  uVar2 = FUN_005b3480(param_1,param_2);
  return uVar2;
}


//// FUNC 005b35e0 FUN_005b35e0

undefined4 FUN_005b35e0(int param_1,int param_2)

{
  int iVar1;
  undefined4 uVar2;
  
  if (param_2 == 0) {
    return 0;
  }
  iVar1 = FUN_0059dd20(param_1,1 - (*(byte *)(param_1 + 2) & 1));
  if (iVar1 == 0) {
    return 0;
  }
  uVar2 = FUN_005b3480(param_1,param_2);
  return uVar2;
}


//// FUNC 005b4860 FUN_005b4860

bool FUN_005b4860(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0059dd20(param_1,1 - (*(byte *)(param_1 + 2) & 1));
  return 0 < iVar1;
}


//// FUNC 005b4890 FUN_005b4890

bool FUN_005b4890(undefined2 *param_1)

{
  uint uVar1;
  undefined4 uVar2;
  uint uVar3;
  
  uVar2 = FUN_004022e0(*param_1);
  uVar3 = func_0x00569c50(*(byte *)(param_1 + 1) & 1,uVar2);
  uVar1 = (uint)((*(byte *)(param_1 + 1) & 0x3e) < 0x15);
  return uVar3 == uVar1 || (int)(uVar3 - uVar1) < 0;
}


//// FUNC 005b48d0 FUN_005b48d0

void FUN_005b48d0(int param_1)

{
  func_0x005aef10(*(byte *)(param_1 + 2) & 1);
  return;
}


//// FUNC 005b48f0 FUN_005b48f0

bool FUN_005b48f0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  return 0 < iVar1;
}


//// FUNC 005b4910 FUN_005b4910

bool FUN_005b4910(int param_1)

{
  uint uVar1;
  
  uVar1 = *(byte *)(param_1 + 2) & 1;
  return (uint)(ushort)(&DAT_00a55d64)[(-uVar1 - 1 & 1) * 0x6a2] <
         (ushort)(&DAT_00a55d64)[uVar1 * 0x6a2] + 500;
}


//// FUNC 005b4970 FUN_005b4970

bool FUN_005b4970(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0056a320(1 - (*(byte *)(param_1 + 2) & 1),0,0,1);
  return 1 < iVar1;
}


//// FUNC 005b49a0 FUN_005b49a0

bool FUN_005b49a0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0056a320(1 - (*(byte *)(param_1 + 2) & 1),1,0,1);
  return 0 < iVar1;
}


//// FUNC 005b49d0 FUN_005b49d0

undefined4 FUN_005b49d0(int param_1)

{
  short sVar1;
  int iVar2;
  
  iVar2 = FUN_00569720(*(byte *)(param_1 + 2) & 1,0x488);
  if (-1 < iVar2) {
    return 1;
  }
  iVar2 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  if (iVar2 == 0) {
    iVar2 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
    if (iVar2 != 0) {
      iVar2 = FUN_0056a320(1 - (*(byte *)(param_1 + 2) & 1),0,0,1);
      if (0 < iVar2) {
        return 1;
      }
    }
  }
  iVar2 = FUN_00569720(*(byte *)(param_1 + 2) & 1,0x447);
  if (-1 < iVar2) {
    sVar1 = FUN_0056b250(*(byte *)(param_1 + 2) & 1,iVar2);
    if (sVar1 == -1) {
      return 1;
    }
    sVar1 = FUN_004022e0(*(ushort *)
                          (&DAT_00a55d74 +
                          (uint)(byte)((ushort)sVar1 >> 8) * 0x24 + ((byte)sVar1 & 1) * 0x351) &
                         0xfff);
    if ((sVar1 == 0x2f) || (sVar1 == 0x23d)) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b4ae0 FUN_005b4ae0

bool FUN_005b4ae0(int param_1)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_0056a320(1 - (*(byte *)(param_1 + 2) & 1),0,0,1);
  iVar2 = FUN_0056a320(*(byte *)(param_1 + 2) & 1,0,0,1);
  return iVar2 < iVar1;
}


//// FUNC 005b4b30 FUN_005b4b30

bool FUN_005b4b30(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0059dd20(param_1,*(byte *)(param_1 + 2) & 1);
  return 1 < iVar1;
}


//// FUNC 005b4b50 FUN_005b4b50

bool FUN_005b4b50(int param_1)

{
  return 4 < *(byte *)(&DAT_00a55d6a + (-(*(byte *)(param_1 + 2) & 1) - 1 & 1) * 0x6a2);
}


//// FUNC 005b4b90 FUN_005b4b90

undefined4 FUN_005b4b90(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  undefined1 auStack_10 [4];
  undefined1 auStack_c [4];
  int iStack_8;
  int iStack_4;
  
  iVar3 = param_1;
  FUN_005aff10(*(byte *)(param_1 + 2) & 1,&param_1,auStack_10,1);
  uVar5 = *(byte *)(iVar3 + 2) & 1;
  iVar6 = 0;
  iVar4 = (-uVar5 - 1 & 1) * 0xd44;
  iVar7 = 0;
  do {
    if ((*(uint *)((int)&DAT_00a55d74 + iVar4 + iVar7) & 0xfff) != 0) {
      iVar4 = (-uVar5 - 1 & 1) * 0xd44;
      if (((&DAT_00a55d7a)[iVar7 + iVar4] & 2) != 0) {
        FUN_0056dd30(-uVar5 + 1,iVar6,auStack_c);
        uVar5 = *(byte *)(iVar3 + 2) & 1;
        iVar4 = (-uVar5 - 1 & 1) * 0xd44;
        iVar1 = iStack_4;
        iVar2 = iStack_8;
        if (((&DAT_00a55d7a)[iVar7 + iVar4] & 1) != 0) {
          iVar1 = iStack_8;
          iVar2 = iStack_4;
        }
        if ((param_1 < iVar2) && (iVar1 < param_1)) {
          return 1;
        }
      }
    }
    iVar7 = iVar7 + 0x90;
    iVar6 = iVar6 + 1;
    if (0x240 < iVar7) {
      return 0;
    }
  } while( true );
}


//// FUNC 005b4c90 FUN_005b4c90

undefined4 FUN_005b4c90(int param_1,undefined4 param_2)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  
  iVar1 = FUN_005b4890(param_1,param_2);
  if (iVar1 != 0) {
    iVar1 = 0;
    uVar2 = *(byte *)(param_1 + 2) & 1;
    if (*(char *)(&DAT_00a55d68 + uVar2 * 0x6a2) != '\0') {
      do {
        iVar3 = FUN_005675f0(*(ushort *)(&DAT_00a56434 + iVar1 + uVar2 * 0x351) & 0xfff);
        if (iVar3 != 0) {
          return 1;
        }
        iVar1 = iVar1 + 1;
        uVar2 = *(byte *)(param_1 + 2) & 1;
      } while (iVar1 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar2 * 0x6a2));
    }
  }
  return 0;
}


//// FUNC 005b4d40 FUN_005b4d40

undefined4 FUN_005b4d40(int param_1)

{
  byte bVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  
  iVar2 = FUN_005709d0(1 - (*(byte *)(param_1 + 2) & 1),0x3ca);
  if (iVar2 == 0) {
    bVar1 = *(byte *)(param_1 + 2) & 1;
    iVar2 = FUN_005affd0(bVar1,bVar1,0xffffffff,1,0);
    iVar5 = 0;
    iVar6 = 0;
    do {
      iVar4 = -(*(byte *)(param_1 + 2) & 1);
      iVar3 = iVar6 + (iVar4 - 1U & 1) * 0xd44;
      if (((*(uint *)((int)&DAT_00a55d74 + iVar3) & 0xfff) != 0) &&
         (((&DAT_00a55d7a)[iVar3] & 1) == 0)) {
        iVar3 = FUN_0056f690(iVar4 + 1,iVar5);
        if (iVar3 < iVar2) {
          return 1;
        }
      }
      iVar6 = iVar6 + 0x90;
      iVar5 = iVar5 + 1;
    } while (iVar6 < 0x2d0);
  }
  return 0;
}


//// FUNC 005b4df0 FUN_005b4df0

undefined4 FUN_005b4df0(int param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = FUN_005b4890(param_1,param_2);
  if (iVar1 != 0) {
    iVar1 = FUN_00569d90(1 - (*(byte *)(param_1 + 2) & 1),0,1);
    if (0 < iVar1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b4e30 FUN_005b4e30

bool FUN_005b4e30(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0056a000(1 - (*(byte *)(param_1 + 2) & 1));
  return 1 < iVar1;
}


//// FUNC 005b4e60 FUN_005b4e60

bool FUN_005b4e60(int param_1)

{
  uint uVar1;
  
  uVar1 = *(byte *)(param_1 + 2) & 1;
  if ((ushort)(&DAT_00a55d64)[(-uVar1 - 1 & 1) * 0x6a2] < 0x1f5) {
    return true;
  }
  return 0x5dc < (ushort)(&DAT_00a55d64)[uVar1 * 0x6a2];
}


//// FUNC 005b4ec0 FUN_005b4ec0

undefined4 FUN_005b4ec0(int param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = FUN_005b4890(param_1,param_2);
  if ((iVar1 != 0) && (5 < *(byte *)(&DAT_00a55d68 + (*(byte *)(param_1 + 2) & 1) * 0x6a2))) {
    return 1;
  }
  return 0;
}


//// FUNC 005b4f10 FUN_005b4f10

bool FUN_005b4f10(int param_1)

{
  uint uVar1;
  int iVar2;
  int iVar3;
  
  iVar2 = func_0x00569c50(*(byte *)(param_1 + 2) & 1,0x4ce);
  iVar3 = func_0x00569c50(*(byte *)(param_1 + 2) & 1,0x15b);
  uVar1 = (uint)(((byte)*(ushort *)(param_1 + 2) & 0x3e) < 0x15);
  if (iVar2 + iVar3 != uVar1 && -1 < (int)((iVar2 + iVar3) - uVar1)) {
    return false;
  }
  iVar2 = FUN_005afe90(*(ushort *)(param_1 + 2) & 1);
  return iVar2 < 0;
}


//// FUNC 005b4f70 FUN_005b4f70

undefined4 FUN_005b4f70(int param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = FUN_005b4890(param_1,param_2);
  if (iVar1 != 0) {
    iVar1 = FUN_00569bf0(1 - (*(byte *)(param_1 + 2) & 1),10);
    if (0 < iVar1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b4fb0 FUN_005b4fb0

bool FUN_005b4fb0(undefined2 *param_1)

{
  undefined4 uVar1;
  int iVar2;
  
  uVar1 = FUN_004022e0(*param_1,0);
  iVar2 = FUN_00599e30(*(byte *)(param_1 + 1) & 1,uVar1);
  return 0 < iVar2;
}


//// FUNC 005b4fe0 FUN_005b4fe0

uint FUN_005b4fe0(int param_1)

{
  return *(uint *)(&DAT_00a56430 + (*(byte *)(param_1 + 2) & 1) * 0xd44) >> 0x18 & 1;
}


//// FUNC 005b5010 FUN_005b5010

bool FUN_005b5010(int param_1)

{
  return (*(uint *)(&DAT_00a56314 + (*(byte *)(param_1 + 2) & 1) * 0x6a2) & 0xfff) == 0;
}


//// FUNC 005b5040 FUN_005b5040

undefined4 FUN_005b5040(int param_1,undefined4 param_2)

{
  undefined4 uVar1;
  
  if ((*(byte *)(param_1 + 3) & 0x30) == 0) {
    uVar1 = FUN_005b5010(param_1,param_2);
    return uVar1;
  }
  return 1;
}


//// FUNC 005b5060 FUN_005b5060

bool FUN_005b5060(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005b3d30(*(byte *)(param_1 + 2) & 1);
  if (iVar1 != 0) {
    return true;
  }
  iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  return iVar1 < 0;
}


//// FUNC 005b50a0 FUN_005b50a0

bool FUN_005b50a0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005b3d30(*(byte *)(param_1 + 2) & 1);
  if (iVar1 != 0) {
    return true;
  }
  iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  if (iVar1 < 0) {
    return true;
  }
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  return 2 < iVar1;
}


//// FUNC 005b5100 FUN_005b5100

bool FUN_005b5100(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  return iVar1 < 0;
}


//// FUNC 005b5120 FUN_005b5120

undefined4 FUN_005b5120(int param_1)

{
  ushort uVar1;
  ushort uVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  
  iVar3 = FUN_0056a200(1 - (*(byte *)(param_1 + 2) & 1),0xffffffff);
  if (0 < iVar3) {
    uVar4 = *(byte *)(param_1 + 2) & 1;
    if (((*(uint *)(&DAT_00a56430 + uVar4 * 0xd44) & 0x20000) == 0) &&
       (iVar3 = 0, *(char *)(&DAT_00a55d68 + uVar4 * 0x6a2) != '\0')) {
      do {
        uVar2 = *(ushort *)(&DAT_00a56434 + iVar3 + uVar4 * 0x351) & 0xfff;
        iVar5 = FUN_00402690(uVar2);
        if ((iVar5 != 0) &&
           ((iVar5 = FUN_00567a00(uVar2), iVar5 == 0 && (uVar1 = FUN_004026c0(uVar2), 4 < uVar1))))
        {
          uVar2 = FUN_004026c0(uVar2);
          if (uVar2 < 7) {
            return 1;
          }
          iVar5 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
          if (iVar5 != 0) {
            return 1;
          }
        }
        iVar3 = iVar3 + 1;
        uVar4 = *(byte *)(param_1 + 2) & 1;
      } while (iVar3 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar4 * 0x6a2));
    }
  }
  return 0;
}


//// FUNC 005b5230 FUN_005b5230

bool FUN_005b5230(int param_1)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  iVar2 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
  return iVar1 < iVar2;
}


//// FUNC 005b5270 FUN_005b5270

bool FUN_005b5270(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
  return 1 < iVar1;
}


//// FUNC 005b5290 FUN_005b5290

undefined4 FUN_005b5290(int param_1)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  
  iVar4 = 0;
  iVar3 = 0;
  do {
    iVar2 = -(*(byte *)(param_1 + 2) & 1);
    iVar1 = iVar3 + (iVar2 - 1U & 1) * 0xd44;
    if (((*(uint *)((int)&DAT_00a55d74 + iVar1) & 0xfff) != 0) &&
       (((&DAT_00a55d7a)[iVar1] & 2) != 0)) {
      iVar1 = FUN_0056f690(iVar2 + 1,iVar4);
      if (0x707 < iVar1) {
        return 1;
      }
    }
    iVar3 = iVar3 + 0x90;
    iVar4 = iVar4 + 1;
  } while (iVar3 < 0x2d0);
  return 0;
}


//// FUNC 005b5300 FUN_005b5300

undefined4 FUN_005b5300(undefined2 *param_1)

{
  undefined2 *puVar1;
  ushort uVar2;
  short sVar3;
  int iVar4;
  uint *puVar5;
  uint uVar6;
  uint uVar7;
  undefined2 *puVar8;
  undefined2 *puStack_4;
  
  puVar1 = param_1;
  iVar4 = FUN_005af5a0(*(byte *)(param_1 + 1) & 1,*param_1,0);
  if (iVar4 < 0) {
    return 0;
  }
  puVar5 = (uint *)FUN_0040cab0();
  uVar7 = *puVar5 & 0xfff;
  FUN_005aff10(1 - (*(byte *)(puVar1 + 1) & 1),&param_1,&puStack_4,1);
  uVar2 = FUN_004027b0(uVar7);
  if (0x6a4 < uVar2) {
    puVar8 = puStack_4;
    if ((int)puStack_4 < (int)param_1) {
      puVar8 = param_1;
    }
    uVar6 = FUN_004027b0(uVar7);
    if ((int)puVar8 < (int)(uVar6 & 0xffff)) goto LAB_005b53a3;
  }
  sVar3 = FUN_00402740(uVar7);
  if (sVar3 != 1) {
    return 0;
  }
  iVar4 = FUN_00567620(uVar7,0xffffffff);
  if (iVar4 != 0) {
    return 0;
  }
LAB_005b53a3:
  if (((*(byte *)(puVar1 + 1) & 1) != (*puVar5 >> 0xc & 1)) &&
     (iVar4 = func_0x005ae8f0(uVar7), iVar4 != 0)) {
    return 0;
  }
  return 1;
}


//// FUNC 005b53e0 FUN_005b53e0

undefined4 FUN_005b53e0(undefined2 *param_1)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint *puVar4;
  uint uVar5;
  uint uVar6;
  undefined2 *puVar7;
  undefined2 *puStack_4;
  
  puVar7 = param_1;
  iVar3 = FUN_005af5a0(*(byte *)(param_1 + 1) & 1,*param_1,0);
  if (-1 < iVar3) {
    puVar4 = (uint *)FUN_0040cab0();
    uVar6 = *puVar4 & 0xfff;
    FUN_005aff10(1 - (*(byte *)(puVar7 + 1) & 1),&param_1,&puStack_4,1);
    uVar1 = FUN_004027b0(uVar6);
    if (0x6a4 < uVar1) {
      puVar7 = puStack_4;
      if ((int)puStack_4 < (int)param_1) {
        puVar7 = param_1;
      }
      uVar5 = FUN_004027b0(uVar6);
      if ((int)puVar7 < (int)(uVar5 & 0xffff)) {
        return 1;
      }
    }
    sVar2 = FUN_00402740(uVar6);
    if ((sVar2 == 1) && (iVar3 = FUN_00567620(uVar6,0xffffffff), iVar3 == 0)) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5490 FUN_005b5490

undefined4 FUN_005b5490(undefined2 *param_1)

{
  ushort uVar1;
  ushort uVar2;
  short sVar3;
  int iVar4;
  uint *puVar5;
  uint uVar6;
  undefined2 *puVar7;
  undefined2 *puVar8;
  uint uVar9;
  undefined2 *puStack_4;
  
  puVar7 = param_1;
  puVar8 = (undefined2 *)0x0;
  iVar4 = FUN_005af5a0(1 - (*(byte *)(param_1 + 1) & 1),*param_1,0);
  if (-1 < iVar4) {
    puVar5 = (uint *)FUN_0040cab0();
    uVar9 = *puVar5 & 0xfff;
    uVar1 = FUN_00402800(uVar9);
    uVar2 = FUN_004027b0(uVar9);
    if (uVar1 < uVar2) {
      uVar9 = FUN_004027b0();
    }
    else {
      uVar9 = FUN_00402800(uVar9);
    }
    puVar8 = (undefined2 *)(uVar9 & 0xffff);
  }
  iVar4 = FUN_005af5a0(*(byte *)(puVar7 + 1) & 1,*puVar7,0);
  if (-1 < iVar4) {
    puVar5 = (uint *)FUN_0040cab0();
    uVar9 = *puVar5 & 0xfff;
    FUN_005aff10(1 - (*(byte *)(puVar7 + 1) & 1),&param_1,&puStack_4,1);
    puVar7 = param_1;
    if ((int)param_1 <= (int)puStack_4) {
      puVar7 = puStack_4;
    }
    if (((int)puVar8 <= (int)puVar7) && (puVar8 = param_1, (int)param_1 <= (int)puStack_4)) {
      puVar8 = puStack_4;
    }
    uVar1 = FUN_004027b0(uVar9);
    if ((0x6a4 < uVar1) && (uVar6 = FUN_00402800(uVar9), (int)puVar8 <= (int)(uVar6 & 0xffff))) {
      return 1;
    }
    sVar3 = FUN_00402740(uVar9);
    if (sVar3 == 1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b55a0 FUN_005b55a0

undefined4 FUN_005b55a0(undefined2 *param_1)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint *puVar4;
  uint uVar5;
  uint uVar6;
  undefined2 *puVar7;
  undefined2 *puStack_4;
  
  puVar7 = param_1;
  iVar3 = FUN_005af5a0(*(byte *)(param_1 + 1) & 1,*param_1,0);
  if (-1 < iVar3) {
    puVar4 = (uint *)FUN_0040cab0();
    uVar6 = *puVar4 & 0xfff;
    FUN_005aff10(1 - (*(byte *)(puVar7 + 1) & 1),&param_1,&puStack_4,1);
    uVar1 = FUN_004027b0(uVar6);
    if (0x6a4 < uVar1) {
      puVar7 = puStack_4;
      if ((int)puStack_4 < (int)param_1) {
        puVar7 = param_1;
      }
      uVar5 = FUN_004027b0(uVar6);
      if ((int)puVar7 <= (int)(uVar5 & 0xffff)) {
        return 1;
      }
    }
    sVar2 = FUN_00402740(uVar6);
    if ((sVar2 == 1) && (iVar3 = FUN_00567620(uVar6,0xffffffff), iVar3 == 0)) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5650 FUN_005b5650

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b5650(undefined4 *param_1)

{
  byte bVar1;
  undefined2 uVar2;
  short sVar3;
  undefined4 uVar4;
  int iVar5;
  undefined4 *puVar6;
  short *psVar7;
  undefined4 *puVar8;
  undefined4 auStack_14 [5];
  
  bVar1 = *(byte *)((int)param_1 + 2);
  puVar6 = param_1;
  puVar8 = auStack_14;
  for (iVar5 = 5; iVar5 != 0; iVar5 = iVar5 + -1) {
    *puVar8 = *puVar6;
    puVar6 = puVar6 + 1;
    puVar8 = puVar8 + 1;
  }
  if ((2000 < (ushort)(&DAT_00a55d64)[(bVar1 & 1) * 0x6a2]) && (_DAT_005dd4c0 != 0x443)) {
    psVar7 = (short *)&DAT_005dd4c0;
    do {
      uVar2 = FUN_00402460(*psVar7);
      auStack_14[0] = CONCAT22(auStack_14[0]._2_2_,uVar2);
      sVar3 = FUN_004025d0(auStack_14[0]);
      if (sVar3 == 0x16) {
        uVar4 = FUN_004022e0(auStack_14[0]);
        iVar5 = FUN_0056cbd0(1 - (*(byte *)((int)param_1 + 2) & 1),uVar4);
        if (iVar5 != 0) {
          iVar5 = (**(code **)(psVar7 + 2))(auStack_14,0);
          if (iVar5 != 0) {
            _DAT_00a579a4 = (undefined2)auStack_14[0];
            return 1;
          }
        }
      }
      psVar7 = psVar7 + 4;
    } while (*psVar7 != 0x443);
  }
  return 0;
}


//// FUNC 005b5720 FUN_005b5720

undefined4 FUN_005b5720(int param_1)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  undefined1 auStack_c [4];
  int iStack_8;
  int iStack_4;
  
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  if (0 < iVar1) {
    iVar1 = 0;
    iVar5 = 0;
    iVar6 = 0;
    do {
      uVar2 = *(byte *)(param_1 + 2) & 1;
      iVar3 = iVar6 + uVar2 * 0xd44;
      if (((*(uint *)((int)&DAT_00a55d74 + iVar3) & 0xfff) != 0) &&
         (((&DAT_00a55d7a)[iVar3] & 1) == 0)) {
        iVar3 = FUN_0056f690(uVar2,iVar5);
        if (iVar1 <= iVar3) {
          iVar1 = FUN_0056f690(*(byte *)(param_1 + 2) & 1,iVar5);
        }
      }
      iVar6 = iVar6 + 0x90;
      iVar5 = iVar5 + 1;
    } while (iVar6 < 0x2d0);
    iVar5 = 0;
    iVar6 = 0;
    do {
      iVar4 = -(*(byte *)(param_1 + 2) & 1);
      iVar3 = iVar6 + (iVar4 - 1U & 1) * 0xd44;
      if (((*(uint *)((int)&DAT_00a55d74 + iVar3) & 0xfff) != 0) &&
         (((&DAT_00a55d7a)[iVar3] & 1) == 0)) {
        FUN_0056dd30(iVar4 + 1,iVar5,auStack_c);
        if ((iVar1 <= iStack_8) && (iStack_4 < iVar1)) {
          return 1;
        }
      }
      iVar6 = iVar6 + 0x90;
      iVar5 = iVar5 + 1;
    } while (iVar6 < 0x2d0);
  }
  return 0;
}


//// FUNC 005b5830 FUN_005b5830

bool FUN_005b5830(int param_1)

{
  int iVar1;
  int iStack_c;
  int iStack_8;
  int iStack_4;
  
  iVar1 = param_1;
  FUN_005aff10(1 - (*(byte *)(param_1 + 2) & 1),&param_1,&iStack_c,1);
  FUN_005aff10(*(byte *)(iVar1 + 2) & 1,&iStack_8,&iStack_4,1);
  iVar1 = param_1;
  if (param_1 <= iStack_c) {
    iVar1 = iStack_c;
  }
  if (iVar1 < iStack_8) {
    return false;
  }
  if (param_1 <= iStack_c) {
    param_1 = iStack_c;
  }
  return param_1 < iStack_4;
}


//// FUNC 005b58b0 FUN_005b58b0

bool FUN_005b58b0(int param_1)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = *(byte *)(param_1 + 2) & 1;
  if (*(byte *)(&DAT_00a55d68 + (-uVar2 - 1 & 1) * 0x6a2) < 2) {
    return false;
  }
  iVar1 = FUN_005b0420(1 - uVar2);
  if (-1 < iVar1) {
    return true;
  }
  iVar1 = FUN_005699a0(*(byte *)(param_1 + 2) & 1,0x40e);
  return iVar1 != 0;
}


//// FUNC 005b5920 FUN_005b5920

bool FUN_005b5920(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005b0420(1 - (*(byte *)(param_1 + 2) & 1));
  return -1 < iVar1;
}


//// FUNC 005b5950 FUN_005b5950

undefined4 FUN_005b5950(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  
  uVar3 = *(byte *)(param_1 + 2) & 1;
  if ((ushort)(&DAT_00a55d64)[(-uVar3 - 1 & 1) * 0x6a2] <= (ushort)(&DAT_00a55d64)[uVar3 * 0x6a2]) {
    return 0;
  }
  iVar1 = FUN_005b0150(param_1,uVar3,0xffffffff,0);
  iVar2 = FUN_0056d660(*(byte *)(param_1 + 2) & 1,iVar1,0x290);
  if (iVar2 != 0) {
    iVar1 = FUN_005b0150(param_1,*(byte *)(param_1 + 2) & 1,iVar1,0);
  }
  if (-1 < iVar1) {
    iVar1 = FUN_0056f690(*(byte *)(param_1 + 2) & 1,iVar1);
    if (0x5db < iVar1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5a00 FUN_005b5a00

bool FUN_005b5a00(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005699a0(*(byte *)(param_1 + 2) & 1,0x51);
  return 0 < iVar1;
}


//// FUNC 005b5a20 FUN_005b5a20

undefined4 FUN_005b5a20(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005b0150(param_1,*(byte *)(param_1 + 2) & 1,0xffffffff,0);
  if (-1 < iVar1) {
    iVar1 = FUN_0056f690(*(byte *)(param_1 + 2) & 1,iVar1);
    if (0x513 < iVar1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5a60 FUN_005b5a60

undefined4 FUN_005b5a60(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005b0150(param_1,1 - (*(byte *)(param_1 + 2) & 1),0xffffffff,0);
  if (-1 < iVar1) {
    iVar1 = FUN_0056f690(1 - (*(byte *)(param_1 + 2) & 1),iVar1);
    if (0x513 < iVar1) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5ab0 FUN_005b5ab0

undefined4 FUN_005b5ab0(undefined4 param_1,undefined4 param_2)

{
  int iVar1;
  
  iVar1 = FUN_005b4890(param_1,param_2);
  if (iVar1 != 0) {
    iVar1 = FUN_005b5a20(param_1,param_2);
    if (iVar1 != 0) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5af0 FUN_005b5af0

bool FUN_005b5af0(int param_1)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = *(byte *)(param_1 + 2) & 1;
  iVar1 = FUN_00569d50(*(byte *)(param_1 + 2) & 1);
  if ((int)(uint)(ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] <= iVar1 * 500) {
    return true;
  }
  iVar1 = FUN_005ae9c0(uVar2,0xffffffff,0);
  return -1 < iVar1;
}


//// FUNC 005b5b60 FUN_005b5b60

bool FUN_005b5b60(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
  return iVar1 < 1;
}


//// FUNC 005b5b80 FUN_005b5b80

bool FUN_005b5b80(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_0059dd20(param_1,*(byte *)(param_1 + 2) & 1);
  return iVar1 == 0;
}


//// FUNC 005b5ba0 FUN_005b5ba0

bool FUN_005b5ba0(int param_1)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = *(byte *)(param_1 + 2) & 1;
  if ((ushort)(&DAT_00a55d64)[(-uVar2 - 1 & 1) * 0x6a2] < 0x4b1) {
    return true;
  }
  iVar1 = FUN_00569d50(uVar2);
  return 2 < iVar1;
}


//// FUNC 005b5bf0 FUN_005b5bf0

undefined4 FUN_005b5bf0(ushort *param_1)

{
  uint uVar1;
  int iVar2;
  uint *puVar3;
  undefined2 extraout_var;
  
  iVar2 = FUN_00569d50((byte)param_1[1] & 1);
  if (1 < iVar2) {
    iVar2 = FUN_005af5a0((byte)param_1[1] & 1,CONCAT22(extraout_var,*param_1),0);
    if (-1 < iVar2) {
      puVar3 = (uint *)FUN_0040cab0();
      uVar1 = *puVar3;
      iVar2 = FUN_00567990(uVar1 & 0xfff);
      if ((iVar2 != 0) && ((uVar1 & 0xfff) != (uint)*param_1)) {
        return 1;
      }
      return 0;
    }
  }
  return 0;
}


//// FUNC 005b5c60 FUN_005b5c60

undefined4 FUN_005b5c60(int param_1)

{
  int iVar1;
  int iVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  undefined1 auStack_c [4];
  int iStack_8;
  int iStack_4;
  
  iVar1 = FUN_005a0dd0(*(byte *)(param_1 + 2) & 1);
  if (iVar1 != 0) {
    iVar1 = FUN_0056b730(*(ushort *)(param_1 + 2) & 1,*(ushort *)(param_1 + 2) >> 1 & 0x1f,1);
    if (iVar1 != 0) {
      uVar3 = *(byte *)(param_1 + 2) & 1;
      iVar5 = 0;
      iVar1 = (-uVar3 - 1 & 1) * 0xd44;
      iVar4 = 0;
      do {
        if ((*(uint *)((int)&DAT_00a55d74 + iVar1 + iVar4) & 0xfff) != 0) {
          FUN_0056dd30(1 - uVar3,iVar5,auStack_c);
          uVar3 = *(byte *)(param_1 + 2) & 1;
          iVar1 = (-uVar3 - 1 & 1) * 0xd44;
          iVar2 = iStack_4;
          if (((&DAT_00a55d7a)[iVar4 + iVar1] & 1) == 0) {
            iVar2 = iStack_8;
          }
          if ((999 < iVar2) && (iVar2 < 2000)) {
            return 1;
          }
        }
        iVar4 = iVar4 + 0x90;
        iVar5 = iVar5 + 1;
      } while (iVar4 < 0x241);
    }
  }
  return 0;
}


//// FUNC 005b5d60 FUN_005b5d60

undefined4 FUN_005b5d60(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005a0dd0(*(byte *)(param_1 + 2) & 1);
  if (iVar1 != 0) {
    iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
    if (iVar1 == 0) {
      return 1;
    }
  }
  return 0;
}


//// FUNC 005b5da0 FUN_005b5da0

undefined4 FUN_005b5da0(int param_1)

{
  int iVar1;
  
  iVar1 = FUN_005a0dd0(*(byte *)(param_1 + 2) & 1);
  if (iVar1 == 0) {
    return 0;
  }
  iVar1 = FUN_00569d50(1 - (*(byte *)(param_1 + 2) & 1));
  if (iVar1 != 0) {
    iVar1 = FUN_005afe90(*(byte *)(param_1 + 2) & 1);
    if (-1 < iVar1) {
      return 0;
    }
  }
  return 1;
}


//// FUNC 005b6e10 FUN_005b6e10

undefined4 FUN_005b6e10(void)

{
  undefined4 in_EAX;
  
  FUN_005b9170(CONCAT22((short)((uint)in_EAX >> 0x10),DAT_00a577f8._2_2_ << 0xf) | 0x52,0,0,0);
  return 1;
}


//// FUNC 005b62f0 FUN_005b62f0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b62f0(void)

{
  undefined2 uVar1;
  ushort uVar2;
  uint uVar3;
  uint uVar4;
  int iVar5;
  undefined *puVar6;
  uint uVar7;
  uint *puStack_8;
  int iStack_4;
  
  uVar7 = (uint)DAT_00a577f8._2_1_;
  uVar4 = uVar7 & 1;
  if (DAT_00a579a2 == '\0') {
    puVar6 = &DAT_005dd3c8;
    do {
      iVar5 = FUN_005b5e00(uVar4,puVar6);
      if (iVar5 != 0) {
        return 0;
      }
      puVar6 = puVar6 + 8;
    } while ((int)puVar6 < 0x5dd4c0);
    _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
  }
  else if (DAT_00a579a2 != '\x01') {
    if (DAT_00a579a2 != '\x02') {
      return 1;
    }
    goto LAB_005b6452;
  }
  uVar1 = FUN_00402460(0x1a8);
  iVar5 = FUN_00570a10(uVar4,uVar1);
  if (((iVar5 != 0) && (iVar5 = FUN_0056d2c0(uVar4,0x1a8), iVar5 != 0)) &&
     (iVar5 = FUN_00599e30(uVar4,0x1a8,0), 0 < iVar5)) {
    iVar5 = FUN_0056d340(uVar4,0x1a8);
    DAT_00a55c94._1_1_ = DAT_00a55c94._1_1_ | 0x80;
    FUN_0059d040(uVar4);
    FUN_00575a10(uVar4,iVar5);
    uVar4 = FUN_00402460(0x1a8,((uint)(&DAT_00a56434)[iVar5 + uVar4 * 0x351] >> 0xc & 1) +
                               ((uint)(&DAT_00a56434)[iVar5 + uVar4 * 0x351] >> 0x18 & 0x7f) * 2);
    FUN_005ba860(uVar4 & 0xffff | uVar7 << 0x1f | 0x4e0000);
    _DAT_00a579a2 = _DAT_00a579a2 & 0xff00;
    return 0;
  }
  _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
LAB_005b6452:
  iStack_4 = 0;
  if (*(char *)(&DAT_00a55d68 + uVar4 * 0x6a2) != '\0') {
    puStack_8 = &DAT_00a56434 + uVar4 * 0x351;
    do {
      uVar7 = *puStack_8 & 0xfff;
      uVar2 = FUN_004022e0(uVar7);
      if (uVar2 < 0x547) {
        if ((uVar2 == 0x546) || ((uVar2 == 0x17a || (uVar2 == 0x34d)))) {
LAB_005b64f2:
          uVar3 = FUN_005aae00(uVar4,uVar7);
          if (uVar3 != 0) {
            if ((uVar3 & 0x400) == 0) {
              iVar5 = 1;
            }
            else if ((uVar3 & 0x800) == 0) {
              iVar5 = 0;
            }
            else {
              iVar5 = FUN_005ae270(uVar4,uVar7,1,0);
            }
            _DAT_00a57808 = _DAT_00a57808 & 0xff;
            _DAT_00a5780e =
                 _DAT_00a5780e ^
                 (byte)(((byte)((uint)(&DAT_00a56434)[iStack_4 + uVar4 * 0x351] >> 0xc) & 1) +
                        (char)((uint)(&DAT_00a56434)[iStack_4 + uVar4 * 0x351] >> 0x18) * '\x02' ^
                       DAT_00a5780e);
            _DAT_00a5780c = _DAT_00a5780c ^ (byte)(DAT_00a5780c ^ (byte)iStack_4);
            DAT_00a57804 = CONCAT22(DAT_00a57804._2_2_,
                                    ((iVar5 != 0) + 10) * 8 | (ushort)DAT_00a57804 & 0xff87) | 6;
            _DAT_00a5780a = CONCAT11((char)uVar4,DAT_00a5780a) | 0x1600;
            DAT_00a57800._2_2_ = (short)uVar7;
            return 0;
          }
        }
      }
      else if ((0x5e9 < uVar2) &&
              ((uVar2 < 0x5f0 || ((uVar2 == 0x5f0 && (iVar5 = FUN_0056cdc0(1 - uVar4), iVar5 == 0)))
               ))) goto LAB_005b64f2;
      puStack_8 = puStack_8 + 1;
      iStack_4 = iStack_4 + 1;
    } while (iStack_4 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar4 * 0x6a2));
  }
  _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
  return 1;
}


//// FUNC 005b76c0 FUN_005b76c0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b76c0(void)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  ushort uVar4;
  byte bVar5;
  
  if (DAT_00a579a2 == '\0') {
    iVar3 = FUN_005b6690(DAT_00a577f8._2_1_ & 1);
    if (iVar3 == 0) {
      bVar5 = DAT_00a579a2;
      _DAT_00a579a0 = _DAT_00a579a0 & 0xffff00ff;
      _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar5 + 1 ^ bVar5);
    }
  }
  else {
    if (DAT_00a579a2 == '\x01') {
      bVar5 = 1;
      if ((_DAT_00a579a0 & 0xff00) < 0x401) {
        do {
          iVar3 = FUN_005b77f0(DAT_00a577f8._2_1_ & 1,(_DAT_00a579a0 & 0xffff) >> 8,0);
          uVar1 = _DAT_00a579a0;
          if (iVar3 != 0) {
            return 0;
          }
          uVar4 = ((ushort)_DAT_00a579a0 & 0xff00) + 0x100 ^ (ushort)DAT_00a579a0;
          _DAT_00a579a0 = CONCAT22(_DAT_00a579a2,uVar4);
          uVar2 = _DAT_00a579a0;
        } while ((uVar4 & 0xff00) < 0x401);
        DAT_00a579a2 = SUB41(uVar1,2);
        bVar5 = DAT_00a579a2;
        _DAT_00a579a0 = uVar2;
      }
      _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar5 + 1 ^ bVar5);
      return 0;
    }
    if (DAT_00a579a2 != '\x02') {
      return 1;
    }
    iVar3 = FUN_005b6690(DAT_00a577f8._2_1_ & 1);
    if (iVar3 == 0) {
      bVar5 = DAT_00a579a2 + 1 ^ DAT_00a579a2;
      _DAT_00a579a2 = _DAT_00a579a2 ^ bVar5;
      return 0;
    }
  }
  return 0;
}


//// FUNC 005b7a50 FUN_005b7a50

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b7a50(void)

{
  int iVar1;
  
  if (DAT_00a579a2 == '\0') {
    *(undefined2 *)(&DAT_00a55d70 + (DAT_00a577f8._2_1_ & 1) * 0xd44) = 0;
    iVar1 = FUN_005a0dd0(DAT_00a577f8._2_1_ & 1);
    if (iVar1 == 0) {
      return 1;
    }
    iVar1 = FUN_005b1310(DAT_00a577f8._2_1_ & 1);
    if (iVar1 == 0) {
      return 1;
    }
    iVar1 = FUN_005b6660(DAT_00a577f8._2_1_ & 1);
    if (iVar1 != 0) {
      return 0;
    }
    DAT_00a577f8._2_2_ = DAT_00a577f8._2_2_ & 0xff;
    _DAT_00a577fc = _DAT_00a577fc & 0xff00;
  }
  else {
    if (DAT_00a579a2 != '\x01') {
      if (DAT_00a579a2 != '\x02') {
        return 0;
      }
      FUN_005b9170(DAT_00a577f8._2_2_ << 0xf | 0x54,0,0,0);
      return 1;
    }
    iVar1 = FUN_005a4090(DAT_00a577f8._2_1_ & 1);
    if (iVar1 == 0) {
      return 0;
    }
  }
  _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
  return 0;
}


//// FUNC 005b75a0 FUN_005b75a0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b75a0(void)

{
  int iVar1;
  uint uVar2;
  undefined4 uVar3;
  
  if (DAT_00a579a2 != '\0') {
    return 1;
  }
  iVar1 = FUN_005ae390(ram0x00a577fa & 1);
  if (((iVar1 != 0) && ((*(uint *)(&DAT_00a56430 + (ram0x00a577fa & 1) * 0xd44) & 0x20000) == 0)) &&
     ((iVar1 = FUN_00570a70(ram0x00a577fa & 1), iVar1 != 0 ||
      (iVar1 = FUN_00570ac0(ram0x00a577fa & 1), iVar1 != 0)))) {
    iVar1 = FUN_005b16c0(ram0x00a577fa & 1);
    if (iVar1 < 0) {
      _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
      return 0;
    }
    uVar2 = ram0x00a577fa & 1;
    uVar3 = FUN_005ae270(uVar2,(&DAT_00a56434)[uVar2 + iVar1 + uVar2 * 0x350] & 0xfff,0,0);
    iVar1 = FUN_005b6ff0(ram0x00a577fa & 1,iVar1,uVar3);
    if (iVar1 == 0) {
      return 0;
    }
  }
  _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(DAT_00a579a2 + 1 ^ DAT_00a579a2);
  return 0;
}


//// FUNC 005b7960 FUN_005b7960

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b7960(void)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  byte bVar4;
  ushort uVar5;
  
  if (DAT_00a579a2 == '\0') {
    iVar3 = FUN_005b6690(DAT_00a577f8._2_1_ & 1);
    if (iVar3 == 0) {
      bVar4 = DAT_00a579a2;
      _DAT_00a579a0 = _DAT_00a579a0 & 0xffff00ff;
      _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar4 + 1 ^ bVar4);
    }
    return 0;
  }
  if (DAT_00a579a2 == '\x01') {
    bVar4 = 1;
    if ((_DAT_00a579a0 & 0xff00) < 0x401) {
      do {
        iVar3 = FUN_005b77f0(DAT_00a577f8._2_1_ & 1,(_DAT_00a579a0 & 0xffff) >> 8,1);
        uVar1 = _DAT_00a579a0;
        if (iVar3 != 0) {
          return 0;
        }
        uVar5 = ((ushort)_DAT_00a579a0 & 0xff00) + 0x100 ^ (ushort)DAT_00a579a0;
        _DAT_00a579a0 = CONCAT22(_DAT_00a579a2,uVar5);
        uVar2 = _DAT_00a579a0;
      } while ((uVar5 & 0xff00) < 0x401);
      DAT_00a579a2 = SUB41(uVar1,2);
      bVar4 = DAT_00a579a2;
      _DAT_00a579a0 = uVar2;
    }
    _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar4 + 1 ^ bVar4);
    return 0;
  }
  return 1;
}


//// FUNC 005b69d0 FUN_005b69d0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b69d0(void)

{
  ushort uVar1;
  short sVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  byte bVar6;
  uint uVar7;
  undefined *puVar8;
  uint uVar9;
  bool bVar10;
  uint *puStack_8;
  int iStack_4;
  
  uVar7 = DAT_00a577f8._2_1_ & 1;
  if (DAT_00a579a2 == '\0') {
    puVar8 = &DAT_005dd8d0;
    do {
      iVar3 = FUN_005b5e00(uVar7,puVar8);
      if (iVar3 != 0) {
        return 0;
      }
      puVar8 = puVar8 + 8;
    } while ((int)puVar8 < 0x5dd980);
    bVar6 = DAT_00a579a2 + 1 ^ DAT_00a579a2;
    _DAT_00a579a2 = _DAT_00a579a2 ^ bVar6;
    uVar9 = _DAT_00a579a0;
    bVar6 = DAT_00a579a2;
  }
  else {
    bVar6 = 1;
    uVar9 = _DAT_00a579a0;
    if (DAT_00a579a2 != '\x01') {
      if (DAT_00a579a2 == '\x02') {
        iStack_4 = 0;
        bVar6 = 2;
        if (*(char *)(&DAT_00a55d68 + uVar7 * 0x6a2) != '\0') {
          puStack_8 = &DAT_00a56434 + uVar7 * 0x351;
          do {
            uVar9 = *puStack_8 & 0xfff;
            uVar1 = FUN_004022e0(uVar9);
            if ((0x2d5 < uVar1) &&
               ((((uVar1 < 0x2d9 || (uVar1 == 0x2fe)) &&
                 (iVar3 = FUN_005aee70(uVar7,uVar9,1), iVar3 != 0)) &&
                (uVar4 = FUN_005aae00(uVar7,uVar9), uVar4 != 0)))) {
              if ((uVar4 & 0x400) == 0) {
                iVar3 = 1;
              }
              else if ((uVar4 & 0x800) == 0) {
                iVar3 = 0;
              }
              else {
                iVar3 = FUN_005ae270(uVar7,uVar9,1,0);
              }
              _DAT_00a57808 = _DAT_00a57808 & 0xff;
              DAT_00a57800._2_2_ = (short)uVar9;
              _DAT_00a5780e =
                   _DAT_00a5780e ^
                   (byte)(((byte)((uint)(&DAT_00a56434)[iStack_4 + uVar7 * 0x351] >> 0xc) & 1) +
                          (char)((uint)(&DAT_00a56434)[iStack_4 + uVar7 * 0x351] >> 0x18) * '\x02' ^
                         DAT_00a5780e);
              _DAT_00a5780a = CONCAT11((char)uVar7,DAT_00a5780a) | 0x1600;
              _DAT_00a5780c = _DAT_00a5780c ^ (byte)(DAT_00a5780c ^ (byte)iStack_4);
              DAT_00a57804 = CONCAT22(DAT_00a57804._2_2_,
                                      ((iVar3 != 0) + 10) * 8 | (ushort)DAT_00a57804 & 0xff87) | 6;
              return 0;
            }
            iStack_4 = iStack_4 + 1;
            puStack_8 = puStack_8 + 1;
          } while (iStack_4 < (int)(uint)*(byte *)(&DAT_00a55d68 + uVar7 * 0x6a2));
          bVar6 = DAT_00a579a2;
        }
        _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar6 + 1 ^ bVar6);
      }
      return 1;
    }
  }
  _DAT_00a579a0 = uVar9;
  bVar10 = DAT_00a579a1 < *(byte *)(&DAT_00a55d68 + uVar7 * 0x6a2);
  if (bVar10) {
    iVar3 = uVar7 * 0x351;
    do {
      uVar1 = *(ushort *)(&DAT_00a56434 + ((_DAT_00a579a0 & 0xffff) >> 8) + iVar3) & 0xfff;
      iVar5 = FUN_00570a10(uVar7,uVar1);
      if (((iVar5 != 0) && (iVar5 = FUN_005b0380(uVar7,uVar1), iVar5 != 0)) &&
         (iVar5 = FUN_005685c0(uVar1), iVar5 == 0)) {
        bVar10 = false;
        sVar2 = FUN_004025d0(uVar1);
        if ((sVar2 == 0x15) ||
           ((sVar2 == 0x16 &&
            ((sVar2 = FUN_00402700(uVar1), sVar2 == 5 || (iVar5 = FUN_005699c0(0x49c), iVar5 != 0)))
            ))) {
          bVar10 = true;
        }
        if (((uint)(&DAT_00a56434)[((_DAT_00a579a0 & 0xffff) >> 8) + iVar3] >> 0xc & 1) != uVar7) {
          bVar10 = false;
        }
        sVar2 = FUN_004022e0(uVar1);
        if ((sVar2 == 0x136) || ((sVar2 != 0x49b && (bVar10)))) {
          _DAT_00a57808 = _DAT_00a57808 & 0xff;
          DAT_00a57800._2_2_ = uVar1;
          _DAT_00a5780e =
               _DAT_00a5780e ^
               (byte)(((byte)((uint)(&DAT_00a56434)[((_DAT_00a579a0 & 0xffff) >> 8) + iVar3] >> 0xc)
                      & 1) + (char)((uint)(&DAT_00a56434)[((_DAT_00a579a0 & 0xffff) >> 8) + iVar3]
                                   >> 0x18) * '\x02' ^ DAT_00a5780e);
          _DAT_00a5780a = CONCAT11((char)uVar7,DAT_00a5780a) | 0x1600;
          _DAT_00a5780c = CONCAT11(DAT_00a5780d,DAT_00a579a1);
          DAT_00a57804 = DAT_00a57804 & 0xffffffa7 | 0x26;
          return 0;
        }
      }
      uVar9 = _DAT_00a579a0;
      uVar1 = ((ushort)_DAT_00a579a0 & 0xff00) + 0x100;
      _DAT_00a579a0 = CONCAT22(_DAT_00a579a2,uVar1 ^ DAT_00a579a0);
      uVar4 = _DAT_00a579a0;
      DAT_00a579a1 = (byte)(uVar1 >> 8);
      bVar10 = DAT_00a579a1 < *(byte *)(&DAT_00a55d68 + uVar7 * 0x6a2);
      _DAT_00a579a0 = uVar4;
    } while (bVar10);
    DAT_00a579a2 = SUB41(uVar9,2);
    bVar6 = DAT_00a579a2;
  }
  _DAT_00a579a2 = _DAT_00a579a2 ^ (byte)(bVar6 + 1 ^ bVar6);
  return 0;
}


//// FUNC 005b7b50 FUN_005b7b50

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b7b50(void)

{
  byte bVar1;
  int iVar2;
  
  if (((*(uint *)(&DAT_00a56430 + (DAT_00a577f8._2_1_ & 1) * 0xd44) & 0x800000) == 0) &&
     ((code *)(&PTR_FUN_005efb50)[_DAT_00a579a0 & 0xff] != (code *)0x0)) {
    iVar2 = (*(code *)(&PTR_FUN_005efb50)[_DAT_00a579a0 & 0xff])();
    if (iVar2 != 0) {
      _DAT_00a579a0 = _DAT_00a579a0 & 0xff0000ff;
      bVar1 = DAT_00a579a0 + 1 ^ DAT_00a579a0;
      _DAT_00a579a0 = _DAT_00a579a0 ^ bVar1;
    }
    return 0;
  }
  return 1;
}


//// FUNC 005b9f50 FUN_005b9f50

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b9f50(void)

{
  ushort uVar1;
  ushort uVar2;
  undefined2 extraout_var;
  
  uVar1 = DAT_00a577f8._2_2_;
  _DAT_00a577f4 = _DAT_00a577f4 & 0xffef;
  DAT_00a577f8._2_2_ = DAT_00a54e5c >> 3 & 1 | DAT_00a577f8._2_2_ & 0xfffe;
  uVar2 = DAT_00a577f8._2_2_;
  if ((_DAT_00a54e5c & 0x180) == 0x80) {
    _DAT_00a54e5c = _DAT_00a54e5c & 0xfffffdff;
    FUN_005bc580(0);
    return 1;
  }
  if ((((uVar1 & 0x10) == 0) || (((~DAT_00a54e5c ^ DAT_00a577f8._2_1_) & 1) != 0)) &&
     ((char)((uint)_DAT_00a577fe >> 8) == '\0')) {
    FUN_005b9170(0x14,0,0,0);
    FUN_005b9170(0x10,0,0,0);
    FUN_005b9170(CONCAT22(extraout_var,DAT_00a577f8._2_2_ << 0xf) | 0x61,0,5,0);
    FUN_005b9170(-(uint)((DAT_00a577f8._2_1_ & 1) != 1) & 0x8000 | 0x61,0,5,0);
    uVar1 = _DAT_00a577fe;
    _DAT_00a577fe =
         CONCAT22((undefined2)DAT_00a57800,(uVar1 & 0xff00) + 0x100 ^ (ushort)DAT_00a577fe);
    return 0;
  }
  DAT_00a577f8._2_2_ = uVar2;
  return 1;
}


//// FUNC 005a59b0 FUN_005a59b0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a59b0(void)

{
  byte bVar1;
  int iVar2;
  
  bVar1 = DAT_00a577f8._2_1_ & 1;
  if (_DAT_00a577fe >> 8 != 0) {
    if (_DAT_00a577fe >> 8 == 1) {
      iVar2 = FUN_005709d0(bVar1,0x517);
      if (iVar2 != 0) {
        FUN_00579930(bVar1,0x17,1);
      }
    }
    return 1;
  }
  FUN_005b9170(-(uint)((DAT_00a577f8._2_1_ & 1) != 0) & 0x8000 | 1,0,0,0);
  _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
  return 0;
}


//// FUNC 005a41c0 FUN_005a41c0

/* WARNING: Removing unreachable block (ram,0x005a42a9) */
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a41c0(void)

{
  int iVar1;
  uint uVar2;
  
  uVar2 = DAT_00a577f8._2_2_ & 1;
  switch(_DAT_00a577fe >> 8) {
  case 0:
    if (((*(uint *)(&DAT_00a56430 + uVar2 * 0xd44) & 2) != 0) ||
       ((*(uint *)(&DAT_00a56430 + uVar2 * 0xd44) & 0x800000) != 0)) {
      FUN_00579930(uVar2,1,0);
      return 1;
    }
    FUN_005b9170(-(uint)((DAT_00a577f8._2_2_ & 1) != 0) & 0x8000 | 0x50,0,0,0);
    break;
  case 1:
    iVar1 = FUN_005709f0(uVar2,0x520);
    if (((-1 < iVar1) &&
        (uVar2 == ((byte)(&DAT_00a563f1)[(iVar1 + uVar2 * 0x6a2) * 2] & 0x80000001))) &&
       ((byte)(&DAT_00a563f1)[(iVar1 + uVar2 * 0x6a2) * 2] / 2 <= (uint)(ushort)DAT_00a577f8)) {
      FUN_005797c0(0,0x520,0);
      FUN_005797c0(1,0x520,0);
      return 0;
    }
    break;
  case 2:
    FUN_00578b60(uVar2,1);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  case 3:
    FUN_00598590(uVar2,1,0);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  default:
    return 1;
  }
  _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
  return 0;
}


//// FUNC 005a8090 FUN_005a8090

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a8090(void)

{
  bool bVar1;
  ushort uVar2;
  short sVar3;
  undefined4 uVar4;
  uint uVar5;
  uint uVar6;
  int iVar7;
  sbyte sVar8;
  byte bVar9;
  uint uVar10;
  int iVar11;
  ushort uVar12;
  uint *puVar13;
  int iStack_184;
  undefined1 auStack_180 [128];
  undefined1 auStack_100 [256];
  
  bVar9 = DAT_00a577f8._2_1_ & 1;
  uVar10 = DAT_00a577f8._2_1_ & 1;
  if (((*(uint *)(&DAT_00a56430 + uVar10 * 0xd44) & 4) == 0) &&
     ((*(uint *)(&DAT_00a56430 + uVar10 * 0xd44) & 0x800000) == 0)) {
    bVar1 = false;
  }
  else {
    bVar1 = true;
  }
  sVar8 = (sbyte)uVar10;
  switch(_DAT_00a577fe >> 8) {
  case 0:
    if (!bVar1) {
      FUN_005b9170(-(uint)((DAT_00a577f8._2_1_ & 1) != 0) & 0x8000 | 0x51,0,0,0);
      DAT_00a57800 = DAT_00a57800 & 0xffff8000;
      _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
      return 0;
    }
    break;
  case 1:
    uVar5 = DAT_00a57800;
    bVar9 = (byte)DAT_00a57800;
    while( true ) {
      DAT_00a57800 = uVar5;
      if (0x1a < bVar9) {
        _DAT_00a577fe = CONCAT11(100,DAT_00a577fe);
        return 0;
      }
      iVar11 = (*(code *)(&PTR_LAB_005dd038)[DAT_00a57800 & 0xff])(uVar10);
      if (iVar11 == 0) break;
      DAT_00a57800 = DAT_00a57800 & 0xffff80ff;
      bVar9 = (byte)DAT_00a57800 + 1 ^ (byte)DAT_00a57800;
      DAT_00a57800._0_2_ = (ushort)DAT_00a57800 ^ bVar9;
      uVar5 = DAT_00a57800;
      bVar9 = (byte)DAT_00a57800;
    }
    return 0;
  default:
    return 1;
  case 100:
    DAT_00a57800 = DAT_00a57800 & 0xffff80ff;
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
  case 0x65:
    if ((DAT_00a57800 & 0x7f00) < 0xa00) {
      do {
        uVar5 = DAT_00a57800 >> 8 & 0x7f;
        if ((((&DAT_00a55d74)[uVar10 * 0x351 + uVar5 * 0x24] & 0xfff) != 0) &&
           (((&DAT_00a55d7a)[uVar5 * 0x90 + uVar10 * 0xd44] & 2) != 0)) {
          uVar12 = *(ushort *)(&DAT_00a55d74 + uVar10 * 0x351 + uVar5 * 0x24) & 0xfff;
          uVar2 = FUN_004022e0(uVar12);
          if (uVar2 < 0x483) {
            if (((uVar2 == 0x482) || (uVar2 == 1099)) || (uVar2 == 0x46b)) {
LAB_005a82d2:
              uVar4 = FUN_004022e0(uVar12);
              iVar11 = FUN_005a8040(uVar4);
              if (iVar11 < (int)(uint)(ushort)(&DAT_00a55d64)[uVar10 * 0x6a2]) {
                _DAT_00a577fe = CONCAT11(0x6e,DAT_00a577fe);
                return 0;
              }
            }
            else {
              if (uVar2 != 0x47a) goto LAB_005a8305;
LAB_005a82b8:
              iVar11 = FUN_0056a290(uVar10,CONCAT11((char)uVar5,sVar8));
              if (0 < iVar11) {
                _DAT_00a577fe = CONCAT11(0x78,DAT_00a577fe);
                return 0;
              }
            }
            FUN_00577840(uVar10,uVar5,0,uVar12);
          }
          else {
            if ((uVar2 == 0x58c) || (uVar2 == 0x590)) goto LAB_005a82d2;
            if (uVar2 == 0x597) goto LAB_005a82b8;
          }
        }
LAB_005a8305:
        uVar2 = (ushort)DAT_00a57800;
        DAT_00a57800._0_2_ = uVar2 ^ ((uVar2 & 0xff00) + 0x100 ^ uVar2) & 0x7f00;
      } while (((ushort)DAT_00a57800 & 0x7f00) < 0xa00);
    }
    break;
  case 0x6e:
    uVar5 = (&DAT_00a55d74)[(DAT_00a57800 >> 8 & 0x7f) * 0x24 + uVar10 * 0x351] & 0xfff;
    if (((DAT_00a54e5c >> 1 & 3) >> sVar8 & 1) == 0) {
      uVar4 = FUN_00402290(uVar5);
      FUN_005bdf40(auStack_180,0xe8,uVar4);
      uVar4 = FUN_004022e0(uVar5);
      uVar4 = FUN_005a8040(uVar4);
      FUN_005bdfc0(auStack_100,auStack_180,uVar4);
      FUN_005bf800(auStack_100);
      FUN_005bf9a0(1,0);
    }
    else {
      DAT_00a558b4 = 1;
      sVar3 = FUN_004022e0(uVar5);
      if (sVar3 == 1099) {
        DAT_00a558b4 = (ushort)(6000 < (ushort)(&DAT_00a55d64)[uVar10 * 0x6a2]);
      }
      else if (sVar3 == 0x482) {
        iVar11 = FUN_005afe90(uVar10);
        DAT_00a558b4 = (ushort)(iVar11 < 1);
      }
    }
    FUN_00578390(uVar10,uVar5,DAT_00a57800 >> 8 & 0x7f);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  case 0x6f:
    if (DAT_00a558b4 == 0) {
      uVar5 = DAT_00a57800 >> 8 & 0x7f;
      FUN_00577840(uVar10,uVar5,0,(&DAT_00a55d74)[uVar5 * 0x24 + uVar10 * 0x351] & 0xfff);
    }
    else {
      uVar4 = FUN_004022e0((&DAT_00a55d74)[(DAT_00a57800 >> 8 & 0x7f) * 0x24 + uVar10 * 0x351] &
                           0xfff);
      uVar4 = FUN_005a8040(uVar4);
      FUN_00578460(uVar10,uVar4);
    }
    goto LAB_005a86f7;
  case 0x78:
    if (((DAT_00a54e5c >> 1 & 3) >> sVar8 & 1) == 0) {
      uVar4 = FUN_00402290((&DAT_00a55d74)[(DAT_00a57800 >> 8 & 0x7f) * 0x24 + uVar10 * 0x351] &
                           0xfff);
      FUN_005bdf40(auStack_100,0xe9,uVar4);
      FUN_005bf800(auStack_100);
      FUN_005bf9a0(1,0);
      _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
      return 0;
    }
    DAT_00a558b4 = 0;
    goto LAB_005a85c3;
  case 0x79:
    if (DAT_00a558b4 == 0) {
      uVar5 = DAT_00a57800 >> 8 & 0x7f;
      FUN_00577840(uVar10,uVar5,0,(&DAT_00a55d74)[uVar5 * 0x24 + uVar10 * 0x351] & 0xfff);
      uVar2 = (ushort)DAT_00a57800;
      DAT_00a57800._0_2_ = uVar2 ^ ((uVar2 & 0xff00) + 0x100 ^ uVar2) & 0x7f00;
      _DAT_00a577fe = CONCAT11(0x65,DAT_00a577fe);
      return 0;
    }
LAB_005a85c3:
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  case 0x7a:
    if ((DAT_00a54e54 & 0x102) != 0) {
      _DAT_00a577fe = CONCAT11(0x78,DAT_00a577fe);
      return 0;
    }
    iVar11 = FUN_005aa440(0xf000f0);
    uVar5 = DAT_00a55044;
    if (iVar11 == 0) {
      return 0;
    }
    uVar6 = DAT_00a5504c + DAT_00a55048;
    iVar11 = FUN_0056a140(uVar10,DAT_00a55044,uVar6);
    if (iVar11 == 0) {
      return 0;
    }
    if ((uVar5 == uVar10) && (uVar6 == (DAT_00a57800 >> 8 & 0x7f))) {
      return 0;
    }
    iVar11 = FUN_005aa480();
    if (iVar11 == 0) {
      return 0;
    }
    FUN_00577b30(DAT_00a55044,DAT_00a5504c);
LAB_005a86f7:
    uVar2 = (ushort)DAT_00a57800;
    DAT_00a57800._0_2_ = uVar2 ^ ((uVar2 & 0xff00) + 0x100 ^ uVar2) & 0x7f00;
    _DAT_00a577fe = CONCAT11(0x65,DAT_00a577fe);
    return 0;
  case 200:
    iVar11 = 0;
    puVar13 = &DAT_00a55d74 + uVar10 * 0x351;
    do {
      if ((((*puVar13 & 0xfff) != 0) && ((*(byte *)((int)puVar13 + 6) & 2) != 0)) &&
         (sVar3 = FUN_004022e0((ushort)*puVar13 & 0xfff), sVar3 == 0x52)) {
        FUN_0059c8d0(uVar10,iVar11);
      }
      iVar11 = iVar11 + 1;
      puVar13 = puVar13 + 0x24;
    } while (iVar11 < 5);
    FUN_0059ca20(uVar10);
    iVar11 = 5;
    puVar13 = (uint *)(&DAT_00a56044 + uVar10 * 0x6a2);
    do {
      if ((((*puVar13 & 0xfff) != 0) && ((*(byte *)((int)puVar13 + 6) & 2) != 0)) &&
         ((sVar3 = FUN_004022e0((ushort)*puVar13 & 0xfff), sVar3 == 0x416 || (sVar3 == 0x424)))) {
        FUN_005b9170(CONCAT31((uint3)(-(uint)(bVar9 != 0) >> 8) & 0x80,0x8b),iVar11,1,0);
      }
      iVar11 = iVar11 + 1;
      puVar13 = puVar13 + 0x24;
    } while (iVar11 < 10);
    iStack_184 = 5;
    puVar13 = (uint *)(&DAT_00a56044 + (-uVar10 - 1 & 1) * 0x6a2);
    do {
      if ((((*puVar13 & 0xfff) != 0) && ((*(byte *)((int)puVar13 + 6) & 2) != 0)) &&
         (sVar3 = FUN_004022e0((ushort)*puVar13 & 0xfff), sVar3 == 0x2df)) {
        iVar11 = 1 - uVar10;
        uVar6 = FUN_0056fb40(iVar11,iStack_184);
        uVar5 = (uVar6 & 0xffff) >> 8;
        if (((uVar6 & 0xffff) != 0xffff) &&
           (iVar7 = FUN_0056dc10(uVar6 & 0xff,uVar5,iVar11,iStack_184),
           ((&DAT_00a55dc0)[(iVar7 + uVar5 * 0x48) * 2 + (uVar6 & 1) * 0xd44] & 0xf) == 1)) {
          FUN_005b9170(-(uint)(iVar11 != 0) & 0x8000 | 0x8b,iStack_184,1,0);
        }
      }
      puVar13 = puVar13 + 0x24;
      iStack_184 = iStack_184 + 1;
    } while (iStack_184 < 10);
    FUN_00579930(uVar10,2,0);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  }
  _DAT_00a577fe = CONCAT11(200,DAT_00a577fe);
  return 0;
}


//// FUNC 005a5120 FUN_005a5120

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a5120(void)

{
  bool bVar1;
  short sVar2;
  ushort uVar3;
  undefined2 uVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  uint uVar8;
  byte bVar9;
  ushort *puVar10;
  uint uVar11;
  int iVar12;
  uint uVar13;
  uint *puVar14;
  uint uVar15;
  uint uStack_10;
  uint uStack_8;
  
  bVar9 = DAT_00a577f8._2_1_ & 1;
  uVar5 = DAT_00a577f8._2_1_ & 1;
  uVar8 = *(uint *)(&DAT_00a56430 + uVar5 * 0xd44) >> 0x17 & 1;
  switch(_DAT_00a577fe >> 8) {
  case 0:
    if (uVar8 == 0) {
      FUN_005b9170(-(uint)((DAT_00a577f8._2_1_ & 1) != 0) & 0x8000 | 0x55,0,0,0);
      FUN_00598590(DAT_00a577f8._2_1_ & 1,3,0);
    }
    DAT_00a57800 = DAT_00a57800 & 0xffff8000;
    _DAT_00a577fe = CONCAT11(2,DAT_00a577fe);
    return 0;
  default:
    return 1;
  case 2:
    iVar7 = FUN_005a46b0(uVar5);
    if (iVar7 == 0) {
      return 0;
    }
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    DAT_00a57800 = DAT_00a57800 & 0xffff85ff | 0x500;
  case 3:
    if ((DAT_00a57800 & 0x7f00) < 0xa00) {
      do {
        uVar15 = DAT_00a57800 >> 8 & 0x7f;
        if ((((((&DAT_00a55d74)[uVar5 * 0x351 + uVar15 * 0x24] & 0xfff) != 0) &&
             (((&DAT_00a55d7a)[uVar15 * 0x90 + uVar5 * 0xd44] & 2) != 0)) &&
            ((sVar2 = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar5 * 0x351 + uVar15 * 0x24) &
                                   0xfff), sVar2 == 0x47 &&
             (((*(byte *)(&DAT_00a55e00 + uVar5 * 0x351 + uVar15 * 0x24) & 0x20) == 0 &&
              ((DAT_00a577ec & 0x10000) == 0)))))) && ((DAT_00a577ec & 0x10) == 0)) {
          FUN_005b9170(-(uint)(bVar9 != 0) & 0x8000 | 0x8b,uVar15,1,0);
          goto LAB_005a546f;
        }
        uVar3 = (ushort)DAT_00a57800;
        DAT_00a57800._0_2_ = uVar3 ^ ((uVar3 & 0xff00) + 0x100 ^ uVar3) & 0x7f00;
      } while (((ushort)DAT_00a57800 & 0x7f00) < 0xa00);
    }
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    DAT_00a57800 = DAT_00a57800 & 0xffff85ff | 0x500;
  case 4:
    if ((DAT_00a57800 & 0x7f00) < 0xa00) {
      uVar15 = -uVar5 - 1 & 1;
      iVar7 = uVar15 * 0xd44;
      do {
        uVar11 = DAT_00a57800 >> 8 & 0x7f;
        if ((((&DAT_00a55d74)[uVar15 * 0x351 + uVar11 * 0x24] & 0xfff) != 0) &&
           (((&DAT_00a55d7a)[uVar11 * 0x90 + iVar7] & 2) != 0)) {
          sVar2 = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar15 * 0x351 + uVar11 * 0x24) & 0xfff);
          if (sVar2 == 0x15b) {
            FUN_005b9170(CONCAT31((uint3)(-(uint)(1 - uVar5 != 0) >> 8) & 0x80,0x8b),uVar11,1,0);
            if ((uVar8 == 0) && (((&DAT_00a55d7a)[iVar7 + uVar11 * 0x90] & 0x3c) == 8)) {
              FUN_00577840(1 - uVar5,uVar11,0,0);
            }
            uVar3 = (ushort)DAT_00a57800;
            DAT_00a57800._0_2_ = uVar3 ^ ((uVar3 & 0xff00) + 0x100 ^ uVar3) & 0x7f00;
            return 0;
          }
          if (sVar2 == 0x4ce) {
            FUN_005b9170(CONCAT31((uint3)(-(uint)(1 - uVar5 != 0) >> 8) & 0x80,0x8b),uVar11,1,0);
            if ((uVar8 == 0) && (((&DAT_00a55d7a)[iVar7 + uVar11 * 0x90] & 0x3c) == 4)) {
              FUN_00577840(1 - uVar5,uVar11,0,0);
            }
LAB_005a546f:
            uVar3 = (ushort)DAT_00a57800;
            DAT_00a57800._0_2_ = uVar3 ^ ((uVar3 & 0xff00) + 0x100 ^ uVar3) & 0x7f00;
            return 0;
          }
        }
        uVar3 = (ushort)DAT_00a57800;
        DAT_00a57800._0_2_ = uVar3 ^ ((uVar3 & 0xff00) + 0x100 ^ uVar3) & 0x7f00;
      } while (((ushort)DAT_00a57800 & 0x7f00) < 0xa00);
    }
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  case 5:
    uStack_10 = 0;
    do {
      iVar7 = 5;
      uVar15 = uStack_10 ^ uVar5;
      puVar14 = (uint *)(&DAT_00a56044 + (uVar15 & 1) * 0x6a2);
      do {
        uVar3 = FUN_00402460(0x60c);
        if ((((ushort)*puVar14 & 0xfff) == uVar3) && ((*(byte *)((int)puVar14 + 6) & 2) != 0)) {
          uVar11 = FUN_0056fb40(uVar15,iVar7);
          uVar13 = uVar11 & 0xff;
          if ((uVar13 == uVar5) &&
             (((FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar15 != 0) >> 8) & 0x80,0x8b),iVar7,1,0),
               uVar8 == 0 && ((puVar14[0x23] & 0x20) == 0)) &&
              ((*(byte *)((int)puVar14 + 6) & 0x3c) == 4)))) {
            FUN_00578390(uVar15,(ushort)*puVar14 & 0xfff,iVar7);
            *puVar14 = *puVar14 & 0xfffff000;
            uVar4 = FUN_00402460(0x60c);
            iVar6 = FUN_00577840(uVar13,uVar11 >> 8 & 0xff,uVar15 != uVar13,uVar4);
            uVar11 = FUN_00402460(0x60c);
            *puVar14 = uVar11 & 0xfff | *puVar14 & 0xfffff000;
            if (iVar6 != 0) {
              FUN_005779d0(uVar15,iVar7,0,0);
            }
          }
        }
        iVar7 = iVar7 + 1;
        puVar14 = puVar14 + 0x24;
      } while (iVar7 < 10);
      uStack_10 = uStack_10 + 1;
    } while ((int)uStack_10 < 2);
    break;
  case 6:
    uStack_8 = 0;
    do {
      uVar15 = uStack_8 ^ uVar5;
      iVar7 = 0;
      puVar10 = (ushort *)(&DAT_00a55d7a + (uVar15 & 1) * 0xd44);
      do {
        if ((puVar10[-3] & 0xfff) != 0) {
          iVar6 = FUN_0056c460(uVar15,iVar7);
          bVar1 = false;
          uStack_10 = 0;
          if ((uVar15 == uVar5) && (uVar11 = (*puVar10 & 0x1c0) >> 6, uVar11 != 0)) {
            iVar12 = uVar11 - 1;
            FUN_005b9170(CONCAT31((uint3)(-(uint)(uVar15 != 0) >> 8) & 0x80,0x97),iVar7,iVar12,0);
            if ((uVar8 == 0) && (iVar12 == 0)) {
              bVar1 = true;
              uStack_10 = 1;
            }
          }
          iVar12 = FUN_0056db30(uVar15,iVar7,0x458);
          if (iVar12 != 0) {
            bVar1 = true;
          }
          if ((iVar6 == 0) && (iVar6 = FUN_0056dbe0(uVar15,iVar7,0x8000), iVar6 != 0)) {
            bVar1 = true;
          }
          iVar6 = FUN_0056db30(uVar15,iVar7,0x5e8);
          if ((iVar6 != 0) || (bVar1)) {
            FUN_00577840(uVar15,iVar7,uStack_10,0);
          }
        }
        iVar7 = iVar7 + 1;
        puVar10 = puVar10 + 0x48;
      } while (iVar7 < 5);
      uStack_8 = uStack_8 + 1;
    } while ((int)uStack_8 < 2);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  case 7:
    if (uVar8 != 0) {
      return 1;
    }
    _DAT_00a577fe = CONCAT11(10,DAT_00a577fe);
  case 10:
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    DAT_00a57800 = DAT_00a57800 & 0xffff8000;
  case 0xb:
    uVar8 = DAT_00a57800;
    bVar9 = (byte)DAT_00a57800;
    while( true ) {
      DAT_00a57800 = uVar8;
      if (9 < bVar9) {
        _DAT_00a577fe = CONCAT11(100,DAT_00a577fe);
        return 0;
      }
      iVar7 = (*(code *)(&PTR_LAB_005dd010)[DAT_00a57800 & 0xff])(uVar5);
      if (iVar7 == 0) break;
      DAT_00a57800 = DAT_00a57800 & 0xffff80ff;
      bVar9 = (byte)DAT_00a57800 + 1 ^ (byte)DAT_00a57800;
      DAT_00a57800._0_2_ = (ushort)DAT_00a57800 ^ bVar9;
      uVar8 = DAT_00a57800;
      bVar9 = (byte)DAT_00a57800;
    }
    return 0;
  case 100:
    iVar7 = FUN_005699c0(0x593);
    if ((iVar7 == 0) && (6 < (byte)(&DAT_00a55d68)[uVar5 * 0x6a2])) {
      FUN_005bcdc0(uVar5,((ushort)(&DAT_00a55d68)[uVar5 * 0x6a2] & 0xff) - 6,0,0);
      return 0;
    }
  }
  _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
  return 0;
}


//// FUNC 005a8a50 FUN_005a8a50

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005a8a50(void)

{
  if (_DAT_00a577fe >> 8 == 0) {
    FUN_005b9170(CONCAT31((uint3)(-(uint)((DAT_00a577f8._2_1_ & 1) != 0) >> 8) & 0x80,2),0,0,0);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
  }
  else if (_DAT_00a577fe >> 8 == 1) {
    FUN_005b9170(CONCAT31((uint3)(-(uint)((DAT_00a577f8._2_1_ & 1) != 0) >> 8) & 0x80,3),0,0,0);
    _DAT_00a577fe = (_DAT_00a577fe & 0xff00) + 0x100 ^ _DAT_00a577fe & 0xff;
    return 0;
  }
  return 0;
}


