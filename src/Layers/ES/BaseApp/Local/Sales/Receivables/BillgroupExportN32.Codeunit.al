// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.DirectDebit;

codeunit 7000093 "Bill group - Export N32"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    var
        BillGroup: Record "Bill Group";
        DirectDebitCollection: Record "Direct Debit Collection";
        BillGroupNo: Code[20];
    begin
        DirectDebitCollection.Get(Rec.GetRangeMin("Direct Debit Collection No."));
        BillGroupNo := DirectDebitCollection.Identifier;
        DirectDebitCollection.Delete();
        if not BillGroup.Get(BillGroupNo) then
            Error(ExportDirectDebitErr);
        Commit();
        REPORT.Run(REPORT::"Bill group - Export N32", true, false, BillGroup);
    end;

    var
        ExportDirectDebitErr: Label 'You cannot export the direct debit with the selected SEPA Direct Debit Exp. Format in To Bank Account No.';
}

