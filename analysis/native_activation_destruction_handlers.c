//// FUNC 00450590 FUN_00450590

void __fastcall FUN_00450590(int param_1)

{
  int iVar1;
  
  if (*(int *)(param_1 + 0x10) == 0) {
    FUN_005c03d0(0x1000000d,0);
  }
  iVar1 = *(int *)(param_1 + 0x10) + 0x10;
  *(int *)(param_1 + 0x10) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x101;
  return;
}


//// FUNC 004505d0 FUN_004505d0

void __fastcall FUN_004505d0(int param_1)

{
  byte bVar1;
  int iVar2;
  int iVar3;
  int unaff_ESI;
  undefined4 unaff_EDI;
  int iVar4;
  undefined4 uVar5;
  undefined1 *puStack_2c;
  undefined1 *puStack_28;
  undefined1 *puStack_24;
  int *piStack_10;
  undefined1 local_8 [4];
  undefined1 local_4 [4];
  
  puStack_24 = local_8;
  puStack_28 = local_4;
  puStack_2c = (undefined1 *)0x4505f2;
  (**(code **)(*(int *)(param_1 + 0xac) + 0x38))();
  iVar2 = (&DAT_00a52ee8)[*(int *)(param_1 + 0x10) - 0x80U & 0x1ff];
  bVar1 = *(byte *)(param_1 + 0x1c);
  puStack_2c = &stack0xffffffe8;
  (**(code **)**(undefined4 **)(param_1 + 0x70))();
  uVar5 = 0xffffffff;
  (**(code **)(*(int *)(param_1 + 0x20) + 8))(unaff_ESI,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x48) + (int)puStack_24 * 4) = 0;
  FUN_00422c00(piStack_10,*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + (int)puStack_24 * 8),
               *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),
               *(int *)(param_1 + 0x10) / 2,iVar2,iVar2,unaff_EDI);
  iVar4 = 0;
  iVar3 = *(int *)(param_1 + 0x18) - unaff_ESI / 2;
  (**(code **)(*piStack_10 + 0x48))
            (param_1 + 0xac,*(int *)(param_1 + 0x14) - ((uint)bVar1 * 2 + 1) / 2,iVar3,iVar2 >> 9,0,
             0);
  puStack_2c = (undefined1 *)((uint)*(byte *)(param_1 + 0x1c) << 1);
  (**(code **)**(undefined4 **)(param_1 + 0x70))(&puStack_2c);
  (**(code **)(*(int *)(param_1 + 0x20) + 8))(uVar5,0xffffffff);
  *(undefined4 *)(*(int *)(param_1 + 0x48) + iVar4 * 4) = 0;
  FUN_00422c00(piStack_10,*(undefined4 *)(*(int *)(param_1 + 0x80) + 4 + iVar4 * 8),
               *(undefined4 *)(param_1 + 0x14),*(undefined4 *)(param_1 + 0x18),
               *(undefined4 *)(param_1 + 0x10),iVar2,iVar2,iVar3);
  return;
}


//// FUNC 00450a90 FUN_00450a90

void __fastcall FUN_00450a90(int param_1)

{
  int iVar1;
  
  if (*(int *)(param_1 + 0x10) == 0) {
    FUN_005c03d0(0x1000000d,0);
  }
  iVar1 = *(int *)(param_1 + 0x10) + 0x10;
  *(int *)(param_1 + 0x10) = iVar1;
  *(bool *)(param_1 + 4) = iVar1 < 0x181;
  return;
}


//// FUNC 00450ad0 FUN_00450ad0

void __fastcall FUN_00450ad0(int param_1)

{
  uint uVar1;
  int *piVar2;
  int *piVar3;
  undefined4 unaff_EBX;
  int iVar4;
  int unaff_EBP;
  int iVar5;
  int unaff_ESI;
  undefined4 uVar6;
  undefined4 *puStack_28;
  undefined4 auStack_14 [5];
  
  piVar2 = DAT_005f2ff8;
  uVar1 = *(uint *)(param_1 + 0x10);
  if ((int)uVar1 < 0) {
    iVar4 = (int)(&DAT_00a52ee8)[uVar1 & 0x1ff] >> 9;
  }
  else {
    iVar4 = 0x80;
  }
  if ((int)uVar1 < 0x100) {
    iVar5 = iVar4 * 2;
  }
  else {
    iVar5 = (int)(&DAT_00a52ee8)[uVar1 - 0x100 & 0x1ff] >> 8;
  }
  auStack_14[0] = *(undefined4 *)(param_1 + 300);
  puStack_28 = auStack_14;
  (*(code *)**(undefined4 **)DAT_005f2ff8[0x14])();
  uVar6 = 0xffffffff;
  (**(code **)(*piVar2 + 8))(unaff_EBX,0xffffffff);
  *(undefined4 *)(piVar2[10] + unaff_EBP * 4) = 0;
  (**(code **)(**(int **)(piVar2[0x18] + 4 + unaff_EBP * 8) + 0x38))(&stack0xffffffe4);
  piVar2 = DAT_005f2ff8;
  puStack_28 = *(undefined4 **)(param_1 + 300);
  piVar3 = (int *)(unaff_ESI * iVar4 >> 8);
  (*(code *)**(undefined4 **)DAT_005f2ff8[0x14])(&puStack_28);
  (**(code **)(*piVar2 + 8))(uVar6,0xffffffff);
  *(undefined4 *)(piVar2[10] + (int)&stack0xffffffe8 * 4) = 0;
  (**(code **)(*piVar3 + 0x48))
            (*(undefined4 *)(piVar2[0x18] + 4 + (int)&stack0xffffffe8 * 8),
             *(int *)(param_1 + 0x14) - (int)puStack_28 / 2,*(int *)(param_1 + 0x18) - unaff_ESI / 2
             ,iVar5,0,&puStack_28,0);
  if ((-1 < *(int *)(param_1 + 0x10)) && (*(int *)(param_1 + 0x10) < 0x101)) {
    FUN_004505d0(piVar3);
  }
  return;
}


//// FUNC 00450fc0 null
//// FUNC 00450ff0 FUN_00450ff0

void FUN_00450ff0(int param_1,int param_2,undefined4 param_3,int param_4,int *param_5,int *param_6)

{
  ushort uVar1;
  uint uVar2;
  int *piVar3;
  int *piVar4;
  int iVar5;
  int unaff_ESI;
  int *unaff_EDI;
  int iVar6;
  int iVar7;
  
  iVar7 = -1;
  (**(code **)(*unaff_EDI + 8))(param_4,0xffffffff);
  *(undefined4 *)(unaff_EDI[10] + param_2 * 4) = 0;
  param_5 = *(int **)(unaff_EDI[0x18] + 4 + param_2 * 8);
  (**(code **)(*param_5 + 0x38))(&param_4,&param_3);
  iVar5 = (int)(*(int *)(unaff_ESI + 0x10) + (*(int *)(unaff_ESI + 0x10) >> 0x1f & 7U)) >> 3;
  iVar6 = 0;
  piVar4 = param_6;
  do {
    piVar3 = param_6;
    param_4 = *piVar4;
    uVar2 = iVar6 / 5;
    (**(code **)(param_4 + 0xac))
              (param_3,(((&DAT_00a52ee8)[uVar2 & 0x1ff] * iVar5 >> 0x10) - param_2 / 2) +
                       *(int *)(unaff_ESI + 0x14),
               (((&DAT_00a52ee8)[uVar2 - 0x80 & 0x1ff] * iVar5 >> 0x10) - param_1 / 2) +
               *(int *)(unaff_ESI + 0x18),
               CONCAT31((int3)(uVar2 >> 8),-1 - *(char *)(unaff_ESI + 0x10)),0,0,0);
    iVar6 = iVar6 + 0x200;
    piVar4 = piVar3;
  } while (iVar6 < 0xa00);
  uVar1 = *(ushort *)(unaff_ESI + 0x1c);
  if (((byte)uVar1 & 0x3e) == 0x16) {
    piVar4 = (int *)FUN_0041f130(((uVar1 >> 0xe & 1) + ((byte)~DAT_00a54e5c & 1 ^ ~uVar1 & 1) * 2) *
                                 0x5a);
  }
  else {
    piVar4 = (int *)FUN_0041f2e0(((uVar1 >> 0xe & 1) + ((byte)~DAT_00a54e5c & 1 ^ ~uVar1 & 1) * 2) *
                                 0x5a);
  }
  (**(code **)(*piVar4 + 0x38))(&param_2,&param_1);
  FUN_00558fb0(piVar3,piVar4,*(int *)(unaff_ESI + 0x14) - iVar5 / 2,
               *(int *)(unaff_ESI + 0x18) - iVar7 / 2,
               0x100 - ((int)(&DAT_00a52ee8)[*(int *)(unaff_ESI + 0x10) / 2 - 0x80U & 0x1ff] >> 8),0
               ,0xff,0);
  return;
}


//// FUNC 0040e010 FUN_0040e010

void __fastcall FUN_0040e010(int param_1)

{
  int iVar1;
  
  *(uint *)(param_1 + 0x10) = *(int *)(param_1 + 0x10) + 8U & 0xff;
  iVar1 = DAT_005f2fdc;
  if ((DAT_005f2fdc != 0) && (*(int *)(param_1 + 0x124) != DAT_005f2fdc)) {
    *(undefined4 *)(param_1 + 0x10) = 0;
  }
  *(int *)(param_1 + 0x124) = iVar1;
  return;
}


//// FUNC 0040e260 FUN_0040e260

void __thiscall FUN_0040e260(int param_1,ushort *param_2)

{
  byte bVar1;
  ushort uVar2;
  uint uVar3;
  ushort uVar4;
  undefined4 uVar5;
  short sVar6;
  ushort *puVar7;
  int iVar8;
  byte *pbVar9;
  uint uVar10;
  int iVar11;
  ushort uVar12;
  uint uVar13;
  uint *puVar14;
  undefined8 uVar15;
  undefined8 uVar16;
  undefined8 *puVar17;
  uint uStack_40;
  uint uStack_3c;
  ushort *puStack_38;
  int iStack_34;
  int iStack_30;
  undefined8 uStack_2c;
  int iStack_24;
  ushort *puStack_20;
  byte *pbStack_1c;
  undefined8 uStack_18;
  undefined8 uStack_10;
  undefined8 uStack_8;
  
  uVar13 = 0;
  if (DAT_005f2fdc != 0) {
    iStack_30 = param_1;
    puVar7 = (ushort *)FUN_00418b50(&uStack_40);
    uVar2 = *puVar7;
    *(undefined4 *)(param_1 + 0x128) = 0;
    pbStack_1c = (byte *)CONCAT22(pbStack_1c._2_2_,uVar2);
    uVar10 = uVar2 >> 1 & 0x1f;
    uStack_40 = (uVar2 >> 6 & 0xff) + uVar10;
    uStack_3c = uVar2 & 1;
    if ((uStack_40 < 0xb) &&
       (iStack_34 = uStack_40 * 0x90 + uStack_3c * 0xd44,
       ((&DAT_00a55d74)[uStack_3c * 0x351 + uStack_40 * 0x24] & 0xfff) != 0)) {
      puVar7 = param_2;
      if ((uVar2 >> 1 & 0x1f) == 0) {
        do {
          iVar11 = 0;
          do {
            iVar8 = FUN_0056f5c0(uStack_3c,uStack_40,uVar13,iVar11);
            if (iVar8 != 0) {
              uVar15 = FUN_0045c140(uVar13,iVar11,0);
              uStack_18 = uVar15;
              FUN_0040e1f0(param_2,&uStack_18,5);
            }
            iVar11 = iVar11 + 1;
          } while (iVar11 < 5);
          uVar13 = uVar13 + 1;
        } while ((int)uVar13 < 2);
        if (((&DAT_00a55d7a)[iStack_34] & 2) != 0) {
          sVar6 = FUN_0056f6d0(uStack_3c,uStack_40);
          if (sVar6 == 1) {
            puVar7 = (ushort *)0x0;
            do {
              iVar11 = 5;
              puVar14 = &DAT_00a560d0 + ((uint)puVar7 & 1) * 0x351;
              do {
                sVar6 = FUN_004022e0((ushort)puVar14[-0x23] & 0xfff);
                if (((sVar6 == 0x148) && ((*(ushort *)((int)puVar14 + -0x86) & 2) != 0)) &&
                   (((uint)(*(ushort *)((int)puVar14 + -0x86) >> 1) & ~(*puVar14 >> 5) &
                     ~(*puVar14 >> 1) & 1) != 0)) {
                  uVar15 = FUN_0045c140(puVar7,iVar11,0);
                  uStack_18 = uVar15;
                  FUN_0040e1f0(param_2,&uStack_18,2);
                }
                iVar11 = iVar11 + 1;
                puVar14 = puVar14 + 0x24;
              } while (iVar11 < 0xb);
              puVar7 = (ushort *)((int)puVar7 + 1);
            } while ((int)puVar7 < 2);
          }
        }
        sVar6 = FUN_004022e0(*(ushort *)((int)&DAT_00a55d74 + iStack_34) & 0xfff);
        pbStack_1c = (byte *)(uint)(sVar6 == 0x536);
        pbVar9 = (byte *)FUN_005699c0(0x536);
        if (pbVar9 != pbStack_1c && -1 < (int)pbVar9 - (int)pbStack_1c) {
          uVar15 = FUN_0045c140(uStack_3c,uStack_40,0);
          uStack_18 = uVar15;
          FUN_0040e1f0(param_2,&uStack_18,4);
        }
        iVar11 = FUN_0056f430(uStack_3c,uStack_40);
        if (-1 < iVar11) {
          uVar15 = FUN_0045c140(iVar11,10,0);
          uStack_18 = uVar15;
          FUN_0040e1f0(param_2,&uStack_18,3);
        }
      }
      else if (uVar10 == 10) {
        do {
          iVar11 = 0;
          puVar7 = (ushort *)(&DAT_00a55d7a + (uVar13 & 1) * 0xd44);
          do {
            if (((*(uint *)(puVar7 + -3) & 0xfff) != 0) && ((*puVar7 & 2) != 0)) {
              iVar8 = FUN_0056f430(uVar13,iVar11);
              if (-1 < iVar8) {
                uVar15 = FUN_0045c140(uVar13,iVar11,0);
                uStack_18 = uVar15;
                FUN_0040e1f0(param_2,&uStack_18,3);
              }
            }
            iVar11 = iVar11 + 1;
            puVar7 = puVar7 + 0x48;
          } while (iVar11 < 5);
          uVar13 = uVar13 + 1;
        } while ((int)uVar13 < 2);
      }
      uVar15 = CONCAT44(uStack_2c._4_4_,(uint)uStack_2c);
      iStack_24 = 0;
      if (*(short *)((int)&DAT_00a55d7e + iStack_34) != 0) {
        pbStack_1c = &DAT_00a55dc0 + iStack_34;
LAB_0040e565:
        bVar1 = *pbStack_1c;
        uVar2 = *(ushort *)(pbStack_1c + -0x40);
        uVar4 = uVar2 >> 8;
        uVar10 = (uint)(byte)uVar2;
        uVar13 = (bVar1 & 0xffffff0f) - 1;
        puVar7 = (ushort *)CONCAT22((short)((uint)puVar7 >> 0x10),uVar4);
        switch(uVar13) {
        case 0:
        case 1:
        case 3:
        case 4:
        case 5:
switchD_0040e594_caseD_0:
          uVar12 = uVar2 & 0xff;
          uVar3 = (uint)uVar4;
          if (((&DAT_00a55d74)[uVar3 * 0x24 + (uVar10 & 1) * 0x351] & 0xfff) == 0) break;
          if ((int)uStack_40 < 5) {
            puStack_20 = (ushort *)0x2;
            uStack_2c = uVar15;
            sVar6 = FUN_004022e0(*(ushort *)(&DAT_00a55d74 + uVar3 * 0x24 + (uVar10 & 1) * 0x351) &
                                 0xfff);
            uVar15 = uStack_2c;
            if (sVar6 == 0x52) {
              puStack_20 = (ushort *)0x5;
            }
            else if ((sVar6 == 0x2d9) || (sVar6 == 0x534)) {
              puStack_20 = (ushort *)0x4;
            }
          }
          uStack_2c = uVar15;
                    /* WARNING (jumptable): Sanity check requires truncation of jumptable */
                    /* WARNING: Could not find normalized switch variable to match jumptable */
          switch(bVar1) {
          case 0:
            goto switchD_0040e594_caseD_0;
          default:
            goto switchD_0040e627_caseD_1;
          case 2:
          case 6:
            puVar7 = puStack_20;
            if (4 < uVar4) {
              puVar7 = (ushort *)0x2;
            }
            uVar16 = FUN_0045c140(uVar10,uVar3,0);
            puVar17 = &uStack_2c;
            uVar15 = uStack_18;
            uStack_2c = uVar16;
            goto LAB_0040e68c;
          case 3:
            break;
          case 7:
          case 10:
          case 0xb:
            goto switchD_0040e7a6_caseD_1;
          case 8:
          case 0xc:
            goto switchD_0040e7a6_caseD_2;
          case 9:
            goto switchD_0040e7a6_caseD_3;
          }
        }
        goto switchD_0040e594_caseD_2;
      }
LAB_0040e6be:
      uStack_2c._0_4_ = 0;
      do {
        uVar15 = CONCAT44(uStack_2c._4_4_,(uint)uStack_2c);
        puStack_20 = (ushort *)0x0;
        puStack_38 = &DAT_00a55d7e + ((uint)uStack_2c & 1) * 0x6a2;
        do {
          if ((*(uint *)(puStack_38 + -5) & 0xfff) != 0) {
            iStack_24 = 0;
            if (*puStack_38 != 0) {
              puVar7 = puStack_38 + 0x21;
              do {
                uStack_2c._0_4_ = (uint)uVar15;
                uVar2 = *puVar7;
                uVar12 = puVar7[-0x20];
                uVar16 = FUN_0045c140((uint)uStack_2c,puStack_20,0);
                uStack_2c = uVar15;
                uVar13 = uStack_40;
                uStack_18 = uVar16;
                uVar15 = uStack_2c;
                if ((int)uStack_40 < 5) {
                  pbStack_1c = (byte *)0x2;
                  sVar6 = FUN_004022e0(*(ushort *)((int)&DAT_00a55d74 + iStack_34) & 0xfff);
                  uVar15 = uStack_2c;
                  if (sVar6 == 0x52) {
                    pbStack_1c = (byte *)0x5;
                  }
                  else if ((sVar6 == 0x2d9) || (sVar6 == 0x534)) {
                    pbStack_1c = (byte *)0x4;
                  }
                }
                switch((byte)uVar2 & 0xf) {
                case 1:
                case 4:
                case 5:
switchD_0040e7a6_caseD_1:
                  if (uVar12 == (ushort)CONCAT31((int3)uVar13,(undefined1)uStack_3c)) {
                    pbVar9 = pbStack_1c;
                    if (4 < (int)uVar13) {
                      pbVar9 = (byte *)0x1;
                    }
LAB_0040e7e5:
                    uStack_2c = uVar15;
                    FUN_0040e1f0(param_2,&uStack_18,pbVar9);
                    uVar15 = uStack_2c;
                  }
                  break;
                case 2:
                case 6:
switchD_0040e7a6_caseD_2:
                  if (uVar12 == (ushort)CONCAT31((int3)uVar13,(undefined1)uStack_3c)) {
                    pbVar9 = pbStack_1c;
                    if (4 < (int)uVar13) {
                      pbVar9 = (byte *)0x2;
                    }
                    goto LAB_0040e7e5;
                  }
                }
switchD_0040e7a6_caseD_3:
                iStack_24 = iStack_24 + 1;
                puVar7 = puVar7 + 1;
              } while (iStack_24 < (int)(uint)*puStack_38);
            }
            puVar7 = puStack_20;
            uStack_2c._0_4_ = (uint)uVar15;
            uVar5 = (uint)uStack_2c;
            if ((puStack_38[-2] & 2) != 0) {
              sVar6 = FUN_0056f6d0((uint)uStack_2c,puStack_20);
              uStack_2c = uVar15;
              iVar11 = iStack_34;
              uVar15 = uStack_2c;
              if (sVar6 == 1) {
                sVar6 = FUN_004022e0(*(ushort *)((int)&DAT_00a55d74 + iStack_34) & 0xfff);
                uVar15 = uStack_2c;
                if (((sVar6 == 0x148) && (((&DAT_00a55d7a)[iVar11] & 2) != 0)) &&
                   ((*(byte *)((int)&DAT_00a55e00 + iVar11) & 0x20) == 0)) {
                  uVar15 = FUN_0045c140(uVar5,puVar7,0);
                  uStack_10 = uVar15;
                  FUN_0040e1f0(param_2,&uStack_10,2);
                  uVar15 = uStack_2c;
                }
              }
            }
            uStack_2c = uVar15;
            iVar11 = FUN_0056f5c0(uVar5,puVar7,uStack_3c,uStack_40);
            uVar15 = uStack_2c;
            if (iVar11 != 0) {
              uVar15 = FUN_0045c140(uVar5,puVar7,0);
              uStack_8 = uVar15;
              FUN_0040e1f0(param_2,&uStack_8,5);
              uVar15 = uStack_2c;
            }
          }
          uStack_2c._4_4_ = (undefined4)((ulonglong)uVar15 >> 0x20);
          uStack_2c._0_4_ = (uint)uVar15;
          puStack_20 = (ushort *)((int)puStack_20 + 1);
          puStack_38 = puStack_38 + 0x48;
        } while ((int)puStack_20 < 0xb);
        uStack_2c._0_4_ = (uint)uStack_2c + 1;
      } while ((int)(uint)uStack_2c < 2);
    }
  }
  return;
switchD_0040e627_caseD_1:
  puVar7 = puStack_20;
  if (4 < uVar4) {
    puVar7 = (ushort *)0x1;
  }
  uVar15 = FUN_0045c140(uVar10,uVar3,0);
  puVar17 = &uStack_18;
LAB_0040e68c:
  uStack_18 = uVar15;
  FUN_0040e1f0(param_2,puVar17,puVar7);
  uVar15 = uStack_2c;
switchD_0040e594_caseD_2:
  uStack_2c._4_4_ = (undefined4)((ulonglong)uVar15 >> 0x20);
  pbStack_1c = pbStack_1c + 2;
  iStack_24 = iStack_24 + 1;
  if ((int)(uint)*(ushort *)((int)&DAT_00a55d7e + iStack_34) <= iStack_24) goto LAB_0040e6be;
  goto LAB_0040e565;
}


