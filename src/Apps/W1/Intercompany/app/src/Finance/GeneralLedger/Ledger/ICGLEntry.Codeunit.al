// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;

codeunit 8424 "IC G/L Entry"
{
    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterCopyGLEntryFromGenJnlLine', '', true, false)]
    local procedure OnAfterCopyGLEntryFromGenJnlLine(var GLEntry: Record "G/L Entry"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::"IC Partner") or
           (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"IC Partner")
        then
            GLEntry."Source Type" := GLEntry."Source Type"::" ";

        GLEntry."IC Partner Code" := GenJournalLine."IC Partner Code";
    end;
}
