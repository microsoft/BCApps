// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;

codeunit 12171 "Vend. Bill List-Change Status"
{
    Permissions = TableData "Vendor Ledger Entry" = rimd;
    TableNo = "Vendor Bill Header";

    trigger OnRun()
    begin
        if not Confirm(Text000) then
            exit;

        FromOpenToSent(Rec);
    end;

    var
        Text000: Label 'Do you want to send the bill?';
        Text001: Label 'There are not lines to send.';
        Text002: Label '%1 or %2 for this %3 has not yet inserted. Please specify it in table %4 before running this function.';
        Text003: Label '%1 is not specified in %2 %3. Please specify it before running this function.';
        Text004: Label 'This operation will cause a gap in the numbering of %1. Continue anyway?';
        VendLedgEntry: Record "Vendor Ledger Entry";
        PaymentMethod: Record "Payment Method";
        BillCode: Record Bill;
        VendorBillLine: Record "Vendor Bill Line";
        NextVendBillNo: Code[20];

    procedure FromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    var
        NoSeries: Codeunit "No. Series";
    begin
        OnBeforeFromOpenToSent(VendorBillHeader);

        VendorBillHeader.TestField("Posting Date");

        VendorBillLine.Reset();
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.SetCurrentKey("Vendor No.", "External Document No.", "Document Date");
        if not VendorBillLine.Find('-') then
            Error(Text001);

        PaymentMethod.Get(VendorBillHeader."Payment Method Code");
        BillCode.LockTable();
        BillCode.Get(PaymentMethod."Bill Code");
        if (BillCode."Vendor Bill List" = '') or
           (BillCode."Vendor Bill No." = '')
        then
            Error(Text002,
              BillCode.FieldCaption("Vendor Bill List"),
              BillCode.FieldCaption("Vendor Bill No."),
              VendorBillHeader.FieldCaption("Payment Method Code"),
              BillCode.TableCaption());
        VendorBillHeader."Vendor Bill List No." := NoSeries.GetNextNo(BillCode."Vendor Bill List", VendorBillHeader."Posting Date");
        VendorBillHeader."List Status" := VendorBillHeader."List Status"::Sent;
        VendorBillHeader."User ID" := UserId;
        VendorBillHeader.Modify();

        repeat
            if VendorBillLine."Due Date" = 0D then
                Error(Text003,
                  VendorBillLine.FieldCaption("Due Date"),
                  VendorBillLine.FieldCaption("Line No."),
                  VendorBillLine."Line No.");
            if not VendorBillLine."Manual Line" then begin
                NextVendBillNo := NoSeries.GetNextNo(BillCode."Vendor Bill No.", VendorBillHeader."Posting Date");
                VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                VendLedgEntry."Vendor Bill List" := VendorBillHeader."Vendor Bill List No.";
                VendLedgEntry."Vendor Bill No." := NextVendBillNo;
                VendLedgEntry.Modify();
            end;
            VendorBillLine."Vendor Bill No." := NextVendBillNo;
            OnFromOpenToSentOnBeforeVendorBillLineModify(VendorBillLine);
            VendorBillLine.Modify();
        until VendorBillLine.Next() = 0;

        OnAfterFromOpenToSent(VendorBillHeader);
    end;

    procedure FromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
        OnBeforeFromSentToOpen(VendorBillHeader);

        if not Confirm(Text004, false, VendorBillHeader.FieldCaption("Vendor Bill List No.")) then
            exit;

        VendorBillHeader."Vendor Bill List No." := '';
        VendorBillHeader."List Status" := VendorBillHeader."List Status"::Open;
        VendorBillHeader."User ID" := UserId;
        VendorBillHeader.Modify();

        VendorBillLine.Reset();
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.SetCurrentKey("Vendor No.", "External Document No.", "Document Date");
        if VendorBillLine.FindSet() then
            repeat
                if not VendorBillLine."Manual Line" then begin
                    VendLedgEntry.Get(VendorBillLine."Vendor Entry No.");
                    VendLedgEntry."Vendor Bill List" := '';
                    VendLedgEntry."Vendor Bill No." := '';
                    VendLedgEntry.Modify();
                end;
                VendorBillLine."Vendor Bill No." := '';
                VendorBillLine.Modify();
            until VendorBillLine.Next() = 0;

        OnAfterFromSentToOpen(VendorBillHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromOpenToSent(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromSentToOpen(var VendorBillHeader: Record "Vendor Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromOpenToSentOnBeforeVendorBillLineModify(var VendorBillLine: Record "Vendor Bill Line")
    begin
    end;
}

