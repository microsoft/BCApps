// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Outbox;

/// <summary>
/// Extends Batch Processing Mgt. with Intercompany-specific functionality.
/// Downloads IC batch files after a General Journal Line batch post completes successfully.
/// </summary>
codeunit 8495 "IC Batch Processing Mgt."
{
    var
        InterCompanyZipFileNamePatternTok: Label 'General Journal IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
#if not CLEAN30
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBatchProcessGenJnlLineOnAfterPost', '', false, false)]
    local procedure OnBatchProcessGenJnlLineOnAfterPost(var GenJournalLine: Record "Gen. Journal Line"; PostingResult: Boolean)
    var
        ICOutboxExport: Codeunit "IC Outbox Export";
    begin
        if PostingResult then
            ICOutboxExport.DownloadBatchFiles(GetICBatchFileName());
    end;

    local procedure GetICBatchFileName() Result: Text
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
#if not CLEAN30
        BatchProcessingMgt.RunOnGetICBatchFileName(Result);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;
}
