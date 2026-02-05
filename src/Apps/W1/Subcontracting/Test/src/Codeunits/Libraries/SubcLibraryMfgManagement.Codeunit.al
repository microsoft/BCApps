// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Requisition;
#if CLEAN27
using Microsoft.Inventory.Setup;
#endif
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

codeunit 139984 "Subc. Library Mfg. Management"
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        UnitCostCalculation: Option Time,Units;

    procedure Initialize()
    begin
        CreateManufacturingSetup();
    end;

    local procedure CreateManufacturingSetup()
    var
        MfgSetup: Record "Manufacturing Setup";
#if CLEAN27
        InventorySetup: Record "Inventory Setup";
#endif
    begin
        if not MfgSetup.Get() then
            MfgSetup.Insert();
        MfgSetup.Validate(MfgSetup."Normal Starting Time", 080000T);
        MfgSetup.Validate(MfgSetup."Normal Ending Time", 230000T);
        MfgSetup.Validate(MfgSetup."Doc. No. Is Prod. Order No.", true);
        MfgSetup.Validate(MfgSetup."Cost Incl. Setup", true);
        MfgSetup.Validate(MfgSetup."Planning Warning", true);
        MfgSetup.Validate(MfgSetup."Dynamic Low-Level Code", true);
        MfgSetup."Simulated Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Planned Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Firm Planned Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Released Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Work Center Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Routing Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Production BOM Nos." := LibraryERM.CreateNoSeriesCode();
#if not CLEAN27
#pragma warning disable AL0432
        MfgSetup."Combined MPS/MRP Calculation" := true;
        Evaluate(MfgSetup."Default Safety Lead Time", '<1D>');
#pragma warning restore AL0432
        MfgSetup.Modify();
#else
        if not InventorySetup.Get() then begin
            InventorySetup.Init();
            InventorySetup.Insert();
            InventorySetup."Combined MPS/MRP Calculation" := true;
            Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
            InventorySetup.Modify();
        end;
#endif
    end;

    procedure CreateWorkCenterWithFixedCost(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10]; DirectUnitCost: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        WorkCenter.Modify(true);
    end;

    procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center"; DirectUnitCost: Decimal)
    var
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);
        CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, DirectUnitCost);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
    end;

    procedure CreateSubcontractorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create a Subcontractor Vendor.
        LibraryPurchase.CreateSubcontractor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateMachineCenter(var MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; FlushingMethod: Option)
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        MachineCenter: Record "Machine Center";
    begin
        // Create Machine Center with required fields where random is used, values not important for test.
        GenProductPostingGroup.FindFirst();
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Overhead Rate", 1);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        MachineCenter.Validate(Efficiency, 100);
        MachineCenter.Modify(true);
        MachineCenterNo := MachineCenter."No.";
    end;

    procedure CreateRouting(var RoutingNo: Code[20]; MachineCenterNo: Code[20]; MachineCenterNo2: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo2);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo2);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Create Routing Lines with required fields.
#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
    end;

    procedure AddProdOrderRoutingLine(ProductionOrder: Record "Production Order"; ProdOrderRoutingLineType: Option; MachineCenterNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        OperationNo: Code[10];
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Routing No.", ProductionOrder."Routing No.");
        ProdOrderRoutingLine.Validate("Routing Reference No.", SelectRoutingRefNo(ProductionOrder."No.", ProductionOrder."Routing No."));
        OperationNo := CopyStr(LibraryUtility.GenerateRandomCode(ProdOrderRoutingLine.FieldNo("Operation No."), Database::"Prod. Order Routing Line"), 1, 9);
        ProdOrderRoutingLine.Validate("Operation No.", OperationNo);
        ProdOrderRoutingLine.Insert(true);
        ProdOrderRoutingLine.Validate(Type, ProdOrderRoutingLineType);
        ProdOrderRoutingLine.Validate("No.", MachineCenterNo);
        ProdOrderRoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure SelectRoutingRefNo(ProductionOrderNo: Code[20]; ProdOrderRoutingNo: Code[20]): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingNo);
        ProdOrderRoutingLine.FindFirst();
        exit(ProdOrderRoutingLine."Routing Reference No.");
    end;

    procedure CreateLaborReqWkshTemplateAndNameAndUpdateSetup()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubMgmtSetup: Record "Subc. Management Setup";
    begin
        CreateReqWkshTemplate(ReqWkshTemplate, false);
        CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        SubMgmtSetup.Get();
        SubMgmtSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        SubMgmtSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
        SubMgmtSetup.Modify();
    end;

    procedure CreateReqWkshTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Recurring: Boolean)
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(
          Name,
          CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"),
            1,
            LibraryUtility.GetFieldLength(Database::"Req. Wksh. Template", ReqWkshTemplate.FieldNo(Name))));
        ReqWkshTemplate.Validate(Description, ReqWkshTemplate.Name);  // Validate Description as Name because value is not important.
        ReqWkshTemplate.Recurring := Recurring;
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::"For. Labor");
        ReqWkshTemplate.Validate("Page ID", Page::"Subcontracting Worksheet");
        ReqWkshTemplate.Insert(true);
    end;

    procedure CreateRequisitionWkshName(var RequisitionWkshName: Record "Requisition Wksh. Name"; WorksheetTemplateName: Text[10])
    begin
        // Create Requisition Wksh. Name with a random Name of String length less than 10.
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", WorksheetTemplateName);
        RequisitionWkshName.Validate(
          Name,
          CopyStr(
            LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
            1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);
    end;

    procedure CreateProdOrderRtngCommentLine(Stat: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingRefNo: Integer; RoutingNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";

        RecRef: RecordRef;
    begin
        ProdOrderRtngCommentLine.Init();
        ProdOrderRtngCommentLine.Status := Stat;
        ProdOrderRtngCommentLine."Prod. Order No." := ProdOrderNo;
        ProdOrderRtngCommentLine."Routing Reference No." := RoutingRefNo;
        ProdOrderRtngCommentLine."Routing No." := RoutingNo;
        ProdOrderRtngCommentLine."Operation No." := OperationNo;
        RecRef.GetTable(ProdOrderRtngCommentLine);
        ProdOrderRtngCommentLine.Validate(ProdOrderRtngCommentLine."Line No.", LibraryUtility.GetNewLineNo(RecRef, ProdOrderRtngCommentLine.FieldNo("Line No.")));
        ProdOrderRtngCommentLine.Insert(true);

        ProdOrderRtngCommentLine.Validate(
            ProdOrderRtngCommentLine.Comment,
            Format(ProdOrderRtngCommentLine."Prod. Order No.") + Format(ProdOrderRtngCommentLine."Routing Reference No.") + Format(ProdOrderRtngCommentLine."Line No."));
        ProdOrderRtngCommentLine.Modify(true);
    end;
}