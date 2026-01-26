// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 13413 "Exp. SEPA CT pain.001.001.09"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        if (Rec.GetFilter("Journal Template Name") <> '') and (Rec.GetFilter("Journal Batch Name") <> '') and (Rec.GetFilter("Document No.") <> '') then
            Error(ExportRefPmtErr);

        RefPmtExp.SetRange(Transferred, false);
        RefPmtExp.SetRange("Applied Payments", false);
        RefPmtExp.SetRange("SEPA Payment", true);
        REPORT.Run(REPORT::"Exp. SEPA CT pain.001.001.09", false, false, RefPmtExp);
    end;

    var
        RefPmtExp: Record "Ref. Payment - Exported";
        ExportRefPmtErr: Label 'Your export format is not set up to export bank Payments with this function. Use the function in the Bank Payment to Send window instead.';
}

