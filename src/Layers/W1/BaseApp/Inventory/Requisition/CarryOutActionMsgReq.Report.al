// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Purchases.Document;

report 493 "Carry Out Action Msg. - Req."
{
    Caption = 'Carry Out Action Msg. - Req.';
    ProcessingOnly = true;

    dataset
    {
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
                    field(PrintOrders; PrintOrders)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Print Orders';
                        ToolTip = 'Specifies whether to print the purchase orders after they are created.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PurchOrderHeader."Order Date" := WorkDate();
            PurchOrderHeader."Posting Date" := WorkDate();
            if ReqWkshTmpl.Recurring then
                EndOrderDate := WorkDate()
            else
                EndOrderDate := 0D;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport(PrintOrders);

        UseOneJnl(ReqLine);
    end;

    trigger OnPostReport()
    begin
        OnBeforePostReport(ReqWkshMakeOrders);
    end;

    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when you create orders';
        Text001: Label 'There is nothing to create.';
#pragma warning disable AA0470
        Text003: Label 'You are now in worksheet %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        PurchOrderHeader: Record "Purchase Header";
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        EndOrderDate: Date;
        PrintOrders: Boolean;

    procedure SetReqWkshLine(var NewReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeSetReqWkshLine(ReqLine, NewReqLine, IsHandled);
        if IsHandled then
            exit;
        ReqLine.Copy(NewReqLine);
        ReqWkshTmpl.Get(NewReqLine."Worksheet Template Name");

        OnAfterSetReqWkshLine(NewReqLine);
    end;

    procedure GetReqWkshLine(var NewReqLine: Record "Requisition Line")
    begin
        NewReqLine.Copy(ReqLine);
    end;

    procedure SetReqWkshName(var NewReqWkshName: Record "Requisition Wksh. Name")
    begin
        ReqWkshName.Copy(NewReqWkshName);
        ReqWkshTmpl.Get(NewReqWkshName."Worksheet Template Name");
    end;

    local procedure UseOneJnl(var ReqLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        ReqWkshTmpl.Get(ReqLine."Worksheet Template Name");
        if ReqWkshTmpl.Recurring and (ReqLine.GetFilter(ReqLine."Order Date") <> '') then
            ReqLine.FieldError("Order Date", Text000);
        TempJnlBatchName := ReqLine."Journal Batch Name";
        IsHandled := false;
        OnUseOneJnlOnBeforeSetReqWkshMakeOrdersParameters(ReqLine, ReqWkshMakeOrders, PurchOrderHeader, EndOrderDate, PrintOrders, SuppressCommit, IsHandled);
        if not IsHandled then begin
            ReqWkshMakeOrders.Set(PurchOrderHeader, EndOrderDate, PrintOrders);
            ReqWkshMakeOrders.SetSuppressCommit(SuppressCommit);
            ReqWkshMakeOrders.CarryOutBatchAction(ReqLine);
        end;

        if ReqLine."Line No." = 0 then
            Message(Text001)
        else
            if not HideDialog then
                if TempJnlBatchName <> ReqLine."Journal Batch Name" then
                    Message(
                      Text003,
                      ReqLine."Journal Batch Name");

        if not ReqLine.Find('=><') or (TempJnlBatchName <> ReqLine."Journal Batch Name") then begin
            ReqLine.Reset();
            ReqLine.FilterGroup := 2;
            ReqLine.SetRange(ReqLine."Worksheet Template Name", ReqLine."Worksheet Template Name");
            ReqLine.SetRange(ReqLine."Journal Batch Name", ReqLine."Journal Batch Name");
            ReqLine.FilterGroup := 0;
            ReqLine."Line No." := 1;
        end;
    end;

    procedure InitializeRequest(ExpirationDate: Date; OrderDate: Date; PostingDate: Date; ExpectedReceiptDate: Date; YourRef: Text[50])
    begin
        EndOrderDate := ExpirationDate;
        PurchOrderHeader."Order Date" := OrderDate;
        PurchOrderHeader."Posting Date" := PostingDate;
        PurchOrderHeader."Expected Receipt Date" := ExpectedReceiptDate;
        PurchOrderHeader."Your Reference" := YourRef;
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetSupressCommit(NewSupressCommit: Boolean)
    begin
        SuppressCommit := NewSupressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReqWkshLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePreReport(var PrintOrders: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostReport(var ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUseOneJnlOnBeforeSetReqWkshMakeOrdersParameters(var ReqLine: Record "Requisition Line"; var ReqWkshMakeOrders: Codeunit "Req. Wksh.-Make Order"; PurchOrderHeader: Record "Purchase Header"; EndOrderDate: Date; PrintOrders: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetReqWkshLine(var RequisitionLine: Record "Requisition Line"; var NewReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;
}

