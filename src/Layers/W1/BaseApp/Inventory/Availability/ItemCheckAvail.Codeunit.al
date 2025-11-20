// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Environment.Configuration;

codeunit 311 "Item-Check Avail."
{
    Permissions = TableData "My Notifications" = rimd;

    trigger OnRun()
    begin
    end;

    var
        AvailableToPromise: Codeunit "Available to Promise";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        AssemblyLineDueDateGlobal: Date;
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        ItemLocationCode: Code[10];
        VariantCode: Code[10];
        NewItemNetChange: Decimal;
        OldItemNetChange: Decimal;
        OldItemNetResChange: Decimal;
        NewItemNetResChange: Decimal;
        ItemNetChange: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        InitialQtyAvailable: Decimal;
        UseOrderPromise: Boolean;
        GrossReq: Decimal;
        ReservedReq: Decimal;
        SchedRcpt: Decimal;
        ReservedRcpt: Decimal;
        EarliestAvailDate: Date;
        InventoryQty: Decimal;
        OldItemShipmentDate: Date;
        ContextInfo: Dictionary of [Text, Text];

#pragma warning disable AA0074
        Text000: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074
        NotificationMsg: Label 'The available inventory for item %1 is lower than the entered quantity at this location.', Comment = '%1=Item No.';
        DetailsTxt: Label 'Show details';
        ItemAvailabilityNotificationTxt: Label 'Item availability is low.';
        ItemAvailabilityNotificationDescriptionTxt: Label 'Show a warning when someone creates a sales order or sales invoice for an item that is out of stock.';
        DontShowAgainTxt: Label 'Don''t show again';

    procedure ItemJnlCheckLine(ItemJnlLine: Record "Item Journal Line") Rollback: Boolean
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          ItemJnlLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if ItemJnlLineShowWarning(ItemJnlLine) then
            Rollback := ShowAndHandleAvailabilityPage(ItemJnlLine.RecordId);
    end;

    procedure SalesLineCheck(SalesLine: Record "Sales Line") Rollback: Boolean
    var
        TempAsmHeader: Record "Assembly Header" temporary;
        TempAsmLine: Record "Assembly Line" temporary;
        ATOLink: Record "Assemble-to-Order Link";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineCheck(SalesLine, Rollback, IsHandled);
        if IsHandled then
            exit(Rollback);

        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          SalesLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if SalesLineShowWarning(SalesLine) then
            Rollback := ShowAndHandleAvailabilityPage(SalesLine.RecordId);

        OnSalesLineCheckOnAfterSalesLineShowWarning(SalesLine, Rollback);

        if not Rollback then
            if ATOLink.SalesLineCheckAvailShowWarning(SalesLine, TempAsmHeader, TempAsmLine) then
                Rollback := ShowAsmWarningYesNo(TempAsmHeader, TempAsmLine);
    end;

    procedure TransferLineCheck(TransLine: Record "Transfer Line") Rollback: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLineCheck(TransLine, Rollback, IsHandled);
        if IsHandled then
            exit(Rollback);
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          TransLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if TransferLineShowWarning(TransLine) then
            Rollback := ShowAndHandleAvailabilityPage(TransLine.RecordId);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServItemChackAvail', '25.0')]
    procedure ServiceInvLineCheck(ServInvLine: Record Microsoft.Service.Document."Service Line") Rollback: Boolean
    var
        ServItemCheckAvail: Codeunit "Serv. Item Check Avail.";
    begin
        exit(ServItemCheckAvail.ServiceInvLineCheck(ServInvLine));
    end;
#endif

    procedure JobPlanningLineCheck(JobPlanningLine: Record "Job Planning Line") Rollback: Boolean
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          JobPlanningLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if JobPlanningLineShowWarning(JobPlanningLine) then
            Rollback := ShowAndHandleAvailabilityPage(JobPlanningLine.RecordId);
    end;

    procedure AssemblyLineCheck(AssemblyLine: Record "Assembly Line") Rollback: Boolean
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          AssemblyLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if AsmOrderLineShowWarning(AssemblyLine) then
            Rollback := ShowAndHandleAvailabilityPage(AssemblyLine.RecordId);
    end;

    procedure ShowAsmWarningYesNo(var AsmHeader: Record "Assembly Header"; var AsmLine: Record "Assembly Line") Rollback: Boolean
    var
        AsmLineMgt: Codeunit "Assembly Line Management";
    begin
        Rollback := AsmLineMgt.ShowAvailability(false, AsmHeader, AsmLine);
    end;

    procedure ItemJnlLineShowWarning(ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        if not ShowWarningForThisItem(ItemJnlLine."Item No.") then
            exit(false);

        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Purchase, ItemJnlLine."Entry Type"::"Positive Adjmt.":
                ItemNetChange := ItemJnlLine.Quantity;
            ItemJnlLine."Entry Type"::Sale, ItemJnlLine."Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::Transfer:
                ItemNetChange := -ItemJnlLine.Quantity;
        end;

        IsHandled := false;
        OnAfterItemJnlLineShowWarning(ItemJnlLine, ItemNetChange, IsHandled);
        if IsHandled then
            exit(false);

        exit(
          ShowWarning(
            ItemJnlLine."Item No.",
            ItemJnlLine."Variant Code",
            ItemJnlLine."Location Code",
            ItemJnlLine."Unit of Measure Code",
            ItemJnlLine."Qty. per Unit of Measure",
            ItemNetChange,
            0,
            0D,
            0D));
    end;

    procedure SalesLineShowWarning(SalesLine: Record "Sales Line"): Boolean
    var
        OldSalesLine: Record "Sales Line";
        CompanyInfo: Record "Company Information";
        LookAheadDate: Date;
        IsHandled: Boolean;
        IsWarning: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineShowWarning(SalesLine, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        if SalesLine."Drop Shipment" then
            exit(false);
        if SalesLine.IsNonInventoriableItem() then
            exit(false);
        if SalesLine.FullQtyIsForAsmToOrder() then
            exit(false);
        if not ShowWarningForThisItem(SalesLine."No.") then
            exit(false);

        Clear(AvailableToPromise);

        OldItemNetChange := 0;
        OldSalesLine := SalesLine;
        if OldSalesLine.Find() then begin // Find previous quantity within Check-Avail. Period
            CompanyInfo.SetLoadFields("Check-Avail. Period Calc.", "Check-Avail. Time Bucket");
            CompanyInfo.Get();
            LookAheadDate :=
              AvailableToPromise.GetForwardPeriodEndDate(
                CompanyInfo."Check-Avail. Period Calc.", CompanyInfo."Check-Avail. Time Bucket", SalesLine."Shipment Date");
            if (OldSalesLine."Document Type" = OldSalesLine."Document Type"::Order) and
               (OldSalesLine."No." = SalesLine."No.") and
               (OldSalesLine."Variant Code" = SalesLine."Variant Code") and
               (OldSalesLine."Location Code" = SalesLine."Location Code") and
               (OldSalesLine."Bin Code" = SalesLine."Bin Code") and
               not OldSalesLine."Drop Shipment" and
               (OldSalesLine."Shipment Date" <= LookAheadDate)
            then begin
                IsHandled := false;
                OnSalesLineShowWarningOnAfterFindingPrevSalesLineQtyWithinPeriod(SalesLine, OldSalesLine, IsHandled);
                if not IsHandled then
                    if OldSalesLine."Shipment Date" > SalesLine."Shipment Date" then
                        AvailableToPromise.SetChangedSalesLine(OldSalesLine)
                    else begin
                        OldItemNetChange := -OldSalesLine."Outstanding Qty. (Base)";
                        OldSalesLine.CalcFields("Reserved Qty. (Base)");
                        OldItemNetResChange := -OldSalesLine."Reserved Qty. (Base)";
                    end;
            end;
        end;

        NewItemNetResChange := -(SalesLine."Qty. to Asm. to Order (Base)" - OldSalesLine.QtyBaseOnATO());

        if SalesLine."Document Type" = SalesLine."Document Type"::Order then
            UseOrderPromise := true;
        IsHandled := false;
        OnSalesLineShowWarningOnBeforeShowWarning(SalesLine, ContextInfo, OldSalesLine, IsWarning, IsHandled, OldItemNetChange);
        if IsHandled then
            exit(IsWarning);

        exit(
          ShowWarning(
            SalesLine."No.",
            SalesLine."Variant Code",
            SalesLine."Location Code",
            SalesLine."Unit of Measure Code",
            SalesLine."Qty. per Unit of Measure",
            -SalesLine."Outstanding Quantity",
            OldItemNetChange,
            SalesLine."Shipment Date",
            OldSalesLine."Shipment Date"));
    end;

    procedure ShowWarning(ItemNoArg: Code[20]; ItemVariantCodeArg: Code[10]; ItemLocationCodeArg: Code[10]; UnitOfMeasureCodeArg: Code[10]; QtyPerUnitOfMeasureArg: Decimal; NewItemNetChangeArg: Decimal; OldItemNetChangeArg: Decimal; ShipmentDateArg: Date; OldShipmentDateArg: Date) Result: Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        ItemNo := ItemNoArg;
        UnitOfMeasureCode := UnitOfMeasureCodeArg;
        QtyPerUnitOfMeasure := QtyPerUnitOfMeasureArg;
        NewItemNetChange := NewItemNetChangeArg;
        OldItemNetChange := ConvertQty(OldItemNetChangeArg);
        OldItemShipmentDate := OldShipmentDateArg;
        ItemLocationCode := ItemLocationCodeArg;
        VariantCode := ItemVariantCodeArg;

        if NewItemNetChange >= 0 then
            exit(false);

        SetFilterOnItem(Item, ItemNo, ItemVariantCodeArg, ItemLocationCode, ShipmentDateArg);
        Calculate(Item);

        IsHandled := false;
        OnShowWarningOnAfterCalculate(ItemNo, InventoryQty, ItemNetChange, InitialQtyAvailable, OldItemNetResChange, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(InitialQtyAvailable + ItemNetChange < 0);
    end;

    local procedure SetFilterOnItem(var Item: Record Item; ItemNo: Code[20]; ItemVariantCode: Code[10]; ItemLocationCode: Code[10]; ShipmentDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFilterOnItem(Item, ItemNo, ItemVariantCode, ItemLocationCode, ShipmentDate, UseOrderPromise, IsHandled, UnitOfMeasureCode);
        if IsHandled then
            exit;

        Item.Get(ItemNo);
        Item.SetRange("No.", ItemNo);
        Item.SetRange("Variant Filter", ItemVariantCode);
        Item.SetRange("Location Filter", ItemLocationCode);
        Item.SetRange("Drop Shipment Filter", false);
        if UseOrderPromise then
            Item.SetRange("Date Filter", 0D, ShipmentDate)
        else
            Item.SetRange("Date Filter", 0D, WorkDate());
    end;

    local procedure Calculate(var Item: Record Item)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        QtyAvailToPromise(Item, CompanyInfo);
        EarliestAvailDate := EarliestAvailabilityDate(Item, CompanyInfo);

        if not UseOrderPromise then
            SchedRcpt := 0;

        OldItemNetResChange := ConvertQty(OldItemNetResChange);
        NewItemNetResChange := ConvertQty(NewItemNetResChange);

        ItemNetChange := 0;
        if Item."No." = ItemNo then begin
            ItemNetChange := NewItemNetChange;
            if GrossReq + OldItemNetChange >= 0 then
                GrossReq := GrossReq + OldItemNetChange;
        end;

        OnCalculateOnBeforeCalcInitialQtyAvailable(Item, SchedRcpt, ReservedRcpt, GrossReq, ReservedReq, OldItemNetResChange, NewItemNetResChange, ContextInfo, InventoryQty);
        InitialQtyAvailable :=
          InventoryQty +
          (SchedRcpt - ReservedRcpt) - (GrossReq - ReservedReq) -
          NewItemNetResChange;

        OnAfterCalculate(Item, InitialQtyAvailable, OldItemNetChange, QtyPerUnitOfMeasure, ContextInfo);
    end;

    local procedure QtyAvailToPromise(var Item: Record Item; CompanyInfo: Record "Company Information")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeQtyAvailToPromise(Item, CompanyInfo, InventoryQty, GrossReq, ReservedReq, OldItemNetResChange, SchedRcpt, ReservedRcpt, IsHandled);
        if IsHandled then
            exit;

        AvailableToPromise.CalcQtyAvailabletoPromise(Item, GrossReq, SchedRcpt, CheckAvailabilityDate(Item, AssemblyLineDueDateGlobal),
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc.");
        InventoryQty := ConvertQty(AvailableToPromise.CalcAvailableInventory(Item) - OldItemNetResChange);
        GrossReq := ConvertQty(GrossReq);
        ReservedReq := ConvertQty(AvailableToPromise.CalcReservedRequirement(Item) + OldItemNetResChange);
        SchedRcpt := ConvertQty(SchedRcpt);
        ReservedRcpt := ConvertQty(AvailableToPromise.CalcReservedReceipt(Item));
    end;

    local procedure EarliestAvailabilityDate(var Item: Record Item; CompanyInfo: Record "Company Information"): Date
    var
        AvailableQty: Decimal;
        NewItemNetChangeBase: Decimal;
        OldItemNetChangeBase: Decimal;
    begin
        NewItemNetChangeBase := ConvertQtyToBaseQty(NewItemNetChange);
        OldItemNetChangeBase := ConvertQtyToBaseQty(OldItemNetChange);
        exit(
          AvailableToPromise.CalcEarliestAvailabilityDate(
            Item, -NewItemNetChangeBase, Item.GetRangeMax("Date Filter"), -OldItemNetChangeBase, OldItemShipmentDate, AvailableQty,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc."));
    end;

    local procedure ConvertQty(Qty: Decimal) Result: Decimal
    begin
        if QtyPerUnitOfMeasure = 0 then
            QtyPerUnitOfMeasure := 1;
        Result := Round(Qty / QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision());
        OnAfterConvertQty(ItemNo, Qty, QtyPerUnitOfMeasure, Result);
    end;

    local procedure ConvertQtyToBaseQty(Qty: Decimal) Result: Decimal
    begin
        if QtyPerUnitOfMeasure = 0 then
            QtyPerUnitOfMeasure := 1;
        Result := Round(Qty * QtyPerUnitOfMeasure, UOMMgt.QtyRndPrecision());
        OnAfterConvertQtyToBaseQty(ItemNo, Qty, QtyPerUnitOfMeasure, Result);
    end;

    procedure TransferLineShowWarning(TransLine: Record "Transfer Line") IsWarning: Boolean
    var
        OldTransLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferLineShowWarning(TransLine, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        if not ShowWarningForThisItem(TransLine."Item No.") then
            exit(false);

        UseOrderPromise := true;

        OldTransLine := TransLine;
        if OldTransLine.Find() then // Find previous quantity
            if (OldTransLine."Item No." = TransLine."Item No.") and
               (OldTransLine."Variant Code" = TransLine."Variant Code") and
               (OldTransLine."Transfer-from Code" = TransLine."Transfer-from Code")
            then begin
                OldItemNetChange := -OldTransLine."Outstanding Qty. (Base)";
                OldTransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                OldItemNetResChange := -OldTransLine."Reserved Qty. Outbnd. (Base)";
            end;

        IsHandled := false;
        OnTransferLineShowWarningOnBeforeShowWarning(TransLine, ContextInfo, OldTransLine, OldItemNetChange, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        exit(
          ShowWarning(
            TransLine."Item No.",
            TransLine."Variant Code",
            TransLine."Transfer-from Code",
            TransLine."Unit of Measure Code",
            TransLine."Qty. per Unit of Measure",
            -TransLine."Outstanding Quantity",
            OldItemNetChange,
            TransLine."Shipment Date",
            OldTransLine."Shipment Date"));
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServItemChackAvail', '25.0')]
    procedure ServiceInvLineShowWarning(ServLine: Record Microsoft.Service.Document."Service Line") IsWarning: Boolean
    var
        ServItemCheckAvail: Codeunit "Serv. Item Check Avail.";
    begin
        exit(ServItemCheckAvail.ServiceInvLineShowWarning(ServLine));
    end;
#endif

    procedure JobPlanningLineShowWarning(JobPlanningLine: Record "Job Planning Line") IsWarning: Boolean
    var
        OldJobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        if not ShowWarningForThisItem(JobPlanningLine."No.") then
            exit(false);

        OldItemNetChange := 0;

        OldJobPlanningLine := JobPlanningLine;

        if OldJobPlanningLine.Find() then // Find previous quantity
            if (OldJobPlanningLine.Type = OldJobPlanningLine.Type::Item) and
               (OldJobPlanningLine."No." = JobPlanningLine."No.") and
               (OldJobPlanningLine."Variant Code" = JobPlanningLine."Variant Code") and
               (OldJobPlanningLine."Location Code" = JobPlanningLine."Location Code") and
               (OldJobPlanningLine."Bin Code" = JobPlanningLine."Bin Code")
            then begin
                IsHandled := false;
                OnJobPlanningLineShowWarningOnAfterFindingPrevJobPlanningLineQtyWithinPeriod(JobPlanningLine, OldJobPlanningLine, IsHandled);
                if not IsHandled then begin
                    OldItemNetChange := -OldJobPlanningLine."Quantity (Base)";
                    OldJobPlanningLine.CalcFields("Reserved Qty. (Base)");
                    OldItemNetResChange := -OldJobPlanningLine."Reserved Qty. (Base)";
                end;
            end;

        UseOrderPromise := true;
        IsHandled := false;
        OnJobPlanningLineShowWarningOnBeforeShowWarning(JobPlanningLine, ContextInfo, OldJobPlanningLine, OldItemNetChange, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        exit(
          ShowWarning(
            JobPlanningLine."No.",
            JobPlanningLine."Variant Code",
            JobPlanningLine."Location Code",
            JobPlanningLine."Unit of Measure Code",
            JobPlanningLine."Qty. per Unit of Measure",
            -JobPlanningLine."Remaining Qty.",
            OldItemNetChange,
            JobPlanningLine."Planning Date",
            OldJobPlanningLine."Planning Date"));
    end;

    procedure AsmOrderLineShowWarning(AssemblyLine: Record "Assembly Line") IsWarning: Boolean
    var
        OldAssemblyLine: Record "Assembly Line";
        ShouldCheckQty, IsHandled : Boolean;
    begin
        if not ShowWarningForThisItem(AssemblyLine."No.") then
            exit(false);

        Clear(AvailableToPromise);

        OldItemNetChange := 0;

        OldAssemblyLine := AssemblyLine;
        AssemblyLineDueDateGlobal := OldAssemblyLine."Due Date";

        if OldAssemblyLine.Find() then begin // Find previous quantity
            ShouldCheckQty :=
               (OldAssemblyLine."Document Type" = OldAssemblyLine."Document Type"::Order) and
               (OldAssemblyLine.Type = OldAssemblyLine.Type::Item) and
               (OldAssemblyLine."No." = AssemblyLine."No.") and
               (OldAssemblyLine."Variant Code" = AssemblyLine."Variant Code") and
               (OldAssemblyLine."Location Code" = AssemblyLine."Location Code") and
               (OldAssemblyLine."Bin Code" = AssemblyLine."Bin Code");
            OnAsmOrderLineShowWarningOnAfterFindPreviousAssemblyOrderLineWithinPeriod(AssemblyLine, OldAssemblyLine, ShouldCheckQty, OldItemNetChange, OldItemNetResChange);

            if ShouldCheckQty then
                if OldAssemblyLine."Due Date" > AssemblyLine."Due Date" then
                    AvailableToPromise.SetChangedAsmLine(OldAssemblyLine)
                else begin
                    OldItemNetChange := -OldAssemblyLine."Remaining Quantity (Base)";
                    OldAssemblyLine.CalcFields("Reserved Qty. (Base)");
                    OldItemNetResChange := -OldAssemblyLine."Reserved Qty. (Base)";
                end;
        end;

        UseOrderPromise := true;
        IsHandled := false;
        OnAsmOrderLineShowWarningOnBeforeShowWarning(AssemblyLine, ContextInfo, OldAssemblyLine, OldItemNetChange, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        exit(
          ShowWarning(
            AssemblyLine."No.",
            AssemblyLine."Variant Code",
            AssemblyLine."Location Code",
            AssemblyLine."Unit of Measure Code",
            AssemblyLine."Qty. per Unit of Measure",
            -AssemblyLine."Remaining Quantity",
            OldItemNetChange,
            AssemblyLine."Due Date",
            OldAssemblyLine."Due Date"));
    end;

    procedure AsmOrderCalculate(AssemblyHeader: Record "Assembly Header"; var InventoryQty2: Decimal; var GrossReq2: Decimal; var ReservedReq2: Decimal; var SchedRcpt2: Decimal; var ReservedRcpt2: Decimal)
    var
        OldAssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        CompanyInfo: Record "Company Information";
        IsHandled: Boolean;
    begin
        UseOrderPromise := true;

        if AssemblyHeader."Due Date" = 0D then
            AssemblyHeader."Due Date" := WorkDate();
        SetFilterOnItem(Item, AssemblyHeader."Item No.", AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Due Date");
        CompanyInfo.Get();
        QtyAvailToPromise(Item, CompanyInfo);

        OldAssemblyHeader := AssemblyHeader;
        if OldAssemblyHeader.Find() then
            // Find previous quantity
            if (OldAssemblyHeader."Document Type" = OldAssemblyHeader."Document Type"::Order) and
               (OldAssemblyHeader."No." = AssemblyHeader."No.") and
               (OldAssemblyHeader."Item No." = AssemblyHeader."Item No.") and
               (OldAssemblyHeader."Variant Code" = AssemblyHeader."Variant Code") and
               (OldAssemblyHeader."Location Code" = AssemblyHeader."Location Code") and
               (OldAssemblyHeader."Bin Code" = AssemblyHeader."Bin Code")
            then begin
                IsHandled := false;
                OnAsmOrderCalculateOnAfterFindingPrevAsmOrderCalculateWithinPeriod(AssemblyHeader, OldAssemblyHeader, IsHandled);
                if not IsHandled then begin
                    OldAssemblyHeader.CalcFields("Reserved Qty. (Base)");
                    SchedRcpt :=
                      SchedRcpt - ConvertQty(OldAssemblyHeader."Remaining Quantity (Base)" - OldAssemblyHeader."Reserved Qty. (Base)");
                end;
            end;
        FetchCalculation2(InventoryQty2, GrossReq2, ReservedReq2, SchedRcpt2, ReservedRcpt2);
    end;

    procedure FetchCalculation(var ItemNo2: Code[20]; var UnitOfMeasureCode2: Code[10]; var InventoryQty2: Decimal; var GrossReq2: Decimal; var ReservedReq2: Decimal; var SchedRcpt2: Decimal; var ReservedRcpt2: Decimal; var CurrentQuantity2: Decimal; var CurrentReservedQty2: Decimal; var TotalQuantity2: Decimal; var EarliestAvailDate2: Date)
    begin
        ItemNo2 := ItemNo;
        UnitOfMeasureCode2 := UnitOfMeasureCode;
        FetchCalculation2(InventoryQty2, GrossReq2, ReservedReq2, SchedRcpt2, ReservedRcpt2);
        CurrentQuantity2 := -NewItemNetChange;
        CurrentReservedQty2 := -(NewItemNetResChange + OldItemNetResChange);
        TotalQuantity2 := InitialQtyAvailable + ItemNetChange;
        EarliestAvailDate2 := EarliestAvailDate;
    end;

    local procedure FetchCalculation2(var InventoryQty2: Decimal; var GrossReq2: Decimal; var ReservedReq2: Decimal; var SchedRcpt2: Decimal; var ReservedRcpt2: Decimal)
    begin
        InventoryQty2 := InventoryQty;
        GrossReq2 := GrossReq;
        ReservedReq2 := ReservedReq;
        SchedRcpt2 := SchedRcpt;
        ReservedRcpt2 := ReservedRcpt;
    end;

    procedure RaiseUpdateInterruptedError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRaiseUpdateInterruptedError(IsHandled, ContextInfo);
        if IsHandled then
            exit;

        Error(Text000);
    end;

    procedure ShowAndHandleAvailabilityPage(RecordId: RecordID) Rollback: Boolean
    var
        ItemNo2: Code[20];
        UnitOfMeasureCode2: Code[10];
        InventoryQty2: Decimal;
        GrossReq2: Decimal;
        ReservedReq2: Decimal;
        SchedRcpt2: Decimal;
        ReservedRcpt2: Decimal;
        CurrentQuantity2: Decimal;
        CurrentReservedQty2: Decimal;
        TotalQuantity2: Decimal;
        EarliestAvailDate2: Date;
    begin
        if not GuiAllowed then
            exit(false);

        FetchCalculation(
          ItemNo2, UnitOfMeasureCode2, InventoryQty2,
          GrossReq2, ReservedReq2, SchedRcpt2, ReservedRcpt2,
          CurrentQuantity2, CurrentReservedQty2, TotalQuantity2, EarliestAvailDate2);
        Rollback := CreateAndSendNotification(UnitOfMeasureCode2, InventoryQty2,
            GrossReq2, ReservedReq2, SchedRcpt2, ReservedRcpt2,
            CurrentQuantity2, CurrentReservedQty2, TotalQuantity2, EarliestAvailDate2, RecordId, ItemLocationCode);

        OnAfterShowAndHandleAvailabilityPage(ItemNo2, UnitOfMeasureCode2, InventoryQty2, GrossReq2, ReservedReq2, SchedRcpt2, ReservedRcpt2, CurrentQuantity2, CurrentReservedQty2, TotalQuantity2, EarliestAvailDate2, Rollback);
    end;

    procedure ShowNotificationDetails(AvailabilityCheckNotification: Notification)
    var
        ItemAvailabilityCheck: Page "Item Availability Check";
    begin
        ItemAvailabilityCheck.InitializeFromNotification(AvailabilityCheckNotification);
        ItemAvailabilityCheck.SetHeading(AvailabilityCheckNotification.Message);
        ItemAvailabilityCheck.RunModal();
    end;

    local procedure CreateAndSendNotification(UnitOfMeasureCode: Code[20]; InventoryQty: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity: Decimal; EarliestAvailDate: Date; RecordId: RecordID; LocationCode: Code[10]) Rollback: Boolean
    var
        ItemAvailabilityCheck: Page "Item Availability Check";
        AvailabilityCheckNotification: Notification;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAndSendNotification(
            ItemNo, UnitOfMeasureCode, InventoryQty, GrossReq, ReservedReq, SchedRcpt, ReservedRcpt, CurrentQuantity,
            CurrentReservedQty, TotalQuantity, EarliestAvailDate, RecordId, ItemLocationCode, ContextInfo, Rollback, IsHandled);
        if IsHandled then
            exit(Rollback);

        AvailabilityCheckNotification.Id(CreateGuid());
        AvailabilityCheckNotification.Message(StrSubstNo(NotificationMsg, ItemNo));
        AvailabilityCheckNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        AvailabilityCheckNotification.AddAction(DetailsTxt, CODEUNIT::"Item-Check Avail.", 'ShowNotificationDetails');
        AvailabilityCheckNotification.AddAction(DontShowAgainTxt, CODEUNIT::"Item-Check Avail.", 'DeactivateNotification');
        ItemAvailabilityCheck.PopulateDataOnNotification(AvailabilityCheckNotification, ItemNo, UnitOfMeasureCode,
          InventoryQty, GrossReq, ReservedReq, SchedRcpt, ReservedRcpt, CurrentQuantity, CurrentReservedQty,
          TotalQuantity, EarliestAvailDate, LocationCode);
        ItemAvailabilityCheck.PopulateDataOnNotification(AvailabilityCheckNotification, 'VariantCode', VariantCode);
        NotificationLifecycleMgt.SendNotificationWithAdditionalContext(
          AvailabilityCheckNotification, RecordId, GetItemAvailabilityNotificationId());
        exit(false);
    end;

    procedure ShowWarningForThisItem(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
        ShowWarning: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowWarningForThisItemOnBeforeItemGet(ItemNo, ShowWarning, IsHandled);
        if IsHandled then
            exit(ShowWarning);

        Item.SetLoadFields(Type, "Stockout Warning");
        if not Item.Get(ItemNo) then
            exit(false);

        IsHandled := false;
        OnBeforeShowWarningForThisItem(Item, ShowWarning, IsHandled);
        if IsHandled then
            exit(ShowWarning);

        if Item.IsNonInventoriableType() then
            exit(false);

        if not IsItemAvailabilityNotificationEnabled(Item) then
            exit(false);

        case Item."Stockout Warning" of
            Item."Stockout Warning"::No:
                exit(false);
            Item."Stockout Warning"::Yes:
                exit(true);
            Item."Stockout Warning"::Default:
                begin
                    SalesSetup.Get();
                    if SalesSetup."Stockout Warning" then
                        exit(true);
                    exit(false);
                end;
        end;
    end;

    procedure InvtDocCheckLine(InvtDocLine: Record "Invt. Document Line") Rollback: Boolean
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecordWithAdditionalContext(
          InvtDocLine.RecordId, GetItemAvailabilityNotificationId(), true);
        if ItemDocLineShowWarning(InvtDocLine) then
            Rollback := ShowAndHandleAvailabilityPage(InvtDocLine.RecordId);
    end;

    procedure ItemDocLineShowWarning(InvtDocLine: Record "Invt. Document Line") IsWarning: Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        SalesSetup.Get();
        if not SalesSetup."Stockout Warning" then
            exit(false);
        case InvtDocLine."Document Type" of
            InvtDocLine."Document Type"::Receipt:
                ItemNetChange := InvtDocLine.Quantity;
            InvtDocLine."Document Type"::Shipment:
                ItemNetChange := -InvtDocLine.Quantity;
        end;

        IsHandled := false;
        OnItemDocLineShowWarningOnBeforeShowWarning(InvtDocLine, ContextInfo, OldItemNetChange, IsWarning, IsHandled);
        if IsHandled then
            exit(IsWarning);

        exit(
          ShowWarning(
            InvtDocLine."Item No.",
            InvtDocLine."Variant Code",
            InvtDocLine."Location Code",
            InvtDocLine."Unit of Measure Code",
            InvtDocLine."Qty. per Unit of Measure",
            ItemNetChange,
            0,
            0D,
            0D));
    end;

    procedure GetItemAvailabilityNotificationId(): Guid
    begin
        exit('2712AD06-C48B-4C20-820E-347A60C9AD00');
    end;

    procedure DeactivateNotification(SetupNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        // Insert notification in case the My Notifications page has not been opened yet
        OnInitializingNotificationWithDefaultState();

        MyNotifications.Disable(GetItemAvailabilityNotificationId())
    end;

    local procedure IsItemAvailabilityNotificationEnabled(Item: Record Item): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabledForRecord(GetItemAvailabilityNotificationId(), Item));
    end;

    procedure SetUseOrderPromise(NewUseOrderPromise: Boolean)
    begin
        UseOrderPromise := NewUseOrderPromise;
    end;

    local procedure CheckAvailabilityDate(var Item: Record Item; AssemblyLineDueDate: Date): Date
    begin
        if AssemblyLineDueDate = 0D then
            exit(Item.GetRangeMax("Date Filter"))
        else
            exit(0D);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(var Item: Record Item; var InitialQtyAvailable: Decimal; OldItemNetChange: Decimal; QtyPerUnitOfMeasure: Decimal; var ContextInfo: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertQty(ItemNo: Code[20]; Qty: Decimal; var QtyPerUnitOfMeasure: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertQtyToBaseQty(ItemNo: Code[20]; QtyBase: Decimal; var QtyPerUnitOfMeasure: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJnlLineShowWarning(var ItemJournalLine: Record "Item Journal Line"; var ItemNetChange: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeQtyAvailToPromise(var Item: Record Item; var CompanyInfo: Record "Company Information"; var InventoryQty: Decimal; var GrossReq: Decimal; var ReservedReq: Decimal; var OldItemNetResChange: Decimal; var SchedRcpt: Decimal; var ReservedRcpt: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAndSendNotification(ItemNo: Code[20]; UnitOfMeasureCode: Code[20]; InventoryQty: Decimal; GrossReq: Decimal; ReservedReq: Decimal; SchedRcpt: Decimal; ReservedRcpt: Decimal; CurrentQuantity: Decimal; CurrentReservedQty: Decimal; TotalQuantity: Decimal; EarliestAvailDate: Date; RecordId: RecordID; LocationCode: Code[10]; ContextInfo: Dictionary of [Text, Text]; var Rollback: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRaiseUpdateInterruptedError(var IsHandled: Boolean; ContextInfo: Dictionary of [Text, Text])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSalesLineCheck(SalesLine: Record "Sales Line"; var Rollback: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineShowWarning(SalesLine: Record "Sales Line"; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFilterOnItem(var Item: Record Item; ItemNo: Code[20]; ItemVariantCode: Code[10]; ItemLocationCode: Code[10]; ShipmentDate: Date; UseOrderPromise: Boolean; var IsHandled: Boolean; UnitOfMeasureCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWarningForThisItem(Item: Record Item; var ShowWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWarningForThisItemOnBeforeItemGet(ItemNo: Code[20]; var ShowWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineCheck(TransferLine: Record "Transfer Line"; var Rollback: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineShowWarning(TransferLine: Record "Transfer Line"; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeServiceInvLineCheck(ServInvLine: Record Microsoft.Service.Document."Service Line"; var Rollback: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeServiceInvLineCheck(ServInvLine, Rollback, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServItemAvailMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceInvLineCheck(ServInvLine: Record Microsoft.Service.Document."Service Line"; var Rollback: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAsmOrderLineShowWarningOnBeforeShowWarning(AssemblyLine: Record "Assembly Line"; var ContextInfo: Dictionary of [Text, Text]; OldAssemblyLine: Record "Assembly Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemDocLineShowWarningOnBeforeShowWarning(InvtDocLine: Record "Invt. Document Line"; var ContextInfo: Dictionary of [Text, Text]; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineShowWarningOnBeforeShowWarning(JobPlanningLine: Record "Job Planning Line"; var ContextInfo: Dictionary of [Text, Text]; OldJobPlanningLine: Record "Job Planning Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineShowWarningOnBeforeShowWarning(SalesLine: Record "Sales Line"; var ContextInfo: Dictionary of [Text, Text]; OldSalesLine: Record "Sales Line"; var IsWarning: Boolean; var IsHandled: Boolean; var OldItemNetChange: Decimal)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnServiceInvLineShowWarningOnBeforeShowWarning(ServLine: Record Microsoft.Service.Document."Service Line"; var ContextInfo: Dictionary of [Text, Text]; OldServLine: Record Microsoft.Service.Document."Service Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
        OnServiceInvLineShowWarningOnBeforeShowWarning(ServLine, ContextInfo, OldServLine, OldItemNetChange, IsWarning, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServItemAvailMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceInvLineShowWarningOnBeforeShowWarning(ServLine: Record Microsoft.Service.Document."Service Line"; var ContextInfo: Dictionary of [Text, Text]; OldServLine: Record Microsoft.Service.Document."Service Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineShowWarningOnBeforeShowWarning(TransLine: Record "Transfer Line"; var ContextInfo: Dictionary of [Text, Text]; OldTransLine: Record "Transfer Line"; var OldItemNetChange: Decimal; var IsWarning: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeCalcInitialQtyAvailable(Item: Record Item; var SchedRcpt: Decimal; var ReservedRcpt: Decimal; var GrossReq: Decimal; var ReservedReq: Decimal; OldItemNetResChange: Decimal; NewItemNetResChange: Decimal; ContextInfo: Dictionary of [Text, Text]; var InventoryQty: Decimal)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure OnInitializingNotificationWithDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefaultWithTableNum(GetItemAvailabilityNotificationId(),
          ItemAvailabilityNotificationTxt,
          ItemAvailabilityNotificationDescriptionTxt,
          DATABASE::Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowWarningOnAfterCalculate(ItemNo: Code[20]; InventoryQty: Decimal; ItemNetChange: Decimal; InitialQtyAvailable: Decimal; OldItemNetResChange: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowAndHandleAvailabilityPage(ItemNo2: Code[20]; UnitOfMeasureCode2: Code[10]; InventoryQty2: Decimal; GrossReq2: Decimal; ReservedReq2: Decimal; SchedRcpt2: Decimal; ReservedRcpt2: Decimal; CurrentQuantity2: Decimal; CurrentReservedQty2: Decimal; TotalQuantity2: Decimal; EarliestAvailDate2: Date; var Rollback: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnServiceInvLineShowWarningOnAfterFindingPrevServiceLineQtyWithinPeriod(ServiceLine: Record Microsoft.Service.Document."Service Line"; OldServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnServiceInvLineShowWarningOnAfterFindingPrevServiceLineQtyWithinPeriod(ServiceLine, OldServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit ServItemAvailMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnServiceInvLineShowWarningOnAfterFindingPrevServiceLineQtyWithinPeriod(ServiceLine: Record Microsoft.Service.Document."Service Line"; OldServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineShowWarningOnAfterFindingPrevSalesLineQtyWithinPeriod(SalesLine: Record "Sales Line"; OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAsmOrderCalculateOnAfterFindingPrevAsmOrderCalculateWithinPeriod(AssemblyHeader: Record "Assembly Header"; OldAssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobPlanningLineShowWarningOnAfterFindingPrevJobPlanningLineQtyWithinPeriod(JobPlanningLine: Record "Job Planning Line"; OldJobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineCheckOnAfterSalesLineShowWarning(var SalesLine: Record "Sales Line"; var Rollback: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAsmOrderLineShowWarningOnAfterFindPreviousAssemblyOrderLineWithinPeriod(AssemblyLine: Record "Assembly Line"; OldAssemblyLine: Record "Assembly Line"; var ShouldCheckQty: Boolean; var OldItemNetChange: Decimal; var OldItemNetResChange: Decimal);
    begin
    end;
}

