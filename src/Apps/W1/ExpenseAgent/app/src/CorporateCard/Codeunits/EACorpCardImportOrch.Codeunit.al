// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

codeunit 7432 "EA Corp Card Import Orch"
{
    Access = Internal;
    Permissions = tabledata "Data Exch." = d;

    internal procedure RunProvider(CorpCardProvider: Record "EA Corp Card Provider")
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        CorpCardProvReg: Codeunit "EA Corp Card Prov Reg";
        AuditSubscribers: Codeunit "EA Corp Card Audit Subscribers";
        CorpCardProviderImpl: Interface "EA Corp Card Provider";
        ImportErrorText: Text;
    begin
        CorpCardProvReg.ResolveProvider(CorpCardProvider, CorpCardProviderImpl);

        CorpCardBatch.Init();
        CorpCardBatch."Provider Code" := CorpCardProvider.Code;
        CorpCardBatch."Started DT" := CurrentDateTime();
        CorpCardBatch.Status := CorpCardBatch.Status::Started;
        CorpCardBatch.Insert(true);

        AuditSubscribers.LogImportStarted(CorpCardProvider.Code, CorpCardBatch."Batch No.");

        if not TryProcessProviderImport(CorpCardProviderImpl, CorpCardBatch) then begin
            ImportErrorText := GetLastErrorText();
            MarkImportFailed(CorpCardBatch);
            AuditSubscribers.LogImportFailed(CorpCardProvider.Code, CorpCardBatch."Batch No.", ImportErrorText);
            ClearSourcePayload(CorpCardProvider.Code, CorpCardBatch);
            UpdateProviderLastBatchNo(CorpCardProvider.Code, CorpCardBatch."Batch No.");
            Commit();
            Error(ImportErrorText);
        end;

        CorpCardBatch.Get(CorpCardBatch."Batch No.");
        if CorpCardBatch.Status <> CorpCardBatch.Status::Failed then
            CorpCardBatch.Status := CorpCardBatch.Status::Completed;

        CorpCardBatch."Ended DT" := CurrentDateTime();
        CorpCardBatch.Modify();

        if CorpCardBatch.Status = CorpCardBatch.Status::Completed then
            AuditSubscribers.LogImportCompleted(CorpCardProvider.Code, CorpCardBatch."Batch No.", CorpCardBatch.Imported, CorpCardBatch.Exceptions, CorpCardBatch.Duplicates);

        ClearSourcePayload(CorpCardProvider.Code, CorpCardBatch);

        CorpCardProvider.Get(CorpCardProvider.Code);
        CorpCardProvider."Last Import DT" := CurrentDateTime();
        CorpCardProvider."Last Batch No." := CorpCardBatch."Batch No.";
        CorpCardProvider.Modify();
    end;

    [TryFunction]
    local procedure TryProcessProviderImport(CorpCardProviderImpl: Interface "EA Corp Card Provider"; var CorpCardBatch: Record "EA Corp Card Batch")
    begin
        CorpCardProviderImpl.Download(CorpCardBatch);
        CorpCardProviderImpl.ParseToStaging(CorpCardBatch."Batch No.");
        CorpCardProviderImpl.Ack(CorpCardBatch."Batch No.");
    end;

    local procedure MarkImportFailed(var CorpCardBatch: Record "EA Corp Card Batch")
    begin
        CorpCardBatch.Get(CorpCardBatch."Batch No.");
        CorpCardBatch.Status := CorpCardBatch.Status::Failed;
        CorpCardBatch."Ended DT" := CurrentDateTime();
        CorpCardBatch.Modify();
    end;

    local procedure ClearSourcePayload(ProviderCode: Code[20]; var CorpCardBatch: Record "EA Corp Card Batch")
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        DataExch: Record "Data Exch.";
    begin
        if CorpCardProvider.Get(ProviderCode) then begin
            Clear(CorpCardProvider."Source Payload");
            CorpCardProvider."Source Payload Record Count" := 0;
            CorpCardProvider.Modify();
        end;

        CorpCardBatch.Get(CorpCardBatch."Batch No.");
        if DataExch.Get(CorpCardBatch."Data Exch Entry No.") then
            DataExch.Delete(true);

        CorpCardBatch."Data Exch Entry No." := 0;
        CorpCardBatch.Modify();
    end;

    local procedure UpdateProviderLastBatchNo(ProviderCode: Code[20]; BatchNo: Integer)
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.Get(ProviderCode);
        CorpCardProvider."Last Batch No." := BatchNo;
        CorpCardProvider.Modify();
    end;
}