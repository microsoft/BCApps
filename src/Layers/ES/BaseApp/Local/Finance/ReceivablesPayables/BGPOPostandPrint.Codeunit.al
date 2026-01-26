// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000003 "BG/PO-Post and Print"
{
    Permissions = TableData "Bill Group" = rm,
                  TableData "Posted Bill Group" = rm,
                  TableData "Closed Bill Group" = rm,
                  TableData "Payment Order" = rm,
                  TableData "Posted Payment Order" = rm,
                  TableData "Closed Payment Order" = rm;

    trigger OnRun()
    begin
    end;

    var
        Text1100000: Label 'This Bill Group has not been printed. Do you want to continue?';
        Text1100001: Label 'The posting process has been cancelled by the user.';
        Text1100002: Label 'Do you want to post the Bill Group?';
        Text1100003: Label 'This Payment Order has not been printed. Do you want to continue?';
        Text1100004: Label 'Do you want to post the Payment Order?';
        CarteraReportSelection: Record "Cartera Report Selections";

    procedure ReceivablePostOnly(BillGr: Record "Bill Group")
    begin
        if BillGr."No. Printed" = 0 then begin
            if not Confirm(Text1100000) then
                Error(Text1100001);
        end else
            if not Confirm(Text1100002, false) then
                Error(Text1100001);

        BillGr.SetRecFilter();
        REPORT.RunModal(REPORT::"Post Bill Group", BillGr."Dealing Type" = BillGr."Dealing Type"::Discount, false, BillGr);
    end;

    procedure ReceivablePostAndPrint(BillGr: Record "Bill Group")
    var
        PostedBillGr: Record "Posted Bill Group";
    begin
        BillGr.SetRecFilter();
        REPORT.RunModal(REPORT::"Post Bill Group", BillGr."Dealing Type" = BillGr."Dealing Type"::Discount, false, BillGr);

        Commit();

        if PostedBillGr.Get(BillGr."No.") then begin
            PostedBillGr.SetRecFilter();
            CarteraReportSelection.Reset();
            CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Posted Bill Group");
            CarteraReportSelection.Find('-');
            repeat
                CarteraReportSelection.TestField("Report ID");
                REPORT.Run(CarteraReportSelection."Report ID", false, false, PostedBillGr);
            until CarteraReportSelection.Next() = 0;
        end;
    end;

    procedure PayablePostOnly(PmtOrd: Record "Payment Order")
    var
        IsHandled: Boolean;
    begin
        OnBeforePayablePostOnly(PmtOrd, IsHandled);
        if not IsHandled then
            if PmtOrd."No. Printed" = 0 then begin
                if not Confirm(Text1100003) then
                    Error(Text1100001);
            end else
                if not Confirm(Text1100004, false) then
                    Error(Text1100001);

        PmtOrd.SetRecFilter();
        REPORT.RunModal(REPORT::"Post Payment Order", false, false, PmtOrd);

        OnAfterPayablePostOnly(PmtOrd);
    end;

    procedure PayablePostAndPrint(PmtOrd: Record "Payment Order")
    var
        PostedPmtOrd: Record "Posted Payment Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePayablePostAndPrint(PmtOrd, IsHandled);
        if not IsHandled then begin
            PmtOrd.SetRecFilter();
            REPORT.RunModal(REPORT::"Post Payment Order", false, false, PmtOrd);

            Commit();

            if PostedPmtOrd.Get(PmtOrd."No.") then begin
                PostedPmtOrd.SetRecFilter();
                CarteraReportSelection.Reset();
                CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::"Posted Payment Order");
                CarteraReportSelection.Find('-');
                repeat
                    CarteraReportSelection.TestField("Report ID");
                    REPORT.Run(CarteraReportSelection."Report ID", false, false, PostedPmtOrd);
                until CarteraReportSelection.Next() = 0;
            end;
        end;

        OnAfterPayablePostAndPrint(PmtOrd);
    end;

    procedure PrintCounter("Table": Integer; Number: Code[20])
    var
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        PostedPaymentOrder: Record "Posted Payment Order";
        ClosedPaymentOrder: Record "Closed Payment Order";
        BillGr: Record "Bill Group";
        PaymentOrder: Record "Payment Order";
    begin
        case true of
            Table = DATABASE::"Bill Group":
                begin
                    BillGr.Get(Number);
                    BillGr."No. Printed" := BillGr."No. Printed" + 1;
                    BillGr.Modify();
                end;
            Table = DATABASE::"Payment Order":
                begin
                    PaymentOrder.Get(Number);
                    PaymentOrder."No. Printed" := PaymentOrder."No. Printed" + 1;
                    PaymentOrder.Modify();
                end;
            Table = DATABASE::"Posted Bill Group":
                begin
                    PostedBillGr.Get(Number);
                    PostedBillGr."No. Printed" := PostedBillGr."No. Printed" + 1;
                    PostedBillGr.Modify();
                end;
            Table = DATABASE::"Closed Bill Group":
                begin
                    ClosedBillGr.Get(Number);
                    ClosedBillGr."No. Printed" := ClosedBillGr."No. Printed" + 1;
                    ClosedBillGr.Modify();
                end;
            Table = DATABASE::"Posted Payment Order":
                begin
                    PostedPaymentOrder.Get(Number);
                    PostedPaymentOrder."No. Printed" := PostedPaymentOrder."No. Printed" + 1;
                    PostedPaymentOrder.Modify();
                end;
            Table = DATABASE::"Closed Payment Order":
                begin
                    ClosedPaymentOrder.Get(Number);
                    ClosedPaymentOrder."No. Printed" := ClosedPaymentOrder."No. Printed" + 1;
                    ClosedPaymentOrder.Modify();
                end;
        end;
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPayablePostOnly(var PaymentOrder: Record "Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPayablePostAndPrint(var PaymentOrder: Record "Payment Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePayablePostOnly(var PaymentOrder: Record "Payment Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePayablePostAndPrint(var PaymentOrder: Record "Payment Order"; var IsHandled: Boolean)
    begin
    end;
}

