// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;

codeunit 11382 "G/L Entry NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterUpdateDebitCredit, '', false, false)]
    local procedure OnAfterUpdateDebitCredit(var GLEntry: Record "G/L Entry"; Correction: Boolean)
    begin
        if GLEntry.Open then
             GLEntry."Remaining Amount" := GLEntry.Amount;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseGLEntryOnBeforeInsertGLEntry', '', false, false)]
    local procedure OnReverseGLEntryOnBeforeInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        GLEntry.Open := false;
        GLEntry."Remaining Amount" := 0;
        GLEntry."Closed by Entry No." := GLEntry2."Entry No.";
        GLEntry."Closed at Date" := GLEntry2."Posting Date";

        GLEntry2.Open := false;
        GLEntry2."Remaining Amount" := 0;
        GLEntry2."Closed by Entry No." := GLEntry."Entry No.";
        GLEntry2."Closed at Date" := GLEntry2."Posting Date";
        GLEntry2."Closed by Amount" := GLEntry2.Amount;
        GLEntry2.Modify();
    end;
}
