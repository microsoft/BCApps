// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Foundation.BatchProcessing;
using Microsoft.Intercompany.Outbox;

codeunit 8453 "IC PurchBatchProcessingMgt"
{
    var
        InterCompanyZipFileNamePatternTok: Label 'Purchase IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';

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
        PurchasePostBatchMgt: Codeunit "Purchase Batch Post Mgt.";
#endif
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
#if not CLEAN29
        PurchasePostBatchMgt.RunOnGetICBatchFileName(Result);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;
}
