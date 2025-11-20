// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;

codeunit 333 "Req. Wksh.-Make Order"
{
    Permissions = TableData "Sales Line" = m;
    TableNo = "Requisition Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if PlanningResiliency then
            Rec.LockTable();

        CarryOutReqLineAction(Rec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Worksheet Name                     #1##########\\';
        Text001: Label 'Checking worksheet lines           #2######\';
        Text002: Label 'Creating purchase orders           #3######\';
        Text003: Label 'Creating purchase lines            #4######\';
        Text004: Label 'Updating worksheet lines           #5######';
        Text005: Label 'Deleting worksheet lines           #5######';
#pragma warning restore AA0470
        Text006: Label '%1 on sales order %2 is already associated with purchase order %3.', Comment = '%1 = number of item, %2 = number of document, %3 = number of purchase order';
        Text007: Label '<Month Text>', Locked = true;
        Text008: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5', Comment = '%1 = table caption, %2 = worksheet template name, %3 = journal batch name, %4 = number of line, %5 = error of dimension combination';
        Text009: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5', Comment = '%1 = table caption, %2 = worksheet template name, %3 = journal batch name, %4 = number of line, %5 = error of dimension posting value';
#pragma warning restore AA0074
        ReservEntry: Record "Reservation Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        ReqTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        PurchOrderHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        SalesOrderHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        TransHeader: Record "Transfer Header";
        TempTransHeader: Record "Transfer Header" temporary;
        AccountingPeriod: Record "Accounting Period";
        TempFailedReqLine: Record "Requisition Line" temporary;
        PurchasingCode: Record Purchasing;
        TempDocumentEntry: Record "Document Entry" temporary;
        TempPurchaseOrderToPrint: Record "Purchase Header" temporary;
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        OrderDateReq: Date;
        PostingDateReq: Date;
        ReceiveDateReq: Date;
        EndOrderDate: Date;
        PrintPurchOrders: Boolean;
        ReferenceReq: Text[35];
        MonthText: Text[30];
        OrderCounter: Integer;
        LineCount: Integer;
        OrderLineCounter: Integer;
        StartLineNo: Integer;
        NextLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        CounterFailed: Integer;
        PrevPurchCode: Code[10];
        PrevShipToCode: Code[10];
#pragma warning disable AA0074
        Text010: Label 'must match %1 on Sales Order %2, Line %3', Comment = '%1 = field caption, %2 = number of document, %3 = number of line';
#pragma warning restore AA0074
        PrevChangedDocOrderType: Enum "Requisition Ref. Order Type";
        PrevChangedDocOrderNo: Code[20];
        PrevLocationCode: Code[10];
        NameAddressDetails: Text;
        SuppressCommit: Boolean;
        HideProgressWindow: Boolean;
        PlanningResiliency: Boolean;

    procedure CarryOutBatchAction(var ReqLine2: Record "Requisition Line")
    var
        ReqLine: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        ReqLine.Copy(ReqLine2);
        ReqLine.SetRange("Accept Action Message", true);
        IsHandled := false;
        OnBeforeCarryOutBatchActionCode(ReqLine, ReqLine2, IsHandled);
        if IsHandled then
            exit;
        Code(ReqLine);
        ReqLine2 := ReqLine;

        OnAfterCarryOutBatchAction(ReqLine2);
    end;

    procedure Set(NewPurchOrderHeader: Record "Purchase Header"; NewEndingOrderDate: Date; NewPrintPurchOrder: Boolean)
    begin
        PurchOrderHeader := NewPurchOrderHeader;
        EndOrderDate := NewEndingOrderDate;
        PrintPurchOrders := NewPrintPurchOrder;
        OrderDateReq := PurchOrderHeader."Order Date";
        PostingDateReq := PurchOrderHeader."Posting Date";
        ReceiveDateReq := PurchOrderHeader."Expected Receipt Date";
        ReferenceReq := PurchOrderHeader."Your Reference";
        OnAfterSet(PurchOrderHeader, SuppressCommit, EndOrderDate, PrintPurchOrders, OrderDateReq, ReceiveDateReq, PostingDateReq, PurchOrderHeader, ReferenceReq);
    end;

    local procedure "Code"(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        ReqLine3: Record "Requisition Line";
        NewReqWkshName: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCode(ReqLine, PlanningResiliency, SuppressCommit, PrintPurchOrders);

        InitShipReceiveDetails();
        Clear(PurchOrderHeader);

        ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        if not PlanningResiliency then
            ReqLine.LockTable();

        if ReqLine."Planning Line Origin" <> ReqLine."Planning Line Origin"::"Order Planning" then
            GetReqTemplate(ReqLine, ReqTemplate);

        if ReqTemplate.Recurring then begin
            ReqLine.SetRange("Order Date", 0D, EndOrderDate);
            ReqLine.SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
        end;

        OnCodeOnAfterFilterReqLine(ReqLine, PlanningResiliency, SuppressCommit, PrintPurchOrders);

        if not ReqLine.Find('=><') then begin
            ReqLine."Line No." := 0;
            if not SuppressCommit then
                Commit();
            exit;
        end;

        OnCodeOnBeforeInitProgressWindow(ReqTemplate, HideProgressWindow);
        if not HideProgressWindow then
            InitProgressWindow();

        if not HideProgressWindow then
            Window.Update(1, ReqLine."Journal Batch Name");
        // Check lines
        CheckRequisitionLines(ReqLine);
        // Create lines
        LineCount := 0;
        OrderCounter := 0;
        OrderLineCounter := 0;
        Clear(PurchOrderHeader);

        IsHandled := false;
        OnCodeOnBeforeSetPurchOrderHeader(ReqLine, IsHandled);
        if not IsHandled then
            SetPurchOrderHeader();
        SetReqLineSortingKey(ReqLine);

        ProcessReqLineActions(ReqLine);

        IsHandled := false;
        OnCodeOnBeforeFinalizeOrderHeader(PurchOrderHeader, ReqLine, IsHandled);
        if not IsHandled then
            if PurchOrderHeader."Buy-from Vendor No." <> '' then
                FinalizeOrderHeader(PurchOrderHeader, ReqLine);

        CheckRunPrintPurchOrders();

        if PrevChangedDocOrderNo <> '' then
            PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);
        // Copy number of created orders and current journal batch name to requisition worksheet
        ReqLine.Init();
        ReqLine."Line No." := OrderCounter;

        if OrderCounter <> 0 then
            if not ReqTemplate.Recurring then begin
                // Not a recurring journal
                ReqLine2.Copy(ReqLine);
                ReqLine2.SetFilter("Vendor No.", '<>%1', '');
                if ReqLine2.FindFirst() then;
                // Remember the last line
                IsHandled := false;
                ReqLine.BlockDynamicTracking(true);
                OnBeforeDeleteReqLines(ReqLine, TempFailedReqLine, IsHandled, ReqLine2);
                if not IsHandled then
                    if ReqLine.Find('-') then
                        repeat
                            TempFailedReqLine := ReqLine;
                            if not TempFailedReqLine.Find() then
                                ReqLine.Delete(true);
                        until ReqLine.Next() = 0;

                ReqLine3.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                ReqLine3.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
                OnCodeOnAfterReqLine3SetFilters(ReqLine, ReqLine3);
                if ReqTemplate."Increment Batch Name" then
                    if not ReqLine3.FindLast() then
                        if IncStr(ReqLine."Journal Batch Name") <> '' then begin
                            ReqWkshName.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
                            NewReqWkshName := true;
                            OnCheckNewNameNeccessary(ReqWkshName, NewReqWkshName);
                            if NewReqWkshName then begin
                                ReqWkshName.Delete();
                                ReqWkshName.Name := IncStr(ReqLine."Journal Batch Name");
                                if ReqWkshName.Insert() then;
                                ReqLine."Journal Batch Name" := ReqWkshName.Name;
                            end;
                        end;
            end;

        OnAfterCode(ReqLine, OrderLineCounter, OrderCounter, PrintPurchOrders, SuppressCommit, PurchOrderHeader);
    end;

    local procedure CheckRunPrintPurchOrders()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRunPrintPurchOrders(TransHeader, PurchOrderHeader, TempPurchaseOrderToPrint, PrintPurchOrders, IsHandled);
        if IsHandled then
            exit;

        if PrintPurchOrders then begin
            PrintTransOrder(TransHeader);
            PrintMultiplePurchaseOrders();
        end;
    end;

    local procedure CheckRequisitionLines(var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequisitionLines(ReqLine, StartLineNo, IsHandled);
        if IsHandled then
            exit;

        LineCount := 0;
        StartLineNo := ReqLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            if not HideProgressWindow then
                Window.Update(2, LineCount);
            CheckRecurringReqLine(ReqLine);
            CheckRequisitionLine(ReqLine);
            if ReqLine.Next() = 0 then
                ReqLine.FindSet();
        until ReqLine."Line No." = StartLineNo;
    end;

    local procedure GetReqTemplate(RequisitionLine: Record "Requisition Line"; var ReqWkshTemplate: Record "Req. Wksh. Template")
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetReqTemplate(RequisitionLine, ReqWkshTemplate, IsHandled);
        if not IsHandled then
            ReqTemplate.Get(RequisitionLine."Worksheet Template Name");
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
    end;

    procedure CheckRequisitionLine(var ReqLine2: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Purchasing: Record Purchasing;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequisitionLine(ReqLine2, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        if (ReqLine2."No." <> '') or (ReqLine2."Vendor No." <> '') or (ReqLine2.Quantity <> 0) then begin
            ReqLine2.TestField("No.");
            IsHandled := false;
            OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckQuantity(ReqLine2, IsHandled);
            if not IsHandled then
                if ReqLine2."Action Message" <> ReqLine2."Action Message"::Cancel then
                    ReqLine2.TestField(Quantity);
            IsHandled := false;
            OnCheckRequisitionLineOnEmptyNewActionMessageOnBeforeOtherCheck(ReqLine2, IsHandled);
            if not IsHandled then
                if (ReqLine2."Action Message" = ReqLine2."Action Message"::" ") or
                   (ReqLine2."Action Message" = ReqLine2."Action Message"::New)
                then
                    if ReqLine2."Replenishment System" = ReqLine2."Replenishment System"::Purchase then
                        TestFieldsForPurchase(ReqLine2)
                    else
                        if ReqLine2."Replenishment System" = ReqLine2."Replenishment System"::Transfer then begin
                            ReqLine2.TestField("Location Code");
                            if ReqLine2."Planning Line Origin" = ReqLine2."Planning Line Origin"::"Order Planning" then
                                ReqLine2.TestField("Supply From");
                            ReqLine2.TestField("Transfer-from Code");
                        end else
                            OnCheckFurtherReplenishmentSystems(ReqLine2);
        end;

        if not DimMgt.CheckDimIDComb(ReqLine2."Dimension Set ID") then
            Error(
              Text008,
              ReqLine2.TableCaption, ReqLine2."Worksheet Template Name", ReqLine2."Journal Batch Name", ReqLine2."Line No.",
              DimMgt.GetDimCombErr());

        TableID[1] := DimMgt.ReqLineTypeToTableID(ReqLine2.Type);
        No[1] := ReqLine2."No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, ReqLine2."Dimension Set ID") then
            if ReqLine2."Line No." <> 0 then
                Error(
                  Text009,
                  ReqLine2.TableCaption, ReqLine2."Worksheet Template Name", ReqLine2."Journal Batch Name", ReqLine2."Line No.",
                  DimMgt.GetDimValuePostingErr())
            else
                Error(DimMgt.GetDimValuePostingErr());

        IsHandled := false;
        OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckUOM(ReqLine2, PurchasingCode, IsHandled);
        if not IsHandled then
            if SalesLine.Get(SalesLine."Document Type"::Order, ReqLine2."Sales Order No.", ReqLine2."Sales Order Line No.") and
               (SalesLine."Unit of Measure Code" <> ReqLine2."Unit of Measure Code")
            then
                if SalesLine."Drop Shipment" or
                   (PurchasingCode.Get(ReqLine2."Purchasing Code") and PurchasingCode."Drop Shipment")
                then
                    ReqLine2.FieldError(
                      ReqLine2."Unit of Measure Code",
                      StrSubstNo(
                        Text010,
                        SalesLine.FieldCaption("Unit of Measure Code"),
                        SalesLine."Document No.",
                        SalesLine."Line No."));

        if ReqLine2.Type = ReqLine2.Type::Item then begin
            Item.SetLoadFields("Variant Mandatory if Exists");
            if Item.Get(ReqLine2."No.") then
                if Item.IsVariantMandatory() then
                    ReqLine2.TestField("Variant Code");
        end;

        if ReqLine2.IsDropShipment() then
            CheckLocation(ReqLine2);

        if Purchasing.Get(ReqLine2."Purchasing Code") then
            if Purchasing."Drop Shipment" or Purchasing."Special Order" then begin
                SalesLine.Get(SalesLine."Document Type"::Order, ReqLine2."Sales Order No.", ReqLine2."Sales Order Line No.");
                CheckLocation(ReqLine2);
                if (Purchasing."Drop Shipment" <> SalesLine."Drop Shipment") or
                   (Purchasing."Special Order" <> SalesLine."Special Order")
                then
                    ReqLine2.FieldError(
                      ReqLine2."Purchasing Code",
                      StrSubstNo(
                        Text010,
                        SalesLine.FieldCaption("Purchasing Code"),
                        SalesLine."Document No.",
                        SalesLine."Line No."));
            end;

        ReqLine2.CheckRequisitionWkshLineRestriction();

        OnAfterCheckReqWkshLine(ReqLine2, SuppressCommit);
    end;

    local procedure TestFieldsForPurchase(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFieldsForPurchase(RequisitionLine, IsHandled);
        if IsHandled then
            exit;
        if RequisitionLine."Planning Line Origin" = RequisitionLine."Planning Line Origin"::"Order Planning" then
            RequisitionLine.TestField("Supply From");
        RequisitionLine.TestField("Vendor No.")
    end;

    local procedure CarryOutReqLineAction(var ReqLine: Record "Requisition Line")
    var
        CarryOutAction: Codeunit "Carry Out Action";
        Failed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCarryOutReqLineAction(ReqLine, Failed, IsHandled, SuppressCommit, OrderCounter, PrintPurchOrders, NextLineNo, PrevShipToCode, PrevPurchCode);
        if Failed then begin
            SetFailedReqLine(ReqLine);
            exit;
        end;

        if IsHandled then
            exit;

        case ReqLine."Replenishment System" of
            ReqLine."Replenishment System"::Transfer:
                case ReqLine."Action Message" of
                    ReqLine."Action Message"::Cancel:
                        begin
                            CarryOutAction.DeleteOrderLines(ReqLine);
                            OrderCounter := OrderCounter + 1;
                        end;
                    ReqLine."Action Message"::"Change Qty.", ReqLine."Action Message"::Reschedule, ReqLine."Action Message"::"Resched. & Chg. Qty.":
                        begin
                            if (PrevChangedDocOrderNo <> '') and
                               ((ReqLine."Ref. Order Type" <> PrevChangedDocOrderType) or (ReqLine."Ref. Order No." <> PrevChangedDocOrderNo))
                            then
                                PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);
                            CarryOutAction.SetPrintOrder(false);
                            CarryOutAction.TransOrderChgAndReshedule(ReqLine);
                            PrevChangedDocOrderType := ReqLine."Ref. Order Type";
                            PrevChangedDocOrderNo := ReqLine."Ref. Order No.";
                            OrderCounter := OrderCounter + 1;
                        end;
                    ReqLine."Action Message"::New, ReqLine."Action Message"::" ":
                        begin
                            CarryOutAction.SetPrintOrder(PrintPurchOrders);
                            GetTransferHeader(TransHeader, ReqLine);
                            CarryOutAction.InsertTransLine(ReqLine, TransHeader);
                            SetTransferHeader(TransHeader);
                            OnCarryOutReqLineActionOnAfterInsertTransLine(TransHeader);
                            OrderCounter := OrderCounter + 1;
                        end;
                end;
            ReqLine."Replenishment System"::Purchase, ReqLine."Replenishment System"::"Prod. Order":
                case ReqLine."Action Message" of
                    ReqLine."Action Message"::Cancel:
                        begin
                            CarryOutAction.DeleteOrderLines(ReqLine);
                            OrderCounter := OrderCounter + 1;
                        end;
                    ReqLine."Action Message"::"Change Qty.", ReqLine."Action Message"::Reschedule, ReqLine."Action Message"::"Resched. & Chg. Qty.":
                        begin
                            if (PrevChangedDocOrderNo <> '') and
                               ((ReqLine."Ref. Order Type" <> PrevChangedDocOrderType) or (ReqLine."Ref. Order No." <> PrevChangedDocOrderNo))
                            then
                                PrintChangedDocument(PrevChangedDocOrderType, PrevChangedDocOrderNo);
                            CarryOutAction.SetPrintOrder(false);
                            CarryOutAction.PurchOrderChgAndReshedule(ReqLine);
                            PrevChangedDocOrderType := ReqLine."Ref. Order Type";
                            PrevChangedDocOrderNo := ReqLine."Ref. Order No.";
                            OrderCounter := OrderCounter + 1;
                        end;
                    ReqLine."Action Message"::New, ReqLine."Action Message"::" ":
                        begin
                            if (PurchOrderHeader."Buy-from Vendor No." <> '') and
                               CheckInsertFinalizePurchaseOrderHeader(ReqLine, PurchOrderHeader, false)
                            then begin
                                FinalizeOrderHeader(PurchOrderHeader, ReqLine);
                                PurchOrderLine.Reset();
                                PurchOrderLine.SetRange("Document Type", PurchOrderHeader."Document Type");
                                PurchOrderLine.SetRange("Document No.", PurchOrderHeader."No.");
                                PurchOrderLine.SetFilter("Special Order Sales Line No.", '<> 0');
                                if PurchOrderLine.Find('-') then
                                    repeat
                                        SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, PurchOrderLine."Special Order Sales No.",
                                          PurchOrderLine."Special Order Sales Line No.");
                                    until PurchOrderLine.Next() = 0;
                            end;
                            MakeRecurringTexts(ReqLine);
                            InsertPurchOrderLine(ReqLine, PurchOrderHeader);
                        end;
                end;
            else
                OnCarryOutReqLineActionOnCaseReplenishmentSystemElse(ReqLine);
        end;

        OnAfterCarryOutReqLineAction(ReqLine, PurchOrderHeader, SuppressCommit, OrderCounter, LineCount);
    end;

    local procedure TryCarryOutReqLineAction(var ReqLine: Record "Requisition Line"): Boolean
    begin
        OnBeforeTryCarryOutReqLineAction(ReqLine);

        ReqWkshMakeOrders.Set(PurchOrderHeader, EndOrderDate, PrintPurchOrders);
        ReqWkshMakeOrders.SetTryParam(
          ReqTemplate,
          LineCount,
          NextLineNo,
          PrevPurchCode,
          PrevShipToCode,
          PrevLocationCode,
          OrderCounter,
          OrderLineCounter,
          TempFailedReqLine,
          TempDocumentEntry);
        ReqWkshMakeOrders.SetSuppressCommit(SuppressCommit);
        if ReqWkshMakeOrders.Run(ReqLine) then begin
            ReqWkshMakeOrders.GetTryParam(
              PurchOrderHeader,
              LineCount,
              NextLineNo,
              PrevPurchCode,
              PrevShipToCode,
              PrevLocationCode,
              OrderCounter,
              OrderLineCounter);

            if PrintPurchOrders and PlanningResiliency then
                if PurchOrderHeader."No." <> '' then
                    if not TempPurchaseOrderToPrint.Get(PurchOrderHeader."Document Type", PurchOrderHeader."No.") then begin
                        TempPurchaseOrderToPrint := PurchOrderHeader;
                        TempPurchaseOrderToPrint.Insert();
                    end;

            if not HideProgressWindow then begin
                Window.Update(3, OrderCounter);
                Window.Update(4, LineCount);
                Window.Update(5, OrderLineCounter);
            end;
            exit(true);
        end;
        exit(false)
    end;

    procedure InitPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPurchOrderLine(
            RequisitionLine, PurchasingCode, PurchOrderHeader, LineCount, NextLineNo, PrevPurchCode, PrevShipToCode, PlanningResiliency,
            TempDocumentEntry, SuppressCommit, PostingDateReq, ReferenceReq, OrderDateReq, ReceiveDateReq, OrderCounter, HideProgressWindow, IsHandled, PurchOrderLine);
        if IsHandled then
            exit;

        Clear(PurchOrderLine);
        PurchOrderLine.Init();
        PurchOrderLine.BlockDynamicTracking(true);
        PurchOrderLine."Document Type" := PurchOrderLine."Document Type"::Order;
        PurchOrderLine."Buy-from Vendor No." := RequisitionLine."Vendor No.";
        PurchOrderLine."Document No." := PurchOrderHeader."No.";
        NextLineNo := NextLineNo + 10000;
        PurchOrderLine."Line No." := NextLineNo;
        OnBeforePurchOrderLineValidateType(PurchOrderLine, RequisitionLine);
        PurchOrderLine.Validate(Type, RequisitionLine.Type);
        OnBeforePurchOrderLineValidateNo(PurchOrderLine, RequisitionLine);
        PurchOrderLine.Validate("No.", RequisitionLine."No.");
        OnAfterPurchOrderLineValidateNo(PurchOrderLine, RequisitionLine);
        PurchOrderLine.Validate("Variant Code", RequisitionLine."Variant Code");
        OnInitPurchOrderLineOnAfterPurchOrderLineAssignVariantCode(PurchOrderLine, RequisitionLine);
        PurchOrderLine.Validate("Location Code", RequisitionLine."Location Code");
        PurchOrderLine.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        PurchOrderLine."Qty. per Unit of Measure" := RequisitionLine."Qty. per Unit of Measure";
        OnInitPurchOrderLineOnBeforeUpdateQuantity(PurchOrderLine, RequisitionLine);
        InitPurchOrderLineUpdateQuantity(RequisitionLine);

        CopyOrderDateFromPurchHeader(RequisitionLine, PurchOrderHeader, PurchOrderLine);
        if PurchOrderHeader."Prices Including VAT" then
            PurchOrderLine.Validate("Direct Unit Cost", RequisitionLine."Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100))
        else
            PurchOrderLine.Validate("Direct Unit Cost", RequisitionLine."Direct Unit Cost");
        OnInitPurchOrderLineOnBeforeValidateLineDiscount(PurchOrderLine, PurchOrderHeader, RequisitionLine);
        PurchOrderLine.Validate("Line Discount %", RequisitionLine."Line Discount %");
        OnInitPurchOrderLineOnAfterValidateLineDiscount(PurchOrderLine, PurchOrderHeader, RequisitionLine);

        PurchOrderLine."Vendor Item No." := RequisitionLine."Vendor Item No.";
        PurchOrderLine.Description := RequisitionLine.Description;
        PurchOrderLine."Description 2" := RequisitionLine."Description 2";
        PurchOrderLine."Sales Order No." := RequisitionLine."Sales Order No.";
        PurchOrderLine."Sales Order Line No." := RequisitionLine."Sales Order Line No.";
        PurchOrderLine."Bin Code" := RequisitionLine."Bin Code";
        PurchOrderLine."Item Category Code" := RequisitionLine."Item Category Code";
        PurchOrderLine.Nonstock := RequisitionLine.Nonstock;
        PurchOrderLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
        PurchOrderLine.Validate("Purchasing Code", RequisitionLine."Purchasing Code");
        if RequisitionLine."Due Date" <> 0D then begin
            PurchOrderLine.Validate("Expected Receipt Date", RequisitionLine."Due Date");
            PurchOrderLine."Requested Receipt Date" := PurchOrderLine."Planned Receipt Date";
        end;

        OnAfterInitPurchOrderLine(PurchOrderLine, RequisitionLine);
    end;

    local procedure InitPurchOrderLineUpdateQuantity(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitPurchOrderLineUpdateQuantity(PurchOrderLine, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        PurchOrderLine.Validate(Quantity, RequisitionLine.Quantity);
    end;

    local procedure CopyOrderDateFromPurchHeader(var RequisitionLine: Record "Requisition Line"; PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyOrderDateFromPurchHeader(RequisitionLine, PurchOrderHeader, PurchOrderLine, IsHandled);
        if IsHandled then
            exit;

        if PurchOrderLine.CountPrice(true) > 0 then
            RequisitionLine.Validate("Order Date", PurchOrderHeader."Order Date");
    end;

    procedure InsertPurchOrderLine(var ReqLine2: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header")
    var
        PurchOrderLine2: Record "Purchase Line";
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertPurchOrderLine(ReqLine2, PurchOrderHeader, NextLineNo, IsHandled, PrevPurchCode, PrevShipToCode, PlanningResiliency, TempDocumentEntry, SuppressCommit,
            PostingDateReq, ReferenceReq, OrderDateReq, ReceiveDateReq, OrderCounter, HideProgressWindow, PrevLocationCode, LineCount, PurchOrderHeader, PurchasingCode, PurchOrderLine);
        if IsHandled then
            exit;

        if (ReqLine2."No." = '') or (ReqLine2."Vendor No." = '') or (ReqLine2.Quantity = 0) then
            exit;

        if CheckInsertFinalizePurchaseOrderHeader(ReqLine2, PurchOrderHeader, true) then begin
            IsHandled := false;
            OnInsertPurchOrderLineOnBeforeInsertHeader(ReqLine2, PurchOrderHeader, PurchOrderLine, LineCount, NextLineNo, IsHandled);
            if not IsHandled then begin
                InsertHeader(ReqLine2);
                LineCount := 0;
                NextLineNo := 0;
            end;
            PrevPurchCode := ReqLine2."Purchasing Code";
            PrevShipToCode := ReqLine2."Ship-to Code";
            PrevLocationCode := ReqLine2."Location Code";
        end;

        OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(ReqLine2, PurchOrderHeader, NextLineNo);

        LineCount := LineCount + 1;
        if not PlanningResiliency then
            if not HideProgressWindow then
                Window.Update(4, LineCount);

        ReqLine2.TestField("Currency Code", PurchOrderHeader."Currency Code");

        InitPurchOrderLine(PurchOrderLine, PurchOrderHeader, ReqLine2);

        TransferFromReqLineToPurchLine(PurchOrderLine, ReqLine2);
        OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine2);

        PurchOrderLine."Drop Shipment" := (ReqLine2."Sales Order Line No." <> 0) or ((ReqLine2."Drop Shipment") and (ReqLine2."Demand Type" = Database::"Sales Line"));

        if (ReqLine2."Drop Shipment") and (ReqLine2."Sales Order Line No." = 0) then begin
            PurchOrderLine.Validate("Sales Order No.", ReqLine2."Demand Order No.");
            PurchOrderLine.Validate("Sales Order Line No.", ReqLine2."Demand Line No.");
        end;

        if PurchasingCode.Get(ReqLine2."Purchasing Code") then
            if PurchasingCode."Special Order" then begin
                PurchOrderLine."Special Order Sales No." := ReqLine2."Sales Order No.";
                PurchOrderLine."Special Order Sales Line No." := ReqLine2."Sales Order Line No.";
                PurchOrderLine."Special Order" := true;
                PurchOrderLine."Drop Shipment" := false;
                PurchOrderLine."Sales Order No." := '';
                PurchOrderLine."Sales Order Line No." := 0;
                PurchOrderLine."Special Order" := true;
                PurchOrderLine.UpdateUnitCost();
            end;

        UpdateJobLink(PurchOrderLine, ReqLine2);

        OnInsertPurchOrderLineOnBeforeTransferReqLine(PurchOrderHeader, PurchOrderLine, ReqLine2);
        ReqLineReserve.TransferReqLineToPurchLine(ReqLine2, PurchOrderLine, ReqLine2."Quantity (Base)", false);

        DimensionSetIDArr[1] := PurchOrderLine."Dimension Set ID";
        DimensionSetIDArr[2] := ReqLine2."Dimension Set ID";
        PurchOrderLine."Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(
            DimensionSetIDArr, PurchOrderLine."Shortcut Dimension 1 Code", PurchOrderLine."Shortcut Dimension 2 Code");

        OnBeforePurchOrderLineInsert(PurchOrderHeader, PurchOrderLine, ReqLine2, SuppressCommit);
        PurchOrderLine.Insert();
        OnAfterPurchOrderLineInsert(PurchOrderLine, ReqLine2, NextLineNo);

        if ReqLine2.Reserve then
            ReserveBindingOrderToPurch(PurchOrderLine, ReqLine2);

        IsHandled := false;
        OnInsertPurchOrderLineOnBeforeUpdateAssociatedSalesLine(PurchOrderLine, ReqLine2, IsHandled);
        if not IsHandled then
            if PurchOrderLine."Drop Shipment" or PurchOrderLine."Special Order" then begin
                SalesOrderLine.LockTable();
                SalesOrderHeader.LockTable();
                SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, ReqLine2."Sales Order No.");
                CheckPurchOrderLineShipToCode(ReqLine2);
                SalesOrderLine.Get(SalesOrderLine."Document Type"::Order, ReqLine2."Sales Order No.", ReqLine2."Sales Order Line No.");
                SalesOrderLine.TestField(Type, SalesOrderLine.Type::Item);
                if SalesOrderLine."Purch. Order Line No." <> 0 then
                    Error(Text006, SalesOrderLine."No.", SalesOrderLine."Document No.", SalesOrderLine."Purchase Order No.");
                if SalesOrderLine."Special Order Purchase No." <> '' then
                    Error(Text006, SalesOrderLine."No.", SalesOrderLine."Document No.", SalesOrderLine."Special Order Purchase No.");
                if not PurchOrderLine."Special Order" then
                    ReqLine2.TestField("Sell-to Customer No.", SalesOrderLine."Sell-to Customer No.");
                ReqLine2.TestField(Type, SalesOrderLine.Type);
                if PurchOrderLine."Drop Shipment" then
                    CheckRequsitionLineQuantity(ReqLine2);
                ReqLine2.TestField("No.", SalesOrderLine."No.");
                ReqLine2.TestField("Location Code", SalesOrderLine."Location Code");
                ReqLine2.TestField("Variant Code", SalesOrderLine."Variant Code");
                ReqLine2.TestField("Bin Code", SalesOrderLine."Bin Code");
                ReqLine2.TestProdOrderNo();
                ReqLine2.TestField("Qty. per Unit of Measure", ReqLine2."Qty. per Unit of Measure");
                OnInsertPurchOrderLineOnBeforeSalesOrderLineValidateUnitCostLCY(PurchOrderLine, SalesOrderLine);
                SalesOrderLine.Validate("Unit Cost (LCY)");

                if SalesOrderLine."Special Order" then begin
                    SalesOrderLine."Special Order Purchase No." := PurchOrderLine."Document No.";
                    SalesOrderLine."Special Order Purch. Line No." := PurchOrderLine."Line No.";
                end else begin
                    SalesOrderLine."Purchase Order No." := PurchOrderLine."Document No.";
                    SalesOrderLine."Purch. Order Line No." := PurchOrderLine."Line No.";
                end;
                OnInsertPurchOrderLineOnBeforeSalesOrderLineModify(SalesOrderLine, ReqLine2, PurchOrderLine);
                SalesOrderLine.Modify();
            end;

        if TransferExtendedText.PurchCheckIfAnyExtText(PurchOrderLine, false) then begin
            TransferExtendedText.InsertPurchExtText(PurchOrderLine);
            PurchOrderLine2.SetRange("Document Type", PurchOrderHeader."Document Type");
            PurchOrderLine2.SetRange("Document No.", PurchOrderHeader."No.");
            if PurchOrderLine2.FindLast() then
                NextLineNo := PurchOrderLine2."Line No.";
        end;

        OnAfterInsertPurchOrderLine(PurchOrderLine, NextLineNo, ReqLine2, PurchOrderHeader);
    end;

    local procedure TransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; ReqLine: Record "Requisition Line")
    begin
        OnTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
    end;

    local procedure CheckRequsitionLineQuantity(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRequsitionLineQuantity(RequisitionLine, PurchOrderLine, SalesOrderLine, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.TestField(
            Quantity,
            Round(
                SalesOrderLine."Outstanding Quantity" * SalesOrderLine."Qty. per Unit of Measure" / RequisitionLine."Qty. per Unit of Measure",
                UOMMgt.QtyRndPrecision()));
    end;

    local procedure CheckPurchOrderLineShipToCode(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchOrderLineShipToCode(RequisitionLine, PurchOrderLine, SalesOrderHeader, IsHandled);
        if IsHandled then
            exit;

        if not PurchOrderLine."Special Order" then
            RequisitionLine.TestField("Ship-to Code", SalesOrderHeader."Ship-to Code");
    end;

    local procedure InsertHeader(var ReqLine2: Record "Requisition Line")
    var
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        SpecialOrder: Boolean;
        ShouldValidateSellToCustNo: Boolean;
        ShouldSetShipToForSpecOrder: Boolean;
    begin
        OnBeforeInsertHeader(ReqLine2, PurchOrderHeader, OrderDateReq, PostingDateReq, ReceiveDateReq, ReferenceReq, NameAddressDetails);

        OrderCounter := OrderCounter + 1;
        if not PlanningResiliency then
            if not HideProgressWindow then
                Window.Update(3, OrderCounter);

        PurchSetup.Get();
        PurchSetup.TestField("Order Nos.");
        Clear(PurchOrderHeader);
        PurchOrderHeader.Init();
        PurchOrderHeader."Document Type" := PurchOrderHeader."Document Type"::Order;
        PurchOrderHeader."No." := '';
        PurchOrderHeader."Posting Date" := PostingDateReq;
        OnBeforePurchOrderHeaderInsert(PurchOrderHeader, ReqLine2, ReceiveDateReq, OrderDateReq, PostingDateReq, ReferenceReq);
        PurchOrderHeader.Insert(true);
        PurchOrderHeader."Your Reference" := ReferenceReq;
        PurchOrderHeader."Order Date" := OrderDateReq;
        PurchOrderHeader."Expected Receipt Date" := ReceiveDateReq;
        ValidateBuyFromVendorNo(PurchOrderHeader, ReqLine2);
        if ReqLine2."Order Address Code" <> '' then
            PurchOrderHeader.Validate("Order Address Code", ReqLine2."Order Address Code");


        ShouldValidateSellToCustNo := ReqLine2."Sell-to Customer No." <> '';
        OnInsertHeaderOnBeforeValidateSellToCustNoFromReqLine(PurchOrderHeader, ReqLine2, ShouldValidateSellToCustNo);
        if ShouldValidateSellToCustNo then
            PurchOrderHeader.Validate("Sell-to Customer No.", ReqLine2."Sell-to Customer No.");

        PurchOrderHeader.Validate("Currency Code", ReqLine2."Currency Code");

        if PurchasingCode.Get(ReqLine2."Purchasing Code") then
            if PurchasingCode."Special Order" then
                SpecialOrder := true;

        if not SpecialOrder then
            UpdateShipToOrLocationCode(ReqLine2, PurchOrderHeader)
        else begin
            PurchOrderHeader.Validate("Location Code", ReqLine2."Location Code");
            ShouldSetShipToForSpecOrder := true;
            OnInsertHeaderOnBeforeSetShipToForSpecOrder(PurchOrderHeader, ReqLine2, ShouldSetShipToForSpecOrder);
            if ShouldSetShipToForSpecOrder then
                PurchOrderHeader.SetShipToForSpecOrder();
            if Vendor.Get(PurchOrderHeader."Buy-from Vendor No.") then
                PurchOrderHeader.Validate("Shipment Method Code", Vendor."Shipment Method Code");
        end;
        if not SpecialOrder then
            if SalesHeader.Get(SalesHeader."Document Type"::Order, ReqLine2."Sales Order No.") then begin
                PurchOrderHeader."Ship-to Name" := SalesHeader."Ship-to Name";
                PurchOrderHeader."Ship-to Name 2" := SalesHeader."Ship-to Name 2";
                PurchOrderHeader."Ship-to Address" := SalesHeader."Ship-to Address";
                PurchOrderHeader."Ship-to Address 2" := SalesHeader."Ship-to Address 2";
                PurchOrderHeader."Ship-to Post Code" := SalesHeader."Ship-to Post Code";
                PurchOrderHeader."Ship-to City" := SalesHeader."Ship-to City";
                PurchOrderHeader."Ship-to Contact" := SalesHeader."Ship-to Contact";
                PurchOrderHeader."Ship-to County" := SalesHeader."Ship-to County";
                PurchOrderHeader."Ship-to Country/Region Code" := SalesHeader."Ship-to Country/Region Code";
                PurchOrderHeader."Ship-to Phone No." := SalesHeader."Ship-to Phone No.";
            end;
        if SpecialOrder then
            if Vendor.Get(PurchOrderHeader."Buy-from Vendor No.") then
                PurchOrderHeader."Shipment Method Code" := Vendor."Shipment Method Code";
        OnAfterInsertPurchOrderHeader(ReqLine2, PurchOrderHeader, SuppressCommit, SpecialOrder);
        PurchOrderHeader.Modify();
        PurchOrderHeader.Mark(true);
        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Purchase Header";
        TempDocumentEntry."Document Type" := PurchOrderHeader."Document Type"::Order;
        TempDocumentEntry."Document No." := PurchOrderHeader."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();
    end;

    local procedure ValidateBuyFromVendorNo(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateBuyFromVendorNo(PurchOrderHeader, RequisitionLine, IsHandled);
        if not IsHandled then
            PurchOrderHeader.Validate("Buy-from Vendor No.", RequisitionLine."Vendor No.");
    end;

    local procedure UpdateShipToOrLocationCode(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShipToOrLocationCode(PurchaseHeader, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        if RequisitionLine."Ship-to Code" <> '' then
            PurchaseHeader.Validate("Ship-to Code", RequisitionLine."Ship-to Code")
        else
            PurchaseHeader.Validate("Location Code", RequisitionLine."Location Code");
    end;

    procedure RunFinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
        FinalizeOrderHeader(PurchOrderHeader, ReqLine);
    end;

    procedure FinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
        IsHandled: Boolean;
    begin
        if ReqTemplate.Recurring then begin
            // Recurring journal
            ReqLine2.Copy(ReqLine);
            ReqLine2.SetRange("Vendor No.", PurchOrderHeader."Buy-from Vendor No.");
            ReqLine2.SetRange("Sell-to Customer No.", PurchOrderHeader."Sell-to Customer No.");
            ReqLine2.SetRange("Ship-to Code", PurchOrderHeader."Ship-to Code");
            ReqLine2.SetRange("Order Address Code", PurchOrderHeader."Order Address Code");
            ReqLine2.SetRange("Currency Code", PurchOrderHeader."Currency Code");
            IsHandled := false;
            OnFinalizeOrderHeaderOnAfterSetFiltersForRecurringReqLine(ReqLine2, PurchOrderHeader, IsHandled);
            if not IsHandled then begin
                ReqLine2.Find('-');
                repeat
                    OrderLineCounter := OrderLineCounter + 1;
                    if not PlanningResiliency then
                        if not HideProgressWindow then
                            Window.Update(5, OrderLineCounter);
                    if ReqLine2."Order Date" <> 0D then begin
                        ReqLine2.Validate("Order Date", CalcDate(ReqLine2."Recurring Frequency", ReqLine2."Order Date"));
                        ReqLine2.Validate("Currency Code", PurchOrderHeader."Currency Code");
                    end;
                    if (ReqLine2."Recurring Method" = ReqLine2."Recurring Method"::Variable) and (ReqLine2."No." <> '') then begin
                        ReqLine2.Quantity := 0;
                        ReqLine2."Line Discount %" := 0;
                    end;
                    OnFinalizeOrderHeaderOnLoopLinesBeforeModifyForRecurrReqLines(ReqLine2);
                    ReqLine2.Modify();
                until ReqLine2.Next() = 0;
            end;
        end else begin
            // Not a recurring journal
            OrderLineCounter := OrderLineCounter + LineCount;
            if not PlanningResiliency then
                if not HideProgressWindow then
                    Window.Update(5, OrderLineCounter);

            ReqLine2.Copy(ReqLine);
            ReqLine2.SetRange("Vendor No.", PurchOrderHeader."Buy-from Vendor No.");
            ReqLine2.SetRange("Sell-to Customer No.", PurchOrderHeader."Sell-to Customer No.");
            ReqLine2.SetRange("Ship-to Code", PurchOrderHeader."Ship-to Code");
            ReqLine2.SetRange("Order Address Code", PurchOrderHeader."Order Address Code");
            ReqLine2.SetRange("Currency Code", PurchOrderHeader."Currency Code");
            ReqLine2.SetRange("Purchasing Code", PrevPurchCode);
            IsHandled := false;
            OnFinalizeOrderHeaderOnAfterSetFiltersForNonRecurringReqLine(ReqLine2, PurchOrderHeader, IsHandled, TempFailedReqLine);
            if not IsHandled then
                if ReqLine2.FindSet() then begin
                    ReqLine2.BlockDynamicTracking(true);
                    ReservEntry.SetCurrentKey(
                        "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
                    repeat
                        if PurchaseOrderLineMatchReqLine(ReqLine2) then begin
                            TempFailedReqLine := ReqLine2;
                            if not TempFailedReqLine.Find() then begin
                                ReqLine2.SetReservationFilters(ReservEntry);
                                ReservEntry.DeleteAll(true);
                                IsHandled := false;
                                OnFinalizeOrderHeaderOnBeforeReqLine2Delete(ReqLine2, IsHandled);
                                if not IsHandled then
                                    ReqLine2.Delete(true);
                            end;
                        end;
                    until ReqLine2.Next() = 0;
                end;
        end;
        OnAfterFinalizeOrderHeader(PurchOrderHeader, ReqLine);
        if not SuppressCommit then
            Commit();

        IsHandled := false;
        OnFinalizeOrderHeaderOnBeforePrint(PrintPurchOrders, PurchOrderHeader, IsHandled);
        if not IsHandled then
            if PrintPurchOrders and not PlanningResiliency then
                if PurchOrderHeader.Get(PurchOrderHeader."Document Type", PurchOrderHeader."No.") then
                    if not TempPurchaseOrderToPrint.Get(PurchOrderHeader."Document Type", PurchOrderHeader."No.") then begin
                        TempPurchaseOrderToPrint := PurchOrderHeader;
                        TempPurchaseOrderToPrint.Insert();
                    end;

        OnAfterFinalizeOrderHeaderProcedure(PurchOrderHeader, ReqLine);
    end;

    procedure CheckRecurringReqLine(var ReqLine2: Record "Requisition Line")
    var
        DummyDateFormula: DateFormula;
    begin
        if ReqLine2."No." <> '' then
            if ReqTemplate.Recurring then begin
                ReqLine2.TestField("Recurring Method");
                ReqLine2.TestField("Recurring Frequency");
                if ReqLine2."Recurring Method" = ReqLine2."Recurring Method"::Variable then
                    ReqLine2.TestField(Quantity);
            end else begin
                ReqLine2.TestField("Recurring Method", 0);
                ReqLine2.TestField("Recurring Frequency", DummyDateFormula);
            end;
    end;

    local procedure MakeRecurringTexts(var ReqLine2: Record "Requisition Line")
    begin
        OnBeforeMakeRecurringTexts(ReqLine2, PurchOrderLine);
        if (ReqLine2."No." <> '') and (ReqLine2."Recurring Method" <> 0) and (ReqLine2."Order Date" <> 0D) then begin
            Day := Date2DMY(ReqLine2."Order Date", 1);
            Week := Date2DWY(ReqLine2."Order Date", 2);
            Month := Date2DMY(ReqLine2."Order Date", 2);
            MonthText := Format(ReqLine2."Order Date", 0, Text007);
            AccountingPeriod.SetRange("Starting Date", 0D, ReqLine2."Order Date");
            if not AccountingPeriod.FindLast() then
                AccountingPeriod.Name := '';
            ReqLine2.Description :=
              DelChr(
                PadStr(
                  StrSubstNo(ReqLine2.Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                  MaxStrLen(ReqLine2.Description)),
                '>');
            ReqLine2.Modify();
        end;
    end;

    procedure ReserveBindingOrderToPurch(var PurchLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        TrackingSpecification: Record "Tracking Specification";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        PurchLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if (PurchLine."Quantity (Base)" - PurchLine."Reserved Qty. (Base)") > ReqLine."Demand Quantity (Base)" then begin
            ReservQty := ReqLine."Demand Quantity";
            ReservQtyBase := ReqLine."Demand Quantity (Base)";
        end else begin
            ReservQty := PurchLine.Quantity - PurchLine."Reserved Quantity";
            ReservQtyBase := PurchLine."Quantity (Base)" - PurchLine."Reserved Qty. (Base)";
        end;

        case ReqLine."Demand Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(ReqLine."Demand Subtype", ReqLine."Demand Order No.", ReqLine."Demand Line No.");
                    TrackingSpecification.InitTrackingSpecification(
                        Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
                        PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
                    SalesLineReserve.BindToTracking(
                        SalesLine, TrackingSpecification, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
                    if SalesLine.Reserve = SalesLine.Reserve::Never then begin
                        SalesLine.Reserve := SalesLine.Reserve::Optional;
                        SalesLine.Modify();
                    end;
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.SetRange("Job Contract Entry No.", ReqLine."Demand Line No.");
                    JobPlanningLine.FindFirst();
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
                        PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
                    JobPlanningLineReserve.BindToTracking(
                        JobPlanningLine, TrackingSpecification, PurchLine.Description, PurchLine."Expected Receipt Date", ReservQty, ReservQtyBase);
                    if JobPlanningLine.Reserve = JobPlanningLine.Reserve::Never then begin
                        JobPlanningLine.Reserve := JobPlanningLine.Reserve::Optional;
                        JobPlanningLine.Modify();
                    end;
                end;
            else
                OnReserveBindingOrderToPurch(ReqLine, PurchLine, ReservQty, ReservQtyBase);
        end;
        PurchLine.Modify();

        OnAfterReserveBindingOrderToPurch(PurchLine, ReqLine, ReservQty, ReservQtyBase, SuppressCommit);
    end;

    procedure SetTryParam(TryReqTemplate: Record "Req. Wksh. Template"; TryLineCount: Integer; TryNextLineNo: Integer; TryPrevPurchCode: Code[10]; TryPrevShipToCode: Code[10]; TryPrevLocationCode: Code[10]; TryOrderCounter: Integer; TryOrderLineCounter: Integer; var TryFailedReqLine: Record "Requisition Line"; var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        SetPlanningResiliency();
        ReqTemplate := TryReqTemplate;
        LineCount := TryLineCount;
        NextLineNo := TryNextLineNo;
        PrevPurchCode := TryPrevPurchCode;
        PrevShipToCode := TryPrevShipToCode;
        PrevLocationCode := TryPrevLocationCode;
        OrderCounter := TryOrderCounter;
        OrderLineCounter := TryOrderLineCounter;
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
        if TryFailedReqLine.Find('-') then
            repeat
                TempFailedReqLine := TryFailedReqLine;
                if TempFailedReqLine.Insert() then;
            until TryFailedReqLine.Next() = 0;
    end;

    procedure GetTryParam(var TryPurchOrderHeader: Record "Purchase Header"; var TryLineCount: Integer; var TryNextLineNo: Integer; var TryPrevPurchCode: Code[10]; var TryPrevShipToCode: Code[10]; var TryPrevLocationCode: Code[10]; var TryOrderCounter: Integer; var TryOrderLineCounter: Integer)
    begin
        TryPurchOrderHeader.Copy(PurchOrderHeader);
        TryLineCount := LineCount;
        TryNextLineNo := NextLineNo;
        TryPrevPurchCode := PrevPurchCode;
        TryPrevShipToCode := PrevShipToCode;
        TryPrevLocationCode := PrevLocationCode;
        TryOrderCounter := OrderCounter;
        TryOrderLineCounter := OrderLineCounter;
    end;

    procedure SetFailedReqLine(var TryFailedReqLine: Record "Requisition Line")
    begin
        TempFailedReqLine := TryFailedReqLine;
        TempFailedReqLine.Insert();
    end;

    procedure SetPlanningResiliency()
    begin
        PlanningResiliency := true;
    end;

    procedure GetFailedCounter(): Integer
    begin
        exit(CounterFailed);
    end;

    local procedure PrintTransOrder(TransferHeader: Record "Transfer Header")
    var
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        if TransferHeader."No." <> '' then begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintTransferOrder(TransferHeader);
        end;
    end;

    local procedure PrintChangedDocument(OrderType: Enum "Requisition Ref. Order Type"; var OrderNo: Code[20])
    var
        DummyReqLine: Record "Requisition Line";
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        CarryOutAction.SetPrintOrder(PrintPurchOrders);
        case OrderType of
            DummyReqLine."Ref. Order Type"::Transfer:
                begin
                    TransferHeader.Get(OrderNo);
                    PrintTransOrder(TransferHeader);
                end;
            DummyReqLine."Ref. Order Type"::Purchase:
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
                    PrintPurchOrder(PurchaseHeader);
                end;
        end;
        OrderNo := '';
    end;

    procedure PrintPurchOrder(PurchHeader: Record "Purchase Header")
    var
        CarryOutAction: Codeunit "Carry Out Action";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPurchOrder(PurchHeader, PrintPurchOrders, IsHandled);
        if IsHandled then
            exit;

        if PurchHeader."No." <> '' then begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintPurchaseOrder(PurchHeader);
        end;
    end;

    local procedure PrintMultiplePurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        CarryOutAction: Codeunit "Carry Out Action";
    begin
        if TempPurchaseOrderToPrint.Count() = 1 then begin
            TempPurchaseOrderToPrint.FindFirst();
            PurchaseHeader.Get(TempPurchaseOrderToPrint."Document Type", TempPurchaseOrderToPrint."No.");
            PrintPurchOrder(PurchaseHeader);
        end else begin
            CarryOutAction.SetPrintOrder(PrintPurchOrders);
            CarryOutAction.PrintMultiplePurchaseOrders(TempPurchaseOrderToPrint);
        end;
    end;

    local procedure ProcessReqLineActions(var ReqLine: Record "Requisition Line")
    begin
        OnBeforeProcessReqLineActions(ReqLine, SuppressCommit, PlanningResiliency);

        if ReqLine.Find('-') then
            repeat
                OnProcessReqLineActionsOnBeforeReqLineLoop(ReqLine);
                if not PlanningResiliency then
                    CarryOutReqLineAction(ReqLine)
                else
                    if not TryCarryOutReqLineAction(ReqLine) then begin
                        SetFailedReqLine(ReqLine);
                        OnProcessReqLineActionsOnAfterSetFailedReqLine(ReqLine);
                        CounterFailed := CounterFailed + 1;
                    end;
            until ReqLine.Next() = 0;
    end;

    local procedure SetPurchOrderHeader()
    begin
        PurchOrderHeader."Order Date" := OrderDateReq;
        PurchOrderHeader."Posting Date" := PostingDateReq;
        PurchOrderHeader."Expected Receipt Date" := ReceiveDateReq;
        PurchOrderHeader."Your Reference" := ReferenceReq;
        OnAfterSetPurchOrderHeader(PurchOrderHeader);
    end;

    local procedure SetReqLineSortingKey(var RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetReqLineSortingKey(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.SetCurrentKey(
              "Worksheet Template Name", "Journal Batch Name", "Vendor No.",
              "Sell-to Customer No.", "Ship-to Code", "Order Address Code", "Currency Code",
              "Ref. Order Type", "Ref. Order Status", "Ref. Order No.",
              "Transfer-from Code", "Purchasing Code");
    end;

    procedure CheckAddressDetails(SalesOrderNo: Code[20]; SalesLineNo: Integer; UpdateAddressDetails: Boolean) Result: Boolean
    var
        SalesLine: Record "Sales Line";
        Purchasing: Record Purchasing;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAddressDetails(SalesOrderNo, SalesLineNo, UpdateAddressDetails, Result, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.Get(SalesLine."Document Type"::Order, SalesOrderNo, SalesLineNo) then
            if Purchasing.Get(SalesLine."Purchasing Code") then
                case true of
                    Purchasing."Drop Shipment":
                        Result :=
                          not CheckDropShptAddressDetails(SalesOrderNo, UpdateAddressDetails);
                    Purchasing."Special Order":
                        Result :=
                          not CheckSpecOrderAddressDetails(SalesLine."Location Code", UpdateAddressDetails);
                end;
    end;

    local procedure CheckLocation(RequisitionLine: Record "Requisition Line")
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLocation(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        if InventorySetup."Location Mandatory" then
            RequisitionLine.TestField("Location Code");
    end;

    local procedure CheckInsertFinalizePurchaseOrderHeader(RequisitionLine: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header"; UpdateAddressDetails: Boolean): Boolean
    var
        CheckInsert: Boolean;
        CheckAddressDetailsResult: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCheckInsertFinalizePurchaseOrderHeaderOnBeforeCheckAddressDetails(RequisitionLine, CheckAddressDetailsResult, IsHandled);
        if not IsHandled then
            CheckAddressDetailsResult := CheckAddressDetails(RequisitionLine."Sales Order No.", RequisitionLine."Sales Order Line No.", UpdateAddressDetails);
        CheckInsert :=
              (PurchOrderHeader."Buy-from Vendor No." <> RequisitionLine."Vendor No.") or
              (PurchOrderHeader."Sell-to Customer No." <> RequisitionLine."Sell-to Customer No.") or
              (PrevShipToCode <> RequisitionLine."Ship-to Code") or
              (PurchOrderHeader."Order Address Code" <> RequisitionLine."Order Address Code") or
              (PurchOrderHeader."Currency Code" <> RequisitionLine."Currency Code") or
              (PrevPurchCode <> RequisitionLine."Purchasing Code") or
              CheckAddressDetailsResult;

        OnBeforeCheckInsertFinalizePurchaseOrderHeader(
            RequisitionLine, PurchOrderHeader, CheckInsert, OrderCounter, PrevPurchCode, PrevLocationCode, PrevShipToCode, UpdateAddressDetails, CheckAddressDetailsResult, ReceiveDateReq);
        exit(CheckInsert);
    end;

    local procedure CheckDropShptAddressDetails(SalesNo: Code[20]; UpdateAddressDetails: Boolean): Boolean
    var
        SalesHeader: Record "Sales Header";
        DropShptNameAddressDetails: Text;
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesNo);
        DropShptNameAddressDetails :=
          SalesHeader."Ship-to Name" + SalesHeader."Ship-to Name 2" +
          SalesHeader."Ship-to Address" + SalesHeader."Ship-to Address 2" +
          SalesHeader."Ship-to Post Code" + SalesHeader."Ship-to City" +
          SalesHeader."Ship-to Contact";
        if NameAddressDetails = '' then
            NameAddressDetails := DropShptNameAddressDetails;
        if NameAddressDetails = DropShptNameAddressDetails then
            exit(true);

        if UpdateAddressDetails then
            NameAddressDetails := DropShptNameAddressDetails;
        exit(false);
    end;

    local procedure CheckSpecOrderAddressDetails(LocationCode: Code[10]; UpdateAddressDetails: Boolean) Result: Boolean
    var
        Location: Record Location;
        CompanyInfo: Record "Company Information";
        SpecOrderNameAddressDetails: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSpecOrderAddressDetails(LocationCode, UpdateAddressDetails, NameAddressDetails, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Location.Get(LocationCode) then
            SpecOrderNameAddressDetails :=
              Location.Name + Location."Name 2" +
              Location.Address + Location."Address 2" +
              Location."Post Code" + Location.City +
              Location.Contact
        else begin
            CompanyInfo.Get();
            SpecOrderNameAddressDetails :=
              CompanyInfo."Ship-to Name" + CompanyInfo."Ship-to Name 2" +
              CompanyInfo."Ship-to Address" + CompanyInfo."Ship-to Address 2" +
              CompanyInfo."Ship-to Post Code" + CompanyInfo."Ship-to City" +
              CompanyInfo."Ship-to Contact";
        end;
        if NameAddressDetails = '' then
            NameAddressDetails := SpecOrderNameAddressDetails;
        if NameAddressDetails = SpecOrderNameAddressDetails then
            exit(true);

        if UpdateAddressDetails then
            NameAddressDetails := SpecOrderNameAddressDetails;
        exit(false);
    end;

    local procedure InitShipReceiveDetails()
    begin
        PrevShipToCode := '';
        PrevPurchCode := '';
        PrevLocationCode := '';
        NameAddressDetails := '';
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure PurchaseOrderLineMatchReqLine(ReqLine: Record "Requisition Line"): Boolean
    begin
        if PurchOrderLine."Drop Shipment" then
            exit(
              (ReqLine."Sales Order No." = PurchOrderLine."Sales Order No.") and
              (ReqLine."Sales Order Line No." = PurchOrderLine."Sales Order Line No."));

        if PurchOrderLine."Special Order" then
            exit(
              (ReqLine."Sales Order No." = PurchOrderLine."Special Order Sales No.") and
              (ReqLine."Sales Order Line No." = PurchOrderLine."Special Order Sales Line No."));

        exit(true);
    end;

    local procedure GetTransferHeader(var TransferHeader: Record "Transfer Header"; RequisitionLine: Record "Requisition Line")
    begin
        TempTransHeader.SetRange("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TempTransHeader.SetRange("Transfer-to Code", RequisitionLine."Location Code");
        if TempTransHeader.FindFirst() then
            TransferHeader.Get(TempTransHeader."No.");
    end;

    local procedure SetTransferHeader(TransferHeader: Record "Transfer Header")
    begin
        TempTransHeader := TransferHeader;
        if TempTransHeader.Insert() then;
    end;

    procedure GetCreatedDocumentBuffer(var TempDocumentEntry2: Record "Document Entry" temporary)
    begin
        TempDocumentEntry2.Copy(TempDocumentEntry, true);
    end;

    local procedure InitProgressWindow()
    begin
        if ReqTemplate.Recurring then
            Window.Open(
              Text000 +
              Text001 +
              Text002 +
              Text003 +
              Text004)
        else
            Window.Open(
              Text000 +
              Text001 +
              Text002 +
              Text003 +
              Text005);
    end;

    local procedure UpdateJobLink(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if RequisitionLine.Reserve then  //if reserve not set job link
            exit;

        if (RequisitionLine."Planning Line Origin" = RequisitionLine."Planning Line Origin"::"Order Planning") and
           (RequisitionLine."Demand Type" = Database::"Job Planning Line")
        then begin
            JobPlanningLine.SetRange("Job Contract Entry No.", RequisitionLine."Demand Line No.");
            JobPlanningLine.FindFirst();

            PurchaseLine.Validate("Job No.", JobPlanningLine."Job No.");
            PurchaseLine.Validate("Job Task No.", JobPlanningLine."Job Task No.");
            PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ReqLine: Record "Requisition Line"; PlanningResiliency: Boolean; SuppressCommit: Boolean; PrintPurchOrders: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutBatchActionCode(var RequisitionLine: Record "Requisition Line"; var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutReqLineAction(var RequisitionLine: Record "Requisition Line"; var Failed: Boolean; var IsHandled: Boolean; SuppressCommit: Boolean; var OrderCounter: Integer; PrintPurchOrders: Boolean; var NextLineNo: Integer; var PrevShipToCode: Code[10]; var PrevPurchCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchOrderLineShipToCode(var RequisitionLine: Record "Requisition Line"; PurchOrderLine: Record "Purchase Line"; SalesOrderHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyOrderDateFromPurchHeader(var RequisitionLine: Record "Requisition Line"; PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReqLines(var ReqLine: Record "Requisition Line"; var TempFailedReqLine: Record "Requisition Line" temporary; var IsHandled: Boolean; var ReqLine2: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetReqTemplate(RequisitionLine: Record "Requisition Line"; var ReqWkshTemplate: Record "Req. Wksh. Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertHeader(RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var OrderDateReq: Date; var PostingDateReq: Date; var ReceiveDateReq: Date; var ReferenceReq: Text[35]; var NameAddressDetails: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPurchOrderLine(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer; var IsHandled: Boolean; var PrevPurchCode: code[10]; var PrevShipToCode: code[10]; var PlanningResiliency: boolean; TempDocumentEntry: Record "Document Entry" temporary; var SuppressCommit: Boolean; var PostingDateReq: date; var ReferenceReq: text[35]; var OrderDateReq: date; var ReceiveDateReq: date; var OrderCounter: integer; var HideProgressWindow: Boolean; var PrevLocationCode: code[10]; var LineCount: Integer; var PurchOrderHeader: Record "Purchase Header"; PurchasingCode: record Purchasing; var PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessReqLineActions(var RequisitionLine: Record "Requisition Line"; CommitIsSuppressed: Boolean; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineInsert(var PurchOrderHeader: Record "Purchase Header"; var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderHeaderInsert(var PurchaseHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line"; var ReceiveDateReq: Date; var OrderDateReq: Date; var PostingDateReq: Date; var ReferenceReq: Text[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateNo(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchOrderLineValidateType(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckInsertFinalizePurchaseOrderHeader(RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var CheckInsert: Boolean; var OrderCounter: Integer; var PrevPurchCode: Code[10]; PrevLocationCode: Code[10]; var PrevShipToCode: Code[10]; var UpdateAddressDetails: Boolean; var CheckAddressDetailsResult: Boolean; ReceiveDateReq: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReqLineSortingKey(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFieldsForPurchase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var RequisitionLine: Record "Requisition Line"; OrderLineCounter: Integer; OrderCounter: Integer; PrintPurchOrders: Boolean; SuppressCommit: Boolean; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineInsert(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCarryOutReqLineAction(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; var OrderCounter: Integer; var LineCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveBindingOrderToPurch(var PurchaseLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(NewPurchOrderHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; EndingOrderDate: Date; PrintPurchOrder: Boolean; var OrderDateReq: Date; ReceiveDateReq: Date; var PostingDateReq: Date; var PurchOrderHeader: Record "Purchase Header"; ReferenceReq: Text[35])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReqWkshLine(var RequisitionLine: Record "Requisition Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitPurchOrderLine(var PurchaseLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseOrderHeader: Record "Purchase Header"; CommitIsSuppressed: Boolean; SpecialOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; var NextLineNo: Integer; var RequisitionLine: Record "Requisition Line"; var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeOrderHeader(var PurchHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinalizeOrderHeaderProcedure(var PurchHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchOrderLineValidateNo(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchOrderHeader(var PurchOrderHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShipToOrLocationCode(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRequisitionLines(var RequisitionLine: Record "Requisition Line"; var StartLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRunPrintPurchOrders(var TransHeader: Record "Transfer Header"; var PurchOrderHeader: Record "Purchase Header"; var TempPurchaseOrderToPrint: Record "Purchase Header" temporary; var PrintPurchOrders: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchOrderLineUpdateQuantity(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitPurchOrderLine(var ReqLine: record "Requisition Line"; var PurchasingCode: Record Purchasing; var PurchOrderHeader: Record "Purchase Header"; var LineCount: Integer; var NextLineNo: Integer; var PrevPurchCode: code[10]; var PrevShipToCode: code[10]; var PlanningResiliency: boolean; TempDocumentEntry: Record "Document Entry" temporary; var SuppressCommit: Boolean; var PostingDateReq: date; var ReferenceReq: text[35]; var OrderDateReq: date; var ReceiveDateReq: date; var OrderCounter: integer; var HideProgressWindow: Boolean; var IsHandled: Boolean; var PurchaseLineOrder: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeRecurringTexts(var RequisitionLine: Record "Requisition Line"; var PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnRun(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBuyFromVendorNo(var PurchOrderHeader: Record "Purchase Header"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutReqLineActionOnCaseReplenishmentSystemElse(var ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutReqLineActionOnAfterInsertTransLine(TransHeader: Record "Transfer Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNewNameNeccessary(RequisitionWkshName: Record "Requisition Wksh. Name"; var NewReqWkshName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckFurtherReplenishmentSystems(var RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterReqLine3SetFilters(ReqLine: Record "Requisition Line"; var ReqLine3: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeFinalizeOrderHeader(PurchOrderHeader: Record "Purchase Header"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOrderHeaderOnAfterSetFiltersForRecurringReqLine(var RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFinalizeOrderHeaderOnAfterSetFiltersForNonRecurringReqLine(var RequisitionLine: Record "Requisition Line"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; var TempFailedRequisitionLine: Record "Requisition Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOrderHeaderOnBeforeReqLine2Delete(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnAfterPurchOrderLineAssignVariantCode(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnBeforeUpdateQuantity(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnAfterValidateLineDiscount(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitPurchOrderLineOnBeforeValidateLineDiscount(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnAfterCheckInsertFinalizePurchaseOrderHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeInsertHeader(var RequisitionLine: Record "Requisition Line"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var LineCount: Integer; var NextLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeSalesOrderLineValidateUnitCostLCY(var PurchOrderLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeSalesOrderLineModify(var SalesOrderLine: Record "Sales Line"; var RequisitionLine: Record "Requisition Line"; var PurchOrderLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessReqLineActionsOnAfterSetFailedReqLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessReqLineActionsOnBeforeReqLineLoop(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInitProgressWindow(ReqTemplate: Record "Req. Wksh. Template"; var HideProgressWindow: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAddressDetails(SalesOrderNo: Code[20]; SalesLineNo: Integer; UpdateAddressDetails: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSpecOrderAddressDetails(LocationCode: Code[10]; UpdateAddressDetails: Boolean; var NameAddressDetails: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRequisitionLine(var ReqLine2: Record "Requisition Line"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRequsitionLineQuantity(var RequisitionLine: Record "Requisition Line"; var PurchOrderLine: Record "Purchase Line"; var SalesOrderLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckQuantity(var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRequisitionLineOnNonCancelActionMessageOnBeforeCheckUOM(var ReqLine2: Record "Requisition Line"; var PurchasingCode: Record Purchasing; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckRequisitionLineOnEmptyNewActionMessageOnBeforeOtherCheck(var ReqLine2: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeTransferReqLine(var PurchOrderHeader: Record "Purchase Header"; PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertHeaderOnBeforeValidateSellToCustNoFromReqLine(PurchOrderHeader: Record "Purchase Header"; ReqLine2: Record "Requisition Line"; var ShouldValidateSellToCustNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOrderHeaderOnBeforePrint(PrintPurchOrders: Boolean; PurchOrderHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinalizeOrderHeaderOnLoopLinesBeforeModifyForRecurrReqLines(var ReqLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchOrder(PurchaseHeader: Record "Purchase Header"; PrintPurchOrders: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertHeaderOnBeforeSetShipToForSpecOrder(var PurchaseHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line"; var ShouldSetShipToForSpecOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCarryOutBatchAction(var RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTryCarryOutReqLineAction(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLocation(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReserveBindingOrderToPurch(var RequisitionLine: Record "Requisition Line"; var PurchaseLine: Record "Purchase Line"; ReservQty: Decimal; ReservQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchOrderLineOnBeforeUpdateAssociatedSalesLine(var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCheckInsertFinalizePurchaseOrderHeaderOnBeforeCheckAddressDetails(var RequisitionLine: Record "Requisition Line"; var CheckAddressDetailsResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeSetPurchOrderHeader(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterFilterReqLine(var RequisitionLine: Record "Requisition Line"; PlanningResiliency: Boolean; SuppressCommit: Boolean; PrintPurchOrders: Boolean)
    begin
    end;
}

