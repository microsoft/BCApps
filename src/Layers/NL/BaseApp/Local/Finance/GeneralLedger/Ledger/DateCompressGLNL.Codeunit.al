// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

codeunit 11448 "Date Compress G/L NL"
{
    Access = Internal;

    internal procedure FilterUnappliedEntries(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.MarkedOnly(false);
        GLEntry.AddLoadFields(GLEntry.Amount, GLEntry."Remaining Amount");
        if GLEntry.FindSet() then
            repeat
                GLEntry.Mark(GLEntry.Amount = GLEntry."Remaining Amount");
            until GLEntry.Next() = 0;
        GLEntry.MarkedOnly(true);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Date Compress General Ledger", 'OnGLEntryOnAfterGetRecordOnBeforeInitNewEntry', '', false, false)]
    local procedure FilterCompressionCandidates(var GLEntry2: Record "G/L Entry")
    begin
        // Marks are local to each record instance, so filter the inner compression scan as well.
        FilterUnappliedEntries(GLEntry2);
        GLEntry2.FindFirst();
    end;

    [EventSubscriber(ObjectType::Report, Report::"Date Compress General Ledger", 'OnSummarizeEntryOnBeforeGLEntryDelete', '', false, false)]
    local procedure OnSummarizeEntryOnBeforeGLEntryDelete(var NewGLEntry: Record "G/L Entry"; GLEntry: Record "G/L Entry")
    begin
        NewGLEntry."Remaining Amount" += GLEntry."Remaining Amount";
    end;
}
