// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Codeunit Shpfy Auto Post Finalize (ID 30423).
/// Runs cleanup and skipped-record persistence in isolated, trappable transactions.
/// </summary>
codeunit 30423 "Shpfy Auto Post Finalize"
{
    Access = Internal;
    TableNo = "Shpfy Order Transaction";

    trigger OnRun()
    begin
        if CleanupBatch then
            RemoveIsolatedBatch();
        if FailureReason <> '' then
            LogFailure(Rec);
    end;

    var
        TemplateName: Code[10];
        BatchName: Code[10];
        FailureReason: Text;
        CleanupBatch: Boolean;

    internal procedure SetCleanupParameters(NewTemplateName: Code[10]; NewBatchName: Code[10])
    begin
        TemplateName := NewTemplateName;
        BatchName := NewBatchName;
        CleanupBatch := true;
        Clear(FailureReason);
    end;

    internal procedure SetFailureParameters(NewFailureReason: Text)
    begin
        Clear(TemplateName);
        Clear(BatchName);
        CleanupBatch := false;
        FailureReason := NewFailureReason;
    end;

    local procedure RemoveIsolatedBatch()
    var
        IsolatedBatch: Record "Gen. Journal Batch";
    begin
        if IsolatedBatch.Get(TemplateName, BatchName) then
            IsolatedBatch.Delete(true);
    end;

    local procedure LogFailure(OrderTransaction: Record "Shpfy Order Transaction")
    var
        Shop: Record "Shpfy Shop";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
    begin
        if Shop.Get(OrderTransaction.Shop) then
            SkippedRecord.LogSkippedRecord(OrderTransaction."Shopify Transaction Id", OrderTransaction.RecordId, CopyStr(FailureReason, 1, 250), Shop);
    end;
}
