// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 13515 "Export SEPA Payment File FI"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
#if not CLEAN30
        BankingFeature.EnsureEnabled();
#endif
        if (Rec.GetFilter("Journal Template Name") <> '') and (Rec.GetFilter("Journal Batch Name") <> '') and (Rec.GetFilter("Document No.") <> '') then
            Error(ExportRefPmtErr);

        RefPmtExp.SetRange(Transferred, false);
        RefPmtExp.SetRange("Applied Payments", false);
        RefPmtExp.SetRange("SEPA Payment", true);
        REPORT.Run(REPORT::"Export SEPA Payment File FI", false, false, RefPmtExp);
    end;

    var
        RefPmtExp: Record "Ref. Payment - Exported FI";
        ExportRefPmtErr: Label 'Your export format is not set up to export bank Payments with this function. Use the function in the Bank Payment to Send window instead.';

#if not CLEAN30
    var
        BankingFeature: Codeunit "Banking Payments Feature FI";
#endif
}
