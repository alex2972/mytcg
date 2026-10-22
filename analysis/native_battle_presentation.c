//// FUNC 00480b10 FUN_00480b10

bool __fastcall FUN_00480b10(int param_1)

{
  return *(int *)(param_1 + 0xa0) != -1;
}


//// FUNC 00480c20 FUN_00480c20

void __fastcall FUN_00480c20(int param_1)

{
  int iVar1;
  
  if (*(int *)(param_1 + 0xa0) != -1) {
    if (((*(int *)(param_1 + 0xa0) == 3) && (iVar1 = *(int *)(param_1 + 0xa4), 0x3f < iVar1)) &&
       (iVar1 < 0x80)) {
      *(int *)(param_1 + 0xa4) = iVar1 + 4;
      return;
    }
    *(int *)(param_1 + 0xa4) = *(int *)(param_1 + 0xa4) + 8;
  }
  return;
}


//// FUNC 00480c60 FUN_00480c60

void __fastcall FUN_00480c60(int param_1)

{
  int *piVar1;
  int *piVar2;
  int iVar3;
  int iVar4;
  int unaff_EBX;
  int unaff_EBP;
  int unaff_EDI;
  int *piVar5;
  int iVar6;
  int iVar7;
  undefined4 uVar8;
  undefined1 *puVar9;
  int iVar10;
  int *piVar11;
  int *piStack_1c;
  int iStack_18;
  int iStack_14;
  int *piStack_10;
  uint uStack_c;
  int iStack_8;
  
  piStack_10 = *(int **)(param_1 + 0xa0);
  if (piStack_10 == (int *)0xffffffff) {
    return;
  }
  uStack_c = (uint)(*(uint *)(param_1 + 0x9c) == ((byte)~DAT_00a54e5c & 1));
  iStack_8 = param_1;
  if (5 < (int)piStack_10) {
    iVar3 = *(int *)(param_1 + 0xa4);
    iVar4 = uStack_c * -10 + 0x24;
    if (iVar3 < 0x40) {
      iVar6 = (0x40 - iVar3) * 2;
      iVar10 = iVar4;
    }
    else {
      if (iVar3 < 0x141) {
        iVar6 = 0;
        iVar3 = (int)(iVar3 + -0x40 + (iVar3 + -0x40 >> 0x1f & 0xfU)) >> 4;
        if (7 < iVar3) {
          iVar3 = 8;
        }
        iVar10 = iVar3 + 1 + iVar4;
      }
      else {
        if (0x17f < iVar3) {
          *(undefined4 *)(param_1 + 0xa0) = 0xffffffff;
          (**(code **)(*(int *)(param_1 + 0x10) + 0x14))(0x7fffffff);
          return;
        }
        iVar10 = uStack_c * -10 + 0x2d;
        iVar6 = (0x140 - iVar3) * 2;
      }
      if (iVar4 < iVar10) {
        (**(code **)(*(int *)(param_1 + 0x10) + 0xc))(iVar10 + -1);
      }
    }
    iStack_8 = DAT_005db570;
    iStack_14 = iVar10;
    (**(code **)**(undefined4 **)(param_1 + 0x60))(&iStack_14);
    (**(code **)(*(int *)(param_1 + 0x10) + 8))(iStack_18,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x38) + unaff_EBX * 4) = 0;
    FUN_004223f0(iStack_8,*(undefined4 *)(*(int *)(param_1 + 0x70) + 4 + unaff_EBX * 8),iStack_14,
                 300,iVar6);
    return;
  }
  iVar3 = *(int *)(param_1 + 0xa4);
  piVar5 = (int *)(param_1 + 0x10);
  iStack_14 = (int)piStack_10 + uStack_c * 6;
  piVar11 = &iStack_14;
  (**(code **)**(undefined4 **)(param_1 + 0x60))(piVar11);
  iVar10 = -1;
  (**(code **)(*piVar5 + 8))(iStack_18);
  *(undefined4 *)(*(int *)(param_1 + 0x38) + unaff_EBX * 4) = 0;
  piVar1 = *(int **)(*(int *)(param_1 + 0x70) + 4 + unaff_EBX * 8);
  puVar9 = &stack0xffffffd8;
  (**(code **)(*piVar1 + 0x38))(&stack0xffffffdc,puVar9);
  piVar2 = piStack_10;
  iVar4 = DAT_005db570;
  if (iVar3 < 0x40) {
    uVar8 = 0;
    iVar7 = 0;
    iVar6 = 0;
    iVar10 = (&DAT_00a52ee8)[iVar3 * 2 & 0x1ff];
    (**(code **)(*piStack_10 + 0x10))
              (piVar1,(DAT_005db570 - unaff_EDI / 2) - (iVar10 >> 10),300 - (int)piVar11 / 2,
               iVar3 * 3,0,0,0);
    (**(code **)(*piVar2 + 0x10))
              (piVar1,(iVar4 - iVar7 / 2) + (iVar10 >> 10),300 - iVar6 / 2,uVar8,0,0,0);
    return;
  }
  if (0x80 < iVar3) {
    if (0xff < iVar3) {
      iVar3 = *piVar5;
      piStack_1c[0x28] = -1;
      (**(code **)(iVar3 + 0x14))(0x7fffffff);
      return;
    }
    (**(code **)(*piStack_10 + 0x10))
              (piVar1,DAT_005db570 - unaff_EDI / 2,300 - (int)piVar11 / 2,
               (int)(&DAT_00a52ee8)[iVar3 - 0x80U & 0x1ff] >> 8,0,0,0);
    return;
  }
  if ((unaff_EBP == 3) && ((int)(iVar3 + -0x40 + (iVar3 + -0x40 >> 0x1f & 7U)) >> 3 < 7)) {
    (**(code **)**(undefined4 **)(param_1 + 0x60))(&stack0xffffffd8);
    (**(code **)(*piVar5 + 8))(unaff_EDI,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x38) + iVar10 * 4) = 0;
    (**(code **)(*piStack_1c + 8))
              (*(undefined4 *)(*(int *)(param_1 + 0x70) + 4 + iVar10 * 8),iVar4 - iStack_18 / 2,
               300 - (int)puVar9 / 2,0,0,0);
    return;
  }
  iVar6 = 0;
  iVar10 = 0;
  (**(code **)(*piStack_10 + 8))(piVar1,DAT_005db570 - unaff_EDI / 2,300 - (int)piVar11 / 2,0,0,0);
  (**(code **)(*piVar2 + 0xb0))(piVar1,iVar4 - iVar6 / 2,300 - iVar10 / 2,(char)iVar3 * -2,0,0,0);
  return;
}


//// FUNC 00456730 FUN_00456730

void __fastcall FUN_00456730(int param_1)

{
  *(int *)(param_1 + 0x10) = *(int *)(param_1 + 0x10) + 8;
  return;
}


//// FUNC 004514b0 FUN_004514b0

void __thiscall FUN_004514b0(int param_1,int *param_2)

{
  int *piVar1;
  undefined4 unaff_EBX;
  int iVar2;
  int iVar3;
  int unaff_ESI;
  int unaff_EDI;
  int iStack_c;
  undefined4 uStack_8;
  int iStack_4;
  
  iVar2 = *(int *)(param_1 + 0x10);
  if ((0x1f < iVar2) && (iVar2 < 0x90)) {
    iVar2 = iVar2 + 0x60;
    iVar3 = iVar2 * 0x100;
    if (0xff < iVar2) {
      iVar2 = 0xff;
    }
    iStack_c = 1;
    (**(code **)**(undefined4 **)(param_1 + 0x70))(&iStack_c);
    (**(code **)(*(int *)(param_1 + 0x20) + 8))(unaff_EBX,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x48) + iStack_c * 4) = 0;
    FUN_00422c00(param_2,*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + iStack_c * 8),
                 *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),0,iVar3,iVar3,iVar2
                );
  }
  iVar2 = *(int *)(param_1 + 0x10);
  if ((0x7f < iVar2) && (iVar2 < 0xd0)) {
    iVar2 = iVar2 * 5 + -0x280;
    iStack_c = ((int)(iVar2 + (iVar2 >> 0x1f & 0x3fU)) >> 6) + 2;
    if (6 < iStack_c) {
      return;
    }
    (**(code **)**(undefined4 **)(param_1 + 0x70))(&iStack_c);
    (**(code **)(*(int *)(param_1 + 0x20) + 8))(unaff_EBX,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x48) + unaff_ESI * 4) = 0;
    piVar1 = *(int **)(*(int *)(param_1 + 0x80) + 4 + unaff_ESI * 8);
    (**(code **)(*piVar1 + 0x38))(&stack0xfffffff0,&stack0xffffffec);
    (**(code **)(*param_2 + 0x28))
              (piVar1,*(int *)(param_1 + 0x14) - unaff_ESI / 2,
               *(int *)(param_1 + 0x18) - unaff_EDI / 2,0,0,0);
  }
  iStack_4 = *(int *)(param_1 + 0x10);
  if (0xcf < iStack_4) {
    *(undefined1 *)(param_1 + 4) = 0;
  }
  if (iStack_4 < 0x80) {
    iVar3 = (iStack_4 + 0x80) * 0x100;
    iVar2 = (int)(&DAT_00a52ee8)[iStack_4 - 0x40U & 0x1ff] >> 8;
    if (0xff < iVar2) {
      iVar2 = 0xff;
    }
    iStack_c = 0;
    (**(code **)**(undefined4 **)(param_1 + 0x70))(&iStack_c);
    (**(code **)(*(int *)(param_1 + 0x20) + 8))(unaff_EBX,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x48) + unaff_ESI * 4) = 0;
    FUN_00422c00(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + unaff_ESI * 8),
                 *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),unaff_EBX,iVar3,
                 iVar3,iVar2);
  }
  return;
}


//// FUNC 00414110 FUN_00414110

void __fastcall FUN_00414110(int param_1)

{
  uint uVar1;
  bool bVar2;
  int iVar3;
  undefined4 uVar4;
  int iVar5;
  uint *puVar6;
  
  iVar3 = *(int *)(param_1 + 0x10);
  switch(iVar3) {
  case 3:
    if (*(int *)(param_1 + 0x14) < 0x80) {
      *(int *)(param_1 + 0x14) = *(int *)(param_1 + 0x14) + 0x10;
      return;
    }
    break;
  case 4:
    iVar5 = *(int *)(param_1 + 0x14) + 0x10;
    *(int *)(param_1 + 0x14) = iVar5;
    if (0x1ff < iVar5) {
      *(int *)(param_1 + 0x10) = iVar3 + 1;
      return;
    }
    break;
  case 6:
    iVar5 = *(int *)(param_1 + 0x14) + 0x10;
    *(int *)(param_1 + 0x14) = iVar5;
    if (iVar5 == 0x200) {
      *(undefined4 *)(param_1 + 0x14) = 0;
      *(int *)(param_1 + 0x10) = iVar3 + 1;
      return;
    }
    break;
  case 7:
    if (*(int *)(param_1 + 0x14) == 0) {
      bVar2 = false;
      if ((*(int *)(param_1 + 0x24) != -1) &&
         ((uVar1 = *(uint *)(param_1 + 0x30 + (uint)(*(int *)(param_1 + 0x18) == 0) * 4),
          (uVar1 & 2) != 0 || (((byte)uVar1 & 0x1c) == 4)))) {
        iVar3 = FUN_0041cee0(*(undefined4 *)(param_1 + 0x20),0,*(int *)(param_1 + 0x24));
        if (iVar3 != 0) {
          *(undefined4 *)(iVar3 + 0x18) = 2;
          *(undefined4 *)(iVar3 + 0x1c) = 0x100;
        }
        bVar2 = true;
      }
      uVar1 = *(uint *)(param_1 + 0x30 + *(int *)(param_1 + 0x18) * 4);
      if (((uVar1 & 2) != 0) || (((byte)uVar1 & 0x1c) == 4)) {
        iVar3 = FUN_0041cee0(*(int *)(param_1 + 0x18),0,*(undefined4 *)(param_1 + 0x1c));
        if (iVar3 != 0) {
          *(undefined4 *)(iVar3 + 0x18) = 2;
          *(undefined4 *)(iVar3 + 0x1c) = 0x100;
        }
        bVar2 = true;
      }
      iVar3 = 0;
      puVar6 = (uint *)(param_1 + 0x30);
      do {
        if (puVar6[-2] != 0) {
          if (iVar3 == *(int *)(param_1 + 0x18)) {
            uVar4 = *(undefined4 *)(param_1 + 0x1c);
          }
          else {
            uVar4 = *(undefined4 *)(param_1 + 0x24);
          }
          if (*(int *)(param_1 + 0x24) == -1) {
            uVar4 = 0xffffffff;
          }
          if ((*puVar6 & 8) != 0) {
            uVar4 = 0xffffffff;
          }
          if ((*puVar6 & 0x10) != 0) {
            uVar4 = 0xffffffff;
          }
          FUN_0047c4f0(-puVar6[-2],uVar4,1);
          bVar2 = false;
        }
        iVar3 = iVar3 + 1;
        puVar6 = puVar6 + 1;
      } while (iVar3 < 2);
      if (bVar2) {
        FUN_005c03d0(0x10000009,0);
      }
    }
    iVar3 = *(int *)(param_1 + 0x14) + 8;
    *(int *)(param_1 + 0x14) = iVar3;
    if (iVar3 == 0x100) {
      *(undefined4 *)(param_1 + 0x14) = 0;
      *(int *)(param_1 + 0x10) = *(int *)(param_1 + 0x10) + 1;
    }
  }
  return;
}


//// FUNC 004142c0 FUN_004142c0

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall FUN_004142c0(int param_1,undefined4 param_2)

{
  char cVar1;
  short sVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  int iVar6;
  int iVar7;
  int unaff_EBX;
  int unaff_EBP;
  int *piVar8;
  int unaff_ESI;
  int unaff_EDI;
  undefined8 uVar9;
  undefined4 uVar10;
  int *piStack_3c;
  int iStack_28;
  undefined8 uStack_24;
  int *piStack_1c;
  undefined8 uStack_18;
  undefined4 uStack_10;
  undefined4 uStack_8;
  
  iVar6 = uStack_18._4_4_;
  iVar4 = (int)uStack_18;
  if (*(int *)(param_1 + 0x10) != 0) {
    piStack_3c = *(int **)(param_1 + 0x24);
    if ((int)piStack_3c < 0) {
      iVar6 = (-(uint)(*(uint *)(param_1 + 0x18) != (_DAT_00a54e5c & 1)) & 0x1d8) + 0x40;
      iVar4 = DAT_005db570;
    }
    else {
      uVar9 = FUN_0045c140(*(undefined4 *)(param_1 + 0x20),0);
      iVar6 = (int)((ulonglong)uVar9 >> 0x20);
      iVar4 = (int)uVar9;
    }
    uStack_24._0_4_ = (int *)0x0;
    do {
      piVar8 = (int *)uStack_24;
      piStack_3c = (int *)uStack_24;
      uVar9 = FUN_0045c140(*(undefined4 *)(param_1 + 0x18),0);
      uStack_18 = uVar9;
      sVar2 = FUN_00570230(*(undefined4 *)(param_1 + 0x18),0,piVar8);
      if (sVar2 != 0) {
        piStack_3c = piVar8;
        cVar1 = FUN_0041cfc0(*(undefined4 *)(param_1 + 0x18),0);
        if ((cVar1 != '\0') &&
           (((*(int *)(param_1 + 0x10) < 3 || (5 < *(int *)(param_1 + 0x10))) ||
            (piVar8 != *(int **)(param_1 + 0x1c))))) {
          piStack_3c = (int *)0x1;
          iVar3 = FUN_0056b730(*(undefined4 *)(param_1 + 0x18),piVar8);
          if (iVar3 != 0) {
            iStack_28 = 0;
            piStack_3c = &iStack_28;
            (**(code **)**(undefined4 **)(param_1 + 0x88))();
            (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EBX,0xffffffff);
            piStack_3c = (int *)0xa0;
            *(undefined4 *)(*(int *)(param_1 + 0x60) + iStack_28 * 4) = 0;
            FUN_00422c00(param_2,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + iStack_28 * 8),
                         uStack_18,
                         (uint)(*(uint *)(param_1 + 0x18) == ((byte)~DAT_00a54e5c & 1)) << 8,0x10000
                         ,0x10000);
            piVar8 = (int *)uStack_24;
          }
        }
      }
      uStack_24._0_4_ = (int *)((int)piVar8 + 1);
    } while ((int)(int *)uStack_24 < 5);
  }
  iVar3 = *(int *)(param_1 + 0x10);
  if (iVar3 == 3) {
    piStack_3c = *(int **)(param_1 + 0x1c);
    uVar9 = FUN_0045c140(*(undefined4 *)(param_1 + 0x18),0);
    piStack_3c = (int *)&uStack_18;
    (**(code **)(*DAT_005f33e0 + 4))(&piStack_1c);
    fpatan((float10)((int)(int *)uStack_24 - (int)uVar9),
           (float10)((int)((ulonglong)uVar9 >> 0x20) - uStack_24._4_4_));
    iVar4 = __ftol();
    iVar6 = *(int *)(param_1 + 0x14);
    if (0x80 < iVar6) {
      iVar6 = 0x80;
    }
    (**(code **)**(undefined4 **)(param_1 + 0x88))(&stack0xffffffd0);
    (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_ESI,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x60) + (int)piStack_3c * 4) = 0;
    FUN_00422840(uStack_10,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + (int)piStack_3c * 8),uVar9
                 ,(int)(iVar6 * iVar4 + (iVar6 * iVar4 >> 0x1f & 0x7fU)) >> 7,0x10000,0x10000,0);
  }
  else if (iVar3 == 4) {
    piStack_3c = *(int **)(param_1 + 0x1c);
    uStack_24 = FUN_0045c140(*(undefined4 *)(param_1 + 0x18),0);
    iVar3 = (int)((ulonglong)uStack_24 >> 0x20);
    uStack_18 = uStack_24;
    if (*(int *)(param_1 + 0x14) < 0x81) {
      if (*(uint *)(param_1 + 0x20) == ((byte)~DAT_00a54e5c & 1)) {
        piStack_1c = (int *)(iVar3 - iVar6);
        fpatan((float10)(iVar4 - (int)uStack_24),(float10)(int)piStack_1c);
        piStack_3c = (int *)0x41484d;
        iVar6 = __ftol();
        iVar6 = iVar6 * *(int *)(param_1 + 0x14);
        iVar6 = (int)(iVar6 + (iVar6 >> 0x1f & 0x7fU)) >> 7;
      }
      else {
        piStack_1c = (int *)(iVar6 - iVar3);
        fpatan((float10)(iVar4 - (int)uStack_24),(float10)(int)piStack_1c);
        piStack_3c = (int *)0x414885;
        iVar6 = __ftol();
        iVar6 = iVar6 * *(int *)(param_1 + 0x14);
        iVar6 = ((int)(iVar6 + (iVar6 >> 0x1f & 0x7fU)) >> 7) + 0x100;
      }
      iStack_28 = 0;
      piStack_3c = &iStack_28;
      (**(code **)**(undefined4 **)(param_1 + 0x88))();
      (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EBX,0xffffffff);
      *(undefined4 *)(*(int *)(param_1 + 0x60) + unaff_ESI * 4) = 0;
      FUN_00422840(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + unaff_ESI * 8),
                   (int *)uStack_24,iVar3,iVar6,0x10000,0x10000,0);
      return;
    }
    uVar9 = uStack_24;
    if (*(int *)(param_1 + 0x14) == 0x90) {
      piStack_3c = (int *)0x0;
      FUN_005c03d0(0x10000006);
      uVar9 = uStack_24;
    }
    uStack_24._4_4_ = (int)((ulonglong)uVar9 >> 0x20);
    uStack_24._0_4_ = (int *)uVar9;
    iVar3 = *(int *)(param_1 + 0x14);
    if (iVar3 < 0x100) {
      iVar7 = 0x100 - ((int)(&DAT_00a52ee8)[iVar3 - 0x80U & 0x1ff] >> 8);
      iVar3 = (int)uStack_18 * (0x100 - iVar7) + iVar7 * iVar4;
      iVar7 = iVar7 * iVar6 + uStack_24._4_4_ * (0x100 - iVar7);
      iVar3 = (int)(iVar3 + (iVar3 >> 0x1f & 0xffU)) >> 8;
      uStack_24._4_4_ = (int)(iVar7 + (iVar7 >> 0x1f & 0xffU)) >> 8;
      piStack_1c = (int *)(uStack_24._4_4_ - iVar6);
      fpatan((float10)(iVar4 - iVar3),(float10)(int)piStack_1c);
      piStack_3c = (int *)0x414689;
      uVar10 = __ftol();
      iStack_28 = 0;
      piStack_3c = &iStack_28;
      (**(code **)**(undefined4 **)(param_1 + 0x88))();
      (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EBX,0xffffffff);
      *(undefined4 *)(*(int *)(param_1 + 0x60) + unaff_ESI * 4) = 0;
      FUN_00422840(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + unaff_ESI * 8),iVar3,
                   unaff_EBX,uVar10,0x10000,0x10000,0);
      return;
    }
    if (iVar3 < 0x200) {
      iStack_28 = 2;
      uVar5 = (0x200 - iVar3) * 2;
      uStack_24._0_4_ = (int *)(((int)uVar5 < 1) - 1 & uVar5);
      piStack_3c = &iStack_28;
      iVar3 = (iVar3 + -0x100) * 0x200;
      (**(code **)**(undefined4 **)(param_1 + 0x88))();
      iVar7 = -1;
      (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EBX);
      *(undefined4 *)(*(int *)(param_1 + 0x60) + unaff_ESI * 4) = 0;
      FUN_00422c00(uStack_8,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + unaff_ESI * 8),iVar4,
                   iVar6,0,iVar3,iVar3,unaff_EBP);
      iStack_28 = uStack_24._4_4_ - iVar6;
      fpatan((float10)(iVar4 - (int)(int *)uStack_24),(float10)iStack_28);
      uVar10 = __ftol();
      (**(code **)**(undefined4 **)(param_1 + 0x88))(&stack0xffffffcc);
      (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EDI,0xffffffff);
      *(undefined4 *)(*(int *)(param_1 + 0x60) + iVar7 * 4) = 0;
      FUN_00422c00(uStack_18._4_4_,*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + iVar7 * 8),iVar4,
                   iVar6,uVar10,0x10000,0x10000,piStack_3c);
      return;
    }
  }
  else if ((iVar3 == 6) && (*(int *)(param_1 + 0x14) < 0x100)) {
    piStack_3c = *(int **)(param_1 + 0x24);
    uVar9 = FUN_0045c140(*(undefined4 *)(param_1 + 0x20),0);
    iVar6 = (int)((ulonglong)uVar9 >> 0x20);
    uStack_18._4_4_ = DAT_005f3008;
    uStack_18._0_4_ = DAT_005f3004;
    if ((*(byte *)(param_1 + 0x30 + (uint)(*(int *)(param_1 + 0x18) == 0) * 4) & 1) != 0) {
      uStack_18._0_4_ = DAT_005f3008;
      uStack_18._4_4_ = DAT_005f3004;
    }
    iStack_28 = 3;
    piStack_3c = &iStack_28;
    (**(code **)**(undefined4 **)(param_1 + 0x88))();
    uVar10 = 0xffffffff;
    (**(code **)(*(int *)(param_1 + 0x38) + 8))(unaff_EBX,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x60) + unaff_ESI * 4) = 0;
    piVar8 = &iStack_28;
    (**(code **)(**(int **)(*(int *)(param_1 + 0x98) + 4 + unaff_ESI * 8) + 0x38))(&stack0xffffffd0)
    ;
    uStack_24._0_4_ = (int *)((int)uVar9 - unaff_EBX / 2);
    piStack_3c = (int *)0x3;
    iVar4 = (unaff_EBX / 2 + (int)uVar9) * (0x100 - *(int *)(param_1 + 0x14)) +
            ((int)(int *)uStack_24 - unaff_EDI) * *(int *)(param_1 + 0x14);
    uStack_24._4_4_ = iVar6 - iStack_28 / 2;
    piStack_1c = (int *)((int)(int *)uStack_24 + unaff_EBX);
    uStack_18._0_4_ = uStack_24._4_4_ + iStack_28;
    (**(code **)**(undefined4 **)(param_1 + 0x88))(&piStack_3c);
    (**(code **)(*(int *)(param_1 + 0x38) + 8))(uVar10,0xffffffff);
    *(undefined4 *)(*(int *)(param_1 + 0x60) + (int)piVar8 * 4) = 0;
    (**(code **)(*piStack_1c + 0x9c))
              (*(undefined4 *)(*(int *)(param_1 + 0x98) + 4 + (int)piVar8 * 8),
               (int)(iVar4 + (iVar4 >> 0x1f & 0xffU)) >> 8,iVar6 - unaff_EBP / 2,0,0,
               &stack0xffffffd0);
    return;
  }
  return;
}


