// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Foundation.BatchProcessing;
using Microsoft.Intercompany.Outbox;

/// <summary>
/// Extends Sales Batch Post Mgt. with Intercompany-specific functionality.
/// Downloads IC batch files after a Sales batch post completes successfully.
/// </summary>
codeunit 8507 "IC Sales Batch Processing Mgt."
{
    var
        InterCompanyZipFileNamePatternTok: Label 'Sales IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBatchProcessOnBeforeResetBatchID', '', false, false)]
    local procedure OnBatchProcessOnBeforeResetBatchID(var RecRef: RecordRef; ProcessingCodeunitID: Integer)
    var
        ICOutboxExport: Codeunit "IC Outbox Export";
    begin
        ICOutboxExport.DownloadBatchFiles(GetICBatchFileName());
    end;

    local procedure GetICBatchFileName() Result: Text
#if not CLEAN29
    var
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
#endif
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
#if not CLEAN29
        SalesBatchPostMgt.RunOnGetICBatchFileName(Result);
#endif
    end;

    /// <summary>
    /// Raised to customize the intercompany batch file name for sales batch posting.
    /// </summary>
    /// <param name="Result">The file name to use for the intercompany batch.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;
}
