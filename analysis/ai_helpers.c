//// FUNC 005aef10 FUN_005aef10

undefined1 FUN_005aef10(undefined4 param_1)

{
  int iVar1;
  int iVar2;
  
  iVar1 = FUN_005699a0(param_1,0x59a);
  if (iVar1 != 0) {
    return 2;
  }
  iVar1 = FUN_0056d2c0(param_1,0x59a);
  iVar2 = FUN_0056cbd0(param_1,0x59a);
  return iVar1 + iVar2 < 1;
}


//// FUNC 005ae8f0 FUN_005ae8f0

undefined4 FUN_005ae8f0(undefined4 param_1)

{
  ushort uVar1;
  
  uVar1 = FUN_004022e0(param_1);
  if (uVar1 < 0x415) {
    if (uVar1 != 0x414) {
      if (uVar1 < 0x141) {
        if (uVar1 != 0x140) {
          if (uVar1 < 0x137) {
            if (((uVar1 != 0x136) && (uVar1 != 0x2f)) && (uVar1 != 0x12f)) {
              return 0;
            }
          }
          else {
            if (uVar1 < 0x138) {
              return 0;
            }
            if (0x139 < uVar1) {
              return 0;
            }
          }
        }
      }
      else if (uVar1 < 0x23e) {
        if (((uVar1 != 0x23d) && (uVar1 != 0x1cd)) && (uVar1 != 0x1de)) {
          return 0;
        }
      }
      else if (uVar1 != 0x412) {
        return 0;
      }
    }
  }
  else if (uVar1 < 0x464) {
    if (uVar1 != 0x463) {
      switch(uVar1) {
      case 0x454:
      case 0x456:
      case 0x45a:
      case 0x45b:
      case 0x45c:
      case 0x45d:
      case 0x45f:
      case 0x460:
        break;
      default:
        goto LAB_005ae99c;
      }
    }
  }
  else if (((uVar1 != 0x4da) && (uVar1 != 0x4e9)) && (uVar1 != 0x57d)) {
LAB_005ae99c:
    return 0;
  }
  return 1;
}


//// FUNC 00569c50 FUN_00569c50

int FUN_00569c50(uint param_1,short param_2)

{
  short sVar1;
  int iVar2;
  ushort *puVar3;
  int iVar4;
  
  iVar2 = 0;
  iVar4 = 0xb;
  puVar3 = (ushort *)(&DAT_00a55d74 + (param_1 & 1) * 0x351);
  do {
    sVar1 = FUN_004022e0(*puVar3 & 0xfff);
    if (sVar1 == param_2) {
      iVar2 = iVar2 + 1;
    }
    puVar3 = puVar3 + 0x48;
    iVar4 = iVar4 + -1;
  } while (iVar4 != 0);
  return iVar2;
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


//// FUNC 0059dbe0 FUN_0059dbe0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

int FUN_0059dbe0(undefined4 param_1)

{
  ushort uVar1;
  ushort uVar2;
  uint uVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  
  iVar5 = 0;
  iVar6 = 0x1ba;
  uVar1 = FUN_004022e0(param_1);
  uVar2 = (ushort)_DAT_005ee560;
  iVar4 = 0xdd;
  uVar3 = _DAT_005ee560;
  while( true ) {
    if (uVar1 == uVar2) {
      return iVar4;
    }
    if (iVar5 == iVar6) break;
    if ((ushort)uVar3 < uVar1) {
      iVar5 = iVar4;
    }
    if (uVar1 < (ushort)uVar3) {
      iVar6 = iVar4;
    }
    if ((iVar6 + iVar5) / 2 == iVar4) {
      iVar5 = iVar6;
    }
    iVar4 = (iVar6 + iVar5) / 2;
    uVar2 = *(ushort *)(iVar4 * 0x18 + 0x5ed0a8);
    uVar3 = (uint)uVar2;
  }
  return -1;
}


