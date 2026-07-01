// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;

tableextension 7000089 "CRT Cust. Ledger Entry" extends "Cust. Ledger Entry"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Document Situation"; Enum Microsoft."ES Document Situation")
        {
            Caption = 'Document Situation';
            DataClassification = CustomerContent;
        }
        field(7000002; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000003; "Document Status"; Enum "ES Document Status")
        {
            Caption = 'Document Status';
            DataClassification = CustomerContent;
        }
        field(7000005; "Remaining Amount (LCY) stats."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Amount (LCY) stats.';
            DataClassification = CustomerContent;
        }
        field(7000006; "Amount (LCY) stats."; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount (LCY) stats.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key7000000; "Bill No.")
        {
        }
        key(Key7000001; "Document Situation", "Document Status")
        {
            SumIndexFields = "Remaining Amount (LCY) stats.", "Amount (LCY) stats.";
        }
    }

    var
        CannotChangePmtMethodErr: Label 'For Cartera-based bills and invoices, you cannot change the Payment Method Code to this value.';
        CheckBillSituationGroupErr: Label '%1 cannot be applied because it is included in a bill group. To apply the document, remove it from the bill group and try again.', Comment = '%1 - document type and number';
        CheckBillSituationPostedErr: Label '%1 cannot be applied because it is included in a posted bill group.', Comment = '%1 - document type and number';

#if not CLEAN27
    [Obsolete('Replaced by W1 version of procedure', '27.0')]
    procedure SetApplyToFilters(CustomerNo: Code[20]; ApplyDocType: Option; ApplyDocNo: Code[20]; ApplyBillNo: Code[20]; ApplyAmount: Decimal)
    begin
        SetCurrentKey("Customer No.", Open, Positive, "Due Date");
        SetRange("Customer No.", CustomerNo);
        SetRange(Open, true);
        SetFilter("Document Situation", '<>%1', "Document Situation"::"Posted BG/PO");
        if ApplyDocNo <> '' then begin
            SetRange("Document Type", ApplyDocType);
            SetRange("Document No.", ApplyDocNo);
            if ApplyBillNo <> '' then
                SetRange("Bill No.", ApplyBillNo);
            if FindFirst() then;
            SetRange("Document Type");
            SetRange("Document No.");
            SetRange("Bill No.");
        end else
            if ApplyDocType <> 0 then begin
                SetRange("Document Type", ApplyDocType);
                if FindFirst() then;
                SetRange("Document Type");
            end else
                if ApplyAmount <> 0 then begin
                    SetRange(Positive, ApplyAmount < 0);
                    if FindFirst() then;
                    SetRange(Positive);
                end;
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by W1 version of procedure', '27.0')]
    procedure SetAmountToApply(AppliesToDocNo: Code[20]; CustomerNo: Code[20]; var AppliesToBillNo: Code[20])
    begin
        SetAmountToApply(AppliesToDocNo, CustomerNo);
        AppliesToBillNo := "Bill No.";
    end;
#endif

    procedure ValidatePaymentMethod()
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get("Payment Method Code");
        if (("Document Type" = "Document Type"::Bill) and not PaymentMethod."Create Bills") or
           (("Document Type" = "Document Type"::Invoice) and
            ("Document Situation" <> "Document Situation"::" ") and
            not PaymentMethod."Invoices to Cartera")
        then
            Error(CannotChangePmtMethodErr);
    end;

    [Scope('OnPrem')]
    procedure PrintBill(ShowRequestForm: Boolean)
    var
        CarteraReportSelection: Record "Cartera Report Selections";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Copy(Rec);
        CarteraReportSelection.SetRange(Usage, CarteraReportSelection.Usage::Bill);
        CarteraReportSelection.SetFilter("Report ID", '<>0');
        CarteraReportSelection.Find('-');
        repeat
            REPORT.RunModal(CarteraReportSelection."Report ID", ShowRequestForm, false, CustLedgEntry);
        until CarteraReportSelection.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckBillSituation()
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        OnBeforeCheckBillSituation(Rec);

        case true of
            CarteraDoc.Get(CarteraDoc.Type::Receivable, "Entry No."):
                if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    Error(CheckBillSituationGroupErr, Description);
            PostedCarteraDoc.Get(PostedCarteraDoc.Type::Receivable, "Entry No."):
                if PostedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    Error(CheckBillSituationPostedErr, Description);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBillSituation(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

}