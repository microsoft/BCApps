// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;

tableextension 7000006 "CRT Vendor Ledger Entry" extends "Vendor Ledger Entry"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Document Situation"; Enum "ES Document Situation")
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
    }

    var
        CannotChangePmtMethodErr: Label 'For Cartera-based bills and invoices, you cannot change the Payment Method Code to this value.';
        CheckBillSituationOrderErr: Label '%1 cannot be applied because it is included in a payment order. To apply the document, remove it from the payment order and try again.', Comment = '%1 - document type and number';
        CheckBillSituationPostedErr: Label '%1 cannot be applied because it is included in a posted payment order.', Comment = '%1 - document type and number';

    [Scope('OnPrem')]
    procedure CheckBillSituation()
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        OnBeforeCheckBillSituation(Rec);

        case true of
            CarteraDoc.Get(CarteraDoc.Type::Payable, "Entry No."):
                if CarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    Error(CheckBillSituationOrderErr, Description);
            PostedCarteraDoc.Get(PostedCarteraDoc.Type::Payable, "Entry No."):
                if PostedCarteraDoc."Bill Gr./Pmt. Order No." <> '' then
                    Error(CheckBillSituationPostedErr, Description);
        end;
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBillSituation(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;
}
