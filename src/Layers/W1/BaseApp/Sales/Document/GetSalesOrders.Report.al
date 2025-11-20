// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

report 698 "Get Sales Orders"
{
    Caption = 'Get Sales Orders';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Sales Line"; "Sales Line")
        {
            DataItemTableView = where("Document Type" = const(Order), Type = const(Item), "Purch. Order Line No." = const(0), "Outstanding Quantity" = filter(<> 0));
            RequestFilterFields = "Document No.", "Sell-to Customer No.", "No.";
            RequestFilterHeading = 'Sales Order Line';

            trigger OnAfterGetRecord()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnAfterGetRecord("Sales Line", IsHandled);
                if IsHandled then
                    CurrReport.Skip();

                if ("Purchasing Code" = '') and (SpecOrder <> 1) then
                    if "Drop Shipment" then begin
                        LineCount := LineCount + 1;
                        if not HideDialog then
                            Window.Update(1, LineCount);
                        InsertReqWkshLine("Sales Line", ReqLine);
                    end;

                if "Purchasing Code" <> '' then
                    if PurchasingCode.Get("Purchasing Code") then
                        if PurchasingCode."Drop Shipment" and (SpecOrder <> 1) then begin
                            LineCount := LineCount + 1;
                            if not HideDialog then
                                Window.Update(1, LineCount);
                            InsertReqWkshLine("Sales Line", ReqLine);
                        end else
                            if PurchasingCode."Special Order" and
                               ("Special Order Purchase No." = '') and
                               (SpecOrder <> 0)
                            then begin
                                LineCount := LineCount + 1;
                                if not HideDialog then
                                    Window.Update(1, LineCount);
                                InsertReqWkshLine("Sales Line", ReqLine);
                            end;
            end;

            trigger OnPostDataItem()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnPostDataItemOnBeforeCheckLineCount(LineCount, IsHandled);
                if (not HideDialog) and (not IsHandled) then
                    if LineCount = 0 then
                        Error(Text001);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(GetDim; GetDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Retrieve dimensions from';
                        OptionCaption = 'Item,Sales Line';
                        ToolTip = 'Specifies the source of dimensions that will be copied in the batch job. Dimensions can be copied exactly as they were used on a sales line or can be copied from the items used on a sales line.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(HideDialog);
        ReqWkshTmpl.Get(ReqLine."Worksheet Template Name");
        ReqWkshName.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine.LockTable();
        if ReqLine.FindLast() then begin
            ReqLine.Init();
            LineNo := ReqLine."Line No.";
        end;
        if not HideDialog then
            Window.Open(Text000);
    end;

    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        SalesHeader: Record "Sales Header";
        PurchasingCode: Record Purchasing;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        LineCount: Integer;
        GetDim: Option Item,"Sales Line";
        HideDialog: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing sales lines  #1######';
#pragma warning restore AA0470
        Text001: Label 'There are no sales lines to retrieve.';
#pragma warning restore AA0074

    protected var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        LineNo: Integer;
        SpecOrder: Integer;

    procedure SetReqWkshLine(NewReqLine: Record "Requisition Line"; SpecialOrder: Integer)
    begin
        ReqLine := NewReqLine;
        SpecOrder := SpecialOrder;
    end;

    procedure InsertReqWkshLine(SalesLine: Record "Sales Line"; var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertReqWkshLineOnBeforeCode(ReqLine, SalesLine, SpecOrder, LineNo, ReqWkshName, GetDim, IsHandled);
        if IsHandled then
            exit;

        ReqLine.Reset();
        ReqLine.SetCurrentKey(Type, "No.");
        ReqLine.SetRange(Type, SalesLine.Type);
        ReqLine.SetRange("No.", SalesLine."No.");
        ReqLine.SetRange("Sales Order No.", SalesLine."Document No.");
        ReqLine.SetRange("Sales Order Line No.", SalesLine."Line No.");
        if ReqLine.FindFirst() then
            exit;

        LineNo := LineNo + 10000;
        Clear(ReqLine);
        ReqLine.Init();
        ReqLine."Worksheet Template Name" := ReqWkshName."Worksheet Template Name";
        ReqLine."Journal Batch Name" := ReqWkshName.Name;
        ReqLine."Line No." := LineNo;
        ReqLine.Validate(Type, SalesLine.Type);
        OnInsertReqWkshLineOnAfterValidateType(ReqLine, SalesLine, SpecOrder);
        ReqLine."Location Code" := SalesLine."Location Code";
        ReqLine."Drop Shipment" := SalesLine."Drop Shipment";
        ReqLine.Validate("No.", SalesLine."No.");
        ReqLine."Variant Code" := SalesLine."Variant Code";
        ReqLine.Validate("Location Code");
        ReqLine."Bin Code" := SalesLine."Bin Code";
        OnInsertReqWkshLineOnAfterSetBinCode(ReqLine, SalesLine, PurchasingCode);

        // Drop Shipment means replenishment by purchase only
        if (ReqLine."Replenishment System" <> ReqLine."Replenishment System"::Purchase) and
            ReqLine."Drop Shipment"
        then
            ReqLine.Validate("Replenishment System", ReqLine."Replenishment System"::Purchase);

        IsHandled := false;
        OnInsertReqWkshLineOnBeforeValidateUoM(ReqLine, SalesLine, SpecOrder, IsHandled);
        if not IsHandled then
            ReqLine.Validate("Unit of Measure Code", SalesLine."Unit of Measure Code");
        ValidateRequisitionLineQuantity(ReqLine, SalesLine);

        IsHandled := false;
        OnInsertReqWkshLineOnBeforeSetInsertRequisitionLineBatch(ReqLine, SalesLine, IsHandled);
        if not IsHandled then begin
            ReqLine."Sales Order No." := SalesLine."Document No.";
            ReqLine."Sales Order Line No." := SalesLine."Line No.";
            IsHandled := false;
            OnInsertReqWkshLineOnBeforeSetSellToCustomerNo(ReqLine, SalesLine, SpecOrder, IsHandled);
            if not IsHandled then
                ReqLine."Sell-to Customer No." := SalesLine."Sell-to Customer No.";
            SalesHeader.Get(1, SalesLine."Document No.");
            if SpecOrder <> 1 then
                ReqLine."Ship-to Code" := SalesHeader."Ship-to Code";
            ReqLine."Item Category Code" := SalesLine."Item Category Code";
            ReqLine.Nonstock := SalesLine.Nonstock;
            ReqLine."Action Message" := "Action Message Type"::New;
            ReqLine."Purchasing Code" := SalesLine."Purchasing Code";
            // Backward Scheduling
            ReqLine."Due Date" := SalesLine."Shipment Date";
            OnInsertReqWkshLineOnBeforeCalcEndingDate(ReqLine, SalesLine);
            ReqLine."Ending Date" :=
                LeadTimeMgt.GetPlannedEndingDate(
                    ReqLine."No.", ReqLine."Location Code", ReqLine."Variant Code", ReqLine."Due Date",
                    ReqLine."Vendor No.", ReqLine."Ref. Order Type");
            ReqLine.CalcStartingDate('');
            ReqLine.UpdateDescription();
            ReqLine.UpdateDatetime();

            OnBeforeInsertReqWkshLine(ReqLine, SalesLine, SpecOrder);
            ReqLine.Insert();
            ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1(), ReqLine.RowID1(), true);
            if GetDim = GetDim::"Sales Line" then begin
                ReqLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
                ReqLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
                ReqLine."Dimension Set ID" := SalesLine."Dimension Set ID";
                ReqLine.Modify();
            end;
        end;

        OnAfterInsertReqWkshLine(ReqLine, SalesLine);
    end;

    local procedure ValidateRequisitionLineQuantity(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateRequisitionLineQuantity(RequisitionLine, SalesLine, SpecOrder, IsHandled);
        if IsHandled then
            exit;

        RequisitionLine.Validate(
          Quantity,
          Round(
            SalesLine."Outstanding Quantity" * SalesLine."Qty. per Unit of Measure" / RequisitionLine."Qty. per Unit of Measure",
            UOMMgt.QtyRndPrecision()));
    end;

    procedure InitializeRequest(NewRetrieveDimensionsFrom: Option)
    begin
        GetDim := NewRetrieveDimensionsFrom;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReqWkshLine(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReqWkshLine(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetRecord(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRequisitionLineQuantity(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReqWkshLineOnBeforeValidateUoM(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReqWkshLineOnBeforeSetSellToCustomerNo(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertReqWkshLineOnBeforeCode(var ReqLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer; var LineNo: Integer; ReqWkshName: Record "Requisition Wksh. Name"; GetDim: Option Item,"Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDataItemOnBeforeCheckLineCount(LineCount: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReqWkshLineOnAfterValidateType(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; SpecOrder: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReqWkshLineOnAfterSetBinCode(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; var PurchasingCode: Record Purchasing)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReqWkshLineOnBeforeCalcEndingDate(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertReqWkshLineOnBeforeSetInsertRequisitionLineBatch(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
}

