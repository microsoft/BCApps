// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 7000008 "Document-Edit"
{
    Permissions = TableData "Cartera Doc." = imd,
                  TableData "Cust. Ledger Entry" = m,
                  TableData "Vendor Ledger Entry" = m,
                  TableData "Detailed Cust. Ledg. Entry" = m,
                  TableData "Detailed Vendor Ledg. Entry" = m;
    TableNo = "Cartera Doc.";

    trigger OnRun()
    begin
        CarteraDoc := Rec;
        CarteraDoc.LockTable();
        CarteraDoc.Find();
        CarteraDoc."Category Code" := Rec."Category Code";
        CarteraDoc."Direct Debit Mandate ID" := Rec."Direct Debit Mandate ID";
        if Rec."Bill Gr./Pmt. Order No." = '' then begin
            CarteraDoc."Due Date" := Rec."Due Date";
            CarteraDoc."Cust./Vendor Bank Acc. Code" := Rec."Cust./Vendor Bank Acc. Code";
            CarteraDoc."Collection Agent" := Rec."Collection Agent";
            CarteraDoc.Accepted := Rec.Accepted;
        end;
        OnBeforeModifyCarteraDoc(CarteraDoc, Rec);
        CarteraDoc.Modify();
        Rec := CarteraDoc;
    end;

    var
        CarteraDoc: Record "Cartera Doc.";

    [Scope('OnPrem')]
    procedure EditDueDate(CarteraDoc: Record "Cartera Doc.")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        case CarteraDoc.Type of
            CarteraDoc.Type::Receivable:
                begin
                    CustLedgEntry.Get(CarteraDoc."Entry No.");
                    CustLedgEntry."Due Date" := CarteraDoc."Due Date";
                    CustLedgEntry.Modify();
                    DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
                    DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
                    DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", CarteraDoc."Due Date");
                end;
            CarteraDoc.Type::Payable:
                begin
                    VendLedgEntry.Get(CarteraDoc."Entry No.");
                    VendLedgEntry."Due Date" := CarteraDoc."Due Date";
                    VendLedgEntry.Modify();
                    DtldVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Posting Date");
                    DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendLedgEntry."Entry No.");
                    DtldVendLedgEntry.ModifyAll("Initial Entry Due Date", CarteraDoc."Due Date");
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyCarteraDoc(var CarteraDoc: Record "Cartera Doc."; CurrCarteraDoc: Record "Cartera Doc.")
    begin
    end;
}

