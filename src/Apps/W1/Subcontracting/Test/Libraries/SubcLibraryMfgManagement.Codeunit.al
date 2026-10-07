// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
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
        LibraryInventory: Codeunit "Library - Inventory";
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
        InventorySetup: Record "Inventory Setup";
    begin
        if not MfgSetup.Get() then
            MfgSetup.Insert();
        MfgSetup.Validate("Normal Starting Time", 080000T);
        MfgSetup.Validate("Normal Ending Time", 230000T);
        MfgSetup.Validate("Doc. No. Is Prod. Order No.", true);
        MfgSetup.Validate("Cost Incl. Setup", true);
        MfgSetup.Validate("Planning Warning", true);
        MfgSetup.Validate("Dynamic Low-Level Code", true);
        MfgSetup."Simulated Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Planned Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Firm Planned Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Released Order Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Work Center Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Routing Nos." := LibraryERM.CreateNoSeriesCode();
        MfgSetup."Production BOM Nos." := LibraryERM.CreateNoSeriesCode();
        if not InventorySetup.Get() then begin
            InventorySetup.Init();
            InventorySetup.Insert();
            InventorySetup."Combined MPS/MRP Calculation" := true;
            Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
            InventorySetup.Modify();
        end;
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

    procedure CreateRoutingLineForMachineCenter(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; MachineCenterNo: Code[20])
    begin
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo);
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

    procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
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

    procedure CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        CreateReqWkshTemplate(ReqWkshTemplate, false);
        CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        ManufacturingSetup.Get();
        ManufacturingSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
        ManufacturingSetup.Modify();
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
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.Validate("Page ID", Page::"Subc. Subcontracting Worksheet");
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

    procedure PostConsumptionForComponent(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComponent: Record "Prod. Order Component"; ComponentItem: Record Item; Qty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateConsumptionJournalLine(
            ItemJournalBatch, ProdOrderLine, ComponentItem, WorkDate(),
            ProdOrderComponent."Location Code", '', Qty, 0);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    procedure PostConsumptionForAllComponents(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ComponentItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if ProdOrderComponent.FindSet() then
            repeat
                ComponentItem.Get(ProdOrderComponent."Item No.");
                ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");
                PostConsumptionForComponent(ProdOrderLine, ProdOrderComponent, ComponentItem, ProdOrderComponent."Expected Quantity");
            until ProdOrderComponent.Next() = 0;
    end;

    procedure PostOutputForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; Qty: Decimal)
    begin
        LibraryManufacturing.PostOutput(ProdOrderLine, Qty, WorkDate(), 0);
    end;

    /// <summary>
    /// Creates a subcontracting routing comment line for the specified routing operation.
    /// </summary>
    /// <param name="RoutingLine">The routing line whose routing and operation information is copied to the comment.</param>
    /// <param name="LineNo">The line number of the comment.</param>
    /// <param name="CommentDescription">The main description of the comment.</param>
    /// <param name="CommentDescription2">The additional description of the comment.</param>
    procedure CreateRoutingSubcComment(RoutingLine: Record "Routing Line"; LineNo: Integer; CommentDescription: Text[100]; CommentDescription2: Text[50])
    var
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
    begin
        SubcRoutingCommentLine.Init();
        SubcRoutingCommentLine."Routing No." := RoutingLine."Routing No.";
        SubcRoutingCommentLine."Version Code" := RoutingLine."Version Code";
        SubcRoutingCommentLine."Operation No." := RoutingLine."Operation No.";
        SubcRoutingCommentLine."Line No." := LineNo;
        SubcRoutingCommentLine.Validate(Description, CommentDescription);
        SubcRoutingCommentLine.Validate("Description 2", CommentDescription2);
        SubcRoutingCommentLine.Insert();
    end;

    /// <summary>
    /// Creates a subcontracting standard task comment line.
    /// </summary>
    /// <param name="StandardTaskCode">The standard task code for the comment.</param>
    /// <param name="LineNo">The line number of the comment.</param>
    /// <param name="CommentDescription">The main description of the comment.</param>
    /// <param name="CommentDescription2">The additional description of the comment.</param>
    procedure CreateStandardTaskComment(StandardTaskCode: Code[10]; LineNo: Integer; CommentDescription: Text[100]; CommentDescription2: Text[50])
    var
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
    begin
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTaskCode);
        SubcStandardTaskComment."Line No." := LineNo;
        SubcStandardTaskComment.Validate(Description, CommentDescription);
        SubcStandardTaskComment.Validate("Description 2", CommentDescription2);
        SubcStandardTaskComment.Insert();
    end;

    /// <summary>
    /// Creates a subcontracting production-order routing comment.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The production-order routing line for the comment.</param>
    /// <param name="LineNo">The line number of the comment.</param>
    /// <param name="CommentDescription">The main description of the comment.</param>
    /// <param name="CommentDescription2">The additional description of the comment.</param>
    procedure CreateProdOrderSubcComment(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; LineNo: Integer; CommentDescription: Text[100]; CommentDescription2: Text[50])
    var
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
    begin
        SubcProdRtngComment.Status := ProdOrderRoutingLine.Status;
        SubcProdRtngComment."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
        SubcProdRtngComment."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        SubcProdRtngComment."Routing No." := ProdOrderRoutingLine."Routing No.";
        SubcProdRtngComment."Operation No." := ProdOrderRoutingLine."Operation No.";
        SubcProdRtngComment."Line No." := LineNo;
        SubcProdRtngComment.Validate(Description, CommentDescription);
        SubcProdRtngComment.Validate("Description 2", CommentDescription2);
        SubcProdRtngComment.Insert();
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
        ProdOrderRtngCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, ProdOrderRtngCommentLine.FieldNo("Line No.")));
        ProdOrderRtngCommentLine.Insert(true);

        ProdOrderRtngCommentLine.Validate(Comment,
            Format(ProdOrderRtngCommentLine."Prod. Order No.") + Format(ProdOrderRtngCommentLine."Routing Reference No.") + Format(ProdOrderRtngCommentLine."Line No."));
        ProdOrderRtngCommentLine.Modify(true);
    end;
}