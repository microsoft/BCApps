// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.History;

codeunit 1256 "Post Late Gen. Journal Lines"
{

    trigger OnRun()
    begin
        SalesInvoiceHeader.SetRange("Your Reference", XLATETxt);
        if SalesInvoiceHeader.FindSet() then
            repeat
                GenJournalLine.SetRange("Account No.", SalesInvoiceHeader."Bill-to Customer No.");
                GenJournalLine.SetRange(Description, SalesInvoiceHeader."Pre-Assigned No.");
                if GenJournalLine.FindFirst() then begin
                    SalesInvoiceHeader.CalcFields("Remaining Amount");
                    GenJournalLine.Validate("Document No.", SalesInvoiceHeader."No.");
                    GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
                    GenJournalLine.Validate("Applies-to Doc. No.", SalesInvoiceHeader."No.");
                    GLAccount.SetRange(Blocked, false);
                    GLAccount.SetRange("Direct Posting", true);
                    GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                    GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
                    GLAccount.FindFirst();
                    GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
                    GenJournalLine.Validate(Amount, -Round(SalesInvoiceHeader."Remaining Amount", 0.01));
                    CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJournalLine);
                    GenJournalLine.Delete();
                end;
            until SalesInvoiceHeader.Next() = 0;
    end;

    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        XLATETxt: Label 'LATE', Comment = 'Late';
        GLAccount: Record "G/L Account";
}

