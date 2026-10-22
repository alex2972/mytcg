//// FUNC 0047c4f0 FUN_0047c4f0 size=74

void __thiscall FUN_0047c4f0(int param_1,int param_2,undefined4 param_3,undefined1 param_4)

{
  if (*(char *)(param_1 + 0x30) != '\0') {
    FUN_0047c540();
    return;
  }
  *(undefined4 *)(param_1 + 0x2c) = param_3;
  *(undefined4 *)(param_1 + 0x34) = 0;
  *(int *)(param_1 + 0x28) = param_2;
  *(undefined1 *)(param_1 + 0x30) = param_4;
  FUN_005c03d0(((-1 < param_2) - 1 & 0xffffffea) + 0x1000001f,0);
  return;
}



//// FUNC 0047c540 FUN_0047c540 size=5

void __fastcall FUN_0047c540(int param_1)

{
  *(undefined1 *)(param_1 + 0x30) = 0;
  return;
}



//// FUNC 0047c550 FUN_0047c550 size=9

void __fastcall FUN_0047c550(int param_1)

{
  *(undefined4 *)(param_1 + 0x28) = 0;
  *(undefined1 *)(param_1 + 0x30) = 0;
  return;
}



//// FUNC 004806f0 FUN_004806f0 size=639

int __thiscall
FUN_004806f0(int param_1,int *param_2,int param_3,int param_4,uint param_5,int param_6,int *param_7,
            int param_8)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  int *piVar6;
  int iVar7;
  int local_4c;
  int local_38;
  undefined4 local_34;
  int local_30;
  undefined4 local_2c;
  int local_28 [10];
  
  if (param_6 < 1) {
    return param_3;
  }
  if (0xff < param_6) {
    iVar1 = FUN_004803c0(param_2,param_3,param_4,param_5,param_7,param_8);
    return iVar1;
  }
  iVar1 = (param_5 ^ (int)param_5 >> 0x1f) - ((int)param_5 >> 0x1f);
  local_4c = 0;
  piVar6 = local_28;
  do {
    iVar2 = local_4c;
    local_4c = iVar2 + 1;
    *piVar6 = iVar1 % 10;
    iVar1 = iVar1 / 10;
    piVar6 = piVar6 + 1;
  } while (iVar1 != 0);
  if (0xb < *(int *)(param_1 + 8)) {
    if ((int)param_5 < 0) {
      local_28[local_4c] = 0xb;
    }
    else {
      if ((char)param_7 == '\0') goto LAB_004807a4;
      local_28[local_4c] = 10;
    }
    local_4c = iVar2 + 2;
  }
LAB_004807a4:
  iVar1 = FUN_00480200();
  iVar2 = FUN_004801e0();
  if (param_8 == 0) {
    param_8 = iVar1;
  }
  local_34 = *(undefined4 *)(*(int *)(param_1 + 4) + 0x1c);
  local_2c = *(undefined4 *)(*(int *)(param_1 + 4) + 0x24);
  if (local_4c < 2) {
    iVar3 = 0;
  }
  else {
    iVar3 = (int)(0x40 / (longlong)(local_4c + -1));
  }
  if (local_4c < 1) {
    return param_3;
  }
  param_7 = local_28;
  param_5 = param_6 * 4 - 0x80;
  uVar5 = param_6 * 2 - 0x80;
  do {
    param_3 = param_3 - param_8;
    local_38 = *param_7 * iVar1;
    local_30 = local_38 + iVar1;
    if (-1 < param_6) {
      if (param_6 < 0x80) {
        iVar4 = *param_2;
        iVar7 = param_4 - ((&DAT_00a52ee8)[uVar5 & 0x1ff] * iVar2 >> 0x10);
      }
      else {
        if (param_6 < 0xc0) {
          (**(code **)(*param_2 + 8))
                    (*(undefined4 *)(param_1 + 4),param_3,
                     param_4 - ((&DAT_00a52ee8)[param_5 & 0x1ff] *
                                ((int)(iVar2 + (iVar2 >> 0x1f & 3U)) >> 2) >> 0x10),&local_38,0,0);
          goto LAB_00480917;
        }
        iVar4 = *param_2;
        iVar7 = param_4;
      }
      (**(code **)(iVar4 + 8))(*(undefined4 *)(param_1 + 4),param_3,iVar7,&local_38,0,0);
    }
LAB_00480917:
    uVar5 = uVar5 + iVar3 * -2;
    param_5 = param_5 + iVar3 * -4;
    param_6 = param_6 - iVar3;
    param_7 = param_7 + 1;
    local_4c = local_4c + -1;
    if (local_4c == 0) {
      return param_3;
    }
  } while( true );
}



//// FUNC 0045c280 FUN_0045c280 size=251

undefined8 FUN_0045c280(uint param_1,int param_2,int param_3)

{
  int iVar1;
  undefined4 uVar2;
  uint uVar3;
  
  uVar3 = (uint)(param_1 == ((byte)~DAT_00a54e5c & 1));
  iVar1 = param_2 + param_3;
  if (iVar1 < 0xb) {
    param_3 = 0;
    param_2 = iVar1;
  }
  switch(param_2) {
  case 0:
  case 1:
  case 2:
  case 3:
  case 4:
    param_2 = param_2 + uVar3 * 5;
    return CONCAT44(*(undefined4 *)(&DAT_005db564 + param_2 * 8),(&DAT_005db560)[param_2 * 2]);
  case 5:
  case 6:
  case 7:
  case 8:
  case 9:
    param_2 = param_2 + uVar3 * 5;
    return CONCAT44((&PTR_LAB_005db4ec)[param_2 * 2],(&PTR_LAB_005db4e8)[param_2 * 2]);
  case 10:
    return CONCAT44(*(undefined4 *)(&DAT_005db5e4 + uVar3 * 8),
                    *(undefined4 *)(&DAT_005db5e0 + uVar3 * 8));
  case 0xb:
    uVar2 = *(undefined4 *)(&DAT_005db608 + uVar3 * 8);
    if (param_3 < (int)(&DAT_005f32c8)[param_1]) {
      uVar2 = *(undefined4 *)((&DAT_005f32ac)[param_1 * 4] + param_3 * 8);
    }
    return CONCAT44(*(undefined4 *)(&DAT_005db60c + uVar3 * 8),uVar2);
  case 0xc:
    return CONCAT44(*(undefined4 *)(&DAT_005db5d4 + uVar3 * 8),
                    *(undefined4 *)(&DAT_005db5d0 + uVar3 * 8));
  case 0xd:
    return CONCAT44(*(undefined4 *)(&DAT_005db5b4 + uVar3 * 8),
                    *(undefined4 *)(&DAT_005db5b0 + uVar3 * 8));
  case 0xe:
    return CONCAT44(*(undefined4 *)(&DAT_005db5c4 + uVar3 * 8),
                    *(undefined4 *)(&DAT_005db5c0 + uVar3 * 8));
  case 0xf:
    return CONCAT44(*(undefined4 *)(&DAT_005db5f4 + uVar3 * 8),
                    *(undefined4 *)(&DAT_005db5f0 + uVar3 * 8));
  default:
    return CONCAT44(300,DAT_005db570);
  }
}


