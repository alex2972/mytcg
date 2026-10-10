//// FUNC 005b72a0 FUN_005b72a0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_005b72a0(void)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  byte bVar4;
  undefined4 uVar5;
  
  switch(_DAT_00a579a2 & 0xff) {
  case 0:
    if ((short)DAT_00a577f8 == 0) {
      return 1;
    }
    if ((((*(uint *)(&DAT_00a56430 + (ram0x00a577fa & 1) * 0xd44) & 0x20000) != 0) ||
        (iVar1 = FUN_005ae390(ram0x00a577fa & 1), iVar1 == 0)) ||
       ((iVar1 = FUN_00570a70(ram0x00a577fa & 1), iVar1 == 0 &&
        (iVar1 = FUN_00570ac0(ram0x00a577fa & 1), iVar1 == 0)))) break;
    iVar1 = FUN_00569820(~DAT_00a577f8._2_1_ & 1,0x15b,0xffffffff);
    if (0 < iVar1) break;
    iVar1 = FUN_005ae9c0(ram0x00a577fa & 1,0xffffffff,1);
    if (iVar1 < 0) {
      iVar1 = FUN_005b08b0(ram0x00a577fa & 1);
      if (iVar1 != 0) {
        uVar5 = 0;
        goto LAB_005b739d;
      }
LAB_005b73aa:
      iVar1 = FUN_005b1360(ram0x00a577fa & 1,0xffffffff);
    }
    else {
      uVar5 = 1;
LAB_005b739d:
      iVar1 = FUN_005b1360(ram0x00a577fa & 1,uVar5);
      if (iVar1 == -1) goto LAB_005b73aa;
    }
    if ((-1 < iVar1) && (iVar1 = FUN_005b6ff0(ram0x00a577fa & 1,iVar1,0), iVar1 == 0)) {
      return 0;
    }
LAB_005b755b:
    bVar4 = DAT_00a579a2 + 1 ^ DAT_00a579a2;
    _DAT_00a579a2 = _DAT_00a579a2 ^ bVar4;
    return 0;
  case 1:
    iVar1 = FUN_005b08b0(ram0x00a577fa & 1);
    if (iVar1 != 0) {
      return 1;
    }
    _DAT_00a579a0 = _DAT_00a579a0 & 0xff;
    break;
  case 2:
    iVar1 = FUN_005b6690(ram0x00a577fa & 1);
    if (iVar1 != 0) {
      _DAT_00a579a2 = _DAT_00a579a2 & 0xffffff00;
      return 0;
    }
    break;
  case 3:
    iVar1 = FUN_005b6630(ram0x00a577fa & 1);
    if (iVar1 != 0) {
      _DAT_00a579a2 = _DAT_00a579a2 & 0xffffff00;
      return 0;
    }
    break;
  case 4:
    iVar1 = FUN_005ae390(ram0x00a577fa & 1);
    if (((iVar1 != 0) && ((*(uint *)(&DAT_00a56430 + (ram0x00a577fa & 1) * 0xd44) & 0x20000) == 0))
       && ((iVar1 = FUN_00570a70(ram0x00a577fa & 1), iVar1 != 0 ||
           (iVar1 = FUN_00570ac0(ram0x00a577fa & 1), iVar1 != 0)))) {
      iVar1 = FUN_005b16c0(ram0x00a577fa & 1);
      if (iVar1 < 0) {
        return 1;
      }
      uVar2 = ram0x00a577fa & 1;
      iVar3 = FUN_005ae270(uVar2,(&DAT_00a56434)[uVar2 + iVar1 + uVar2 * 0x350] & 0xfff,0,0);
      if (iVar3 == 0) {
        iVar1 = FUN_005b6ff0(ram0x00a577fa & 1,iVar1,0);
        if (iVar1 == 0) {
          return 0;
        }
        _DAT_00a579a2 = _DAT_00a579a2 & 0xffffff01 | 1;
        return 0;
      }
      return 1;
    }
    goto LAB_005b755b;
  default:
    return 1;
  }
  bVar4 = DAT_00a579a2 + 1 ^ DAT_00a579a2;
  _DAT_00a579a2 = _DAT_00a579a2 ^ bVar4;
  return 0;
}


